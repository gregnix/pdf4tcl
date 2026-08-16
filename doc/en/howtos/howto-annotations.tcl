#!/usr/bin/env tclsh
source [file join [file dirname [info script]] ../_bootstrap.tcl]
pdf4tcl::doc::init [info script]
set pdf [::pdf4tcl::new %AUTO% -paper a4 -orient 1 -margin 50]
$pdf startPage
$pdf setFont 12 Helvetica
$pdf text "Annotation samples" -x 0 -y 24
$pdf addAnnotNote 20 40 20 20 -content "Review this" -author "Editor" \
        -icon Comment -color {0.6 0.8 1.0}
$pdf addAnnotFreeText 50 80 200 40 "Always visible" -color {0 0 0} -bgcolor {1 1 0.8}
$pdf addAnnotStamp 280 80 80 30 -name Approved -color {1 0 0}
$pdf text "Marked line of text for highlight" -x 0 -y 160
$pdf addAnnotHighlight 0 148 200 14 -color {1 1 0}
$pdf addAnnotUnderline 0 175 200 14
$pdf addAnnotStrikeOut 0 195 200 14 -color {1 0 0}
$pdf addAnnotLine 0 230 200 230 -color {0 0 0}
$pdf endPage
set out [pdf4tcl::doc::outfile howto-annotations.pdf]
$pdf write -file $out
$pdf destroy
pdf4tcl::doc::done $out
