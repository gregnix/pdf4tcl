#!/usr/bin/env tclsh
source [file join [file dirname [info script]] ../_bootstrap.tcl]
pdf4tcl::doc::init [info script]
set pdf [::pdf4tcl::new %AUTO% -paper a4 -orient 1]
$pdf startPage
$pdf setFont 12 Helvetica
$pdf text "streamed via write -chan" -x 50 -y 50
$pdf endPage
set out [pdf4tcl::doc::outfile howto-write-chan.pdf]
set ch [open $out wb]
$pdf write -chan $ch
close $ch
$pdf destroy
pdf4tcl::doc::done $out
