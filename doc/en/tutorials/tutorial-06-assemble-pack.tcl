#!/usr/bin/env tclsh
# Companion to tutorial-06-assemble-pack.md
# Builds a multi-source reading pack: cover, images, text notes, appended PDF.
source [file join [file dirname [info script]] ../_bootstrap.tcl]
pdf4tcl::doc::init [info script]

set sampleDir [file join $::pdf4tcl::doc::outdir assemble-samples]
file mkdir $sampleDir

# --- sample assets ----------------------------------------------------------
set shot [file join $sampleDir screenshot.png]
set shot2 [file join $sampleDir diagram.png]
set notes [file join $sampleDir notes.txt]
set appendix [file join $sampleDir appendix.pdf]
set samplePng [file join [file dirname [info script]] ../howtos/_sample.png]

if {[file exists $samplePng]} {
    file copy -force $samplePng $shot
    file copy -force $samplePng $shot2
} else {
    # fallback: tiny PNG via raw write already in howtos; require it
    return -code error "missing howtos/_sample.png -- run from repo checkout"
}

set fh [open $notes w]
fconfigure $fh -encoding utf-8
puts $fh "Meeting follow-ups"
puts $fh ""
puts $fh "Please review in this order:"
puts $fh "1. Screenshot of the login UI"
puts $fh "2. These notes"
puts $fh "3. Architecture diagram"
puts $fh "4. Appendix PDF"
puts $fh ""
# pad so drawTextBox may wrap / spill a second page on small margins
for {set i 1} {$i <= 40} {incr i} {
    puts $fh "Line $i: Confirm deployment checklist item and owner for Q2."
}
close $fh

# one-page appendix PDF
set ap [::pdf4tcl::new %AUTO% -paper a4 -orient 1 -margin 50]
$ap metadata -title "Appendix"
$ap startPage
$ap setFont 14 Helvetica-Bold
$ap text "Appendix" -x 0 -y 30
$ap setFont 11 Helvetica
$ap text "This page came from a separate PDF, merged with catPdf." -x 0 -y 60
$ap endPage
$ap write -file $appendix
$ap destroy

# --- assemble body ----------------------------------------------------------
set body [pdf4tcl::doc::outfile tutorial-06-pack-body.pdf]
set pdf [::pdf4tcl::new %AUTO% -paper a4 -orient 1 -margin 40]
$pdf metadata -title "Reading pack" -author "pdf4tcl tutorial" \
        -subject "Screenshots, notes, images, appendix"

proc chrome {pdf title pageNo} {
    lassign [$pdf getDrawableArea] W H
    $pdf setFont 8 Helvetica
    $pdf setFillColor 0.45 0.45 0.45
    $pdf text $title -x 0 -y 8
    $pdf text "Page $pageNo" -x [expr {$W - 40}] -y [expr {$H - 6}]
    $pdf setStrokeColor 0.8 0.8 0.8
    $pdf setLineWidth 0.4
    $pdf line 0 12 $W 12
    $pdf setFillColor 0 0 0
}

set page 0

# Cover
incr page
$pdf startPage
chrome $pdf "Reading pack" $page
$pdf setFont 22 Helvetica-Bold
$pdf text "Reading pack" -x 0 -y 50
$pdf setFont 11 Helvetica
$pdf text "Single PDF for review -- read top to bottom." -x 0 -y 80
set y 120
$pdf setFont 12 Helvetica-Bold
$pdf text "Contents" -x 0 -y $y
incr y 24
$pdf setFont 11 Helvetica
foreach item {
    "1. Screenshot -- UI after login"
    "2. Notes -- meeting follow-ups"
    "3. Diagram -- architecture sketch"
    "4. Appendix -- existing one-page PDF"
} {
    $pdf text $item -x 0 -y $y
    incr y 18
}
$pdf bookmarkAdd -title "Cover" -level 0
$pdf endPage

# Screenshot
incr page
$pdf startPage
chrome $pdf "Reading pack" $page
$pdf bookmarkAdd -title "1. Screenshot" -level 0
$pdf setFont 12 Helvetica-Bold
$pdf text "1. Screenshot -- UI after login" -x 0 -y 28
set id [$pdf addImage $shot]
lassign [$pdf getDrawableArea] W H
$pdf putImage $id 0 45 -width [expr {min($W, 400)}]
$pdf endPage

# Notes (paginated)
set fh [open $notes r]
fconfigure $fh -encoding utf-8
set rest [read $fh]
close $fh
set part 0
while {$rest ne ""} {
    incr part
    incr page
    $pdf startPage
    chrome $pdf "Reading pack" $page
    if {$part == 1} {
        $pdf bookmarkAdd -title "2. Notes" -level 0
        $pdf setFont 12 Helvetica-Bold
        $pdf text "2. Notes -- meeting follow-ups" -x 0 -y 28
        set top 48
    } else {
        set top 28
    }
    $pdf setFont 10 Helvetica
    lassign [$pdf getDrawableArea] W H
    set rest [$pdf drawTextBox 0 $top $W [expr {$H - $top - 16}] $rest]
    $pdf endPage
}

# Diagram image
incr page
$pdf startPage
chrome $pdf "Reading pack" $page
$pdf bookmarkAdd -title "3. Diagram" -level 0
$pdf setFont 12 Helvetica-Bold
$pdf text "3. Diagram -- architecture sketch" -x 0 -y 28
set id2 [$pdf addImage $shot2]
$pdf putImage $id2 0 45 -width [expr {min($W, 350)}]
$pdf endPage

$pdf write -file $body
$pdf destroy

# Append appendix PDF
set out [pdf4tcl::doc::outfile tutorial-06-reading-pack.pdf]
set ::pdf4tcl::warnings {}
# -title, weil sonst der Titel der ersten Datei gilt (0.9.4.48).
pdf4tcl::catPdf -title "Reading pack" $body $appendix $out
pdf4tcl::doc::done $out
puts "samples in $sampleDir"
puts "body:    $body"
if {[llength $::pdf4tcl::warnings]} {
    foreach w $::pdf4tcl::warnings { puts "warning: $w" }
}
