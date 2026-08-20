# How-to: standard ligatures

## Runnable script

```bash
tclsh doc/en/howtos/howto-ligatures.tcl
# PDF -> doc/en/out/
```

Companion: [`howto-ligatures.tcl`](howto-ligatures.tcl).

## Problem

In `Auflage` the `f` and the `l` collide; in `offiziell` the `f` pair does
the same. Most faces ship a single glyph for such pairs.

## Recipe

```tcl
pdf4tcl::loadBaseTrueTypeFont BaseLiga $fontFile
pdf4tcl::createFontSpecCID BaseLiga LigaFont

$pdf setFont 22 LigaFont
$pdf setLigatures 1
$pdf text "Auflage finden" -x 0 -y 70
```

Off by default, because it changes the output of documents that already
exist. Like `setKerning`, the setting belongs to the text state and comes
back with `grestore`.

## The part that has to be right

A ligature is **one glyph for two characters**. Set without a matching
`ToUnicode` entry, the document looks better and is no longer searchable --
`Auflage` cannot be found any more, and it shows up weeks later.

pdf4tcl records every character a ligature stands for:

```
glyphChars:  67 {102 105}
ToUnicode:   <0043> <00660069>
```

Measured with `pdftotext` over the generated file:

```
Auflage finden, offiziell
```

The words come back whole. `tests/ligatures.test` pins this, and the
counter-check -- recording only the first character -- turns it red.

## Not every face means the same thing

Measured across 66 TrueType faces on one Linux installation:

| | |
|---|---|
| Carlito | 424 ligature targets |
| Liberation Serif | none |
| DejaVu Sans | the `liga` feature is **Arabic**, and the face has no `fi` glyph at all (U+FB01 missing) |
| 64 of 65 | do have a `fi` glyph |

So check the face rather than assuming. The example script prefers Carlito
for that reason.

## What is read

`GSUB`, lookup type 4 (ligature substitution), including type 7
(extension). The longest match wins, so `ffi` becomes one glyph rather
than `f` followed by `fi`.

Only for embedded fonts. The standard 14 have no `GSUB`.

## Interaction with kerning

Both can be on. The text is shaped first and kerned afterwards, so a run is
substituted before any pair is looked up:

```
Unicode -> glyphs -> ligatures -> kerning -> TJ
```

That order matters. Until 0.9.4.49 the string was split on the glyphs
*before* substitution, so `ffi` in Carlito came out as `f` + kern + `fi`
instead of the `ffi` glyph -- the kerning split undid "longest match wins".

Kerning pairs are looked up on the **ligature glyph**, which is what the
font intends: a face that defines an `ffi` glyph also defines its kerning.

## Measuring and drawing agree (0.9.4.49)

`getStringWidth` measures the same shaped run, so a ligature changes the
number as well:

```tcl
$pdf setLigatures 0
set a [$pdf getStringWidth "ffi"]   ;# 9.96 at 20pt Carlito
$pdf setLigatures 1
set b [$pdf getStringWidth "ffi"]   ;# 9.69
```

The difference is not decoration. In Carlito, per 1000 units:

| | width |
|---|---|
| `f` + `f` + `i` | 839.8 |
| `ffi` glyph | 807.6 |

Four percent. Before 0.9.4.49 the width was summed per character while a
ligature glyph was drawn, so centred text sat off centre, right-aligned
text ran past its anchor, and `drawTextBox` broke lines in the wrong place.

## See also

- [`howto-kerning.md`](howto-kerning.md)
- `tests/ligatures.test` -- 16 tests
