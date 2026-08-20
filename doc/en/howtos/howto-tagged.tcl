#!/usr/bin/env tclsh
# How-to: tagged PDF.
#
# Shows the four calls that make a document readable by a screen reader,
# and -- the part that matters -- how to find out whether anything was
# left out.

source [file join [file dirname [info script]] ../_bootstrap.tcl]
pdf4tcl::doc::init [info script]

# PDF/UA needs every font programme embedded. The standard 14 have none,
# so a tagged document set in Helvetica claims something it cannot keep.
set font [pdf4tcl::doc::needFont freesans]
pdf4tcl::loadBaseTrueTypeFont BaseTag $font
pdf4tcl::createFontSpecCID BaseTag Body

set pdf [::pdf4tcl::new %AUTO% -paper a4 -margin 50 -orient 1]

# Four things turn structure on. The order matters: tagged before the
# first page, or the content of that page has nowhere to go.
$pdf tagged 1 -lang en-GB -ua 1
$pdf metadata -title "Quarterly report" -author "pdf4tcl"
$pdf viewerPreferences -displaydoctitle 1

$pdf startPage

# --------------------------------------------------------------------------
# A heading and a paragraph
# --------------------------------------------------------------------------

$pdf setFont 18 Body
$pdf tagText H1 "Quarterly report" -x 0 -y 40

$pdf setFont 11 Body
$pdf tagText P "Sales rose in every region." -x 0 -y 80

# tagBegin/tagEnd where several draws belong to one element.
$pdf tagBegin P
$pdf text "A paragraph can be drawn in pieces --" -x 0 -y 110
$pdf text "they still form one element." -x 0 -y 126
$pdf tagEnd

# --------------------------------------------------------------------------
# A table, which is where tagging earns its keep
# --------------------------------------------------------------------------

$pdf setFont 11 Body
$pdf tagBegin Table

$pdf tagBegin TR
foreach {kopf x} {Region 0 Revenue 150 Change 260} {
    $pdf tagText TH $kopf -scope Column -x $x -y 170
}
$pdf tagEnd

set y 190
foreach {region umsatz aenderung} {
    North  "12,400" "+4%"
    South   "9,850" "+11%"
    Export  "3,100" "-2%"
} {
    $pdf tagBegin TR
    $pdf tagText TD $region    -x 0   -y $y
    $pdf tagText TD $umsatz    -x 150 -y $y
    $pdf tagText TD $aenderung -x 260 -y $y
    $pdf tagEnd
    incr y 18
}
$pdf tagEnd

# --------------------------------------------------------------------------
# Decoration is not content
# --------------------------------------------------------------------------

# A rule carries no meaning. Marked as an artifact it stays out of the
# structure tree -- and out of what a screen reader announces.
$pdf tagArtifact
$pdf setStrokeColor 0.6 0.6 0.6
$pdf line 0 260 400 260
$pdf tagArtifactEnd

# An image, on the other hand, is content, and needs a description. Without
# -alt a screen reader announces "graphic" and nothing else.
$pdf tagBegin Figure -alt "Bar chart: revenue by region, North highest"
$pdf setFillColor 0.3 0.5 0.8
foreach {x h} {0 30 40 22 80 8} {
    $pdf rectangle $x [expr {320 - $h}] 30 $h -filled 1
}
$pdf tagEnd

$pdf setFillColor 0 0 0

# --------------------------------------------------------------------------
# What was left out?
# --------------------------------------------------------------------------

# Text drawn without a tag while tagging is on is content a screen reader
# cannot reach. It is counted, not refused -- so ask.
#
# Drawn here inside tagBegin/tagEnd, because a document that DEMONSTRATES
# the mistake would fail veraPDF at clause 7.1 and could not be used as an
# example of a tagged file. Leave the tags off and getUntaggedCount goes
# to 1 -- try it.
$pdf setFont 11 Body
$pdf tagBegin P
$pdf text "Every painting operation belongs to an element or an artifact." \
        -x 0 -y 380
$pdf tagEnd

set untagged [$pdf getUntaggedCount]
$pdf setFont 9 Body
$pdf tagArtifact
$pdf text "getUntaggedCount reports $untagged item(s) outside the tree." \
        -x 0 -y 410
$pdf text "Anything above zero means a screen reader cannot reach that part." \
        -x 0 -y 424
$pdf tagArtifactEnd

set out [pdf4tcl::doc::outfile howto-tagged.pdf]
$pdf write -file $out

puts "untagged items: $untagged"
if {[llength $::pdf4tcl::warnings]} {
    foreach w $::pdf4tcl::warnings { puts "warning: $w" }
}

pdf4tcl::doc::done $out
$pdf destroy
