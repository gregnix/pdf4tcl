#!/usr/bin/env tclsh

set auto_path [linsert $auto_path 0 [file join [file dirname [info script]] ..]]
# puts stderr $auto_path
package require pdf4tcl

pdf4tcl::new p1 -compress false -paper a4
p1 startPage
p1 line 100 140 300 160
p1 setStrokeColor 1 0 0
p1 arrow 100 150 300 170 10 15
p1 curve 100 100 200 300 300 100
p1 setStrokeColor 0 0 0
p1 setFillColor 0.3 0.6 0.9
p1 rectangle 400 40 166 166 -filled 1
p1 setFillColor 0 0 0
p1 setFont 12 "Helvetica"
p1 text "linksbündig" -x 100 -y 200
p1 text "rechtsbündig \xAC" -x 100 -y 214 -align right
p1 text "zentriert" -x 100 -y 228 -align center
p1 setFont 8 "Times-Roman"
p1 text "Dies ist ein etwas längerer Satz in einer kleineren Schriftart." \
        -x 100 -y 242
p1 setFont 12 "Courier-Bold"
for {set w 0} {$w<360} {incr w 15} {
 	p1 text "   rotierter Text" -angle $w -x 200 -y 400 
}
p1 circle 200 400 130
p1 setFillColor 1 1 1
p1 setLineStyle 0.1 5 2
p1 rectangle 348 288 224 104 -filled 1
p1 setFillColor 0 0 0
p1 setFont 12 "Times-Italic"
p1 drawTextBox 350 290 220 100 "Dieser Abschnitt sollte im Blocksatz gesetzt sein.\n\nDie Textbox ist 220 Postscript-Punkte breit. pdf4tcl teilt den Text an Leerzeichen, Zeilenendezeichen und Bindestrichen auf." -align justify
p1 setFillColor 0.8 0.8 0.8
p1 rectangle 348 408 224 54 -filled 1
p1 setFillColor 0 0 0
p1 drawTextBox 350 410 220 50 "Eine links- oder rechtsbündige und auch eine zentrierte Ausrichtung in der Textbox sind ebenfalls möglich." -align right
p1 addImage tcl.jpg -id 1
p1 putImage 1 20 20 -height 75
p1 setFillColor 1.0 0 0
p1 setStrokeColor 0 0 1
p1 setLineStyle 0.2 1 0
p1 polygon 100 600 300 600 250 650 150 650 -filled 1
p1 setStrokeColor 0 0.5 0
p1 polygon 300 650 500 650 450 600 350 600
# Second page uses -orient 0
p1 startPage -orient 0
p1 line 100 140 300 160
p1 setStrokeColor 1 0 0
p1 arrow 100 150 300 170 10 15
p1 curve 100 100 200 300 300 100
p1 setStrokeColor 0 0 0
p1 setFillColor 0.3 0.6 0.9
p1 rectangle 400 40 166 166 -filled 1
p1 setFillColor 0 0 0
p1 text "linksbündig" -x 100 -y 200
p1 text "rechtsbündig \xAC" -align right -x 100 -y 214
p1 text "zentriert" -align center -x 100 -y 228
p1 setFont 8 "Times-Roman"
p1 text "Dies ist ein etwas längerer Satz in einer kleineren Schriftart." \
        -x 100 -y 242
p1 setFont 12 "Courier-Bold"
for {set w 0} {$w<360} {incr w 15} {
 	p1 text "   rotierter Text" -angle $w -x 200 -y 400
}
p1 circle 200 400 130
p1 setFillColor 1 1 1
p1 setLineStyle 0.1 5 2
p1 rectangle 348 288 224 104 -filled 1
p1 setFillColor 0 0 0
p1 setFont 12 "Times-Italic"
p1 drawTextBox 350 290 220 100 "Dieser Abschnitt sollte im Blocksatz gesetzt sein.\n\nDie Textbox ist 220 Postscript-Punkte breit. pdf4tcl teilt den Text an Leerzeichen, Zeilenendezeichen und Bindestrichen auf." -align justify
p1 setFillColor 0.8 0.8 0.8
p1 rectangle 348 408 224 54 -filled 1
p1 setFillColor 0 0 0
p1 drawTextBox 350 410 220 50 "Eine links- oder rechtsbündige und auch eine zentrierte Ausrichtung in der Textbox sind ebenfalls möglich." -align right
p1 putImage 1 20 20 -height 75
p1 setFillColor 1.0 0 0
p1 setStrokeColor 0 0 1
p1 setLineStyle 0.2 1 0
p1 polygon 100 600 300 600 250 650 150 650 -filled 1
p1 setStrokeColor 0 0.5 0
p1 polygon 300 650 500 650 450 600 350 600

# Image stuff
p1 startPage -orient 1
p1 addImage ../examples/smile.png   -id 2
p1 addImage ../examples/ccitt_4.tif -id 3
p1 addImage ../examples/ecf22e.tif  -id 4 

package require Tk
image create photo img1 -file ../examples/smile.png
set imgdata [img1 data]
namespace import tcl::mathop::*
proc cross {x y} {
    p1 line [- $x 100] $y [+ $x 100] $y
    p1 line $x [- $y 100] $x [+ $y 100]
}
# Rotated image
p1 putImage 2 200 200 -height 75 -angle 0
p1 putImage 2 200 200 -height 75 -angle 60
p1 putImage 2 200 200 -height 75 -angle 120
p1 putImage 2 200 200 -height 75 -angle 180
p1 putRawImage $imgdata 200 200 -height 75 -angle 240 -compress 1
cross 200 200
p1 putImage 2 200 400 -height 90 -angle 223 -anchor center
cross 200 400
p1 putImage 2 400 400 -height 52 -angle 65 -anchor ne
cross 400 400
p1 putImage 2 400 600 -height 87 -angle 87 -anchor se
cross 400 600
# Rotated image, other orientation
p1 startPage -orient 0
p1 putImage 2 200 200 -height 75 -angle 0
p1 putImage 2 200 200 -height 75 -angle 60
p1 putImage 2 200 200 -height 75 -angle 120
p1 putImage 2 200 200 -height 75 -angle 180
p1 putImage 2 200 200 -height 75 -angle 240
cross 200 200
p1 putImage 2 200 400 -height 90 -angle 223 -anchor center
cross 200 400
p1 putImage 2 400 400 -height 52 -angle 65 -anchor ne
cross 400 400
p1 putImage 2 400 600 -height 87 -angle 87 -anchor se
cross 400 600
p1 putImage 3 200 600 -height 100 -anchor center
cross 200 600
p1 putImage 4 200 700 -height 100 -anchor center
cross 200 700

p1 addImage gmarbles2.jpg -id marble
p1 putImage marble 20 700 -height 75

p1 write -file test4.pdf
p1 destroy
exit
