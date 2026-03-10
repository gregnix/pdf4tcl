#!/usr/bin/env tclsh

#lappend auto_path [file join [file dirname [info script]] ..]
set auto_path [linsert $auto_path 0 [file normalize [file join [file dirname [info script]] ..]]]
package require pdf4tcl

pdf4tcl::new p1 -compress false -paper a4
p1 startPage
p1 setFont 12 "Helvetica"

# Test aimed at angled stuff

# Cross at 100 100
p1 line 50 100 150 100
p1 line 100 50 100 150
# Text leaning down
p1 text "Lean down" -x 100 -y 100 -align left -angle -20 -bg {1 0 0}

# Cross at 300 300
p1 line 250 300 350 300
p1 line 300 250 300 350
# Text leaning up
p1 text "Lean up" -x 300 -y 300 -align center -angle 20 -bg {0 1 0}

# Cross at 500 500
p1 line 450 500 550 500
p1 line 500 450 500 550
# Text leaning up
p1 text "Lean up left" -x 500 -y 500 -align right -angle 110 -bg {0.3 0.3 1}

# Cross at 100 500
p1 line  50 500 150 500
p1 line 100 450 100 550
# Text leaning up
p1 text "Lean up, yskew" -x 100 -y 500 -align center -angle 50 -bg {0.3 0.3 1} \
        -yangle 40
p1 text "Lean up, noskew" -x 130 -y 500 -align center -angle 50

# Cross at 500 100
p1 line 450 100 550 100
p1 line 500  50 500 150
# Text leaning up
p1 text "Lean down, xskew" -x 500 -y 100 -align center -angle -50 -bg {0.3 0.3 1} \
        -xangle 40
p1 text "Lean down, noskew" -x 470 -y 100 -align center -angle -50

# Second page is a canvas test
p1 startPage

package require Tk
canvas .c
.c create rectangle 0 0 500 500 -outline black

# Control fonts using named fonts
font create MyArial1 -family Arial -size -14
font create MyArial2 -family Arial -size -14
# Chars within iso8859-1
.c create text 10 10 -text "Apa bepa \xe5 \xd5 cepa" -anchor nw \
        -font MyArial1
# Special chars needs a unique font to make an encoding mapping
.c create text 10 30 -text "1\u20ac!" -anchor nw \
        -font MyArial2

pdf4tcl::loadBaseTrueTypeFont BaseArial "../examples/FreeSans.ttf"
pdf4tcl::createFont BaseArial MyArial1 iso8859-1
# "1" "euro" and "!" maps to 0 1 and 2
set subset [list 49 [expr 0x20AC] 33]
pdf4tcl::createFontSpecEnc BaseArial MyArial2 $subset

.c create line 10 50 80 80 -dash "..."
.c create line 10 60 80 90 -dash "..." -width 5

p1 canvas .c -fontmap {MyArial1 "MyArial1 16" MyArial2 "MyArial2 13"}

p1 write -file test3.pdf
p1 destroy
exit
