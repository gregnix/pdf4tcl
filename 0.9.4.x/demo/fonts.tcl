#!/usr/bin/env tclsh
package require pdf4tcl 0.9

set pdf [::pdf4tcl::new %AUTO% -paper a4 -orient true]
$pdf startPage

# Ueberschrift
$pdf setFont 24 Helvetica-Bold
$pdf text "Mein Dokument" -x 50 -y 60

# Fliesstext
$pdf setFont 12 Times-Roman
$pdf text "Dies ist ein Absatz in Times Roman." -x 50 -y 100

# Hervorgehobener Text
$pdf setFont 12 Helvetica-Bold
$pdf text "Wichtig:" -x 50 -y 130
$pdf setFont 12 Helvetica
$pdf text "Normaler Text nach der Hervorhebung." -x 110 -y 130

# Monospace fuer Code
$pdf setFont 10 Courier
$pdf text "puts \"Hello World\"" -x 50 -y 170

$pdf endPage
$pdf write -file fonts-demo.pdf
$pdf destroy

