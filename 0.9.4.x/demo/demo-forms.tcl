#!/usr/bin/env tclsh
# demo-forms.tcl — Bestellformular ohne Verschluesselung
# Ablageort: pdf4tcl0.9.4.16src/pdf4tcl/0.9.4.x/demo/
# Aufruf:    tclsh demo-forms.tcl

set scriptDir [file dirname [file normalize [info script]]]
set pdf4tclDir [file normalize [file join $scriptDir .. .. ..]]
set auto_path  [linsert $auto_path 0 $pdf4tclDir]
package require pdf4tcl 0.9.4.16

set outfile [file join $scriptDir demo-forms.pdf]

set p [pdf4tcl::new %AUTO% -paper a4 -orient true]

$p startPage

# --- Titel ---
$p setFont 16 Helvetica-Bold
$p text "Bestellformular" -x 72 -y 60

$p setLineWidth 0.5
$p setStrokeColor 0.5 0.5 0.5
$p line 72 75 520 75
$p setStrokeColor 0 0 0

# --- Textfelder ---
foreach {label id y} {
    "Name:"   f_name  105
    "Firma:"  f_firma 130
    "E-Mail:" f_email 155
} {
    $p setFont 10 Helvetica
    $p text $label -x 72 -y $y
    $p setFont 10 Helvetica
    $p addForm text 160 [expr {$y - 10}] 300 16 -id $id -init ""
}

# --- Combobox ---
$p setFont 10 Helvetica
$p text "Artikel:" -x 72 -y 180
$p setFont 10 Helvetica
$p addForm combobox 160 170 200 16 -id "f_artikel" \
    -options {"Artikel A" "Artikel B" "Artikel C" "Sonderbestellung"}

# --- Menge ---
$p setFont 10 Helvetica
$p text "Menge:" -x 72 -y 205
$p setFont 10 Helvetica
$p addForm text 160 195 60 16 -id "f_menge" -init "1"

# --- Radiobuttons ---
$p setFont 10 Helvetica
$p text "Prioritaet:" -x 72 -y 240
foreach {rid rval rx rlabel} {
    prio_n  normal    160 "Normal"
    prio_e  express   240 "Express"
    prio_o  overnight 320 "Overnight"
} {
    $p setFont 10 Helvetica
    $p addForm radiobutton $rx 230 12 12 -id $rid -group "prio" -value $rval
    $p setFont 10 Helvetica
    $p text $rlabel -x [expr {$rx + 16}] -y 240
}

# --- Checkbox ---
$p setFont 10 Helvetica
$p addForm checkbutton 72 263 12 12 -id "f_agb"
$p setFont 10 Helvetica
$p text "Ich akzeptiere die AGB." -x 90 -y 273

# --- Bemerkung ---
$p setFont 10 Helvetica
$p text "Bemerkung:" -x 72 -y 300
$p setFont 10 Helvetica
$p addForm text 160 285 300 55 -id "f_bemerkung" -multiline 1

# --- Buttons ---
$p setFont 10 Helvetica
$p addForm pushbutton 72 360 90 20 \
    -id "f_submit" -caption "Absenden" -action submit \
    -url "mailto:bestellung@example.com"

$p setFont 10 Helvetica
$p addForm pushbutton 175 360 90 20 \
    -id "f_reset" -caption "Zuruecksetzen" -action reset

$p endPage
$p write -file $outfile
$p destroy

puts "Geschrieben: $outfile ([file size $outfile] Bytes)"
puts "Oeffnen:     firefox $outfile"
