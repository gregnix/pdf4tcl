#!/usr/bin/env tclsh
# tools/bump.tcl -- Versionsnummer ersetzen und Release vorbereiten
#
# Liest Zielversion und Beschreibung aus tools/next.tcl.
# Erledigt alles automatisch was moeglich ist.
# Zeigt am Ende klar was noch manuell erledigt werden muss.
#
# Aufruf:
#   tclsh tools/bump.tcl           -- alles ausfuehren
#   tclsh tools/bump.tcl --show    -- nur anzeigen, nichts schreiben
#   tclsh tools/bump.tcl --verify  -- Versionskonsistenz pruefen
#   tclsh tools/bump.tcl --to 0.9.4.X [--msg "..."]
#                                  -- Ziel abweichend von tools/next.tcl
#
# Ein unbekanntes Argument ist ein Fehler. Frueher wurde es verworfen,
# und ein "--dry-run" nach dem Vorbild anderer Werkzeuge schrieb dann in
# Wahrheit alle Dateien -- der Schalter heisst hier --show.

set dryRun    0
set verify    0
set optVersion ""
set optMsg     ""
for {set i 0} {$i < [llength $argv]} {incr i} {
    set a [lindex $argv $i]
    switch -exact -- $a {
        --show   { set dryRun 1 }
        --dry-run { set dryRun 1 }
        --verify { set verify 1 }
        --to     { incr i; set optVersion [lindex $argv $i] }
        --msg    { incr i; set optMsg     [lindex $argv $i] }
        default  {
            puts stderr "Unbekanntes Argument \"$a\".\
                    Erlaubt: --show, --dry-run, --verify, --to VERSION,\
                    --msg TEXT"
            exit 2
        }
    }
}
if {$optVersion ne "" && ![regexp {^\d+(\.\d+)+$} $optVersion]} {
    puts stderr "Keine Versionsnummer: \"$optVersion\""
    exit 2
}

# --- Hilfsprozeduren ---
proc readFile {f} {
    set fh [open $f r]; fconfigure $fh -encoding utf-8
    set c [read $fh]; close $fh; return $c
}
proc writeFile {f c} {
    set fh [open $f w]; fconfigure $fh -encoding utf-8
    puts -nonewline $fh $c; close $fh
}
proc replaceInFile {f old new label} {
    global dryRun
    set c [readFile $f]
    set c2 [string map [list $old $new] $c]
    if {$c2 eq $c} { puts "  --  $f ($label unveraendert)"; return }
    if {!$dryRun} { writeFile $f $c2 }
    puts "  OK  $f ($label)"
}
proc regsubInFile {f pat sub label} {
    global dryRun
    set c [readFile $f]
    set c2 [regsub $pat $c $sub]
    if {$c2 eq $c} { puts "  --  $f ($label unveraendert)"; return }
    if {!$dryRun} { writeFile $f $c2 }
    puts "  OK  $f ($label)"
}

# --- next.tcl lesen; --to/--msg haben Vorrang ---
set nextFile [file join [file dirname [info script]] next.tcl]
source $nextFile
set newVersion $NEXT_VERSION
set newMsg     $NEXT_MSG
if {$optVersion ne ""} { set newVersion $optVersion }
if {$optMsg     ne ""} { set newMsg     $optMsg }

# --- aktuelle Version aus src/prologue.tcl ---
if {![file exists src/prologue.tcl]} {
    puts stderr "Fehler: Bitte aus dem pdf4tcl-Wurzelverzeichnis ausfuehren"
    exit 1
}
set c [readFile src/prologue.tcl]
regexp {package provide pdf4tcl\s+(\S+)} $c -> oldVersion

