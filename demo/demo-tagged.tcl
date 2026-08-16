#!/usr/bin/env tclsh
# demo-tagged.tcl -- Tagged PDF: logische Struktur (0.9.4.36 / 0.9.4.37)
#
# Usage: tclsh demo-tagged.tcl [outputdir_or_file]
#
# Ein gewoehnliches PDF haelt nur fest, wo Glyphen gemalt werden. Was davon
# Ueberschrift, Tabellenzelle oder Seitenzahl ist, steht nirgends, und die
# Lesereihenfolge ergibt sich zufaellig aus der Reihenfolge im Content-Stream.
# Tagged PDF ergaenzt einen Strukturbaum (ISO 32000-1 Kapitel 14.7/14.8) und
# verbindet ihn ueber Marked Content mit dem Gemalten.
#
# Das erzeugte PDF ist PDF/UA-1-konform. Pruefen mit:
#     verapdf -f ua1 demo-tagged.pdf
#     python3 ../../tools/check-tagged.py demo-tagged.pdf
#
# KOORDINATEN
# pdf4tcl steht per Default auf -orient 1: y waechst nach UNTEN, ab dem oberen
# Rand, x nach rechts ab dem linken. (0,0) ist also die linke obere Ecke der
# Zeichenflaeche, die Raender sind bereits eingerechnet.

# ---------------------------------------------------------------------------
# Wurzel suchen, nicht zaehlen.
#
# Zwei Ebenen hoch stimmte, solange die Demos unter demo lagen.
# Nach dem Flachlegen des fork-Verzeichnisses zeigte es aus dem Repo
# hinaus. Sichtbar wurde das nur in den Demos, die daraus einen Dateipfad
# bauen (demo-tagged brach ab); die uebrigen legten still ein falsches
# Verzeichnis in auto_path und pruefen dann das pdf4tcl, das auf dem
# Rechner zufaellig installiert ist -- gruen, und ueber die falsche
# Fassung.
#
# Markierung ist pkgIndex.tcl neben src/; beides gibt es nur in der Wurzel.
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

set outdir [expr {$argc > 0 ? [lindex $argv 0] : $demodir}]
if {[file isdirectory $outdir]} {
    set outfile [file join $outdir demo-tagged.pdf]
} else {
    set outfile $outdir
}

# PDF/UA verlangt eingebettete Fontprogramme (ISO 14289-1 Kapitel 7.21.4.1).
# Die Base-14-Fonts haben gar kein einbettbares Programm, deshalb FreeSans.
set fontFile [file join $reporoot examples FreeSans.ttf]
pdf4tcl::loadBaseTrueTypeFont BaseFreeSans $fontFile
pdf4tcl::createFont BaseFreeSans DemoFont iso8859-1

set pdf [::pdf4tcl::new %AUTO% -paper a4 -margin 50 -compress 1]

# -ua 1 behauptet PDF/UA-Konformitaet. Bewusst opt-in: pdf4tcl kann sie nicht
# pruefen, dafuer sind Fonts, Titel, vollstaendige Auszeichnung und eine
# sinnvolle Ueberschriftenordnung Sache des Aufrufers.
$pdf tagged 1 -lang de-DE -ua 1
$pdf metadata -title "Tagged PDF Demo" -author "pdf4tcl" \
        -subject "Logische Struktur, Barrierefreiheit"
$pdf viewerPreferences -displaydoctitle 1

lassign [$pdf getDrawableArea] areaWidth areaHeight

set y 0
proc down {points} {
    upvar 1 y y
    incr y $points
    return $y
}

proc kopfzeile {pdf areaWidth} {
    # Kolumnentitel: kein Inhalt, sondern Artefakt. Artefakte tragen keine
    # MCID und werden von Screenreadern uebersprungen.
    $pdf tagArtifact -type Pagination -subtype Header
    $pdf setFont 8 DemoFont
    $pdf text "pdf4tcl -- Tagged PDF" -x 0 -y -20
    $pdf line 0 -14 $areaWidth -14
    $pdf tagArtifactEnd
}

proc fusszeile {pdf seite areaWidth areaHeight} {
    $pdf tagArtifact -type Pagination -subtype Footer
    $pdf setFont 8 DemoFont
    $pdf text "Seite $seite" -x [expr {$areaWidth - 40}] \
            -y [expr {$areaHeight - 4}]
    $pdf tagArtifactEnd
}

# --------------------------------------------------------------- Seite 1
$pdf startPage
kopfzeile $pdf $areaWidth
fusszeile $pdf 1 $areaWidth $areaHeight

$pdf setFont 18 DemoFont
$pdf tagText H1 "Logische Struktur" -x 0 -y [down 18]

$pdf setFont 11 DemoFont
$pdf tagBegin P
$pdf text "Ein Absatz ist ein Strukturelement, auch wenn er ueber" -x 0 -y [down 30]
$pdf text "mehrere Zeilen laeuft oder eine Seite umbricht." -x 0 -y [down 15]
$pdf tagEnd

