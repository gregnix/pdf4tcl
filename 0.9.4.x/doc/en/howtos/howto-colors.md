# How-to: Colours (RGB, CMYK, names, range)

Since **0.9.4.39** colours live in `src/color.tcl` and share one pipeline
(`GetColor`) for fill, stroke, background, annotations, forms, and gradients.
Details: `../pdf4tcl-graphics-and-colors.md` (section "Color input"),
`../UPGRADING.md`.

## Problem

Set a fill or stroke colour without Tk, without writing illegal operands.

## Forms accepted

```tcl
$pdf setFillColor 1 0 0                 ;# RGB 0.0 .. 1.0
$pdf setFillColor #cc3300               ;# hex
$pdf setFillColor red                   ;# 147 X11/CSS names, no Tk needed
$pdf setFillColor 0 0.5 1 0             ;# CMYK; converted unless -cmyk 1
$pdf setStrokeColor navy
$pdf setBgColor 1 1 0                   ;# only for text -bg / -fill box
```

Components **must** be in `0.0 .. 1.0`. Out of range raises an error (before
0.9.4.39 the PDF was written anyway and viewers clamped silently):

```tcl
$pdf setFillColor 255 0 0    ;# ERROR -- use 1 0 0 or #ff0000
```

## Names without Tk

Headless `tclsh` can use `red`, `navy`, `gray`, … Names outside the built-in
table still fall back to `winfo rgb` when Tk and a display are available.

## Gradients

Same inputs as `setFillColor`. In a `-cmyk 1` document the shading uses
`/DeviceCMYK`. See `howto-gradients.md`, `howto-cmyk.md`.

## API channels

| Method | Role |
|---|---|
| `setFillColor` | Fills + text |
| `setStrokeColor` | Lines / outlines |
| `setBgColor` | Background **of `text -bg`**, not the page |

There is no page-background setter; draw a full-page rectangle if you need one.
