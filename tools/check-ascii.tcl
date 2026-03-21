#!/usr/bin/env tclsh
# tools/check-ascii.tcl
#
# Prüft ob alle Quelldateien in src/ und tests/ reines ASCII sind.
# Nicht-ASCII in Tcl-Quellcode führt unter Windows Tcl 8.6 (ohne UTF-8-BOM)
# zu Syntaxfehlern (missing close-brace u.ä.).
#
# Ausnahmen:
#   - tests/regression.test   (absichtliche Unicode-Testdaten: äöüß)
#   - tests/tounicode.test     (absichtliche Unicode-Testdaten: ÄÖÜ)
#   - tests/nist-tests.tcl     (Kommentare mit Nicht-ASCII erlaubt)
#
# Aufruf:
#   tclsh tools/check-ascii.tcl           -- prüft relativ zum Repo-Root
#   tclsh tools/check-ascii.tcl --verbose -- zeigt auch OK-Dateien
#   tclsh tools/check-ascii.tcl --fix     -- ersetzt bekannte Symbole automatisch

# ---------------------------------------------------------------------------
# Konfiguration
# ---------------------------------------------------------------------------

# Verzeichnisse relativ zum Repo-Root
set CHECK_DIRS {src tests}

# Dateimuster die geprüft werden
set CHECK_PATTERNS {*.tcl *.test}

# Dateien die absichtlich Unicode enthalten (Pfad relativ zu Repo-Root)
set WHITELIST {
    tests/regression.test
    tests/tounicode.test
    tests/nist-tests.tcl
}

# Bekannte Ersetzungen für --fix
# Format: {original_utf8_hex  ersetzung}
set FIX_MAP {
    "\u2500"  "-"
    "\u2014"  "--"
    "\u2013"  "-"
    "\u2192"  "->"
    "\u2190"  "<-"
    "\u00e4"  "ae"
    "\u00f6"  "oe"
    "\u00fc"  "ue"
    "\u00df"  "ss"
    "\u00c4"  "Ae"
    "\u00d6"  "Oe"
    "\u00dc"  "Ue"
    "\u00a7"  "ss."
    "\u00b5"  "u"
}

# ---------------------------------------------------------------------------
# Argumente
# ---------------------------------------------------------------------------
set verbose [expr {[lsearch $argv --verbose] >= 0}]
set do_fix  [expr {[lsearch $argv --fix]     >= 0}]

# ---------------------------------------------------------------------------
# Repo-Root ermitteln (tools/ ist ein Unterverzeichnis)
# ---------------------------------------------------------------------------
set scriptDir [file dirname [file normalize [info script]]]
set repoDir   [file dirname $scriptDir]

if {![file exists [file join $repoDir src prologue.tcl]]} {
    puts stderr "FEHLER: Repo-Root nicht gefunden (erwartet src/prologue.tcl)"
    puts stderr "       Skript muss aus tools/ oder dem Repo-Root aufgerufen werden."
    exit 1
}

# ---------------------------------------------------------------------------
# Hilfsprozeduren
# ---------------------------------------------------------------------------

proc collectFiles {repoDir dirs patterns} {
    set result {}
    foreach dir $dirs {
        set dirpath [file join $repoDir $dir]
        if {![file isdirectory $dirpath]} continue
        foreach pat $patterns {
            foreach f [glob -nocomplain [file join $dirpath $pat]] {
                lappend result $f
            }
        }
    }
    return [lsort -unique $result]
}

proc isWhitelisted {repoDir filepath whitelist} {
    set rel [string map [list [file normalize $repoDir]/ ""] \
                 [file normalize $filepath]]
    foreach w $whitelist {
        if {$rel eq $w} { return 1 }
    }
    return 0
}

proc checkFile {filepath} {
    set fh [open $filepath rb]
    set data [read $fh]
    close $fh

    set lines [split $data "\n"]
    set hits {}
    set linenum 0
    foreach line $lines {
        incr linenum
        set bytes [split $line ""]
        foreach ch $bytes {
            scan $ch %c code
            if {$code > 127} {
                lappend hits [list $linenum $line]
                break
            }
        }
    }
    return $hits
}

