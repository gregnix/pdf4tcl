#!/usr/bin/env tclsh
#
# layout-check.tcl -- does the text on the page overlap or run into the margin?
#
# The gap this fills: qpdf says whether the file is intact, veraPDF whether it
# keeps the promise it makes, pdfcheck-native whether the structures are
# right. None of them looks at where the text ENDS UP. A report can pass every
# one of those and still be unreadable, because two blocks sit on top of each
# other.
#
# Grown out of nogit/scripts/pdflab, which has this as one tab among many.
# Here it is on its own so it can run in the acceptance chain.
#
# Usage:
#     tclsh tools/layout-check.tcl FILE.pdf ...
#     tclsh tools/layout-check.tcl -margin 20 doc/en/out/
#
# Exit status is 1 when something was found, so it can gate a build.
#
# Needs pdftotext (poppler-utils). Without it the script says so and exits 0 --
# a missing tool is not a finding.
#
# What a finding means has to be read, not obeyed. Two of the shipped
# examples report one:
#
#   howto-xobject.pdf     places the same XObject on several pages, so the
#                         same words land in the same spot. That is what the
#                         howto demonstrates.
#   howto-paper-sizes.pdf writes at -x 0 with the document's own margin, so
#                         the word sits inside the text area but within 36pt
#                         of the sheet edge.
#
# Both are correct output. The check finds where text ENDS UP, and whether
# that is wrong depends on what the page is for.
#
# Three kinds of page report findings that are not defects, measured over
# demo/out where 25 of 50 files did:
#
#   dense character tables   pdftotext gives every character its own box and
#                            neighbouring boxes touch. unicode-tabelle-
#                            FreeSerif.pdf reports 2309 overlaps and is fine.
#   reference cards          laid out with small margins on purpose. The
#                            three cheat sheets report 76 to 89 each.
#   transformed text         a rotated word has an axis-aligned bounding box
#                            much larger than the glyphs. demo-transform.tcl
#                            uses 23 transformations and reports 12.
#
# So this is a check for pages of ordinary running text, and it is worth
# running where that is what they are. "make layoutcheck" covers doc/en/out
# for that reason and leaves demo/out alone: a check that cries wolf half
# the time gets ignored, and then it catches nothing at all.

package require Tcl 8.6-

namespace eval ::layoutcheck {
    variable margin 36        ;# points; 36pt = half an inch
    variable toleranz 1.0     ;# points; below this it is a box artefact
    variable verbose 0
}

# Read the word boxes out of "pdftotext -tsv".
#
# Column positions are taken from the header rather than counted, because they
# differ between poppler versions -- that is what the fallback below is for.
proc ::layoutcheck::parseTsv {tsvfile} {
    set words {}
    if {![file exists $tsvfile]} { return {} }
    set ch [open $tsvfile r]
    fconfigure $ch -translation auto -encoding utf-8
    gets $ch header
    set cols [split $header "\t"]
    set iLevel  [lsearch $cols "level"]
    set iPage   [lsearch $cols "page_num"]
    set iLeft   [lsearch $cols "left"]
    set iTop    [lsearch $cols "top"]
    set iWidth  [lsearch $cols "width"]
    set iHeight [lsearch $cols "height"]
    set iText   [lsearch $cols "text"]
    if {$iLevel < 0} {
        set iLevel 0; set iPage 1; set iLeft 2; set iTop 3
        set iWidth 4; set iHeight 5; set iText 6
    }
    while {[gets $ch line] >= 0} {
        if {[string trim $line] eq ""} continue
        set f [split $line "\t"]
        if {[llength $f] < 7} continue
        if {[lindex $f $iLevel] != 5} continue      ;# level 5 = a word
        set l [lindex $f $iLeft];  set t [lindex $f $iTop]
        set w [lindex $f $iWidth]; set h [lindex $f $iHeight]
        set txt [lindex $f $iText]
        if {$txt eq "" || $w <= 0 || $h <= 0} continue
        lappend words [dict create \
                page [lindex $f $iPage] left $l top $t \
                width $w height $h text $txt \
                right [expr {$l + $w}] bottom [expr {$t + $h}]]
    }
    close $ch
    return $words
}

# Do two word boxes overlap by more than a hair?
#
# pdftotext reports the LINE box, not the glyphs: a 4pt word comes back
# 10.5pt high, because the box spans ascender to descender. Set two such
# lines 9.9pt apart -- a perfectly readable table -- and the boxes touch by
# half a point while nothing on the page does.
#
# So a tolerance, in points. Measured on unicode-tabelle-DejaVuSans.pdf:
# the header and the first row report a 0.57pt overlap and look fine. The
# two real defects found this way were 9pt (demo-pdfa-3a) and a whole line
# (demo-kerning-ligatures), so 1pt separates them cleanly.
proc ::layoutcheck::overlaps {a b} {
    variable toleranz
    set waag [expr {min([dict get $a right],  [dict get $b right])
                  - max([dict get $a left],   [dict get $b left])}]
    set senk [expr {min([dict get $a bottom], [dict get $b bottom])
                  - max([dict get $a top],    [dict get $b top])}]
    expr {$waag > $toleranz && $senk > $toleranz}
}

# Page size in points, from pdfinfo. Needed for the right and bottom margin;
# without it only left and top can be judged.
proc ::layoutcheck::pageSize {pdf} {
    if {[catch {exec pdfinfo $pdf} out]} { return {} }
    if {[regexp {Page size:\s+([0-9.]+) x ([0-9.]+)} $out -> w h]} {
        return [list $w $h]
    }
    return {}
}

