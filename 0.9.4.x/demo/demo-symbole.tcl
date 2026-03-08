#!/usr/bin/env tclsh
# demo-symbole.tcl -- Symbolrepertoire von createFontSpecCID (4 Seiten)
#
# Seite 1: Latein-1-Erg., Latein-Ext-A/B, IPA, Griechisch
# Seite 2: Kyrillisch, Pfeile, Mathematik, Hoch/Tief+Zahlenformen
# Seite 3: Technisch, Box-Drawing, Block/Geometrie, Symbole, Dingbats
# Seite 4: Math. Operatoren, Verschiedene Symbole+Pfeile
#
# Benoetigt: DejaVuSans.ttf  (apt install fonts-dejavu-core)
# Aufruf:    tclsh demo-symbole.tcl [/pfad/zu/DejaVuSans.ttf]

lappend auto_path [file join [file dirname [info script]] ../..] \
                  [file join [file dirname [info script]] ../../..]
package require pdf4tcl

# ---------------------------------------------------------------------------
# Font-Pfad
# ---------------------------------------------------------------------------
set fontPath [lindex $argv 0]
if {$fontPath eq ""} {
    foreach c {
        /usr/share/fonts/truetype/dejavu/DejaVuSans.ttf
        /usr/share/fonts/TTF/DejaVuSans.ttf
        /Library/Fonts/DejaVuSans.ttf
        C:/Windows/Fonts/DejaVuSans.ttf
    } { if {[file exists $c]} { set fontPath $c; break } }
}
if {$fontPath eq "" || ![file exists $fontPath]} {
    puts stderr "Fehler: DejaVuSans.ttf nicht gefunden."
    exit 1
}
puts "Font: $fontPath"

pdf4tcl::loadBaseTrueTypeFont DejaVuBase $fontPath
pdf4tcl::createFontSpecCID    DejaVuBase cidFont
set cfont cidFont

# ---------------------------------------------------------------------------
# Konstanten
# ---------------------------------------------------------------------------
set FONT_SIZE  13
set LINE_H     20
set HEADER_H   38   ;# blauer Balken 20pt + 18pt Abstand bis erste Textzeile
set GAP        10
set MAX_W     490
set LEFT       50
set TOP_START  90

# ---------------------------------------------------------------------------
# Hilfsprozeduren
# ---------------------------------------------------------------------------
proc hline {pdf y} {
    $pdf setStrokeColor 0.75 0.75 0.75
    $pdf line 50 $y 545 $y
    $pdf setStrokeColor 0 0 0
}

proc pageTitle {pdf title pagenum} {
    $pdf setFont 14 Helvetica-Bold
    $pdf text $title -x 50 -y 32
    $pdf setFont 8 Helvetica
    $pdf setFillColor 0.45 0.45 0.45
    $pdf text "DejaVuSans.ttf  --  nur mit createFontSpecCID darstellbar  --  pdf4tcl 0.9.4.5  --  Seite $pagenum" \
        -x 50 -y 48
    $pdf setFillColor 0 0 0
    hline $pdf 56
}

proc groupHeader {pdf y title sub} {
    # Blauer Balken 20pt hoch
    $pdf setFillColor 0.18 0.35 0.62
    $pdf rectangle 50 $y 495 20 -filled 1
    $pdf setFillColor 1 1 1
    # Titel (fett) in Zeile 1
    $pdf setFont 10 Helvetica-Bold
    $pdf text $title -x 55 -y [expr {$y+15}]
    $pdf setFillColor 0 0 0
    # Untertitel in Zeile 2 (schwarz, unter dem Balken)
    $pdf setFont 8 Helvetica
    $pdf setFillColor 0.3 0.3 0.3
    $pdf text $sub -x 55 -y [expr {$y+28}]
    $pdf setFillColor 0 0 0
}

# Alle Codepoints eines Bereichs die im Font vorhanden sind
proc buildRange {bfname from to} {
    set result ""
    for {set cp $from} {$cp <= $to} {incr cp} {
        if {[dict exists $::pdf4tcl::BFA($bfname,charToGlyph) $cp]} {
            append result [format %c $cp]
            append result " "
        }
    }
    return $result
}

proc renderChars {pdf cfont chars x y maxW lineH fontSize} {
    $pdf setFont $fontSize $cfont
    set row ""
    foreach ch [split $chars {}] {
        set candidate "$row$ch"
        if {[$pdf getStringWidth $candidate] > $maxW} {
            if {$row ne ""} {
                $pdf text $row -x $x -y $y
                incr y $lineH
            }
            set row $ch
        } else {
            set row $candidate
        }
    }
    if {$row ne ""} {
        $pdf text $row -x $x -y $y
        incr y $lineH
    }
    return $y
}

