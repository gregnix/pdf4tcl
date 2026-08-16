#!/usr/bin/env tclsh
# run-all-demos.tcl -- alle pdf4tcl Demos ausfuehren
#
# Fuehrt alle Demo-Skripte aus und sammelt Ergebnisse.
# Demos die Tk benoetigen werden uebersprungen wenn kein DISPLAY gesetzt ist.
#
# Usage:
#   tclsh run-all-demos.tcl              -- Ausgabe nach demo/out/
#   tclsh run-all-demos.tcl --outdir /tmp/pdfout
#   tclsh run-all-demos.tcl --alle       -- auch die sonst uebersprungenen

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

# ---------------------------------------------------------------------------
# Argumente
# ---------------------------------------------------------------------------

set outdir [file join $demodir out]
set idx [lsearch $argv --outdir]
if {$idx >= 0} {
    set outdir [lindex $argv [expr {$idx + 1}]]
}
file mkdir $outdir

# --alle laesst auch die Demos laufen, die sonst mit Grund uebersprungen
# werden (langsame Verschluesselung, optionale Pakete).
set runAll [expr {[lsearch -exact $argv --alle] >= 0}]

# ---------------------------------------------------------------------------
# Tk verfuegbar?
# ---------------------------------------------------------------------------

set hasTk [expr {[info exists env(DISPLAY)] && $env(DISPLAY) ne ""}]

# ---------------------------------------------------------------------------
# Zeitgrenze je Demo
# ---------------------------------------------------------------------------
#
# exec wartet ohne Grenze. Eine Demo, die Tk laedt und kein exit hat, geht am
# Skriptende in die Event-Loop und haelt den Sammellauf fest -- und zwar nur
# auf einer Maschine mit Anzeige. Ohne DISPLAY wird dieselbe Demo
# uebersprungen, der Lauf ist gruen, und niemand sieht es.
#
# timeout(1) stammt aus den coreutils und fehlt auf Windows. Wo es fehlt,
# laeuft es wie bisher -- eine Zeitgrenze in reinem Tcl braeuchte
# nichtblockierende Kanaele und eine eigene Event-Schleife, was fuer einen
# Demo-Runner zu viel Apparat ist.

set demoTimeout 120
set timeoutCmd {}
if {[llength [auto_execok timeout]] > 0} {
    set timeoutCmd [list timeout $demoTimeout]
}

# timeout(1) beendet mit 124, wenn die Grenze zuschlug.
proc TimedOut {} {
    return [expr {[lindex $::errorCode 0] eq "CHILDSTATUS"
                  && [lindex $::errorCode 2] == 124}]
}

# ---------------------------------------------------------------------------
# Demo-Liste
# Eintraege: {skriptname tk_erforderlich beschreibung}
# ---------------------------------------------------------------------------

# Demo-Liste
# Eintraege: {skriptname tk_erforderlich argschema beschreibung ?grund?}
# argschema:
#   none      -- kein Argument. Diese Demos schreiben immer nach demo/out und
#                folgen --outdir NICHT: ihre Argumente sind bereits mit
#                Font-Pfaden belegt. Betrifft demo-api-vergleich, demo-cidfont,
#                demo-symbole, demo-unicode-tabelle und demo-make-cheatsheets.
#   dir       -- outdir als positionales Argument
#   file NAME -- outdir/NAME als positionales Argument
#   --out     -- --out outdir
#   --out+    -- --out outdir (plus weitere feste Argumente moeglich)
#
# grund (optional): ist er gesetzt, wird die Demo uebersprungen und der Grund
# ausgegeben. So steht jede bewusst ausgelassene Demo in der Liste, statt zu
# fehlen -- vorher war einer fehlenden Datei nicht anzusehen, ob sie vergessen
# wurde oder Absicht war. Ueberspringen laesst sich mit --alle abschalten.