proc ::layoutcheck::checkFile {pdf} {
    variable margin
    variable verbose

    set tsv [file join [file dirname $pdf] \
            "_layoutcheck_[pid].tsv"]
    # Look at the file, not at the exit status. pdftotext writes syntax
    # warnings to stderr and exec turns those into an error, although the
    # TSV is there and complete -- measured on howto-gradients.pdf, which
    # produced eight lines of output alongside two warnings.
    #
    # A password-protected file is the real failure: nothing is written.
    catch {exec pdftotext -tsv $pdf $tsv 2>@1} e
    if {![file exists $tsv] || ![file size $tsv]} {
        catch {file delete $tsv}
        set e [string map {\n " "} $e]
        return [list error "pdftotext: [string range $e 0 55]"]
    }
    set words [parseTsv $tsv]
    catch {file delete $tsv}
    if {![llength $words]} { return [list ok "no text"] }

    # Overlaps, per page. Comparing every word with every other is O(n^2);
    # for a page of text that is a few thousand comparisons, which is fine,
    # and grouping by page keeps it from growing across a long document.
    set proSeite [dict create]
    foreach w $words {
        dict lappend proSeite [dict get $w page] $w
    }
    set gefunden {}
    dict for {pg liste} $proSeite {
        set n [llength $liste]
        for {set i 0} {$i < $n} {incr i} {
            for {set j [expr {$i + 1}]} {$j < $n} {incr j} {
                set a [lindex $liste $i]
                set b [lindex $liste $j]
                if {![overlaps $a $b]} continue
                lappend gefunden [list overlap $pg \
                        [dict get $a text] [dict get $b text]]
            }
        }
    }

    # Margins. Right and bottom need the page size; where pdfinfo gives
    # nothing, only left and top are judged rather than guessing.
    set masse [pageSize $pdf]
    foreach w $words {
        set pg [dict get $w page]
        if {[dict get $w left] < $margin} {
            lappend gefunden [list margin $pg left [dict get $w text]]
        }
        if {[dict get $w top] < $margin} {
            lappend gefunden [list margin $pg top [dict get $w text]]
        }
        if {[llength $masse] == 2} {
            lassign $masse pw ph
            if {[dict get $w right] > $pw - $margin} {
                lappend gefunden [list margin $pg right [dict get $w text]]
            }
            if {[dict get $w bottom] > $ph - $margin} {
                lappend gefunden [list margin $pg bottom [dict get $w text]]
            }
        }
    }

    if {![llength $gefunden]} {
        return [list ok "[llength $words] word(s)"]
    }
    return [list found $gefunden]
}

proc ::layoutcheck::main {argv} {
    variable margin
    variable toleranz
    variable verbose

    set dateien {}
    for {set i 0} {$i < [llength $argv]} {incr i} {
        set a [lindex $argv $i]
        switch -- $a {
            -margin { incr i; set margin [lindex $argv $i] }
            -tol    { incr i; set toleranz [lindex $argv $i] }
            -v      { set verbose 1 }
            -h - --help {
                puts "usage: layout-check.tcl ?-margin PT? ?-v? FILE.pdf|DIR ..."
                return 0
            }
            default {
                if {[file isdirectory $a]} {
                    foreach f [lsort [glob -nocomplain [file join $a *.pdf]]] {
                        lappend dateien $f
                    }
                } else {
                    lappend dateien $a
                }
            }
        }
    }
    if {![llength $dateien]} {
        puts "usage: layout-check.tcl ?-margin PT? ?-v? FILE.pdf|DIR ..."
        return 2
    }
    if {[auto_execok pdftotext] eq ""} {
        puts "layout-check: pdftotext not found -- skipped"
        return 0
    }

    set schlecht 0
    set geprueft 0
    foreach f $dateien {
        incr geprueft
        lassign [checkFile $f] status info
        switch -- $status {
            ok {
                if {$verbose} { puts [format "  %-44s OK   %s" [file tail $f] $info] }
            }
            error {
                puts [format "  %-44s SKIP %s" [file tail $f] $info]
            }
            found {
                incr schlecht
                set ueber 0
                set rand 0
                foreach e $info {
                    if {[lindex $e 0] eq "overlap"} { incr ueber } else { incr rand }
                }
                puts [format "  %-44s %d overlap(s), %d margin(s)" \
                        [file tail $f] $ueber $rand]
                if {$verbose} {
                    foreach e [lrange $info 0 5] {
                        if {[lindex $e 0] eq "overlap"} {
                            puts "      page [lindex $e 1]: \"[lindex $e 2]\"\
                                    over \"[lindex $e 3]\""
                        } else {
                            puts "      page [lindex $e 1]: [lindex $e 2]\
                                    margin, \"[lindex $e 3]\""
                        }
                    }
                    if {[llength $info] > 6} {
                        puts "      ... and [expr {[llength $info] - 6}] more"
                    }
                }
            }
        }
    }
    puts ""
    puts [format "%d file(s): %d clean, %d with findings (margin %spt)" \
            $geprueft [expr {$geprueft - $schlecht}] $schlecht $margin]
    return [expr {$schlecht > 0}]
}

if {[info exists argv0] && [file tail $argv0] eq "layout-check.tcl"} {
    exit [::layoutcheck::main $argv]
}
