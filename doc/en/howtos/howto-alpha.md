# How-to: Transparency (`setAlpha`)

## Runnable script

```bash
tclsh doc/en/howtos/howto-alpha.tcl
# PDF -> doc/en/out/
```

Companion: [`howto-alpha.tcl`](howto-alpha.tcl).

Demo: `demo/demo-alpha.tcl`

## Problem

Overlap shapes or fade text without inventing a gradient.

## Recipe

```tcl
set pdf [::pdf4tcl::new %AUTO% -paper a4 -orient 1 -margin 50]
$pdf startPage

$pdf setFillColor 1 0 0
$pdf setAlpha 1.0
$pdf rectangle 40 40 100 50 -filled 1

$pdf setFillColor 0 0.7 0
$pdf setAlpha 0.5
$pdf rectangle 80 55 100 50 -filled 1

# Fill and stroke independently
$pdf setFillColor 1 0.5 0
$pdf setStrokeColor 0 0 0
$pdf setAlpha 0.4 -fill
$pdf setAlpha 1.0 -stroke
$pdf setLineWidth 2
$pdf rectangle 40 130 160 40 -filled 1 -stroke 1

$pdf setAlpha 1.0
$pdf endPage
$pdf write -file alpha.pdf
$pdf destroy
```

## Notes

- Values are clamped to `0.0 .. 1.0`. State is saved/restored by `gsave` /
  `grestore`.
- PDF/A-1 forbids transparency; with `-pdfa 1b` and alpha &lt; 1, pdf4tcl
  appends a warning to `::pdf4tcl::warnings`.
- Also shown in the demo: `roundedRect`, unit helpers.
