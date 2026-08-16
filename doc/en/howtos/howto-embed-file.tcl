#!/usr/bin/env tclsh
source [file join [file dirname [info script]] ../_bootstrap.tcl]
pdf4tcl::doc::init [info script]
set font [pdf4tcl::doc::needFont freesans]
pdf4tcl::loadBaseTrueTypeFont BaseFreeSans $font
pdf4tcl::createFont BaseFreeSans Body iso8859-1
set pdf [::pdf4tcl::new %AUTO% -paper a4 -orient 1 -pdfa 3b]
$pdf metadata -title "With attachment"
$pdf startPage
$pdf setFont 12 Body
$pdf text "Human-readable page; notes.txt is embedded." -x 50 -y 50
$pdf endPage
$pdf addEmbeddedFile "notes.txt" \
        -contents "plain attachment\n" \
        -mimetype "text/plain" \
        -description "Side notes" \
        -afrelationship Data
set out [pdf4tcl::doc::outfile howto-embed-file.pdf]
$pdf write -file $out
$pdf destroy
pdf4tcl::doc::done $out