set DEMOS {
    {minimalPdf.tcl              0  dir        "Minimales PDF (Hello World)"}
    {FarbenundFormen.tcl         0  dir        "Farben und Formen"}
    {demo-all.tcl                0  dir        "Alle Features (Comprehensive)"}
    {demo-alpha.tcl              0  {file demo-alpha.pdf}  "Transparenz (setAlpha/getAlpha)"}
    {demo-api-vergleich.tcl      0  none       "API-Vergleich (Font-Demo)"}
    {demo-cidfont.tcl            0  none       "CIDFont Unicode-Support"}
    {demo-embedfile.tcl          0  --out      "Eingebettete Dateien (addEmbeddedFile)"}
    {demo-interlaced-png.tcl     0  dir        "Interlaced PNG (Adam7, 0.9.4.28)"}
    {demo-encryption.tcl         0  dir        "AES-128 Verschluesselung + -permissions"}
    {demo-transform.tcl          0  dir        "transform + getPageSize (0.9.4.20)"}
    {demo-permissions.tcl        0  dir        "PDF-Berechtigungen (-permissions)"}
    {demo-layers.tcl             0  dir        "Layer / OCG (0.9.4.21)"}
    {demo-annotations.tcl        0  dir        "Annotationen (Note/FreeText/Stamp/Markup/Line 0.9.4.23)"}
    {demo-pdfa.tcl               0  --out      "PDF/A direkt"}
    {demo-pdfa-3a.tcl            0  --out      "PDF/A-3a und PDF/UA-1"}
    {demo-pdfa-gs.tcl            0  --out      "PDF/A via Ghostscript"}
    {demo-stdfonts-tabelle.tcl   0  dir        "Standard-Fonts Tabelle"}
    {demo-stdfonts-tounicode.tcl 0  dir        "Standard-Fonts ToUnicode"}
    {demo-symbole.tcl            0  none       "Symbole"}
    {demo-unicode-tabelle.tcl    0  none       "Unicode-Tabelle"}
    {fonts.tcl                   0  dir        "Font-Demo"}
    {demo-forms-calc.tcl         0  dir        "Formular + Summenberechnung (-calculate 0.9.4.32)"}
    {demo-forms-tk.tcl           1  none       "Formulare (Tk-GUI)"
        "interaktiv -- oeffnet ein Fenster und wartet, kein Stapellauf"}
    {demo-tagged.tcl             0  dir        "Tagged PDF / PDF-UA (0.9.4.36+0.9.4.37)"}
    {demo-forms.tcl              0  dir        "Bestellformular ohne Verschluesselung"}
    {demo-gradients.tcl          0  dir        "Verlaeufe und Blendmodi"}
    {demo-paper-sizes.tcl        0  dir        "Papierformate"}
    {demo-write-chan.tcl         0  dir        "write -chan / -file / get"}
    {demo-make-cheatsheets.tcl   0  none       "Cheat Sheets"}

    {demo-aes256.tcl             0  dir        "AES-256 Verschluesselung"
        "tcllib-AES braucht rund 24 s pro Durchlauf"}
    {demo-forms-aes128.tcl       0  dir        "Formular mit AES-128"
        "Verschluesselung, langsam"}
    {demo-forms-aes256.tcl       0  dir        "Formular mit AES-256"
        "Verschluesselung, sehr langsam"}
    {demo-forms-enc.tcl          0  dir        "Formular verschluesselt"
        "Verschluesselung, langsam"}
    {demo-otf.tcl                0  --out      "OpenType-Fonts"
        "benoetigt OTF-Fonts im System (Loma o.ae.)"}
    {demo-canvas-0.9.4.24.tcl    1  none       "Canvas-Export"
        "benoetigt Tk"}
    {demo-canvas-tkpath.tcl      1  none       "Canvas-Export mit tkpath"
        "benoetigt Tk und tkpath"}
}

# ---------------------------------------------------------------------------
# Hilfsprozeduren
# ---------------------------------------------------------------------------

proc ok   {msg} { puts "  OK     $msg" }
proc skip {msg} { puts "  SKIP   $msg" }
proc fail {msg} { puts "  FEHLER $msg" }

# ---------------------------------------------------------------------------
# Demos ausfuehren
# ---------------------------------------------------------------------------

set n_ok   0
set n_skip 0
set n_fail 0
set failed {}

puts "Ausgabe: $outdir"
puts "Tk verfuegbar: [expr {$hasTk ? {ja} : {nein (DISPLAY nicht gesetzt)}}]"
puts "\n[string repeat - 60]"

foreach demo $DEMOS {
    lassign $demo script needsTk argschema desc grund

    set scriptpath [file join $demodir $script]

    # Datei vorhanden?
    if {![file exists $scriptpath]} {
        skip "$script -- Datei nicht gefunden"
        incr n_skip
        continue
    }

    # Bewusst ausgelassen?
    if {$grund ne "" && !$runAll} {
        skip "$script -- $grund"
        incr n_skip
        continue
    }

    # Tk-Check
    if {$needsTk && !$hasTk} {
        skip "$script -- benoetigt Tk (kein DISPLAY)"
        incr n_skip
        continue
    }

    # Argumente aufbauen
    set extraargs {}
    switch -glob $argschema {
        none      { }
        dir       { set extraargs [list $outdir] }
        {file *}  { set fname [lindex $argschema 1]
                    set extraargs [list [file join $outdir $fname]] }
        --out     { set extraargs [list --out $outdir] }
    }

    # Ausfuehren
    puts -nonewline "  RUN    $script ... "
    flush stdout

    set cmd [list {*}$timeoutCmd [info nameofexecutable] $scriptpath {*}$extraargs]
    if {[catch {exec {*}$cmd 2>@stdout} result]} {
        if {[TimedOut]} {
            puts "ZEITGRENZE (${demoTimeout}s)"
            puts "         Laeuft die Demo in eine Event-Loop? Ein Skript, das"
            puts "         Tk laedt und kein exit hat, wartet hier unbegrenzt."
        } else {
            puts "FEHLER"
            if {$result ne ""} { puts "         $result" }
        }
        lappend failed $script
        incr n_fail
    } else {
        puts "OK"
        incr n_ok
    }
}

# ---------------------------------------------------------------------------
# Zusammenfassung
# ---------------------------------------------------------------------------

puts "\n[string repeat - 60]"
puts "Ergebnis: $n_ok OK  /  $n_skip uebersprungen  /  $n_fail Fehler"

if {[llength $failed] > 0} {
    puts "\nFehlgeschlagen:"
    foreach s $failed { puts "  - $s" }
    exit 1
}

puts "\nAlle Demos erfolgreich. PDFs in: $outdir"
