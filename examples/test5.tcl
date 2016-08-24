#!/usr/bin/env tclsh

lappend auto_path [pwd]/..
package require pdf4tcl

pdf4tcl::new p1 -compress false -paper a4
p1 startPage

p1 line 100 100 200 200
p1 circle 100 100 50
p1 arc 100 100 90 90 0 90
p1 arc 100 100 85 85 15 135
p1 arc 100 100 85 85 5 -135

p1 startPage -rotate 90

p1 line 100 100 200 200
p1 circle 100 100 50
p1 arc 100 100 90 90 0 90
p1 arc 100 100 85 85 15 135
p1 arc 100 100 85 85 5 -135

# Testing rotated aligned text
p1 startPage
p1 setFont 16p Helvetica

# --- cross hair at text center
p1 setStrokeColor 0.5 0.5 0.5
p1 line 2i 5.5i 4.5i 5.5i
p1 line 3.25i 4i 3.25i 7i
p1 line 3i 5.5i 5.5i 5.5i
p1 line 4.25i 4i 4.25i 7i
p1 line 4i 5.5i 6.5i 5.5i
p1 line 5.25i 4i 5.25i 7i

# --- text at various angles
p1 setStrokeColor 0 0 0
for {set ang 0} {$ang <= 90} {incr ang 45} {
    p1 text "^XX^" -x 3.25i -y 5.5i -align left -angle $ang
    p1 text "^XX^" -x 4.25i -y 5.5i -align center -angle $ang
    p1 text "^XX^" -x 5.25i -y 5.5i -align right -angle $ang
}

p1 write -file test5.pdf
p1 destroy