if {$verify} {
    # --- Versionspruefung ---
    puts "Versionspruefung: $oldVersion"
    set ok 1
    # Die Muster muessen zu den Dateien passen -- tests/init.tcl wurde mit
    # {set version \S+} gesucht und enthaelt "package require pdf4tcl X".
    # Das Muster traf nie, und der Zweig darunter schwieg dazu: die Datei
    # stand in der Liste und wurde nie geprueft. Ein Muster ohne Treffer
    # ist jetzt selbst ein Befund.
    foreach {f pat} {
        src/prologue.tcl   {package provide pdf4tcl \S+}
        tests/init.tcl     {package require pdf4tcl \S+}
        pkgIndex.tcl       {pdf4tcl \S+}
        pkg/pkgIndex.tcl   {pdf4tcl \S+}
        pdf4tcl.man        {manpage_begin pdf4tcl n \S+}
        Makefile           {VERSION\s*=\s*\S+}
        pdf4tcl.html       {pdf4tcl\(n\) \S+ pdf4tcl}
    } {
        if {![file exists $f]} { puts "  SKIP $f"; continue }
        set c [readFile $f]
        if {![regexp $pat $c m]} {
            puts "  WARN $f: Muster \"$pat\" trifft nicht -- ungeprueft"
            set ok 0
            continue
        }
        # Makefile fuehrt die Version ohne Punkte (09444).
        set want $oldVersion
        if {$f eq "Makefile"} { set want [regsub -all {\.} $oldVersion {}] }
        if {[string match "*$want*" $m]} {
            puts "  OK   $f: $m"
        } else {
            puts "  WARN $f: $m (erwartet $want)"
            set ok 0
        }
    }
    exit [expr {$ok ? 0 : 1}]
}

# Vergleicht zwei Versionen der Form a.b.c.d numerisch je Feld.
# Rueckgabe: -1, 0 oder 1.
proc versionCompare {a b} {
    set as [split $a .]
    set bs [split $b .]
    set n [expr {max([llength $as], [llength $bs])}]
    for {set i 0} {$i < $n} {incr i} {
        set x [lindex $as $i] ; if {$x eq ""} { set x 0 }
        set y [lindex $bs $i] ; if {$y eq ""} { set y 0 }
        if {![string is integer -strict $x] || ![string is integer -strict $y]} {
            if {$x eq $y} continue
            return [expr {$x < $y ? -1 : 1}]
        }
        if {$x < $y} { return -1 }
        if {$x > $y} { return 1 }
    }
    return 0
}

puts "Bump: $oldVersion --> $newVersion"
puts "Msg:  $newMsg"

# Eine Version darf nicht rueckwaerts gehen. Gemessen 2026-08-16: nach dem
# Bump auf 0.9.4.44 stand in next.tcl weiterhin 0.9.4.43, und ein Aufruf
# ohne --to meldete "Bump: 0.9.4.44 --> 0.9.4.43" -- mit der Beschreibung
# der vorletzten Version dazu. Das Werkzeug haette den Baum bereitwillig
# zurueckdatiert.
set cmp [versionCompare $newVersion $oldVersion]
if {$cmp < 0} {
    puts stderr "Fehler: $newVersion ist AELTER als $oldVersion."
    puts stderr "  tools/next.tcl steht auf $NEXT_VERSION und ist offenbar"
    puts stderr "  nicht fortgeschrieben worden. Entweder --to angeben oder"
    puts stderr "  next.tcl auf die naechste Version setzen."
    exit 1
}
if {$cmp == 0} {
    # Kein Abbruch: derselbe Aufruf ein zweites Mal ist ein
    # REPARATURLAUF. Alles, was noch auf der alten Nummer steht, wird
    # nachgezogen, der Rest meldet sich als unveraendert -- das Werkzeug
    # ist dafuer gebaut: replaceInFile vergleicht vor dem Schreiben, und
    # der ChangeLog-Stub wird nur eingefuegt, wenn er fehlt.
    #
    # Gebraucht wird das vor allem fuer die erzeugten Dateien:
    # pdf4tcl.html und .n entstehen erst durch "make doc", und wenn das
    # ausbleibt oder wegen der Zeitstempel uebersprungen wird, traegt das
    # HTML noch die alte Version. --verify zeigt das an.
    puts "Hinweis: der Baum steht bereits auf $newVersion -- Reparaturlauf."
}

if {$dryRun} { puts "(--show: keine Aenderungen)"; exit 0 }

set oldNd [regsub -all {\.} $oldVersion {}]
set newNd [regsub -all {\.} $newVersion {}]
set today [clock format [clock seconds] -format "%Y-%m-%d"]

# ---------------------------------------------------------------
# 1. Einfache Versionsersetzung (string map)
# ---------------------------------------------------------------
foreach f {
    src/prologue.tcl
    tests/init.tcl
    pkgIndex.tcl
    pkg/pkgIndex.tcl
} {
    if {![file exists $f]} { puts "  SKIP $f"; continue }
    replaceInFile $f $oldVersion $newVersion $oldVersion
}

