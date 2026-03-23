#!/usr/bin/env tclsh
# demo-permissions.tcl -- demonstrate -permissions option (0.9.4.20)
#
# IMPORTANT: -permissions alone does NOT protect the file.
# Without -userpassword, any viewer can open the PDF.
# -permissions is only a hint to conforming viewers about what
# the user may do AFTER opening.
#
# The two-password model:
#   -userpassword  -- controls who can OPEN the file
#   -ownerpassword -- owner can do everything regardless of /P
#   -permissions   -- controls rights of the user after opening
#
# All PDFs here use: -userpassword "user" -ownerpassword "admin"
# Open with "user" -> /P restrictions apply
# Open with "admin" -> all rights, /P ignored
#
# Verify: qpdf --password=user --show-encryption <file>
#
# Usage: tclsh demo-permissions.tcl [outputdir]

set demodir  [file dirname [file normalize [info script]]]
set reporoot [file normalize [file join $demodir ../..]]
set auto_path [linsert $auto_path 0 $reporoot]

package require pdf4tcl

set outdir [expr {$argc > 0 ? [lindex $argv 0] : [file join $demodir out]}]
file mkdir $outdir

# ---------------------------------------------------------------------------
# Helper: one page showing permission info
# ---------------------------------------------------------------------------

proc makePermPdf {outfile title pvalue desc flags} {
    set pdf [pdf4tcl::new %AUTO% -paper a4 -orient 1 -compress 1 \
        -userpassword  "user" \
        -ownerpassword "admin" \
        -permissions   $pvalue]

    $pdf startPage
    $pdf setFont 14 Helvetica-Bold
    $pdf text $title -x 50 -y 40

    $pdf setFont 10 Helvetica-Bold
    $pdf text "Permission value: $pvalue" -x 50 -y 68
    $pdf setFont 9 Helvetica
    $pdf text $desc -x 50 -y 84

    set y 110
    $pdf setFont 10 Helvetica-Bold
    $pdf text "Permissions:" -x 50 -y $y
    incr y 18

    $pdf setFont 9 Helvetica
    foreach {flag allowed} {
        print          ""
        hq-print       ""
        modify         ""
        copy           ""
        annotate       ""
        fill-forms     ""
        accessibility  ""
        assemble       ""
    } {
        set mark [expr {$flag in $flags ? "YES" : "no"}]
        set color [expr {$flag in $flags ? {0 0.5 0} : {0.6 0 0}}]
        lassign $color r g b
        $pdf setFillColor $r $g $b
        $pdf text "  $flag" -x 50 -y $y
        $pdf text $mark -x 200 -y $y
        $pdf setFillColor 0 0 0
        incr y 16
    }

    incr y 10
    $pdf setFont 8 Helvetica
    $pdf text "User password: user  |  Owner password: admin" -x 50 -y $y
    incr y 14
    $pdf text "Verify: qpdf --password=user --show-encryption [file tail $outfile]" \
        -x 50 -y $y

    $pdf endPage
    $pdf write -file $outfile
    $pdf destroy
    puts "Written: $outfile"
}

# ---------------------------------------------------------------------------
# Presets
# ---------------------------------------------------------------------------

makePermPdf \
    [file join $outdir demo-perm-all.pdf] \
    "Permissions: all (default)" \
    all \
    "All rights allowed. /P = -196  (0xFFFFFF3C)" \
    {print hq-print modify copy annotate fill-forms accessibility assemble}

makePermPdf \
    [file join $outdir demo-perm-none.pdf] \
    "Permissions: none" \
    none \
    "No rights allowed. /P = -4096 (0xFFFFF000)" \
    {}

makePermPdf \
    [file join $outdir demo-perm-readonly.pdf] \
    "Permissions: readonly (print only)" \
    readonly \
    "Print only. /P = -4092 (0xFFFFF004)" \
    {print}

# ---------------------------------------------------------------------------
# Symbolic flag combinations
# ---------------------------------------------------------------------------

makePermPdf \
    [file join $outdir demo-perm-print-copy.pdf] \
    "Permissions: {print copy}" \
    {print copy} \
    "Print + Copy allowed." \
    {print copy}

makePermPdf \
    [file join $outdir demo-perm-forms.pdf] \
    "Permissions: {print fill-forms annotate}" \
    {print fill-forms annotate} \
    "Print + fill forms + annotate." \
    {print fill-forms annotate}

makePermPdf \
    [file join $outdir demo-perm-fullexcept-modify.pdf] \
    "Permissions: all except modify" \
    {print hq-print copy annotate fill-forms accessibility assemble} \
    "All rights except modify content." \
    {print hq-print copy annotate fill-forms accessibility assemble}

# ---------------------------------------------------------------------------
# Direct integer
# ---------------------------------------------------------------------------

makePermPdf \
    [file join $outdir demo-perm-integer.pdf] \
    "Permissions: -196 (integer)" \
    -196 \
    "Direct /P integer value -196 = all rights." \
    {print hq-print modify copy annotate fill-forms accessibility assemble}

puts "\nAll permission demos written to: $outdir"
puts "Verify with: qpdf --password=user --show-encryption <file>"
