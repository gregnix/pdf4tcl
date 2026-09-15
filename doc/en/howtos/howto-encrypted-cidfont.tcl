#!/usr/bin/env tclsh
# Verschluesseltes PDF mit eigener, eingebetteter Schrift.
#
# Bis 0.9.4.66 entstand hier eine Datei, die ohne Kennwort dicht war und
# sich MIT Kennwort ebenfalls nicht lesen liess -- die Schriftobjekte
# gingen an der Verschluesselung vorbei. Seit .67 ist nichts Besonderes
# zu tun.
source [file join [file dirname [info script]] ../_bootstrap.tcl]
pdf4tcl::doc::init [info script]

# Eine Schrift suchen, die auf dieser Maschine da ist.
set kandidaten {
    /usr/share/fonts/truetype/dejavu/DejaVuSans.ttf
    /usr/share/fonts/dejavu/DejaVuSans.ttf
    C:/Windows/Fonts/arial.ttf
}
set ttf ""
foreach k $kandidaten { if {[file readable $k]} { set ttf $k ; break } }

set pdf [::pdf4tcl::new %AUTO% -paper a4 \
        -userpassword "open-me" -ownerpassword "change-me" \
        -permissions {print}]
$pdf startPage

if {$ttf ne ""} {
    pdf4tcl::loadBaseTrueTypeFont HowtoEncBase $ttf
    pdf4tcl::createFontSpecCID HowtoEncBase HowtoEncUni
    $pdf setFont 14 HowtoEncUni
    $pdf text "Grüße aus München - eingebettete Schrift" -x 50 -y 750
    $pdf setFont 9 Helvetica
    $pdf text "Schrift: [file tail $ttf]" -x 50 -y 725
} else {
    $pdf setFont 14 Helvetica
    $pdf text "No TrueType font found - standard font used" -x 50 -y 750
}

$pdf setFont 10 Helvetica
$pdf text "Password: open-me   Permissions: print only" -x 50 -y 690
$pdf text "Check it:" -x 50 -y 665
$pdf text "  qpdf --password=open-me --check <file>" -x 50 -y 650
$pdf text "  pdftotext -upw open-me <file> -" -x 50 -y 635
$pdf endPage

set out [pdf4tcl::doc::outfile howto-encrypted-cidfont.pdf]
$pdf write -file $out
$pdf destroy
pdf4tcl::doc::done $out
