# How-to: OpenType / CFF fonts (OTF)

Demo: `0.9.4.x/demo/demo-otf.tcl` (skipped unless an OTF is found, or pass
`--font`; `run-all-demos.tcl --alle` forces the attempt)

## Problem

Embed an OpenType font with CFF outlines the same way as TrueType.

## Recipe

```tcl
pdf4tcl::loadBaseTrueTypeFont BaseLoma /usr/share/fonts/opentype/tlwg/Loma.otf
pdf4tcl::createFontSpecCID BaseLoma Uni

set pdf [::pdf4tcl::new %AUTO% -paper a4 -orient 1 -margin 50]
$pdf startPage
$pdf setFont 14 Uni
$pdf text "OTF/CFF via loadBaseTrueTypeFont" -x 0 -y 24
$pdf endPage
$pdf write -file otf-demo.pdf
$pdf destroy
```

Or with WinAnsi for Latin-1 only:

```tcl
pdf4tcl::createFont BaseLoma Body iso8859-1
```

## Run the demo

```bash
tclsh 0.9.4.x/demo/demo-otf.tcl --out 0.9.4.x/demo/out
tclsh 0.9.4.x/demo/demo-otf.tcl --out out --font /path/to/font.otf
```

## Notes

- Same loader API as TTF (`loadBaseTrueTypeFont`); OTF support since 0.9.4.15.
- Colour-bitmap / COLR-only fonts are still rejected.
- For Unicode coverage prefer `createFontSpecCID` (see `howto-unicode.md`).
