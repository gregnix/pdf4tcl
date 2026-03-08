#!/usr/bin/env tclsh
# demo-api-vergleich.tcl -- API-Vergleich: createFont (WinAnsi) vs createFontSpecCID
#
# Linke Spalte:  createFont / WinAnsi  (Standard-API)
# Rechte Spalte: createFontSpecCID     (Unicode-API ab 0.9.4.5)
#
# Benoetigt: DejaVuSans.ttf  (apt install fonts-dejavu-core)
# Aufruf:    tclsh demo-api-vergleich.tcl [/pfad/zu/DejaVuSans.ttf]

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

# ---------------------------------------------------------------------------
# Fonts laden
# ---------------------------------------------------------------------------
pdf4tcl::loadBaseTrueTypeFont DejaVuBase $fontPath
pdf4tcl::createFont           DejaVuBase winAnsiFont cp1252
set wfont winAnsiFont

pdf4tcl::createFontSpecCID    DejaVuBase cidFont
set cfont cidFont

# ---------------------------------------------------------------------------
# Hilfsprozeduren  (arbeiten alle mit orient true: Y von oben)
# ---------------------------------------------------------------------------

proc hline {pdf y} {
    $pdf setStrokeColor 0.8 0.8 0.8
    $pdf line 50 $y 545 $y
    $pdf setStrokeColor 0 0 0
}

proc colHeader {pdf x y label sub r g b} {
    $pdf setFillColor $r $g $b
    $pdf rectangle $x $y 230 20 -filled 1
    $pdf setFillColor 1 1 1
    $pdf setFont 10 Helvetica-Bold
    $pdf text $label -x [expr {$x+6}] -y [expr {$y+14}]
    $pdf setFillColor 0 0 0
    $pdf setFont 8 Helvetica
    $pdf text $sub -x [expr {$x+6}] -y [expr {$y+26}]
}

proc fallbackBox {pdf x y} {
    $pdf setFillColor 1.0 0.93 0.80
    $pdf rectangle $x [expr {$y-1}] 220 14 -filled 1
    $pdf setFillColor 0.65 0.35 0.0
    $pdf setFont 7 Helvetica
    $pdf text "(ausserhalb WinAnsi -- nicht darstellbar)" \
        -x [expr {$x+4}] -y [expr {$y+10}]
    $pdf setFillColor 0 0 0
}

proc codeBox {pdf x y lines} {
    $pdf setFillColor 0.94 0.94 0.94
    $pdf rectangle $x $y 225 [expr {[llength $lines]*10+6}] -filled 1
    $pdf setFillColor 0 0 0
    $pdf setFont 7 Courier
    set ly [expr {$y+8}]
    foreach line $lines {
        $pdf text $line -x [expr {$x+4}] -y $ly
        incr ly 10
    }
}

# ---------------------------------------------------------------------------
# Demo-Zeilen:  {label  winText|FALLBACK  cidText}
# ---------------------------------------------------------------------------
set rows {
    {"ASCII"
        "Hello World!  0-9  + - * /"
        "Hello World!  0-9  + - * /"}
    {"Deutsch (Umlaute)"
        "\u00e4 \u00f6 \u00fc \u00df  \u00c4 \u00d6 \u00dc"
        "\u00e4 \u00f6 \u00fc \u00df  \u00c4 \u00d6 \u00dc"}
    {"Westeuropaeisch"
        "\u00e9 \u00e8 \u00ea  \u00f1  \u00e5  \u00e6  \u00f8"
        "\u00e9 \u00e8 \u00ea  \u00f1  \u00e5  \u00e6  \u00f8"}
    {"Tschechisch / Slowakisch"
        FALLBACK
        "\u0105 \u0119 \u015b \u017c \u017a  \u010d \u017e \u0161"}
    {"Polnisch"
        FALLBACK
        "\u0105 \u0119 \u015b \u017a \u017c \u0107 \u0144 \u00f3 \u0142  \u0141\u00f3d\u017a"}
    {"Griechisch"
        FALLBACK
        "\u0391\u03b1  \u0392\u03b2  \u0393\u03b3  \u03a3\u03c3  \u03a9\u03c9  \u03c0"}
    {"Kyrillisch / Russisch"
        FALLBACK
        "\u041f\u0440\u0438\u0432\u0435\u0442  \u041c\u0438\u0440  \u0420\u043e\u0441\u0441\u0438\u044f"}
    {"Ukrainisch"
        FALLBACK
        "\u0423\u043a\u0440\u0430\u0457\u043d\u0430  \u0456 \u0457 \u0454 \u0491"}
    {"Mathematik / Symbole"
        FALLBACK
        "\u03b1\u00b2 + \u03b2\u00b2 = \u03b3\u00b2   \u221a\u03c0   \u2264  \u2260  \u2265"}
    {"Waehrungen"
        "\u20ac  \u00a3  \u00a5  \u00a2"
        "\u20ac  \u00a3  \u00a5  \u00a2"}
    {"Pfeile"
        FALLBACK
        "\u2190  \u2192  \u2191  \u2193  \u21d2  \u21d4  \u21a6"}
    {"getStringWidth"
        WIDTH
        WIDTH}
}

