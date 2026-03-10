#!/usr/bin/env tclsh -encoding cp1251

#lappend auto_path [pwd]/../..
set auto_path [linsert $auto_path 0 [file normalize [file join [file dirname [info script]] ..]]]
#Must be sourced with cp1251 encoding
package require pdf4tcl

proc manypages {} {
    pdf4tcl::loadBaseTrueTypeFont BaseArial "FreeSans.ttf"
    pdf4tcl::createFont BaseArial MyArial cp1251 
    pdf4tcl::new mypdf -paper a4 -compress 1

    set start [clock seconds]
    mypdf startPage
    mypdf setFont 14 MyArial 
    foreach {w h} [mypdf getDrawableArea] break
    set h [expr {$h-30.0}]

    set page 1.0
    set y 30
    for {set f 1} {$f<=30000} {incr f} {
        mypdf text "Ýòî $f ñòðîêà äëèííîãî òåñòîâîãî òåêñòà." -bg #CACACA -x 30 -y $y
        incr y 20
        if {$y>=$h} {
            mypdf endPage 
            mypdf startPage
            mypdf setFont 14 MyArial
            set page [expr {$page+1.0}]
            set y 30
        }
    }

    mypdf write -file mypdfbig.pdf
    mypdf destroy

    set end [clock seconds]
    set sec [expr {$end-$start}]
    set psec [format %2.2f [expr {$page/$sec}]]
    puts "Used $sec seconds for [format %.f $page] pages ($psec pages/sec)."
}

manypages

