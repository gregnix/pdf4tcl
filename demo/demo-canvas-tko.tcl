#!/usr/bin/env wish
# demo-canvas-tko.tcl -- tko::path PDF export
#
# pdf4tcl tells three canvas classes apart by "winfo class":
#
#     Canvas       tk::canvas      the classic one
#     PathCanvas   tkp::canvas     tkpath
#     everything else              tko::path
#
# The third one had no demo. What differs from the other two is the font
# mapping: a tko::path text item carries family, size and weight as separate
# options, so -fontmap is keyed on the FAMILY alone. A tk::canvas item is
# keyed on its whole font specification.
#
# Usage: wish demo-canvas-tko.tcl [outputdir]

package require Tk
if {[catch {package require tko} e]} {
    puts "tko not available: $e"
    puts "  Debian/Ubuntu: build from https://github.com/gregnix/tko"
    exit 0
}

set here [file dirname [file normalize [info script]]]
lappend auto_path [file join $here ..] [file join $here .. pkg]
package require pdf4tcl

set outdir [lindex $argv 0]
if {$outdir eq ""} {
    set outdir [file join $here out]
    file mkdir $outdir
}
set outfile [file join $outdir demo-canvas-tko.pdf]

set pdf [pdf4tcl::new %AUTO% -paper a4 -margin 40]

# ---------------------------------------------------------------------------
# Seite 1: die Elementtypen
# ---------------------------------------------------------------------------
$pdf startPage
$pdf setFont 14 Helvetica-Bold
$pdf text "tko::path -- Elementtypen" -x 0 -y 0
$pdf setFont 9 Helvetica
$pdf text "rect, ellipse, circle, path, line, polyline, text" -x 0 -y 20

tko::path .tp1 -width 460 -height 300 -background white
pack .tp1

.tp1 create rect 20 20 140 80 -fill lightblue -stroke navy -strokewidth 2
.tp1 create rect 160 20 280 80 -fill lightyellow -stroke darkorange \
        -strokewidth 2 -rx 12
.tp1 create ellipse 360 50 -rx 60 -ry 30 -fill lightgreen -stroke darkgreen
.tp1 create circle 60 160 -r 35 -fill lightcoral -stroke darkred
.tp1 create path "M 150 130 L 200 190 L 250 130 Z" \
        -fill lightsteelblue -stroke steelblue -strokewidth 2
.tp1 create line 300 130 420 190 -stroke purple -strokewidth 3
.tp1 create polyline 300 200 340 230 380 200 420 230 \
        -stroke teal -strokewidth 2 -fill ""
.tp1 create text 20 250 -text "text in Helvetica" \
        -fontfamily Helvetica -fontsize 14 -fill black

update
$pdf canvas .tp1 -bbox [.tp1 bbox all] -x 0 -y 45 -width 460 -height 300
destroy .tp1
$pdf endPage

# ---------------------------------------------------------------------------
# Seite 2: -fontmap mit einer CID-Schrift
#
# Bis 0.9.4.58 brach der Export hier ab:
#
#     can't read "FontsAttrs(...,specialencoding)"
#
# weil der Rueckruf getTkpptext bedingungslos den 8-Bit-Weg nahm. Ohne
# -fontmap kaemen stattdessen Fragezeichen, weil die geratene
# Standardschrift kein Griechisch fuehrt.
#
# DER SCHLUESSEL IST DIE FAMILIE, nicht die ganze Fontangabe -- ein
# text-Element traegt -fontfamily, -fontsize und -fontweight getrennt.
# Beim tk::canvas ist es umgekehrt; siehe
# doc/en/reference/pdf4tcl-canvas.md.
# ---------------------------------------------------------------------------
source [file join $here .. tools findfont.tcl]
set uniFont [::pdf4tcl::findFont unicode]

