namespace eval pdf4tcl {
    # AcroForm field flags (/Ff) - PDF Reference Table 8.70 ff.
    variable Ff_READONLY       1       ;# Bit 1:  ReadOnly
    variable Ff_REQUIRED       2       ;# Bit 2:  Required
    variable Ff_NOEXPORT       4       ;# Bit 3:  NoExport
    variable Ff_MULTILINE   4096       ;# Bit 13: Multiline (Tx)
    variable Ff_PASSWORD    8192       ;# Bit 14: Password (Tx)
    variable Ff_NOTOGGLEOFF 16384      ;# Bit 15: NoToggleToOff (Btn/Radio)
    variable Ff_RADIO       32768      ;# Bit 16: Radio (Btn)
    variable Ff_PUSHBUTTON  65536      ;# Bit 17: Pushbutton (Btn)
    variable Ff_COMBO       131072     ;# Bit 18: Combo (Ch)
    variable Ff_EDIT        262144     ;# Bit 19: Edit (Ch)
    variable Ff_SORT        524288     ;# Bit 20: Sort (Ch)
    variable Ff_MULTISELECT 2097152    ;# Bit 22: MultiSelect (Ch)
    variable Ff_COMB       16777216    ;# Bit 25: Comb (Tx, needs /MaxLen)

    # rgb2Cmyk and cmyk2Rgb moved to src/color.tcl.
}

#######################################################################
# Helpers
#######################################################################

# This must create optionally compressed PDF stream.
# dictval must contain correct string value without >> terminator.
# Terminator and length will be added by this proc.
proc ::pdf4tcl::MakeStream {dictval body compress} {
    set res $dictval
    if {$compress} {
        set body2 [zlib compress $body]
        # Any win?
        if {[string length $body2] + 20 < [string length $body]} {
            append res "\n/Filter \[/FlateDecode\]"
            set body $body2
        }
    }
    set len [string length $body]
    append res "\n/Length $len\n>>\nstream\n"
    append res $body
    append res "\nendstream"
    return $res
}

# Write a string as a PDF name (ISO 32000-1 clause 7.3.5).
#
# A name carries regular characters as they are; whitespace, the
# delimiters, the number sign itself and everything outside 0x21..0x7e
# have to be written as a number sign followed by two hex digits.
#
# This matters for font resource names, which pdf4tcl takes from the
# caller. A font loaded as "DejaVu Sans" used to be written as
# "/DejaVu Sans 15 Tf" -- the space ends the name, the rest is garbage,
# and the page shows nothing at all. No error was raised anywhere.
proc ::pdf4tcl::PdfName {name} {
    set res ""
    # Names are byte strings, so a character above U+007F contributes its
    # UTF-8 bytes, each escaped.
    binary scan [encoding convertto utf-8 $name] cu* bytes
    foreach byte $bytes {
        set ch [format %c $byte]
        if {$byte > 0x20 && $byte < 0x7f &&
                $ch ni {"#" "(" ")" "<" ">" "\[" "\]" "\{" "\}" "/" "%"}} {
            append res $ch
        } else {
            append res [format "#%02x" $byte]
        }
    }
    return $res
}

# This procedure determines the number of open items of an outline
# dictionary object.
proc ::pdf4tcl::BookmarkCount {bookmarks level} {
    set count 0

    # Increment the count if the bookmark is not closed.
    foreach bookmark $bookmarks {
        if {[lindex $bookmark 1] <= $level} {break}
        if {! [lindex $bookmark 2]} {
            incr count
        }
    }

    return $count
}

# This procedure determines the properties for an outline item dictionary
# object.
proc ::pdf4tcl::BookmarkProperties {oid current bookmarks n f l c} {
    upvar 1 $n next $f first $l last $c count

    set next  {}
    set first {}
    set last  {}

    # Determine the number of open descendants.
    set count [BookmarkCount $bookmarks $current]

    set child [expr {$current + 1}]

    set n 0
    foreach bookmark $bookmarks {
        incr n

        set level [lindex $bookmark 1]

        if {$level < $current} {break}

        # Determine the object ID for the next bookmark at the same level.
        if {$next == {}} {
            if {$level == $current} {
                set next [expr {$oid + $n}]
                continue
            }

            # Determine the object ID for the first and last child
            # bookmarks.
            if {$level == $child} {
                if {$first == {}} {
                    set first [expr {$oid + $n}]
                }
                set last [expr {$oid + $n}]
            }
        }
    }
}

proc ::pdf4tcl::MulVxM {vector matrix} {
    foreach {x y} $vector break
    foreach {a b c d e f} $matrix break
    lappend res [expr {$a*$x + $c*$y + $e}]
    lappend res [expr {$b*$x + $d*$y + $f}]
    return $res
}

