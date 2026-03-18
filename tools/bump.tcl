#!/usr/bin/env tclsh
# tools/bump.tcl -- Atomarer Versions-Bump fuer pdf4tcl Fork
#
# Aktualisiert alle Versionsdateien in einem Schritt, prueft Konsistenz
# vorher und nachher, und kann optional git commit + tag ausfuehren.
#
# Verwendung:
#   tclsh tools/bump.tcl --to 0.9.4.16 --msg "addLink annotation support"
#   tclsh tools/bump.tcl --verify          -- nur Konsistenzcheck, kein Bump
#   tclsh tools/bump.tcl --to 0.9.4.16 --msg "..." --git    -- mit commit+tag
#   tclsh tools/bump.tcl --to 0.9.4.16 --msg "..." --dry-run
#
# Muss aus dem pdf4tcl-Wurzelverzeichnis ausgefuehrt werden.

# ---------------------------------------------------------------------------
# Argument-Parsing
# ---------------------------------------------------------------------------
proc usage {} {
    puts stderr {
Usage: tclsh tools/bump.tcl OPTION...

Options:
  --to VERSION    New version, e.g. 0.9.4.16  (required unless --verify)
  --msg TEXT      One-line description of changes  (required unless --verify)
  --verify        Only check consistency, no changes
  --git           After bump: git add -A, commit, tag, push
  --no-test       Skip "make test" during bump
  --dry-run       Show what would change, do not write files
}
    exit 1
}

set newVersion  ""
set msg         ""
set doVerify    0
set doGit       0
set doTest      1
set dryRun      0

for {set i 0} {$i < [llength $argv]} {incr i} {
    switch -- [lindex $argv $i] {
        --to       { set newVersion [lindex $argv [incr i]] }
        --msg      { set msg        [lindex $argv [incr i]] }
        --verify   { set doVerify   1 }
        --git      { set doGit      1 }
        --no-test  { set doTest     0 }
        --dry-run  { set dryRun     1 }
        default    { puts stderr "Unknown option: [lindex $argv $i]"; usage }
    }
}

if {!$doVerify && ($newVersion eq "" || $msg eq "")} {
    set nextFile [file join [file dirname [info script]] next.tcl]
    if {[file exists $nextFile]} {
        source $nextFile
        if {$newVersion eq "" && [info exists NEXT_VERSION]} { set newVersion $NEXT_VERSION }
        if {$msg eq ""       && [info exists NEXT_MSG]}     { set msg $NEXT_MSG }
    }
}

if {!$doVerify && $newVersion eq ""} { puts stderr "--to VERSION required (or set NEXT_VERSION in tools/next.tcl)"; usage }
if {!$doVerify && $msg eq ""}        { puts stderr "--msg TEXT required (or set NEXT_MSG in tools/next.tcl)";       usage }

# ---------------------------------------------------------------------------
# Hilfsprozeduren
# ---------------------------------------------------------------------------
proc step {msg} {
    puts "\n[string repeat - 60]"
    puts "  $msg"
    puts [string repeat - 60]
}

proc ok  {msg} { puts "  \[OK\]  $msg" }
proc err {msg} { puts stderr "  \[FEHLER\]  $msg"; exit 1 }
proc info {msg} { puts "        $msg" }

proc readFile {path} {
    set fh [open $path r]
    fconfigure $fh -encoding utf-8
    set content [read $fh]
    close $fh
    return $content
}

proc writeFile {path content} {
    global dryRun
    if {$dryRun} {
        puts "  \[DRY\]  wuerde schreiben: $path"
        return
    }
    set fh [open $path w]
    fconfigure $fh -encoding utf-8
    puts -nonewline $fh $content
    close $fh
}

proc today {} {
    # clock format kann in manchen Umgebungen msgcat benoetigen -- Fallback
    if {[catch {clock format [clock seconds] -format "%Y-%m-%d"} d]} {
        set d [exec date +%Y-%m-%d]
    }
    return $d
}

proc versionNoDots {v} {
    return [regsub -all {\.} $v {}]
}

# Prueft ob ein Muster in einer Datei vorkommt und gibt den gefundenen Wert
# zurueck. pattern muss eine Tcl-Regex mit einer Capture-Gruppe sein.
proc extractVersion {path pattern} {
    set content [readFile $path]
    if {[regexp $pattern $content -> found]} {
        return [string trim $found]
    }
    return ""
}