# ---------------------------------------------------------------
# 1a. README.md: NUR die Titelzeile.
#
# Frueher stand README.md in der Liste oben und bekam jedes Vorkommen
# der alten Nummer ersetzt. Das ist genau eine Zeile zu viel: die
# Titelzeile SOLL mitwandern, jede andere Angabe im Text ist
# historisch -- "Since 0.9.4.36", "fixed in 0.9.4.49", "kept as
# ticket*/ directories until 0.9.4.45".
#
# Gemessen: die Zeile ueber die ticket-Verzeichnisse nannte
# urspruenglich richtig 0.9.4.45 und wanderte ueber acht Bumps bis
# 0.9.4.53 mit, bis sie am 2026-08-23 auffiel -- und war da laengst in
# eine oeffentliche Antwort uebernommen worden. Der naechste Kandidat
# waere "fixed in 0.9.4.53" im Abschnitt ueber die Herkunft gewesen.
#
# Die Titelzeile ist die erste Zeile und hat die Form
#     # pdf4tcl fork (0.9.4.53)
if {[file exists README.md]} {
    regsubInFile README.md \
        "^(# pdf4tcl fork \\()\[0-9.\]+(\\))" \
        "\\1$newVersion\\2" "Titelzeile"
} else {
    puts "  SKIP README.md"
}

# ---------------------------------------------------------------
# 1b. Versions-Asserts in den Test-Tripwires (tests/new-*.test):
#     nur die Assert-Muster "version is X" und -result *X* bumpen,
#     historische "# Tests for pdf4tcl X"-Kommentare bleiben.
# ---------------------------------------------------------------
foreach tf [lsort [glob -nocomplain tests/new-*.test]] {
    set c [readFile $tf]
    set c2 [string map [list \
        "version is $oldVersion" "version is $newVersion" \
        "*$oldVersion*"          "*$newVersion*"] $c]
    if {$c2 ne $c} {
        if {!$dryRun} { writeFile $tf $c2 }
        puts "  OK  $tf (Versions-Assert)"
    }
}

# ---------------------------------------------------------------
# 2. pdf4tcl.man -- Doctools-Direktiven (zwei Stellen)
# ---------------------------------------------------------------
set f pdf4tcl.man
if {[file exists $f]} {
    set c [readFile $f]
    set c2 $c
    set c2 [string map [list \
        "\[manpage_begin pdf4tcl n $oldVersion\]" \
        "\[manpage_begin pdf4tcl n $newVersion\]"] $c2]
    set c2 [string map [list \
        "\[require pdf4tcl \[opt $oldVersion\]\]" \
        "\[require pdf4tcl \[opt $newVersion\]\]"] $c2]
    if {$c2 ne $c} {
        writeFile $f $c2
        puts "  OK  $f (manpage_begin + require)"
    } else {
        puts "  --  $f (unveraendert)"
    }
}

# ---------------------------------------------------------------
# 3. Makefile: VERSION ohne Punkte
# ---------------------------------------------------------------
regsubInFile Makefile \
    "(VERSION\\s*=\\s*)\\S+" \
    "\\1$newNd" \
    "VERSION=$oldNd->$newNd"

# ---------------------------------------------------------------
# 4. sync-pdf4tcl.tcl: Pfade
# ---------------------------------------------------------------
# Der Pfad ist mit dem Flachlegen des fork-Verzeichnisses gewandert. Ein
# fehlendes Skript wird jetzt GENANNT statt stillschweigend uebersprungen:
# "nicht gefunden" und "nichts zu aendern" sahen vorher gleich aus.
set sf nogit/scripts/sync-pdf4tcl.tcl
if {![file exists $sf]} {
    puts "  --  $sf (nicht vorhanden -- nogit liegt nicht im Repo)"
} else {
    set c [readFile $sf]
    set c2 [string map [list \
        "pdf4tcl${oldVersion}" "pdf4tcl${newVersion}" \
        "pdf4tcl${oldNd}"      "pdf4tcl${newNd}"] $c]
    if {$c2 ne $c} {
        writeFile $sf $c2
        puts "  OK  $sf"
    } else {
        puts "  --  $sf (unveraendert)"
    }
}