proc ::pdf4tcl::MulMxM {m1 m2} {
    foreach {a1 b1 c1 d1 e1 f1} $m1 break
    foreach {a2 b2 c2 d2 e2 f2} $m2 break
    lappend res [expr {$a1*$a2 + $b1*$c2}]
    lappend res [expr {$a1*$b2 + $b1*$d2}]
    lappend res [expr {$c1*$a2 + $d1*$c2}]
    lappend res [expr {$c1*$b2 + $d1*$d2}]
    lappend res [expr {$e1*$a2 + $f1*$c2 + $e2}]
    lappend res [expr {$e1*$b2 + $f1*$d2 + $f2}]
    return $res
}

# rotate by phi, scale with rx/ry and move by (dx, dy)
proc ::pdf4tcl::Transform {rx ry phi dx dy points} {
    set cos_phi [expr {cos($phi)}]
    set sin_phi [expr {sin($phi)}]
    set res [list]
    foreach {x y} $points {
        set xn [expr {$rx * ($x*$cos_phi - $y*$sin_phi) + $dx}]
        set yn [expr {$ry * ($x*$sin_phi + $y*$cos_phi) + $dy}]
        lappend res $xn $yn
    }
    return $res
}

# Create a four-point spline that forms an arc along the unit circle
# from angle -phi2 to +phi2 (where phi2 is in radians)
proc ::pdf4tcl::Simplearc {phi2} {
    set x0 [expr {cos($phi2)}]
    set y0 [expr {-sin($phi2)}]
    set x3 $x0
    set y3 [expr {-$y0}]
    set x1 [expr {0.3333*(4.0-$x0)}]
    set y1 [expr {(1.0-$x0)*(3.0-$x0)/(3.0*$y0)}]
    set x2 $x1
    set y2 [expr {-$y1}]
    return [list $x0 $y0 $x1 $y1 $x2 $y2 $x3 $y3]
}

# Utility for translating dash patterns - if needed
proc ::pdf4tcl::CanvasMakeDashPattern {pattern linewidth} {
    # If numeric, return the same
    if { ! [regexp {[.,-_]} $pattern] } {
        return $pattern
    }
    # A pattern adapts to line width
    set linewidth [expr {int($linewidth + 0.5)}]
    if {$linewidth < 1} {
        set linewidth 1
    }
    set lw2 [expr {2 * $linewidth}]
    set lw4 [expr {4 * $linewidth}]
    set lw6 [expr {6 * $linewidth}]
    set lw8 [expr {8 * $linewidth}]
    # Translate each character
    set newPattern {}
    foreach c [split $pattern ""] {
        switch $c {
            " " {
                if { [llength $newPattern] > 0 } {
                    set lastNumber [expr {$lw4 + [lindex $newPattern end]}]
                    set newPattern [lreplace $newPattern end end $lastNumber]
                }
            }
            "." {
                lappend newPattern $lw2 $lw4
            }
            "," {
                lappend newPattern $lw4 $lw4
            }
            "-" {
                lappend newPattern $lw6 $lw4
            }
            "_" {
                lappend newPattern $lw8 $lw4
            }
        }
    }
    return $newPattern
}

# Helper to extract configuration from a canvas item
proc ::pdf4tcl::CanvasGetOpts {path id arrName} {
    upvar 1 $arrName arr
    array unset arr
    foreach item [$path itemconfigure $id] {
        set arr([lindex $item 0]) [lindex $item 4]
    }
    if {![info exists arr(-state)]} {
        return
    }
    if {$arr(-state) eq "" || $arr(-state) eq "normal"} {
        return
    }
    # Translate options depending on state
    set state $arr(-state)
    foreach item [array names arr] {
        if {[regexp -- "^-${state}(.*)\$" $item -> orig]} {
            if {[info exists arr(-$orig)]} {
                set arr(-$orig) $arr($item)
            }
        }
    }
}

