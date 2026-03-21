#!/usr/bin/env tclsh
# demo-cidfont.tcl -- Demo: Unicode/CID font support (pdf4tcl 0.9.4.5)
#
# Zeigt createFontSpecCID mit Latin Extended, Griechisch, Kyrillisch.
# Benoetigt: DejaVuSans.ttf (Debian/Ubuntu: fonts-dejavu-core)
#
# Aufruf:  tclsh demo-cidfont.tcl [/pfad/zur/schrift.ttf]

lappend auto_path [file join [file dirname [info script]] ../..] \
                  [file join [file dirname [info script]] ../../..]
package require pdf4tcl

# Font-Pfad ermitteln
set fontPath [lindex $argv 0]
if {$fontPath eq ""} {
    foreach candidate {
        /usr/share/fonts/truetype/dejavu/DejaVuSans.ttf
        /usr/share/fonts/TTF/DejaVuSans.ttf
        /Library/Fonts/DejaVuSans.ttf
        C:/Windows/Fonts/DejaVuSans.ttf
    } {
        if {[file exists $candidate]} { set fontPath $candidate; break }
    }
}
if {$fontPath eq "" || ![file exists $fontPath]} {
    puts stderr "Fehler: DejaVuSans.ttf nicht gefunden."
    puts stderr "Aufruf: tclsh demo-cidfont.tcl /pfad/zu/DejaVuSans.ttf"
    exit 1
}
puts "Lade Font: $fontPath"

# Basis-Font laden und CID-Spec erstellen
pdf4tcl::loadBaseTrueTypeFont DejaVuSans $fontPath
pdf4tcl::createFontSpecCID DejaVuSans cidSans

# Ausgabedatei
set outFile [file join [file dirname [info script]] demo-cidfont.pdf]

set pdf [pdf4tcl::new %AUTO% -compress 1 -orient 1]
$pdf startPage -paper a4

# Titel
$pdf setFont 20 cidSans
$pdf text "pdf4tcl CID Font Unicode Demo" -x 50 -y 50

# Trennlinie
$pdf setFillColor 0.5 0.5 0.5
$pdf rectangle 50 68 495 1 -filled 1
$pdf setFillColor 0 0 0

# Inhalte
$pdf setFont 14 cidSans
set y 90
foreach {label text} {
  "Latin (ASCII):"  "Hello World! ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz"
  "Latin Extended:" "\u00c0\u00c1\u00c2\u00c3\u00c4\u00c5\u00c6\u00c7\u00c8\u00c9\u00ca\u00cb \u00e4\u00f6\u00fc\u00df Oe Ae Ue"
  "Griechisch:"     "\u0391\u03b2\u03b3\u03b4\u03b5\u03b6\u03b7\u03b8\u03b9\u03ba\u03bb\u03bc\u03bd\u03be \u03b1\u03b2\u03b3\u03b4\u03b5\u03b6"
  "Kyrillisch:"     "\u041f\u0440\u0438\u0432\u0435\u0442 \u041c\u0438\u0440 \u0420\u043e\u0441\u0441\u0438\u044f"
  "Mathematik:"     "\u03b1 + \u03b2 = \u03b3 \u2264 \u03b4 \u2260 \u03b5 \u2265 \u03b6 \u221a\u03c0"
  "Sonderzeichen:"  "\u00a9 \u00ae \u2122 \u20ac \u00a3 \u00a5 \u00a2 \u00b0 \u00b1 \u00b5"
  "Pfeile:"         "\u2190 \u2191 \u2192 \u2193 \u21d0 \u21d2 \u21d4 \u2194"
} {
    $pdf setFont 10 cidSans
    $pdf text $label -x 30 -y $y
    $pdf setFont 12 cidSans
    $pdf text $text -x 115 -y $y
    incr y 28
}

# getStringWidth Demo
incr y 20
$pdf setFont 12 cidSans
set testStr "\u00e4\u00f6\u00fc\u00df"
set w [$pdf getStringWidth $testStr]
$pdf text "getStringWidth(\"$testStr\") = [format %.2f $w] Punkte" -x 50 -y $y

$pdf endPage
$pdf write -file $outFile
$pdf destroy

puts "Erstellt: $outFile"