# ---------------------------------------------------------------
# 5. ChangeLog: Stub oben einfuegen (einmalig)
# ---------------------------------------------------------------
set stub "${today} Gregor  <gregnix@github>\n\n\t* Bumped revision to ${newVersion}\n\t* ${newMsg}\n\n"
set c [readFile ChangeLog]
# Nur einfuegen wenn der Stub noch nicht da ist
if {![string match "*Bumped revision to ${newVersion}*" $c]} {
    writeFile ChangeLog "${stub}${c}"
    puts "  OK  ChangeLog (Stub eingefuegt)"
} else {
    puts "  --  ChangeLog (Stub bereits vorhanden)"
}

# Der frueher hier stehende Schritt fuer web/changes.html ist mit dem
# Verzeichnis web/ entfallen (0.9.4.45). Die Projektseite gehoerte dem
# Original und war aus diesem Fork nicht veroeffentlichbar; der Eintrag
# waere ins Leere gelaufen.

# ---------------------------------------------------------------
# 7. Assemblieren
# ---------------------------------------------------------------
# Die Reihenfolge steht im Makefile (CATFILES) und wird von dort gelesen.
# Eine zweite Liste hier ging schief: sie kannte src/color.tcl (0.9.4.39)
# und src/tagged.tcl nicht, und jeder Bump schrieb ein pdf4tcl.tcl ohne
# Farben und ohne Tagging -- mit der Meldung "OK". Aufgefallen ist es
# allein durch "make checkbuild".
set parts {}
if {[catch {
    set mk [readFile Makefile]
    if {[regexp -line {^CATFILES\s*=\s*(.*)$} $mk -> line]} {
        set parts $line
    }
} e]} {
    puts stderr "Makefile nicht lesbar: $e"
    exit 1
}
foreach f $parts {
    if {![file exists $f]} {
        puts stderr "CATFILES nennt $f -- nicht vorhanden"
        exit 1
    }
}
if {[llength $parts] < 2} {
    puts stderr "CATFILES im Makefile nicht gefunden"
    exit 1
}
set out ""
foreach p $parts {
    set fh [open $p r]; fconfigure $fh -encoding utf-8
    append out [read $fh]; close $fh
}
writeFile pdf4tcl.tcl $out
writeFile pkg/pdf4tcl.tcl $out
puts "  OK  pdf4tcl.tcl + pkg/pdf4tcl.tcl"

# ---------------------------------------------------------------
# X. tools/next.tcl NICHT anfassen
# ---------------------------------------------------------------
#
# Die Datei wird gelesen und bleibt stehen. Sie von Hand zu pflegen ist
# Absicht: welche Nummer als naechste kommt, entscheidet der Autor --
# nach 0.9.4.47 kann 0.9.4.48 folgen oder 0.9.5.0, und das kann kein
# Werkzeug wissen.
#
# Eine Fassung schrieb die letzte Stelle automatisch hoch. Das tauschte
# einen Fehler gegen einen anderen: wer next.tcl aus alter Gewohnheit
# vorher von Hand setzte, uebersprang eine Version. Gegen das Vergessen
# steht der Hinweis im Abschlussblock, gegen ein Rueckwaertslaufen die
# Pruefung weiter oben.
set nv [split $newVersion .]
set last [lindex $nv end]
set vorschlag ""
if {[string is integer -strict $last]} {
    lset nv end [expr {$last + 1}]
    set vorschlag [join $nv .]
}

# ---------------------------------------------------------------
# Zusammenfassung
# ---------------------------------------------------------------
puts "\nFertig. Noch manuell:"
if {$vorschlag ne ""} {
    puts "  - tools/next.tcl auf die naechste Version setzen (Vorschlag:\
            $vorschlag) und NEXT_MSG fuellen"
    puts "    -- die Datei wird NICHT automatisch fortgeschrieben; bleibt sie"
    puts "       stehen, ist der naechste Aufruf ein Reparaturlauf"
} else {
    puts "  - tools/next.tcl auf die naechste Version setzen und NEXT_MSG fuellen"
}
puts "  - ChangeLog ausformulieren"
puts "  - make doc   (pdf4tcl.html + pdf4tcl.n aus pdf4tcl.man)"
puts "  - make md    (pdf4tcl.md aus pdf4tcl.n)"
puts "  - make example (Referenz-PDFs neu generieren -- Version steckt in /Creator + komprimierten Metadaten)"
puts "  - make test"
puts "  - make release && make zip"
puts "  - git add -A && git commit -m \"$newVersion: $newMsg\""
puts "  - git tag -a v$newVersion -m \"$newMsg\""
puts "  - git push origin master --tags"
