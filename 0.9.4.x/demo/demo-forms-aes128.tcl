#!/usr/bin/env tclsh
# demo-forms-aes256.tcl \u2014 AcroForm-Formular mit AES-256-Verschl\u00FCsselung
# Ablageort: pdf4tcl0.9.4.16src/pdf4tcl/
# Aufruf: tclsh demo-forms-aes256.tcl
#
# Hinweis: AES-256 benoetigt openssl im PATH (SHA-384/512).
#          Laufzeit ca. 2-4 Sekunden.

set scriptDir [file dirname [file normalize [info script]]]
set auto_path  [linsert $auto_path 0 $scriptDir]
package require pdf4tcl 0.9.4.16

set outfile [file join $scriptDir demo-forms-ase128.pdf]
set user    "geheim"
set owner   "admin"

# encversion 4 = AES-128 (sofort, reines Tcl)
# encversion 5 = AES-256 (2-4 Sek., benoetigt openssl)

set p [pdf4tcl::new %AUTO% -paper a4 -orient true \
    -userpassword  $user \
    -ownerpassword $owner \
    -encversion    4]

$p startPage

# --- Titel ---
$p setFont 16 Helvetica-Bold
$p text "Bestellformular (AES-128)" -x 72 -y 60

$p setFont 9 Helvetica
$p text "Passwort: $user  |  Verschl\u00FCsselung: AES-128 (V=4/R=4)" -x 72 -y 80

# --- Trennlinie ---
$p setLineWidth 0.5
$p setStrokeColor 0.5 0.5 0.5
$p line 72 90 520 90
$p setStrokeColor 0 0 0

# --- Felder ---
$p setFont 10 Helvetica

# Name
$p text "Name:" -x 72 -y 115
$p addForm text 140 105 240 16 \
    -id "f_name" -init ""

# Firma
$p text "Firma:" -x 72 -y 140
$p addForm text 140 130 240 16 \
    -id "f_firma" -init ""

# E-Mail
$p text "E-Mail:" -x 72 -y 165
$p addForm text 140 155 240 16 \
    -id "f_email" -init ""

# Artikel
$p text "Artikel:" -x 72 -y 190
$p addForm combobox 140 180 200 16 \
    -id "f_artikel" \
    -options {"Artikel A" "Artikel B" "Artikel C" "Sonderbestellung"}

# Menge
$p text "Menge:" -x 72 -y 215
$p addForm text 140 205 60 16 \
    -id "f_menge" -init "1"

# Priorit\u00E4t
$p text "Priorit\u00E4t:" -x 72 -y 250
$p addForm radiobutton 140 240 12 12 \
    -id "prio_normal" -group "prio" -value "normal"
$p text "Normal" -x 157 -y 250

$p addForm radiobutton 210 240 12 12 \
    -id "prio_express" -group "prio" -value "express"
$p text "Express" -x 227 -y 250

$p addForm radiobutton 285 240 12 12 \
    -id "prio_overnight" -group "prio" -value "overnight"
$p text "Overnight" -x 302 -y 250

# AGB
$p addForm checkbutton 72 273 12 12 \
    -id "agb"
$p text "Ich akzeptiere die Allgemeinen Gesch\u00E4ftsbedingungen." -x 90 -y 283

# Bemerkung
$p text "Bemerkung:" -x 72 -y 310
$p addForm text 140 300 360 50 \
    -id "bemerkung" -multiline 1

# Absenden-Button
$p addForm pushbutton 72 370 80 20 \
    -id "submit" -caption "Absenden" -action submit \
    -url "mailto:bestellung@example.com"

# Zur\u00FCcksetzen-Button
$p addForm pushbutton 165 370 80 20 \
    -id "reset" -caption "Zur\u00FCcksetzen" -action reset

# --- Fusszeile ---
$p setFont 8 Helvetica
$p setFillColor 0.5 0.5 0.5
$p text "Dieses Formular ist mit AES-128 verschl\u00FCsselt. Passwort: \"$user\"" \
    -x 72 -y 810
$p setFillColor 0 0 0

$p endPage
$p write -file $outfile
$p destroy

puts "Geschrieben: $outfile"
puts "\u00D6ffnen mit: evince --password=$user $outfile"
puts "Pr\u00FCfen mit: qpdf --password=$user --check $outfile"
