#!/usr/bin/env tclsh
# demo-stdfonts-tounicode.tcl -- Standard-Type1-Fonts mit ToUnicode CMap
#
# Zeigt alle 14 eingebauten PDF-Fonts. Ab 0.9.4.9 enthalten diese Fonts
# einen ToUnicode-CMap-Stream (WinAnsi/cp1252) -- Copy-Paste funktioniert.
#
# Aufruf: tclsh demo-stdfonts-tounicode.tcl

lappend auto_path [file join [file dirname [info script]] ../..] \
                  [file join [file dirname [info script]] ../../..]
package require pdf4tcl

# ---------------------------------------------------------------------------
# Hilfsprozeduren
# ---------------------------------------------------------------------------

proc hline {pdf y} {
    $pdf setStrokeColor 0.8 0.8 0.8
    $pdf line 50 $y 545 $y
    $pdf setStrokeColor 0 0 0
}

proc sectionHeader {pdf y label r g b} {
    $pdf setFillColor $r $g $b
    $pdf rectangle 50 $y 495 18 -filled 1
    $pdf setFillColor 1 1 1
    $pdf setFont 9 Helvetica-Bold
    $pdf text $label -x 56 -y [expr {$y+13}]
    $pdf setFillColor 0 0 0
}

proc infoBox {pdf x y w text} {
    $pdf setFillColor 0.94 0.97 0.94
    $pdf rectangle $x $y $w 14 -filled 1
    $pdf setStrokeColor 0.6 0.8 0.6
    $pdf rectangle $x $y $w 14
    $pdf setStrokeColor 0 0 0
    $pdf setFillColor 0.1 0.4 0.1
    $pdf setFont 7 Helvetica
    $pdf text $text -x [expr {$x+4}] -y [expr {$y+10}]
    $pdf setFillColor 0 0 0
}

# ---------------------------------------------------------------------------
# PDF erzeugen
# ---------------------------------------------------------------------------
set outFile [file join [file dirname [info script]] demo-stdfonts-tounicode.pdf]
set pdf [pdf4tcl::new %AUTO% -paper a4 -orient true]
$pdf startPage

# -- Titel --
$pdf setFont 15 Helvetica-Bold
$pdf text "pdf4tcl 0.9.4.9: Standard-Type1-Fonts mit ToUnicode" -x 50 -y 38
$pdf setFont 9 Helvetica
$pdf text "Alle 14 eingebetteten PDF-Fonts -- Copy-Paste via ToUnicode CMap (WinAnsi/cp1252)" \
    -x 50 -y 54
hline $pdf 62

# -- Erklaerungsbox --
infoBox $pdf 50 68 495 \
    "Neu in 0.9.4.9: MakeStdToUnicodeCMap erzeugt einen 256-Eintrag-CMap-Stream fuer jeden Standard-Type1-Font."
infoBox $pdf 50 84 495 \
    "Ergebnis: pdffonts zeigt uni=yes -- Text ist kopierbar und durchsuchbar -- PDF/A-1b konform (veraPDF Regel 6.3.9)."

# -- Testtext --
set latin "Hello World!  Hallo Welt!   \u00e4 \u00f6 \u00fc \u00df  \u00c4 \u00d6 \u00dc"
set west  "\u00e9 \u00e8 \u00ea \u00f1 \u00e5 \u00e6 \u00f8  \u00e0 \u00e2 \u00ee \u00ef \u00f4 \u00fb"
set curr  "1 + 2 = 3   100 \u00d7 0,5 = 50   \u20ac 99   \u00a3 80   \u00a5 1200"

# ---------------------------------------------------------------------------
# Serifenlose Fonts
# ---------------------------------------------------------------------------
set y 112
sectionHeader $pdf $y "Serifenlose (Sans-Serif)" 0.18 0.38 0.68
incr y 26

foreach {fname size} {
    Helvetica        11
    Helvetica-Bold   11
    Helvetica-Oblique 11
    Helvetica-BoldOblique 11
} {
    $pdf setFont 8 Helvetica-Bold
    $pdf text $fname -x 50 -y [expr {$y+12}]

    $pdf setFont $size $fname
    $pdf text $latin -x 200 -y [expr {$y+12}]

    hline $pdf [expr {$y+20}]
    incr y 22
}

# ---------------------------------------------------------------------------
# Serifen-Fonts (Times)
# ---------------------------------------------------------------------------
incr y 6
sectionHeader $pdf $y "Serifen (Times-Roman)" 0.55 0.27 0.07
incr y 26

