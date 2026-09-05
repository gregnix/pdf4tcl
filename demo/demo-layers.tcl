#!/usr/bin/env tclsh
# demo-layers.tcl -- demonstrate OCG/Layer support (pdf4tcl 0.9.4.21)
#
# Three practical use cases on three pages:
#   Page 1 -- Debug grid (hidden) + content
#   Page 2 -- Letterhead variants (with/without header)
#   Page 3 -- Layer overview table + PDF structure
#   Page 4 -- Screen only: a layer that is visible but not printed
#
# Usage: tclsh demo-layers.tcl [outputdir]

# ---------------------------------------------------------------------------
# Wurzel suchen, nicht zaehlen.
#
# Zwei Ebenen hoch stimmte, solange die Demos unter demo lagen.
# Nach dem Flachlegen des fork-Verzeichnisses zeigte es aus dem Repo
# hinaus. Sichtbar wurde das nur in den Demos, die daraus einen Dateipfad
# bauen (demo-tagged brach ab); die uebrigen legten still ein falsches
# Verzeichnis in auto_path und pruefen dann das pdf4tcl, das auf dem
# Rechner zufaellig installiert ist -- gruen, und ueber die falsche
# Fassung.
#
# Markierung ist pkgIndex.tcl neben src/; beides gibt es nur in der Wurzel.
# ---------------------------------------------------------------------------
proc pdf4tclRepoRoot {start} {
    set dir [file normalize $start]
    for {set i 0} {$i < 8} {incr i} {
        if {[file exists [file join $dir pkgIndex.tcl]]
                && [file isdirectory [file join $dir src]]} { return $dir }
        set parent [file dirname $dir]
        if {$parent eq $dir} break
        set dir $parent
    }
    return -code error "pdf4tcl-Wurzel nicht gefunden ueber $start"
}
set demodir  [file dirname [file normalize [info script]]]
set reporoot [pdf4tclRepoRoot $demodir]
set auto_path [linsert $auto_path 0 $reporoot]

package require pdf4tcl

set outdir [expr {$argc > 0 ? [lindex $argv 0] : [file join $demodir out]}]
file mkdir $outdir
set outfile [file join $outdir demo-layers.pdf]

# ---------------------------------------------------------------------------
# Helpers  (orient 1: y=0 oben, y wächst nach unten)
# ---------------------------------------------------------------------------

proc heading {pdf text y} {
    $pdf setFillColor 0.10 0.25 0.50
    $pdf rectangle 40 $y 515 22 -filled 1
    $pdf setFillColor 1 1 1
    $pdf setFont 11 Helvetica-Bold
    $pdf text $text -x 46 -y [expr {$y + 15}]
    $pdf setFillColor 0 0 0
    return [expr {$y + 30}]
}

proc body {pdf text y} {
    $pdf setFont 10 Helvetica
    $pdf setFillColor 0 0 0
    $pdf text $text -x 50 -y $y
    return [expr {$y + 15}]
}

proc codebox {pdf lines y} {
    set h [expr {[llength $lines] * 12 + 12}]
    $pdf setFillColor 0.95 0.95 0.95
    $pdf rectangle 50 $y 495 $h -filled 1
    $pdf setFillColor 0.25 0.25 0.25
    $pdf setFont 8 Helvetica
    set cy [expr {$y + 10}]
    foreach line $lines {
        $pdf text $line -x 56 -y $cy
        incr cy 12
    }
    $pdf setFillColor 0 0 0
    return [expr {$y + $h + 8}]
}

# ---------------------------------------------------------------------------
# Create PDF
# ---------------------------------------------------------------------------

set pdf [pdf4tcl::new %AUTO% -paper a4 -orient 1 -compress 0]

