#!/usr/bin/env tclsh
# demo-annotations.tcl -- Annotation-Methoden (pdf4tcl 0.9.4.23)
#
# Seite 1: addAnnotNote, addAnnotFreeText, addAnnotStamp
# Seite 2: addAnnotHighlight, addAnnotUnderline, addAnnotStrikeOut
# Seite 3: addAnnotLine, Uebersichtstabelle
#
# Usage: tclsh demo-annotations.tcl [outputdir]

set demodir  [file dirname [file normalize [info script]]]
set reporoot [file normalize [file join $demodir ../..]]
set auto_path [linsert $auto_path 0 $reporoot]
package require pdf4tcl

set outdir [expr {$argc > 0 ? [lindex $argv 0] : [file join $demodir out]}]
file mkdir $outdir
set outfile [file join $outdir demo-annotations.pdf]

# ---------------------------------------------------------------------------
# Hilfsprocs
# ---------------------------------------------------------------------------

proc heading {pdf txt y} {
    $pdf setFillColor 0.10 0.25 0.50
    $pdf rectangle 40 $y 515 22 -filled 1
    $pdf setFillColor 1 1 1
    $pdf setFont 11 Helvetica-Bold
    $pdf text $txt -x 46 -y [expr {$y+15}]
    $pdf setFillColor 0 0 0
    return [expr {$y+32}]
}

proc infobox {pdf txt y} {
    $pdf setFillColor 0.93 0.97 1.0
    $pdf setStrokeColor 0.6 0.8 1.0
    $pdf setLineWidth 0.5
    $pdf rectangle 40 [expr {$y-8}] 515 16 -filled 1
    $pdf setFont 7.3 Courier
    $pdf setFillColor 0.1 0.3 0.6
    $pdf text $txt -x 44 -y $y
    $pdf setFillColor 0 0 0
    $pdf setStrokeColor 0 0 0
    return [expr {$y+20}]
}

proc body {pdf txt y} {
    $pdf setFont 10 Helvetica
    $pdf setFillColor 0.2 0.2 0.2
    $pdf text $txt -x 46 -y $y
    $pdf setFillColor 0 0 0
    return [expr {$y+14}]
}

proc pagetitle {pdf txt} {
    $pdf setFont 15 Helvetica-Bold
    $pdf setFillColor 0.1 0.25 0.5
    $pdf text $txt -x 40 -y 25
    $pdf setFillColor 0 0 0
    $pdf setLineWidth 0.5
    $pdf setStrokeColor 0.5 0.5 0.5
    $pdf line 40 42 555 42
    $pdf setStrokeColor 0 0 0
}

# ===========================================================================
# Seite 1 -- addAnnotNote, addAnnotFreeText, addAnnotStamp
# ===========================================================================

set pdf [pdf4tcl::new %AUTO% -paper a4 -orient 1 -file $outfile]
$pdf startPage
pagetitle $pdf "pdf4tcl 0.9.4.23 -- Annotationen: Note, FreeText, Stamp"
set y 55

# --- Sticky Notes ---
set y [heading $pdf "1. Sticky Notes (addAnnotNote)" $y]
set y [body $pdf "Erscheinen als Icon; Klick oeffnet Popup-Fenster mit Text." $y]
incr y 5

foreach {lbl icon col cx} {
    "Note (gelb)"       Note    {1.0 1.0 0.3}  46
    "Comment (blau)"    Comment {0.6 0.8 1.0} 200
    "Key (gruen)"       Key     {0.6 1.0 0.6} 354
} {
    $pdf setFont 9 Helvetica
    $pdf setFillColor 0.3 0.3 0.3
    $pdf text $lbl -x $cx -y [expr {$y+32}]
    $pdf addAnnotNote $cx $y 20 20 \
        -icon  $icon \
        -color $col  \
        -content "Icon: $icon\nFarbe: $col\nAutor: Greg" \
        -author "Greg"
}
incr y 42
set y [infobox $pdf \
    {addAnnotNote x y w h  -content text  -author name  -icon Note|Comment|Key|Help  -color {r g b}  -open bool} \
    $y]
incr y 8

# --- FreeText ---
set y [heading $pdf "2. FreeText-Annotationen (addAnnotFreeText)" $y]
set y [body $pdf "Sichtbare Textboxen direkt auf der Seite -- kein Klick noetig." $y]
incr y 5

$pdf addAnnotFreeText 46 $y 230 45 \
    "Standard-FreeText\nHintergrund: hellgelb\nFont: 10pt" \
    -fontsize 10

$pdf addAnnotFreeText 296 $y 255 45 \
    "Angepasst: blau\nFarbe + Hintergrund\nkonfigurierbar" \
    -fontsize 9 \
    -color   {0.0 0.1 0.6} \
    -bgcolor {0.88 0.92 1.0}
incr y 58

