# How-to: Transforms (`translate` / `rotate` / `scale`)

Demo: `0.9.4.x/demo/demo-transform.tcl`

## Problem

Rotate or scale graphics around a point.

## Recipe

```tcl
$pdf gsave
$pdf translate 200 300
$pdf rotate 45
$pdf setStrokeColor 0 0 0.6
$pdf line 0 0 80 0
$pdf grestore
```

`getPageSize` returns the paper size in the document unit:

```tcl
lassign [$pdf getPageSize] w h
```

## Important trap

**Text is not moved by `cm` transforms.** `text` uses absolute `Tm`
positioning. For rotated text:

```tcl
$pdf gsave
$pdf translate 100 200
$pdf rotate 90
$pdf text "Sideways" -x 0 -y 0
$pdf grestore
```

Always pair transforms with `gsave` / `grestore` so later drawing is not
skewed.
