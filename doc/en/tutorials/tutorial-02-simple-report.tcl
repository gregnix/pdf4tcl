#!/usr/bin/env tclsh
# Runnable companion to tutorial-02-simple-report.md
source [file join [file dirname [info script]] ../_bootstrap.tcl]
pdf4tcl::doc::init [info script]

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

$pdf startPage
header $pdf "Quarterly report"
footer $pdf 1
$pdf setFont 28 Helvetica-Bold
$pdf text "Q2 Summary" -x 0 -y 120
$pdf setFont 12 Helvetica
$pdf text "Generated with pdf4tcl." -x 0 -y 150
$pdf endPage

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
foreach row {
    {Widgets 120 4.90}
    {Gadgets 45 12.00}
    {Sprockets 200 1.25}
} {
    incr y 16
    set x 0
    foreach cell $row w $cols {
        $pdf text $cell -x $x -y $y
        incr x $w
    }
}
$pdf endPage

set out [pdf4tcl::doc::outfile tutorial-02-report.pdf]
$pdf write -file $out
$pdf destroy
pdf4tcl::doc::done $out
