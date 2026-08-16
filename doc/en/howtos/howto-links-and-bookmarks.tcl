#!/usr/bin/env tclsh
source [file join [file dirname [info script]] ../_bootstrap.tcl]
pdf4tcl::doc::init [info script]
set pdf [::pdf4tcl::new %AUTO% -paper a4 -orient 1 -margin 50]
$pdf startPage
$pdf setFont 14 Helvetica-Bold
$pdf text "Chapter 1" -x 0 -y 24
$pdf bookmarkAdd -title "Chapter 1" -level 0
$pdf setFont 11 Helvetica
$pdf text "Visit tcl.tk" -x 0 -y 50
$pdf hyperlinkAdd 0 40 50 14 "https://www.tcl.tk" -borderwidth 1 -bordercolor {0 0 1}
$pdf endPage
$pdf startPage
$pdf setFont 12 Helvetica-Bold
$pdf text "Section 1.1" -x 0 -y 24
$pdf bookmarkAdd -title "Section 1.1" -level 1
$pdf endPage
set out [pdf4tcl::doc::outfile howto-links-bookmarks.pdf]
$pdf write -file $out
$pdf destroy
pdf4tcl::doc::done $out
