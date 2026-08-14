#!/usr/bin/env tclsh
source [file join [file dirname [info script]] ../_bootstrap.tcl]
pdf4tcl::doc::init [info script]
set pdf [::pdf4tcl::new %AUTO% -paper a4 -orient 1]
set grid [$pdf addLayer "Debug grid" -visible 0]
set body [$pdf addLayer "Body" -visible 1]
$pdf startPage
$pdf beginLayer $grid
$pdf setStrokeColor 0.85 0.85 0.85
for {set x 0} {$x <= 500} {incr x 50} { $pdf line $x 0 $x 700 }
$pdf endLayer
$pdf beginLayer $body
$pdf setFont 12 Helvetica
$pdf text "Visible body text" -x 50 -y 50
$pdf endLayer
$pdf endPage
set out [pdf4tcl::doc::outfile howto-layers.pdf]
$pdf write -file $out
$pdf destroy
pdf4tcl::doc::done $out
