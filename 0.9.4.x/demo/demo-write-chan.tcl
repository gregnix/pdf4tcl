#!/usr/bin/env tclsh
# demo-write-chan.tcl -- demonstrate write -chan option (0.9.4.25)
#
# write -chan writes the generated PDF to an existing open channel instead
# of a file. Useful for:
#   - In-memory processing without temp files (with Memchan)
#   - Sending PDF directly over a socket
#   - Piping PDF to another process (e.g. lp, gs)
#
# This demo shows three use cases:
#   1. -chan with a regular file channel (equivalent to -file)
#   2. -chan with a pipe to gs for immediate rendering
#   3. Size comparison: -file vs -chan vs get
#
# Usage: tclsh demo-write-chan.tcl [outputdir]

set demodir  [file dirname [file normalize [info script]]]
set reporoot [file normalize [file join $demodir ../..]]
set auto_path [linsert $auto_path 0 $reporoot]

package require pdf4tcl

set outdir [expr {$argc > 0 ? [lindex $argv 0] : \
    [file join $demodir out]}]
file mkdir $outdir

# Helper: build a sample PDF object
proc makeSamplePdf {} {
    set pdf [::pdf4tcl::new %AUTO% -paper a4 -orient true]
    $pdf startPage
    $pdf setFont 20 Helvetica-Bold
    $pdf text "write -chan Demo (0.9.4.25)" -x 50 -y 50
    $pdf setFont 12 Helvetica
    $pdf setFillColor 0.3 0.3 0.3
    $pdf text "PDF written via -chan option" -x 50 -y 80
    $pdf setFillColor 0 0 0

    # Draw a simple diagram
    $pdf setFillColor 0.85 0.92 0.98
    $pdf rectangle 50 110 200 60 -filled 1
    $pdf setFillColor 0 0 0
    $pdf setFont 11 Helvetica-Bold
    $pdf text "\$pdf write -chan \$ch" -x 55 -y 135
    $pdf setFont 9 Helvetica
    $pdf text "schreibt PDF in offenen Channel" -x 55 -y 152

    # Arrow
    $pdf line 255 140 300 140

    # Channel box
    $pdf setFillColor 0.88 0.98 0.88
    $pdf rectangle 305 110 140 60 -filled 1
    $pdf setFillColor 0 0 0
    $pdf setFont 11 Helvetica-Bold
    $pdf text "Channel" -x 310 -y 135
    $pdf setFont 9 Helvetica
    $pdf text "file/socket/pipe" -x 310 -y 152

    $pdf endPage
    return $pdf
}

# ---------------------------------------------------------------------------
# Use case 1: -chan mit File-Channel (equivalent zu -file)
# ---------------------------------------------------------------------------
puts "=== Use case 1: write -chan mit File-Channel ==="

set out1 [file join $outdir demo-write-chan-1.pdf]
set pdf [makeSamplePdf]

set ch [open $out1 w]
fconfigure $ch -translation binary
$pdf write -chan $ch
close $ch
$pdf destroy

puts "  Geschrieben: $out1"
puts "  Groesse:     [file size $out1] Bytes"

# Vergleich mit -file
set out1b [file join $outdir demo-write-chan-1b.pdf]
set pdf [makeSamplePdf]
$pdf write -file $out1b
$pdf destroy

set sz1  [file size $out1]
set sz1b [file size $out1b]
puts "  -chan Groesse: $sz1 Bytes"
puts "  -file Groesse: $sz1b Bytes"
puts "  Identisch: [expr {$sz1 == $sz1b ? \"JA\" : \"NEIN\"}]"
puts ""

# ---------------------------------------------------------------------------
# Use case 2: -chan in Tcl-Variable (In-Memory ohne Memchan)
# ---------------------------------------------------------------------------
puts "=== Use case 2: In-Memory via fcopy + pipe ==="

# Tcl 8.6+: pipe mit chan pipe
set pdf [makeSamplePdf]
set data [$pdf get]
$pdf destroy

# Schreibe data via -chan in tmp, dann lese zurück
# (Memchan nicht vorausgesetzt -- universell nutzbar)
set tmpf [file join $outdir demo-write-chan-tmp.pdf]
set ch [open $tmpf w]
fconfigure $ch -translation binary
puts -nonewline $ch $data
close $ch

set fd [open $tmpf rb]
set readback [read $fd]
close $fd
file delete $tmpf

puts "  get -> string -> channel -> verify"
puts "  Groesse original:  [string length $data] Bytes"
puts "  Groesse readback:  [string length $readback] Bytes"
puts "  Identisch: [expr {$data eq $readback ? \"JA\" : \"NEIN\"}]"
puts ""

# ---------------------------------------------------------------------------
# Use case 3: -chan in stdout (Pipe zu anderem Programm)
# ---------------------------------------------------------------------------
puts "=== Use case 3: write -chan stdout ==="
puts "  Beispiel fuer Shell-Pipe:"
puts "  tclsh demo.tcl | gs -sDEVICE=png16m -sOutputFile=out.png -"
puts ""
puts "  Im Code:"
puts {  set ch [open "|lp -" w]}
puts {  $pdf write -chan $ch}
puts {  close $ch}
puts ""

# ---------------------------------------------------------------------------
# Vergleich aller Methoden
# ---------------------------------------------------------------------------
puts "=== Vergleich write-Methoden ==="
puts [format "  %-30s %s" "Methode" "Ergebnis"]
puts [format "  %-30s %s" "------" "-------"]
puts [format "  %-30s %s" {$pdf write -file path} "PDF in Datei"]
puts [format "  %-30s %s" {$pdf write -chan $ch}  "PDF in offenen Channel"]
puts [format "  %-30s %s" {$pdf write}            "PDF nach stdout"]
puts [format "  %-30s %s" {set d [$pdf get]}      "PDF als Tcl-String"]
puts ""
puts "Alle Ausgaben in: $outdir"
