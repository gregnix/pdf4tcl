#!/usr/bin/env tclsh
# How-to: form XObjects, and tagging inside them.
#
# An XObject is drawn once and placed many times -- a letterhead, a stamp,
# a logo. Shows what that saves, and where the structure tree runs into a
# limit that is not a bug but a property of the format.

source [file join [file dirname [info script]] ../_bootstrap.tcl]
pdf4tcl::doc::init [info script]

set font [pdf4tcl::doc::needFont freesans]
pdf4tcl::loadBaseTrueTypeFont BaseXo $font
pdf4tcl::createFontSpecCID BaseXo Body

# ---------------------------------------------------------------------------
# 1. What it saves
#
# The same drawing on three pages: once as an XObject, once drawn again
# each time. Compare the file sizes.
# ---------------------------------------------------------------------------

# Fuer den Groessenvergleich eine Standardschrift: eine eingebettete
# waere 800 KB und wuerde den Unterschied vollstaendig ueberdecken.
proc briefkopf {pdf} {
    $pdf setFillColor 0.2 0.3 0.6
    $pdf rectangle 0 0 495 30 -filled 1
    $pdf setFillColor 1 1 1
    $pdf setFont 14 Helvetica-Bold
    $pdf text "ACME Corporation" -x 10 -y 20
    $pdf setFillColor 0 0 0
    $pdf setFont 8 Helvetica
    $pdf text "Beispielweg 1 - 12345 Musterstadt" -x 10 -y 44
    # Genug Inhalt, dass sich das Wiederholen bemerkbar macht.
    foreach y {56 66 76 86} {
        $pdf line 0 $y 495 $y
    }
}

# Mit XObject
set p [::pdf4tcl::new %AUTO% -paper a4 -margin 40 -orient 1]
set kopf [$p startXObject -paper a4 -margin 40 -orient 1]
briefkopf $p
$p endXObject
foreach seite {1 2 3 4 5 6 7 8 9 10 11 12} {
    $p startPage
    $p putImage $kopf 0 0
    $p setFont 11 Helvetica
    $p text "Page $seite" -x 0 -y 100
}
$p write -file [pdf4tcl::doc::outfile howto-xobject-shared.pdf]
$p destroy

# Ohne -- dieselbe Zeichnung dreimal im Inhalt
set q [::pdf4tcl::new %AUTO% -paper a4 -margin 40 -orient 1]
foreach seite {1 2 3 4 5 6 7 8 9 10 11 12} {
    $q startPage
    briefkopf $q
    $q setFont 11 Helvetica
    $q text "Page $seite" -x 0 -y 100
}
$q write -file [pdf4tcl::doc::outfile howto-xobject-repeated.pdf]
$q destroy

set mit  [file size [pdf4tcl::doc::outfile howto-xobject-shared.pdf]]
set ohne [file size [pdf4tcl::doc::outfile howto-xobject-repeated.pdf]]
puts [format "shared:   %6d bytes" $mit]
puts [format "repeated: %6d bytes" $ohne]
puts [format "saved:    %6d bytes over 12 pages" [expr {$ohne - $mit}]]
# Bei DREI Seiten ist das geteilte Dokument groesser: das XObject kostet
# ein eigenes Objekt mit Woerterbuch und Laengenangabe, und das holt sich
# erst ab etwa zehn Wiederholungen zurueck. Gemessen: 3 Seiten 4059 gegen
# 3994, 20 Seiten 10469 gegen 12428.

# ---------------------------------------------------------------------------
# 2. Tagging inside an XObject
#
# Since 0.9.4.46 the content of an XObject can carry structure. The
# XObject gets its own /StructParents, and every /MCR names the stream in
# /Stm and the page in /Pg.
# ---------------------------------------------------------------------------

set pdf [::pdf4tcl::new %AUTO% -paper a4 -margin 40 -orient 1]
$pdf tagged 1 -lang en-GB -ua 1
$pdf metadata -title "XObject with structure"
$pdf viewerPreferences -displaydoctitle 1

# The frame carries no meaning -- artifact, and it may be placed as often
# as you like.
set rahmen [$pdf startXObject -paper a4 -margin 40 -orient 1]
$pdf tagArtifact
$pdf setStrokeColor 0.7 0.7 0.7
$pdf rectangle 0 0 495 700
$pdf tagArtifactEnd
$pdf endXObject

$pdf startPage
# Auch ein Artefakt darf in einem UA-Dokument nur einmal platziert
# werden: veraPDF zaehlt die Wiederholung, gleich was der Inhalt ist.
$pdf putImage $rahmen 0 0

$pdf setFont 14 Body
$pdf tagText H1 "Content on the page" -x 10 -y 40
$pdf setFont 11 Body
$pdf tagText P "The frame around this is an artifact." -x 10 -y 80

# ---------------------------------------------------------------------------
# 3. Where the limit is
#
# Structure inside an XObject is allowed -- but only if the XObject is
# placed EXACTLY ONCE. The structure tree knows one occurrence of each
# element; place it twice and there is one tree and two appearances, and
# no way to say which is meant.
#
# pdf4tcl does not refuse it. It warns at write time, because the file is
# valid PDF -- just not PDF/UA (veraPDF rule 7.20-2).
# ---------------------------------------------------------------------------

# Der Kasten ist so gross wie sein Inhalt, nicht so gross wie die Seite.
#
# Vorher stand hier "-paper a4": ein XObject in Seitengroesse, mit
# putImage bei y=40 gesetzt. Es lag damit ueber fast dem ganzen Blatt,
# und sein Absatz landete auf dem Absatz der Seite. layout-check meldete
# zehn Ueberlappungen -- zu Recht, im PDF stand der Text uebereinander.
set gezaehlt [$pdf startXObject -paper {300p 30p} -margin 0 -orient 1]
$pdf tagBegin P
$pdf setFont 11 Body
$pdf text "This paragraph lives inside an XObject." -x 2 -y 15
$pdf tagEnd
$pdf endXObject

$pdf startPage
$pdf putImage $gezaehlt 50 60     ;# genau EINMAL -- mehr waere nicht UA
$pdf setFont 11 Body
$pdf tagText P "The paragraph above came from an XObject." -x 10 -y 120

set out [pdf4tcl::doc::outfile howto-xobject.pdf]
$pdf write -file $out
if {[llength $::pdf4tcl::warnings]} {
    foreach w $::pdf4tcl::warnings { puts "warning: $w" }
}
pdf4tcl::doc::done $out
$pdf destroy
