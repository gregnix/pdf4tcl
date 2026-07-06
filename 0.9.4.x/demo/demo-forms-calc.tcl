#!/usr/bin/env tclsh
# demo-forms-calc.tcl -- Bestellformular mit Feld-Ausrichtung, Farbe/Rahmen
#                        und automatischer Summenberechnung.
# Ablageort: pdf4tcl/0.9.4.x/demo/
# Aufruf:    tclsh demo-forms-calc.tcl
#
# Zeigt:
#   -align right                     rechtsbuendige Betraege (0.9.4.30)
#   -color / -borderwidth / -bgcolor Feld-Optik                (0.9.4.31)
#   -calculate {sum {...}}           Live-Summe via AFSimple_Calculate,
#                                    /CO-Reihenfolge, /NeedAppearances (0.9.4.32)
#
# Die Betragsfelder sind vorbelegt, damit die Summe schon statisch (via -init)
# sichtbar ist -- korrekt in jedem Reader. In einem JavaScript-faehigen Viewer
# (Adobe Acrobat/Reader, Firefox, Chrome/Edge, Foxit) wird die Summe live neu
# berechnet, sobald ein Betrag geaendert wird.

set scriptDir  [file dirname [file normalize [info script]]]
set pdf4tclDir [file normalize [file join $scriptDir .. .. ..]]
set auto_path  [linsert $auto_path 0 $pdf4tclDir]
package require pdf4tcl 0.9.4.32

set outfile [file join $scriptDir demo-forms-calc.pdf]

set p [pdf4tcl::new %AUTO% -paper a4 -orient true]
$p startPage

# --- Titel ---
$p setFont 16 Helvetica-Bold
$p text "Bestellung mit Summenberechnung" -x 72 -y 55
$p setLineWidth 0.5
$p setStrokeColor 0.5 0.5 0.5
$p line 72 70 520 70
$p setStrokeColor 0 0 0

# --- Kundendaten ---
foreach {label id y} {
    "Name:"  f_name  100
    "Firma:" f_firma 125
} {
    $p setFont 10 Helvetica
    $p text $label -x 72 -y $y
    $p addForm text 160 [expr {$y - 10}] 300 16 -id $id
}

# --- Positionen ---
$p setFont 12 Helvetica-Bold
$p text "Positionen" -x 72 -y 165
$p setFont 10 Helvetica-Bold
$p text "Artikel"      -x 72  -y 185
$p text "Betrag (EUR)" -x 400 -y 185
$p setFont 10 Helvetica

# Vorbelegte Betraege -> statische Summe = 250
foreach {artId artName betId betrag y} {
    a1 "Artikel A" b1 120 205
    a2 "Artikel B" b2  80 228
    a3 "Artikel C" b3  50 251
} {
    $p addForm text 72 [expr {$y - 10}] 250 16 -id $artId -init $artName
    $p addForm text 400 [expr {$y - 10}] 90 16 -id $betId -align right \
        -borderwidth 0.5 -init $betrag
}

# Trennlinie unter den Betraegen
$p setStrokeColor 0 0 0
$p setLineWidth 0.5
$p line 400 258 490 258

# --- Summe: hybrid (statischer Vorabwert + AFSimple_Calculate) ---
$p setFont 11 Helvetica-Bold
$p text "Zwischensumme:" -x 280 -y 280
$p setFont 10 Helvetica
$p addForm text 400 270 90 16 -id f_summe -align right \
    -calculate {sum {b1 b2 b3}} -init 250 \
    -borderwidth 1 -bordercolor {0 0 0.5} -bgcolor {0.95 0.95 0.82}

$p setFont 9 Helvetica-Oblique
$p text "Betrag aendern -> Summe rechnet in Acrobat/Firefox/Chrome/Edge/Foxit live neu." \
    -x 72 -y 310

# --- Buttons ---
$p setFont 10 Helvetica
$p addForm pushbutton 72 340 90 20 -id f_submit \
    -caption "Absenden" -action submit -url "mailto:bestellung@example.com"
$p addForm pushbutton 175 340 90 20 -id f_reset \
    -caption "Zuruecksetzen" -action reset

$p endPage
$p write -file $outfile
$p destroy

puts "Geschrieben: $outfile ([file size $outfile] Bytes)"
puts "Oeffnen:     firefox $outfile"
