#!/usr/bin/env tclsh

#lappend auto_path [pwd]/../..
set auto_path [linsert $auto_path 0 [file normalize [file join [file dirname [info script]] ..]]]
package require pdf4tcl

proc example_specenc {} {
    pdf4tcl::loadBaseTrueTypeFont BaseArial "FreeSans.ttf"
    # Subset is a list of unicodes:
    for {set f 0} {$f < 128} {incr f} {lappend subset $f}
    lappend subset [expr 0xB2] [expr 0x3B2]

    pdf4tcl::createFontSpecEnc BaseArial MyArial $subset 
    pdf4tcl::new mypdf -paper a4 -compress 1
    mypdf startPage
    mypdf setFont 16 MyArial
    set txt "sin\u00B2\u03B2 + cos\u00B2\u03B2 = 1"
    mypdf text $txt -x 50 -y 100
    mypdf write -file specenc.pdf
    mypdf destroy
}

example_specenc
