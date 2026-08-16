#!/usr/bin/env tclsh
source [file join [file dirname [info script]] ../_bootstrap.tcl]
pdf4tcl::doc::init [info script]
set pdf [::pdf4tcl::new %AUTO% -paper a4 -orient 1 -margin 50]
$pdf startPage
$pdf setFillColor 1 0 0
$pdf setAlpha 1.0
$pdf rectangle 40 40 100 50 -filled 1
$pdf setFillColor 0 0.7 0
$pdf setAlpha 0.5
$pdf rectangle 80 55 100 50 -filled 1
$pdf setFillColor 1 0.5 0
$pdf setStrokeColor 0 0 0
$pdf setAlpha 0.4 -fill
$pdf setAlpha 1.0 -stroke
$pdf setLineWidth 2
$pdf rectangle 40 130 160 40 -filled 1 -stroke 1
$pdf setAlpha 1.0
$pdf endPage
set out [pdf4tcl::doc::outfile howto-alpha.pdf]
$pdf write -file $out
$pdf destroy
pdf4tcl::doc::done $out
