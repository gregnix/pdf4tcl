#!/usr/bin/env tclsh
# demo-tagged-xobject.tcl -- Struktur in einem Form-XObject (0.9.4.46)
#
# Ein XObject ist wiederverwendbarer Inhalt. Bis 0.9.4.45 konnte man es
# platzieren und DIESE Platzierung auszeichnen -- was drin steht, blieb ein
# Block ohne innere Struktur. Seit .46 traegt der Inhalt selbst Struktur,
# unter einer Bedingung: das XObject darf genau einmal gezeichnet werden.
#
#   tclsh demo/demo-tagged-xobject.tcl [outdir]

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

set demodir  [file dirname [file normalize [info script]]]
set reporoot [pdf4tclRepoRoot $demodir]
set auto_path [linsert $auto_path 0 $reporoot]
package require pdf4tcl

# Die 14 Standardfonts haben kein einbettbares Fontprogramm, also kann ein
# Dokument mit ihnen PDF/UA nicht bestehen -- pdf4tcl warnt darueber. Fuer
# eine Demo, die gegen veraPDF laufen soll, ist das der Unterschied zwischen
# "geprueft" und "nicht pruefbar".
set fontFile [file join $reporoot examples FreeSans.ttf]
if {![file exists $fontFile]} {
    puts stderr "FreeSans.ttf nicht gefunden: $fontFile"
    exit 1
}
pdf4tcl::loadBaseTrueTypeFont BaseFreeSans $fontFile
pdf4tcl::createFont BaseFreeSans DemoFont iso8859-1
pdf4tcl::createFont BaseFreeSans DemoFontBold iso8859-1

set outdir [expr {$argc > 0 ? [lindex $argv 0] : [file join $demodir out]}]
file mkdir $outdir
set outfile [file join $outdir demo-tagged-xobject.pdf]

set pdf [::pdf4tcl::new %AUTO% -paper a4 -orient 1 -compress 0 -margin 40]
$pdf tagged 1 -ua 1 -lang de-DE
$pdf metadata -title "Struktur in einem Form-XObject" -author "pdf4tcl"
# PDF/UA verlangt, dass ein Leser den Titel statt des Dateinamens anzeigt
# (ISO 14289-1, Regel 7.1-10). Ohne diese Zeile faellt das Dokument durch,
# und zwar unabhaengig von allem Tagging -- gemessen mit veraPDF 1.30.2.
$pdf viewerPreferences -displaydoctitle 1

# ---------------------------------------------------------------------------
# 1. Ein XObject MIT Struktur -- genau einmal gezeichnet
# ---------------------------------------------------------------------------
#
# Innen wird ganz normal ausgezeichnet. Die MCIDs zaehlen ab 0, unabhaengig
# von der Seite: sie gehoeren zum Stream, nicht zur Seite.

# KEINE Ueberschrift hier drin -- und das ist die Lehre dieser Demo.
#
# Strukturelemente kommen in den Baum, wenn tagBegin laeuft. Ein XObject
# wird vor seiner Platzierung gebaut, seine Elemente stehen also VOR allem,
# was die Seite danach schreibt. Die erste Fassung setzte hier ein H2, die
# Seite darunter ihr H1 -- und der Baum begann mit H2.
#
# Gemessen: veraPDF 1.30.2 laesst das Dokument als PDF/UA durchfallen.
# ISO 14289-1 Klausel 7.4.2 verlangt Ueberschriften in aufsteigender
# Ordnung ohne Sprung, und zwar in der Reihenfolge des STRUKTURBAUMS --
# das ist die Lesereihenfolge, nicht die Anordnung auf dem Papier.
# tools/check-tagged.py prueft das seit dieser Runde ebenfalls.
#
# Wer in einem XObject Ueberschriften braucht, muss es an der Stelle
# bauen, an der sein Inhalt gelesen werden soll -- und stoesst dann auf
# die zweite Falle: startXObject ruft startPage, und das beendet eine
# offene Seite.
set karte [$pdf startXObject -paper {240p 90p}]
$pdf tagBegin P
$pdf setFont 10 DemoFont
$pdf text "Muster GmbH" -x 10 -y 22
$pdf text "Musterstrasse 1" -x 10 -y 44
$pdf text "12345 Musterstadt" -x 10 -y 66
$pdf tagEnd
# Der Rahmen sagt nichts -- Dekoration gehoert als Artefakt markiert, auch
# im XObject.
$pdf tagArtifact -type Layout
$pdf setLineWidth 0.5
$pdf rectangle 2 2 236 86
$pdf tagArtifactEnd
$pdf endXObject

