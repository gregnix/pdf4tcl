# Tagged PDF demo -- writes tagged.pdf next to this script
#
# Run:   tclsh examples/tagged.tcl
# Check: python3 tools/check-tagged.py examples/tagged.pdf
#        verapdf -f ua1 examples/tagged.pdf
#
# COORDINATES
# pdf4tcl defaults to -orient 1: y counts DOWNWARD from the top margin and x
# rightward from the left margin, so (0,0) is the top left corner of the
# drawable area and the margins are already accounted for. Adding the margin
# to the coordinates again shifts everything right and down.
#
# An earlier version of this file used y=780 for the heading and y=40 for the
# running foot, as if the origin were at the bottom left. The page then read
# from bottom to top with the foot at the top -- and veraPDF still called it
# PDF/UA compliant, because it validates the structure tree, not the layout.

lappend auto_path [file join [file dirname [file dirname [file normalize [info script]]]]]
package require pdf4tcl

# PDF/UA requires every font program to be embedded (ISO 14289-1 clause
# 7.21.4.1). The base 14 fonts (Helvetica and friends) have no embeddable
# program at all, so a real TrueType font is loaded instead. FreeSans ships
# with the examples; only one weight is available, so the heading hierarchy
# below is carried by size rather than by boldness.
set fontFile [file join [file dirname [file normalize [info script]]] FreeSans.ttf]
pdf4tcl::loadBaseTrueTypeFont BaseFreeSans $fontFile
pdf4tcl::createFont BaseFreeSans DemoFont iso8859-1

set pdf [pdf4tcl::new %AUTO% -paper a4 -margin 50]
$pdf tagged 1 -lang de-DE -ua 1

# PDF/UA-1 requires a document title in the XMP metadata (clause 7.1-9) and
# ViewerPreferences/DisplayDocTitle true (clause 7.1-10), so that a reader
# announces the title rather than the file name.
$pdf metadata -title "Tagged PDF mit pdf4tcl" \
        -author "pdf4tcl" -subject "Beispiel fuer Tagged PDF"
$pdf viewerPreferences -displaydoctitle 1

# Drawable area, i.e. the page minus the margins.
lassign [$pdf getDrawableArea] areaWidth areaHeight

# Vertical cursor, growing downward from the top of the drawable area.
set y 0
proc down {points} {
    upvar 1 y y
    incr y $points
    return $y
}

proc footer {pdf page areaWidth areaHeight} {
    # Running foot: not part of the document content, so it is an artifact.
    # Placed just above the bottom edge of the drawable area.
    $pdf tagArtifact -type Pagination -subtype Footer
    $pdf setFont 8 DemoFont
    $pdf text "Seite $page" -x [expr {$areaWidth - 40}] \
            -y [expr {$areaHeight - 4}]
    $pdf tagArtifactEnd
}

# ---------------------------------------------------------------- page 1
$pdf startPage
footer $pdf 1 $areaWidth $areaHeight

$pdf setFont 18 DemoFont
$pdf tagText H1 "Tagged PDF mit pdf4tcl" -x 0 -y [down 18]

$pdf setFont 11 DemoFont
$pdf tagBegin P
$pdf text "Dieser Absatz besteht aus zwei Zeilen und ist ein" -x 0 -y [down 30]
$pdf text "einziges Strukturelement." -x 0 -y [down 15]
$pdf tagEnd

$pdf tagBegin P
$pdf text "Mehr dazu auf der" -x 0 -y [down 22]
$pdf tagBegin Link -alt "pdf4tcl project page on GitHub"
$pdf tagText Span "Projektseite" -x 105 -y $y
$pdf hyperlinkAdd 105 [expr {$y - 9}] 65 12 \
        "https://github.com/gregnix/pdf4tcl"
$pdf tagEnd
$pdf tagEnd

$pdf setFont 14 DemoFont
$pdf tagText H2 "Eine Liste" -x 0 -y [down 32]

$pdf setFont 11 DemoFont
$pdf tagBegin L -listnumbering Decimal
down 22
foreach {label body} {
    "1." "Erster Punkt"
    "2." "Zweiter Punkt"
    "3." "Dritter Punkt"
} {
    $pdf tagBegin LI
    $pdf tagText Lbl   $label -x 10 -y $y
    $pdf tagText LBody $body  -x 30 -y $y
    $pdf tagEnd
    down 18
}
$pdf tagEnd

$pdf setFont 14 DemoFont
$pdf tagText H2 "Eine Tabelle" -x 0 -y [down 14]

$pdf setFont 10 DemoFont
$pdf tagBegin Table
down 22
$pdf tagBegin TR
set x 0
set col 0
foreach head {Artikel Menge Preis} {
    # /Scope says the header applies to its column; /ID lets the data cells
    # below name it explicitly through -headers.
    $pdf tagText TH $head -scope Column -id "h$col" -x $x -y $y
    incr x 150
    incr col
}
$pdf tagEnd
down 16
foreach row {
    {Schraube 100 4,90}
    {Mutter 200 3,50}
} {
    $pdf tagBegin TR
    set x 0
    set col 0
    foreach cell $row {
        $pdf tagText TD $cell -headers "h$col" -x $x -y $y
        incr x 150
        incr col
    }
    $pdf tagEnd
    down 16
}
$pdf tagEnd

# A graphic carries no text at all -- /Alt is the only thing a screen
# reader can announce.
down 20
$pdf tagBegin Figure -alt "Rotes Quadrat neben blauem Kreis" -title "Abbildung 1"
$pdf setFillColor 0.8 0.1 0.1
$pdf rectangle 0 $y 60 60 -filled 1
$pdf setFillColor 0.1 0.2 0.8
$pdf circle 150 [expr {$y + 30}] 30 -filled 1
$pdf setFillColor 0 0 0
$pdf tagEnd
down 80

# Decoration: a rule is not content
$pdf tagArtifact -type Layout
$pdf setLineWidth 0.5
$pdf line 0 $y $areaWidth $y
$pdf tagArtifactEnd

# ---------------------------------------------------------------- page 2
# This paragraph is opened on page 1 and closed on page 2.
$pdf setFont 11 DemoFont
$pdf tagBegin P
$pdf text "Dieser Absatz beginnt auf Seite eins ..." -x 0 -y [down 24]
$pdf startPage
footer $pdf 2 $areaWidth $areaHeight
$pdf text "... und endet auf Seite zwei." -x 0 -y 0
$pdf tagEnd

set outfile [file join [file dirname [file normalize [info script]]] tagged.pdf]
$pdf write -file $outfile
$pdf destroy
puts "wrote $outfile"
