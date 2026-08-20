#!/usr/bin/env tclsh
# demo-catpdf.tcl -- Demo: Dokumente zusammenfuehren (pdf4tcl 0.9.4.48)
#
# Zeigt, was catPdf tut und was nicht:
#   - der Titel des Ergebnisses (-title, seit 0.9.4.48)
#   - Fonts werden geteilt, gemessen an der Dateigroesse
#   - welche Eingaben abgelehnt werden und warum
#
# Aufruf:  tclsh demo-catpdf.tcl [ausgabeverzeichnis]

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

set outdir [lindex $argv 0]
if {$outdir eq ""} { set outdir [file dirname [info script]] }
file mkdir $outdir
proc out {name} { return [file join $::outdir $name] }

# Eine eingebettete Schrift, damit sich am Zusammenfuehren zeigt, ob das
# Fontprogramm doppelt landet. Mit Helvetica waere nichts zu messen.
set fontPath ""
foreach candidate {
    /usr/share/fonts/truetype/freefont/FreeSans.ttf
    /usr/share/fonts/truetype/dejavu/DejaVuSans.ttf
    /usr/share/fonts/TTF/DejaVuSans.ttf
} {
    if {[file exists $candidate]} { set fontPath $candidate; break }
}
set haveTtf [expr {$fontPath ne ""}]
if {$haveTtf} {
    pdf4tcl::loadBaseTrueTypeFont DemoBase $fontPath
    pdf4tcl::createFontSpecCID DemoBase DemoFont
    set useFont DemoFont
} else {
    puts "Keine TrueType-Schrift gefunden -- der Groessenvergleich entfaellt."
    set useFont Helvetica
}

# ---------------------------------------------------------------------------
# Hilfsmittel
# ---------------------------------------------------------------------------

proc teil {file titel text} {
    set p [pdf4tcl::new %AUTO% -paper a4]
    $p metadata -title $titel -author "Demo"
    $p startPage
    $p setFont 14 $::useFont
    $p text $titel -x 60 -y 60
    $p setFont 11 $::useFont
    $p text $text -x 60 -y 90
    $p write -file $file
    $p destroy
}

# Den Titel ueber /Info aus dem Trailer lesen, NICHT das erste /Title in
# der Datei: das /Info der angehaengten Dokumente bleibt unreferenziert
# liegen und steht sogar davor.
proc infoTitel {file} {
    set fh [open $file rb]
    set data [read $fh]
    close $fh
    if {![regexp {/Info\s+(\d+)\s+0\s+R} $data -> id]} { return "(keiner)" }
    if {![regexp "\n$id\\s+0\\s+obj(.*?)endobj" $data -> body]} { return "(keiner)" }
    if {[regexp {/Title\s*\(([^)]*)\)} $body -> t]} { return $t }
    return "(keiner)"
}

# Die VERSCHIEDENEN Objekte zaehlen, auf die /FontFile2 zeigt -- nicht
# die Verweise. Mehrere FontDescriptor koennen auf dasselbe Programm
# zeigen, und genau das ist der Punkt: "grep -c FontFile2" liefert 4 und
# legt zwei Programme nahe, wo eines liegt.
proc fontProgramme {file} {
    set fh [open $file rb]
    set data [read $fh]
    close $fh
    set ids {}
    foreach {voll id} [regexp -all -inline {/FontFile2\s+(\d+)\s+0\s+R} $data] {
        if {$id ni $ids} { lappend ids $id }
    }
    return [llength $ids]
}

# ---------------------------------------------------------------------------
# 1. Der Titel des zusammengefuehrten Dokuments
# ---------------------------------------------------------------------------

puts "\n1. Titel"
puts [string repeat - 60]

teil [out demo-cat-1.pdf] "Teil eins" "Inhalt des ersten Teils."
teil [out demo-cat-2.pdf] "Teil zwei" "Inhalt des zweiten Teils."

pdf4tcl::catPdf [out demo-cat-1.pdf] [out demo-cat-2.pdf] [out demo-cat-ohne.pdf]
puts "  ohne Option:  [infoTitel [out demo-cat-ohne.pdf]]"

