#!/usr/bin/env tclsh
source [file join [file dirname [info script]] ../_bootstrap.tcl]
pdf4tcl::doc::init [info script]
set font [pdf4tcl::doc::needFont dejavu]
pdf4tcl::loadBaseTrueTypeFont BaseDejaVu $font
pdf4tcl::createFontSpecCID BaseDejaVu Uni
set pdf [::pdf4tcl::new %AUTO% -paper a4 -orient 1 -margin 50]
$pdf startPage
$pdf setFont 12 Uni
$pdf text "Zazólc gesla jazn -- Greek -- Russian" -x 0 -y 24
# real unicode:
$pdf text "Za\u017c\u00f3\u0142\u0107 g\u0119\u015bl\u0105 ja\u017a\u0144 -- \u0395\u03bb\u03bb\u03b7\u03bd\u03b9\u03ba\u03ac -- \u0420\u0443\u0441\u0441\u043a\u0438\u0439" -x 0 -y 50
$pdf endPage
set out [pdf4tcl::doc::outfile howto-unicode.pdf]
$pdf write -file $out
$pdf destroy
pdf4tcl::doc::done $out
