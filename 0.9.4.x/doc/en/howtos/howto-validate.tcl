#!/usr/bin/env tclsh
source [file join [file dirname [info script]] ../_bootstrap.tcl]
pdf4tcl::doc::init [info script]
set font [pdf4tcl::doc::needFont freesans]
pdf4tcl::loadBaseTrueTypeFont BaseFreeSans $font
pdf4tcl::createFont BaseFreeSans Body iso8859-1
set pdf [::pdf4tcl::new %AUTO% -paper a4 -orient 1 -margin 50]
$pdf tagged 1 -lang en-GB -ua 1
$pdf metadata -title "Validate me" -author "pdf4tcl"
$pdf viewerPreferences -displaydoctitle 1
$pdf startPage
$pdf setFont 12 Body
$pdf tagText H1 "Validate" -x 0 -y 24
$pdf tagBegin P
$pdf text "Run qpdf / veraPDF / check-tagged.py on this file." -x 0 -y 50
$pdf tagEnd
$pdf endPage
set out [pdf4tcl::doc::outfile howto-validate.pdf]
$pdf write -file $out
$pdf destroy
pdf4tcl::doc::done $out
puts "Suggested checks:"
puts "  qpdf --check $out"
puts "  verapdf -f ua1 $out"
puts "  python3 [file join $::pdf4tcl::doc::reporoot tools check-tagged.py] $out"