# Zusammenfuehren behaelt den Katalog des ERSTEN Dokuments, und damit
# dessen /Info. Ein Werkzeug kann nicht wissen, wie zwei Dokumente
# zusammen heissen -- also sagt man es ihm.
pdf4tcl::catPdf -title "Gesamtwerk" -author "Demo" \
        [out demo-cat-1.pdf] [out demo-cat-2.pdf] [out demo-cat-mit.pdf]
puts "  mit -title:   [infoTitel [out demo-cat-mit.pdf]]"

# Ein leerer Wert ENTFERNT den Eintrag -- besser kein Titel als der
# falsche.
pdf4tcl::catPdf -title "" \
        [out demo-cat-1.pdf] [out demo-cat-2.pdf] [out demo-cat-leer.pdf]
puts "  mit -title \"\": [infoTitel [out demo-cat-leer.pdf]]"

# ---------------------------------------------------------------------------
# 2. Fonts werden geteilt
# ---------------------------------------------------------------------------

if {$haveTtf} {
    puts "\n2. Dateigroesse -- das Fontprogramm liegt einmal drin"
    puts [string repeat - 60]

    foreach n {3 4} {
        teil [out demo-cat-$n.pdf] "Teil $n" "Noch ein Teil."
    }
    pdf4tcl::catPdf \
            [out demo-cat-1.pdf] [out demo-cat-2.pdf] \
            [out demo-cat-3.pdf] [out demo-cat-4.pdf] \
            [out demo-cat-vier.pdf]

    set einzeln 0
    foreach n {1 2 3 4} { incr einzeln [file size [out demo-cat-$n.pdf]] }
    set zusammen [file size [out demo-cat-vier.pdf]]

    puts [format "  4 Dateien einzeln:  %8d Bytes" $einzeln]
    puts [format "  zusammengefuehrt:   %8d Bytes" $zusammen]
    puts "  /FontFile2 im Ergebnis: [fontProgramme [out demo-cat-vier.pdf]]"
    puts "\n  DedupObjects faltet Objekte mit gleichem Koerper zusammen. Die"
    puts "  Font-WOERTERBUECHER bleiben doppelt -- das Umnummerieren macht"
    puts "  ihre Koerper unterschiedlich -- das kostet ein paar hundert Bytes."
}

# ---------------------------------------------------------------------------
# 3. Eingabeformen
# ---------------------------------------------------------------------------

puts "\n3. Eingabeformen"
puts [string repeat - 60]

# PDF/A-1 verbietet xref-Streams, PDF/A-2 und -3 verlangen sie. Seit
# 0.9.4.49 liest catPdf beide Formen -- bis dahin liess sich kein
# Archivdokument ab 2b zusammenfuehren.
foreach level {1b 2b} {
    foreach seite {a b} {
        set p [pdf4tcl::new %AUTO% -paper a4 -pdfa $level]
        $p startPage
        $p setFont 12 $useFont
        $p text "PDF/A-$level, Teil $seite" -x 60 -y 60
        $p write -file [out demo-cat-$level-$seite.pdf]
        $p destroy
    }
    if {[catch {
        pdf4tcl::catPdf [out demo-cat-$level-a.pdf] [out demo-cat-$level-b.pdf] \
                [out demo-cat-$level-zus.pdf]
    } err]} {
        puts "  PDF/A-$level: abgelehnt"
        puts "    [string range $err 0 70]..."
    } else {
        puts "  PDF/A-$level: zusammengefuehrt"
    }
}

puts "\n  Seit 0.9.4.50 werden auch /ObjStm-Container ausgepackt --"
puts "  Dateien aus anderen Werkzeugen also ebenfalls. qpdf schreibt sie"
puts "  standardmaessig."
puts ""
puts "  Eine Falle liegt dabei in der EINGABE: qpdf schreibt ohne"
puts "  --newline-before-endstream Streams ohne Zeilenende davor und"
puts "  verletzt damit ISO 19005-2 Klausel 6.1.7.1. Die Eingabe faellt"
puts "  dann schon bei veraPDF durch, und alles daraus ebenso."

puts "\nDateien in $outdir"
