#!/usr/bin/env tclsh
# demo-stdfonts-tabelle.tcl -- WinAnsi-Zeichentabelle fuer alle 14 Standard-Type1-Fonts
#
# Pro Font wird eine Seite mit allen 256 WinAnsi-Positionen erzeugt.
# Ab pdf4tcl 0.9.4.9: ToUnicode CMap eingebettet -> uni=yes -> Copy-Paste OK.
#
# Aufruf: tclsh demo-stdfonts-tabelle.tcl
# Ausgabe: demo-stdfonts-tabelle.pdf  im Skript-Verzeichnis

lappend auto_path [file join [file dirname [info script]] ../..] \
                  [file join [file dirname [info script]] ../../..]
package require pdf4tcl

# ---------------------------------------------------------------------------
# WinAnsi cp1252 -> Unicode-Mapping fuer die 5 undefinierten Stellen
# (alle anderen Bytes: direkt als Unicode-Codepoint verwendbar)
# ---------------------------------------------------------------------------
array set cp1252extra {
    0x80 0x20AC  0x82 0x201A  0x83 0x0192  0x84 0x201E  0x85 0x2026
    0x86 0x2020  0x87 0x2021  0x88 0x02C6  0x89 0x2030  0x8A 0x0160
    0x8B 0x2039  0x8C 0x0152  0x8E 0x017D  0x91 0x2018  0x92 0x2019
    0x93 0x201C  0x94 0x201D  0x95 0x2022  0x96 0x2013  0x97 0x2014
    0x98 0x02DC  0x99 0x2122  0x9A 0x0161  0x9B 0x203A  0x9C 0x0153
    0x9E 0x017E  0x9F 0x0178
}
# Undefinierte Positionen (kein Glyph in cp1252)
set cp1252undef {0x81 0x8D 0x8F 0x90 0x9D}

proc cpToUnicode {byte} {
    global cp1252extra cp1252undef
    set hb [format "0x%02X" $byte]
    if {$hb in $::cp1252undef}         { return -1 }
    if {[info exists cp1252extra($hb)]} { return $cp1252extra($hb) }
    return $byte
}

# Glyphname aus glyph2unicode wenn verfuegbar
set hasGlyph2u 0
if {![catch {package require pdf4tcl::glyph2unicode}]} {
    set hasGlyph2u 1
    array set cpToGlyph {}
    foreach {gname cp} [array get pdf4tcl::GlName2Uni] {
        if {![info exists cpToGlyph($cp)] ||
            [string length $gname] < [string length $cpToGlyph($cp)]} {
            set cpToGlyph($cp) $gname
        }
    }
}

proc glyphName {unicode} {
    global hasGlyph2u cpToGlyph
    if {!$hasGlyph2u}                       { return "" }
    if {[info exists cpToGlyph($unicode)]}  { return $cpToGlyph($unicode) }
    return ""
}

# ---------------------------------------------------------------------------
# Layout-Konstanten
# ---------------------------------------------------------------------------
set mL   12.0   ;# Rand links mm
set mT   18.0   ;# Rand oben mm
set mB   12.0   ;# Rand unten mm
set pH  297.0   ;# A4-Hoehe mm
set pW  210.0   ;# A4-Breite mm
set rowH  4.5   ;# Zeilenhoehe mm
set fGl   4.0   ;# Schriftgroesse Glyph
set fTxt  3.8   ;# Schriftgroesse Text / Name
set fHead 4.5   ;# Schriftgroesse Kopfzeile
set cByte  8.0  ;# Spaltenbreite Hex-Byte
set cGlyph 8.0  ;# Spaltenbreite Glyph
set cUni   12.0 ;# Spaltenbreite Unicode
set cName  52.0 ;# Spaltenbreite Glyphname
set blockW [expr {$cByte + $cGlyph + $cUni + $cName}]
set gap     8.0
set x0L     $mL
set x0R    [expr {$mL + $blockW + $gap}]

# ---------------------------------------------------------------------------
# Hilfsprozeduren
# ---------------------------------------------------------------------------
proc newPage {pdf title} {
    global mL mT pW fHead
    $pdf startPage
    $pdf setFont $fHead Helvetica-Bold
    $pdf text $title -x $mL -y $mT
    $pdf line $mL [expr {$mT + 2.0}] [expr {$pW - $mL}] [expr {$mT + 2.0}]
}

proc tableHeader {pdf y} {
    global x0L x0R cByte cGlyph cUni fTxt
    $pdf setFont $fTxt Helvetica-Bold
    foreach x [list $x0L $x0R] {
        $pdf text "Hex"    -x $x                               -y $y
        $pdf text "Gl."    -x [expr {$x + $cByte}]            -y $y
        $pdf text "U+"     -x [expr {$x + $cByte + $cGlyph}]  -y $y
        $pdf text "Name"   -x [expr {$x + $cByte + $cGlyph + $cUni}] -y $y
    }
}

proc drawRow {pdf x y byte sfont} {
    global cByte cGlyph cUni fTxt fGl
    # Hex-Byte
    $pdf setFont $fTxt Helvetica
    $pdf text [format "%02X" $byte] -x $x -y $y
    # Glyph
    set uni [cpToUnicode $byte]
    if {$uni < 0} {
        # undefiniert
        $pdf setFont $fTxt Helvetica
        $pdf text "(undef)" -x [expr {$x + $cByte}] -y $y
        return
    }
    if {$byte >= 0x20} {
        $pdf setFont $fGl $sfont
        $pdf text [format "%c" $uni] -x [expr {$x + $cByte + 1.0}] -y $y
    }
    # Unicode-Codepoint
    $pdf setFont $fTxt Helvetica
    $pdf text [format "%04X" $uni] -x [expr {$x + $cByte + $cGlyph}] -y $y
    # Glyphname
    set name [glyphName $uni]
    if {$name ne ""} {
        $pdf text $name -x [expr {$x + $cByte + $cGlyph + $cUni}] -y $y
    }
}

