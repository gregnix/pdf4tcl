#!/usr/bin/env tclsh
source [file join [file dirname [info script]] ../_bootstrap.tcl]
pdf4tcl::doc::init [info script]
set font [pdf4tcl::doc::needFont freesans]
pdf4tcl::loadBaseTrueTypeFont BaseFreeSans $font
pdf4tcl::createFont BaseFreeSans Body iso8859-1

proc onePart {path title} {
    set pdf [::pdf4tcl::new %AUTO% -paper a4 -orient 1 -margin 50]
    $pdf tagged 1 -lang en-GB -ua 1
    $pdf metadata -title $title -author "pdf4tcl"
    $pdf viewerPreferences -displaydoctitle 1
    $pdf startPage
    $pdf setFont 14 Body
    $pdf tagText H1 $title -x 0 -y 24
    $pdf tagBegin P
    $pdf text "Content of $title." -x 0 -y 50
    $pdf tagEnd
    $pdf endPage
    $pdf write -file $path
    $pdf destroy
}

set a [pdf4tcl::doc::outfile howto-catpdf-a.pdf]
set b [pdf4tcl::doc::outfile howto-catpdf-b.pdf]
set out [pdf4tcl::doc::outfile howto-catpdf-merged.pdf]
onePart $a "Part 1"
onePart $b "Part 2"
set ::pdf4tcl::warnings {}
pdf4tcl::catPdf $a $b $out
pdf4tcl::doc::done $out
if {[llength $::pdf4tcl::warnings]} {
    foreach w $::pdf4tcl::warnings { puts "warning: $w" }
}

# ---------------------------------------------------------------------------
# Interactive forms (0.9.4.44)
#
# Before 0.9.4.44 only the first document's /AcroForm survived the merge: the
# second document's widget sat on its page, fully formed, and no reader
# offered it for filling. Now /Fields is the union of both.
# ---------------------------------------------------------------------------
proc formPart {file id} {
    set pdf [pdf4tcl::new %AUTO% -paper a4 -compress 0]
    $pdf startPage
    $pdf setFont 12 Helvetica
    $pdf text "Form $id" -x 60 -y 60
    $pdf addForm text 60 100 200 20 -id $id
    $pdf write -file $file
    $pdf destroy
}

set fa [pdf4tcl::doc::outfile howto-catpdf-form-a.pdf]
set fb [pdf4tcl::doc::outfile howto-catpdf-form-b.pdf]
set fout [pdf4tcl::doc::outfile howto-catpdf-form-merged.pdf]
formPart $fa customer
formPart $fb invoice

set ::pdf4tcl::warnings {}
pdf4tcl::catPdf $fa $fb $fout
pdf4tcl::doc::done $fout

# Beide Felder muessen im Wurzelkatalog stehen -- sonst sieht ein Leser nur
# eines. Nachgelesen statt behauptet:
set doc [::pdf4tcl::cat::ReadPdf $fout]
set rootId [lindex [dict get $doc trailer /Root] 0]
set root [::pdf4tcl::cat::PdfObjToTclDict [dict get $doc $rootId full]]
set namen {}
if {[dict exists $root /AcroForm]} {
    set acroId [lindex [dict get $root /AcroForm] 0]
    set acro [::pdf4tcl::cat::PdfObjToTclDict [dict get $doc $acroId full]]
    foreach {full num} [regexp -all -inline {(\d+)\s+\d+\s+R} \
            [dict get $acro /Fields]] {
        if {[dict exists $doc $num]
                && [regexp {/T\s*\(([^)]*)\)} [dict get $doc $num full] -> n]} {
            lappend namen $n
        }
    }
}
puts "fields in the merged document: [lsort $namen]"

if {[llength $::pdf4tcl::warnings]} {
    foreach w $::pdf4tcl::warnings { puts "warning: $w" }
}