# Define layers (shared across all pages)
set lGrid    [$pdf addLayer "Debug-Raster"   -visible 0]
set lHeader  [$pdf addLayer "Briefkopf"      -visible 1]
set lContent [$pdf addLayer "Inhalt"         -visible 1]
set lWmark   [$pdf addLayer "Wasserzeichen"  -visible 0]
# Sichtbar, aber nicht gedruckt (0.9.4.63). Fuer den Fall, dass ein
# Vordruck schon auf dem Papier liegt und die Datei nur die Eintragungen
# beisteuern soll.
set lVordruck [$pdf addLayer "Vordruck (nur Ansicht)" -print 0]

# ---------------------------------------------------------------------------
# Page 1 -- Debug grid + content
# ---------------------------------------------------------------------------
$pdf startPage

# Title (outside any layer)
$pdf setFont 14 Helvetica-Bold
$pdf text "pdf4tcl 0.9.4.21 -- Layer / OCG Demo" -x 40 -y 30
$pdf setFont 9 Helvetica
$pdf setFillColor 0.4 0.4 0.4
$pdf text "Seite 1: Debug-Raster (versteckt) + Inhalt-Layer" -x 40 -y 46
$pdf setFillColor 0 0 0

# === Debug grid layer (hidden by default) ===
$pdf beginLayer $lGrid
$pdf setStrokeColor 0.85 0.85 0.85
$pdf setLineWidth 0.25
for {set x 0} {$x <= 595} {incr x 50} { $pdf line $x 0 $x 842 }
for {set y 0} {$y <= 842} {incr y 50} { $pdf line 0 $y 595 $y }
$pdf setFont 6 Helvetica
$pdf setFillColor 0.7 0.7 0.7
for {set x 50} {$x <= 595} {incr x 50} { $pdf text $x -x $x -y 8 }
for {set y 50} {$y <= 842} {incr y 50} { $pdf text $y -x 2 -y $y }
$pdf setFillColor 0 0 0
$pdf setStrokeColor 0 0 0
$pdf setLineWidth 0.5
$pdf endLayer

# === Content layer ===
$pdf beginLayer $lContent
set y 60
set y [heading $pdf "1. Debug-Raster (Layer: Debug-Raster)" $y]
set y [body $pdf "Der Debug-Raster-Layer ist standardmaessig UNSICHTBAR (-visible 0)." $y]
set y [body $pdf "Im PDF-Viewer (z.B. Acrobat): Ansicht > Layer > einschalten." $y]
set y [body $pdf "Typischer Einsatz: Koordinatenraster beim Entwickeln anschalten," $y]
set y [body $pdf "im fertigen Druck ausschalten -- ohne den Code zu aendern." $y]
incr y 10

set y [heading $pdf "2. Layer-API" $y]
set y [codebox $pdf {
    {set lGrid [$pdf addLayer "Debug-Raster" -visible 0]}
    {set lKopf [$pdf addLayer "Briefkopf"   -visible 1]}
    {}
    {$pdf beginLayer $lGrid}
    {  ... Zeichenbefehle (nur im Layer sichtbar) ...}
    {$pdf endLayer}
} $y]
incr y 5

set y [heading $pdf "3. Layer in diesem Dokument" $y]
incr y 5

foreach {name color std} {
    "Debug-Raster"  {0.5 0.5 0.5}  "versteckt (-visible 0)"
    "Briefkopf"     {0.2 0.5 0.8}  "sichtbar  (-visible 1)"
    "Inhalt"        {0.1 0.6 0.2}  "sichtbar  (-visible 1)"
    "Wasserzeichen" {0.7 0.3 0.1}  "versteckt (-visible 0)"
} {
    lassign $color r g b
    $pdf setFillColor $r $g $b
    $pdf rectangle 50 $y 130 16 -filled 1
    $pdf setFillColor 1 1 1
    $pdf setFont 9 Helvetica-Bold
    $pdf text $name -x 54 -y [expr {$y + 11}]
    $pdf setFillColor 0 0 0
    $pdf setFont 9 Helvetica
    $pdf text $std -x 188 -y [expr {$y + 11}]
    incr y 22
}
$pdf endLayer

