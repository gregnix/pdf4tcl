# Tutorial 1 -- Hello PDF

Build a one-page A4 PDF with a title, a coloured rule, and a short paragraph.
About five minutes if pdf4tcl is already on your `auto_path`.

## Setup

```tcl
#!/usr/bin/env tclsh
lappend auto_path /path/to/pdf4tcl          ;# or: /path/to/pdf4tcl/pkg
package require pdf4tcl 0.9
```

From a checkout of this repository:

```tcl
lappend auto_path [file normalize [file join [file dirname [info script]] ../../..]]
package require pdf4tcl 0.9
```

## Create the document

Always set `-orient` explicitly. With the default `-orient 1`, **y grows
downward** from the top margin; `(0,0)` is the top-left of the drawable area
once margins are applied. See `../pdf4tcl-basics.md` if that surprises you.

```tcl
set pdf [::pdf4tcl::new %AUTO% -paper a4 -orient 1 -margin 50]
$pdf startPage

$pdf setFont 22 Helvetica-Bold
$pdf setFillColor 0.1 0.2 0.45
$pdf text "Hello pdf4tcl" -x 0 -y 24

$pdf setStrokeColor 0.1 0.2 0.45
$pdf setLineWidth 1.5
$pdf line 0 36 200 36

$pdf setFillColor 0 0 0
$pdf setFont 11 Helvetica
$pdf text "A one-page PDF built with Pure Tcl." -x 0 -y 60
$pdf text "Colours stay active until you change them again." -x 0 -y 76

$pdf endPage
$pdf write -file hello.pdf
$pdf destroy
puts "wrote hello.pdf"
```

## What to notice

1. **Baseline.** The `-y` of `text` is the baseline, not the top of the glyphs.
   With a 22 pt font, `y 24` keeps the title clear of the top edge.
2. **Colour state.** After the blue title, fill is reset to black before the
   body text. Stroke colour only affects lines and outlines.
3. **Finish order.** `write` then `destroy`. Destroying first leaves nothing to
   write.

## Next

- Change the paper to `letter` or add `-landscape 1`.
- Replace Helvetica with an embedded TrueType font (`../howtos/howto-unicode.md`).
- Continue with [Tutorial 2](tutorial-02-simple-report.md).
