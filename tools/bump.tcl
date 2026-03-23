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

set dryRun  0
set verify  0
foreach a $argv {
    if {$a eq "--show"}   { set dryRun 1 }
    if {$a eq "--verify"} { set verify 1 }
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

# --- next.tcl lesen ---
set nextFile [file join [file dirname [info script]] next.tcl]
source $nextFile
set newVersion $NEXT_VERSION
set newMsg     $NEXT_MSG

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
set parts {src/prologue.tcl src/fonts.tcl src/helpers.tcl
           src/options.tcl  src/main.tcl  src/encrypt.tcl src/cat.tcl}
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
puts "  - make test"
puts "  - make release && make zip"
puts "  - git add -A && git commit -m \"$newVersion: $newMsg\""
puts "  - git tag -a v$newVersion -m \"$newMsg\""
puts "  - git push origin master --tags"
