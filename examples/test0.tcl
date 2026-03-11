#!/usr/bin/env tclsh

# ./pdf4tcl/examples/test0.tcl
set auto_path [linsert $auto_path 0 [file normalize [file join [file dirname [info script]] ..]]]

package require pdf4tcl

set ver  [package present pdf4tcl]
set file [lindex [package ifneeded pdf4tcl $ver] ]
set scriptfile [info script]
set scriptdir [file dirname [info script]]
set pwddir [pwd]
puts "pdf4tcl $ver load froms: \n$file"
puts "scriptdir: \n$scriptdir"
puts "scriptfile:_\n$scriptfile"
puts "pwd: \n$pwddir\n"
puts "\nauto_path:\n[join $auto_path \n]\n"


pdf4tcl::new p1 -compress 0

p1 metadata \
        -title    "pdf4tcl [file tail $scriptfile]" \
        -keywords  "./pdf4tcl/examples/test0.tcl" \
        -creator  "pdf4tcl $ver" \
        -moddate  [clock seconds]

p1 startPage -paper {595 842}
p1 write -file test0.pdf
p1 destroy

