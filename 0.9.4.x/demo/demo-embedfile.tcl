#!/usr/bin/env tclsh
# demo-embedfile.tcl -- pdf4tcl 0.9.4.14: addEmbeddedFile
#
# Demonstrates embedding files silently in the PDF Catalog NameTree:
#   Page 1 -- basic XML embedding (ZUGFeRD invoice pattern)
#   Page 2 -- multiple files with options (-mimetype, -description, -afrelationship)
#   Page 3 -- coexistence with forms and bookmarks
#
# Usage:
#   tclsh demo-embedfile.tcl ?--out dir?

set outDir [file dirname [file normalize [info script]]]
for {set i 0} {$i < [llength $argv]} {incr i} {
    if {[lindex $argv $i] eq "--out"} {
        set outDir [lindex $argv [incr i]]
    }
}

set scriptDir [file dirname [file normalize [info script]]]
lappend auto_path [file normalize [file join $scriptDir .. ..]]
package require pdf4tcl

set outFile [file join $outDir demo-embedfile.pdf]

# \u2500\u2500 helper: box outline \u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500
proc drawBox {pdf x y w h {label ""}} {
    $pdf setStrokeColor 0.5 0.5 0.5
    $pdf setLineWidth 0.5
    $pdf rectangle $x $y $w $h
    if {$label ne ""} {
        $pdf setFillColor 0.3 0.3 0.3
        $pdf setFont 8 Helvetica
        $pdf text $label -x [expr {$x+4}] -y [expr {$y+$h-10}]
    }
}

proc heading {pdf text y} {
    $pdf setFillColor 0.1 0.1 0.5
    $pdf setFont 14 Helvetica-Bold
    $pdf text $text -x 56 -y $y
    $pdf setFillColor 0 0 0
}

proc body {pdf text y} {
    $pdf setFont 10 Helvetica
    $pdf setFillColor 0 0 0
    $pdf text $text -x 56 -y $y
}

proc mono {pdf text y} {
    $pdf setFont 9 Courier
    $pdf setFillColor 0.1 0.3 0.1
    $pdf text $text -x 72 -y $y
    $pdf setFillColor 0 0 0
}

# \u2500\u2500 sample XML content \u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500
set invoiceXml {<?xml version="1.0" encoding="UTF-8"?>
<rsm:CrossIndustryInvoice
    xmlns:rsm="urn:un:unece:uncefact:data:standard:CrossIndustryInvoice:100">
  <rsm:ExchangedDocument>
    <ram:ID>2026-0042</ram:ID>
    <ram:TypeCode>380</ram:TypeCode>
  </rsm:ExchangedDocument>
</rsm:CrossIndustryInvoice>}

set schemaXsd {<?xml version="1.0" encoding="UTF-8"?>
<xs:schema xmlns:xs="http://www.w3.org/2001/XMLSchema">
  <xs:element name="invoice" type="xs:string"/>
</xs:schema>}

# \u2500\u2500 create PDF \u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500
set pdf [pdf4tcl::new %AUTO% -paper a4 -compress 0]

# \u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500
# Page 1: Grundkonzept
# \u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500
$pdf startPage

heading $pdf "addEmbeddedFile -- Catalog-Einbettung" 780

body $pdf "Dateien werden still im PDF-Catalog-NameTree eingebettet." 748
body $pdf "Kein sichtbares Icon auf der Seite (anders als attachFile)." 733
body $pdf "Typischer Anwendungsfall: ZUGFeRD / Factur-X Rechnungen." 718

