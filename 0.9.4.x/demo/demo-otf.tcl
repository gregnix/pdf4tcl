#!/usr/bin/env tclsh
# demo-otf.tcl -- OTF/CFF font support demo for pdf4tcl 0.9.4.15
#
# Usage (from pdf4tcl root, with auto_path set):
#   tclsh demo-otf.tcl
#   tclsh demo-otf.tcl --out /tmp --font /path/to/font.otf
#
# Demonstrates:
#   Page 1 -- loadBaseTrueTypeFont with OTF/CFF font, font metadata
#   Page 2 -- Multiple OTF fonts, font sizes, getStringWidth
#   Page 3 -- Unicode character coverage (Latin, Thai, symbols)

package require pdf4tcl

# ---------------------------------------------------------------------------
# Argument parsing
# ---------------------------------------------------------------------------
set outDir  "."
set otfFile ""

for {set i 0} {$i < [llength $argv]} {incr i} {
    switch -- [lindex $argv $i] {
        --out  { set outDir  [lindex $argv [incr i]] }
        --font { set otfFile [lindex $argv [incr i]] }
    }
}

# ---------------------------------------------------------------------------
# Font discovery
# ---------------------------------------------------------------------------
proc findFont {candidates} {
    foreach f $candidates {
        if {[file exists $f]} { return $f }
    }
    return ""
}

if {$otfFile eq ""} {
    set otfFile [findFont {
        /usr/share/fonts/opentype/tlwg/Loma.otf
        /usr/share/fonts/truetype/baskerville/GFSBaskerville.otf
        /usr/share/fonts/opentype/porson/GFSPorson.otf
    }]
}
if {$otfFile eq ""} {
    puts stderr "No OTF font found. Use --font /path/to/font.otf"
    exit 1
}
set otfBold [findFont {/usr/share/fonts/opentype/tlwg/Loma-Bold.otf}]
set ttfFile [findFont {
    /usr/share/fonts/truetype/dejavu/DejaVuSans.ttf
    /usr/share/fonts/TTF/DejaVuSans.ttf
}]

puts "OTF font:      $otfFile"
puts "OTF bold:      [expr {$otfBold ne {} ? $otfBold : {(not found)}}]"
puts "TTF reference: [expr {$ttfFile ne {} ? $ttfFile : {(not found)}}]"

# ---------------------------------------------------------------------------
# Load fonts
# font names are literal strings passed to setFont, not Tcl variables
# ---------------------------------------------------------------------------
pdf4tcl::loadBaseTrueTypeFont MainOTF $otfFile
pdf4tcl::createFontSpecCID MainOTF cidMain      ;# font name: "cidMain"

set hasBold 0
if {$otfBold ne ""} {
    pdf4tcl::loadBaseTrueTypeFont BoldOTF $otfBold
    pdf4tcl::createFontSpecCID BoldOTF cidBold  ;# font name: "cidBold"
    set hasBold 1
}
set hasTTF 0
if {$ttfFile ne ""} {
    pdf4tcl::loadBaseTrueTypeFont RefTTF $ttfFile
    pdf4tcl::createFontSpecCID RefTTF cidTTF    ;# font name: "cidTTF"
    set hasTTF 1
}

# ---------------------------------------------------------------------------
# PDF setup
# ---------------------------------------------------------------------------
set outFile [file join $outDir demo-otf.pdf]
set pdf [::pdf4tcl::new %AUTO% -paper a4 -orient 1]

set pageW 595.28
set pageH 841.89
set M     50
set TW    [expr {$pageW - 2*$M}]

# Helper procs -- font name passed explicitly, no globals needed
proc hline {pdf y} {
    global M TW
    $pdf setStrokeColor 0.7 0.7 0.7
    $pdf setLineWidth 0.5
    $pdf line $M $y [expr {$M + $TW}] $y
    $pdf setStrokeColor 0 0 0
    $pdf setLineWidth 1
}

