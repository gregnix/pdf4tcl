#!/usr/bin/env tclsh
# Runnable companion to tutorial-05-graphics-lab.md
source [file join [file dirname [info script]] ../_bootstrap.tcl]
pdf4tcl::doc::init [info script]

set pdf [::pdf4tcl::new %AUTO% -paper a4 -orient 1 -margin 40]
$pdf startPage

$pdf setFont 16 Helvetica-Bold
$pdf text "Graphics lab" -x 0 -y 24

$pdf setFont 10 Helvetica
$pdf text "Alpha" -x 0 -y 50
$pdf setFillColor 1 0 0
$pdf setAlpha 0.7
$pdf rectangle 0 60 90 50 -filled 1
$pdf setFillColor 0 0 1
$pdf setAlpha 0.5
$pdf rectangle 40 75 90 50 -filled 1
$pdf setAlpha 1.0

$pdf text "Gradient" -x 200 -y 50
$pdf gsave
$pdf clip 200 60 220 50
$pdf linearGradient 200 85 420 85 #ff6600 #3366cc
$pdf grestore
$pdf rectangle 200 60 220 50

$pdf text "Transform (graphics only)" -x 0 -y 160
set cx 120
set cy 280
$pdf setStrokeColor 0.1 0.2 0.5
$pdf setLineWidth 1
for {set deg 0} {$deg < 180} {incr deg 15} {
    $pdf gsave
    $pdf translate $cx $cy
    $pdf rotate $deg
    $pdf line 0 0 70 0
    $pdf grestore
}

$pdf setFillColor 0 0 0
$pdf setFont 9 Helvetica-Oblique
$pdf text "Text itself ignores cm transforms; use translate+rotate around text -x 0 -y 0." \
        -x 0 -y 380

$pdf endPage
set out [pdf4tcl::doc::outfile tutorial-05-graphics.pdf]
$pdf write -file $out
$pdf destroy
pdf4tcl::doc::done $out
