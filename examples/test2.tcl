#!/usr/bin/env tclsh

lappend auto_path [pwd]/../..
package require pdf4tcl

pdf4tcl::new p1 -compress 0
p1 startPage -paper {595 842}
p1 setTextPosition 100 100
p1 setFont 12 "Helvetica"
p1 text "Ein Test"
p1 newLine
p1 text "Zweite Zeile"
p1 write -file test2.pdf
p1 destroy

