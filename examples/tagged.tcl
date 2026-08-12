# Tagged PDF demo -- writes tagged.pdf
#
# Run:  tclsh examples/tagged.tcl
# Check: python3 tools/check-tagged.py tagged.pdf

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

proc footer {pdf page} {
    # Running foot: not part of the document content
    $pdf tagArtifact -type Pagination -subtype Footer
    $pdf setFont 8 DemoFont
    $pdf text "Seite $page" -x 500 -y 40
    $pdf tagArtifactEnd
}

# ---------------------------------------------------------------- page 1
$pdf startPage
footer $pdf 1

$pdf setFont 18 DemoFont
$pdf tagText H1 "Tagged PDF mit pdf4tcl" -x 50 -y 780

$pdf setFont 11 DemoFont
$pdf tagBegin P
$pdf text "Dieser Absatz besteht aus zwei Zeilen und ist ein" -x 50 -y 750
$pdf text "einziges Strukturelement." -x 50 -y 735
$pdf tagEnd

$pdf setFont 14 DemoFont
$pdf tagText H2 "Eine Liste" -x 50 -y 700

$pdf setFont 11 DemoFont
$pdf tagBegin L
set y 675
foreach {label body} {
    "1." "Erster Punkt"
    "2." "Zweiter Punkt"
    "3." "Dritter Punkt"
} {
    $pdf tagBegin LI
    $pdf tagText Lbl   $label -x 60 -y $y
    $pdf tagText LBody $body  -x 80 -y $y
    $pdf tagEnd
    incr y -18
}
$pdf tagEnd

$pdf setFont 14 DemoFont
$pdf tagText H2 "Eine Tabelle" -x 50 -y 590

$pdf setFont 10 DemoFont
$pdf tagBegin Table
set y 565
$pdf tagBegin TR
set x 50
foreach head {Artikel Menge Preis} {
    # PDF/UA needs /Scope where the header relation is not derivable
    $pdf tagText TH $head -scope Column -x $x -y $y
    incr x 150
}
$pdf tagEnd
incr y -16
foreach row {
    {Schraube 100 4,90}
    {Mutter 200 3,50}
} {
    $pdf tagBegin TR
    set x 50
    foreach cell $row {
        $pdf tagText TD $cell -x $x -y $y
        incr x 150
    }
    $pdf tagEnd
    incr y -16
}
$pdf tagEnd

# A graphic carries no text at all -- /Alt is the only thing a screen
# reader can announce.
$pdf tagBegin Figure -alt "Rotes Quadrat \u2192 blauer Kreis" -title "Abbildung 1"
$pdf setFillColor 0.8 0.1 0.1
$pdf rectangle 50 420 60 60 -filled 1
$pdf setFillColor 0.1 0.2 0.8
$pdf circle 200 450 30 -filled 1
$pdf setFillColor 0 0 0
$pdf tagEnd

# Decoration: a rule is not content
$pdf tagArtifact -type Layout
$pdf setLineWidth 0.5
$pdf line 50 400 545 400
$pdf tagArtifactEnd

# ---------------------------------------------------------------- page 2
# This paragraph is opened on page 1 and closed on page 2.
$pdf setFont 11 DemoFont
$pdf tagBegin P
$pdf text "Dieser Absatz beginnt auf Seite eins ..." -x 50 -y 380
$pdf startPage
footer $pdf 2
$pdf text "... und endet auf Seite zwei." -x 50 -y 780
$pdf tagEnd

# Write next to this script, not into the current directory. Running
# "tclsh examples/tagged.tcl" from the repository root used to drop the file
# in the root while a stale copy stayed in examples/, and validating the
# wrong one costs more time than it saves.
set outfile [file join [file dirname [file normalize [info script]]] tagged.pdf]
$pdf write -file $outfile
$pdf destroy
puts "wrote $outfile"