# ---------------------------------------------------------------------------
# PDF erzeugen  -- orient true: Y=0 oben links, Y waechst nach unten
# ---------------------------------------------------------------------------
set outFile [file join [file dirname [info script]] demo-api-vergleich.pdf]
set pdf [pdf4tcl::new %AUTO% -paper a4 -orient true]
$pdf startPage

# -- Titel --
$pdf setFont 15 Helvetica-Bold
$pdf text "pdf4tcl 0.9.4.5: createFont vs createFontSpecCID" -x 50 -y 38
$pdf setFont 9 Helvetica
$pdf text "Gleicher Text -- zwei APIs -- eine Seite" -x 50 -y 56
hline $pdf 64

# -- Code-Boxen --
codeBox $pdf 155 72 {
    "pdf4tcl::loadBaseTrueTypeFont BF font.ttf"
    "pdf4tcl::createFont BF myFont cp1252"
    ""
    {$pdf setFont 11 myFont}
    {$pdf text $str -x 50 -y 100}
}
codeBox $pdf 390 72 {
    "pdf4tcl::loadBaseTrueTypeFont BF font.ttf"
    "pdf4tcl::createFontSpecCID BF myFont"
    ""
    {$pdf setFont 11 myFont}
    {$pdf text $str -x 50 -y 100}
}

# -- Spaltenkoepfe --
colHeader $pdf 155 128 "createFont + cp1252 (WinAnsi)" \
    "256-Zeichen-Limit -- TTF-Subset -- Type1-kompatibel" \
    0.18 0.38 0.68
colHeader $pdf 390 128 "createFontSpecCID" \
    "Unicode BMP -- vollst. TTF eingebettet -- ab 0.9.4.5" \
    0.12 0.50 0.28

# -- Vergleichszeilen --
set y 168
set rowH 24
set fs 11

foreach row $rows {
    lassign $row label winText cidText
    hline $pdf $y

    $pdf setFont 8 Helvetica-Bold
    $pdf text $label -x 50 -y [expr {$y+15}]

    # WinAnsi-Spalte
    if {$winText eq "FALLBACK"} {
        fallbackBox $pdf 155 [expr {$y+4}]
    } elseif {$winText eq "WIDTH"} {
        set ts "\u00e4\u00f6\u00fc\u00df"
        $pdf setFont $fs $wfont
        set w [$pdf getStringWidth $ts]
        $pdf text "$ts   ->  [format %.2f $w] pt" -x 160 -y [expr {$y+16}]
    } else {
        $pdf setFont $fs $wfont
        $pdf text $winText -x 160 -y [expr {$y+16}]
    }

    # CID-Spalte
    if {$cidText eq "WIDTH"} {
        set ts "\u00e4\u00f6\u00fc\u00df"
        $pdf setFont $fs $cfont
        set w [$pdf getStringWidth $ts]
        $pdf text "$ts   ->  [format %.2f $w] pt" -x 395 -y [expr {$y+16}]
    } else {
        $pdf setFont $fs $cfont
        $pdf text $cidText -x 395 -y [expr {$y+16}]
    }

    incr y $rowH
}
hline $pdf $y

# -- Eigenschaftstabelle --
set y [expr {$y+20}]
$pdf setFont 10 Helvetica-Bold
$pdf text "Eigenschaften im Vergleich" -x 50 -y $y
incr y 16

foreach {attr win cid} {
    "Zeichenvorrat"         "256  (WinAnsi/cp1252)"       "Unicode BMP  (unbegrenzt)"
    "Schriftarten"          "TTF und Type1"                "nur TTF"
    "TTF-Einbettung"        "Subset  (kleinere Datei)"     "vollstaendig  (groessere Datei)"
    "AcroForm-Felder"       "ja"                           "nein  (PDF-Spezifikation)"
    "Copy-Paste im PDF"     "ja  (ToUnicode CMap)"         "ja  (ToUnicode CMap)"
    "getStringWidth"        "ja"                           "ja"
    "drawTextBox / Umbruch" "ja"                           "ja"
    "Fehlendes Zeichen"     "? (CleanText-Ersetzung)"      ".notdef-Box  (kein CMap-Eintrag)"
} {
    $pdf setFont 8 Helvetica
    $pdf text $attr -x 50  -y $y
    $pdf text $win  -x 200 -y $y
    $pdf text $cid  -x 385 -y $y
    incr y 13
}

$pdf endPage
$pdf write -file $outFile
$pdf destroy
puts "Erstellt: $outFile"