# ---------------------------------------------------------------------------
# Konsistenzpruefung
# ---------------------------------------------------------------------------
proc verifyAll {expectedVersion} {
    global newVersion

    # Liste: {Datei Regex Beschreibung}
    set checks {
        {src/prologue.tcl
            {package provide pdf4tcl\s+(\S+)}
            "src/prologue.tcl package provide"}
        {tests/init.tcl
            {package require pdf4tcl\s+(\S+)}
            "tests/init.tcl package require"}
        {pkgIndex.tcl
            {package ifneeded pdf4tcl\s+(\S+)}
            "pkgIndex.tcl"}
        {pkg/pkgIndex.tcl
            {package ifneeded pdf4tcl\s+(\S+)}
            "pkg/pkgIndex.tcl"}
        {pdf4tcl.man
            {\[manpage_begin pdf4tcl n\s+(\S+)\]}
            "pdf4tcl.man manpage_begin"}
        {pdf4tcl.man
            {\[require pdf4tcl \[opt\s+(\S+)\]\]}
            "pdf4tcl.man require"}
        {README.md
            {# pdf4tcl fork \(([0-9.]+)\)}
            "README.md heading"}
        {web/index.html
            {version ([0-9]+\.[0-9]+\.[0-9]+\.[0-9]+)}
            "web/index.html"}
    }

    # Makefile: VERSION ohne Punkte
    set makeExpected [versionNoDots $expectedVersion]

    set allOk 1
    foreach check $checks {
        lassign $check file pattern desc
        set found [extractVersion $file $pattern]
        if {$found eq $expectedVersion} {
            ok $desc
        } else {
            puts "  \[MISMATCH\]  $desc"
            info "    gefunden:  \"$found\""
            info "    erwartet:  \"$expectedVersion\""
            set allOk 0
        }
    }

    # Makefile gesondert
    set mfound [extractVersion Makefile {VERSION\s*=\s*(\S+)}]
    if {$mfound eq $makeExpected} {
        ok "Makefile VERSION"
    } else {
        puts "  \[MISMATCH\]  Makefile VERSION"
        info "    gefunden:  \"$mfound\""
        info "    erwartet:  \"$makeExpected\""
        set allOk 0
    }

    # sync-pdf4tcl.tcl: Pfade enthalten dotted version (0.9.4.15src)
    set syncContent [readFile 0.9.4.x/nogit/scripts/sync-pdf4tcl.tcl]
    set syncOk [expr {[string first "pdf4tcl${expectedVersion}src" $syncContent] >= 0}]
    if {$syncOk} {
        ok "sync-pdf4tcl.tcl paths"
    } else {
        puts "  \[MISMATCH\]  sync-pdf4tcl.tcl paths"
        info "    erwartet: pdf4tcl${expectedVersion}src"
        set allOk 0
    }

    # make-release.tcl
    set mrVer [extractVersion 0.9.4.x/nogit/scripts/make-release.tcl \
        {set VERSION\s+"([^"]+)"}]
    if {$mrVer eq $expectedVersion} {
        ok "make-release.tcl VERSION"
    } else {
        puts "  \[MISMATCH\]  make-release.tcl VERSION"
        info "    gefunden:  \"$mrVer\""
        info "    erwartet:  \"$expectedVersion\""
        set allOk 0
    }

    # pdf4tcl.tcl (assembliert)
    set asmVer [extractVersion pdf4tcl.tcl \
        {package provide pdf4tcl\s+(\S+)}]
    if {$asmVer eq $expectedVersion} {
        ok "pdf4tcl.tcl (assembliert)"
    } else {
        puts "  \[MISMATCH\]  pdf4tcl.tcl (assembliert)"
        info "    gefunden:  \"$asmVer\""
        info "    erwartet:  \"$expectedVersion\""
        set allOk 0
    }

    # pkg/pdf4tcl.tcl
    set pkgVer [extractVersion pkg/pdf4tcl.tcl \
        {package provide pdf4tcl\s+(\S+)}]
    if {$pkgVer eq $expectedVersion} {
        ok "pkg/pdf4tcl.tcl"
    } else {
        puts "  \[MISMATCH\]  pkg/pdf4tcl.tcl"
        info "    gefunden:  \"$pkgVer\""
        info "    erwartet:  \"$expectedVersion\""
        set allOk 0
    }

    return $allOk
}

# ---------------------------------------------------------------------------
# Bump: alle Dateien in einem Schritt aktualisieren
# ---------------------------------------------------------------------------
proc bumpAll {oldVersion newVersion msg} {
    set oldNd [versionNoDots $oldVersion]
    set newNd [versionNoDots $newVersion]

    # -- src/prologue.tcl --
    set f src/prologue.tcl
    set c [readFile $f]
    regsub {(package provide pdf4tcl\s+)\S+} $c "\\1$newVersion" c
    writeFile $f $c
    ok $f

    # -- tests/init.tcl --
    set f tests/init.tcl
    set c [readFile $f]
    regsub {(package require pdf4tcl\s+)\S+} $c "\\1$newVersion" c
    writeFile $f $c
    ok $f

    # -- pkgIndex.tcl --
    set f pkgIndex.tcl
    set c [readFile $f]
    regsub {(package ifneeded pdf4tcl\s+)\S+} $c "\\1$newVersion" c
    writeFile $f $c
    ok $f

    # -- pkg/pkgIndex.tcl --
    set f pkg/pkgIndex.tcl
    set c [readFile $f]
    regsub {(package ifneeded pdf4tcl\s+)\S+} $c "\\1$newVersion" c
    writeFile $f $c
    ok $f

    # -- Makefile --
    set f Makefile
    set c [readFile $f]
    regsub {(VERSION\s*=\s*)\S+} $c "\\1$newNd" c
    writeFile $f $c
    ok $f

    # -- pdf4tcl.man (2 Stellen) --
    set f pdf4tcl.man
    set c [readFile $f]
    regsub {(\[manpage_begin pdf4tcl n\s+)\S+(\])} $c "\\1${newVersion}\\2" c
    regsub {(\[require pdf4tcl \[opt\s+)\S+(\]\])} $c "\\1${newVersion}\\2" c
    writeFile $f $c
    ok "$f (2 Stellen)"

    # -- README.md (nur Heading-Version) --
    set f README.md
    set c [readFile $f]
    regsub {(# pdf4tcl fork \()([0-9.]+)(\))} $c "\\1${newVersion}\\3" c
    writeFile $f $c
    ok $f

    # -- web/index.html --
    set f web/index.html
    set c [readFile $f]
    regsub {(version )[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+} $c "\\1$newVersion" c
    writeFile $f $c
    ok $f

    # -- web/changes.html: neuen Eintrag OBEN einfuegen --
    set f web/changes.html
    set c [readFile $f]
    set today [today]
    set newEntry "\nChanges in v${newVersion} (${today}, fork gregnix):<br>\n<ul>\n  <li> $msg </li>\n</ul>\n"
    # Einfuegen nach dem ersten <ul>...</ul>-Block (nach "Changes in v0.X.X.X")
    # Strategie: vor dem ersten "Changes in v" einfuegen
    regsub {(\nChanges in v)} $c "${newEntry}\\1" c
    writeFile $f $c
    ok "$f (neuer Eintrag)"

    # -- sync-pdf4tcl.tcl (2 Pfade mit dotted version: 0.9.4.15src) --
    set f 0.9.4.x/nogit/scripts/sync-pdf4tcl.tcl
    set c [readFile $f]
    regsub -all "pdf4tcl${oldVersion}src" $c "pdf4tcl${newVersion}src" c
    regsub -all "pdf4tcl${oldVersion}\b" $c "pdf4tcl${newVersion}" c
    writeFile $f $c
    ok $f

    # -- make-release.tcl --
    set f 0.9.4.x/nogit/scripts/make-release.tcl
    set c [readFile $f]
    regsub {(set VERSION\s+")[^"]+(\")} $c "\\1${newVersion}\\2" c
    regsub -all "pdf4tcl${oldNd}src" $c "pdf4tcl${newNd}src" c
    # TAGMSG: Versionsnummer aktualisieren, Rest manuell
    regsub {(set TAGMSG\s+")[^"]*(\")} $c "\\1${newVersion}: ${msg}\\2" c
    writeFile $f $c
    ok $f

    # -- ChangeLog: neuen Eintrag oben --
    set f ChangeLog
    set c [readFile $f]
    set today [today]
    set clEntry "# placeholder - edit manually\n${today} Gregor  <gregnix@github>\n\t* Bumped revision to ${newVersion}\n\t* ${msg}\n\n"
    set c "${clEntry}${c}"
    writeFile $f $c
    ok "$f (Eintrag oben eingefuegt -- bitte manuell ausformulieren)"
}

# ---------------------------------------------------------------------------
# Assemblieren + pkg synchronisieren
# ---------------------------------------------------------------------------
proc assemble {} {
    global dryRun
    set catfiles {
        src/prologue.tcl src/fonts.tcl src/helpers.tcl
        src/options.tcl  src/main.tcl  src/encrypt.tcl src/cat.tcl
    }
    set content ""
    foreach f $catfiles { append content [readFile $f] }
    writeFile pdf4tcl.tcl $content
    writeFile pkg/pdf4tcl.tcl $content
    ok "pdf4tcl.tcl + pkg/pdf4tcl.tcl assembliert"
}

# ---------------------------------------------------------------------------
# Tests ausfuehren
# ---------------------------------------------------------------------------
proc runTests {} {
    puts "\n>> tclsh tests/all.tcl"
    if {[catch {exec tclsh tests/all.tcl 2>@stderr} out]} {
        puts $out
        err "Tests fehlgeschlagen"
    }
    # Letzte Zeile auswerten
    set lines [split $out \n]
    foreach line $lines {
        if {[string match "all.tcl:*" $line]} {
            puts "  $line"
            if {[regexp {Failed\s+(\d+)} $line -> n] && $n > 0} {
                # Failures -- aber pre-existing sind ok
                puts "  Hinweis: $n Failures -- bitte pruefen ob pre-existing"
            }
        }
    }
}

# ---------------------------------------------------------------------------
# git commit + tag + push
# ---------------------------------------------------------------------------
proc doGitRelease {version msg} {
    global dryRun
    set cmds [list \
        [list git add -A] \
        [list git commit -m "Release $version: $msg"] \
        [list git push origin master] \
        [list git tag -a v$version -m "$version: $msg"] \
        [list git push origin v$version] \
    ]
    foreach cmd $cmds {
        puts "\n>> [join $cmd { }]"
        if {$dryRun} { puts "  \[DRY\] uebersprungen"; continue }
        if {[catch {exec {*}$cmd 2>@stderr} out]} {
            puts $out
            err "git Fehler: [join $cmd { }]"
        }
        if {$out ne ""} { puts $out }
    }
}

# ---------------------------------------------------------------------------
# Hauptprogramm
# ---------------------------------------------------------------------------

# Arbeitsverzeichnis muss das Repo-Root sein
if {![file exists src/prologue.tcl]} {
    err "Bitte aus dem pdf4tcl-Wurzelverzeichnis ausfuehren"
}

# Aktuelle Version lesen
set currentVersion [extractVersion src/prologue.tcl \
    {package provide pdf4tcl\s+(\S+)}]
if {$currentVersion eq ""} {
    err "Aktuelle Version nicht erkennbar aus src/prologue.tcl"
}

if {$dryRun} { puts "\n*** DRY-RUN -- keine Dateien werden geschrieben ***" }

# --- Nur Verify ---
if {$doVerify} {
    step "Konsistenzcheck -- aktuelle Version: $currentVersion"
    set ok [verifyAll $currentVersion]
    if {$ok} {
        puts "\nAlle Versionsdateien konsistent ($currentVersion)."
    } else {
        puts "\nKonsistenzfehler gefunden -- bitte oben beheben."
        exit 1
    }
    exit 0
}

# --- Bump ---
step "Konsistenzcheck VOR Bump (erwartet: $currentVersion)"
set beforeOk [verifyAll $currentVersion]
if {!$beforeOk} {
    err "Versionsdateien bereits inkonsistent -- bitte erst bereinigen.\nFuehre 'tclsh tools/bump.tcl --verify' aus um Details zu sehen."
}

step "Bump $currentVersion --> $newVersion"
info "Beschreibung: $msg"
bumpAll $currentVersion $newVersion $msg

step "Assemblieren"
assemble

if {$doTest} {
    step "Tests"
    runTests
}

if {!$dryRun} {
    step "Konsistenzcheck NACH Bump (erwartet: $newVersion)"
    set afterOk [verifyAll $newVersion]
    if {!$afterOk} {
        err "Inkonsistenz nach Bump -- bitte pruefen!"
    }
}

if {$doGit} {
    step "git commit + tag + push"
    doGitRelease $newVersion $msg
}

puts "\n[string repeat = 60]"
if {$dryRun} {
    puts "  DRY-RUN abgeschlossen. Keine Aenderungen vorgenommen."
} else {
    puts "  Bump $currentVersion --> $newVersion abgeschlossen."
    puts ""
    puts "  Noch manuell zu tun:"
    puts "    - ChangeLog ausformulieren (oben eingefuegt)"
    puts "    - web/changes.html Eintrag ausformulieren"
    puts "    - nogit/docs/de/regelbuch-pdf4tcl.md: neuer Abschnitt"
    puts "    - nogit/docs/de/TODO.md: Version + Tabelle"
    puts "    - make doc  (pdf4tcl.html + pdf4tcl.n regenerieren)"
    if {!$doGit} {
        puts "    - git add -A && git commit && git tag v$newVersion && git push"
    }
}
puts [string repeat = 60]
