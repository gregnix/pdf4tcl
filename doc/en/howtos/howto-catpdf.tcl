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

# ---------------------------------------------------------------------------
# Naming the merged document (0.9.4.48)
#
# Merging keeps the catalog of the first input, so without saying otherwise
# the result carries the title of part one.
# ---------------------------------------------------------------------------

proc titledDoc {file title text} {
    set p [::pdf4tcl::new %AUTO% -compress 0 -paper a4]
    $p metadata -title $title
    $p startPage
    $p setFont 12 Body
    $p text $text -x 60 -y 60
    $p write -file $file
    $p destroy
}

# Read the title through /Info in the trailer, not by searching the file:
# the /Info of the appended document stays behind unreferenced, and it sits
# BEFORE the valid one.
proc infoTitle {file} {
    set fh [open $file rb]
    set data [read $fh]
    close $fh
    if {![regexp {/Info\s+(\d+)\s+0\s+R} $data -> id]} { return "(none)" }
    if {![regexp "\n$id\\s+0\\s+obj(.*?)endobj" $data -> body]} { return "(none)" }
    if {[regexp {/Title\s*\(([^)]*)\)} $body -> t]} { return $t }
    return "(none)"
}

titledDoc [pdf4tcl::doc::outfile cat-t1.pdf] "Part one" "first"
titledDoc [pdf4tcl::doc::outfile cat-t2.pdf] "Part two" "second"

::pdf4tcl::catPdf \
        [pdf4tcl::doc::outfile cat-t1.pdf] [pdf4tcl::doc::outfile cat-t2.pdf] \
        [pdf4tcl::doc::outfile cat-plain.pdf]
puts "without options: [infoTitle [pdf4tcl::doc::outfile cat-plain.pdf]]"

::pdf4tcl::catPdf -title "Complete file" -author "" \
        [pdf4tcl::doc::outfile cat-t1.pdf] [pdf4tcl::doc::outfile cat-t2.pdf] \
        [pdf4tcl::doc::outfile cat-named.pdf]
puts "with -title:     [infoTitle [pdf4tcl::doc::outfile cat-named.pdf]]"

# ---------------------------------------------------------------------------
# Cross-reference streams (0.9.4.49)
#
# PDF/A-2 and -3 require a cross-reference stream, PDF/A-1 forbids it.
# Both forms are read since 0.9.4.49; before, nothing from 2b upwards
# could be merged.
# ---------------------------------------------------------------------------

proc pdfaDoc {file level} {
    set p [::pdf4tcl::new %AUTO% -paper a4 -pdfa $level]
    $p startPage
    # Body, nicht Helvetica: PDF/A verlangt jedes Fontprogramm
    # eingebettet, und die vierzehn Standardschriften haben keins. Sonst
    # entstehen hier Dateien, die einen Anspruch tragen und ihn nicht
    # halten -- geprueft mit tools/check-conformance.py.
    $p setFont 12 Body
    $p text "PDF/A-$level" -x 60 -y 60
    $p write -file $file
    $p destroy
}

foreach level {1b 2b} {
    pdfaDoc [pdf4tcl::doc::outfile cat-a-$level.pdf] $level
    pdfaDoc [pdf4tcl::doc::outfile cat-b-$level.pdf] $level
    if {[catch {
        ::pdf4tcl::catPdf \
                [pdf4tcl::doc::outfile cat-a-$level.pdf] \
                [pdf4tcl::doc::outfile cat-b-$level.pdf] \
                [pdf4tcl::doc::outfile cat-out-$level.pdf]
    } err]} {
        puts "PDF/A-$level: refused -- [string range $err 0 60]..."
    } else {
        puts "PDF/A-$level: merged"
    }
}

# ---------------------------------------------------------------------------
# Objects inside containers, and orphans (0.9.4.50)
# ---------------------------------------------------------------------------

# qpdf packs objects into /ObjStm containers by default. Until 0.9.4.50
# such a file was refused with a count; now it is unpacked.
#
# --newline-before-endstream because without it qpdf writes streams with
# no EOL before "endstream", which breaks ISO 19005-2 clause 6.1.7.1 --
# in the INPUT, before pdf4tcl ever sees it.
if {![catch {exec qpdf --version}]} {
    set eins [pdf4tcl::doc::outfile howto-catpdf-a.pdf]
    set container [pdf4tcl::doc::outfile howto-catpdf-objstm.pdf]
    exec qpdf --object-streams=generate --newline-before-endstream \
            $eins $container
    set zusammen [pdf4tcl::doc::outfile howto-catpdf-fromobjstm.pdf]
    pdf4tcl::catPdf -title "From a container" $container $eins $zusammen
    puts "objstm merged: [file size $zusammen] bytes"

    # Genau ein /Title -- das der angehaengten Datei bleibt nicht liegen.
    set fh [open $zusammen rb]
    set daten [read $fh]
    close $fh
    puts "titles in the file: [regexp -all {/Title} $daten]"
} else {
    puts "qpdf not installed -- object stream part skipped"
}
