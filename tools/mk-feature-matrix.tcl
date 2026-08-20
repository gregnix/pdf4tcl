#!/usr/bin/env tclsh
# mk-feature-matrix.tcl -- welches Thema hat welche Belege?
#
#   tclsh tools/mk-feature-matrix.tcl ?/pfad/zu/pdf4tcllib?
#
# Erzeugt eine Tabelle: je Thema eine Zeile, je Belegart eine Spalte. Sie
# zeigt nicht, was pdf4tcl kann -- das steht im Handbuch -- sondern wo ein
# Thema unbelegt ist: eine Funktion ohne Test, ein Howto ohne lauffaehiges
# Skript, ein Thema ohne Demo.
#
# VON HAND GEPFLEGT waere so eine Liste beim naechsten Bump falsch. Deshalb
# wird gesucht, nicht aufgezaehlt: die Themen kommen aus den Howto-Namen,
# die Belege aus dem Dateibestand. Was neu dazukommt, taucht von selbst auf.
#
# Ein Haken bleibt: gefunden wird, was den Namen traegt. Ein Test, der
# Kerning prueft und anders heisst, faellt durch. Die Spalte "Test" sucht
# deshalb zusaetzlich im Inhalt.

set root [file normalize [file join [file dirname [info script]] ..]]
set libRoot [lindex $argv 0]

# pdf4tcllib legt die Doku unter docs/en, pdf4tcl unter doc/en. Beide
# Baeume sind sonst gleich gebaut, also genuegt es, den Namen zu finden.
proc docWurzel {basis} {
    foreach k {doc/en docs/en} {
        if {[file isdirectory [file join $basis $k]]} {
            return [file join $basis $k]
        }
    }
    return [file join $basis doc en]
}
set docs [docWurzel $root]

# ---------------------------------------------------------------------------
# Themen: aus den Howto-Dateinamen, das ist der thematische Schnitt, den
# das Projekt selbst gewaehlt hat.
# ---------------------------------------------------------------------------
set themen {}
foreach f [lsort [glob -nocomplain -directory [file join $docs howtos] \
        howto-*.md]] {
    set name [file rootname [file tail $f]]
    set name [string range $name 6 end]      ;# "howto-" weg
    if {$name in {run-demos cheatsheets feature-tour}} { continue }
    lappend themen $name
}

# Ein paar Themen haben kein Howto, sind aber zu wichtig zum Weglassen.
# Hier stehen sie ausdruecklich, damit die Luecke sichtbar bleibt statt zu
# fehlen.
# Nur fuer pdf4tcl -- pdf4tcllib kennt beides nicht, dort waere die Zeile
# eine Luecke, die keine ist.
if {[file readable [file join $root pdf4tcl.man]]} {
    foreach extra {tagged-pdf xobject-tagging} {
        if {$extra ni $themen} { lappend themen $extra }
    }
}
set themen [lsort $themen]

# ---------------------------------------------------------------------------
# Suchhilfen
# ---------------------------------------------------------------------------

# Passt ein Dateiname zum Thema? "links-and-bookmarks" trifft auch
# "links-bookmarks" und "bookmarks".
proc passt {name thema} {
    set n [string tolower $name]
    set t [string tolower $thema]
    if {[string match "*$t*" $n]} { return 1 }
    foreach teil [split $t "-"] {
        if {[string length $teil] < 4} { continue }
        if {[string match "*$teil*" $n]} { return 1 }
    }
    return 0
}

proc dateiTreffer {verzeichnis muster thema} {
    foreach f [glob -nocomplain -directory $verzeichnis $muster] {
        if {[passt [file tail $f] $thema]} { return 1 }
    }
    return 0
}

# Fuer Tests zusaetzlich im Inhalt suchen: ein Test kann das Thema pruefen
# und anders heissen. Ohne das meldet die Tabelle Luecken, die keine sind.
proc inhaltTreffer {verzeichnis muster woerter} {
    foreach f [glob -nocomplain -directory $verzeichnis $muster] {
        if {[catch {open $f r} ch]} { continue }
        set data [read $ch]
        close $ch
        foreach w $woerter {
            if {[string length $w] < 4} { continue }
            if {[string match -nocase "*$w*" $data]} { return 1 }
        }
    }
    return 0
}

proc zeichen {ja} { return [expr {$ja ? "x" : "-"}] }

