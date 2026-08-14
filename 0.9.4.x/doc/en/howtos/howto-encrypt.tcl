#!/usr/bin/env tclsh
source [file join [file dirname [info script]] ../_bootstrap.tcl]
pdf4tcl::doc::init [info script]
set pdf [::pdf4tcl::new %AUTO% -paper a4 -orient 1 \
        -userpassword "open-me" -ownerpassword "change-me" -permissions print]
$pdf startPage
$pdf setFont 12 Helvetica
$pdf text "Confidential. Password: open-me" -x 50 -y 50
$pdf endPage
set out [pdf4tcl::doc::outfile howto-encrypt.pdf]
$pdf write -file $out
$pdf destroy
pdf4tcl::doc::done $out
