#!/usr/bin/env tclsh
source [file join [file dirname [info script]] ../_bootstrap.tcl]
pdf4tcl::doc::init [info script]
set font [pdf4tcl::doc::needFont freesans]
pdf4tcl::loadBaseTrueTypeFont BaseFreeSans $font
pdf4tcl::createFont BaseFreeSans Body iso8859-1

# 2b sample
set pdf [::pdf4tcl::new %AUTO% -paper a4 -orient 1 -margin 50 -pdfa 2b]
$pdf metadata -title "Archive sample 2b" -author "pdf4tcl"
$pdf startPage
$pdf setFont 12 Body
$pdf text "This file claims PDF/A-2b." -x 0 -y 24
$pdf endPage
set out2 [pdf4tcl::doc::outfile howto-pdfa-2b.pdf]
$pdf write -file $out2
$pdf destroy
pdf4tcl::doc::done $out2

# 3a sample (tagged + lang)
set pdf [::pdf4tcl::new %AUTO% -paper a4 -orient 1 -margin 50 -pdfa 3a]
$pdf tagged 1 -lang en-GB -ua 1
$pdf metadata -title "Accessible archive" -author "pdf4tcl"
$pdf viewerPreferences -displaydoctitle 1
$pdf startPage
$pdf setFont 12 Body
$pdf tagText H1 "Title" -x 0 -y 24
$pdf tagBegin P
$pdf text "Tagged body text." -x 0 -y 50
$pdf tagEnd
$pdf endPage
set out3 [pdf4tcl::doc::outfile howto-pdfa-3a.pdf]
$pdf write -file $out3
$pdf destroy
pdf4tcl::doc::done $out3
if {[llength $::pdf4tcl::warnings]} {
    foreach w $::pdf4tcl::warnings { puts "warning: $w" }
}