# Wonach im Testinhalt zu suchen ist, wenn der Themenname dort nicht
# vorkommt. Von Hand gepflegt -- das laesst sich nicht erraten.
set ::synonyme {
    shapes      {circle rectangle polygon arc}
    symbols     {ZapfDingbats Symbol}
    stdfonts    {Helvetica Courier Times-Roman}
    catpdf      {catPdf}
    facturx     {facturx ZUGFeRD}
    tagged-pdf  {tagBegin tagText StructTreeRoot}
    xobject-tagging {beginXObject tagArtifact}
    write-chan  {writeChan}
    otf         {OpenType CFF}
    paper-sizes {getPaperSize a4}
    embed-file  {addEmbeddedFile embedFile}
    font-coverage {fontCoverage}
    headers-footers {addHeader addFooter}
    links-and-bookmarks {hyperlinkAdd bookmark}
    encrypted-forms {addForm encrypt}
}

# ---------------------------------------------------------------------------
# Sammeln
# ---------------------------------------------------------------------------
set zeilen {}
set luecken {}

foreach thema $themen {
    set woerter [split $thema "-"]
    # Ein Thema heisst im Test oft anders als im Howto. Ohne diese
    # Ergaenzung meldet die Tabelle Luecken, die keine sind: "shapes" wird
    # in canvas.test geprueft, "symbols" in font.test.
    if {[dict exists $::synonyme $thema]} {
        set woerter [concat $woerter [dict get $::synonyme $thema]]
    }

    set ref   [dateiTreffer [file join $docs reference]  *.md   $thema]
    set howto [dateiTreffer [file join $docs howtos]     *.md   $thema]
    set hscr  [dateiTreffer [file join $docs howtos]     *.tcl  $thema]
    set tut   [dateiTreffer [file join $docs tutorials]  *.md   $thema]
    set demo  [dateiTreffer [file join $root demo]              *.tcl  $thema]
    # Beispiele liegen flach (pdf4tcl) oder in basic/ und advanced/
    # (pdf4tcllib).
    set bsp 0
    foreach d [list [file join $root examples] \
                    [file join $root examples basic] \
                    [file join $root examples advanced]] {
        if {[dateiTreffer $d *.tcl $thema]} { set bsp 1; break }
    }
    # pdf4tcl nennt sie *.test, pdf4tcllib test_*.tcl -- beides suchen.
    set test 0
    foreach muster {*.test test_*.tcl} {
        if {[dateiTreffer [file join $root tests] $muster $thema]
                || [inhaltTreffer [file join $root tests] $muster $woerter]} {
            set test 1
            break
        }
    }

    # Handbuch: ein Thema gilt als belegt, wenn es im Text vorkommt.
    set man 0
    if {[file readable [file join $root pdf4tcl.man]]} {
        set ch [open [file join $root pdf4tcl.man] r]
        set manData [read $ch]
        close $ch
        foreach w $woerter {
            if {[string length $w] >= 4
                    && [string match -nocase "*$w*" $manData]} { set man 1 }
        }
    }

    set lib "-"
    if {$libRoot ne "" && [file isdirectory $libRoot]} {
        set l [expr {[dateiTreffer [file join $libRoot lib] *.tm $thema]
                || [dateiTreffer [file join $libRoot examples basic] *.tcl $thema]
                || [dateiTreffer [file join $libRoot examples advanced] *.tcl $thema]}]
        set lib [zeichen $l]
    }

    lappend zeilen [list $thema $man $ref $howto $hscr $tut $demo $bsp $test $lib]
    if {!$test || !$howto} { lappend luecken $thema }
}

# ---------------------------------------------------------------------------
# Ausgeben
# ---------------------------------------------------------------------------
set breite 0
foreach z $zeilen {
    set l [string length [lindex $z 0]]
    if {$l > $breite} { set breite $l }
}

puts "| [format %-${breite}s Thema] | man | ref | howto | .tcl | tut | demo | bsp | test | lib |"
puts "|[string repeat - [expr {$breite + 2}]]|-----|-----|-------|------|-----|------|-----|------|-----|"
foreach z $zeilen {
    lassign $z thema man ref howto hscr tut demo bsp test lib
    puts "| [format %-${breite}s $thema] |  [zeichen $man]  |  [zeichen $ref]  |\
            [format %-5s "  [zeichen $howto]"] |  [zeichen $hscr]   |  [zeichen $tut]  |\
            [format %-4s "  [zeichen $demo]"] |  [zeichen $bsp]  |  [zeichen $test]   |  $lib  |"
}
puts ""
puts "[llength $zeilen] Themen. Spalten: man=pdf4tcl.man, ref=reference/,"
puts "howto=howtos/*.md, .tcl=lauffaehiges Howto-Skript, tut=tutorials/,"
puts "demo=demo/, bsp=examples/, test=tests/, lib=pdf4tcllib."
puts ""
puts "Ein \"-\" ist keine Fehlermeldung. Nicht jedes Thema braucht ein"
puts "Tutorial, und pdf4tcllib deckt bewusst nur einen Teil ab."
if {[llength $luecken]} {
    puts ""
    puts "Ohne Test oder ohne Howto: [join $luecken {, }]"
}