# Get the text from a text item, as a list of lines
# This takes and line wrapping into account
proc ::pdf4tcl::CanvasGetWrappedText {w item ulName} {
    upvar 1 $ulName underline
    set text  [$w itemcget $item -text]
    set width [$w itemcget $item -width]
    set underline [$w itemcget $item -underline]

    # 8.7 changes underline index (TIP 577)
    # Empty string is the same as -1
    if {$underline eq ""} {
        set underline -1
    }
    if {![string is integer $underline]} {
        # Support end-style index, if lseq is available (8.7+)
        try {
            # Try to translate end-style index
            set len [string length $text]
            set i [lindex [lseq $len] $underline]
            set underline $i
        } on error {} {
            set underline -1
        }
    }

    # Simple non-wrapping case. Only divide on newlines.
    if {$width == 0} {
        set lines [split $text \n]
        if {$underline != -1} {
            set isum 0
            set lineNo 0
            foreach line $lines {
                set iend [expr {$isum + [string length $line]}]
                if {$underline < $iend} {
                    set underline [list $lineNo [expr {$underline - $isum}]]
                    break
                }
                incr lineNo
                set isum [expr {$iend + 1}]
            }
        }
        return $lines
    }

    # Run across the text's left side and look for all indexes
    # that start a line.

    foreach {x1 y1 x2 y2} [$w bbox $item] break
    set firsts {}
    for {set y $y1} {$y < $y2} {incr y} {
        lappend firsts [$w index $item @$x1,$y]
    }
    set firsts [lsort -integer -unique $firsts]

    # Extract each displayed line
    set prev 0
    set res {}
    foreach index $firsts {
        if {$prev != $index} {
            set line [string range $text $prev [expr {$index - 1}]]
            if {[string index $line end] eq "\n"} {
                set line [string trimright $line \n]
            } else {
                # If the line does not end with \n it is wrapped.
                # Then spaces should be discarded
                set line [string trimright $line]
            }
            lappend res $line
        }
        set prev $index
    }
    # The last chunk
    lappend res [string range $text $prev end]
    if {$underline != -1} {
        set lineNo -1
        set prev 0
        foreach index $firsts {
            if {$underline < $index} {
                set underline [lindex $lineNo [expr {$underline - $prev}]]
                break
            }
            set prev $index
            incr lineNo
        }
    }
    return $res
}

proc ::pdf4tcl::Swap {aName bName} {
    upvar 1 $aName a $bName b
    set tmp $a
    set a   $b
    set b   $tmp
}

# Encode a Unicode string for a CID font (Identity-H).
# Returns a PDF hex string <GGGG...> using original GlyphIDs.
# Records which characters each glyph stands for, in
# FontsAttrs($fn,glyphChars).
# Report a codepoint the font cannot draw -- once per font and codepoint,
# so a page of Chinese in a Latin font gives a handful of lines rather than
# one per character.
#
# Warning rather than error: every existing document that puts up with a
# .notdef box or a question mark keeps working. For the strict case there
# is getSubstCount, which counts both paths.
proc ::pdf4tcl::NoteMissingGlyph {basefont codepoint {shown .notdef}} {
    variable missingGlyphSeen
    set key "$basefont,$codepoint"
    if {[info exists missingGlyphSeen($key)]} { return }
    set missingGlyphSeen($key) 1
    lappend ::pdf4tcl::warnings [format \
            "font %s cannot represent U+%04X -- drawn as %s" \
            $basefont $codepoint $shown]
}

proc ::pdf4tcl::CIDEncodeText {in fn {ligatures 0}} {
    variable ::pdf4tcl::FontsAttrs
    variable ::pdf4tcl::BFA
    set BFN $FontsAttrs($fn,basefontname)

    set glyphs {}
    set chars {}
    foreach ch [split $in {}] {
        scan $ch %c n
        if {[dict exists $BFA($BFN,charToGlyph) $n]} {
            lappend glyphs [dict get $BFA($BFN,charToGlyph) $n]
            lappend chars [list $n]
        } else {
            # The font has no glyph for this codepoint. Count it like the
            # subset path does, and say so once per codepoint and font --
            # a .notdef box is easy to miss in a long document, and the
            # text simply is not what the caller passed in.
            lappend glyphs 0        ;# render as .notdef box
            lappend chars {}        ;# no CMap entry
            incr ::pdf4tcl::substCount
            NoteMissingGlyph $BFN $n
        }
    }

    if {$ligatures} { ApplyLigatures $BFN glyphs chars }

    set hex ""
    foreach glyph $glyphs char $chars {
        # Record real glyphs only. GlyphID 0 (.notdef) has no Unicode
        # mapping and must not appear in the ToUnicode CMap.
        if {$glyph != 0 && [llength $char]} {
            dict set FontsAttrs($fn,glyphChars) $glyph $char
        }
        append hex [format %04X $glyph]
    }
    return "<$hex>"
}

