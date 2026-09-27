#!/usr/bin/env tclsh
# demo-cidsubset.tcl -- pdf4tcl 0.9.4.68: was in einer eingebetteten
# CID-Teilschrift wirklich steht
#
# demo-cidfont.tcl zeigt, was man SIEHT: Unicode-Text in einer CID-Schrift.
# Dieser Demo zeigt, was man NICHT sieht -- und genau dort lagen die beiden
# Fehler, die 0.9.4.68 behebt:
#
#   * Bis 0.9.4.67 fehlte in der eingebetteten Schrift die cmap. Sie ist eine
#     Pflichttabelle; die Teilschrift war also keine gueltige Schrift. Jede
#     Anzeige, die /CIDToGIDMap /Identity folgt, zeichnete trotzdem, pdftotext
#     lieferte den richtigen Text, qpdf fand keinen Syntaxfehler -- und der
#     Adobe Reader zeigte eine leere Seite.
#   * Die Pruefsummen im Tabellenverzeichnis standen alle auf 0, und
#     checkSumAdjustment trug noch den Wert der AUSGANGSSCHRIFT. pdf4tcl hat
#     sein eigenes Erzeugnis abgelehnt: loadBaseTrueTypeFont verlangt die
#     Gesamtsumme 0xB1B0AFBA.
#
# Beides ist an einem fertigen PDF nicht zu sehen, solange man nur hineinsieht
# und nicht hineinrechnet. Dieser Demo rechnet: er schreibt ein PDF, holt die
# eingebettete Schrift wieder heraus und prueft sie.
#
# Aufruf:  tclsh demo-cidsubset.tcl [/pfad/zur/schrift.ttf]
#
# Der Ausgang ist 0, wenn alles stimmt, und 1, wenn nicht -- damit taugt der
# Demo auch als Handprobe nach einer Aenderung an MakeCIDSubset oder
# CIDRebuildTtf.

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
lappend auto_path [pdf4tclRepoRoot [file dirname [info script]]]
package require pdf4tcl

set fontPath [lindex $argv 0]
if {$fontPath eq ""} {
    foreach kandidat {
        /usr/share/fonts/truetype/dejavu/DejaVuSans.ttf
        /usr/share/fonts/TTF/DejaVuSans.ttf
        /Library/Fonts/DejaVuSans.ttf
        C:/Windows/Fonts/arial.ttf
    } {
        if {[file exists $kandidat]} { set fontPath $kandidat ; break }
    }
}
if {$fontPath eq "" || ![file exists $fontPath]} {
    puts stderr "Keine TrueType-Schrift gefunden. Pfad als Argument angeben."
    exit 2
}

set demoOutDir [file join [file dirname [file normalize [info script]]] out]
file mkdir $demoOutDir
set outFile [file join $demoOutDir demo-cidsubset.pdf]

# ---------------------------------------------------------------------------
# 1. Ein PDF mit einer CID-Teilschrift schreiben
# ---------------------------------------------------------------------------
pdf4tcl::loadBaseTrueTypeFont demoBase $fontPath
pdf4tcl::createFontSpecCID demoBase demoCid
set pdf [pdf4tcl::new %AUTO% -paper a4 -compress 0]
$pdf startPage
$pdf setFont 16 demoCid
$pdf text "pdf4tcl: CID-Teilschrift von innen" -x 50 -y 60
$pdf setFont 11 demoCid
set y 95
foreach zeile {
    "Im Inhaltsstrom stehen GLYPHENNUMMERN, nicht Unicode."
    "ToUnicode macht daraus wieder Text -- darum findet pdftotext ihn."
    "Die cmap der Schrift bildet Code N auf Glyphe N ab."
    "Gruesse aus Muenchen: \u00e4\u00f6\u00fc\u00df \u2014 \u00c4\u00d6\u00dc"
} {
    $pdf text $zeile -x 50 -y $y
    incr y 20
}
$pdf endPage
$pdf write -file $outFile
$pdf destroy
puts "Erstellt: $outFile"

