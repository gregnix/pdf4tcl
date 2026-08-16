#!/usr/bin/env tclsh
# Needs Tk + DISPLAY. Companion to howto-canvas.md
source [file join [file dirname [info script]] ../_bootstrap.tcl]
pdf4tcl::doc::init [info script]
if {![info exists ::env(DISPLAY)] || $::env(DISPLAY) eq ""} {
    puts "SKIP howto-canvas: no DISPLAY"
    exit 0
}
if {[catch {package require Tk} err]} {
    puts "SKIP howto-canvas: $err"
    exit 0
}
canvas .c -width 400 -height 200 -background white
.c create rectangle 20 20 120 80 -fill #4472c4 -outline black
.c create text 200 100 -text "Hello canvas" -font {Helvetica 14}
set pdf [::pdf4tcl::new %AUTO% -paper a4 -orient 1]
$pdf startPage
$pdf canvas .c -x 50 -y 50 -width 400 -height 200
$pdf endPage
set out [pdf4tcl::doc::outfile howto-canvas.pdf]
$pdf write -file $out
$pdf destroy
pdf4tcl::doc::done $out
exit 0
