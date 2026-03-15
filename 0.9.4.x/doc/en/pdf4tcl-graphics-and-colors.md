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

### Basic Concept

In pdf4tcl, individual objects are not transformed — the entire
coordinate system is. All subsequent drawing commands are affected.
`gsave`/`grestore` is therefore essential.

### gsave and grestore

```tcl
# Save coordinate system
$pdf gsave

# Apply transformation
$pdf rotate 45
$pdf text "Rotated" -x 0 -y 0

# Restore coordinate system
$pdf grestore

# Back to normal
$pdf text "Normal" -x 100 -y 100
```

Without `gsave`/`grestore` all further drawing operations would also be
rotated.

### Rotation

```tcl
$pdf gsave
$pdf translate 200 400    ;# move to the rotation point first
$pdf rotate 45            ;# rotate 45 degrees
$pdf text "45 degrees" -x 0 -y 0
$pdf grestore
```

Rotation always happens around the current origin. The coordinate system
must therefore be translated to the desired pivot point first.

### Scaling

```tcl
$pdf gsave
$pdf scale 2.0 2.0        ;# 200% enlargement
$pdf text "Large" -x 50 -y 50
$pdf grestore
```

### Translation (Offset)

```tcl
$pdf gsave
$pdf translate 100 200    ;# move origin
$pdf text "Offset" -x 0 -y 0
$pdf grestore
```

### Combined Transformations

Transformations can be combined. The order matters because each one
builds on the previous.

```tcl
$pdf gsave
$pdf translate 300 400    ;# 1. move to point
$pdf rotate 30            ;# 2. rotate
$pdf scale 0.5 0.5        ;# 3. shrink
$pdf text "Combined" -x 0 -y 0
$pdf grestore
```

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
$pdf translate $dx $dy
$pdf rotate $degrees
$pdf scale $sx $sy
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
