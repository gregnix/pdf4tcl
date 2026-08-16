#!/usr/bin/env tclsh
source [file join [file dirname [info script]] ../_bootstrap.tcl]
pdf4tcl::doc::init [info script]
set pdf [::pdf4tcl::new %AUTO% -paper a4 -orient 1 \
        -userpassword "user" -ownerpassword "admin" -permissions print]
$pdf startPage
$pdf setFont 11 Helvetica
$pdf text "Open with user / admin. Permissions: print" -x 40 -y 40
$pdf endPage
set out [pdf4tcl::doc::outfile howto-permissions.pdf]
$pdf write -file $out
$pdf destroy
pdf4tcl::doc::done $out
