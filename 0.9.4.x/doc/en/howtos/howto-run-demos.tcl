#!/usr/bin/env tclsh
# Prints how to run the demo suite; optionally runs a tiny smoke demo list
source [file join [file dirname [info script]] ../_bootstrap.tcl]
pdf4tcl::doc::init [info script]
set runner [file join $::pdf4tcl::doc::reporoot 0.9.4.x demo run-all-demos.tcl]
puts "Demo runner: $runner"
puts "Example:"
puts "  tclsh $runner"
puts "  tclsh $runner --outdir /tmp/pdfout"
puts "  tclsh $runner --alle"
set pdf [::pdf4tcl::new %AUTO% -paper a4 -orient 1 -margin 50]
$pdf startPage
$pdf setFont 12 Helvetica
$pdf text "See howto-run-demos.md / run-all-demos.tcl" -x 0 -y 40
$pdf endPage
set out [pdf4tcl::doc::outfile howto-run-demos.pdf]
$pdf write -file $out
$pdf destroy
pdf4tcl::doc::done $out
