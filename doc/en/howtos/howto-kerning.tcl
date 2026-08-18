#!/usr/bin/env tclsh
# How-to: pair kerning.
#
# Shows the three levels, what they do to a line, and how to check that
# measuring and drawing agree.

source [file join [file dirname [info script]] ../_bootstrap.tcl]
pdf4tcl::doc::init [info script]

# A face that carries kern pairs. FreeSans has 464 in its kern table,
# DejaVu Sans 2727.
set fontFile [pdf4tcl::doc::needFont freesans]
pdf4tcl::loadBaseTrueTypeFont BaseKern $fontFile
pdf4tcl::createFontSpecCID BaseKern KernFont

set pdf [::pdf4tcl::new %AUTO% -paper a4 -margin 50]
$pdf startPage

set probe "AVATAR Wave To Ty."

$pdf setFont 14 Helvetica-Bold
$pdf text "Pair kerning" -x 0 -y 20

# --- 1. embedded face, the default ----------------------------------------
$pdf setFont 20 KernFont
$pdf setKerning 0
$pdf text $probe -x 0 -y 70
$pdf setFont 9 Helvetica
$pdf text "setKerning 0 -- [format %.2f [$pdf getStringWidth $probe]] pt" \
        -x 0 -y 88

$pdf setFont 20 KernFont
$pdf setKerning 1
$pdf text $probe -x 0 -y 120
$pdf setFont 9 Helvetica
$pdf text "setKerning 1 (default) -- [format %.2f [$pdf getStringWidth $probe]] pt" \
        -x 0 -y 138

# --- 2. a standard font, which needs "all" ---------------------------------
$pdf setFont 20 Helvetica
$pdf setKerning 1
$pdf text $probe -x 0 -y 180
$pdf setFont 9 Helvetica
$pdf text "Helvetica, setKerning 1 -- unchanged, [format %.2f \
        [$pdf getStringWidth $probe]] pt" -x 0 -y 198

$pdf setFont 20 Helvetica
if {[catch {$pdf setKerning all} err]} {
    $pdf setFont 9 Helvetica
    $pdf text "setKerning all not available: $err" -x 0 -y 240
} else {
    $pdf text $probe -x 0 -y 240
    $pdf setFont 9 Helvetica
    $pdf text "Helvetica, setKerning all -- [format %.2f \
            [$pdf getStringWidth $probe]] pt" -x 0 -y 258
    $pdf setKerning 1
}

# --- 3. measuring and drawing agree ----------------------------------------
#
# Right-align a string: pdf4tcl subtracts the measured width from the
# anchor. If the measurement did not include kerning, the drawn line would
# end past the anchor -- the rule below makes that visible.
set anchor [lindex [$pdf getDrawableArea] 0]
$pdf setFont 20 KernFont
$pdf text $probe -x $anchor -y 320 -align right
$pdf setLineWidth 0.5
$pdf line $anchor 300 $anchor 330
$pdf setFont 9 Helvetica
$pdf text "right-aligned on the rule: the line ends exactly there" \
        -x 0 -y 345

$pdf write -file [pdf4tcl::doc::outfile howto-kerning.pdf]
pdf4tcl::doc::done [pdf4tcl::doc::outfile howto-kerning.pdf]
$pdf destroy
