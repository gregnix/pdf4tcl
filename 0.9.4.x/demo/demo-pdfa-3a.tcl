#!/usr/bin/env tclsh
# demo-pdfa-3a.tcl -- PDF/A-3a und PDF/UA-1 in einem Dokument
#
# Die uebrigen PDF/A-Demos zeigen Konformitaetsstufe B: archivierbar, aber
# nicht barrierefrei. Stufe A verlangt darueber hinaus einen Strukturbaum,
# eine Dokumentsprache und Unicode-Zuordnungen -- also genau das, was Tagged
# PDF ohnehin liefert. Beide Normen zusammen sind daher weniger Aufwand, als
# es aussieht: eine Zeile "tagged 1", und der Rest ist Auszeichnen.
#
# Aufruf:
#   tclsh demo-pdfa-3a.tcl
#   tclsh demo-pdfa-3a.tcl --out /tmp
#   tclsh demo-pdfa-3a.tcl --font /pfad/zu/font.ttf
#
# Abhaengigkeiten:
#   pdf4tcl 0.9.4.41 (Stufe A), 0.9.4.42 fuer Formularfelder im Baum
#   ein TrueType- oder OpenType-Font -- PDF/A verlangt eingebettete
#   Fontprogramme, und die 14 Standardfonts haben keine
#
# Ausgabe:
#   demo-pdfa-3a.pdf
#
# Pruefen:
#   python3 ../../tools/check-conformance.py demo-pdfa-3a.pdf
#   verapdf -f 3a  demo-pdfa-3a.pdf
#   verapdf -f ua1 demo-pdfa-3a.pdf

set demodir  [file dirname [file normalize [info script]]]
set reporoot [file normalize [file join $demodir ../..]]
set auto_path [linsert $auto_path 0 $reporoot]

package require pdf4tcl

# -----------------------------------------------------------------------------
# Argumente
# -----------------------------------------------------------------------------

set out_dir       [file join $demodir out]
set font_override ""

for {set i 0} {$i < [llength $argv]} {incr i} {
    set arg [lindex $argv $i]
    switch -- $arg {
        --out  { set out_dir       [lindex $argv [incr i]] }
        --font { set font_override [lindex $argv [incr i]] }
        default {
            puts stderr "Unbekanntes Argument: $arg"
            puts stderr "Aufruf: tclsh demo-pdfa-3a.tcl \[--out dir\] \[--font pfad\]"
            exit 1
        }
    }
}

file mkdir $out_dir

# -----------------------------------------------------------------------------
# Font suchen -- ohne eingebetteten Font kein PDF/A
# -----------------------------------------------------------------------------

set font_path $font_override
if {$font_path eq ""} {
    foreach candidate {
        /usr/share/fonts/truetype/dejavu/DejaVuSans.ttf
        /usr/share/fonts/truetype/freefont/FreeSans.ttf
        /usr/share/fonts/TTF/DejaVuSans.ttf
    } {
        if {[file readable $candidate]} { set font_path $candidate ; break }
    }
}
if {$font_path eq "" || ![file readable $font_path]} {
    set fallback [file join $reporoot examples FreeSans.ttf]
    if {[file readable $fallback]} { set font_path $fallback }
}
if {$font_path eq ""} {
    puts stderr "Kein TrueType-Font gefunden -- mit --font einen angeben."
    puts stderr "PDF/A verlangt eingebettete Fontprogramme; die 14"
    puts stderr "Standardfonts haben keine, deshalb geht es ohne nicht."
    exit 1
}

pdf4tcl::loadBaseTrueTypeFont BaseA3 $font_path
pdf4tcl::createFont BaseA3 Body   iso8859-1
pdf4tcl::createFont BaseA3 Head   iso8859-1

# -----------------------------------------------------------------------------
# Dokument
# -----------------------------------------------------------------------------

set ::pdf4tcl::warnings {}
set outfile [file join $out_dir demo-pdfa-3a.pdf]

# -pdfa 3a prueft beim Schreiben, ob Tagging und Sprache gesetzt sind, und
# wirft sonst -- pdfaid:conformance A ist eine Behauptung, auf die sich ein
# Leser verlaesst.
set pdf [pdf4tcl::new %AUTO% -paper a4 -margin 50 -pdfa 3a]

# -ua 1 beansprucht zusaetzlich PDF/UA-1. Seit 0.9.4.41 wird der
# pdfuaid-Namensraum dann ueber ein pdfaExtension-Schema deklariert, was
# PDF/A fuer jedes nicht vordefinierte Schema verlangt. Ohne das schlaegt
# die PDF/A-Pruefung fehl, obwohl mit dem Strukturbaum alles stimmt.
$pdf tagged 1 -lang de-DE -ua 1

