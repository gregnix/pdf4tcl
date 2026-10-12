#!/usr/bin/env tclsh
# demo-forms-hex.tcl -- Formularfelder mit Hex-Zeichenketten
# Aufruf:    tclsh demo-forms-hex.tcl ?ausgabeverzeichnis?
#
# Eine Zeichenkette darf in PDF literal (...) oder hex <...> stehen.
# pdf4tcl schreibt literal; fremde Erzeuger oft hex -- Acrobat einen
# Feldnamen mit Umlaut als UTF-16BE <FEFF...>. Bis 0.9.4.70 fand getForms
# solche Felder nicht, und fillForms meldete "no such field".
#
# Die Demo schreibt ein Formular mit pdf4tcl und stellt danach die
# Schreibweise eines fremden Erzeugers nach: Name, Wert, Tooltip,
# Darstellung und Optionen in hex. Dann liest und fuellt sie es.
#
# Ausgabe (demo/out):
#   demo-forms-hex.pdf            Feldnamen "Strasse" (mit sz) und "farbe" in hex
#   demo-forms-hex-gefuellt.pdf   gefuellt

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
set scriptDir [file dirname [file normalize [info script]]]
set auto_path [linsert $auto_path 0 [pdf4tclRepoRoot $scriptDir]]
package require pdf4tcl

set outDir [file join $scriptDir out]
if {$argc > 0} { set outDir [lindex $argv 0] }
file mkdir $outDir

set klar [file join $outDir demo-forms-hex-klar.pdf]
set pdf  [file join $outDir demo-forms-hex.pdf]
set voll [file join $outDir demo-forms-hex-gefuellt.pdf]

# Bytes als <HEX>, Text als UTF-16BE mit BOM
proc hexStr {bytes} { return <[string toupper [binary encode hex $bytes]]> }
proc utf16Str {text} {
    set out FEFF
    foreach ch [split $text ""] { append out [format %04X [scan $ch %c]] }
    return <$out>
}

# ---------------------------------------------------------------------------
# 1. Formular schreiben
# ---------------------------------------------------------------------------
set p [pdf4tcl::new %AUTO% -paper a4 -orient true]
$p startPage
$p setFont 16 Helvetica-Bold
$p text "Formular mit Hex-Zeichenketten" -x 72 -y 60
$p setFont 10 Helvetica
$p text "Stra\u00dfe:" -x 72 -y 100
$p text "Farbe:"  -x 72 -y 130
$p setFont 11 Helvetica
$p addForm text 160 88 220 16 -id name -init "Meier" -tooltip "Ihre Stra\u00dfe"
$p addForm combobox 160 118 120 16 -id farbe -options {Rot Gruen Blau} -init Rot
$p endPage
$p write -file $klar
$p destroy

# ---------------------------------------------------------------------------
# 2. Wie ein fremder Erzeuger: die Zeichenketten der Felder in hex
# ---------------------------------------------------------------------------
set da "/Helvetica 11 Tf 0 g"
set map [list \
    "/T (name)"   "/T [utf16Str Stra\u00dfe]" \
    "/V (Meier)"  "/V [utf16Str M\u00fcller]" \
    "/TU (Ihre Stra\u00dfe)" \
                  "/TU [utf16Str "Ihre Stra\u00dfe"]" \
    "/DA ($da)"   "/DA [hexStr $da]" \
    "/T (farbe)"  "/T [hexStr farbe]" \
    "/V (Rot)"    "/V [hexStr Rot]" \
    "/Opt \[(Rot) (Gruen) (Blau) \]" \
                  "/Opt \[[hexStr Rot] [hexStr Gruen] [hexStr Blau]\]" \
]
set d [pdf4tcl::cat::ReadPdf $klar]
foreach o [dict keys $d] {
    if {![string is digit -strict $o]} continue
    dict set d $o full [string map $map [dict get $d $o full]]
}
pdf4tcl::cat::WritePdf $pdf $d
file delete $klar
puts "Geschrieben: $pdf"

# Wie es in der Datei steht
set ch [open $pdf rb]; set roh [read $ch]; close $ch
foreach k {/T /V /DA /Opt} {
    if {[regexp "(\\$k \[\\\[<\]\[^\\n\]{0,60})" $roh -> zeile]} {
        puts "  in der Datei: $zeile"
    }
}

# ---------------------------------------------------------------------------
# 3. Lesen
# ---------------------------------------------------------------------------
puts "\ngetForms:"
set f [pdf4tcl::getForms $pdf]
foreach id [lsort [dict keys $f]] {
    puts [format "  %-8s value=%-8s description=%s options=%s" $id \
            [dict get $f $id value] [dict get $f $id description] \
            [dict get $f $id options]]
}

# ---------------------------------------------------------------------------
# 4. Fuellen -- unter dem dekodierten Namen
# ---------------------------------------------------------------------------
set n [pdf4tcl::fillForms $pdf $voll \
        [dict create Stra\u00dfe "Hauptstra\u00dfe 1" farbe Blau]]
puts "\nfillForms: $n Felder -> $voll"
set f [pdf4tcl::getForms $voll]
foreach id [lsort [dict keys $f]] {
    puts [format "  %-8s value=%s" $id [dict get $f $id value]]
}

puts "\nFertig."
