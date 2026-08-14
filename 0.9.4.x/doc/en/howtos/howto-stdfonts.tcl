#!/usr/bin/env tclsh
source [file join [file dirname [info script]] ../_bootstrap.tcl]
pdf4tcl::doc::init [info script]
set pdf [::pdf4tcl::new %AUTO% -paper a4 -orient 1 -margin 50]
$pdf startPage
$pdf setFont 18 Helvetica-Bold
$pdf text "Title" -x 0 -y 24
$pdf setFont 12 Times-Roman
$pdf text "Body with umlauts: ae oe ue" -x 0 -y 50
$pdf text "äöü ÄÖÜ ß" -x 0 -y 70
$pdf setFont 10 Courier
$pdf text "mono 0123456789" -x 0 -y 95
$pdf endPage
set out [pdf4tcl::doc::outfile howto-stdfonts.pdf]
$pdf write -file $out
$pdf destroy
pdf4tcl::doc::done $out