$pdf endPage

# ---------------------------------------------------------------------------
# Page 2 -- Letterhead variants
# ---------------------------------------------------------------------------
$pdf startPage

# === Briefkopf-Layer (oben auf der Seite) ===
$pdf beginLayer $lHeader
$pdf setFillColor 0.10 0.25 0.50
$pdf rectangle 0 0 595 45 -filled 1
$pdf setFillColor 1 1 1
$pdf setFont 16 Helvetica-Bold
$pdf text "Musterfirma GmbH" -x 40 -y 28
$pdf setFont 9 Helvetica
$pdf text "Musterstrasse 1  |  12345 Musterstadt  |  info@musterfirma.de" -x 40 -y 40
$pdf setFillColor 0 0 0
$pdf setStrokeColor 0.10 0.25 0.50
$pdf setLineWidth 1.5
$pdf line 40 47 555 47
$pdf setLineWidth 0.5
$pdf setStrokeColor 0 0 0
$pdf endLayer

# === Wasserzeichen-Layer (versteckt, diagonal) ===
$pdf beginLayer $lWmark
$pdf setFillColor 0.88 0.88 0.88
$pdf gsave
$pdf translate 150 [expr {460 + 80}]
$pdf rotate -42
$pdf rectangle 0 0 295 80 -filled 1
$pdf grestore
$pdf setFillColor 0.60 0.60 0.60
$pdf setFont 52 Helvetica-Bold
$pdf text "ENTWURF" -x 115 -y 470
$pdf setFillColor 0 0 0
$pdf endLayer

# === Inhalt-Layer ===
$pdf beginLayer $lContent
set y 62
set y [heading $pdf "Seite 2: Briefbogen mit Layer-Varianten" $y]
set y [body $pdf "Der Briefkopf-Layer ist standardmaessig SICHTBAR." $y]
set y [body $pdf "Fuer vorgedrucktes Papier: Layer 'Briefkopf' im Viewer ausschalten." $y]
set y [body $pdf "Der Wasserzeichen-Layer ist standardmaessig UNSICHTBAR." $y]
set y [body $pdf "Fuer Entwurfs-Ausdruck: Layer 'Wasserzeichen' einschalten." $y]
incr y 10
set y [heading $pdf "Typischer Workflow" $y]
set y [body $pdf "1. Entwickeln:  alle Layer sichtbar (Debug-Raster an)" $y]
set y [body $pdf "2. Entwurf:     Wasserzeichen-Layer einschalten" $y]
set y [body $pdf "3. Blanko:      Briefkopf-Layer ausschalten (vorgedrucktes Papier)" $y]
set y [body $pdf "4. Archiv/Druck: Standard (Briefkopf an, Rest aus)" $y]
$pdf endLayer

$pdf endPage

# ---------------------------------------------------------------------------
# Page 3 -- Overview + PDF structure
# ---------------------------------------------------------------------------
$pdf startPage

$pdf beginLayer $lContent

$pdf setFont 14 Helvetica-Bold
$pdf text "pdf4tcl 0.9.4.21 -- Layer / OCG Demo" -x 40 -y 30
$pdf setFont 9 Helvetica
$pdf setFillColor 0.4 0.4 0.4
$pdf text "Seite 3: Uebersicht und Implementierungsdetails" -x 40 -y 46
$pdf setFillColor 0 0 0

set y 60
set y [heading $pdf "OCG-Struktur im PDF (ISO 32000 SS8.11)" $y]
set y [body $pdf "Jeder Layer erzeugt ein OCG-Objekt im Catalog:" $y]
set y [codebox $pdf {
    {1 0 obj  << /Type /Catalog}
    {            /OCProperties << /OCGs [4 0 R 5 0 R 6 0 R 7 0 R]}
    {                             /D << /ON [5 0 R 6 0 R]}
    {                                   /OFF [4 0 R 7 0 R] >> >> >>}
    {4 0 obj  << /Type /OCG  /Name (Debug-Raster) >> endobj}
    {5 0 obj  << /Type /OCG  /Name (Briefkopf)    >> endobj}
} $y]

