#!/usr/bin/env tclsh

set auto_path [linsert $auto_path 0 [pwd]/..]
# puts stderr $auto_path
package require pdf4tcl

pdf4tcl::new p1 -compress false -paper a4
p1 startPage
p1 setFont 12 "Helvetica"
p1 text "Bookmark 1" -x 10 -y 10
p1 bookmarkAdd -title "Bookmark 1"
p1 bookmarkAdd -title "Bookmark 1.1" -level 1

#p1 setTextPosition 50 50
#set bboxb [p1 getFontMetric bboxb]
#set bboxt [p1 getFontMetric bboxt]
#set dh [expr {$bboxb - $bboxt}]
#set sp [expr {$dh / 12.0}]
#p1 text "FilljXYÅÄÖQ" -fill "1.0 0.0 0.0"
#p1 newLine $sp
#p1 text " iilljXYÅÄ" -fill "0.0 1.0 0.0"

set xobj1 [p1 startXObject -margin 100 -paper {1000 1000}]
p1 line 0 0 800 800
p1 setLineWidth 10
p1 line 0 800 800 0 
p1 endPage

set xobj2 [p1 startXObject]
p1 setFillColor \#FF0000
p1 setStrokeColor \#0000FF
p1 circle 50 50 40 -filled 1
p1 circle 50 50 20
p1 endPage

p1 startPage
p1 text "Bookmark 2" -x 50 -y 50
p1 bookmarkAdd -title "Bookmark 2"
p1 bookmarkAdd -title "Bookmark 2.1" -level 1
p1 bookmarkAdd -title "Bookmark 2.1.1" -level 2
p1 bookmarkAdd -title "Bookmark 2.1.2" -level 2
p1 bookmarkAdd -title "Bookmark 2.2" -level 1
p1 bookmarkAdd -title "Bookmark 2.2.1" -level 2
p1 bookmarkAdd -title "Bookmark 2.2.2" -level 2

set fid [p1 embedFile "data.txt" -contents "This should be stored in the file."]
p1 attachFile 0 0 100 100 $fid "This is the description"

p1 embedFile "data2.txt" -contents "This should be stored in the second file \u00E5 \u00F5." -id ScndFile
p1 attachFile 200 0 100 100 ScndFile "This is the second description" -icon Tag

set fid [p1 embedFile "data3.txt" -contents "This should be stored in the third file."]
p1 attachFile 0 200 100 100 $fid "This is the third description" -icon Graph

set fid [p1 embedFile "data4.txt" -contents "This should be stored in the fourth file."]
p1 attachFile 200 200 100 100 $fid "This is the fourth description" -icon PushPin

set fid [p1 embedFile "data5.txt" -contents "This should be stored in the fourth file."]
p1 attachFile 0 400 150 180 $fid "This is the fourth description" -icon $xobj2

set fid [p1 embedFile "data6.txt" -contents "This should be stored in the fourth file."]
p1 attachFile 200 400 100 100 $fid "This is the fourth description" -icon $xobj1

p1 putImage $xobj2 0 600 -width 80 -height 50

p1 startPage
p1 text "Bookmark 3" -x 100 -y 100
p1 bookmarkAdd -title "Bookmark 3"
p1 bookmarkAdd -title "Bookmark 3.1" -level 1
p1 bookmarkAdd -title "Bookmark 3.1.1" -level 2
p1 bookmarkAdd -title "Bookmark 3.1.2" -level 2
p1 bookmarkAdd -title "Bookmark 3.2" -level 1 -closed 1
p1 bookmarkAdd -title "Bookmark 3.2.1" -level 2
p1 bookmarkAdd -title "Bookmark 3.2.2" -level 2

p1 write -file test6.pdf
p1 destroy
