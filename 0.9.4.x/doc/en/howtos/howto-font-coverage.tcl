#!/usr/bin/env tclsh
# howto-font-coverage.tcl -- which characters does this font actually paint?
#
#   tclsh howto-font-coverage.tcl [outdir]
#
# Writes a report PDF and prints the same findings to stdout. Pass a font
# path as the second argument to check a different file:
#
#   tclsh howto-font-coverage.tcl "" /usr/share/fonts/truetype/freefont/FreeSerif.ttf

source [file join [file dirname [info script]] ../_bootstrap.tcl]
pdf4tcl::doc::init [info script]

set fontFile [lindex $argv 1]
if {$fontFile eq ""} {
    set fontFile [pdf4tcl::doc::needFont dejavu]
}
pdf4tcl::loadBaseTrueTypeFont Base $fontFile
pdf4tcl::createFontSpecCID Base Uni

# The whole check. A CID font can encode any codepoint; whether the font has
# a picture for it is a different question, and this is the only way to ask.
proc glyphAvailable {baseName codepoint} {
    return [dict exists $::pdf4tcl::BFA($baseName,charToGlyph) $codepoint]
}

# Which codepoints of a string the font cannot paint.
proc missingGlyphs {baseName text} {
    set missing {}
    foreach ch [split $text {}] {
        scan $ch %c n
        if {![glyphAvailable $baseName $n]} {
            lappend missing $n
        }
    }
    return $missing
}

set samples {
    "Latin"         "Grüße aus München"
    "Latin ext"     "Zażółć gęślą jaźń"
    "Greek"         "Ελληνικά κείμενα"
    "Cyrillic"      "Русский текст"
    "Maths"         "∑ ∫ ≤ ≥ ± ∞ √"
    "Arrows"        "← ↑ → ↓ ⇒ ⇔"
    "Box drawing"   "┌─┬─┐ │ ├─┼─┤"
    "Dingbats"      "✓ ✗ ★ ☎ ✉"
    "CJK"           "日本語 中文"
    "Hebrew"        "שלום"
    "Arabic"        "مرحبا"
    "Emoji"         "\U0001F600\U0001F4C4"
}

set pdf [::pdf4tcl::new %AUTO% -paper a4 -orient 1 -margin 40]
$pdf startPage
$pdf setFont 14 Uni
$pdf text "Font coverage: [file tail $fontFile]" -x 0 -y 20
$pdf setFont 8 Uni
$pdf text "Tcl [info patchlevel] -- pdf4tcl [package provide pdf4tcl]" -x 0 -y 34

set y 60
$pdf setFont 10 Uni
foreach {label text} $samples {
    set missing [missingGlyphs Base $text]
    if {[llength $missing] == 0} {
        set verdict "complete"
    } else {
        set codes {}
        foreach n [lrange $missing 0 3] { lappend codes "U+[format %04X $n]" }
        if {[llength $missing] > 4} { lappend codes "..." }
        set verdict "[llength $missing] missing: [join $codes { }]"
    }
    puts [format "  %-12s %-24s %s" $label $text $verdict]

    $pdf text $label -x 0 -y $y
    $pdf text $text -x 90 -y $y
    $pdf setFont 8 Uni
    $pdf text $verdict -x 260 -y $y
    $pdf setFont 10 Uni
    incr y 18
}

# A missing glyph is not an error and not a substitution: it becomes glyph 0
# and getSubstCount stays at zero. Shown here so the difference is on record.
incr y 12
$pdf setFont 9 Uni
$pdf text "getSubstCount after all of the above: [$pdf getSubstCount]" -x 0 -y $y
incr y 14
$pdf text "A CID font encodes every codepoint -- the counter only sees encoding" -x 0 -y $y
incr y 12
$pdf text "substitutions, which cannot happen here. Check coverage instead." -x 0 -y $y

$pdf endPage
set out [pdf4tcl::doc::outfile howto-font-coverage.pdf]
$pdf write -file $out
$pdf destroy
pdf4tcl::doc::done $out
