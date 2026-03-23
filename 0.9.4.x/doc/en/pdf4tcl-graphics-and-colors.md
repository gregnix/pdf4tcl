# pdf4tcl Graphics and Colors

This document covers the graphics API of pdf4tcl: lines, rectangles,
circles, colors, and transformations. It shows how to draw and style
geometric shapes.

## Colors

### RGB Color Model

pdf4tcl uses RGB colors with values from 0.0 to 1.0, not 0 to 255.

```tcl
# Black
$pdf setFillColor 0.0 0.0 0.0

# White
$pdf setFillColor 1.0 1.0 1.0

# Red
$pdf setFillColor 1.0 0.0 0.0

# 50% gray
$pdf setFillColor 0.5 0.5 0.5
```

### Fill Color and Stroke Color

There are two color channels: fill color (for text and filled shapes) and
stroke color (for lines and outlines).

```tcl
# Fill color (text, filled shapes)
$pdf setFillColor R G B

# Stroke color (lines, outlines)
$pdf setStrokeColor R G B
```

Both colors remain active until explicitly changed. After colored text or
shapes the colors must be reset.

```tcl
# Write colored text
$pdf setFillColor 0.8 0.0 0.0
$pdf text "Red text" -x 50 -y 100

# Reset color
$pdf setFillColor 0.0 0.0 0.0
$pdf text "Black text" -x 50 -y 120
```

### Converting Hex and 0–255 Values

```tcl
proc rgb255_to_pdf {r g b} {
    return [list \
        [expr {$r / 255.0}] \
        [expr {$g / 255.0}] \
        [expr {$b / 255.0}]]
}

proc hex_to_rgb {hex} {
    set hex [string trimleft $hex "#"]
    scan $hex "%2x%2x%2x" r g b
    return [list \
        [expr {$r / 255.0}] \
        [expr {$g / 255.0}] \
        [expr {$b / 255.0}]]
}

# Usage
lassign [hex_to_rgb "#FF6347"] r g b
$pdf setFillColor $r $g $b
```

### Useful Color Table

| Color       | R    | G    | B    | Usage                 |
|-------------|------|------|------|-----------------------|
| Black       | 0.0  | 0.0  | 0.0  | Text, lines           |
| White       | 1.0  | 1.0  | 1.0  | Background            |
| Light gray  | 0.9  | 0.9  | 0.9  | Table headers         |
| Medium gray | 0.6  | 0.6  | 0.6  | Grid lines            |
| Dark gray   | 0.3  | 0.3  | 0.3  | Secondary text        |
| Red         | 0.8  | 0.0  | 0.0  | Errors, warnings      |
| Dark blue   | 0.0  | 0.0  | 0.6  | Links, headings       |
| Dark green  | 0.0  | 0.4  | 0.0  | Success, positive     |

## Lines

### Simple Line

```tcl
$pdf setStrokeColor 0 0 0
$pdf setLineWidth 1
$pdf line 50 100 300 100
```

Parameters: X1, Y1 (start point), X2, Y2 (end point).

### Line Width

```tcl
$pdf setLineWidth 0.5    ;# thin (grids, guide lines)
$pdf setLineWidth 1      ;# standard
$pdf setLineWidth 2      ;# thick (borders)
$pdf setLineWidth 5      ;# very thick (diagrams)
```

### Dashed Lines

```tcl
# Dashed: 5pt dash, 3pt gap
$pdf setLineDash 5 3
$pdf line 50 100 300 100

# Dotted: 1pt dash, 3pt gap
$pdf setLineDash 1 3
$pdf line 50 120 300 120

# Back to solid
$pdf setLineDash 0 0
```

## Rectangles

### Outline Only

```tcl
$pdf setStrokeColor 0 0 0
$pdf setLineWidth 1
$pdf rectangle 50 100 200 80
```

Parameters: X, Y, width, height.

### Filled

```tcl
$pdf setFillColor 0.9 0.9 0.9
$pdf rectangle 50 100 200 80 -filled 1
```

### Filled with Outline

```tcl
$pdf setFillColor 0.9 0.9 0.9
$pdf setStrokeColor 0 0 0
$pdf setLineWidth 0.5
$pdf rectangle 50 100 200 80 -filled 1 -stroke 1
```

### Table Cell with Background

```tcl
proc drawCell {pdf x y w h text {bg ""}} {
    if {$bg ne ""} {
        lassign $bg r g b
        $pdf setFillColor $r $g $b
        $pdf rectangle $x $y $w $h -filled 1
    }
    $pdf setStrokeColor 0.6 0.6 0.6
    $pdf setLineWidth 0.5
    $pdf rectangle $x $y $w $h
    $pdf setFillColor 0 0 0
    $pdf setFont 10 Helvetica
    set textY [expr {$y + int(($h - 10) / 0.45)}]
    $pdf text $text -x [expr {$x + 4}] -y $textY
}
```