proc renderGroup {pdf cfont y title sub from to} {
    global FONT_SIZE LINE_H HEADER_H GAP MAX_W LEFT
    groupHeader $pdf $y $title $sub
    set y [expr {$y + $HEADER_H}]
    set chars [buildRange DejaVuBase $from $to]
    set y [renderChars $pdf $cfont $chars \
               [expr {$LEFT + 4}] $y $MAX_W $LINE_H $FONT_SIZE]
    return [expr {$y + $GAP}]
}

# ---------------------------------------------------------------------------
# Seitengruppen
# ---------------------------------------------------------------------------
# Format: {Titel  Untertitel  U+from  U+to}
set pages {
    {
        {"Latein-1-Ergaenzung (Westeuropaeisch)"
            "U+00C0..U+00FF -- Zeichen ausserhalb ASCII, in WinAnsi enthalten"
            0x00C0 0x00FF}
        {"Lateinisch erweitert A -- Mitteleuropaeisch"
            "U+0100..U+017F -- Tschechisch, Polnisch, Slowakisch, Kroatisch u.a."
            0x0100 0x017F}
        {"Lateinisch erweitert B"
            "U+0180..U+024F -- Seltene lateinische Zeichen, Phonetik, Afrikanisch"
            0x0180 0x024F}
        {"IPA -- Internationales Phonetisches Alphabet"
            "U+0250..U+02AF -- Lautschrift fuer alle Sprachen der Welt"
            0x0250 0x02AF}
        {"Griechisch und Koptisch"
            "U+0370..U+03FF -- Griechisch, Mathematik (pi, sigma, alpha...)"
            0x0370 0x03FF}
    }
    {
        {"Kyrillisch"
            "U+0400..U+04FF -- Russisch, Ukrainisch, Bulgarisch, Serbisch u.a."
            0x0400 0x04FF}
        {"Pfeile"
            "U+2190..U+21FF -- Einzel-, Doppel-, gebogene und diagonale Pfeile"
            0x2190 0x21FF}
        {"Mathematische Operatoren"
            "U+2200..U+22FF -- Mengen, Relationen, Integrale, Summen, Wurzeln"
            0x2200 0x22FF}
        {"Hoch-/Tiefgestellt, Zahlenformen und Letterlike"
            "U+2070..U+218F -- Exponenten, Indizes, Brueche, Letterlike-Symbole"
            0x2070 0x218F}
    }
    {
        {"Technische Symbole"
            "U+2300..U+23FF -- Tastatur, Uhren, Klammern, technische Zeichen"
            0x2300 0x23FF}
        {"Box-Zeichnung (Box Drawing)"
            "U+2500..U+257F -- Einfache und doppelte Linien, Ecken, Kreuzungen"
            0x2500 0x257F}
        {"Block-Elemente und Geometrische Formen"
            "U+2580..U+25FF -- Bloecke, Dreiecke, Kreise, Rauten, Quadrate"
            0x2580 0x25FF}
        {"Diverse Symbole"
            "U+2600..U+26FF -- Wetter, Sternzeichen, Schach, Karten, Musik"
            0x2600 0x26FF}
        {"Dingbats"
            "U+2700..U+27BF -- Schere, Flugzeug, Haken, Sterne, Ziffernkreise"
            0x2700 0x27BF}
    }
    {
        {"Zusaetzliche Mathematische Operatoren"
            "U+2A00..U+2AFF -- Erweiterte Operatoren: Kreuzprodukt, Summation u.a."
            0x2A00 0x2AFF}
        {"Verschiedene Symbole und Pfeile"
            "U+2B00..U+2BFF -- Moderne Symbole, breite Pfeile, Sterne"
            0x2B00 0x2BFF}
        {"Waehrungssymbole"
            "U+20A0..U+20CF -- Euro, Pfund, Yen, Rubel, Rupie und weitere"
            0x20A0 0x20CF}
        {"Umschlossene Alphanumerische Zeichen"
            "U+2460..U+24FF -- Eingekreiste Ziffern 1-20, Buchstaben A-Z"
            0x2460 0x24FF}
    }
}

set pageTitles {
    "Symbolrepertoire (1/4): Lateinisch, IPA, Griechisch"
    "Symbolrepertoire (2/4): Kyrillisch, Pfeile, Mathematik"
    "Symbolrepertoire (3/4): Technisch, Box, Geometrie, Symbole, Dingbats"
    "Symbolrepertoire (4/4): Math. Operatoren, Waehrungen, Sonderzeichen"
}

# ---------------------------------------------------------------------------
# PDF erzeugen
# ---------------------------------------------------------------------------
set outFile [file join [file dirname [info script]] demo-symbole.pdf]
set pdf [pdf4tcl::new %AUTO% -paper a4 -orient true -compress 1]

set pnum 0
foreach page $pages ptitle $pageTitles {
    incr pnum
    $pdf startPage
    pageTitle $pdf $ptitle $pnum
    set y $TOP_START
    foreach grp $page {
        lassign $grp title sub from to
        set y [renderGroup $pdf $cfont $y $title $sub $from $to]
    }
}

$pdf write -file $outFile
$pdf destroy
puts "Erstellt: $outFile"
