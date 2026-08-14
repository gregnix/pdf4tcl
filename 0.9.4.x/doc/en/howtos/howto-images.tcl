#!/usr/bin/env tclsh
source [file join [file dirname [info script]] ../_bootstrap.tcl]
pdf4tcl::doc::init [info script]
set png [file join [file dirname [info script]] _sample.png]
set pdf [::pdf4tcl::new %AUTO% -paper a4 -orient 1 -margin 50]
$pdf startPage
$pdf setFont 12 Helvetica
$pdf text "addImage / putImage" -x 0 -y 24
set id [$pdf addImage $png]
$pdf putImage $id 0 40 -width 120
$pdf endPage
set out [pdf4tcl::doc::outfile howto-images.pdf]
$pdf write -file $out
$pdf destroy
pdf4tcl::doc::done $out