# Apply standard ligatures to a glyph run.
#
# Takes lists of glyphs and of the characters each stands for; returns the
# same two, with runs replaced by their ligature glyph. The character list
# of a ligature holds ALL the characters it replaces -- that is what makes
# the text extractable afterwards.
#
# Longest match wins, and matching restarts after the replacement, so
# "ffi" becomes one glyph rather than "f" plus "fi".
proc ::pdf4tcl::ApplyLigatures {BFN glyphsVar charsVar} {
    variable ::pdf4tcl::BFA
    upvar 1 $glyphsVar glyphs $charsVar chars
    if {![info exists BFA($BFN,ligatures)]
            || ![dict size $BFA($BFN,ligatures)]} { return 0 }
    set ligs $BFA($BFN,ligatures)

    set outG {}
    set outC {}
    set n [llength $glyphs]
    set i 0
    set ersetzt 0
    while {$i < $n} {
        set g [lindex $glyphs $i]
        set treffer 0
        if {[dict exists $ligs $g]} {
            foreach eintrag [dict get $ligs $g] {
                lassign $eintrag folger ligGlyph
                set k [llength $folger]
                # Not enough glyphs left for this ligature.
                if {$i + $k > $n - 1} { continue }
                set passt 1
                for {set j 0} {$j < $k} {incr j} {
                    if {[lindex $glyphs [expr {$i + 1 + $j}]] != [lindex $folger $j]} {
                        set passt 0
                        break
                    }
                }
                if {!$passt} { continue }
                # All the characters the ligature stands for, in order.
                set zeichen {}
                for {set j 0} {$j <= $k} {incr j} {
                    foreach c [lindex $chars [expr {$i + $j}]] { lappend zeichen $c }
                }
                lappend outG $ligGlyph
                lappend outC $zeichen
                incr i [expr {$k + 1}]
                set treffer 1
                set ersetzt 1
                break
            }
        }
        if {!$treffer} {
            lappend outG $g
            lappend outC [lindex $chars $i]
            incr i
        }
    }
    set glyphs $outG
    set chars $outC
    return $ersetzt
}

# The next glyph that takes part in kerning, starting at index i+1, or -1.
#
# A lookup may ask for marks to be skipped (lookupFlag bit 3). Then
# "A" + U+0301 + "V" kerns as the pair A V, which is what the font
# intends -- the accent sits above the A and does not change the gap.
#
# The flag belongs to the LOOKUP the pair came from, not to the face, so
# the immediate neighbour is tried first: if A and the accent kern, that
# pair wins and nothing is skipped. Only when there is no adjustment there
# is the mark stepped over, and then only if the pair found beyond it
# carries the flag. A font-wide flag used to make every pair skip marks,
# including those from lookups without it and from the kern table, which
# has no lookup flags at all.
proc ::pdf4tcl::NextKernGlyph {BFN glyphs i} {
    set n [llength $glyphs]
    set j [expr {$i + 1}]
    if {$j >= $n} { return -1 }

    # The direct neighbour, whatever it is.
    lassign [GetKernPairInfo $BFN [lindex $glyphs $i] [lindex $glyphs $j]] v
    if {$v != 0} { return $j }
    if {![IsMarkGlyph $BFN [lindex $glyphs $j]]} { return $j }

    # A mark with no pair of its own: look past it, and take what is
    # beyond only if THAT lookup asks for marks to be ignored.
    for {set k [expr {$j + 1}]} {$k < $n} {incr k} {
        if {[IsMarkGlyph $BFN [lindex $glyphs $k]]} { continue }
        lassign [GetKernPairInfo $BFN [lindex $glyphs $i] \
                [lindex $glyphs $k]] v2 ignore
        if {$v2 != 0 && $ignore} { return $k }
        return $j
    }
    return $j
}

# The sum of the kerning adjustments of a string, in 1/1000 em.
#
# Negative where the line gets tighter, which is the normal case. Added to
# the measured width so that measuring and drawing use the same number.
proc ::pdf4tcl::KernWidth {fn in {stdAllowed 0}} {
    variable ::pdf4tcl::FontsAttrs
    variable ::pdf4tcl::BFA
    if {![info exists FontsAttrs($fn,basefontname)]} { return 0 }
    if {!$stdAllowed && (![info exists FontsAttrs($fn,type)]
            || $FontsAttrs($fn,type) ne "CID")} { return 0 }
    set BFN $FontsAttrs($fn,basefontname)
    # The class tables count as well. A face that keeps its kerning only
    # as GPOS classes has no individual pairs at all -- Carlito is one,
    # and testing kernPairs alone set it unkerned although GetKernPair
    # returns values.
    if {(![info exists BFA($BFN,kernPairs)] || ![dict size $BFA($BFN,kernPairs)])
            && (![info exists BFA($BFN,kernClasses)]
                || ![llength $BFA($BFN,kernClasses)])} {
        return 0
    }
    # For an embedded face the keys are GLYPH ids; for the standard 14
    # they are UNICODE numbers, which is how the pairs generated from the
    # AFM files are stored, matching charWidths. What tells the two apart
    # is whether a charToGlyph mapping exists.
    set hatGlyphen [info exists BFA($BFN,charToGlyph)]
    set glyphs {}
    foreach ch [split $in {}] {
        scan $ch %c n
        if {!$hatGlyphen} {
            lappend glyphs $n
        } elseif {[dict exists $BFA($BFN,charToGlyph) $n]} {
            lappend glyphs [dict get $BFA($BFN,charToGlyph) $n]
        } else {
            lappend glyphs 0
        }
    }
    set summe 0.0
    for {set i 0} {$i < [llength $glyphs]} {incr i} {
        # Eine Mark, die gerade uebersprungen wurde, darf nicht selbst
        # noch einmal als linkes Glyph zaehlen -- sonst wird zweimal
        # addiert. Ob sie uebersprungen WIRD, entscheidet NextKernGlyph
        # je Paar; hier genuegt zu wissen, dass es eine Mark ohne eigenes
        # Paar zum Vorgaenger ist.
        if {$i > 0 && [IsMarkGlyph $BFN [lindex $glyphs $i]]
                && [lindex [GetKernPairInfo $BFN [lindex $glyphs [expr {$i-1}]] \
                        [lindex $glyphs $i]] 0] == 0} { continue }
        set j [NextKernGlyph $BFN $glyphs $i]
        if {$j < 0} { break }
        set summe [expr {$summe + [GetKernPair $BFN [lindex $glyphs $i] \
                [lindex $glyphs $j]]}]
    }
    return $summe
}