# Syntax-Box
drawBox $pdf 56 600 483 100 "API"
mono $pdf {$pdf addEmbeddedFile filename} 680
mono $pdf {    ?-contents    data?        ;# bin\u00E4rinhalt direkt \u00FCbergeben} 665
mono $pdf {    ?-mimetype    type?        ;# z.B. "application/xml"} 650
mono $pdf {    ?-description text?        ;# lesbare Beschreibung} 635
mono $pdf {    ?-afrelationship rel?      ;# Alternative|Data|Source|...} 620

# Einfaches Beispiel
drawBox $pdf 56 490 483 98 "Beispiel: ZUGFeRD-Rechnung"
mono $pdf {set pdf [pdf4tcl::new %AUTO% -paper a4]} 572
mono $pdf {$pdf startPage} 557
mono $pdf {# Text und Layout ...} 542
mono $pdf {$pdf addEmbeddedFile "ZUGFeRD-invoice.xml"} 527
mono $pdf {    -contents $xmlData} 512
mono $pdf {    -mimetype "application/xml"} 497
mono $pdf {    -afrelationship Alternative} 482

# Hinweis PDF/A
$pdf setFillColor 0.6 0.0 0.0
$pdf setFont 9 Helvetica-Bold
$pdf text "Hinweis:" -x 56 -y 455
$pdf setFont 9 Helvetica
$pdf setFillColor 0 0 0
$pdf text "In PDF/A-1b verboten (ISO 19005-1 SS6.1.7). Erlaubt ab PDF/A-2b." -x 120 -y 455

$pdf bookmarkAdd -title "Grundkonzept" -level 0

$pdf endPage

# \u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500
# Page 2: Mehrere Dateien + Optionen
# \u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500
$pdf startPage

heading $pdf "Mehrere Dateien und Optionen" 780

body $pdf "Alle Optionen im \u00DCberblick:" 750

# Optionen-Tabelle
set rows {
    {"-contents data"          "Bin\u00E4rinhalt direkt (kein Dateizugriff)"}
    {"-mimetype type"          "MIME-Typ -> /Subtype im EmbeddedFile-Stream"}
    {"-description text"       "/Desc im Filespec-Dictionary"}
    {"-afrelationship rel"     "/AFRelationship (PDF/A-3: Alternative/Data/...)"}
}
set ty 720
$pdf setFillColor 0.85 0.90 0.98
$pdf rectangle 56 [expr {$ty-12}] 483 [expr {[llength $rows]*20+24}] -filled 1
$pdf setFillColor 0 0 0
$pdf setFont 9 Helvetica-Bold
$pdf text "Option" -x 64 -y $ty
$pdf text "Bedeutung" -x 220 -y $ty
incr ty -18
foreach row $rows {
    $pdf setFont 9 Courier
    $pdf setFillColor 0.1 0.3 0.1
    $pdf text [lindex $row 0] -x 64 -y $ty
    $pdf setFont 9 Helvetica
    $pdf setFillColor 0 0 0
    $pdf text [lindex $row 1] -x 220 -y $ty
    incr ty -18
}

# Zwei-Dateien-Beispiel
drawBox $pdf 56 490 483 160 "Beispiel: Rechnung + Schema"
mono $pdf {# Rechnung (ZUGFeRD-Muster)} 632
mono $pdf {$pdf addEmbeddedFile "factur-x.xml"} 617
mono $pdf {    -contents $invoiceXml} 602
mono $pdf {    -mimetype "application/xml"} 587
mono $pdf {    -description "Factur-X Rechnung 2026-0042"} 572
mono $pdf {    -afrelationship Alternative} 557

mono $pdf {# Begleitendes Schema} 532
mono $pdf {$pdf addEmbeddedFile "schema.xsd"} 517
mono $pdf {    -contents $schemaXsd} 502
mono $pdf {    -mimetype "application/xml"} 487
mono $pdf {    -afrelationship Data} 472

# AFRelationship-Werte
drawBox $pdf 56 380 483 80 "Gueltige -afrelationship Werte (PDF/A-3 SS6.2.7)"
body $pdf "Alternative  -- Ersatzdarstellung des Seiteninhalts" 446
body $pdf "Data         -- Quelldaten (z.B. Rohdaten einer Grafik)" 431
body $pdf "Source       -- Quelldatei (z.B. Original-Tabellenkalkulation)" 416
body $pdf "Supplement   -- Ergaenzungsmaterial" 401
body $pdf "Unspecified  -- Nicht naeher definierte Beziehung" 386

$pdf bookmarkAdd -title "Optionen" -level 0

$pdf endPage

# \u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500
# Page 3: PDF-Struktur + Koexistenz
# \u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500
$pdf startPage

heading $pdf "PDF-Objektstruktur" 780

body $pdf "Drei Objekte je eingebetteter Datei + ein NameTree-Objekt im Catalog:" 750

drawBox $pdf 56 580 483 155 "PDF-Struktur"
mono $pdf {1 0 obj  % Catalog} 720
mono $pdf {  << /Type /Catalog} 705
mono $pdf {     /Pages 2 0 R} 690
mono $pdf {     /Names << /EmbeddedFiles 9 0 R >>   % NameTree} 675
mono $pdf {  >>} 660
mono $pdf {9 0 obj  % NameTree (flach)} 645
mono $pdf {  << /Names [ (factur-x.xml) 10 0 R ] >>} 630
mono $pdf {10 0 obj % FileSpec} 615
mono $pdf {  << /Type /Filespec /F (factur-x.xml) /UF (factur-x.xml)} 600
mono $pdf {     /EF << /F 11 0 R /UF 11 0 R >> /Desc (...) >>} 585

# Koexistenz-Info
drawBox $pdf 56 450 483 115 "Koexistenz mit anderen Features"
body $pdf "addEmbeddedFile ist unabhaengig von:" 538
body $pdf "  - Lesezeichen (bookmarkAdd) -- beides landet im Catalog" 523
body $pdf "  - Formularfeldern (addForm)  -- AcroForm bleibt unberuehrt" 508
body $pdf "  - attachFile -- sichtbare Annotation bleibt separat" 493
body $pdf "  - Verschluesselung (encrypt) -- EmbeddedFile-Streams werden" 478
body $pdf "    wie alle Streams verschluesselt" 463
body $pdf "  - Kompression (-compress 1)  -- zlib-komprimiert wenn sinnvoll" 448

# Abschluss-Hinweis
$pdf setFillColor 0.0 0.4 0.0
$pdf setFont 10 Helvetica-Bold
$pdf text "Demo enthaelt zwei eingebettete Dateien (unsichtbar im Catalog):" -x 56 -y 415
$pdf setFont 9 Helvetica
$pdf setFillColor 0 0 0
$pdf text "factur-x.xml -- ZUGFeRD-Muster-Rechnung" -x 72 -y 400
$pdf text "schema.xsd   -- Begleit-Schema" -x 72 -y 385

$pdf bookmarkAdd -title "PDF-Struktur" -level 0

# Jetzt die tatsaechlichen Einbettungen
$pdf addEmbeddedFile "factur-x.xml" \
    -contents $invoiceXml \
    -mimetype "application/xml" \
    -description "Factur-X Rechnung 2026-0042" \
    -afrelationship Alternative

$pdf addEmbeddedFile "schema.xsd" \
    -contents $schemaXsd \
    -mimetype "application/xml" \
    -description "Begleit-Schema" \
    -afrelationship Data

$pdf endPage

# \u2500\u2500 schreiben \u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500
$pdf write -file $outFile
$pdf destroy

puts "Written: $outFile"
