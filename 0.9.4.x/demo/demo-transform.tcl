#!/usr/bin/env tclsh
# demo-transform.tcl -- demonstrate rotate/scale/translate, getPageSize (0.9.4.20)
#
# rotate/scale/translate work on graphics operators (line, rectangle etc.).
# Text uses absolute Tm positioning and is not affected by cm transforms.
# For text rotation/scaling, use pdf4tcllib::drawing::textRotated etc.
#
# Usage: tclsh demo-transform.tcl [outputdir]

set demodir  [file dirname [file normalize [info script]]]
set reporoot [file normalize [file join $demodir ../..]]
set auto_path [linsert $auto_path 0 $reporoot]

package require pdf4tcl

set outdir [expr {$argc > 0 ? [lindex $argv 0] : [file join $demodir out]}]
file mkdir $outdir
set outfile [file join $outdir demo-transform.pdf]

set pi 3.14159265358979

set pdf [pdf4tcl::new %AUTO% -paper a4 -orient 1 -compress 0]

# ---------------------------------------------------------------------------
# Page 1: getPageSize + translation + rotation + scaling
# ---------------------------------------------------------------------------
$pdf startPage

$pdf setFont 14 Helvetica-Bold
$pdf text "rotate / scale / translate / getPageSize (0.9.4.20)" -x 50 -y 40

# --- getPageSize ---
$pdf setFont 9 Helvetica
set ppts [pdf4tcl::new %AUTO% -paper a4 -unit p]
$ppts startPage; set spts [$ppts getPageSize]; $ppts endPage; $ppts destroy
set pmm  [pdf4tcl::new %AUTO% -paper a4 -unit mm]
$pmm  startPage; set smm  [$pmm  getPageSize]; $pmm  endPage; $pmm  destroy

set y 65
$pdf setFont 10 Helvetica-Bold
$pdf text "getPageSize" -x 50 -y $y; incr y 14
$pdf setFont 9 Helvetica
$pdf text "  Points: [lindex $spts 0] x [lindex $spts 1] pt" -x 50 -y $y; incr y 13
$pdf text "  mm:     [format %.1f [lindex $smm 0]] x [format %.1f [lindex $smm 1]] mm" \
    -x 50 -y $y; incr y 13
$pdf text "  (A4 spec: 210.0 x 297.0 mm)" -x 50 -y $y; incr y 25

# --- Translation: move a rectangle ---
$pdf setFont 10 Helvetica-Bold
$pdf text "translate: moves the coordinate origin" -x 50 -y $y; incr y 15
$pdf setFont 8 Helvetica

# Draw rectangles, label to the RIGHT of each
# Row 1: origin + +50pt X
$pdf setStrokeColor 0.7 0.7 0.7
$pdf rectangle 60 $y 30 20
$pdf setStrokeColor 0 0 0
$pdf text "origin" -x 100 -y [expr {$y + 12}]

$pdf setStrokeColor 0 0 0.8
$pdf gsave
$pdf translate [expr {80 + 50}] [expr {$y + 20}]
$pdf rectangle 0 0 30 20
$pdf grestore
$pdf setStrokeColor 0 0 0
$pdf text "+50pt X" -x [expr {80+50+32}] -y [expr {$y +12}]

# Row 2: +35pt Y + +50ptX+35ptY
incr y 40
$pdf setStrokeColor 0 0.6 0
$pdf gsave
$pdf translate 60 $y
$pdf rectangle 0 0 30 20
$pdf grestore
$pdf setStrokeColor 0 0 0
$pdf text "+35pt Y" -x 100 -y [expr {$y -6}]

$pdf setStrokeColor 0.7 0 0
$pdf gsave
$pdf translate [expr {80 + 50}] $y
$pdf rectangle 0 0 30 20
$pdf grestore
$pdf setStrokeColor 0 0 0
$pdf text "+50pt X +35pt Y" -x [expr {80+50+32}] -y [expr {$y -6 }]
incr y 40

# --- Rotation: rotate lines around a center point ---
$pdf setFont 10 Helvetica-Bold
$pdf text "rotate: rotates graphics around the current origin" -x 50 -y $y; incr y 15

set cx 150; set cy [expr {$y + 55}]
# center dot
$pdf setFillColor 0 0 0
$pdf circle $cx $cy 2 -filled 1