# The same string as a TJ array with the pair kerning applied.
#
# Returns the empty string when there is nothing to apply -- the caller then
# writes a plain Tj, so a document without kerning comes out byte-identical
# to before.
#
# Only for CID fonts. The fourteen standard faces carry no pairs (their AFM
# kern data is not read), and a simple font would need the adjustment in its
# own encoding, which is a separate matter.
#
# Sign: a negative number in the kern table moves the pair TOGETHER, and a
# positive number in a TJ array moves the pen BACK. So the value is negated
# on the way in -- getting this backwards spreads exactly the pairs that
# should be tightened, which looks deliberate and is the reason this is
# spelled out here.
# stdAllowed: kern the standard 14 as well? Off by default, see setKerning.
# Build the glyph run that gets drawn, once, so that measuring and drawing
# cannot disagree.
#
# Order matters and used to be wrong: PdfTextKerned split the string on the
# glyphs BEFORE ligature substitution and passed the ligature flag only to
# the last piece. "ffi" in Carlito came out as f + kern + fi instead of the
# ffi glyph, although ApplyLigatures says longest match wins -- the kerning
# split undid it. And getStringWidth never looked at ligatures at all, so a
# line measured wider than it was drawn.
#
# Returns {glyphs chars}: the glyph ids in drawing order, and for each one
# the list of codepoints it stands for (a ligature carries several). For a
# standard-14 font there is no glyph mapping and the codepoints ARE the
# keys -- the AFM kern pairs are keyed by Unicode.
proc ::pdf4tcl::ShapeRun {in fn {ligatures 0}} {
    variable ::pdf4tcl::FontsAttrs
    variable ::pdf4tcl::BFA
    if {![info exists FontsAttrs($fn,basefontname)]} { return [list {} {}] }
    set BFN $FontsAttrs($fn,basefontname)
    set istCID [expr {[info exists FontsAttrs($fn,type)]
            && $FontsAttrs($fn,type) eq "CID"}]

    set glyphs {}
    set chars {}
    foreach ch [split $in {}] {
        scan $ch %c n
        if {!$istCID} {
            lappend glyphs $n
            lappend chars [list $n]
            continue
        }
        if {[dict exists $BFA($BFN,charToGlyph) $n]} {
            lappend glyphs [dict get $BFA($BFN,charToGlyph) $n]
            lappend chars [list $n]
        } else {
            # The codepoint is kept even though there is no glyph, so the
            # encoder can say WHICH character was lost. Counting here would
            # be wrong -- ShapeRun also serves getStringWidth, and merely
            # measuring a string must not raise the substitution counter.
            lappend glyphs 0
            lappend chars [list $n]
        }
    }
    if {$ligatures && $istCID} {
        ApplyLigatures $BFN glyphs chars
    }
    return [list $glyphs $chars]
}

