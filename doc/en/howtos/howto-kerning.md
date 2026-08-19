# How-to: pair kerning

## Runnable script

```bash
tclsh doc/en/howtos/howto-kerning.tcl
# PDF -> doc/en/out/
```

Companion: [`howto-kerning.tcl`](howto-kerning.tcl).

## Problem

`AV`, `To`, `Wa` and `Ty` leave a visible gap when the glyphs are simply
placed one after another. The font carries a correction for such pairs;
without it a heading looks typed rather than typeset.

## Recipe

```tcl
pdf4tcl::loadBaseTrueTypeFont BaseKern $fontFile
pdf4tcl::createFontSpecCID BaseKern KernFont

$pdf setFont 20 KernFont
$pdf text "AVATAR Wave To Ty." -x 0 -y 70
```

That is all. Kerning is on by default for embedded fonts, so a document
that loads a TrueType face gets it without asking.

## Three levels

| | |
|---|---|
| `$pdf setKerning 0` | off -- the output of 0.9.4.46 and earlier |
| `$pdf setKerning 1` | embedded fonts only, the default |
| `$pdf setKerning all` | the standard 14 as well |

The standard 14 are not in the default because their output is pinned by
the regression tests: a document that has looked the same for years does
not change unasked. `setKerning all` raises an error when the pairs are
not available, rather than silently doing nothing.

The setting belongs to the text state and comes back with `grestore`, so
a block that turns it off does not leak into what follows.

## What ends up in the file

A kerned string is written as a `TJ` array instead of a `Tj` string:

```
[(A) 70 (V) 80 (A) 120 (T) 120 (AR ) 40 (W) 40 (a) ...] TJ
```

A positive number moves the pen back, so the pair sits tighter. An
embedded face writes hex in angle brackets instead:

```
[<0024> 63.9648 <0039>] TJ
```

Where a face has no pairs for the string, the plain `Tj` form is written
and the output is byte for byte as before.

## Measuring and drawing agree

This is the part that matters in practice. `getStringWidth` returns the
kerned width, so line breaking, centring and table columns work on the
number that actually gets drawn.

The script shows it with a rule: a right-aligned string ends exactly on
the anchor. If the measurement ignored kerning, the line would run past
it.

```tcl
set anchor [lindex [$pdf getDrawableArea] 0]
$pdf text $probe -x $anchor -y 320 -align right
$pdf line $anchor 300 $anchor 330
```

## Where the numbers come from

| Source | |
|---|---|
| `kern` table | the legacy format, version 0, coverage format 0 |
| `GPOS` | the `kern` feature, pair adjustment (type 2), both subtable formats, including extension lookups (type 9) |
| Adobe metrics | for the standard 14, keyed by Unicode like their widths |

Both font sources are needed: of 66 TrueType faces on a typical Linux
installation, 33 carry a `kern` table and 43 a `kern` feature in GPOS.
Carlito and Caladea -- the metric stand-ins for Calibri and Cambria --
have GPOS only, and wrap their subtables in extension lookups.

Class-based GPOS subtables are kept as classes rather than expanded into
glyph pairs. Expanding Carlito gives 171859 pairs, 1271 ms to load and
2.2 MB; kept as classes it is 47 ms.

## Combining marks

Where a face sets `lookupFlag` bit 3 (`IgnoreMarks`), mark glyphs named by
`GDEF` are skipped when pairs are formed:

```tcl
$pdf getStringWidth "AV"          ;# 25.920
$pdf getStringWidth "A\u0301V"    ;# 25.920 -- the accent takes no room
```

The adjustment is written after the mark, so the accent stays with the
letter it belongs to:

```
[<00050121> 117 <001A>] TJ
```

18 of 66 faces here set that bit, and none sets any other.

## Not read

- the remaining `lookupFlag` bits -- a face that suppresses kerning for
  base glyphs or ligatures still gets it here
- script and language system selection -- every `kern` feature is taken
- contextual lookups
- version 1 of the `kern` table (the Apple layout), skipped rather than
  misread
- the fourteen standard faces have no kern data for `Symbol`,
  `ZapfDingbats` or `Courier`; a fixed-pitch face does not kern

## See also

- `tests/kerning.test` -- 25 tests, including the cross-check that
  `getStringWidth` and the content stream produce the same numbers
- `tools/mk-stdkern.tcl` -- generates `stdkern.tcl` from the AFM files
