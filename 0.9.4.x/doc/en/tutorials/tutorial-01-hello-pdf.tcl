#!/usr/bin/env tclsh
# Runnable companion to tutorial-01-hello-pdf.md
source [file join [file dirname [info script]] ../_bootstrap.tcl]
pdf4tcl::doc::init [info script]

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
set out [pdf4tcl::doc::outfile tutorial-01-hello.pdf]
$pdf write -file $out
$pdf destroy
pdf4tcl::doc::done $out