# Width of a shaped run in 1/1000 em, kerning included.
#
# Ligature glyphs are not in charWidths, which is keyed by codepoint, so
# their advance is read from the glyph table. In Carlito f+f+i is 839.8 and
# the ffi glyph 807.6 -- four percent, enough to break centring and line
# breaking.
proc ::pdf4tcl::ShapedWidth {in fn {ligatures 0} {kerning 0} {stdAllowed 0}} {
    variable ::pdf4tcl::FontsAttrs
    variable ::pdf4tcl::BFA
    if {![info exists FontsAttrs($fn,basefontname)]} { return 0 }
    set BFN $FontsAttrs($fn,basefontname)
    lassign [ShapeRun $in $fn $ligatures] glyphs chars

    set w 0.0
    foreach glyph $glyphs cps $chars {
        if {[llength $cps] == 1
                && [dict exists $BFA($BFN,charWidths) [lindex $cps 0]]} {
            set w [expr {$w + [dict get $BFA($BFN,charWidths) [lindex $cps 0]]}]
        } elseif {[info exists BFA($BFN,hmetrics)]
                && [lindex $BFA($BFN,hmetrics) $glyph] ne ""} {
            # A ligature has no codepoint of its own, so the advance comes
            # from the horizontal metrics, indexed by glyph id -- the same
            # source the /W array is built from.
            set aw [lindex [lindex $BFA($BFN,hmetrics) $glyph] 0]
            set w [expr {$w + $aw * 1000.0 / $BFA($BFN,unitsPerEm)}]
        } else {
            # No width to be had. Fall back per codepoint, and for one the
            # font cannot represent use the width of '?' -- that is what
            # CleanText actually draws, and what GetCharWidth has done
            # since ticket #17. Counting it as zero made "AB" plus two CJK
            # characters measure half of "AB??" (util-6.2).
            foreach cp $cps {
                if {[dict exists $BFA($BFN,charWidths) $cp]} {
                    set w [expr {$w + [dict get $BFA($BFN,charWidths) $cp]}]
                } elseif {$cp > 32
                        && [dict exists $BFA($BFN,charWidths) 63]} {
                    set w [expr {$w + [dict get $BFA($BFN,charWidths) 63]}]
                }
            }
        }
    }
    if {$kerning} {
        # A standard-14 font only kerns when the caller asked for it --
        # setKerning "all". Same rule as KernWidth, and the tests
        # kerning-2.3 and 2.5 hold it.
        set istCID [expr {[info exists FontsAttrs($fn,type)]
                && $FontsAttrs($fn,type) eq "CID"}]
        if {$istCID || $stdAllowed} {
            set n [llength $glyphs]
            for {set i 0} {$i < $n - 1} {incr i} {
                # Eine Mark, die gerade uebersprungen wurde, darf nicht selbst
        # noch einmal als linkes Glyph zaehlen -- sonst wird zweimal
        # addiert. Ob sie uebersprungen WIRD, entscheidet NextKernGlyph
        # je Paar; hier genuegt zu wissen, dass es eine Mark ohne eigenes
        # Paar zum Vorgaenger ist.
        if {$i > 0 && [IsMarkGlyph $BFN [lindex $glyphs $i]]
                && [lindex [GetKernPairInfo $BFN [lindex $glyphs [expr {$i-1}]] \
                        [lindex $glyphs $i]] 0] == 0} { continue }
                set j [NextKernGlyph $BFN $glyphs $i]
                if {$j < 0} { continue }
                set w [expr {$w + [GetKernPair $BFN [lindex $glyphs $i] \
                        [lindex $glyphs $j]]}]
            }
        }
    }
    return $w
}

# Encode a slice of an already-shaped glyph run.
#
# CID text is hex in angle brackets; a standard-14 font has no glyph
# mapping, so its "glyphs" are codepoints and go through the normal string
# encoder. Recording glyph -> characters here keeps the ToUnicode CMap
# right for ligatures.
proc ::pdf4tcl::EncodeGlyphSlice {glyphs chars fn} {
    variable ::pdf4tcl::FontsAttrs
    set istCID [expr {[info exists FontsAttrs($fn,type)]
            && $FontsAttrs($fn,type) eq "CID"}]
    if {!$istCID} {
        set txt ""
        foreach cps $chars {
            foreach cp $cps { append txt [format %c $cp] }
        }
        return [PdfText $txt $fn]
    }
    set hex ""
    foreach glyph $glyphs char $chars {
        if {$glyph != 0} {
            if {[llength $char]} {
                dict set FontsAttrs($fn,glyphChars) $glyph $char
            }
        } else {
            # .notdef gets drawn -- count and report it here, where the
            # text really goes onto the page. CIDEncodeText does the same;
            # without it a missing character was reported or not depending
            # on whether the string happened to kern somewhere.
            incr ::pdf4tcl::substCount
            if {[llength $char]} {
                NoteMissingGlyph $FontsAttrs($fn,basefontname) [lindex $char 0]
            }
        }
        append hex [format %04X $glyph]
    }
    return "<$hex>"
}

