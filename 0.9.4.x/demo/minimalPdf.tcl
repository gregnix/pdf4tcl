#!/usr/bin/env tclsh
set demodir  [file dirname [file normalize [info script]]]
set reporoot [file normalize [file join $demodir ../..]]
set auto_path [linsert $auto_path 0 $reporoot]

package require pdf4tcl

set pdf [::pdf4tcl::new %AUTO% -paper a4 -orient true]
$pdf startPage
$pdf setFont 18 Helvetica-Bold
$pdf text "Hello World!" -x 50 -y 100
$pdf endPage
set demoOutDir [file join [file dirname [file normalize [info script]]] out]
if {$argc > 0} { set demoOutDir [lindex $argv 0] }
file mkdir $demoOutDir
$pdf write -file [file join $demoOutDir hello.pdf]
$pdf destroy




