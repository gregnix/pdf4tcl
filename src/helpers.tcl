namespace eval pdf4tcl {
    # The incoming RGB must contain three values in the range 0.0 to 1.0
    # The return value is CMYK as a list of values in the range 0.0 to 1.0
    proc rgb2Cmyk {RGB} {
        foreach {r g b} $RGB break

        # Black, including some margin for float roundings
        if {$r <= 0.00001 && $g <= 0.00001 && $b <= 0.00001} {
            return [list 0.0 0.0 0.0 1.0]
        }
        set c [expr {1.0 - $r}]
        set m [expr {1.0 - $g}]
        set y [expr {1.0 - $b}]

        # k is min of c/m/y
        set k [expr {min($c, $m, $y)}]
        # k is less than 1 since only black would give exactly 1
        # so all divisions are safe.
        # Since k is min, all numerators are >= 0
        # All numerators are <= denominators, leaving all results <= 1.0
        set c [expr {($c - $k) / (1.0 - $k)}]
        set m [expr {($m - $k) / (1.0 - $k)}]
        set y [expr {($y - $k) / (1.0 - $k)}]

        return [list $c $m $y $k]
    }

    # The incoming CMYK must contain four values in the range 0.0 to 1.0
    # The return value is RGB as a list of values in the range 0.0 to 1.0
    proc cmyk2Rgb {CMYK} {
        foreach {c m y k} $CMYK break

        # Black, including some margin for float roundings
        if {$k >= 0.99999} {
            return [list 0.0 0.0 0.0]
        }

        set c [expr {$c * (1.0 - $k) + $k}]
        set m [expr {$m * (1.0 - $k) + $k}]
        set y [expr {$y * (1.0 - $k) + $k}]

        set r [expr {1.0 - $c}]
        set g [expr {1.0 - $m}]
        set b [expr {1.0 - $y}]

        return [list $r $g $b]
    }
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

# helper function: mask parentheses and backslash
proc ::pdf4tcl::CleanText {in fn} {
    variable ::pdf4tcl::FontsAttrs
    if {$FontsAttrs($fn,specialencoding)} {
        # Convert using special encoding of font subset:
        set out ""
        foreach uchar [split $in {}] {
            append out [dict get $FontsAttrs($fn,encoding) $uchar]
        }
    } else {
        set out [encoding convertto $FontsAttrs($fn,encoding) $in]
    }
    # map special characters
    return [string map {
        \n "\\n" \r "\\r" \t "\\t" \b "\\b" \f "\\f" ( "\\(" ) "\\)" \\ "\\\\"
    } $out]
}

# helper function: correctly quote string with parentheses
proc ::pdf4tcl::QuoteString {string} {
    # map special characters
    return ([string map {
        \n "\\n" \r "\\r" \t "\\t" \b "\\b" \f "\\f" ( "\\(" ) "\\)" \\ "\\\\"
    } $string])
}
