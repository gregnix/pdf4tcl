# probe-textobjekt.tcl -- der Ausloeser, von Hand.
#
# Erzeugt ein getaggtes PDF mit fuenf Textausgaben. Die vierte steht in einem
# anderen Element als die dritte, OHNE dass dazwischen ein tagEnd das
# Textobjekt schliesst. Genau dort stand das Tj vor 0.9.4.69 ausserhalb von
# BT/ET, und genau das zeichnet der Adobe Reader nicht.
#
# Aufruf:
#   tclsh probe-textobjekt.tcl <pdf4tcl-Wurzel> <ausgabe.pdf>
#
# Danach:
#   python3 pruefe-textobjekte.py <ausgabe.pdf>
#
# Erwartung mit 0.9.4.69:   alle 5 Textausgaben stehen in einem Textobjekt
# Erwartung mit 0.9.4.68:   1 von 5 ausserhalb (die vierte)

if {$argc != 2} {
    puts stderr "Aufruf: tclsh probe-textobjekt.tcl <pdf4tcl-Wurzel> <ausgabe.pdf>"
    exit 2
}
lassign $argv wurzel out
set auto_path [linsert $auto_path 0 $wurzel]
package require pdf4tcl
puts "pdf4tcl [package present pdf4tcl]"

set pdf [::pdf4tcl::new %AUTO% -paper a4]
$pdf tagged 1 -lang de-DE
$pdf startPage
$pdf setFont 12 Helvetica
$pdf tagBegin Document
  # Je ein eigenes Element mit eigenem Ende: das Textobjekt wird jedes Mal
  # geschlossen, die naechste Ausgabe holt sich ihre Auszeichnung selbst.
  # Diese beiden waren immer richtig.
  $pdf tagBegin P
    $pdf text "erstes Stueck" -x 50 -y 700
  $pdf tagEnd
  $pdf tagBegin P
    $pdf text "zweites Stueck" -x 50 -y 680
  $pdf tagEnd
  # Hier wechselt die Auszeichnung, waehrend das Textobjekt offen bleibt.
  $pdf tagBegin P
    $pdf text "drittes Stueck" -x 50 -y 660
    $pdf tagBegin Span
      $pdf text "viertes Stueck" -x 50 -y 640
    $pdf tagEnd
    $pdf text "fuenftes Stueck" -x 50 -y 620
  $pdf tagEnd
$pdf tagEnd
$pdf write -file $out
$pdf destroy
puts "geschrieben: $out"
