#!/usr/bin/env tclsh
source [file join [file dirname [info script]] ../_bootstrap.tcl]
pdf4tcl::doc::init [info script]
set pdf [::pdf4tcl::new %AUTO% -paper a4 -orient 1 -margin 50]
$pdf startPage
$pdf setFont 16 Helvetica-Bold
$pdf setFillColor 0.8 0 0
$pdf text "Red text" -x 0 -y 24
$pdf setStrokeColor 0 0 0
$pdf setLineWidth 1
$pdf line 0 36 250 36
$pdf setFillColor 0.9 0.9 0.9
$pdf rectangle 0 50 250 60 -filled 1
$pdf setFillColor 0 0 0
$pdf setFont 12 Helvetica
$pdf text "Label on grey box" -x 10 -y 85
$pdf endPage
set out [pdf4tcl::doc::outfile howto-shapes.pdf]
$pdf write -file $out
$pdf destroy
pdf4tcl::doc::done $out
