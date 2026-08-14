#!/usr/bin/env tclsh
source [file join [file dirname [info script]] ../_bootstrap.tcl]
pdf4tcl::doc::init [info script]
set pdf [::pdf4tcl::new %AUTO% -paper a4 -orient 1 -margin 50]
$pdf startPage
$pdf setFont 12 Helvetica
$pdf text "linearGradient" -x 0 -y 24
$pdf gsave
$pdf clip 0 40 400 60
$pdf linearGradient 0 70 400 70 red blue
$pdf grestore
$pdf rectangle 0 40 400 60
$pdf text "radialGradient" -x 0 -y 130
$pdf gsave
$pdf clip 0 140 200 120
$pdf radialGradient 100 200 0 100 200 80 white black
$pdf grestore
$pdf endPage
set out [pdf4tcl::doc::outfile howto-gradients.pdf]
$pdf write -file $out
$pdf destroy
pdf4tcl::doc::done $out
