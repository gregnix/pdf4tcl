#!/usr/bin/env tclsh
source [file join [file dirname [info script]] ../_bootstrap.tcl]
pdf4tcl::doc::init [info script]
set pdf [::pdf4tcl::new %AUTO% -paper a5 -orient 1 -margin 30]
$pdf startPage
lassign [$pdf getPageSize] w h
$pdf setFont 12 Helvetica
$pdf text "Paper a5: ${w} x ${h}" -x 0 -y 24
$pdf endPage
set out [pdf4tcl::doc::outfile howto-paper-sizes.pdf]
$pdf write -file $out
$pdf destroy
pdf4tcl::doc::done $out