proc heading {pdf y text {size 14}} {
    global M
    $pdf setFont $size cidMain
    $pdf setFillColor 0.1 0.2 0.5
    $pdf text $text -x $M -y $y
    $pdf setFillColor 0 0 0
}

proc body {pdf y text {size 11}} {
    global M
    $pdf setFont $size cidMain
    $pdf text $text -x $M -y $y
}

proc section {pdf yVar title chars {size 12}} {
    global M
    upvar $yVar y
    $pdf setFont 11 cidMain
    $pdf setFillColor 0.2 0.4 0.2
    $pdf text $title -x $M -y $y
    $pdf setFillColor 0 0 0
    incr y 18
    $pdf setFont $size cidMain
    $pdf text $chars -x $M -y $y
    incr y 28
}

# ===========================================================================
# Page 1: Font loading info and PDF structure
# ===========================================================================
$pdf startPage

heading $pdf 60 "pdf4tcl 0.9.4.15 -- OTF/CFF Font Support" 18
hline $pdf 75

body $pdf 95  "pdf4tcl can now load OpenType fonts with CFF outlines (.otf files)." 12
body $pdf 113 "Previously these fonts caused: \"TTF: postscript outlines are not supported\"" 10
body $pdf 128 "The fix recognises the OTTO magic number and uses CIDFontType0 embedding." 10

hline $pdf 143

# Font metadata table
heading $pdf 158 "Loaded Font Information" 12

set y 178
set col2 210
foreach {label value} [list \
    "Font file"         [file tail $otfFile] \
    "isCFF flag"        $::pdf4tcl::BFA(MainOTF,isCFF) \
    "PS Name"           $::pdf4tcl::BFA(MainOTF,psName) \
    "unitsPerEm"        $::pdf4tcl::BFA(MainOTF,unitsPerEm) \
    "Glyphs (hmetrics)" [llength $::pdf4tcl::BFA(MainOTF,hmetrics)] \
    "CharWidths entries" [dict size $::pdf4tcl::BFA(MainOTF,charWidths)] \
    "Ascent"            [expr {int($::pdf4tcl::BFA(MainOTF,ascend))}] \
    "Descent"           [expr {int($::pdf4tcl::BFA(MainOTF,descend))}] \
] {
    $pdf setFont 10 cidMain
    $pdf setFillColor 0.35 0.35 0.35
    $pdf text $label -x $M -y $y
    $pdf setFillColor 0 0 0
    $pdf text $value -x $col2 -y $y
    incr y 16
}

hline $pdf [expr {$y + 8}]
incr y 23

# PDF structure comparison
heading $pdf $y "PDF Object Structure: TTF vs OTF" 12
incr y 20

$pdf setFont 10 cidMain
foreach line {
    "TTF:  /Subtype /CIDFontType2     /FontFile2  (raw TTF, requires /Length1)"
    "OTF:  /Subtype /CIDFontType0     /FontFile3 with /Subtype /OpenType"
    ""
    "Both use /Encoding /Identity-H and a full ToUnicode CMap (beginbfchar)."
    "CIDFontType0 omits /CIDToGIDMap -- not applicable to CFF outline fonts."
} {
    $pdf text $line -x $M -y $y
    incr y 14
}

$pdf endPage

# ===========================================================================
# Page 2: Font sizes, getStringWidth, two-font comparison
# ===========================================================================
$pdf startPage

heading $pdf 60 "Page 2 -- Font Sizes and Metrics" 16
hline $pdf 75

set y 95
foreach size {8 10 12 14 18 24} {
    $pdf setFont $size cidMain
    $pdf text "OTF at ${size}pt -- The quick brown fox jumps over the lazy dog" -x $M -y $y
    incr y [expr {$size + 8}]
}

hline $pdf [expr {$y + 5}]
incr y 20

heading $pdf $y "getStringWidth (size 12pt)" 12
incr y 20
$pdf setFont 10 cidMain
foreach str {"A" "Hello" "Hello World" "The quick brown fox jumps over the lazy dog"} {
    $pdf setFont 12 cidMain
    set w [$pdf getStringWidth $str]
    $pdf setFont 10 cidMain
    $pdf text [format "  %-44s -> %6.2f pt" "\"$str\"" $w] -x $M -y $y
    incr y 16
}

