#!/usr/bin/env tclsh
# Minimal stand-in for demo-all / minimalPdf (see those demos for the full tour)
source [file join [file dirname [info script]] ../_bootstrap.tcl]
pdf4tcl::doc::init [info script]
set pdf [::pdf4tcl::new %AUTO% -paper a4 -orient 1 -margin 50]
$pdf metadata -title "Feature tour (short)"
$pdf startPage
$pdf setFont 16 Helvetica-Bold
$pdf text "Feature tour (short)" -x 0 -y 24
$pdf setFont 11 Helvetica
$pdf text "Full tour: demo/demo-all.tcl" -x 0 -y 50
$pdf text "Minimal: demo/minimalPdf.tcl" -x 0 -y 70
$pdf setFillColor 0.2 0.4 0.7
$pdf rectangle 0 90 120 40 -filled 1
$pdf hyperlinkAdd 0 140 200 14 "https://github.com/gregnix/pdf4tcl"
$pdf setFillColor 0 0 0
$pdf text "github.com/gregnix/pdf4tcl" -x 0 -y 152
$pdf endPage
set out [pdf4tcl::doc::outfile howto-feature-tour.pdf]
$pdf write -file $out
$pdf destroy
pdf4tcl::doc::done $out
