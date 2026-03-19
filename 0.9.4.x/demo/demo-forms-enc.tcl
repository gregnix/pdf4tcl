#!/usr/bin/env tclsh
# demo-forms-enc.tcl \u2014 Bestellformular mit AES-128-Verschluesselung
# Ablageort: pdf4tcl0.9.4.16src/pdf4tcl/0.9.4.x/demo/
# Aufruf:    tclsh demo-forms-enc.tcl
#
# Viewer: Firefox / Evince / Acrobat (Chrome zeigt AcroForm nicht an)
# Passwort zum Oeffnen: geheim

set scriptDir [file dirname [file normalize [info script]]]
set pdf4tclDir [file normalize [file join $scriptDir .. .. ..]]
set auto_path  [linsert $auto_path 0 $pdf4tclDir]
package require pdf4tcl 0.9.4.16

set outfile [file join $scriptDir demo-forms-enc.pdf]
set user    "geheim"
set owner   "admin"

set p [pdf4tcl::new %AUTO% -paper a4 -orient true \
    -userpassword  $user \
    -ownerpassword $owner \
    -encversion    4]

$p startPage

# --- Titel ---
$p setFont 16 Helvetica-Bold
$p text "Bestellformular" -x 72 -y 60

$p setFont 9 Helvetica
$p text "AES-128 verschluesselt  |  Passwort: $user" -x 72 -y 80

$p setLineWidth 0.5
$p setStrokeColor 0.5 0.5 0.5
$p line 72 90 520 90
$p setStrokeColor 0 0 0

# --- Textfelder ---
# Wichtig: setFont VOR jedem addForm damit /DA korrekt gesetzt wird
foreach {label id y} {
    "Name:"   f_name  115
    "Firma:"  f_firma 140
    "E-Mail:" f_email 165
} {
    $p setFont 10 Helvetica
    $p text $label -x 72 -y $y
    $p setFont 10 Helvetica
    $p addForm text 160 [expr {$y - 10}] 300 16 -id $id -init ""
}

# --- Combobox ---
$p setFont 10 Helvetica
$p text "Artikel:" -x 72 -y 190
$p setFont 10 Helvetica
$p addForm combobox 160 180 200 16 -id "f_artikel" \
    -options {"Artikel A" "Artikel B" "Artikel C" "Sonderbestellung"}

# --- Menge ---
$p setFont 10 Helvetica
$p text "Menge:" -x 72 -y 215
$p setFont 10 Helvetica
$p addForm text 160 205 60 16 -id "f_menge" -init "1"

# --- Radiobuttons ---
$p setFont 10 Helvetica
$p text "Prioritaet:" -x 72 -y 250
foreach {rid rval rx rlabel} {
    prio_n  normal    160 "Normal"
    prio_e  express   240 "Express"
    prio_o  overnight 320 "Overnight"
} {
    $p setFont 10 Helvetica
    $p addForm radiobutton $rx 240 12 12 -id $rid -group "prio" -value $rval
    $p setFont 10 Helvetica
    $p text $rlabel -x [expr {$rx + 16}] -y 250
}

# --- Checkbox ---
$p setFont 10 Helvetica
$p addForm checkbutton 72 273 12 12 -id "f_agb"
$p setFont 10 Helvetica
$p text "Ich akzeptiere die Allgemeinen Geschaeftsbedingungen." -x 90 -y 283

# --- Bemerkung ---
$p setFont 10 Helvetica
$p text "Bemerkung:" -x 72 -y 310
$p setFont 10 Helvetica
$p addForm text 160 295 300 55 -id "f_bemerkung" -multiline 1

# --- Buttons ---
$p setFont 10 Helvetica
$p addForm pushbutton 72 370 90 20 \
    -id "f_submit" -caption "Absenden" -action submit \
    -url "mailto:bestellung@example.com"

$p setFont 10 Helvetica
$p addForm pushbutton 175 370 90 20 \
    -id "f_reset" -caption "Zuruecksetzen" -action reset

# --- Fusszeile ---
$p setFont 8 Helvetica
$p setFillColor 0.5 0.5 0.5
$p text "Verschluesselt mit AES-128. Passwort: $user" -x 72 -y 810
$p setFillColor 0 0 0

$p endPage
$p write -file $outfile
$p destroy

puts "Geschrieben: $outfile ([file size $outfile] Bytes)"
puts "Pruefen:     qpdf --password=$user --check $outfile"
puts "Oeffnen:     firefox $outfile"
