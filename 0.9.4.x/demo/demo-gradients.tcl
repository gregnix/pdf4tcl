#!/usr/bin/env tclsh
# demo-gradients.tcl -- demonstrate linearGradient, radialGradient, setBlendMode
#
# Usage: tclsh demo-gradients.tcl [outputdir_or_file]

set demodir  [file dirname [file normalize [info script]]]
set reporoot [file normalize [file join $demodir ../..]]
set auto_path [linsert $auto_path 0 $reporoot]

package require pdf4tcl

set outdir  [expr {$argc > 0 ? [lindex $argv 0] : $demodir}]
if {[file isdirectory $outdir]} {
    set outfile [file join $outdir demo-gradients.pdf]
} else {
    set outfile $outdir
}

set pdf [::pdf4tcl::new %AUTO% -paper a4 -orient false -compress 1]

# Helper: zeichnet einen gef\u00FCllten Gradient-Streifen mit Rahmen
# clip x y w h, dann gradient-command als block
proc gradRect {pdf x y w h gradcmd} {
    $pdf gsave
    $pdf clip $x $y $w $h
    uplevel 1 $gradcmd
    $pdf grestore
    $pdf rectangle $x $y $w $h
}

# \u2500\u2500 Page 1: linearGradient \u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500
$pdf startPage

$pdf setFont 14 Helvetica-Bold
$pdf text "linearGradient -- Axial Shading Demo" -x 50 -y 800

$pdf setFont 10 Helvetica

# 1) Horizontal: rot -> blau
$pdf text "1) Horizontal: red -> blue" -x 50 -y 772
gradRect $pdf 50 700 500 60 {$pdf linearGradient 50 730 550 730 red blue}

# 2) Vertikal: gelb -> gruen
$pdf text "2) Vertical: yellow -> green" -x 50 -y 682
gradRect $pdf 50 610 500 60 {$pdf linearGradient 300 610 300 670 yellow green}

# 3) Diagonal: weiss -> schwarz
$pdf text "3) Diagonal: white -> black" -x 50 -y 592
gradRect $pdf 50 520 500 60 {$pdf linearGradient 50 520 550 580 white black}

# 4) Hex-Farben: cyan -> magenta
$pdf text "4) Hex: #00ffff -> #ff00ff" -x 50 -y 502
gradRect $pdf 50 430 500 60 {$pdf linearGradient 50 460 550 460 #00ffff #ff00ff}

# 5) RGB-Tripel: orange -> dunkelblau
$pdf text "5) RGB triple: {1.0 0.5 0.0} -> {0.0 0.1 0.5}" -x 50 -y 412
gradRect $pdf 50 340 500 60 {
    $pdf linearGradient 50 370 550 370 {1.0 0.5 0.0} {0.0 0.1 0.5}
}

# 6) -extend {0 0}: kein Extend ausserhalb Koordinaten
$pdf text "6) -extend {0 0}: gradient stops at boundary (grey outside)" -x 50 -y 322
gradRect $pdf 50 250 500 60 {
    $pdf linearGradient 150 280 450 280 red blue -extend {0 0}
}

# \u2500\u2500 Page 2: radialGradient \u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500
$pdf startPage

$pdf setFont 14 Helvetica-Bold
$pdf text "radialGradient -- Radial Shading Demo" -x 50 -y 800

$pdf setFont 10 Helvetica

# 1) Klassischer Radial: weisses Zentrum -> schwarz
$pdf text "1) White center -> black edge" -x 50 -y 770
gradRect $pdf 50 640 220 120 {$pdf radialGradient 160 700 0 160 700 100 white black}

# 2) Versetztes Innenzentrum
$pdf text "2) Offset inner circle" -x 290 -y 770
gradRect $pdf 290 640 220 120 {$pdf radialGradient 360 700 10 400 700 90 #0066ff white}

# 3) Leuchtender Punkt (dunkler Hintergrund)
$pdf text "3) Glowing dot on dark bg" -x 50 -y 610
$pdf gsave
$pdf clip 50 510 220 90
$pdf setFillColor 0 0 0
$pdf rectangle 50 510 220 90 -filled 1 -stroke 0
$pdf radialGradient 160 555 0 160 555 55 {1.0 0.9 0.5} {0.0 0.0 0.0}
$pdf grestore
$pdf rectangle 50 510 220 90

# 4) Hex-Farben
$pdf text "4) Hex: #ff4400 -> #001144" -x 290 -y 610
gradRect $pdf 290 510 220 90 {$pdf radialGradient 400 555 0 400 555 80 #ff4400 #001144}

# 5) Mehrere Gradienten auf einer Seite (Kreise)
$pdf text "5) Multiple radial gradients" -x 50 -y 490
set pairs {{red blue} {green yellow} {#ff00ff #00ffff} {white black} {#ff6600 #0033cc}}
set xi 75
foreach pair $pairs {
    set c1 [lindex $pair 0]
    set c2 [lindex $pair 1]
    $pdf gsave
    $pdf clip [expr {$xi - 40}] 410 80 80
    $pdf radialGradient $xi 450 0 $xi 450 40 $c1 $c2
    $pdf grestore
    $pdf circle $xi 450 40
    incr xi 105
}

# 6) Grosse Seite: Hintergrundgradient
$pdf text "6) Full-area background gradient" -x 50 -y 370
gradRect $pdf 50 240 500 120 {
    $pdf radialGradient 300 300 10 300 300 280 #fffacc #003366
}
$pdf setFont 18 Helvetica-Bold
$pdf setFillColor 1 1 1
$pdf text "Centered Text" -x 175 -y 292
$pdf setFillColor 0 0 0

# \u2500\u2500 Page 3: setBlendMode \u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500
$pdf startPage

$pdf setFont 14 Helvetica-Bold
$pdf text "setBlendMode -- Blend Mode Demo" -x 50 -y 800
$pdf setFont 9 Helvetica
$pdf text "(Yellow circle @ 85% alpha blended over red->blue linear gradient)" -x 50 -y 783

set modes {Normal Multiply Screen Overlay Darken Lighten
           ColorDodge ColorBurn HardLight SoftLight
           Difference Exclusion Hue Saturation Color Luminosity}

set col 0
set row 0
foreach mode $modes {
    set bx [expr {50  + $col * 260}]
    set by [expr {755 - $row * 115}]
    set bw 240
    set bh 95

    # Label
    $pdf setFont 9 Helvetica-Bold
    $pdf text $mode -x $bx -y [expr {$by + 3}]

    # Hintergrund: horizontaler roter -> blauer Gradient
    $pdf gsave
    $pdf clip $bx [expr {$by - $bh + 10}] $bw [expr {$bh - 10}]
    $pdf linearGradient $bx [expr {$by - 40}] [expr {$bx + $bw}] [expr {$by - 40}] red blue
    $pdf grestore

    # Vordergrund: gelber Kreis mit Blend Mode
    $pdf gsave
    $pdf setBlendMode $mode
    $pdf setAlpha 0.85
    $pdf setFillColor 1.0 1.0 0.0
    $pdf circle [expr {$bx + 100}] [expr {$by - 40}] 35 -filled 1
    $pdf setBlendMode Normal
    $pdf setAlpha 1.0
    $pdf grestore

    # Rahmen
    $pdf rectangle $bx [expr {$by - $bh + 10}] $bw [expr {$bh - 10}]

    incr col
    if {$col >= 2} { set col 0; incr row }
}

# \u2500\u2500 Ausgabe \u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500
$pdf write -file $outfile
$pdf destroy
puts "Written: $outfile"
