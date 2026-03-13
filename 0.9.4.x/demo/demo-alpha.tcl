#!/usr/bin/env tclsh
# demo-alpha.tcl -- demonstrate setAlpha (fill/stroke opacity)
#
# Usage: tclsh demo-alpha.tcl [outputfile.pdf]

set demodir  [file dirname [file normalize [info script]]]
set reporoot [file normalize [file join $demodir ../..]]
set auto_path [linsert $auto_path 0 $reporoot]

package require pdf4tcl

set outdir  [expr {$argc > 0 ? [lindex $argv 0] : $demodir}]
if {[file isdirectory $outdir]} {
    set outfile [file join $outdir demo-alpha.pdf]
} else {
    set outfile $outdir
}

set pdf [::pdf4tcl::new %AUTO% -paper a4 -orient false -compress 1]
$pdf startPage

$pdf setFont 14 Helvetica-Bold
$pdf text "setAlpha -- Transparency Demo" -x 50 -y 780

# -----------------------------------------------------------------------
# Section 1: Overlapping rectangles with different fill alpha
# -----------------------------------------------------------------------
$pdf setFont 11 Helvetica
$pdf text "1) Overlapping rectangles -- fill alpha 1.0 / 0.6 / 0.3" -x 50 -y 755

# opaque red
$pdf setFillColor 1 0 0
$pdf setAlpha 1.0
$pdf rectangle 60  700 120 60 -filled 1

# semi-transparent green
$pdf setFillColor 0 0.7 0
$pdf setAlpha 0.6
$pdf rectangle 120 700 120 60 -filled 1

# very transparent blue
$pdf setFillColor 0 0 1
$pdf setAlpha 0.3
$pdf rectangle 180 700 120 60 -filled 1

# -----------------------------------------------------------------------
# Section 2: Gradient-like row of same color with decreasing alpha
# -----------------------------------------------------------------------
$pdf setAlpha 1.0
$pdf setFont 11 Helvetica
$pdf text "2) Same color (blue), alpha steps 1.0 -> 0.1" -x 50 -y 680

set x 60
for {set i 10} {$i >= 1} {incr i -1} {
    set a [expr {$i / 10.0}]
    $pdf setFillColor 0 0 0.8
    $pdf setAlpha $a
    $pdf rectangle $x 620 36 50 -filled 1
    incr x 38
}

# -----------------------------------------------------------------------
# Section 3: Fill vs stroke alpha independently
# -----------------------------------------------------------------------
$pdf setAlpha 1.0
$pdf text "3) Fill alpha 0.4, stroke alpha 1.0 -- thick border visible" -x 50 -y 605

$pdf setFillColor 1 0.5 0
$pdf setStrokeColor 0 0 0
$pdf setAlpha 0.4 -fill
$pdf setAlpha 1.0 -stroke
$pdf setLineStyle 3
$pdf rectangle 60 540 180 50 -filled 1 -stroke 1

# -----------------------------------------------------------------------
# Section 4: Text with alpha
# -----------------------------------------------------------------------
$pdf setAlpha 1.0
$pdf setLineStyle 1
$pdf text "4) Text with fill alpha 0.5" -x 50 -y 525

$pdf setFont 36 Helvetica-Bold
$pdf setFillColor 0 0 0
$pdf setAlpha 0.5
$pdf text "Semi-transparent" -x 60 -y 480

# -----------------------------------------------------------------------
# Section 5: gsave / grestore restores alpha
# -----------------------------------------------------------------------
$pdf setAlpha 1.0
$pdf setFont 11 Helvetica
$pdf text "5) gsave/grestore restores alpha (left=0.3, right=1.0 after restore)" -x 50 -y 455

$pdf setFillColor 0.6 0 0.6
$pdf setAlpha 0.3
$pdf gsave
$pdf rectangle 60 390 100 50 -filled 1
$pdf grestore
# alpha is restored to 1.0 here
$pdf rectangle 180 390 100 50 -filled 1

$pdf endPage
$pdf write -file $outfile
$pdf destroy

puts "Written: $outfile"
