#!/usr/bin/env tclsh
# Prints how to run the demo suite; optionally runs a tiny smoke demo list
source [file join [file dirname [info script]] ../_bootstrap.tcl]
pdf4tcl::doc::init [info script]
set runner [file join $::pdf4tcl::doc::reporoot demo run-all-demos.tcl]

# Der Pfad wird geprueft, nicht nur gedruckt. Vor dem Flachlegen des
# fork-Verzeichnisses stand hier "0.9.4.x demo", und danach nannte dieses
# Skript klaglos einen Pfad, den es nicht mehr gab -- der Lauf war gruen,
# die Anleitung falsch.
if {![file exists $runner]} {
    puts stderr "Demo runner nicht gefunden: $runner"
    exit 1
}
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
