#!/usr/bin/env tclsh
# Companion to howto-colors.md
source [file join [file dirname [info script]] ../_bootstrap.tcl]
pdf4tcl::doc::init [info script]
set pdf [::pdf4tcl::new %AUTO% -paper a4 -orient 1 -margin 50]
$pdf startPage
$pdf setFont 14 Helvetica-Bold
$pdf text "Colors (0.9.4.39+)" -x 0 -y 24
set y 50
foreach {label args} {
    "RGB 1 0 0" {1 0 0}
    "hex #336699" {#336699}
    "name navy" {navy}
    "CMYK list" {0 0.5 1 0}
} {
    $pdf setFillColor {*}$args
    $pdf rectangle 0 $y 40 18 -filled 1
    $pdf setFillColor 0 0 0
    $pdf setFont 10 Helvetica
    $pdf text $label -x 50 -y [expr {$y + 12}]
    incr y 28
}
$pdf endPage
set out [pdf4tcl::doc::outfile howto-colors.pdf]
$pdf write -file $out
$pdf destroy
pdf4tcl::doc::done $out
