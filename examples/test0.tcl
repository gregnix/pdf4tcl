#!/usr/bin/env tclsh

lappend auto_path [pwd]/../..
package require pdf4tcl

pdf4tcl::new p1 -compress 0
p1 startPage -paper {595 842}
p1 write -file test0.pdf
p1 destroy

