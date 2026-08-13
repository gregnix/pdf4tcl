# How-to: Unicode text (CID fonts)

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
- Full manual: `../pdf4tcl-cidfont-manual.md`.
- Side-by-side WinAnsi vs CID: `0.9.4.x/demo/demo-api-vergleich.tcl`.
- If text shows as `?` or blanks, check `getSubstCount` and switch to CID.