set y [heading $pdf "Content-Stream: BDC/EMC Klammerung" $y]
set y [codebox $pdf {
    {/OC /Lyr4 BDC        ;# Layer-Block beginnen (Lyr4 = OID 4)}
    {  $pdf line 0 0 100 100  ;# Grafik-Befehle}
    {EMC                  ;# Layer-Block beenden}
    {3 0 obj  << /Properties << /Lyr4  4 0 R >> >>  ;# Resources}
} $y]

set y [heading $pdf "Layer in diesem Dokument" $y]
incr y 4

# Tabellenkopf
$pdf setFillColor 0.20 0.40 0.70
$pdf rectangle 50 $y 495 18 -filled 1
$pdf setFillColor 1 1 1
$pdf setFont 9 Helvetica-Bold
$pdf text "Layer-Name"   -x 56  -y [expr {$y + 12}]
$pdf text "Standard"     -x 220 -y [expr {$y + 12}]
$pdf text "Verwendung"   -x 300 -y [expr {$y + 12}]
$pdf setFillColor 0 0 0
incr y 18

foreach {name std usage alt} {
    "Debug-Raster"   "versteckt"  "Koordinatengitter zum Entwickeln"  0
    "Briefkopf"      "sichtbar"   "Logo, Adresse, Trennlinie"         1
    "Inhalt"         "sichtbar"   "Laufender Text und Grafik"         0
    "Wasserzeichen"  "versteckt"  "ENTWURF-Stempel fuer Proofs"       1
    "Vordruck"       "nur Schirm" "-print 0: sichtbar, nicht gedruckt" 0
} {
    if {$alt} {
        $pdf setFillColor 0.94 0.94 0.94
        $pdf rectangle 50 $y 495 16 -filled 1
        $pdf setFillColor 0 0 0
    }
    $pdf setFont 9 Helvetica
    $pdf text $name -x 56  -y [expr {$y + 11}]
    if {$std eq "versteckt"} { $pdf setFillColor 0.7 0.3 0.1 } \
    else                     { $pdf setFillColor 0.1 0.6 0.2 }
    $pdf text $std  -x 220 -y [expr {$y + 11}]
    $pdf setFillColor 0 0 0
    $pdf text $usage -x 300 -y [expr {$y + 11}]
    incr y 16
}

$pdf endLayer
$pdf endPage

# ---------------------------------------------------------------------------
# Page 4 -- sichtbar, aber nicht gedruckt
# ---------------------------------------------------------------------------

$pdf startPage
set y [heading $pdf "Seite 4 -- Ebene, die nicht gedruckt wird" 40]
set y [body $pdf "Der Vordruck liegt schon im Drucker. Auf dem Bildschirm soll er" $y]
set y [body $pdf "zu sehen sein, damit man erkennt, wo die Kaesten liegen -- auf dem" $y]
set y [body $pdf "Papier darf er nicht noch einmal erscheinen." $y]
incr y 6
set y [codebox $pdf {
    {set l [$pdf addLayer "Vordruck (nur Ansicht)" -print 0]}
    {$pdf beginLayer $l}
    {  $pdf putImage $scan 0 0 -width 210 -height 297}
    {$pdf endLayer}
} $y]

set y [body $pdf "Das OCG traegt dann /Usage << /Print << /PrintState /OFF >> >>," $y]
set y [body $pdf "und /AS steht in der Standardkonfiguration -- ohne /AS wendet" $y]
set y [body $pdf "kein Betrachter /Usage an (ISO 32000-1 8.11.4.4)." $y]
incr y 10

# --- der Vordruck: gezeichnet, aber nur fuer den Bildschirm ---
$pdf beginLayer $lVordruck
$pdf setStrokeColor 0.55 0.65 0.80
$pdf setLineWidth 0.8
$pdf rectangle 50 [expr {$y + 10}] 495 120
foreach {lx ly lw lh beschriftung} {
    50  10  247 40 "1 Absender"
    297 10  248 40 "16 Frachtfuehrer"
    50  50  247 40 "2 Empfaenger"
    297 50  248 40 "17 Nachfolgende"
    50  90  495 40 "13 Anweisungen"
} {
    $pdf rectangle [expr {$lx}] [expr {$y + 10 + $ly}] $lw $lh
    $pdf setFillColor 0.45 0.55 0.70
    $pdf setFont 7 Helvetica
    $pdf text $beschriftung -x [expr {$lx + 4}] -y [expr {$y + 10 + $ly + 9}]
    $pdf setFillColor 0 0 0
}
$pdf setStrokeColor 0 0 0
$pdf endLayer

# --- die Eintragungen: die kommen aufs Papier ---
$pdf setFont 10 Helvetica
# Die Eintragungen sitzen UNTER der Kastenbeschriftung, nicht darauf --
# derselbe Abstand, den ein echter Vordruck verlangt.
$pdf text "Spedition Muster GmbH"   -x 56  -y [expr {$y + 46}]
$pdf text "Transporte Mustermann"   -x 303 -y [expr {$y + 46}]
$pdf text "Warenhaus Beispiel N.V." -x 56  -y [expr {$y + 86}]
$pdf text "Anlieferung nur nach Avis" -x 56 -y [expr {$y + 126}]

set y [expr {$y + 145}]
set y [body $pdf "Blau: die Ebene -- am Bildschirm da, beim Druck aus einem" $y]
set y [body $pdf "Betrachter weg. Schwarz: die Eintragungen, die aufs Papier gehoeren." $y]
incr y 6
set y [body $pdf "Grenze: Usage-Application-Dictionaries duerfen laut 8.11.4.4 NUR" $y]
set y [body $pdf "von interaktiven Betrachtern benutzt werden, nicht von Anwendungen," $y]
set y [body $pdf "die PDF als Endform verarbeiten. Aus Acrobat gedruckt: Ebene weg." $y]
set y [body $pdf "Datei an einen RIP gegeben: Ebene kommt mit -- und das ist" $y]
set y [body $pdf "normgerecht. Wo es nicht schiefgehen darf, gehoert das Bild" $y]
set y [body $pdf "gar nicht erst in die Datei." $y]

$pdf endPage

$pdf write -file $outfile
$pdf destroy
puts "Written: $outfile ([file size $outfile] bytes)"

# --- Was in der Datei steht, nachgesehen statt behauptet ---
set fh [open $outfile rb] ; set data [read $fh] ; close $fh
puts ""
puts "Ebene \"nur Ansicht\" -- nachgesehen in der Datei:"
puts "  /Usage /PrintState /OFF : [expr {[regexp {/PrintState /OFF} $data] ? {ja} : {NEIN}}]"
regexp {/Event /Print[^\n]*/OCGs \[([^\]]*)\]} $data -> druck
regexp {/Event /View[^\n]*/OCGs \[([^\]]*)\]} $data -> sicht
puts "  /AS Print  nennt [expr {[llength $druck]/3}] Ebene(n) -- die druckbaren"
puts "  /AS View   nennt [expr {[llength $sicht]/3}] Ebene(n) -- die mit /Usage"
puts ""
puts "Selber pruefen: Datei in einem Betrachter oeffnen -- der blaue"
puts "Vordruck auf Seite 4 ist da. Aus demselben Betrachter auf Papier"
puts "drucken -- er darf nicht mitkommen. Kommt er mit, befolgt der"
puts "Betrachter /PrintState nicht; dann bleibt nur, das Bild wegzulassen."