# ---------------------------------------------------------------------------
# Eine Seite pro Byte-Bereich erzeugen (max 128 Eintraege = eine Seite)
# ---------------------------------------------------------------------------
proc rangePage {pdf title from to sfont} {
    global mT mB pH rowH x0L x0R
    set yStart [expr {$mT + 8.0}]
    set yMax   [expr {$pH - $mB}]
    set perPage [expr {int(($yMax - $yStart) / $rowH) * 2}]
    set chars {}
    for {set b $from} {$b <= $to} {incr b} { lappend chars $b }
    set i 0; set total [llength $chars]; set firstPage 1
    while {$i < $total} {
        newPage $pdf $title
        if {$firstPage} {
            $pdf bookmarkAdd -title $title -level 1
            set firstPage 0
        }
        tableHeader $pdf [expr {$mT + 5.0}]
        set y $yStart; set col 0; set n 0
        while {$i < $total && $n < $perPage} {
            set x [expr {$col == 0 ? $x0L : $x0R}]
            drawRow $pdf $x $y [lindex $chars $i] $sfont
            incr col
            if {$col == 2} { set col 0; set y [expr {$y + $rowH}] }
            incr i; incr n
        }
        $pdf endPage
    }
}

# ---------------------------------------------------------------------------
# 14 Standard-Type1-Fonts
# ---------------------------------------------------------------------------
set latinFonts {
    Helvetica             Helvetica-Bold
    Helvetica-Oblique     Helvetica-BoldOblique
    Times-Roman           Times-Bold
    Times-Italic          Times-BoldItalic
    Courier               Courier-Bold
    Courier-Oblique       Courier-BoldOblique
}
set specialFonts {Symbol ZapfDingbats}

# ---------------------------------------------------------------------------
# PDF erzeugen
# ---------------------------------------------------------------------------
set outFile [file join [file dirname [info script]] demo-stdfonts-tabelle.pdf]
set pdf [pdf4tcl::new %AUTO% -paper a4 -orient 1 -compress 1 -unit mm]

# --- Titelseite ---
$pdf startPage
$pdf setFont 16 Helvetica-Bold
$pdf text "pdf4tcl 0.9.4.9: Standard-Type1-Fonts" -x 15 -y 40
$pdf setFont 11 Helvetica-Bold
$pdf text "WinAnsi-Zeichentabelle (cp1252) fuer alle 14 eingebauten Fonts" -x 15 -y 56
$pdf setFont 9 Helvetica
$pdf text "Jede Seite zeigt: Hex-Byte  |  Glyph  |  Unicode-Codepoint  |  Glyphname" -x 15 -y 70
$pdf line 15 76 195 76

set y 86
foreach {attr val} {
    "Encoding"       "WinAnsi (cp1252) fuer 12 Latin-Fonts -- eigene Encoding fuer Symbol/ZapfDingbats"
    "ToUnicode CMap" "ab 0.9.4.9: 256-Eintraege, max. 100 pro beginbfchar-Block (PDF-Spec 9.10.3)"
    "Copy-Paste"     "funktioniert ab 0.9.4.9  (pdffonts: uni=yes)"
    "Einbettung"     "nein -- Type1-Fonts sind in jedem PDF-Viewer eingebaut"
    "PDF/A-1b"       "NICHT erlaubt (fehlende Einbettung, ISO 6.3.4) -- TTF verwenden"
    "Undefiniert"    "0x81 0x8D 0x8F 0x90 0x9D -> U+FFFD (kein Glyph in cp1252)"
} {
    $pdf setFont 8 Helvetica-Bold
    $pdf text $attr -x 15 -y $y
    $pdf setFont 8 Helvetica
    $pdf text $val  -x 55 -y $y
    incr y 12
}

$pdf line 15 [expr {$y+2}] 195 [expr {$y+2}]
incr y 10
$pdf setFont 9 Helvetica-Bold
$pdf text "Enthaltene Fonts:" -x 15 -y $y
incr y 10
set col 0; set fx 15
foreach f [concat $latinFonts $specialFonts] {
    $pdf setFont 8 $f
    $pdf text $f -x $fx -y $y
    incr col
    if {$col == 2} { set col 0; incr y 10; set fx 15 } else { set fx 110 }
}
$pdf endPage

# --- Latin-Fonts: je 2 Bereiche (0x00-0x7F, 0x80-0xFF) ---
foreach fname $latinFonts {
    $pdf bookmarkAdd -title $fname -level 0
    rangePage $pdf "$fname -- 0x00..0x7F (ASCII + Steuerzeichen)" \
        0x00 0x7F $fname
    rangePage $pdf "$fname -- 0x80..0xFF (WinAnsi-Erweiterung)" \
        0x80 0xFF $fname
}

# --- Symbol + ZapfDingbats: nur 0x20-0xFF sinnvoll ---
foreach fname $specialFonts {
    $pdf bookmarkAdd -title "$fname (eigene Encoding)" -level 0
    rangePage $pdf "$fname -- 0x20..0x7E (druckbare Zeichen)" \
        0x20 0x7E $fname
    rangePage $pdf "$fname -- 0xA0..0xFF (oberer Bereich)" \
        0xA0 0xFF $fname
}

$pdf write -file $outFile
$pdf destroy
puts "Erstellt: $outFile"
