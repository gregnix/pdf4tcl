#!/usr/bin/env tclsh
# How-to: standard ligatures.
#
# Shows the switch, what it does to a word, and -- the part that matters --
# that the text is still searchable afterwards.

source [file join [file dirname [info script]] ../_bootstrap.tcl]
pdf4tcl::doc::init [info script]

# A face with Latin ligatures. Not every face has them where one expects:
# DejaVu Sans has an Arabic liga feature and no fi glyph at all.
set fontFile ""
foreach k {
    /usr/share/fonts/truetype/crosextra/Carlito-Regular.ttf
    /usr/share/fonts/truetype/crosextra/Caladea-Regular.ttf
} {
    if {[file readable $k]} { set fontFile $k; break }
}
if {$fontFile eq ""} {
    set fontFile [pdf4tcl::doc::needFont freesans]
}
pdf4tcl::loadBaseTrueTypeFont BaseLiga $fontFile
pdf4tcl::createFontSpecCID BaseLiga LigaFont

set pdf [::pdf4tcl::new %AUTO% -paper a4 -margin 50]
$pdf startPage

set probe "Auflage finden, offiziell"

$pdf setFont 14 Helvetica-Bold
$pdf text "Standard ligatures" -x 0 -y 20

$pdf setFont 22 LigaFont
$pdf setLigatures 0
$pdf text $probe -x 0 -y 70
$pdf setFont 9 Helvetica
$pdf text "setLigatures 0 (default)" -x 0 -y 90

$pdf setFont 22 LigaFont
$pdf setLigatures 1
$pdf text $probe -x 0 -y 130
$pdf setFont 9 Helvetica
$pdf text "setLigatures 1 -- fl and fi are single glyphs" -x 0 -y 150

# How many glyphs each version needs. Same text, fewer glyphs.
$pdf setLigatures 0
set plain [pdf4tcl::CIDEncodeText "Auflage" LigaFont]
set ligated [pdf4tcl::CIDEncodeText "Auflage" LigaFont 1]
$pdf setFont 10 Helvetica
$pdf text "\"Auflage\": [expr {([string length $plain] - 2) / 4}] glyphs plain,\
        [expr {([string length $ligated] - 2) / 4}] with ligatures" -x 0 -y 190

$pdf setFont 10 Helvetica
$pdf text "The text stays searchable: the ToUnicode CMap records both" -x 0 -y 230
$pdf text "characters a ligature stands for. Run pdftotext over this file" -x 0 -y 246
$pdf text "and the words come back whole." -x 0 -y 262

set out [pdf4tcl::doc::outfile howto-ligatures.pdf]
$pdf write -file $out
pdf4tcl::doc::done $out
$pdf destroy
