#!/usr/bin/env tclsh
# run-all-demos.tcl -- alle pdf4tcl Demos ausfuehren
#
# Fuehrt alle Demo-Skripte aus und sammelt Ergebnisse.
# Demos die Tk benoetigen werden uebersprungen, wenn sich kein Fenster
# oeffnen laesst -- unter X11 heisst das "kein DISPLAY", auf Windows und
# macOS nichts.
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

# DISPLAY ist ein X11-Begriff. Auf Windows und macOS gibt es kein DISPLAY
# und Tk laeuft trotzdem -- der Test meldete dort "Tk verfuegbar: nein" und
# uebersprang jede Tk-Demo. Gemeldet am 05.09.2026 aus einem Windows-Lauf.
#
# Die Frage ist nicht, ob eine Umgebungsvariable gesetzt ist, sondern ob
# sich ein Fenster oeffnen laesst. Auf X11 bleibt DISPLAY die Antwort, sonst
# entscheidet die Plattform.
switch -- $tcl_platform(platform) {
    windows { set hasTk 1 }
    default {
        if {$tcl_platform(os) eq "Darwin"} {
            # Aqua braucht kein DISPLAY; ein gesetztes DISPLAY hiesse dort
            # nur, dass zusaetzlich X11 da ist.
            set hasTk 1
        } else {
            set hasTk [expr {[info exists env(DISPLAY)] && $env(DISPLAY) ne ""}]
        }
    }
}

# ---------------------------------------------------------------------------
# Zeitgrenze je Demo
# ---------------------------------------------------------------------------
#
# exec wartet ohne Grenze. Eine Demo, die Tk laedt und kein exit hat, geht am
# Skriptende in die Event-Loop und haelt den Sammellauf fest -- und zwar nur
# auf einer Maschine mit Anzeige. Ohne DISPLAY wird dieselbe Demo
# uebersprungen, der Lauf ist gruen, und niemand sieht es.
#
# timeout(1) stammt aus den coreutils. Wo es fehlt, laeuft es wie bisher --
# eine Zeitgrenze in reinem Tcl braeuchte nichtblockierende Kanaele und eine
# eigene Event-Schleife, was fuer einen Demo-Runner zu viel Apparat ist.
#
# ABER: "vorhanden" heisst nicht "dasselbe Programm". Windows bringt ein
# eigenes TIMEOUT.EXE mit, das WARTET statt zu begrenzen -- "timeout 120
# tclsh demo.tcl" ist dort ein Syntaxfehler:
#
#   FEHLER: Ungueltige Syntax. Die Standardoption darf nicht mehr als
#   1 Mal verwendet werden.
#
# Gemeldet am 05.09.2026 von einem Windows-Lauf: 31 von 31 Demos
# "fehlgeschlagen", keine einzige davon wegen der Demo. auto_execok fand
# ein Programm dieses Namens, und das wurde als Beleg dafuer genommen, dass
# es das richtige ist.
#
# Also nachfragen statt annehmen: coreutils-timeout kennt "--version" und
# nennt sich darin. Alles andere zaehlt nicht.
set demoTimeout 120
set timeoutCmd {}
if {[llength [auto_execok timeout]] > 0} {
    if {![catch {exec timeout --version} probe]
            && [string match -nocase "*coreutils*" $probe]} {
        set timeoutCmd [list timeout $demoTimeout]
    }
}
if {![llength $timeoutCmd]} {
    puts "Zeitgrenze: keine (kein coreutils-timeout gefunden)"
}

# 77: die Demo hat eine Voraussetzung vermisst und sich selbst
# abgemeldet -- kein Fehler. Dieselbe Zahl benutzt autoconf dafuer.
proc Uebersprungen {} {
    return [expr {[lindex $::errorCode 0] eq "CHILDSTATUS"
                  && [lindex $::errorCode 2] == 77}]
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
    {demo-catpdf.tcl             0  none       "PDFs zusammenfuehren (catPdf)"}
    {demo-kerning-ligatures.tcl  0  none       "Kerning und Ligaturen"}
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
    {demo-tagged-xobject.tcl     0  dir        "Struktur in einem Form-XObject (0.9.4.46)"}
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
        ""}
    {demo-canvas-tkpath.tcl      1  none       "Canvas-Export mit tkpath"
        "@paket tkpath"}
    {demo-canvas-tko.tcl         1  none       "Canvas-Export mit tko::path"
        "@paket tko"}
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
# Den Grund nennen, aber nur den, der hier gilt: "DISPLAY nicht gesetzt"
# waere auf Windows eine falsche Auskunft.
puts "Tk verfuegbar: [expr {$hasTk ? {ja} : {nein (kein DISPLAY)}}]"
puts "\n[string repeat - 60]"

# Waechter gegen die stille Luecke: DEMOS ist eine feste Liste, und eine
# neue Datei im Verzeichnis laeuft nie, ohne dass jemand es merkt. Genau so
# war demo-tagged-xobject.tcl nach dem Schreiben nicht im Lauf.
set listed {}
foreach d $DEMOS { lappend listed [lindex $d 0] }
set onDisk [lsort [glob -nocomplain -tails -directory $demodir demo-*.tcl]]
set missing {}
foreach f $onDisk {
    if {$f ni $listed} { lappend missing $f }
}
if {[llength $missing]} {
    puts "WARNUNG: nicht in DEMOS und damit ungeprueft:"
    foreach f $missing { puts "  $f" }
    puts ""
}

foreach demo $DEMOS {
    lassign $demo script needsTk argschema desc grund

    set scriptpath [file join $demodir $script]

    # Datei vorhanden?
    if {![file exists $scriptpath]} {
        skip "$script -- Datei nicht gefunden"
        incr n_skip
        continue
    }

    # Ein Grund der Form "@paket X" ist keine Entscheidung, sondern eine
    # Frage: ist das Paket da? Vorher stand hier fuer die Canvas-Demos
    # ein fester Grund "benoetigt Tk" -- sie wurden uebersprungen, AUCH
    # wenn Tk laengst geladen werden konnte. Gemeldet aus einem
    # Windows-Lauf 05.09.2026: "Tk verfuegbar: ja" und drei Zeilen
    # weiter "SKIP -- benoetigt Tk".
    if {[string match "@paket *" $grund]} {
        set paket [lindex $grund 1]
        if {[catch {package require $paket}]} {
            skip "$script -- Paket \"$paket\" nicht vorhanden"
            incr n_skip
            continue
        }
        set grund ""
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
        if {[Uebersprungen]} {
            # Ein fehlendes Fremdteil ist kein Fehler der Demo.
            #
            # demo-kerning-ligatures braucht Carlito, demo-pdfa-gs
            # braucht Ghostscript. Beide melden das sauber und enden mit
            # 1 -- der Lauf zaehlte sie als FEHLER, und damit war er auf
            # keiner Maschine ohne diese Teile jemals gruen. Ein Lauf,
            # der nie gruen wird, wird nicht mehr gelesen; dann faellt
            # ein echter Fehler daneben nicht mehr auf.
            #
            # 77 ist die Zahl, die autoconf dafuer benutzt. Sie sagt:
            # "nicht ausgefuehrt, Voraussetzung fehlt".
            puts "SKIP (Voraussetzung fehlt)"
            if {$result ne ""} { puts "         [lindex [split $result \n] 0]" }
            incr n_skip
            continue
        }
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