set y [infobox $pdf \
    {addAnnotFreeText x y w h text  -fontsize n  -color {r g b}  -bgcolor {r g b}  -align 0|1|2} \
    $y]
incr y 8

# --- Stamps ---
set y [heading $pdf "3. Stempel (addAnnotStamp)" $y]
set y [body $pdf "Vordefinierte Stempel: Draft, Confidential, Approved, Final, Expired, TopSecret, ..." $y]
incr y 8

set stamps {
    {Draft       {0.8 0.0 0.0}  46}
    {Confidential {0.7 0.2 0.0} 195}
    {Approved    {0.0 0.55 0.1} 355}
    {Final       {0.0 0.3 0.7}  46}
    {Expired     {0.4 0.4 0.4} 195}
    {TopSecret   {0.5 0.0 0.5} 355}
}
foreach row $stamps {
    lassign $row name col x
    if {$x == 46 && $name eq "Final"} { incr y 60 }
    $pdf addAnnotStamp $x $y 130 48 -name $name -color $col
    $pdf setFont 8 Helvetica
    $pdf setFillColor 0.3 0.3 0.3
    $pdf text $name -x [expr {$x+2}] -y [expr {$y+58}]
    $pdf setFillColor 0 0 0
}
incr y 118

set y [infobox $pdf \
    {addAnnotStamp x y w h  -name Draft|Confidential|Approved|Final|Expired|TopSecret|...  -color {r g b}} \
    $y]
$pdf endPage

# ===========================================================================
# Seite 2 -- addAnnotHighlight, addAnnotUnderline, addAnnotStrikeOut
# ===========================================================================

$pdf startPage
pagetitle $pdf "Seite 2: Text-Markup Annotationen"
set y 55

# --- Highlight ---
set y [heading $pdf "4. Hervorhebung (addAnnotHighlight)" $y]
set y [body $pdf "Markiert Textbereiche farbig -- wie ein Textmarker." $y]
incr y 5

foreach {txt col} {
    "Dieser Text wird gelb hervorgehoben (Standardfarbe)."  {1.0 1.0 0.3}
    "Gruen markierter Text (-color {0.6 1.0 0.6})."        {0.6 1.0 0.6}
    "Blau markierter Text (-color {0.7 0.85 1.0})."        {0.7 0.85 1.0}
    "Rosa markierter Text (-color {1.0 0.75 0.8})."        {1.0 0.75 0.8}
} {
    $pdf setFont 11 Helvetica
    $pdf setFillColor 0 0 0
    $pdf text $txt -x 46 -y [expr {$y+11}]
    $pdf addAnnotHighlight 46 $y 470 15 -color $col
    incr y 22
}
incr y 4

set y [infobox $pdf \
    {addAnnotHighlight x y w h  -color {r g b}  -content text  -author name} \
    $y]
incr y 10

# --- Underline ---
set y [heading $pdf "5. Unterstreichung (addAnnotUnderline)" $y]
set y [body $pdf "Unterstreicht Textbereiche als Annotation (nicht als Textformatierung)." $y]
incr y 5

foreach {txt col} {
    "Einfache schwarze Unterstreichung (Standard)."     {0.0 0.0 0.0}
    "Blaue Unterstreichung (-color {0.0 0.2 0.8})."    {0.0 0.2 0.8}
    "Rote Unterstreichung fuer Korrekturen."             {0.8 0.0 0.0}
} {
    $pdf setFont 11 Helvetica
    $pdf setFillColor 0 0 0
    $pdf text $txt -x 46 -y [expr {$y+11}]
    $pdf addAnnotUnderline 46 $y 470 15 -color $col
    incr y 22
}
incr y 4

set y [infobox $pdf \
    {addAnnotUnderline x y w h  -color {r g b}  -content text  -author name} \
    $y]
incr y 10

# --- StrikeOut ---
set y [heading $pdf "6. Durchstreichen (addAnnotStrikeOut)" $y]
set y [body $pdf "Markiert Text als geloescht -- fuer Review-Dokumente und Korrekturen." $y]
incr y 5

foreach {txt col} {
    "Dieser Text wird als geloescht markiert (rot)."  {0.9 0.0 0.0}
    "Grau durchgestrichen -- weniger aufdringlich."   {0.5 0.5 0.5}
    "Kombination: Highlight + StrikeOut moeglich."    {0.0 0.0 0.0}
} {
    $pdf setFont 11 Helvetica
    $pdf setFillColor 0 0 0
    $pdf text $txt -x 46 -y [expr {$y+11}]
    $pdf addAnnotStrikeOut 46 $y 470 15 -color $col
    incr y 22
}
incr y 4

set y [infobox $pdf \
    {addAnnotStrikeOut x y w h  -color {r g b}  -content text  -author name} \
    $y]

$pdf endPage

# ===========================================================================
# Seite 3 -- addAnnotLine + Uebersichtstabelle
# ===========================================================================

$pdf startPage
pagetitle $pdf "Seite 3: Linien-Annotationen + Uebersicht"
set y 55