# ---------------------------------------------------------------------------
# 2. Die eingebettete Schrift wieder herausholen
#
# Eine TrueType-Datei beginnt mit 00 01 00 00. Im unkomprimierten PDF ist das
# der Anfang des FontFile2-Stroms. Das Ende ergibt sich aus dem weitesten
# Tabellenende im Verzeichnis -- verlaesslicher als /Length zu suchen.
# ---------------------------------------------------------------------------
set fh [::open $outFile rb]
set pdfdaten [read $fh]
::close $fh
set anfang [string first "\x00\x01\x00\x00" $pdfdaten]
if {$anfang < 0} {
    puts stderr "Keine eingebettete TrueType-Datei gefunden."
    exit 1
}
set roh [string range $pdfdaten $anfang end]
binary scan $roh IuSu ttfVer anzahl
set verzeichnis {}
set ende 0
for {set i 0} {$i < $anzahl} {incr i} {
    set o [expr {12 + $i * 16}]
    binary scan [string range $roh $o [expr {$o + 15}]] a4IuIuIu tag chk off len
    dict set verzeichnis [string trimright $tag] [list $chk $off $len]
    if {$off + $len > $ende} { set ende [expr {$off + $len}] }
}
# auf vier Bytes aufrunden: die letzte Tabelle ist gepolstert
while {$ende % 4} { incr ende }
set ttf [string range $roh 0 [expr {$ende - 1}]]
puts "Eingebettete Schrift: [string length $ttf] Bytes, $anzahl Tabellen"

set fehler {}

# ---------------------------------------------------------------------------
# 3. Die Pflichttabellen
# ---------------------------------------------------------------------------
puts ""
puts "Tabellen:"
puts "   [join [lsort [dict keys $verzeichnis]] { }]"
# Apple TrueType Reference, Font Tables, Table 2
set pflicht {cmap glyf head hhea hmtx loca maxp name post}
set fehlend {}
foreach tag $pflicht {
    if {![dict exists $verzeichnis $tag]} { lappend fehlend $tag }
}
if {[llength $fehlend]} {
    lappend fehler "Pflichttabellen fehlen: $fehlend"
    puts "   FEHLT: $fehlend"
} else {
    puts "   alle neun Pflichttabellen da"
}

# ---------------------------------------------------------------------------
# 4. Die Pruefsummen
#
# head ist der Sonderfall: seine Tabellenpruefsumme wird mit
# checkSumAdjustment = 0 gerechnet, weil das Feld erst danach gesetzt wird.
# ---------------------------------------------------------------------------
puts ""
puts "Pruefsummen:"
set schlechte {}
foreach tag [lsort [dict keys $verzeichnis]] {
    lassign [dict get $verzeichnis $tag] chk off len
    set echt [::pdf4tcl::CalcTTFCheckSum $ttf $off $len]
    if {$tag eq "head"} {
        binary scan [string range $ttf [expr {$off + 8}] [expr {$off + 11}]] Iu adj
        set echt [expr {($echt - $adj) & 0xFFFFFFFF}]
    }
    if {$echt != $chk} { lappend schlechte $tag }
}
if {[llength $schlechte]} {
    lappend fehler "Tabellen mit falscher Pruefsumme: $schlechte"
    puts "   FALSCH: $schlechte"
} else {
    puts "   alle $anzahl Tabellensummen stimmen"
}
set gesamt [::pdf4tcl::CalcTTFCheckSum $ttf 0 [string length $ttf]]
puts "   Gesamtsumme: [format 0x%08X $gesamt] (verlangt 0xB1B0AFBA)"
if {$gesamt != 0xB1B0AFBA} {
    lappend fehler "Gesamtsumme [format 0x%08X $gesamt]"
}
lassign [dict get $verzeichnis head] hchk hoff hlen
binary scan [string range $ttf [expr {$hoff + 8}] [expr {$hoff + 11}]] Iu adj
puts "   head.checkSumAdjustment: [format 0x%08X $adj]"

# ---------------------------------------------------------------------------
# 5. Die cmap
# ---------------------------------------------------------------------------
puts ""
puts "cmap:"
if {![dict exists $verzeichnis cmap]} {
    puts "   keine -- bis 0.9.4.67 war das der Zustand"
} else {
    lassign [dict get $verzeichnis cmap] cchk coff clen
    set cmap [string range $ttf $coff [expr {$coff + $clen - 1}]]
    lassign [dict get $verzeichnis maxp] mchk moff mlen
    binary scan [string range $ttf [expr {$moff + 4}] [expr {$moff + 5}]] Su numGlyphs
    binary scan $cmap SuSu cver untertabellen
    puts "   $clen Bytes, $untertabellen Untertabelle(n), numGlyphs $numGlyphs"
    for {set i 0} {$i < $untertabellen} {incr i} {
        set o [expr {4 + $i * 8}]
        binary scan [string range $cmap $o [expr {$o + 7}]] SuSuIu plat enc soff
        set s [string range $cmap $soff end]
        binary scan $s SuSu fmt len
        puts "   Plattform $plat, Kodierung $enc, Format $fmt, $len Bytes"
        if {$fmt != 4} { continue }
        binary scan [string range $s 6 7] Su segX2
        set seg [expr {$segX2 / 2}]
        set p 14
        binary scan [string range $s $p [expr {$p + $segX2 - 1}]] Su$seg endc
        incr p [expr {$segX2 + 2}]
        binary scan [string range $s $p [expr {$p + $segX2 - 1}]] Su$seg startc
        incr p $segX2
        binary scan [string range $s $p [expr {$p + $segX2 - 1}]] S$seg delta
        foreach a $startc b $endc d $delta {
            if {$a == 0xFFFF} {
                puts "      Marke FFFF -> Glyphe [expr {(0xFFFF + $d) % 65536}]"
                continue
            }
            puts "      Codes $a..$b, idDelta $d -> Glyphen [expr {$a + $d}]..[expr {$b + $d}]"
            if {$d != 0} { lappend fehler "idDelta $d: Code ist nicht die Glyphe" }
            if {$b >= $numGlyphs} {
                lappend fehler "Segment reicht bis $b, numGlyphs ist $numGlyphs"
            }
        }
    }
}