### Rounded rectangles (0.9.4.12)

```tcl
$pdf roundedRect x y width height ?-radius r? ?-filled 0/1? ?-stroke 0/1?
```

Draws a rectangle with rounded corners (Bezier approximation).

| Option | Default | Description |
|--------|---------|-------------|
| `-radius` | 5 | Corner radius in points |
| `-filled` | 0 | Fill the shape |
| `-stroke` | 1 | Draw outline |

The radius is automatically clamped to half the shorter side.

```tcl
# Outline only
$pdf roundedRect 50 100 200 80 -radius 12

# Filled with outline
$pdf setFillColor 0.2 0.6 0.3
$pdf roundedRect 50 100 200 80 -radius 20 -filled 1 -stroke 1

# Filled, no outline, semi-transparent
$pdf setFillColor 0.8 0.2 0.2
$pdf setAlpha 0.5
$pdf roundedRect 50 100 200 80 -radius 8 -filled 1 -stroke 0
```


## Circles and Ellipses

### Circle

```tcl
$pdf circle 200 300 50
```

Parameters: center X, center Y, radius.

### Filled Circle

```tcl
$pdf setFillColor 0.2 0.4 0.8
$pdf circle 200 300 50 -filled 1
```

### Ellipse

```tcl
$pdf oval 200 300 80 40
```

Parameters: center X, center Y, X radius, Y radius.

## Paths and Bezier Curves

### Polygon

```tcl
# Triangle
$pdf polygon 100 200 200 100 300 200
```

Coordinates are X,Y pairs for each vertex.

### Bezier Curve

```tcl
# Cubic Bezier curve
$pdf curve 50 300 100 200 200 200 250 300
```

Parameters: start point, control point 1, control point 2, end point.

## Transformations

`translate`, `rotate`, `scale`, and `transform` (all added in 0.9.4.20)
apply PDF coordinate transformations via the `cm` operator. Always wrap
with `gsave`/`grestore` to limit the effect.

**Important:** after any of these calls, drawing commands (`line`,
`rectangle`, `circle` etc.) work in **raw PDF coordinates**: y points
upward, no margin offset, no orient flip. Text commands (`text`,
`setFont`) use absolute `Tm` positioning and are **not affected** by
transformations.

### Raw-coordinate mode and the y offset

After `translate tx ty`, `rectangle 0 0 w h` draws `h` points
**upward** from the new origin. To place the bottom edge of a rectangle
at user-y, add the height to the y argument:

```tcl
set y 200; set rh 20
$pdf gsave
$pdf translate 100 [expr {$y + $rh}]  ;# bottom edge lands at y=200
$pdf rectangle 0 0 50 $rh
$pdf grestore
```

The `translate` point itself is converted from user-space (orient + margin)
correctly. Only subsequent drawing commands are raw.

### Translation (Offset)

```tcl
$pdf gsave
$pdf translate 100 [expr {200 + 20}]  ;# bottom of 20pt rect at y=200
$pdf rectangle 0 0 50 20
$pdf grestore
```

### Rotation

Rotation is around the current origin. Translate to the pivot first.

```tcl
$pdf gsave
$pdf translate 200 400    ;# 1. move origin to pivot point
$pdf rotate 45            ;# 2. rotate 45 degrees clockwise
$pdf line 0 0 50 0        ;# 3. draw (graphics only, not text)
$pdf grestore
```

### Scaling

```tcl
$pdf gsave
$pdf translate 50 [expr {300 + 40}]   ;# position (40 = 20*scale)
$pdf scale 2.0 2.0
$pdf rectangle 0 0 30 20 -filled 1
$pdf grestore
```

### Combined Transformations

Transformations accumulate. Order matters.

```tcl
$pdf gsave
$pdf translate 300 400    ;# 1. move origin
$pdf rotate 30            ;# 2. rotate
$pdf scale 0.5 0.5        ;# 3. scale
$pdf line 0 0 60 0        ;# draws along rotated+scaled x-axis
$pdf grestore
```

### transform (low-level matrix)

```tcl
$pdf gsave
$pdf transform a b c d e f    ;# raw PDF cm matrix
... drawing commands ...
$pdf grestore
```

Common matrices:

| Effect | a | b | c | d | e | f |
|---|---|---|---|---|---|---|
| Translate tx ty | 1 | 0 | 0 | 1 | tx | ty |
| Scale sx sy | sx | 0 | 0 | sy | 0 | 0 |
| Rotate θ | cos θ | sin θ | −sin θ | cos θ | 0 | 0 |