proc ::pdf4tcl::PdfTextKerned {in fn {stdAllowed 0} {ligatures 0}} {
    variable ::pdf4tcl::FontsAttrs
    variable ::pdf4tcl::BFA
    if {![info exists FontsAttrs($fn,basefontname)]} { return "" }
    set istCID [expr {[info exists FontsAttrs($fn,type)]
            && $FontsAttrs($fn,type) eq "CID"}]
    if {!$istCID && !$stdAllowed} { return "" }
    set BFN $FontsAttrs($fn,basefontname)
    # The class tables count as well. A face that keeps its kerning only
    # as GPOS classes has no individual pairs at all -- Carlito is one,
    # and testing kernPairs alone set it unkerned although GetKernPair
    # returns values.
    if {(![info exists BFA($BFN,kernPairs)] || ![dict size $BFA($BFN,kernPairs)])
            && (![info exists BFA($BFN,kernClasses)]
                || ![llength $BFA($BFN,kernClasses)])} {
        return ""
    }

    # Shape ONCE, then kern the result. The order is the whole point:
    # splitting on the unshaped glyphs and applying ligatures only to the
    # last piece meant "ffi" in Carlito came out as f + kern + fi instead
    # of the ffi glyph, undoing "longest match wins" from ApplyLigatures.
    lassign [ShapeRun $in $fn $ligatures] glyphs chars
    if {[llength $glyphs] < 2} { return "" }

    set teile {}
    set sliceG {}
    set sliceC {}
    set kerned 0
    set n [llength $glyphs]
    for {set i 0} {$i < $n} {incr i} {
        lappend sliceG [lindex $glyphs $i]
        lappend sliceC [lindex $chars $i]
        if {$i + 1 >= $n} { break }
        # Eine Mark, die gerade uebersprungen wurde, darf nicht selbst
        # noch einmal als linkes Glyph zaehlen -- sonst wird zweimal
        # addiert. Ob sie uebersprungen WIRD, entscheidet NextKernGlyph
        # je Paar; hier genuegt zu wissen, dass es eine Mark ohne eigenes
        # Paar zum Vorgaenger ist.
        if {$i > 0 && [IsMarkGlyph $BFN [lindex $glyphs $i]]
                && [lindex [GetKernPairInfo $BFN [lindex $glyphs [expr {$i-1}]] \
                        [lindex $glyphs $i]] 0] == 0} { continue }
        set j [NextKernGlyph $BFN $glyphs $i]
        if {$j < 0} { continue }
        set adj [GetKernPair $BFN [lindex $glyphs $i] [lindex $glyphs $j]]
        if {$adj == 0} { continue }
        # The adjustment goes after the LAST glyph before the partner, so
        # skipped marks stay with the glyph they belong to.
        if {$j > $i + 1} {
            for {set k [expr {$i + 1}]} {$k < $j} {incr k} {
                lappend sliceG [lindex $glyphs $k]
                lappend sliceC [lindex $chars $k]
            }
            set i [expr {$j - 1}]
        }
        lappend teile [EncodeGlyphSlice $sliceG $sliceC $fn] \
                [format %g [expr {-$adj}]]
        set sliceG {}
        set sliceC {}
        set kerned 1
    }
    if {!$kerned} { return "" }
    if {[llength $sliceG]} {
        lappend teile [EncodeGlyphSlice $sliceG $sliceC $fn]
    }
    return "\[[join $teile { }]\]"
}

# Unified text encoder: routes to CIDEncodeText or CleanText.
# Returns a complete PDF text object string (incl. delimiters).
# Ligatures are passed in rather than read from the document, because
# PdfText is also used for form field values and appearance strings, where
# a ligature glyph would be wrong.
proc ::pdf4tcl::PdfText {in fn {ligatures 0}} {
    variable ::pdf4tcl::FontsAttrs
    if {[info exists FontsAttrs($fn,type)] && $FontsAttrs($fn,type) eq "CID"} {
        return [CIDEncodeText $in $fn $ligatures]
    } else {
        return "([CleanText $in $fn])"
    }
}

# Number of characters that CleanText could not represent in the font's
# encoding and replaced with "?" (or, in a subset without "?", with .notdef).
# The PDF stays valid, the text does not: an unmappable character is silently
# lost. Read it per document with [$pdf getSubstCount] -- see the manual.
namespace eval pdf4tcl {
    variable substCount 0
    # Welche Codepunkte schon gemeldet wurden, je Basisschrift.
    variable missingGlyphSeen
    array set missingGlyphSeen {}
}

# helper function: mask parentheses and backslash
proc ::pdf4tcl::CleanText {in fn} {
    variable ::pdf4tcl::FontsAttrs
    variable ::pdf4tcl::substCount
    if {$FontsAttrs($fn,specialencoding)} {
        # Convert using special encoding of font subset:
        set out ""
        set encDict $FontsAttrs($fn,encoding)
        foreach uchar [split $in {}] {
            if {[dict exists $encDict $uchar]} {
                append out [dict get $encDict $uchar]
            } elseif {[dict exists $encDict "?"]} {
                append out [dict get $encDict "?"]
                incr substCount
                scan $uchar %c ucp
                NoteMissingGlyph $FontsAttrs($fn,basefontname) $ucp "?"
            } else {
                append out [binary format cu 0]
                incr substCount
                scan $uchar %c ucp
                NoteMissingGlyph $FontsAttrs($fn,basefontname) $ucp
            }
        }
    } else {
        # Tcl 9: encoding convertto wirft Fehler fuer nicht-darstellbare Zeichen.
        # Zeichenweise konvertieren mit catch -- unmappbare Zeichen als '?' ausgeben.
        if {[catch {set out [encoding convertto $FontsAttrs($fn,encoding) $in]}]} {
            set out ""
            set enc $FontsAttrs($fn,encoding)
            foreach uchar [split $in {}] {
                if {[catch {append out [encoding convertto $enc $uchar]}]} {
                    append out "?"
                    incr substCount
                    scan $uchar %c ucp
                    NoteMissingGlyph $FontsAttrs($fn,basefontname) $ucp "?"
                }
            }
        }
    }
    # map special characters
    return [string map {
        \n "\\n" \r "\\r" \t "\\t" \b "\\b" \f "\\f" ( "\\(" ) "\\)" \\ "\\\\"
    } $out]
}

