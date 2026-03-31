#!/usr/bin/env tclsh
# demo-paper-sizes.tcl -- all ISO paper formats (A, B, C + 4A0/2A0) (0.9.4.25)
#
# Shows all supported paper sizes scaled to an A4 page.
# Each format is drawn as a proportional rectangle with label.
# Demonstrates the new B-series (b0-b10) and C-series (c0-c10) formats
# added in 0.9.4.25, alongside the existing A-series.
#
# Usage: tclsh demo-paper-sizes.tcl [outputdir]

set demodir  [file dirname [file normalize [info script]]]
set reporoot [file normalize [file join $demodir ../..]]
set auto_path [linsert $auto_path 0 $reporoot]

package require pdf4tcl

set outdir [expr {$argc > 0 ? [lindex $argv 0] : \
    [file join $demodir out]}]
file mkdir $outdir
set outfile [file join $outdir demo-paper-sizes.pdf]

set pdf [::pdf4tcl::new %AUTO% -paper a4 -orient true]

# ---------------------------------------------------------------------------
# Helper: draw one paper rectangle on the page
# ---------------------------------------------------------------------------
proc drawPaper {pdf x y maxW maxH name color} {
    lassign [pdf4tcl::getPaperSize $name] pw ph
    if {$pw == 0} return

    # Scale to fit maxW x maxH box preserving aspect ratio
    set sx [expr {$maxW / $pw}]
    set sy [expr {$maxH / $ph}]
    set s  [expr {min($sx,$sy)}]
    set rw [expr {$pw * $s}]
    set rh [expr {$ph * $s}]

    lassign $color r g b
    $pdf setFillColor $r $g $b
    $pdf rectangle $x $y $rw $rh -filled 1
    $pdf setFillColor 0.4 0.4 0.4
    $pdf rectangle $x $y $rw $rh
    $pdf setFillColor 0 0 0
    $pdf setFont 6 Helvetica
    set tx [expr {$x + $rw/2.0}]
    set ty [expr {$y + $rh/2.0 + 2}]
    $pdf text [string toupper $name] -x $tx -y $ty
    set ty2 [expr {$y + $rh/2.0 - 5}]
    $pdf setFont 5 Helvetica
    $pdf setFillColor 0.3 0.3 0.3
    $pdf text "[format %.0f $pw]x[format %.0f $ph]pt" \
        -x $tx -y $ty2
    $pdf setFillColor 0 0 0
}

# ---------------------------------------------------------------------------
# Seite 1: A-Serie
# ---------------------------------------------------------------------------
$pdf startPage
$pdf setFont 14 Helvetica-Bold
$pdf text "ISO A-Serie (0.9.4.25)" -x 50 -y 40

set aBlue {0.85 0.92 0.98}
set col 0
set row 0
foreach name {4a0 2a0 a0 a1 a2 a3 a4 a5 a6 a7 a8 a9 a10} {
    set x [expr {50 + $col * 120}]
    set y [expr {60 + $row * 130}]
    drawPaper $pdf $x $y 110 120 $name $aBlue
    incr col
    if {$col >= 4} { set col 0; incr row }
}
$pdf endPage

# ---------------------------------------------------------------------------
# Seite 2: B-Serie
# ---------------------------------------------------------------------------
$pdf startPage
$pdf setFont 14 Helvetica-Bold
$pdf text "ISO B-Serie (0.9.4.25)" -x 50 -y 40

set bGreen {0.88 0.97 0.88}
set col 0
set row 0
foreach name {b0 b1 b2 b3 b4 b5 b6 b7 b8 b9 b10} {
    set x [expr {50 + $col * 120}]
    set y [expr {60 + $row * 130}]
    drawPaper $pdf $x $y 110 120 $name $bGreen
    incr col
    if {$col >= 4} { set col 0; incr row }
}
$pdf endPage

# ---------------------------------------------------------------------------
# Seite 3: C-Serie
# ---------------------------------------------------------------------------
$pdf startPage
$pdf setFont 14 Helvetica-Bold
$pdf text "ISO C-Serie -- Umschlagformate (0.9.4.25)" -x 50 -y 40

set cYellow {0.98 0.96 0.82}
set col 0
set row 0
foreach name {c0 c1 c2 c3 c4 c5 c6 c7 c8 c9 c10} {
    set x [expr {50 + $col * 120}]
    set y [expr {60 + $row * 130}]
    drawPaper $pdf $x $y 110 120 $name $cYellow
    incr col
    if {$col >= 4} { set col 0; incr row }
}
$pdf endPage

# ---------------------------------------------------------------------------
# Seite 4: write -chan Demo
# ---------------------------------------------------------------------------
$pdf startPage
$pdf setFont 14 Helvetica-Bold
$pdf text "write -chan (0.9.4.25)" -x 50 -y 50

$pdf setFont 10 Helvetica
$pdf setFillColor 0.3 0.3 0.3
$pdf text "Neue Option: \$pdf write -chan \$channel" -x 50 -y 75
$pdf setFillColor 0 0 0

$pdf setFont 9 Courier
set lines {
    "# In Datei schreiben (wie bisher):"
    "\$pdf write -file output.pdf"
    ""
    "# In offenen Channel schreiben (NEU 0.9.4.25):"
    "set ch \[open output.pdf w\]"
    "\$pdf write -chan \$ch"
    "close \$ch"
    ""
    "# Mit Memchan (In-Memory, kein tempfile):"
    "package require Memchan"
    "set ch \[memchan\]"
    "\$pdf write -chan \$ch"
    "seek \$ch 0"
    "set data \[read \$ch\]"
    "close \$ch"
    ""
    "# Stdout (wie bisher -- kein Argument):"
    "\$pdf write"
}
set y 100
foreach line $lines {
    $pdf text $line -x 50 -y $y
    set y [expr {$y + 14}]
}
$pdf endPage

$pdf write -file $outfile
$pdf destroy

puts "pdf4tcl 0.9.4.25 -- paper sizes + write -chan demo"
puts "Geschrieben: $outfile"
