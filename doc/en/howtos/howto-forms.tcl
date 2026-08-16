#!/usr/bin/env tclsh
source [file join [file dirname [info script]] ../_bootstrap.tcl]
pdf4tcl::doc::init [info script]
set pdf [::pdf4tcl::new %AUTO% -paper a4 -orient 1 -margin 50]
$pdf startPage
$pdf setFont 12 Helvetica
$pdf text "Name:" -x 0 -y 40
$pdf addForm text 60 28 200 16 -id f_name
$pdf addForm pushbutton 0 70 90 20 -id f_reset -caption "Reset" -action reset
$pdf addForm pushbutton 100 70 90 20 -id f_go -caption "Submit" -action submit \
        -url "mailto:orders@example.com"
$pdf endPage
set out [pdf4tcl::doc::outfile howto-forms.pdf]
$pdf write -file $out
$pdf destroy
pdf4tcl::doc::done $out
