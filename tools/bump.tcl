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
    foreach {f pat} {
        src/prologue.tcl   {package provide pdf4tcl \S+}
        tests/init.tcl     {set version \S+}
        pkgIndex.tcl       {pdf4tcl \S+}
        pdf4tcl.man        {manpage_begin pdf4tcl n \S+}
    } {
        if {![file exists $f]} { puts "  SKIP $f"; continue }
        set c [readFile $f]
        if {[regexp $pat $c m]} {
            if {[string match "*$oldVersion*" $m]} {
                puts "  OK   $f: $m"
            } else {
                puts "  WARN $f: $m (erwartet $oldVersion)"
                set ok 0
            }
        }
    }
    exit [expr {$ok ? 0 : 1}]
}

puts "Bump: $oldVersion --> $newVersion"
puts "Msg:  $newMsg"
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
    README.md
    web/index.html
} {
    if {![file exists $f]} { puts "  SKIP $f"; continue }
    replaceInFile $f $oldVersion $newVersion $oldVersion
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
set sf 0.9.4.x/nogit/scripts/sync-pdf4tcl.tcl
if {[file exists $sf]} {
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

# ---------------------------------------------------------------
# 6. web/changes.html: Eintrag oben einfuegen (einmalig)
# ---------------------------------------------------------------
set f web/changes.html
if {[file exists $f]} {
    set c [readFile $f]
    if {![string match "*Changes in v${newVersion}*" $c]} {
        set htmlEntry "\nChanges in v${newVersion} (${today}, fork gregnix):<br>\n<ul>\n  <li>${newMsg}</li>\n</ul>\n"
        set c2 [regsub {\nChanges in v} $c "${htmlEntry}\nChanges in v"]
        writeFile $f $c2
        puts "  OK  $f (Eintrag eingefuegt)"
    } else {
        puts "  --  $f (Eintrag bereits vorhanden)"
    }
}

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
# Zusammenfassung
# ---------------------------------------------------------------
puts "\nFertig. Noch manuell:"
puts "  - ChangeLog ausformulieren (web/changes.html ggf. praezisieren)"
puts "  - make doc   (pdf4tcl.html + pdf4tcl.n aus pdf4tcl.man)"
puts "  - make md    (pdf4tcl.md aus pdf4tcl.n)"
puts "  - make example (Referenz-PDFs neu generieren -- Version steckt in /Creator + komprimierten Metadaten)"
puts "  - make test"
puts "  - make release && make zip"
puts "  - git add -A && git commit -m \"$newVersion: $newMsg\""
puts "  - git tag -a v$newVersion -m \"$newMsg\""
puts "  - git push origin master --tags"