if {$hasBold} {
    hline $pdf [expr {$y + 8}]
    incr y 23
    heading $pdf $y "Two OTF fonts in same PDF (Regular + Bold)" 12
    incr y 20
    $pdf setFont 16 cidMain
    $pdf text "Regular: The quick brown fox" -x $M -y $y
    incr y 24
    $pdf setFont 16 cidBold
    $pdf text "Bold:    The quick brown fox" -x $M -y $y
    incr y 24
    $pdf setFont 10 cidMain
    $pdf text "Both embedded as /CIDFontType0 /FontFile3 /Subtype /OpenType" -x $M -y $y
}

if {$hasTTF} {
    hline $pdf [expr {$y + 15}]
    incr y 30
    heading $pdf $y "OTF vs TTF (both embedded in same PDF)" 12
    incr y 20
    $pdf setFont 13 cidMain
    $pdf text "This line: OTF font -> /CIDFontType0 / /FontFile3 / /Subtype /OpenType" -x $M -y $y
    incr y 20
    $pdf setFont 13 cidTTF
    $pdf text "This line: TTF font -> /CIDFontType2 / /FontFile2 / /Length1 (unchanged)" -x $M -y $y
}

$pdf endPage

# ===========================================================================
# Page 3: Unicode coverage
# ===========================================================================
$pdf startPage

heading $pdf 60 "Page 3 -- Unicode Character Coverage" 16
hline $pdf 75

set y 95
body $pdf $y "Characters from the font's cmap table, rendered via Identity-H encoding and ToUnicode CMap:" 10
incr y 22

section $pdf y "Basic Latin" \
    "ABCDEFGHIJKLMNOPQRSTUVWXYZ   abcdefghijklmnopqrstuvwxyz   0123456789" 12

section $pdf y "Latin Extended (diacritics)" \
    "\u00C0\u00C1\u00C2\u00C4\u00C5\u00C6\u00C7\u00C8\u00C9\u00CA\u00CB  \u00CC\u00CD\u00CE\u00CF\u00D0\u00D1\u00D2\u00D3\u00D4\u00D6\u00D8\u00DC  \u00DF\u00E0\u00E1\u00E2\u00E4\u00E5\u00E6\u00E7\u00E8\u00E9\u00EA\u00EB\u00F1\u00F6\u00FC" 14

section $pdf y "Punctuation and symbols" \
    "\u2018\u2019\u201C\u201D  \u2013\u2014  \u2022\u2026  \u20AC\u00A3\u00A5  \u00A9\u00AE\u2122  \u00B0\u00B1\u00D7\u00F7" 14

# Thai only if Loma
if {[string match "*Loma*" $otfFile] || [string match "*loma*" $otfFile]} {
    section $pdf y "Thai script (Loma OTF)" \
        "\u0E2A\u0E27\u0E31\u0E2A\u0E14\u0E35  \u0E40\u0E21\u0E37\u0E2D\u0E07\u0E44\u0E17\u0E22  \u0E01\u0E02\u0E04\u0E07\u0E08\u0E0A\u0E0D\u0E10\u0E14\u0E15\u0E19\u0E1A\u0E1C\u0E21\u0E22\u0E23\u0E25\u0E27\u0E2A\u0E2D" 16
}

hline $pdf [expr {$y + 8}]
incr y 23
$pdf setFont 9 cidMain
$pdf setFillColor 0.5 0.5 0.5
$pdf text "Font: [file tail $otfFile]  |  pdf4tcl 0.9.4.15  |  OTF/CFF support via CIDFontType0" \
    -x $M -y $y
$pdf setFillColor 0 0 0

$pdf endPage

# ---------------------------------------------------------------------------
# Write output
# ---------------------------------------------------------------------------
$pdf finish
$pdf write -file $outFile
$pdf destroy

puts "Output: $outFile  ([file size $outFile] bytes, 3 pages)"