if {$uniFont eq ""} {
    puts "  keine Unicode-Schrift gefunden -- Seite 2 uebersprungen"
} else {
    pdf4tcl::loadBaseTrueTypeFont UniBase $uniFont
    pdf4tcl::createFontSpecCID UniBase UniCid

    $pdf startPage
    $pdf setFont 14 Helvetica-Bold
    $pdf text "-fontmap mit einer CID-Schrift" -x 0 -y 0
    $pdf setFont 9 Helvetica
    $pdf text "Der Schluessel ist die FAMILIE -- {Helvetica UniCid}" -x 0 -y 20

    tko::path .tp2 -width 460 -height 180 -background white
    pack .tp2

    .tp2 create text 20 40 -fontfamily Helvetica -fontsize 15 -fill black \
            -text "Griechisch: \u0395\u03bb\u03bb\u03ac\u03b4\u03b1"
    .tp2 create text 20 80 -fontfamily Helvetica -fontsize 15 -fill black \
            -text "Mathematik: \u0394 \u2211 \u221e \u03c6"
    .tp2 create text 20 120 -fontfamily Helvetica -fontsize 15 -fill black \
            -text "Kyrillisch: \u041f\u0440\u0438\u0432\u0435\u0442"
    update

    $pdf canvas .tp2 -bbox [.tp2 bbox all] -x 0 -y 45 \
            -width 460 -height 180 -fontmap {Helvetica UniCid}
    destroy .tp2

    $pdf setFont 9 Helvetica
    $pdf text "getSubstCount: [$pdf getSubstCount]   (0 = jedes Zeichen\
            hatte eine Glyphe)" -x 0 -y 250
    $pdf text "Die Probe: pdftotext auf diese Seite muss die Woerter\
            zurueckgeben, nicht Fragezeichen." -x 0 -y 265
    $pdf endPage
}

# ---------------------------------------------------------------------------
# Seite 3: dieselbe Schrift OHNE -fontmap
#
# Seit 0.9.4.60 nimmt der Export eine Schrift, die unter dem Namen der
# Familie geladen ist. Hier heisst die Familie des Elements "UniFamilie",
# und genau so heisst die CID-Schrift -- mehr braucht es nicht.
#
# Vorher landete eine unbekannte Familie bei Helvetica, und jedes Zeichen
# jenseits von Latin-1 wurde still zum Fragezeichen. Gemessen wird das mit
# getSubstCount.
# ---------------------------------------------------------------------------
if {$uniFont ne ""} {
    pdf4tcl::loadBaseTrueTypeFont UniBase2 $uniFont
    pdf4tcl::createFontSpecCID UniBase2 UniFamilie   ;# wie die Tk-Familie

    $pdf startPage
    $pdf setFont 14 Helvetica-Bold
    $pdf text "Ohne -fontmap: die Familie traegt den Namen" -x 0 -y 0
    $pdf setFont 9 Helvetica
    $pdf text "createFontSpecCID ... UniFamilie, und das Element hat\
            -fontfamily UniFamilie" -x 0 -y 20

    set vorher [$pdf getSubstCount]

    tko::path .tp3 -width 460 -height 140 -background white
    pack .tp3
    .tp3 create text 20 40 -fontfamily UniFamilie -fontsize 15 -fill black \
            -text "Griechisch: \u0395\u03bb\u03bb\u03ac\u03b4\u03b1"
    .tp3 create text 20 80 -fontfamily UniFamilie -fontsize 15 -fill black \
            -text "Mathematik: \u0394 \u2211 \u221e \u03c6"
    update

    $pdf canvas .tp3 -bbox [.tp3 bbox all] -x 0 -y 45 \
            -width 460 -height 140
    destroy .tp3

    $pdf setFont 9 Helvetica
    $pdf text "Ersetzungen auf dieser Seite:\
            [expr {[$pdf getSubstCount] - $vorher}]   (0 = die Suche hat\
            gegriffen)" -x 0 -y 210
    $pdf text "Eine ausdrueckliche -fontmap-Angabe gewinnt weiterhin gegen\
            diese Suche." -x 0 -y 225
    $pdf endPage
}

$pdf write -file $outfile
$pdf destroy

puts "tko demo geschrieben: $outfile"

# Unter wish geht der Interpreter nach dem Skript in die Event-Loop. Damit
# die Demo im Sammellauf ein definiertes Ende hat, endet sie wie unter tclsh.
exit 0
