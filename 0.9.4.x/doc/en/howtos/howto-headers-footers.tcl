#!/usr/bin/env tclsh
source [file join [file dirname [info script]] ../_bootstrap.tcl]
pdf4tcl::doc::init [info script]
set pdf [::pdf4tcl::new %AUTO% -paper a4 -orient 1 -margin 50]
set pageNo 0
proc pageChrome {pdf title} {
    upvar 1 pageNo pageNo
    incr pageNo
    lassign [$pdf getDrawableArea] W H
    $pdf setFont 9 Helvetica
    $pdf setFillColor 0.4 0.4 0.4
    $pdf text $title -x 0 -y 10
    $pdf setStrokeColor 0.75 0.75 0.75
    $pdf setLineWidth 0.4
    $pdf line 0 14 $W 14
    $pdf text "Page $pageNo" -x [expr {$W - 40}] -y [expr {$H - 8}]
    $pdf setFillColor 0 0 0
}
foreach n {1 2} {
    $pdf startPage
    pageChrome $pdf "My document"
    $pdf setFont 12 Helvetica
    $pdf text "Body of page $n" -x 0 -y 40
    $pdf endPage
}
set out [pdf4tcl::doc::outfile howto-headers-footers.pdf]
$pdf write -file $out
$pdf destroy
pdf4tcl::doc::done $out
