#!/usr/bin/env tclsh
source [file join [file dirname [info script]] ../_bootstrap.tcl]
pdf4tcl::doc::init [info script]
set font [pdf4tcl::doc::needFont dejavu]
pdf4tcl::loadBaseTrueTypeFont BaseDejaVu $font
pdf4tcl::createFontSpecCID BaseDejaVu Uni
set pdf [::pdf4tcl::new %AUTO% -paper a4 -orient 1 -margin 50]
$pdf startPage
$pdf setFont 14 Uni
$pdf text "Symbol sample" -x 0 -y 24
$pdf setFont 16 Uni
$pdf text "\u2211 \u222b \u2192 \u2605 \u2500 \u2502 \u03b1 \u03b2 \u042f" -x 0 -y 60
$pdf setFont 10 Helvetica
$pdf text "substCount=[$pdf getSubstCount]" -x 0 -y 90
$pdf endPage
set out [pdf4tcl::doc::outfile howto-symbols.pdf]
$pdf write -file $out
$pdf destroy
pdf4tcl::doc::done $out