# ---------------------------------------------------------------------------
# 2. Ein XObject OHNE Struktur -- beliebig oft gezeichnet
# ---------------------------------------------------------------------------
#
# Fuer wiederverwendete Bausteine bleibt das der richtige Weg: innen roh,
# aussen die Platzierung auszeichnen. Ein XObject mit Struktur zweimal zu
# zeichnen wird abgelehnt -- ein Strukturbaum kann nicht zwei Erscheinungen
# beschreiben.

set marke [$pdf startXObject -paper {60p 24p}]
$pdf tagArtifact -type Layout
$pdf setFillColor 0.85 0.88 0.94
$pdf rectangle 0 0 60 24 -filled 1
$pdf setFillColor 0.2 0.2 0.3
$pdf setFont 9 DemoFont
$pdf text "pdf4tcl" -x 8 -y 16
$pdf tagArtifactEnd
$pdf endXObject

# ---------------------------------------------------------------------------
# 3. Die Seite
# ---------------------------------------------------------------------------

$pdf startPage

$pdf tagBegin H1
$pdf setFont 16 DemoFontBold
$pdf text "Struktur in einem Form-XObject" -x 0 -y 20
$pdf tagEnd

$pdf tagBegin P
$pdf setFont 10 DemoFont
$pdf text "Der Kasten unten ist ein XObject. Sein Inhalt traegt eigene" -x 0 -y 50
$pdf text "Strukturelemente -- die Ueberschrift ist eine Ueberschrift," -x 0 -y 64
$pdf text "der Absatz ein Absatz, der Rahmen ein Artefakt." -x 0 -y 78
$pdf tagEnd

# Das XObject mit Struktur: EINMAL gezeichnet. Es steht hier ohne
# umschliessendes Figure -- seine Teile sind eigene Elemente im Baum, kein
# Bild mit Alternativtext.
$pdf putImage $karte 0 100 -width 240 -height 90

$pdf tagBegin P
$pdf setFont 10 DemoFont
$pdf text "Die kleine Marke rechts ist ebenfalls ein XObject, aber ohne" -x 0 -y 210
$pdf text "innere Struktur -- Zierde, als Artefakt platziert, die kein" -x 0 -y 224
$pdf text "Leser vorlesen soll. Auch sie wird nur EINMAL gezeichnet." -x 0 -y 238
$pdf tagEnd

# NUR EINMAL. Der urspruengliche Entwurf zeichnete die Marke dreimal --
# und veraPDF 1.30.2 liess das Dokument als PDF/UA durchfallen, mit
# Regel 7.20-2 ("The content of Form XObjects shall be incorporated into
# structure elements") und genau ZWEI Treffern: einem je zusaetzlicher
# Platzierung.
#
# Nachgemessen mit einem Artefakt-XObject: 1 Platzierung = 0 Fehlschlaege,
# 2 = 1, 3 = 2. Und zwar unabhaengig davon, WIE ausgezeichnet wird --
# Artefakt innen, Artefakt aussen, Figure aussen, gar nichts: alle vier
# Varianten fallen ab der zweiten Platzierung durch.
$pdf tagArtifact -type Layout
$pdf putImage $marke 380 270 -width 60 -height 24
$pdf tagArtifactEnd

$pdf endPage
$pdf finish

puts "ungetaggte Malbefehle: [$pdf getUntaggedCount]"
if {[llength $::pdf4tcl::warnings]} {
    puts "Warnungen:"
    foreach w $::pdf4tcl::warnings { puts "  $w" }
}

$pdf write -file $outfile
$pdf destroy
puts "Geschrieben: $outfile"
exit 0
