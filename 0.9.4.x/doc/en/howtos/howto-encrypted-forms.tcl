#!/usr/bin/env tclsh
source [file join [file dirname [info script]] ../_bootstrap.tcl]
pdf4tcl::doc::init [info script]
set pdf [::pdf4tcl::new %AUTO% -paper a4 -orient 1 \
        -userpassword "geheim" -ownerpassword "admin" -encversion 4]
$pdf startPage
$pdf setFont 12 Helvetica
$pdf text "Name: (AES-128, password geheim)" -x 50 -y 60
$pdf addForm text 50 70 250 16 -id f_name
$pdf endPage
set out [pdf4tcl::doc::outfile howto-encrypted-forms.pdf]
$pdf write -file $out
$pdf destroy
pdf4tcl::doc::done $out