proc fixFile {filepath fixMap} {
    set fh [open $filepath r]
    fconfigure $fh -encoding utf-8
    set content [read $fh]
    close $fh

    set changed 0
    foreach {from to} $fixMap {
        if {[string first $from $content] >= 0} {
            set content [string map [list $from $to] $content]
            set changed 1
        }
    }

    if {$changed} {
        set fh [open $filepath w]
        fconfigure $fh -encoding utf-8
        puts -nonewline $fh $content
        close $fh
        return 1
    }
    return 0
}

proc shortPath {repoDir filepath} {
    set norm [file normalize $filepath]
    set base [file normalize $repoDir]
    if {[string first $base $norm] == 0} {
        return [string range $norm [expr {[string length $base]+1}] end]
    }
    return $norm
}

# ---------------------------------------------------------------------------
# Hauptprogramm
# ---------------------------------------------------------------------------

set files [collectFiles $repoDir $CHECK_DIRS $CHECK_PATTERNS]

set nOk      0
set nSkipped 0
set nFailed  0
set nFixed   0

puts "=== ASCII-Check: src/ und tests/ ==="
puts "Repo: $repoDir"
puts ""

foreach f $files {
    set rel [shortPath $repoDir $f]

    if {[isWhitelisted $repoDir $f $WHITELIST]} {
        incr nSkipped
        if {$verbose} { puts "  SKIP  $rel" }
        continue
    }

    set hits [checkFile $f]

    if {[llength $hits] == 0} {
        incr nOk
        if {$verbose} { puts "  OK    $rel" }
        continue
    }

    # Nicht-ASCII gefunden
    if {$do_fix} {
        set fixed [fixFile $f $FIX_MAP]
        if {$fixed} {
            # Nochmal prüfen
            set remaining [checkFile $f]
            if {[llength $remaining] == 0} {
                incr nFixed
                puts "  FIXED $rel"
                continue
            } else {
                puts "  PART  $rel  ([llength $remaining] Zeile(n) verbleibend nach Fix)"
                foreach hit $remaining {
                    lassign $hit linenum line
                    puts "        Z[format %3d $linenum]: [string range $line 0 79]"
                }
                incr nFailed
                continue
            }
        }
    }

    incr nFailed
    puts "  FAIL  $rel  ([llength $hits] Zeile(n))"
    foreach hit $hits {
        lassign $hit linenum line
        # Nicht-ASCII Bytes in \uXXXX Notation anzeigen
        set display ""
        foreach ch [split $line ""] {
            scan $ch %c code
            if {$code > 127} {
                append display "\\u[format %04x $code]"
            } else {
                append display $ch
            }
        }
        puts "        Z[format %3d $linenum]: [string range $display 0 79]"
    }
}

# ---------------------------------------------------------------------------
# Zusammenfassung
# ---------------------------------------------------------------------------
puts ""
puts "=== Ergebnis ==="
puts "  OK:       $nOk"
puts "  Skipped:  $nSkipped  (Whitelist)"
if {$do_fix} {
    puts "  Fixed:    $nFixed"
}
puts "  Failed:   $nFailed"

if {$nFailed > 0} {
    puts ""
    puts "Nicht-ASCII gefunden. Optionen:"
    puts "  tclsh tools/check-ascii.tcl --fix      -- bekannte Symbole ersetzen"
    puts "  tclsh tools/check-ascii.tcl --verbose  -- alle Dateien anzeigen"
    puts ""
    puts "Bekannte Ersetzungen (--fix):"
    foreach {from to} $FIX_MAP {
        puts "  U+[format %04X [scan $from %c]] -> $to"
    }
    exit 1
}

puts ""
puts "Alle Quelldateien sind reines ASCII."
exit 0