# Ein Titel ist Pflicht: PDF/UA 7.1-10 verlangt, dass ein Leser ihn statt
# des Dateinamens ansagt, und dafuer muss er da sein.
$pdf metadata -title "Archivierbar und barrierefrei" \
              -author "pdf4tcl demo" \
              -subject "PDF/A-3a und PDF/UA-1 in einem Dokument"
$pdf viewerPreferences -displaydoctitle 1

$pdf startPage

$pdf setFont 18 Head
$pdf tagText H1 "PDF/A-3a und PDF/UA-1" -x 0 -y 20

$pdf setFont 11 Body
$pdf tagBegin P
$pdf text "Dieses Dokument erfuellt beide Normen zugleich." -x 0 -y 60
$pdf text "Archivierbar heisst: alles Noetige steckt in der Datei." -x 0 -y 76
$pdf text "Barrierefrei heisst: ein Screenreader findet sich zurecht." -x 0 -y 92
$pdf tagEnd

$pdf setFont 14 Head
$pdf tagText H2 "Was Stufe A verlangt" -x 0 -y 130

$pdf setFont 11 Body
$pdf tagBegin L -listnumbering Decimal
foreach {nr txt} {
    1 "einen Strukturbaum -- also Tagging"
    2 "eine Dokumentsprache, hier de-DE"
    3 "Unicode-Zuordnungen, die pdf4tcl ohnehin schreibt"
} {
    $pdf tagBegin LI
    $pdf tagText Lbl "$nr." -x 10 -y [expr {150 + ($nr - 1) * 18}]
    $pdf tagText LBody $txt -x 30 -y [expr {150 + ($nr - 1) * 18}]
    $pdf tagEnd
}
$pdf tagEnd

$pdf setFont 14 Head
$pdf tagText H2 "Eine Tabelle" -x 0 -y 220

# Kopfzellen brauchen /Scope: ISO 14289-1 Kapitel 7.5 verlangt es, wo sich
# die Beziehung zwischen Kopf- und Datenzelle nicht aus dem Layout ergibt.
# Mehrwortige Zellen brauchen Klammern, sonst zerfaellt "ISO 19005-3" in
# zwei Listenelemente und die Zeile hat eine Spalte zu viel.
set rows [list \
    [list "Norm" "Regelt" "Stufe"] \
    [list "ISO 19005-3" "Archivierung" "3a"] \
    [list "ISO 14289-1" "Zugaenglichkeit" "UA-1"]]
set y 245
set first 1
$pdf tagBegin Table
foreach row $rows {
    $pdf tagBegin TR
    set x 0
    foreach cell $row {
        if {$first} {
            $pdf setFont 11 Head
            $pdf tagBegin TH -scope Column
        } else {
            $pdf setFont 11 Body
            $pdf tagBegin TD
        }
        $pdf text $cell -x $x -y $y
        $pdf tagEnd
        incr x 160
    }
    $pdf tagEnd
    incr y 18
    set first 0
}
$pdf tagEnd

# Die Trennlinie ist Dekoration. Als Inhalt ausgezeichnet wuerde ein
# Screenreader sie ansagen, als bedeutete sie etwas.
$pdf tagArtifact -type Layout
$pdf setLineWidth 0.5
$pdf line 0 310 480 310
$pdf tagArtifactEnd

$pdf setFont 11 Body
$pdf tagBegin P
$pdf text "Mehr dazu auf der" -x 0 -y 330
$pdf tagEnd

# Ein Link braucht ein Link-Element, sonst erreicht ihn nur die Maus.
$pdf tagBegin Link -alt "pdf4tcl auf GitHub"
$pdf tagText Span "Projektseite" -x 95 -y 330
$pdf hyperlinkAdd 95 328 60 12 "https://github.com/gregnix/pdf4tcl"
$pdf tagEnd

# Die Fusszeile gehoert nicht zum Inhalt.
$pdf tagArtifact -type Pagination -subtype Footer
$pdf setFont 8 Body
$pdf text "pdf4tcl demo -- Seite 1" -x 0 -y 700
$pdf tagArtifactEnd

$pdf write -file $outfile
$pdf destroy

puts "pdf4tcl -- PDF/A-3a und PDF/UA-1"
puts "Geschrieben: $outfile"
if {[llength $::pdf4tcl::warnings]} {
    puts "Warnungen:"
    foreach w $::pdf4tcl::warnings { puts "  $w" }
} else {
    puts "Keine Warnungen."
}
puts ""
puts "Pruefen:"
puts "  python3 [file join $reporoot tools check-conformance.py] $outfile"
puts "  verapdf -f 3a  $outfile"
puts "  verapdf -f ua1 $outfile"
