#!/usr/bin/env tclsh
# build.tcl -- Assemble pdf4tcl.tcl from source files.
# Works on Linux, macOS and Windows (no make/cat required).
#
# Usage:  tclsh build.tcl

set srcFiles {
    src/prologue.tcl
    src/fonts.tcl
    src/helpers.tcl
    src/options.tcl
    src/main.tcl
    src/cat.tcl
}

set scriptDir [file dirname [file normalize [info script]]]
set outFile   [file join $scriptDir pdf4tcl.tcl]

set out [open $outFile w]
fconfigure $out -translation lf

foreach f $srcFiles {
    set path [file join $scriptDir $f]
    if {![file exists $path]} {
        close $out
        puts stderr "ERROR: $path not found"
        exit 1
    }
    set fh [open $path r]
    puts -nonewline $out [read $fh]
    close $fh
}

close $out
puts "Assembled: $outFile"
