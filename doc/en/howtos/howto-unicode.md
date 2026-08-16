# How-to: Unicode text (CID fonts)

## Runnable script

```bash
tclsh doc/en/howtos/howto-unicode.tcl
# PDF -> doc/en/out/
```

Companion: [`howto-unicode.tcl`](howto-unicode.tcl).

## Problem

`createFont` with WinAnsi / ISO-8859-1 only covers Latin-1. Polish, Greek,
Cyrillic, maths symbols, or CJK need a CID font.

## Recipe

```tcl
pdf4tcl::loadBaseTrueTypeFont BaseDejaVu /usr/share/fonts/truetype/dejavu/DejaVuSans.ttf
pdf4tcl::createFontSpecCID BaseDejaVu Uni

set pdf [::pdf4tcl::new %AUTO% -paper a4 -orient 1 -margin 50]
$pdf startPage
$pdf setFont 12 Uni
$pdf text "Zażółć gęślą jaźń -- Ελληνικά -- Русский" -x 0 -y 24
$pdf endPage
$pdf write -file unicode.pdf
$pdf destroy
```

## Notes

- The whole TTF is embedded (no subsetting for CID). Prefer a font that covers
  the scripts you need; CJK needs a CJK face.
- Colour-bitmap emoji fonts (CBDT/CBLC) and COLR fonts are detected and
  rejected -- outline fonts only.
- Full manual: `../reference/pdf4tcl-cidfont-manual.md`.
- Side-by-side WinAnsi vs CID: `demo/demo-api-vergleich.tcl`.
- If text shows as `?` or blanks, check `getSubstCount` and switch to CID.

## Two things the recipe does not tell you

**A CID font embeds the whole file.** One line of Greek in DejaVu Sans comes
to 762 698 bytes uncompressed, 386 728 compressed. If the character
repertoire is fixed, `createFontSpecEnc` embeds a real subset instead:

| | file |
|---|---|
| subset, 5 codepoints | 8 860 bytes |
| subset, 200 codepoints | 29 761 bytes |
| CID, whole font | 386 728 bytes |

256 codepoints is the ceiling for a subset -- beyond that only CID works.
And always put `?` (63) in the subset: characters outside the list fall back
to `?` if it is there, and to slot 0 -- the *first codepoint you listed* --
if it is not. Measured: a subset starting with `G` turned Greek text into
`GGGGGG`, which reads like real text and is not.

**Characters above U+FFFF depend on the Tcl generation.** Written as a
literal in the source:

| | `string length` | first character | extracted |
|---|---|---|---|
| Tcl 9.0.4 | 1 | U+1F600 | correct |
| Tcl 8.6.14 | 1 | U+FFFD | replacement character |

Read from a UTF-8 file, both generations produce the correct PDF; only
`string length` differs (surrogate pair on 8.6). So: no `\U`-escapes above
U+FFFF in code that must run on 8.6, and measure widths with
`getStringWidth`, not `string length`.

## See also

- [`../reference/pdf4tcl-fonts-and-unicode.md`](../reference/pdf4tcl-fonts-and-unicode.md) --
  the three routes compared, with sizes
- [`howto-font-coverage.md`](howto-font-coverage.md) -- does the font
  actually have the glyph?
- [`../tutorials/tutorial-07-multilingual.md`](../tutorials/tutorial-07-multilingual.md)
