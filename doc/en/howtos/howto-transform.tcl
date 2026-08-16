#!/usr/bin/env tclsh
source [file join [file dirname [info script]] ../_bootstrap.tcl]
pdf4tcl::doc::init [info script]
set pdf [::pdf4tcl::new %AUTO% -paper a4 -orient 1 -margin 50]
$pdf startPage
$pdf setFont 12 Helvetica
$pdf text "rotate/scale/translate" -x 0 -y 24
lassign [$pdf getPageSize] w h
$pdf text "page size: $w x $h" -x 0 -y 44
$pdf setStrokeColor 0 0 0.6
for {set deg 0} {$deg < 360} {incr deg 30} {
    $pdf gsave
    $pdf translate 200 200
    $pdf rotate $deg
    $pdf line 0 0 60 0
    $pdf grestore
}
$pdf gsave
$pdf translate 100 320
$pdf rotate 90
$pdf setFillColor 0 0 0
$pdf text "Sideways" -x 0 -y 0
$pdf grestore
$pdf endPage
set out [pdf4tcl::doc::outfile howto-transform.pdf]
$pdf write -file $out
$pdf destroy
pdf4tcl::doc::done $out
