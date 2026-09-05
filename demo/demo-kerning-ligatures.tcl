#!/usr/bin/env tclsh
# demo-kerning-ligatures.tcl -- Demo: pair kerning and standard ligatures
#                               (pdf4tcl 0.9.4.47)
#
# Zeigt setKerning und setLigatures nebeneinander, mit den Zahlen aus der
# Schrift und dem, was im Inhalt landet.
#
# Benoetigt eine TrueType-Schrift mit Kernpaaren UND lateinischen
# Ligaturen. Carlito ist der beste Fall, weil es beides in moderner Form
# fuehrt: Kerning nur in GPOS, klassenbasiert, und 424 Ligaturen.
#   Debian/Ubuntu: fonts-crosextra-carlito
#
# Aufruf:  tclsh demo-kerning-ligatures.tcl [/pfad/zur/schrift.ttf]

# ---------------------------------------------------------------------------
# Wurzel suchen, nicht zaehlen. Markierung ist pkgIndex.tcl neben src/.
# ---------------------------------------------------------------------------
proc pdf4tclRepoRoot {start} {
    set dir [file normalize $start]
    for {set i 0} {$i < 8} {incr i} {
        if {[file exists [file join $dir pkgIndex.tcl]]
                && [file isdirectory [file join $dir src]]} { return $dir }
        set parent [file dirname $dir]
        if {$parent eq $dir} break
        set dir $parent
    }
    return -code error "pdf4tcl-Wurzel nicht gefunden ueber $start"
}
lappend auto_path [pdf4tclRepoRoot [file dirname [info script]]] \
                  [file join [file dirname [info script]] ../../..]
package require pdf4tcl

set fontPath [lindex $argv 0]
if {$fontPath eq ""} {
    foreach candidate {
        /usr/share/fonts/truetype/crosextra/Carlito-Regular.ttf
        /usr/share/fonts/truetype/crosextra/Caladea-Regular.ttf
        /usr/share/fonts/truetype/freefont/FreeSerif.ttf
        /usr/share/fonts/TTF/Carlito-Regular.ttf
    } {
        if {[file exists $candidate]} { set fontPath $candidate; break }
    }
}
if {$fontPath eq "" || ![file exists $fontPath]} {
    puts stderr "Fehler: keine geeignete Schrift gefunden."
    puts stderr "Aufruf: tclsh demo-kerning-ligatures.tcl /pfad/zur/schrift.ttf"
    puts stderr "Debian/Ubuntu: apt install fonts-crosextra-carlito"
    # 77 statt 1: eine fehlende Schrift ist keine Stoerung dieser Demo,
    # sondern ein Grund, sie nicht auszufuehren. run-all-demos.tcl liest
    # die Zahl und zaehlt sie als "uebersprungen" -- sonst ist der Lauf
    # auf keiner Maschine ohne Carlito jemals gruen, und ein echter
    # Fehler daneben faellt nicht mehr auf. Dieselbe Zahl benutzt
    # autoconf dafuer.
    exit 77
}
puts "Lade Font: $fontPath"

pdf4tcl::loadBaseTrueTypeFont DemoBase $fontPath
pdf4tcl::createFontSpecCID DemoBase DemoFont

# Was die Schrift mitbringt -- gemessen, nicht behauptet.
set einzelpaare [dict size $::pdf4tcl::BFA(DemoBase,kernPairs)]
set klassen     [llength $::pdf4tcl::BFA(DemoBase,kernClasses)]
set ligaErste   [dict size $::pdf4tcl::BFA(DemoBase,ligatures)]
puts "  Kernpaare einzeln: $einzelpaare, Klassentabellen: $klassen"
puts "  Glyphen mit Ligaturen: $ligaErste"

# Nach out/, wie die uebrigen Demos.
set outdir [file join [file dirname [info script]] out]
file mkdir $outdir
set outfile [file join $outdir demo-kerning-ligatures.pdf]
set pdf [::pdf4tcl::new %AUTO% -paper a4 -margin 50 -compress 1]
$pdf startPage

lassign [$pdf getDrawableArea] breite hoehe

proc zeile {y text {size 10} {font Helvetica}} {
    global pdf
    $pdf setFont $size $font
    $pdf text $text -x 0 -y $y
}

zeile 20 "Kerning und Ligaturen" 15 Helvetica-Bold
zeile 40 [file tail $fontPath] 9

# --- Kerning ---------------------------------------------------------------
zeile 75 "Kerning" 12 Helvetica-Bold

set probe "AVATAR Wave To Ty."
$pdf setLigatures 0

