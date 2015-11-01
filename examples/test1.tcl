#!/usr/bin/env tclsh

lappend auto_path [pwd]/../..
package require pdf4tcl

pdf4tcl::new p1 -compress false -paper a4
p1 startPage
p1 line 100 140 300 160
p1 setStrokeColor 1 0 0
p1 arrow 100 150 300 170 10 15
p1 setStrokeColor 0 0 0
p1 setFillColor 0.3 0.6 0.9
p1 rectangle 400 40 166 166 -filled 1
p1 setFillColor 0 0 0
p1 setFont 12 "Helvetica"
p1 text "linksbündig" -x 100 -y 200
p1 rectangle 200 40 166 20
p1 addForm text 200 40 166 20
p1 setFont 8 "Helvetica"
p1 rectangle 400 40 50 20
p1 addForm text 400 40 50 20
p1 rectangle 200 80 40 40
p1 addForm checkbutton 200 80 40 40
p1 rectangle 280 80 20 20
p1 addForm checkbutton 280 80 20 20
p1 setFont 12 "Helvetica"
p1 text "rechtsbündig \xAC" -align right -x 100 -y 214
p1 text "zentriert" -align center -x 100 -y 228
p1 setFont 8 "Times-Roman"
p1 text "Dies ist ein etwas längerer Satz in einer kleineren Schriftart." -x 100 -y 242
p1 setFont 12 "Courier-Bold"
for {set w 0} {$w<360} {incr w 15} {
 	p1 text "   rotierter Text" -angle $w -x 200 -y 400
}
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
p1 addJpeg tcl.jpg 1
p1 putImage 1 20 20 -height 75
p1 write -file test1.pdf
p1 cleanup

