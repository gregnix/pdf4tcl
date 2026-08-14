#!/usr/bin/env tclsh
source [file join [file dirname [info script]] ../_bootstrap.tcl]
pdf4tcl::doc::init [info script]
set otf ""
foreach c {
    /usr/share/fonts/opentype/freefont/FreeSans.otf
    /usr/share/fonts/opentype/tlwg/Loma.otf
    /usr/share/fonts/opentype/urw-base35/NimbusSans-Regular.otf
} {
    if {[file exists $c]} { set otf $c; break }
}
if {$otf eq ""} {
    puts "SKIP howto-otf: no OTF font found (pass system OTF or install fonts)"
    exit 0
}
pdf4tcl::loadBaseTrueTypeFont BaseOtf $otf
pdf4tcl::createFontSpecCID BaseOtf Uni
set pdf [::pdf4tcl::new %AUTO% -paper a4 -orient 1 -margin 50]
$pdf startPage
$pdf setFont 14 Uni
$pdf text "OTF/CFF via loadBaseTrueTypeFont" -x 0 -y 24
$pdf setFont 10 Helvetica
$pdf text "font: $otf" -x 0 -y 50
$pdf endPage
set out [pdf4tcl::doc::outfile howto-otf.pdf]
$pdf write -file $out
$pdf destroy
pdf4tcl::doc::done $out
