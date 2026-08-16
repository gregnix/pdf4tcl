# Tutorial 2 -- Simple multi-page report

## Runnable script

```bash
tclsh 0.9.4.x/doc/en/tutorials/tutorial-02-simple-report.tcl
# PDF -> 0.9.4.x/doc/en/out/
```

Companion: [`tutorial-02-simple-report.tcl`](tutorial-02-simple-report.tcl).

Produce a short report: title page, a content page with a small table, and a
running header/footer. Still Pure Tcl, still Base-14 fonts (Latin-1 only).

## Skeleton

```tcl
#!/usr/bin/env tclsh
lappend auto_path /path/to/pdf4tcl
package require pdf4tcl 0.9

set pdf [::pdf4tcl::new %AUTO% -paper a4 -orient 1 -margin 48]
$pdf metadata -title "Quarterly report" -author "pdf4tcl tutorial"

proc header {pdf title} {
    $pdf setFont 9 Helvetica
    $pdf setFillColor 0.35 0.35 0.35
    $pdf text $title -x 0 -y 10
    $pdf setStrokeColor 0.7 0.7 0.7
    $pdf setLineWidth 0.5
    lassign [$pdf getDrawableArea] w h
    $pdf line 0 14 $w 14
    $pdf setFillColor 0 0 0
}

proc footer {pdf page} {
    lassign [$pdf getDrawableArea] w h
    $pdf setFont 8 Helvetica
    $pdf setFillColor 0.35 0.35 0.35
    $pdf text "Page $page" -x [expr {$w - 40}] -y [expr {$h - 8}]
    $pdf setFillColor 0 0 0
}

# --- title page ----------------------------------------------------------
$pdf startPage
header $pdf "Quarterly report"
footer $pdf 1

$pdf setFont 28 Helvetica-Bold
$pdf text "Q2 Summary" -x 0 -y 120
$pdf setFont 12 Helvetica
$pdf text "Generated with pdf4tcl." -x 0 -y 150
$pdf endPage

# --- content page --------------------------------------------------------
$pdf startPage
header $pdf "Quarterly report"
footer $pdf 2

$pdf setFont 16 Helvetica-Bold
$pdf text "Figures" -x 0 -y 40

$pdf setFont 10 Helvetica-Bold
set y 70
set cols {80 80 80}
set headers {Item Qty Price}
set x 0
foreach h $headers w $cols {
    $pdf text $h -x $x -y $y
    incr x $w
}

$pdf setFont 10 Helvetica
set rows {
    {Widgets 120 4.90}
    {Gadgets 45 12.00}
    {Sprockets 200 1.25}
}
foreach row $rows {
    incr y 16
    set x 0
    foreach cell $row w $cols {
        $pdf text $cell -x $x -y $y
        incr x $w
    }
}

$pdf endPage
$pdf write -file report.pdf
$pdf destroy
puts "wrote report.pdf"
```

## Patterns used

| Need | Approach |
|---|---|
| Same chrome on every page | Small `header` / `footer` procs called after each `startPage` |
| Drawable size | `getDrawableArea` -- width/height inside the margins |
| Grey rules | `setStrokeColor` + `line`; reset fill for body text |
| Metadata | `metadata` -- useful for viewers and for PDF/A later |

This table is painted by hand. For flowing paragraphs, columns, and
automatic page breaks, use **pdf4tcllib** (or your own layout layer) on top of
pdf4tcl -- the engine draws what you ask for; it does not paginate text for you.

## Next

- Embed DejaVu or FreeSans and switch to Unicode (`../howtos/howto-unicode.md`).
- Add a bookmark outline (`../howtos/howto-links-and-bookmarks.md`).
- Make it accessible (`tutorial-03-accessible-pdf.md`).
