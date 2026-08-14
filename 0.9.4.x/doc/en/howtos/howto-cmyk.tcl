#!/usr/bin/env tclsh
source [file join [file dirname [info script]] ../_bootstrap.tcl]
pdf4tcl::doc::init [info script]
set pdf [::pdf4tcl::new %AUTO% -paper a4 -orient 1 -cmyk 1 -margin 50]
$pdf startPage
$pdf setFillColor 0.0 0.5 1.0 0.0
$pdf rectangle 50 50 100 40 -filled 1
$pdf setFillColor 1 0 0
$pdf setFont 12 Helvetica
$pdf text "Converted from RGB" -x 50 -y 120
$pdf gsave
$pdf clip 50 150 200 40
$pdf linearGradient 50 170 250 170 {0 0 0 0} {0 0.5 1 0}
$pdf grestore
$pdf endPage
set out [pdf4tcl::doc::outfile howto-cmyk.pdf]
$pdf write -file $out
$pdf destroy
pdf4tcl::doc::done $out
