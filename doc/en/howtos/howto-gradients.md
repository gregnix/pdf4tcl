# How-to: Gradients and blend modes

## Runnable script

```bash
tclsh 0.9.4.x/doc/en/howtos/howto-gradients.tcl
# PDF -> 0.9.4.x/doc/en/out/
```

Companion: [`howto-gradients.tcl`](howto-gradients.tcl).

Demo: `0.9.4.x/demo/demo-gradients.tcl`

## Problem

Fill a region with an axial or radial colour blend.

## Linear (axial)

Clip first so the shading stays inside a box:

```tcl
$pdf gsave
$pdf clip 50 100 400 60
$pdf linearGradient 50 130 450 130 red blue
$pdf grestore
$pdf rectangle 50 100 400 60   ;# optional frame
```

Since **0.9.4.39** gradient colours use the same `GetColor` pipeline as
`setFillColor`: RGB lists, CMYK lists, `#rrggbb`, and named colours (no Tk
required for the built-in name table). Option `-extend {0 0}` stops the blend
at the endpoints.

## Radial

```tcl
$pdf gsave
$pdf clip 50 200 200 200
$pdf radialGradient 150 300 0 150 300 90 white black
$pdf grestore
```

Arguments: inner centre/radius, outer centre/radius, colour1, colour2.

## Blend mode

```tcl
$pdf setBlendMode Multiply
# ... draw overlapping fills ...
$pdf setBlendMode Normal
```

## CMYK documents

With `-cmyk 1` the shading dictionary uses `/DeviceCMYK`. See
`howto-cmyk.md`, `howto-colors.md`, `../pdf4tcl-graphics-and-colors.md`.
