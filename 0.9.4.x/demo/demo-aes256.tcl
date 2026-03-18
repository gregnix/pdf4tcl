#!/usr/bin/env tclsh
# demo-aes256.tcl — AES-256 Verschlüsselung Demo
# Ablageort: pdf4tcl0.9.4.16src/pdf4tcl/
# Aufruf: tclsh demo-aes256.tcl

set scriptDir [file dirname [file normalize [info script]]]
set auto_path  [linsert $auto_path 0 $scriptDir]
package require pdf4tcl 0.9.4.16

set outfile [file join $scriptDir demo-aes256.pdf]
set user    "geheim"
set owner   "admin"

set p [pdf4tcl::new %AUTO% -paper a4 -orient true \
    -userpassword  $user \
    -ownerpassword $owner \
    -encversion    5]

$p startPage
$p setFont 18 Helvetica-Bold
$p text "pdf4tcl 0.9.4.16 — AES-256 Demo" -x 72 -y 72

$p setFont 12 Helvetica
$p text "Dieses PDF ist mit AES-256 (V=5/R=6) verschluesselt." -x 72 -y 112
$p text "User-Passwort:  $user"  -x 72 -y 137
$p text "Owner-Passwort: $owner" -x 72 -y 162

$p setFont 10 Helvetica
$p text "Verifizierung:" -x 72 -y 202
$p text "  qpdf --password=$user --check demo-aes256.pdf" -x 72 -y 222
$p text "  python3 verify_enc3.py demo-aes256.pdf $user"  -x 72 -y 242

$p endPage
$p write -file $outfile
$p destroy

puts "Geschrieben: $outfile ([file size $outfile] Bytes)"
puts "Pruefen mit: qpdf --password=$user --check $outfile"
