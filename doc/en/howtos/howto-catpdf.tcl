#!/usr/bin/env tclsh
source [file join [file dirname [info script]] ../_bootstrap.tcl]
pdf4tcl::doc::init [info script]
set font [pdf4tcl::doc::needFont freesans]
pdf4tcl::loadBaseTrueTypeFont BaseFreeSans $font
pdf4tcl::createFont BaseFreeSans Body iso8859-1

proc onePart {path title} {
    set pdf [::pdf4tcl::new %AUTO% -paper a4 -orient 1 -margin 50]
    $pdf tagged 1 -lang en-GB -ua 1
    $pdf metadata -title $title -author "pdf4tcl"
    $pdf viewerPreferences -displaydoctitle 1
    $pdf startPage
    $pdf setFont 14 Body
    $pdf tagText H1 $title -x 0 -y 24
    $pdf tagBegin P
    $pdf text "Content of $title." -x 0 -y 50
    $pdf tagEnd
    $pdf endPage
    $pdf write -file $path
    $pdf destroy
}

set a [pdf4tcl::doc::outfile howto-catpdf-a.pdf]
set b [pdf4tcl::doc::outfile howto-catpdf-b.pdf]
set out [pdf4tcl::doc::outfile howto-catpdf-merged.pdf]
onePart $a "Part 1"
onePart $b "Part 2"
set ::pdf4tcl::warnings {}
pdf4tcl::catPdf $a $b $out
pdf4tcl::doc::done $out
if {[llength $::pdf4tcl::warnings]} {
    foreach w $::pdf4tcl::warnings { puts "warning: $w" }
}
