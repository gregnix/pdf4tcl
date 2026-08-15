#!/usr/bin/env tclsh
# tutorial-07-multilingual.tcl -- one document, several scripts
#
#   tclsh tutorial-07-multilingual.tcl [outdir]

source [file join [file dirname [info script]] ../_bootstrap.tcl]
pdf4tcl::doc::init [info script]

set fontFile [pdf4tcl::doc::needFont dejavu]
pdf4tcl::loadBaseTrueTypeFont Base $fontFile
pdf4tcl::createFontSpecCID Base Uni

# ---------------------------------------------------------------------------
# Step 1 -- know what the font can paint, before writing anything
# ---------------------------------------------------------------------------

proc glyphAvailable {baseName codepoint} {
    return [dict exists $::pdf4tcl::BFA($baseName,charToGlyph) $codepoint]
}

proc missingGlyphs {baseName text} {
    set missing {}
    foreach ch [split $text {}] {
        scan $ch %c n
        if {![glyphAvailable $baseName $n]} { lappend missing $n }
    }
    return $missing
}

# The greeting in five languages, plus one line the font cannot do.
set rows {
    "English"   "Good morning"
    "German"    "Guten Morgen -- Grüße aus München"
    "Polish"    "Dzień dobry -- Zażółć gęślą jaźń"
    "Greek"     "Καλημέρα -- Ελληνικά κείμενα"
    "Russian"   "Доброе утро -- Русский текст"
    "Japanese"  "おはよう -- 日本語"
}

# ---------------------------------------------------------------------------
# Step 2 -- the document
# ---------------------------------------------------------------------------

set pdf [::pdf4tcl::new %AUTO% -paper a4 -orient 1 -margin 50]
$pdf startPage

$pdf setFont 16 Uni
$pdf text "A document in five scripts" -x 0 -y 20

$pdf setFont 8 Uni
$pdf text "Font: [file tail $fontFile] -- Tcl [info patchlevel]" -x 0 -y 36

# Two columns: language, greeting. A third column records what the check
# above found, so the page itself shows where the font runs out.
set y 70
$pdf setFont 11 Uni
foreach {lang text} $rows {
    set missing [missingGlyphs Base $text]

    $pdf setFont 11 Uni
    $pdf text $lang -x 0 -y $y
    $pdf text $text -x 90 -y $y

    if {[llength $missing] > 0} {
        $pdf setFont 8 Uni
        $pdf text "[llength $missing] glyphs missing" -x 340 -y $y
    }
    incr y 22
}

# ---------------------------------------------------------------------------
# Step 3 -- mixing fonts: standard font for the bulk, CID for the exception
# ---------------------------------------------------------------------------

incr y 20
$pdf setFont 12 Helvetica
$pdf text "Mixed: Helvetica for the label, " -x 0 -y $y
set w [$pdf getStringWidth "Mixed: Helvetica for the label, "]
$pdf setFont 12 Uni
$pdf text "Ελλάδα for the value" -x $w -y $y

# getStringWidth measures in points and works across fonts -- that is what
# makes the position above correct in both Tcl generations. Counting
# characters would not be: a surrogate pair is two characters under 8.6 and
# one under 9.
incr y 24
$pdf setFont 8 Uni
$pdf text "Position from getStringWidth ([format %.1f $w] pt), not from string length" -x 0 -y $y

# ---------------------------------------------------------------------------
# Step 4 -- what the standard font does with the same text
# ---------------------------------------------------------------------------

incr y 30
$pdf setFont 11 Helvetica
$pdf text "The same lines in Helvetica:" -x 0 -y $y
incr y 18
foreach {lang text} $rows {
    $pdf setFont 10 Helvetica
    $pdf text $text -x 0 -y $y
    incr y 16
}
incr y 4
$pdf setFont 8 Uni
# The counter only works under Tcl 9. On 8.6 "encoding convertto" replaces
# silently instead of raising an error, so pdf4tcl never sees the failure --
# the page still shows "?", the number just stays at zero. Measured.
set n [$pdf getSubstCount]
if {$n > 0} {
    $pdf text "$n characters were replaced by '?' above" -x 0 -y $y
} else {
    $pdf text "getSubstCount reports 0 -- expected under Tcl 8.6, where\
            encoding convertto substitutes without an error" -x 0 -y $y
}

$pdf endPage
set out [pdf4tcl::doc::outfile tutorial-07-multilingual.pdf]
$pdf write -file $out
$pdf destroy

puts "substitutions in the Helvetica block are counted on the page itself"
pdf4tcl::doc::done $out
