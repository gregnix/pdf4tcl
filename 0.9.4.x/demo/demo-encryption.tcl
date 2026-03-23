#!/usr/bin/env tclsh
# demo-encryption.tcl -- demonstrate AES-128 PDF encryption
#
# Creates four encrypted PDFs:
#   demo-encryption-user.pdf        -- user password only
#   demo-encryption-owner.pdf       -- owner password only
#   demo-encryption-both.pdf        -- user + owner password
#   demo-encryption-permissions.pdf -- restricted permissions
#
# Usage: tclsh demo-encryption.tcl [outputdir]

set demodir  [file dirname [file normalize [info script]]]
set reporoot [file normalize [file join $demodir ../..]]
set auto_path [linsert $auto_path 0 $reporoot]

package require pdf4tcl

set outdir [expr {$argc > 0 ? [lindex $argv 0] : $demodir}]
file mkdir $outdir

proc makePage {pdf title info} {
    $pdf startPage
    $pdf setFont 16 Helvetica-Bold
    $pdf text $title -x 50 -y 780

    $pdf setFont 11 Helvetica
    set y 750
    foreach line $info {
        $pdf text $line -x 50 -y $y
        incr y -18
    }

    $pdf setFont 10 Helvetica
    $pdf setFont 9 Helvetica
    $pdf text "pdf4tcl AES-128 Encryption Demo (V=4 R=4)" -x 50 -y 100
    $pdf endPage
}

# ---------------------------------------------------------------------------
# 1) User-Passwort
# ---------------------------------------------------------------------------

set outfile [file join $outdir demo-encryption-user.pdf]

set pdf [::pdf4tcl::new %AUTO% \
    -paper a4 -orient false -compress 1 \
    -userpassword "geheim"]

makePage $pdf "AES-128: User Password" {
    "This PDF is protected with a user password."
    ""
    "User password:  geheim"
    "Owner password: (none)"
    ""
    "The document cannot be opened without the password."
    ""
    "Encryption: AES-128 (V=4, R=4)"
    "Permissions: all allowed"
}

$pdf write -file $outfile
$pdf destroy
puts "Written: $outfile"

# ---------------------------------------------------------------------------
# 2) Owner-Passwort + eingeschraenkte Berechtigungen
# ---------------------------------------------------------------------------

set outfile [file join $outdir demo-encryption-owner.pdf]

set pdf [::pdf4tcl::new %AUTO% \
    -paper a4 -orient false -compress 1 \
    -ownerpassword "admin"]

makePage $pdf "AES-128: Owner Password" {
    "This PDF has an owner password."
    ""
    "User password:  (none -- opens without password)"
    "Owner password: admin"
    ""
    "Encryption: AES-128 (V=4, R=4)"
}

$pdf write -file $outfile
$pdf destroy
puts "Written: $outfile"

# ---------------------------------------------------------------------------
# 3) User + Owner Passwort
# ---------------------------------------------------------------------------

set outfile [file join $outdir demo-encryption-both.pdf]

set pdf [::pdf4tcl::new %AUTO% \
    -paper a4 -orient false -compress 1 \
    -userpassword  "user123" \
    -ownerpassword "admin456"]

makePage $pdf "AES-128: User + Owner Password" {
    "This PDF requires a password to open."
    ""
    "User password:  user123"
    "Owner password: admin456"
    ""
    "Encryption: AES-128 (V=4, R=4)"
}

$pdf write -file $outfile
$pdf destroy
puts "Written: $outfile"


# ---------------------------------------------------------------------------
# 4) Eingeschraenkte Berechtigungen
# ---------------------------------------------------------------------------

set outfile [file join $outdir demo-encryption-permissions.pdf]

set pdf [::pdf4tcl::new %AUTO% \
    -paper a4 -orient 1 -compress 1 \
    -userpassword  "readonly" \
    -ownerpassword "admin" \
    -permissions   {print}]

$pdf startPage
$pdf setFont 16 Helvetica-Bold
$pdf text "AES-128: Restricted Permissions" -x 50 -y 60

$pdf setFont 11 Helvetica
set y 100
foreach line {
    "This PDF has restricted permissions."
    ""
    "User password:  readonly"
    "Owner password: admin"
    ""
    "Permissions: print only"
    "  print          allowed"
    "  copy           NOT allowed"
    "  modify         NOT allowed"
    "  fill-forms     NOT allowed"
    "  annotate       NOT allowed"
    ""
    "Encryption: AES-128 (V=4, R=4)"
    "/P value: -4092"
    ""
    "Other preset examples:"
    "  -permissions all       -> -196  (default)"
    "  -permissions none      -> -4096 (no rights)"
    "  -permissions readonly  -> -4092 (print only)"
    "  -permissions {print copy fill-forms}"
    "  -permissions -196      (integer direct)"
} {
    $pdf text $line -x 50 -y $y
    incr y 18
}

$pdf endPage
$pdf write -file $outfile
$pdf destroy
puts "Written: $outfile"

puts "\nAll encryption demos written to: $outdir"
