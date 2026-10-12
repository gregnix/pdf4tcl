#!/usr/bin/env tclsh
source [file join [file dirname [info script]] ../_bootstrap.tcl]
pdf4tcl::doc::init [info script]

# 1. Write an encrypted form
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

# 2. Read it back (0.9.4.71) -- user or owner password
set fields [pdf4tcl::getForms $out -password geheim]
puts "fields: [dict keys $fields]"

# 3. Fill it; the result is encrypted the same way
set filled [pdf4tcl::doc::outfile howto-encrypted-forms-filled.pdf]
pdf4tcl::fillForms $out $filled {f_name "Meier"} -password geheim
puts "f_name: [dict get [pdf4tcl::getForms $filled -password admin] f_name value]"

# 4. Without the password: an error, not an empty result
if {[catch {pdf4tcl::getForms $filled} msg opts]} {
    puts "[dict get $opts -errorcode]: $msg"
}

pdf4tcl::doc::done $filled
