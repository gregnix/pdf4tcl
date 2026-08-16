# How-to: CMYK output

## Runnable script

```bash
tclsh 0.9.4.x/doc/en/howtos/howto-cmyk.tcl
# PDF -> 0.9.4.x/doc/en/out/
```

Companion: [`howto-cmyk.tcl`](howto-cmyk.tcl).

## Problem

Print workflows want DeviceCMYK operators instead of DeviceRGB.

## Recipe

```tcl
set pdf [::pdf4tcl::new %AUTO% -paper a4 -orient 1 -cmyk 1]
$pdf startPage

# Four components: C M Y K in 0.0 .. 1.0 (range-checked since 0.9.4.39)
$pdf setFillColor 0.0 0.5 1.0 0.0
$pdf rectangle 50 50 100 40 -filled 1

# RGB-looking input is converted with pdf4tcl::rgb2Cmyk
$pdf setFont 12 Helvetica
$pdf setFillColor 1 0 0
$pdf text "Converted from RGB" -x 50 -y 120

# Gradients use the same pipeline and /DeviceCMYK when -cmyk 1
$pdf gsave
$pdf clip 50 150 200 40
$pdf linearGradient 50 170 250 170 {0 0 0 0} {0 0.5 1 0}
$pdf grestore

$pdf endPage
$pdf write -file cmyk.pdf
$pdf destroy
```

## Notes

- `-cmyk` is fixed at `new` time (readonly).
- Conversion is a simple formula, **not** an ICC transform. Override
  `::pdf4tcl::rgb2Cmyk` / `cmyk2Rgb` if you need a better mapping.
- Since 0.9.4.39 gradients share `GetColor` and declare CMYK in CMYK
  documents (they used to be fixed DeviceRGB with a narrower colour parser).
- Details: `howto-colors.md`, `../pdf4tcl-graphics-and-colors.md`.