### gsave and grestore

`gsave` saves the complete graphics state (coordinate system, colors,
line width, font). `grestore` restores it. Always pair them.

```tcl
$pdf gsave
$pdf setFillColor 1 0 0
$pdf translate 50 [expr {200 + 20}]
$pdf rectangle 0 0 50 20 -filled 1
$pdf grestore
# Back to original coordinate system and color
$pdf rectangle 50 200 50 20    ;# same position, user-coords
```

### getPageSize

Returns the full page dimensions as `{width height}` in the current unit.

```tcl
set sz [$pdf getPageSize]
set w [lindex $sz 0]
set h [lindex $sz 1]
# A4 at -unit mm: approx {210.0 297.0}
# A4 at -unit p:  approx {595.0 842.0}
```

Use `getDrawableArea` for the printable area (excluding margins).

## Drawing Command Reference

```tcl
# Line
$pdf line $x1 $y1 $x2 $y2

# Rectangle (outline only)
$pdf rectangle $x $y $width $height

# Rectangle (filled)
$pdf rectangle $x $y $width $height -filled 1

# Rectangle (filled + outline)
$pdf rectangle $x $y $width $height -filled 1 -stroke 1

# Circle
$pdf circle $cx $cy $radius
$pdf circle $cx $cy $radius -filled 1

# Line width
$pdf setLineWidth 0.5

# Colors (RGB, 0.0 to 1.0)
$pdf setStrokeColor $r $g $b
$pdf setFillColor $r $g $b

# Dashed line
$pdf setLineDash $dash $gap

# Transformation
$pdf gsave
$pdf translate $dx $dy    ;# or rotate/scale/transform
$pdf grestore
```

## Practical Example: Horizontal Separator

```tcl
proc drawSeparator {pdf x y width {color "0.6 0.6 0.6"}} {
    lassign $color r g b
    $pdf setStrokeColor $r $g $b
    $pdf setLineWidth 0.5
    $pdf line $x $y [expr {$x + $width}] $y
    $pdf setStrokeColor 0 0 0
}
```

Never use `string repeat "-"` as a separator. Always use `$pdf line`
for pixel-accurate positioning.

## Blend Modes (0.9.4.13)

`setBlendMode` sets the PDF blend mode via ExtGState `/BM`. The mode
controls how new drawing operations combine with the content underneath.
`getBlendMode` returns the currently active mode.

```tcl
# Set blend mode
$pdf setBlendMode Multiply
$pdf rectangle 50 100 200 100 -filled 1

# Combine with alpha
$pdf setAlpha 0.7
$pdf setBlendMode Screen
$pdf rectangle 100 150 200 100 -filled 1

# Query current mode
set mode [$pdf getBlendMode]   ;# --> "Screen"

# Reset
$pdf setBlendMode Normal
$pdf setAlpha 1.0
```

Supported modes: `Normal Multiply Screen Overlay Darken Lighten
ColorDodge ColorBurn HardLight SoftLight Difference Exclusion
Hue Saturation Color Luminosity`

Note: Blend modes require PDF 1.4 or later. pdf4tcl raises the PDF
version to at least 1.4 automatically. ExtGState objects are cached
per mode + alpha combination.

## Gradients (0.9.4.13)

### linearGradient

Axial gradient from color A to color B along a line between two points
(PDF ShadingType 2 + FunctionType 2).

```tcl
# Horizontal: red to blue
$pdf linearGradient 50 100 250 100 \
    {1.0 0.0 0.0} {0.0 0.0 1.0}

# Diagonal with extend
$pdf linearGradient 50 200 300 350 \
    {1.0 1.0 1.0} {0.2 0.2 0.2} -extend 1

# Hex notation
$pdf linearGradient 50 400 350 400 \
    {#ff6600} {#0066ff}
```

Options:
- `-extend 1` — continue gradient beyond endpoints (default: 0)

### radialGradient

Radial gradient between two circles (PDF ShadingType 3 + FunctionType 2).

```tcl
# Simple radial: bright center, dark edge
$pdf radialGradient \
    150 300 0  \
    150 300 80 \
    {1.0 1.0 0.8} {0.6 0.3 0.0}

# Offset centers (spotlight effect)
$pdf radialGradient \
    120 480 10 \
    150 500 100 \
    {1.0 1.0 1.0} {0.1 0.1 0.3} -extend 1
```

Arguments: `x0 y0 r0 x1 y1 r1 color0 color1 ?-extend bool?`

Colors accept `{r g b}` (0.0–1.0), `{r g b a}` with alpha, or `#rrggbb`.
