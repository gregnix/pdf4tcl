#!/usr/bin/env tclsh

# test8 -- field appearance (-align, -color, -border*, -bgcolor) and
#          calculated fields (-calculate) added in pdf4tcl 0.9.4.30 / .32.

set auto_path [linsert $auto_path 0 [file join [file dirname [info script]] ..]]
package require pdf4tcl

pdf4tcl::new p1 -orient 0 -compress false -paper a4

p1 startPage
p1 setFont 16 "Helvetica-Bold"
p1 text "Field appearance & calculation" -x 50 -y 800

# ---------------------------------------------------------------------------
# Text alignment (-align)
# ---------------------------------------------------------------------------
p1 setFont 12 "Helvetica-Bold"
p1 text "Alignment (-align)" -x 50 -y 765
p1 setFont 10 "Helvetica"

p1 text "Left:"   -x 50 -y 743
p1 addForm text 150 735 200 18 -id aLeft   -align left   -init "left"
p1 text "Center:" -x 50 -y 720
p1 addForm text 150 712 200 18 -id aCenter -align center -init "center"
p1 text "Right:"  -x 50 -y 697
p1 addForm text 150 689 200 18 -id aRight  -align right  -init "right"

# ---------------------------------------------------------------------------
# Text color, border and background (-color, -borderwidth/-bordercolor, -bgcolor)
# ---------------------------------------------------------------------------
p1 setFont 12 "Helvetica-Bold"
p1 text "Color, border, background" -x 50 -y 660
p1 setFont 10 "Helvetica"

p1 text "Text color:"  -x 50 -y 638
p1 addForm text 150 630 200 18 -id cColor -color {0.8 0 0} -init "red text"

p1 text "Border:"      -x 50 -y 613
p1 addForm text 150 605 200 18 -id cBorder -borderwidth 1 -bordercolor {0 0 1}

p1 text "Background:"  -x 50 -y 588
p1 addForm text 150 580 200 18 -id cBg -bgcolor {0.93 0.93 0.82}

p1 text "Combined:"    -x 50 -y 563
p1 addForm text 150 555 200 18 -id cAll -align right \
    -color {0 0.4 0} -borderwidth 1.5 -bordercolor {0 0.4 0} \
    -bgcolor {0.90 1.0 0.90} -init "styled"

# ---------------------------------------------------------------------------
# Calculated fields (-calculate) -- needs a JavaScript-capable viewer
# (Adobe Acrobat/Reader, Firefox, Chrome/Edge, Foxit) for live recalculation.
# The -init value is the static, pre-computed result shown everywhere else.
# ---------------------------------------------------------------------------
p1 setFont 12 "Helvetica-Bold"
p1 text "Calculation (-calculate)" -x 50 -y 520
p1 setFont 9 "Helvetica-Oblique"
p1 text "Live recalculation needs a JavaScript-capable viewer; the shown value is the static pre-computed result." \
    -x 50 -y 505
p1 setFont 10 "Helvetica"

# Three source amounts (right aligned)
p1 text "Position 1:" -x 50 -y 480
p1 addForm text 200 472 120 18 -id pos1 -align right -borderwidth 0.5 -init "100"
p1 text "Position 2:" -x 50 -y 457
p1 addForm text 200 449 120 18 -id pos2 -align right -borderwidth 0.5 -init "250"
p1 text "Position 3:" -x 50 -y 434
p1 addForm text 200 426 120 18 -id pos3 -align right -borderwidth 0.5 -init "50"

p1 setStrokeColor 0 0 0
p1 setLineWidth 0.5
p1 line 200 421 320 421

# Sum = pos1 + pos2 + pos3  (static pre-value 400)
p1 setFont 10 "Helvetica-Bold"
p1 text "Sum:" -x 50 -y 405
p1 setFont 10 "Helvetica"
p1 addForm text 200 397 120 18 -id total -align right \
    -calculate {sum {pos1 pos2 pos3}} -init "400" \
    -borderwidth 1 -bgcolor {0.95 0.95 0.82}

# Min / Max over the same fields
p1 text "Min:" -x 50 -y 372
p1 addForm text 200 364 120 18 -id fmin -align right \
    -calculate {min {pos1 pos2 pos3}} -init "50" -borderwidth 0.5
p1 text "Max:" -x 50 -y 349
p1 addForm text 200 341 120 18 -id fmax -align right \
    -calculate {max {pos1 pos2 pos3}} -init "250" -borderwidth 0.5

p1 setFont 9 "Helvetica-Oblique"
p1 text "Try it: open in Acrobat or Firefox, change a position, and Sum/Min/Max update." \
    -x 50 -y 315

p1 write -file test8.pdf
p1 destroy
