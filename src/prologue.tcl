# library of tcl procedures for generating portable document format files
# this began as a port of pdf4php from php to tcl
#
# Copyright (c) 2004 by Frank Richter <frichter@truckle.in-chemnitz.de> and
#                       Jens Ponisch <jens@ruessel.in-chemnitz.de>
# Copyright (c) 2006-2016 by Peter Spjuth <peter.spjuth@gmail.com>
# Copyright (c) 2009 by Yaroslav Schekin <ladayaroslav@yandex.ru>
# Copyright (c) 2024-2026 by gregnix (fork 0.9.4.x additions)
#
# See the file "licence.terms" for information on usage and redistribution
# of this file, and for a DISCLAIMER OF ALL WARRANTIES.

package provide pdf4tcl 0.9.4.25
package require TclOO
package require pdf4tcl::stdmetrics
package require pdf4tcl::glyph2unicode

namespace eval pdf4tcl {
    # helper variables (constants) packaged into arrays to minimize
    # variable import statements
    variable paper_sizes
    variable units
    variable dir [file dirname [file join [pwd] [info script]]]

    # Accumulated warnings (e.g. PDF/A violations). Check with:
    #   $::pdf4tcl::warnings
    # Reset with: set ::pdf4tcl::warnings {}
    variable warnings {}

    # Make mathops available
    namespace import ::tcl::mathop::*

    # Known paper sizes. These are always in points.
    array set paper_sizes {
        4a0    {4768.0 6741.0}
        2a0    {3370.0 4768.0}
        a0     {2384.0 3370.0}
        a1     {1684.0 2384.0}
        a2     {1191.0 1684.0}
        a3     { 842.0 1191.0}
        a4     { 595.0  842.0}
        a5     { 420.0  595.0}
        a6     { 298.0  420.0}
        a7     { 210.0  298.0}
        a8     { 147.0  210.0}
        a9     { 105.0  147.0}
        a10    {  74.0  105.0}
        b0     {2835.0 4008.0}
        b1     {2004.0 2835.0}
        b2     {1417.0 2004.0}
        b3     {1001.0 1417.0}
        b4     { 709.0 1001.0}
        b5     { 499.0  709.0}
        b6     { 354.0  499.0}
        b7     { 249.0  354.0}
        b8     { 176.0  249.0}
        b9     { 125.0  176.0}
        b10    {  88.0  125.0}
        c0     {2599.0 3677.0}
        c1     {1837.0 2599.0}
        c2     {1298.0 1837.0}
        c3     { 918.0 1298.0}
        c4     { 649.0  918.0}
        c5     { 459.0  649.0}
        c6     { 323.0  459.0}
        c7     { 230.0  323.0}
        c8     { 162.0  230.0}
        c9     { 113.0  162.0}
        c10    {  79.0  113.0}
        11x17  { 792.0 1224.0}
        ledger {1224.0  792.0}
        legal  { 612.0 1008.0}
        letter { 612.0  792.0}
    }

    # Known units. The value is their relationship to points
    array set units [list \
            mm [expr {72.0 / 25.4}] \
            m  [expr {72.0 / 25.4}] \
            cm [expr {72.0 / 2.54}] \
            c  [expr {72.0 / 2.54}] \
            i  72.0                 \
            p  1.0                  \
           ]

    # Utility to look up paper size by name
    # A two element list of width and height is also allowed.
    # Return value is in points
    proc getPaperSize {papername {unit 1.0}} {
        variable paper_sizes

        set papername [string tolower $papername]
        if {[info exists paper_sizes($papername)]} {
            # This array is always correct format
            return $paper_sizes($papername)
        }
        if {[catch {set len [llength $papername]}] || $len != 2} {
            return {}
        }
        foreach {w h} $papername break
        set w [getPoints $w $unit]
        set h [getPoints $h $unit]
        return [list $w $h]
    }

    # Return a list of known paper sizes
    proc getPaperSizeList {} {
        variable paper_sizes
        return [array names paper_sizes]
    }

    # Get points from a measurement.
    # No unit means points.
    # Supported units are "mm", "m", "cm", "c", "p" and "i".
    proc getPoints {val {unit 1.0}} {
        variable units
        if {[string is double -strict $val]} {
            # Always return a pure double value
            return [expr {$val * $unit}]
        }
        if {[regexp {^\s*(\S+?)\s*([[:alpha:]]+)\s*$} $val -> num unit]} {
            if {[string is double -strict $num]} {
                if {[info exists units($unit)]} {
                    return [expr {$num * $units($unit)}]
                }
            }
        }
        throw {PDF4TCL} "unknown value $val"
    }

    # Wrapper to create pdf4tcl object
    proc new {args} {
        set cmd create
        # Support Snit style of naming
        if {[lindex $args 0] eq "%AUTO%"} {
            set args [lrange $args 1 end]
            set cmd new
        }
        uplevel 1 pdf4tcl::pdf4tcl $cmd $args
    }
}
