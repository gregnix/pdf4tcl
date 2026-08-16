# How-to: Colours and basic shapes

## Runnable script

```bash
tclsh doc/en/howtos/howto-shapes.tcl
# PDF -> doc/en/out/
```

Companion: [`howto-shapes.tcl`](howto-shapes.tcl).

Demo: `demo/FarbenundFormen.tcl`  
Also: Tutorial 1, `../reference/pdf4tcl-graphics-and-colors.md`

## Problem

Draw coloured text, a line, and a filled rectangle on one page.

## Recipe

```tcl
set pdf [::pdf4tcl::new %AUTO% -paper a4 -orient 1 -margin 50]
$pdf startPage

$pdf setFont 16 Helvetica-Bold
$pdf setFillColor 0.8 0 0
$pdf text "Red text" -x 0 -y 24

$pdf setStrokeColor 0 0 0
$pdf setLineWidth 1
$pdf line 0 36 250 36

$pdf setFillColor 0.9 0.9 0.9
$pdf rectangle 0 50 250 60 -filled 1
$pdf setFillColor 0 0 0
$pdf setFont 12 Helvetica
$pdf text "Label on grey box" -x 10 -y 85

$pdf endPage
$pdf write -file shapes.pdf
$pdf destroy
```

Reset fill to black after coloured text. Colour values are **0.0 .. 1.0**
(range-checked since 0.9.4.39); names like `red` work without Tk -- see
`howto-colors.md`. More shapes: `circle`, `oval`, `polygon`, `arc`,
`roundedRect`, `arrow` -- see the graphics guide and `demo-alpha.tcl` /
`demo-gradients.tcl`.
