#!/usr/bin/env tclsh
# run-all-examples.tcl -- run tutorial + howto companion scripts
#
# Usage:
#   tclsh 0.9.4.x/doc/en/run-all-examples.tcl
#   tclsh 0.9.4.x/doc/en/run-all-examples.tcl --outdir /tmp/docout
#   tclsh 0.9.4.x/doc/en/run-all-examples.tcl --alle   # include canvas/otf/cheatsheets

set here [file dirname [file normalize [info script]]]
set outdir [file join $here out]
set alle 0
for {set i 0} {$i < [llength $argv]} {incr i} {
    switch -- [lindex $argv $i] {
        --outdir { set outdir [lindex $argv [incr i]] }
        --alle   { set alle 1 }
    }
}
file mkdir $outdir

set tclsh [info nameofexecutable]
set ok 0
set skip 0
set fail 0

proc runOne {path} {
    global tclsh outdir ok skip fail alle
    set base [file tail $path]
    # optional / slow / needs extras
    if {!$alle} {
        if {$base in {
            howto-canvas.tcl
            howto-cheatsheets.tcl
        }} {
            puts "SKIP $base (use --alle)"
            incr skip
            return
        }
    }
    puts "RUN  $base"
    set rc [catch {
        exec $tclsh $path $outdir 2>@1
    } out]
    puts $out
    if {$rc} {
        if {[string match *SKIP* $out]} {
            incr skip
        } else {
            puts "FAIL $base"
            incr fail
        }
    } else {
        if {[string match *SKIP* $out]} {
            incr skip
        } else {
            incr ok
        }
    }
}

foreach dir {tutorials howtos} {
    foreach f [lsort [glob -nocomplain [file join $here $dir *.tcl]]] {
        runOne $f
    }
}

puts ""
puts "OK=$ok  SKIP=$skip  FAIL=$fail  outdir=$outdir"
exit [expr {$fail > 0}]
