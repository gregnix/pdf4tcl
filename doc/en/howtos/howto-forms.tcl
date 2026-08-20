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

# ---------------------------------------------------------------------------
# Reading and filling (0.9.4.50)
# ---------------------------------------------------------------------------

# What is in the form?
set felder [pdf4tcl::getForms $out]
puts "fields: [join [lsort [dict keys $felder]] {, }]"

# Fill it and write a second file. A text field takes a string, a check
# box the state name with the slash.
set voll [pdf4tcl::doc::outfile howto-forms-filled.pdf]
set n [pdf4tcl::fillForms $out $voll \
        [dict create f_name "Meier & Co (GmbH)"]]
puts "filled: $n field(s)"

# Read it back -- the value is in the file, escaped as PDF wants it.
set danach [pdf4tcl::getForms $voll]
puts "f_name is now: [dict get $danach f_name value]"

# A name that is not in the form is reported rather than ignored.
if {[catch {pdf4tcl::fillForms $out $voll {no_such_field "x"}} e]} {
    puts "refused: [string range $e 0 60]..."
}

pdf4tcl::doc::done $out
