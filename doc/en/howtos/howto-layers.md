# How-to: Optional content layers (OCG)

## Runnable script

```bash
tclsh 0.9.4.x/doc/en/howtos/howto-layers.tcl
# PDF -> 0.9.4.x/doc/en/out/
```

Companion: [`howto-layers.tcl`](howto-layers.tcl).

Demo: `0.9.4.x/demo/demo-layers.tcl`

## Problem

Let the reader turn a debug grid, letterhead, or watermark on and off.

## Recipe

```tcl
set pdf [::pdf4tcl::new %AUTO% -paper a4 -orient 1]
set grid [$pdf addLayer "Debug grid" -visible 0]
set body [$pdf addLayer "Body" -visible 1]

$pdf startPage

$pdf beginLayer $grid
$pdf setStrokeColor 0.85 0.85 0.85
for {set x 0} {$x <= 500} {incr x 50} {
    $pdf line $x 0 $x 700
}
$pdf endLayer

$pdf beginLayer $body
$pdf setFont 12 Helvetica
$pdf text "Visible body text" -x 50 -y 50
$pdf endLayer

$pdf endPage
$pdf write -file layers.pdf
$pdf destroy
```

## Notes

- Layers are document-wide; `beginLayer` / `endLayer` wrap painting on a page.
- With PDF/A-2b, OCG has extra rules (AS array); see demos / manpage if you
  combine `-pdfa 2b` and layers.
- Viewer UI for layers varies; Acrobat and some others show a layers panel.