# --- Lines ---
set y [heading $pdf "7. Linien-Annotationen (addAnnotLine)" $y]
set y [body $pdf "Linien mit konfigurierbaren Pfeilspitzen, Farbe und Breite." $y]
incr y 10

# Einfache Linie
$pdf setFont 9 Helvetica
$pdf setFillColor 0.3 0.3 0.3
$pdf text "Einfache Linie:" -x 46 -y $y
$pdf addAnnotLine 160 [expr {$y-4}] 400 [expr {$y-4}]
incr y 18

# Pfeil rechts
$pdf text "Pfeil (OpenArrow):" -x 46 -y $y
$pdf addAnnotLine 160 [expr {$y-4}] 400 [expr {$y-4}] \
    -startend {None OpenArrow} -color {0 0 0.8}
incr y 18

# Doppelpfeil
$pdf text "Doppelpfeil:" -x 46 -y $y
$pdf addAnnotLine 160 [expr {$y-4}] 400 [expr {$y-4}] \
    -startend {OpenArrow OpenArrow} -color {0 0.5 0}
incr y 18

# Dicker roter Pfeil
$pdf text "Dicker roter Pfeil:" -x 46 -y $y
$pdf addAnnotLine 160 [expr {$y-4}] 400 [expr {$y-4}] \
    -startend {None ClosedArrow} -color {0.8 0 0} -width 2
incr y 18

# Diagonale Linie
$pdf text "Diagonal:" -x 46 -y $y
$pdf addAnnotLine 160 [expr {$y-14}] 400 [expr {$y+6}] \
    -startend {Circle OpenArrow} -color {0.5 0 0.5}
incr y 30

set y [infobox $pdf \
    {addAnnotLine x1 y1 x2 y2  -color {r g b}  -width n  -startend {None|OpenArrow|ClosedArrow|Circle|...}  -content text} \
    $y]
incr y 15

# --- Uebersichtstabelle ---
set y [heading $pdf "Uebersicht: Neue Annotation-Methoden (0.9.4.23)" $y]
incr y 5

set rows {
    {"addAnnotNote"       "/Text"        "Sticky Note Icon"                    "Note Comment Key Help"}
    {"addAnnotFreeText"   "/FreeText"    "Sichtbare Textbox"                   "-fontsize -color -bgcolor"}
    {"addAnnotHighlight"  "/Highlight"   "Farbige Hervorhebung"                "-color -content"}
    {"addAnnotUnderline"  "/Underline"   "Unterstreichung"                     "-color -content"}
    {"addAnnotStrikeOut"  "/StrikeOut"   "Durchstreichen"                      "-color -content"}
    {"addAnnotStamp"      "/Stamp"       "Stempel (Draft/Confidential/...)"    "-name -color"}
    {"addAnnotLine"       "/Line"        "Linie mit Pfeilspitzen"              "-startend -width"}
}

# Header
set hx {40 155 245 370}
$pdf setFillColor 0.15 0.30 0.55
$pdf rectangle 40 $y 515 18 -filled 1
$pdf setFont 8 Helvetica-Bold
$pdf setFillColor 1 1 1
foreach hdr {"Methode" "PDF-Typ" "Beschreibung" "Optionen"} x $hx {
    $pdf text $hdr -x [expr {$x+3}] -y [expr {$y+12}]
}
incr y 18

set alt 0
foreach row $rows {
    lassign $row meth typ desc opts
    if {$alt} {
        $pdf setFillColor 0.95 0.95 0.95
        $pdf rectangle 40 $y 515 16 -filled 1
        $pdf setFillColor 0 0 0
    }
    $pdf setFont 8 Courier
    $pdf setFillColor 0.1 0.3 0.6
    $pdf text $meth -x [expr {[lindex $hx 0]+3}] -y [expr {$y+11}]
    $pdf setFont 8 Helvetica
    $pdf setFillColor 0.2 0.2 0.2
    $pdf text $typ  -x [expr {[lindex $hx 1]+3}] -y [expr {$y+11}]
    $pdf text $desc -x [expr {[lindex $hx 2]+3}] -y [expr {$y+11}]
    $pdf setFont 7 Courier
    $pdf setFillColor 0.4 0.4 0.4
    $pdf text $opts -x [expr {[lindex $hx 3]+3}] -y [expr {$y+11}]
    $pdf setFillColor 0 0 0
    incr y 16
    set alt [expr {!$alt}]
}

# Rahmen
$pdf setLineWidth 0.3
$pdf setStrokeColor 0.6 0.6 0.6
set topy [expr {$y - 16 * [llength $rows] - 18}]
$pdf rectangle 40 $topy 515 [expr {$y - $topy}]
$pdf setStrokeColor 0 0 0

$pdf endPage
$pdf destroy
puts "Erzeugt: $outfile ([expr {[file size $outfile]/1024}] KB)"