# Ein Link muss ausdruecklich in ein Link-Element gefasst werden. Sonst
# funktioniert er beim Klicken, ist aber fuer Screenreader unerreichbar.
$pdf tagBegin P
$pdf text "Quelltext auf der" -x 0 -y [down 22]
$pdf tagBegin Link -alt "pdf4tcl auf GitHub"
$pdf tagText Span "Projektseite" -x 100 -y $y
$pdf hyperlinkAdd 100 [expr {$y - 9}] 65 12 \
        "https://github.com/gregnix/pdf4tcl"
$pdf tagEnd
$pdf tagEnd

# --- Liste
$pdf setFont 14 DemoFont
$pdf tagText H2 "Liste" -x 0 -y [down 32]

$pdf setFont 11 DemoFont
$pdf tagBegin L -listnumbering Decimal
down 22
foreach {marke text} {
    "1." "Lbl traegt die Marke"
    "2." "LBody den Inhalt"
    "3." "ListNumbering nennt den Stil"
} {
    $pdf tagBegin LI
    $pdf tagText Lbl   $marke -x 10 -y $y
    $pdf tagText LBody $text  -x 30 -y $y
    $pdf tagEnd
    down 18
}
$pdf tagEnd

# --- Tabelle
$pdf setFont 14 DemoFont
$pdf tagText H2 "Tabelle" -x 0 -y [down 14]

$pdf setFont 10 DemoFont
$pdf tagBegin Table
down 22
$pdf tagBegin TR
set spalte 0
foreach kopf {Artikel Menge Preis} {
    # /Scope sagt, dass die Kopfzelle fuer ihre Spalte gilt; /ID erlaubt den
    # Datenzellen, sie ueber -headers ausdruecklich zu nennen.
    $pdf tagText TH $kopf -scope Column -id "h$spalte" \
            -x [expr {$spalte * 150}] -y $y
    incr spalte
}
$pdf tagEnd
down 16
foreach zeile {
    {Schraube 100 4,90}
    {Mutter   200 3,50}
    {Scheibe  500 1,20}
} {
    $pdf tagBegin TR
    set spalte 0
    foreach zelle $zeile {
        $pdf tagText TD $zelle -headers "h$spalte" \
                -x [expr {$spalte * 150}] -y $y
        incr spalte
    }
    $pdf tagEnd
    down 16
}
$pdf tagEnd

# --- Abbildung
$pdf setFont 14 DemoFont
$pdf tagText H2 "Abbildung" -x 0 -y [down 20]
down 20

# Eine Grafik enthaelt keinen Text. /Alt ist das Einzige, was ein
# Screenreader vorlesen kann.
$pdf tagBegin Figure -alt "Rotes Quadrat neben blauem Kreis" \
        -title "Abbildung 1"
$pdf setFillColor 0.8 0.1 0.1
$pdf rectangle 0 $y 50 50 -filled 1
$pdf setFillColor 0.1 0.2 0.8
$pdf circle 120 [expr {$y + 25}] 25 -filled 1
$pdf setFillColor 0 0 0
$pdf tagEnd
down 70

# --------------------------------------------------------------- Seite 2
# Dieser Absatz beginnt auf Seite 1 und endet auf Seite 2. Marked Content
# darf keine Streamgrenze ueberschreiten, also wird es am Seitenende
# geschlossen und auf der naechsten Seite neu geoeffnet -- ein Element, zwei
# Sequenzen, ein Eintrag im Baum.
$pdf setFont 11 DemoFont
$pdf tagBegin P
$pdf text "Dieser Absatz beginnt auf Seite eins ..." -x 0 -y [down 20]
$pdf startPage
kopfzeile $pdf $areaWidth
fusszeile $pdf 2 $areaWidth $areaHeight
$pdf text "... und endet auf Seite zwei." -x 0 -y 0
$pdf tagEnd

set y 0
down 40
$pdf setFont 14 DemoFont
$pdf tagText H2 "Was der Baum leistet" -x 0 -y $y

$pdf setFont 11 DemoFont
foreach satz {
    "Screenreader folgen dem Baum, nicht der Malreihenfolge."
    "Textextraktion und Copy-Paste behalten die Reihenfolge."
    "Reflow auf kleinen Bildschirmen wird moeglich."
    "Export nach HTML oder Word erhaelt die Struktur."
} {
    $pdf tagBegin P
    $pdf text $satz -x 0 -y [down 20]
    $pdf tagEnd
}

$pdf tagBegin P
$pdf text "Getaggt heisst aber nicht zugaenglich: ein Dokument, in dem" \
        -x 0 -y [down 30]
$pdf text "jeder Absatz P und jede Ueberschrift H1 ist, besteht jede" \
        -x 0 -y [down 15]
$pdf text "Pruefung und sagt einem Leser trotzdem nichts." -x 0 -y [down 15]
$pdf tagEnd

$pdf write -file $outfile
$pdf destroy

puts "Geschrieben: $outfile"
puts "Pruefen:     verapdf -f ua1 $outfile"