# helper function: correctly quote string with parentheses
# Transliteration of common typography that does not fit into a PDF literal
# string (see QuoteString). Extend or override this variable if a document
# needs different substitutions.
namespace eval pdf4tcl {
    variable asciiMap [list \
        \u2010 -    \u2011 -    \u2012 -    \u2013 -    \u2014 -    \u2015 -   \
        \u2018 '    \u2019 '    \u201A '    \u201B '                            \
        \u201C \"   \u201D \"   \u201E \"   \u201F \"                           \
        \u2039 <    \u203A >    \u2026 ...  \u2022 *                           \
        \u2190 <-   \u2192 ->   \u2264 <=   \u2265 >=   \u2260 !=               \
        \u20AC EUR  \u2122 (TM) \u2116 No.  \u2032 '    \u2033 \"                \
        \u200B ""   \u2028 " "  \u2029 " "                                      \
    ]
}

# QuoteString: escape a Tcl string for a PDF literal string, and make it safe
# for the binary PDF stream.
#
# PDF literal strings go into the binary output. Tcl 9.0 rejects codepoints
# above U+00FF on a binary-translation channel (EILSEQ), so such a character
# does not fail here but much later, in `finish`, as an opaque
#     expected code point values below 0xff but value at byte offset N was 0x...
# hundreds of kilobytes away from its origin. Replacing it here turns a build
# abort into a visible, local defect.
#
# Replacement is silent for ordinary text and noisy for control characters --
# see the two comments in the body.
proc ::pdf4tcl::QuoteString {string} {
    # Codepoints above U+00FF: replaced silently. Titles, metadata and
    # annotation text are ordinary prose; an en-dash or a typographic quote is
    # normal there, and a warning would fire on nearly every real document.
    #
    # Common typography is transliterated first, so a bookmark reads
    # "Chapter 1 - Introduction" and not "Chapter 1 ? Introduction". Whatever
    # is left over becomes "?".
    if {[regexp {[^\x00-\xFF]} $string]} {
        variable asciiMap
        set string [string map $asciiMap $string]
        if {[regexp {[^\x00-\xFF]} $string]} {
            set string [regsub -all {[^\x00-\xFF]} $string {?}]
        }
    }
    # Control characters are different: they never belong in a PDF string and
    # always indicate a defect upstream. Worth one line on stderr.
    if {[regexp {[\x00-\x08\x0B\x0E-\x1F\x7F]} $string]} {
        set string [regsub -all {[\x00-\x08\x0B\x0E-\x1F\x7F]} $string {}]
        QuoteStringWarn "control character"
    }
    # map special characters
    return ([string map {
        \n "\\n" \r "\\r" \t "\\t" \b "\\b" \f "\\f" ( "\\(" ) "\\)" \\ "\\\\"
    } $string])
}

# Non-fatal warnings go into ::pdf4tcl::warnings, the list the package already
# uses for PDF/A compliance notes (see the manual, PACKAGE VARIABLES). Nothing
# is written to stderr: a library should not decide for its caller where
# diagnostics appear, and tcltest counts any stderr output as a file error.
#
# One entry per kind and process -- a broken document would otherwise produce
# one line per string. Reset with [set ::pdf4tcl::warnings {}], which also
# re-arms the reporting.
proc ::pdf4tcl::QuoteStringWarn {what} {
    variable quoteWarned
    variable warnings
    if {$warnings eq ""} {
        # list was reset by the caller; report again
        catch {unset quoteWarned}
    }
    if {![info exists quoteWarned($what)]} {
        set quoteWarned($what) 1
        lappend warnings "quoteString: $what in a PDF string was replaced\
                (further occurrences are not reported)"
    }
}

# SafeQuoteString: kept for compatibility. QuoteString is safe by itself
# since 0.9.4.x; this is a plain alias now.
proc ::pdf4tcl::SafeQuoteString {string} {
    return [QuoteString $string]
}

# -- Unit conversion helpers (0.9.4.12) ----------------------------------------
# Convert common units to PDF points (1 pt = 1/72 inch)

namespace eval pdf4tcl {
    # mm to points
    proc mm {v} { expr {$v * 72.0 / 25.4} }

    # cm to points
    proc cm {v} { expr {$v * 72.0 / 2.54} }

    # inches to points
    proc in {v} { expr {$v * 72.0} }

    # points (identity -- for symmetric usage)
    proc pt {v} { expr {double($v)} }
}