$pdf setKerning 0
$pdf setFont 20 DemoFont
$pdf text $probe -x 0 -y 105
zeile 123 "setKerning 0 -- [format %.2f [$pdf getStringWidth $probe]] pt" 9

$pdf setKerning 1
$pdf setFont 20 DemoFont
$pdf text $probe -x 0 -y 150
zeile 168 "setKerning 1 (Vorgabe) -- [format %.2f [$pdf getStringWidth $probe]] pt" 9

# Messen und Zeichnen stimmen ueberein: rechtsbuendig auf einer Linie.
$pdf setFont 20 DemoFont
$pdf text $probe -x $breite -y 200 -align right
$pdf setLineWidth 0.5
$pdf line $breite 185 $breite 210
zeile 218 "rechtsbuendig auf der Linie -- die Zeile endet genau dort," 9
zeile 230 "weil getStringWidth die gekernte Breite liefert" 9

# --- Ligaturen -------------------------------------------------------------
zeile 270 "Ligaturen" 12 Helvetica-Bold

set wort "Auflage finden, offiziell"

$pdf setKerning 1
$pdf setLigatures 0
$pdf setFont 20 DemoFont
$pdf text $wort -x 0 -y 300
zeile 318 "setLigatures 0 (Vorgabe)" 9

$pdf setLigatures 1
$pdf setFont 20 DemoFont
$pdf text $wort -x 0 -y 345
zeile 363 "setLigatures 1 -- fl und fi sind je ein Glyph" 9

# Und was es fuer die BREITE bedeutet. Seit 0.9.4.49 misst
# getStringWidth denselben geformten Lauf, der gezeichnet wird -- vorher
# war die Zahl gleich, obwohl eine andere Glyphe auf der Seite stand.
$pdf setFont 12 DemoFont
$pdf setLigatures 0
set wOhne [$pdf getStringWidth "ffi"]
$pdf setLigatures 1
set wMit  [$pdf getStringWidth "ffi"]
zeile 415 [format "Breite von \"ffi\": %.2f pt ohne Ligaturen, %.2f pt mit" \
        $wOhne $wMit] 9
zeile 430 "-- die ffi-Glyphe ist schmaler als f + f + i. Bis 0.9.4.48" 9
zeile 443 "   lieferte getStringWidth beide Male denselben Wert." 9

# Der Beweis, dass geformt wird BEVOR gekernt wird: mit beiden Schaltern
# steht ein Glyph da, nicht f + fi.
$pdf setLigatures 1
$pdf setKerning 1
set ffiRun [pdf4tcl::CIDEncodeText "ffi" DemoFont 1]
zeile 460 "\"ffi\" mit beiden Schaltern: [expr {([string length $ffiRun] - 2) / 4}] Glyph(en)" 9

# Wie viele Glyphen es kostet.
#
# Die y-Werte liefen hier rueckwaerts: nach 460 ging es wieder bei 390
# los, und fuenf Zeilenpaare lagen ineinander. Auf der Seite sieht man
# es kaum -- gefunden hat es tools/layout-check.tcl mit 39 Meldungen.
set ohne  [pdf4tcl::CIDEncodeText "Auflage" DemoFont]
set mit   [pdf4tcl::CIDEncodeText "Auflage" DemoFont 1]
zeile 478 "\"Auflage\": [expr {([string length $ohne] - 2) / 4}] Glyphen ohne,\
        [expr {([string length $mit] - 2) / 4}] mit Ligaturen" 10

zeile 508 "Der Text bleibt durchsuchbar: die ToUnicode-Zuordnung haelt beide" 10
zeile 522 "Zeichen fest, fuer die eine Ligatur steht. Probe:" 10
zeile 540 "    pdftotext demo-kerning-ligatures.pdf -" 10 Courier
zeile 558 "liefert die Woerter vollstaendig zurueck." 10

# --- was diese Schrift kann ------------------------------------------------
zeile 592 "Was diese Schrift mitbringt" 12 Helvetica-Bold
zeile 617 "Kernpaare einzeln:      $einzelpaare" 10 Courier
zeile 631 "Klassentabellen:        $klassen" 10 Courier
zeile 645 "Glyphen mit Ligaturen:  $ligaErste" 10 Courier

zeile 677 "Nicht jede Schrift meint dasselbe: DejaVu Sans hat ein" 9
zeile 689 "arabisches liga-Feature und gar kein fi-Glyph, Liberation" 9
zeile 701 "Serif hat keine Ligaturen, Carlito hat 424." 9

$pdf write -file $outfile
$pdf destroy
puts "Geschrieben: $outfile"
