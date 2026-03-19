#!/usr/bin/env tclsh
# tools/bump.tcl -- Versionsnummer ersetzen
#
# Liest Zielversion aus tools/next.tcl
# Aufruf: tclsh tools/bump.tcl
#         tclsh tools/bump.tcl --show   (nur anzeigen, nichts schreiben)

set dryRun 0
if {[lindex $argv 0] eq "--show"} { set dryRun 1 }

# --- next.tcl lesen ---
set nextFile [file join [file dirname [info script]] next.tcl]
source $nextFile
set newVersion $NEXT_VERSION
set newMsg     $NEXT_MSG

# --- aktuelle Version aus src/prologue.tcl ---
set fh [open src/prologue.tcl r]
set content [read $fh]; close $fh
regexp {package provide pdf4tcl\s+(\S+)} $content -> oldVersion

puts "Bump: $oldVersion --> $newVersion"
puts "Msg:  $newMsg"

if {$dryRun} { puts "(--show: keine Aenderungen)"; exit 0 }

# --- Ersetzen in allen Dateien ---
set files {
    src/prologue.tcl
    tests/init.tcl
    pkgIndex.tcl
    pkg/pkgIndex.tcl
    pdf4tcl.man
    README.md
    web/index.html
}

foreach f $files {
    if {![file exists $f]} { puts "  SKIP $f (nicht vorhanden)"; continue }
    set fh [open $f r]; fconfigure $fh -encoding utf-8
    set c [read $fh]; close $fh
    set c2 [string map [list $oldVersion $newVersion] $c]
    if {$c2 ne $c} {
        set fh [open $f w]; fconfigure $fh -encoding utf-8
        puts -nonewline $fh $c2; close $fh
        puts "  OK  $f"
    } else {
        puts "  --  $f (unveraendert)"
    }
}

# --- Makefile: VERSION ohne Punkte ---
set oldNd [regsub -all {\.} $oldVersion {}]
set newNd [regsub -all {\.} $newVersion {}]
set fh [open Makefile r]; set c [read $fh]; close $fh
set c2 [regsub {(VERSION\s*=\s*)\S+} $c "\\1$newNd"]
if {$c2 ne $c} {
    set fh [open Makefile w]; puts -nonewline $fh $c2; close $fh
    puts "  OK  Makefile"
}

# --- sync-pdf4tcl.tcl ---
set sf 0.9.4.x/nogit/scripts/sync-pdf4tcl.tcl
if {[file exists $sf]} {
    set fh [open $sf r]; set c [read $fh]; close $fh
    set c2 [string map [list \
        "pdf4tcl${oldVersion}src" "pdf4tcl${newVersion}src" \
        "pdf4tcl${oldNd}src"      "pdf4tcl${newNd}src"] $c]
    if {$c2 ne $c} {
        set fh [open $sf w]; puts -nonewline $fh $c2; close $fh
        puts "  OK  $sf"
    }
}

# --- ChangeLog: Stub oben einfuegen ---
set today [clock format [clock seconds] -format "%Y-%m-%d"]
set stub "${today} Gregor  <gregnix@github>\n\n\t* Bumped revision to ${newVersion}\n\t* ${newMsg}\n\n"
set fh [open ChangeLog r]; fconfigure $fh -encoding utf-8
set c [read $fh]; close $fh
set fh [open ChangeLog w]; fconfigure $fh -encoding utf-8
puts -nonewline $fh "${stub}${c}"; close $fh
puts "  OK  ChangeLog (Stub eingefuegt)"

# --- assemblieren ---
set parts {src/prologue.tcl src/fonts.tcl src/helpers.tcl
           src/options.tcl  src/main.tcl  src/encrypt.tcl src/cat.tcl}
set out ""
foreach p $parts {
    set fh [open $p r]; fconfigure $fh -encoding utf-8
    append out [read $fh]; close $fh
}
set fh [open pdf4tcl.tcl w]; fconfigure $fh -encoding utf-8
puts -nonewline $fh $out; close $fh
set fh [open pkg/pdf4tcl.tcl w]; fconfigure $fh -encoding utf-8
puts -nonewline $fh $out; close $fh
puts "  OK  pdf4tcl.tcl + pkg/pdf4tcl.tcl"

puts "\nFertig. Noch manuell:"
puts "  - ChangeLog ausformulieren"
puts "  - web/changes.html Eintrag"
puts "  - make doc"
puts "  - git add -A && git commit && git tag v$newVersion && git push"