foreach deg {0 30 60 90 120 150 180 210 240 270 300 330} {
    set gray [expr {$deg / 400.0 + 0.1}]
    $pdf setStrokeColor $gray 0 [expr {1.0 - $gray}]
    $pdf setLineWidth 1.5
    $pdf gsave
    $pdf translate $cx $cy
    $pdf rotate $deg
    # Draw a line outward from origin (works correctly with rotate)
    $pdf line 5 0 45 0
    $pdf grestore
}
$pdf setStrokeColor 0 0 0
$pdf setLineWidth 0.5
$pdf setFillColor 0 0 0
$pdf setFont 8 Helvetica
$pdf text "Lines rotated 0-330 deg" -x [expr {$cx + 55}] -y [expr {$cy - 5}]
incr y 130

# --- Scaling: scale rectangles ---
$pdf setFont 10 Helvetica-Bold
$pdf text "scale: scales graphics" -x 50 -y $y; incr y 35
$pdf setFont 8 Helvetica

# Rectangles with labels to the right
set startx 55
foreach {sc label colr} {
    0.5  "0.5x"       {0.2 0.4 0.8}
    1.0  "1.0x"       {0.1 0.6 0.2}
    1.5  "1.5x"       {0.7 0.4 0.1}
    2.0  "2.0x"       {0.7 0.1 0.1}
} {
    lassign $colr r g b
    set rh [expr {int(20 * $sc)}]
    set rw [expr {int(30 * $sc)}]
    $pdf setFillColor $r $g $b
    $pdf gsave
    $pdf translate $startx $y
    $pdf scale $sc $sc
    $pdf rectangle 0 0 30 20 -filled 1
    $pdf grestore
    $pdf setFillColor 0 0 0
    # Label below rectangle (at y + rect_height + 5)
    $pdf text $label -x $startx -y [expr {$y + $rh + 8}]
    incr startx [expr {$rw + 15}]
}

$pdf endPage

# ---------------------------------------------------------------------------
# Page 2: combined + note about text
# ---------------------------------------------------------------------------
$pdf startPage

$pdf setFont 14 Helvetica-Bold
$pdf text "Combined + Important Note" -x 50 -y 40

# Note about text
$pdf setFont 9 Helvetica
$pdf setFillColor 0.5 0 0
set y 65
$pdf text "Note: rotate/scale/translate affect graphics (line, rectangle, circle)." \
    -x 50 -y $y; incr y 13
$pdf text "Text uses absolute positioning (Tm operator) and is NOT affected by cm transforms." \
    -x 50 -y $y; incr y 13
$pdf text "For rotated text, use pdf4tcllib::drawing::textRotated." \
    -x 50 -y $y; incr y 25
$pdf setFillColor 0 0 0

# Combined: star pattern with rotated lines
$pdf setFont 10 Helvetica-Bold
$pdf text "Combined: translate + rotate + line" -x 50 -y $y; incr y 15

set cx 160; set cy [expr {$y + 70}]
$pdf setFillColor 0 0 0
$pdf circle $cx $cy 3 -filled 1

for {set i 0} {$i < 12} {incr i} {
    set deg [expr {$i * 30}]
    set t [expr {$i / 12.0}]
    $pdf setStrokeColor $t [expr {0.3+$t*0.4}] [expr {1-$t}]
    $pdf setLineWidth [expr {1 + $i * 0.3}]
    $pdf gsave
    $pdf translate $cx $cy
    $pdf rotate $deg
    $pdf line 10 0 60 0
    $pdf grestore
}
$pdf setStrokeColor 0 0 0
$pdf setLineWidth 0.5
$pdf setFont 8 Helvetica
$pdf text "12 lines: translate(cx,cy) + rotate(i*30) + line(10,0,60,0)" \
    -x 50 -y [expr {$cy + 85}]

# Nested scaling
incr cy 180
$pdf setFont 10 Helvetica-Bold
$pdf text "Combined: translate + scale + rectangle" -x 50 -y [expr {$cy - 50}]
set bx 60
foreach {sc r g b} {
    0.4 0.2 0.5 0.9
    0.7 0.1 0.7 0.4
    1.0 0.8 0.3 0.1
    1.3 0.9 0.1 0.5
    1.6 0.1 0.8 0.8
} {
    $pdf setFillColor $r $g $b
    $pdf gsave
    $pdf translate $bx $cy
    $pdf scale $sc $sc
    $pdf rectangle 0 0 25 18 -filled 1
    $pdf grestore
    incr bx [expr {int(25 * $sc) + 10}]
}
$pdf setFillColor 0 0 0

$pdf endPage

$pdf write -file $outfile
$pdf destroy
puts "Written: $outfile"