# ---------------------------------------------------------------------------
# 5b. /Flags der Schriftbeschreibung
#
# Die cmap allein genuegte nicht. loadBaseTrueTypeFont setzt fuer jede
# TrueType-Schrift pauschal Bit 3 ("symbolic"), auch fuer eine reine
# Textschrift. ISO 32000-1 zu einer symbolischen Schrift: sie soll eine
# (3,0)- oder (1,0)-cmap haben, "otherwise it leaves the character code to
# GID mapping up to the PDF reader". Die angehaengte Tabelle ist (3,1) --
# symbolisch plus nur (3,1) ist die Grauzone, in der Umsetzungen
# auseinanderlaufen. Seit 0.9.4.69 traegt der CID-Weg Bit 6
# ("nonsymbolic", 32) statt Bit 3.
# ---------------------------------------------------------------------------
puts ""
puts "Schriftbeschreibung:"
set gefunden 0
# "split $pdfdaten endobj" waere falsch: split trennt an JEDEM ZEICHEN der
# zweiten Zeichenkette. Erst eine Marke setzen.
foreach stueck [split [string map [list endobj \u0000] $pdfdaten] \u0000] {
    if {![string match *FontDescriptor* $stueck]} continue
    if {![regexp {/FontName\s*/(\S+)} $stueck -> fname]} continue
    if {![regexp {/Flags\s+(\d+)} $stueck -> flags]} continue
    incr gefunden
    set bits {}
    if {$flags & 1}        { lappend bits "fester Schritt" }
    if {$flags & 4}        { lappend bits "SYMBOLISCH" }
    if {$flags & 32}       { lappend bits "nicht symbolisch" }
    if {$flags & 64}       { lappend bits "kursiv" }
    if {$flags & (1<<18)}  { lappend bits "fett erzwungen" }
    puts "   $fname: /Flags $flags ([join $bits {, }])"
    if {$flags & 4} {
        lappend fehler "$fname ist symbolisch markiert, die cmap ist aber (3,1)"
    }
    if {!($flags & 32)} {
        lappend fehler "$fname ist nicht als nicht-symbolisch markiert"
    }
}
if {!$gefunden} { lappend fehler "keine Schriftbeschreibung gefunden" }

# ---------------------------------------------------------------------------
# 6. Der Rundlauf: nimmt pdf4tcl sein eigenes Erzeugnis?
#
# Das ist die schaerfste Probe und braucht keinen Betrachter. Bis 0.9.4.67
# schlug sie fehl: "invalid TTF file checksum".
# ---------------------------------------------------------------------------
puts ""
set probe [file join $demoOutDir demo-cidsubset-extrahiert.ttf]
set fh [::open $probe wb]
puts -nonewline $fh $ttf
::close $fh
set rc [catch {pdf4tcl::loadBaseTrueTypeFont demoRueck $probe 1} meldung]
if {$rc} {
    puts "loadBaseTrueTypeFont auf die eigene Teilschrift: ABGELEHNT"
    puts "   $meldung"
    lappend fehler "die eigene Ladefunktion lehnt die eigene Teilschrift ab"
} else {
    puts "loadBaseTrueTypeFont auf die eigene Teilschrift: angenommen"
}
puts "Herausgeschrieben: $probe"

# ---------------------------------------------------------------------------
puts ""
if {[llength $fehler]} {
    puts "NICHT IN ORDNUNG:"
    foreach f $fehler { puts "   - $f" }
    exit 1
}
puts "Alles in Ordnung: gueltige Schrift, richtige Pruefsummen, Code N ist\n   Glyphe N, und die Schrift ist nicht als symbolisch markiert."
exit 0
