#!/usr/bin/env tclsh

set auto_path [linsert $auto_path 0 [file normalize [file join [file dirname [info script]] ..]]]

package require pdf4tcl

set ver  [package present pdf4tcl]
set file [lindex [package ifneeded pdf4tcl $ver] ]
set scriptdir [file dirname [info script]]
puts "pdf4tcl $ver load froms: \n$file"
puts "scriptdir: \n$scriptdir"
puts "\nauto_path:\n[join $auto_path \n]\n"


pdf4tcl::new p1 -compress 0
p1 startPage -paper {595 842}
p1 write -file test0.pdf
p1 destroy

