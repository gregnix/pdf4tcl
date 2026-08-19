#!/usr/bin/env tclsh
# restore-pkg-symlinks.tcl
#
# Stellt pkg/ als Symlink-Verzeichnis wieder her.
# Jede Datei in pkg/ zeigt auf die entsprechende Datei im Repo-Root.
# VERSION wird automatisch aus src/prologue.tcl gelesen.
#
# Verwendung:
#   tclsh tools/restore-pkg-symlinks.tcl
#   tclsh tools/restore-pkg-symlinks.tcl --dry-run
#
# Liegt seit 0.9.4.44 in tools/ statt in nogit/scripts/: pkg/ gehoert zum
# Repo, also gehoert auch das Werkzeug dazu, das pkg/ herstellt.

# VERSION aus src/prologue.tcl lesen
proc readVersion {repodir} {
    set f [file join $repodir src/prologue.tcl]
    if {![file exists $f]} { return "" }
    set fh [open $f r]
    set content [read $fh]
    close $fh
    if {[regexp {package provide pdf4tcl\s+(\S+)} $content -> v]} { return $v }
    return ""
}

set dryrun [expr {[lsearch $argv --dry-run] >= 0}]
if {$dryrun} { puts "*** DRY-RUN -- keine Aenderungen ***\n" }

# REPODIR wird GESUCHT, nicht gezaehlt. "../../.." stimmte, solange das
# Skript unter nogit/scripts/ lag; nach dem Flachlegen zeigte es
# eine Ebene zu hoch, und das Skript brach mit
#   FEHLER: Version nicht erkennbar aus /home/.../tk/src/prologue.tcl
# ab -- einem Pfad ausserhalb des Repos.
# Markierung ist pkgIndex.tcl neben src/; beides gibt es nur in der Wurzel.
set SCRIPTDIR [file dirname [file normalize [info script]]]
set REPODIR ""
set dir $SCRIPTDIR
for {set i 0} {$i < 8} {incr i} {
    if {[file exists [file join $dir pkgIndex.tcl]]
            && [file isdirectory [file join $dir src]]} {
        set REPODIR $dir
        break
    }
    set parent [file dirname $dir]
    if {$parent eq $dir} break
    set dir $parent
}
if {$REPODIR eq ""} {
    puts stderr "FEHLER: pdf4tcl-Wurzel nicht gefunden ueber $SCRIPTDIR"
    exit 1
}

set VERSION [readVersion $REPODIR]
if {$VERSION eq ""} {
    puts stderr "FEHLER: Version nicht erkennbar aus $REPODIR/src/prologue.tcl"
    exit 1
}

set PKGDIR [file join $REPODIR pkg]

set FILES {
    pdf4tcl.tcl
    pdf4tcl.html
    pdf4tcl.man
    pkgIndex.tcl
    stdmetrics.tcl
    stdkern.tcl
    glyph2uni.tcl
    licence.terms
}

puts "Repo:    $REPODIR"
puts "Version: $VERSION"
puts "pkg/:    $PKGDIR\n"

if {![file isdirectory $REPODIR]} {
    puts stderr "FEHLER: Repo nicht gefunden: $REPODIR"; exit 1
}
if {![file isdirectory $PKGDIR]} {
    puts stderr "FEHLER: pkg/ nicht gefunden: $PKGDIR"; exit 1
}

foreach f $FILES {
    set target [file join $REPODIR $f]
    set link   [file join $PKGDIR  $f]

    if {![file exists $target]} {
        puts "  SKIP $f -- Quelle nicht gefunden"
        continue
    }
    if {$dryrun} {
        puts "  DRY  pkg/$f -> ../$f"
        continue
    }
    if {[file exists $link] || [catch {file type $link}] == 0} {
        file delete $link
    }
    exec ln -s ../$f $link
    puts "  OK   pkg/$f -> ../$f"
}

if {!$dryrun} { puts "\npkg/ Symlinks wiederhergestellt (Version $VERSION)." }
