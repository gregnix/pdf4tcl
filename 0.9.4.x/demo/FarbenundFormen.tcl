#!/usr/bin/env tclsh
set demodir  [file dirname [file normalize [info script]]]
set reporoot [file normalize [file join $demodir ../..]]
set auto_path [linsert $auto_path 0 $reporoot]

package require pdf4tcl

# Resolve exact file and version of loaded pdf4tcl
set pkgfile [lindex [package ifneeded pdf4tcl [package require pdf4tcl]] end]
set pkgver  [package require pdf4tcl]

set outfile [file join $demodir farbenundFormen.pdf]

puts "Written: $outfile"
puts "Package: pdf4tcl $pkgver"
puts "File:    $pkgfile"

set pdf [::pdf4tcl::new %AUTO% -paper a4 -orient true]
$pdf startPage

# Farbiger Text
$pdf setFont 16 Helvetica-Bold
$pdf setFillColor 0.8 0.0 0.0
$pdf text "Roter Text" -x 50 -y 50

# Linie
$pdf setStrokeColor 0.0 0.0 0.0
$pdf setLineWidth 1
$pdf line 50 70 300 70

# Gefuelltes Rechteck
$pdf setFillColor 0.9 0.9 0.9
$pdf rectangle 50 90 250 80 -filled 1

# Text auf Rechteck
$pdf setFillColor 0.0 0.0 0.0
$pdf setFont 12 Helvetica
$pdf text "Text auf grauem Hintergrund" -x 60 -y 120

$pdf endPage
$pdf write -file $outfile
$pdf destroy

