#!/usr/bin/env tclsh
# examples/test-transform.tcl -- rotate/scale/translate/getPageSize demo
# Part of pdf4tcl examples test suite (0.9.4.20)

set auto_path [linsert $auto_path 0 \
    [file normalize [file join [file dirname [info script]] ..]]]

package require pdf4tcl

set pi 3.14159265358979
set outfile test-transform.pdf

set pdf [pdf4tcl::new %AUTO% -paper a4 -orient 1 -compress 0]

# ---------------------------------------------------------------------------
# Page 1: translate, rotate, scale
# ---------------------------------------------------------------------------
$pdf startPage
$pdf setFont 12 Helvetica-Bold
$pdf text "rotate / scale / translate (pdf4tcl 0.9.4.20)" -x 50 -y 40

# --- getPageSize ---
$pdf setFont 9 Helvetica
set pmm [pdf4tcl::new %AUTO% -paper a4 -unit mm]
$pmm startPage; set smm [$pmm getPageSize]; $pmm endPage; $pmm destroy
set y 65
$pdf text "getPageSize (mm): [format %.1f [lindex $smm 0]] x [format %.1f [lindex $smm 1]]" \
    -x 50 -y $y; incr y 30

# --- translate ---
$pdf setFont 10 Helvetica-Bold
$pdf text "translate" -x 50 -y $y; incr y 30
$pdf setStrokeColor 0.7 0.7 0.7
$pdf rectangle 60 $y 30 20
$pdf setStrokeColor 0 0 0.8
$pdf gsave
$pdf translate [expr {60 + 50}] $y
$pdf rectangle 0 0 30 20
$pdf grestore
$pdf setStrokeColor 0 0 0
incr y 50

# --- rotate ---
$pdf setFont 10 Helvetica-Bold
$pdf text "rotate" -x 50 -y $y; incr y 20
set cx 120; set cy [expr {$y + 50}]
$pdf setFillColor 0 0 0
$pdf circle $cx $cy 2 -filled 1
foreach deg {0 45 90 135 180 225 270 315} {
    set r [expr {$deg * $pi / 180.0}]
    set c [expr {cos($r)}]; set s [expr {sin($r)}]
    $pdf setStrokeColor [expr {$deg/400.0+0.1}] 0 [expr {1-$deg/400.0}]
    $pdf setLineWidth 1.5
    $pdf gsave
    $pdf translate $cx $cy
    $pdf rotate $deg
    $pdf line 8 0 45 0
    $pdf grestore
}
$pdf setStrokeColor 0 0 0; $pdf setLineWidth 0.5
$pdf setFillColor 0 0 0
incr y 120

# --- scale ---
$pdf setFont 10 Helvetica-Bold
$pdf text "scale" -x 50 -y $y; incr y 50
set sx 55
foreach {sc colr} {0.5 {0.2 0.4 0.8} 1.0 {0.1 0.6 0.2} 1.5 {0.7 0.4 0.1} 2.0 {0.7 0.1 0.1}} {
    lassign $colr r g b
    $pdf setFillColor $r $g $b
    $pdf gsave
    $pdf translate $sx $y
    $pdf scale $sc $sc
    $pdf rectangle 0 0 30 20 -filled 1
    $pdf grestore
    $pdf setFillColor 0 0 0
    incr sx [expr {int(30 * $sc) + 12}]
}
$pdf endPage

# ---------------------------------------------------------------------------
# Page 2: combined
# ---------------------------------------------------------------------------
$pdf startPage
$pdf setFont 12 Helvetica-Bold
$pdf text "Combined: translate + rotate + line" -x 50 -y 40

set cx 200; set cy 200
$pdf setFillColor 0 0 0
$pdf circle $cx $cy 3 -filled 1
for {set i 0} {$i < 12} {incr i} {
    set deg [expr {$i * 30}]
    set t [expr {$i / 12.0}]
    $pdf setStrokeColor $t [expr {0.3+$t*0.3}] [expr {1-$t}]
    $pdf setLineWidth [expr {1 + $i * 0.2}]
    $pdf gsave
    $pdf translate $cx $cy
    $pdf rotate $deg
    $pdf line 10 0 60 0
    $pdf grestore
}
$pdf setStrokeColor 0 0 0; $pdf setLineWidth 0.5
$pdf setFillColor 0 0 0

set cy 420
$pdf setFont 10 Helvetica-Bold
$pdf text "Combined: translate + scale + rectangle" -x 50 -y [expr {$cy - 40}]
set bx 60
foreach {sc r g b} {0.4 0.2 0.5 0.9 0.7 0.1 0.7 0.4 1.0 0.8 0.3 0.1 1.3 0.9 0.1 0.5 1.6 0.1 0.8 0.8} {
    $pdf setFillColor $r $g $b
    $pdf gsave
    $pdf translate $bx $cy
    $pdf scale $sc $sc
    $pdf rectangle 0 0 25 18 -filled 1
    $pdf grestore
    incr bx [expr {int(25 * $sc) + 8}]
}
$pdf setFillColor 0 0 0
$pdf endPage

$pdf write -file $outfile
$pdf destroy
