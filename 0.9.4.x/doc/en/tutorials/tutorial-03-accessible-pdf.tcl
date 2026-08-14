#!/usr/bin/env tclsh
# Runnable companion to tutorial-03-accessible-pdf.md
source [file join [file dirname [info script]] ../_bootstrap.tcl]
pdf4tcl::doc::init [info script]

set font [pdf4tcl::doc::needFont freesans]
pdf4tcl::loadBaseTrueTypeFont BaseFreeSans $font
pdf4tcl::createFont BaseFreeSans Body iso8859-1

set pdf [::pdf4tcl::new %AUTO% -paper a4 -orient 1 -margin 50]
$pdf tagged 1 -lang en-GB -ua 1
$pdf metadata -title "Accessible sample" -author "pdf4tcl tutorial"
$pdf viewerPreferences -displaydoctitle 1

lassign [$pdf getDrawableArea] W H

$pdf startPage

$pdf tagArtifact -type Pagination -subtype Footer
$pdf setFont 8 Body
$pdf text "1" -x [expr {$W - 20}] -y [expr {$H - 4}]
$pdf tagArtifactEnd

$pdf setFont 18 Body
$pdf tagText H1 "Accessible sample" -x 0 -y 24

$pdf setFont 11 Body
$pdf tagBegin P
$pdf text "This paragraph is one structure element." -x 0 -y 50
$pdf tagEnd

$pdf tagBegin P
$pdf text "More on the" -x 0 -y 74
$pdf tagBegin Link -alt "pdf4tcl on GitHub"
$pdf tagText Span "project page" -x 62 -y 74
$pdf hyperlinkAdd 62 65 70 12 "https://github.com/gregnix/pdf4tcl"
$pdf tagEnd
$pdf text "." -x 134 -y 74
$pdf tagEnd

$pdf endPage
set out [pdf4tcl::doc::outfile tutorial-03-accessible.pdf]
$pdf write -file $out
$pdf destroy
pdf4tcl::doc::done $out
if {[llength $::pdf4tcl::warnings]} {
    puts "warnings:"
    foreach w $::pdf4tcl::warnings { puts "  $w" }
}