foreach {fname size} {
    Times-Roman      11
    Times-Bold       11
    Times-Italic     11
    Times-BoldItalic 11
} {
    $pdf setFont 8 Helvetica-Bold
    $pdf text $fname -x 50 -y [expr {$y+12}]

    $pdf setFont $size $fname
    $pdf text $latin -x 200 -y [expr {$y+12}]

    hline $pdf [expr {$y+20}]
    incr y 22
}

# ---------------------------------------------------------------------------
# Monospace (Courier)
# ---------------------------------------------------------------------------
incr y 6
sectionHeader $pdf $y "Monospace (Courier)" 0.25 0.25 0.25
incr y 26

foreach {fname size} {
    Courier          10
    Courier-Bold     10
    Courier-Oblique  10
    Courier-BoldOblique 10
} {
    $pdf setFont 8 Helvetica-Bold
    $pdf text $fname -x 50 -y [expr {$y+12}]

    $pdf setFont $size $fname
    $pdf text $latin -x 200 -y [expr {$y+12}]

    hline $pdf [expr {$y+20}]
    incr y 22
}

# ---------------------------------------------------------------------------
# Sonderfonts: Symbol + ZapfDingbats
# ---------------------------------------------------------------------------
incr y 6
sectionHeader $pdf $y "Sonderfonts (eigene Encoding -- kein ToUnicode)" 0.45 0.10 0.45
incr y 26

foreach {fname txt note} {
    Symbol       "! \" # $ % & ' ( ) * + , - . / 0 1 2 3 4 5 6 7 8 9 : ; < = >" \
        "Griechisch + Mathematik -- spezielle Encoding"
    ZapfDingbats "! \" # $ % & ' ( ) * + , - . / 0 1 2 3 4 5 6 7 8 9" \
        "Symbole -- spezielle Encoding"
} {
    $pdf setFont 8 Helvetica-Bold
    $pdf text $fname -x 50 -y [expr {$y+10}]
    $pdf setFont 7 Helvetica
    $pdf text "($note)" -x 50 -y [expr {$y+20}]

    $pdf setFont 10 $fname
    $pdf text $txt -x 200 -y [expr {$y+12}]

    hline $pdf [expr {$y+26}]
    incr y 30
}

# ---------------------------------------------------------------------------
# Westeuropaeische Zeichen -- alle 12 Latin-Fonts
# ---------------------------------------------------------------------------
incr y 10
sectionHeader $pdf $y "Westeuropaeische Sonderzeichen (WinAnsi-Bereich -- alle Latin-Fonts)" \
    0.12 0.45 0.35
incr y 26

foreach fname {
    Helvetica Times-Roman Courier
} {
    $pdf setFont 8 Helvetica-Bold
    $pdf text $fname -x 50 -y [expr {$y+12}]

    $pdf setFont 10 $fname
    $pdf text $west -x 200 -y [expr {$y+12}]

    $pdf setFont 9 $fname
    $pdf text $curr -x 200 -y [expr {$y+24}]

    hline $pdf [expr {$y+30}]
    incr y 34
}

# ---------------------------------------------------------------------------
# Eigenschaften
# ---------------------------------------------------------------------------
incr y 10
sectionHeader $pdf $y "Eigenschaften der Standard-Type1-Fonts" 0.3 0.3 0.3
incr y 26

set props {
    "Einbettung"       "nein (Type1-Fonts sind in jedem PDF-Viewer eingebaut)"
    "Encoding"         "WinAnsi (cp1252) fuer 12 Latin-Fonts; eigene Enc. fuer Symbol/ZapfDingbats"
    "ToUnicode CMap"   "ja, ab 0.9.4.9 -- 256-Eintraege, max. 100 pro beginbfchar-Block"
    "Copy-Paste"       "ja, ab 0.9.4.9 (vorher: uni=no, Zeichen wurden falsch kopiert)"
    "PDF/A-1b"         "nicht erlaubt (fehlende Einbettung, ISO 6.3.4) -- TTF verwenden"
    "getStringWidth"   "ja"
    "drawTextBox"      "ja"
    "AcroForm-Felder"  "ja"
}

foreach {attr val} $props {
    $pdf setFont 8 Helvetica-Bold
    $pdf text $attr -x 50 -y $y
    $pdf setFont 8 Helvetica
    $pdf text $val -x 175 -y $y
    incr y 13
}

$pdf endPage
$pdf write -file $outFile
$pdf destroy
puts "Erstellt: $outFile"
