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

package provide pdf4tcl 0.9.4.12
package require TclOO
package require pdf4tcl::stdmetrics
package require pdf4tcl::glyph2unicode

namespace eval pdf4tcl {
    # helper variables (constants) packaged into arrays to minimize
    # variable import statements
    variable paper_sizes
    variable units
    variable dir [file dirname [file join [pwd] [info script]]]

    # Make mathops available
    namespace import ::tcl::mathop::*

    # Known paper sizes. These are always in points.
    array set paper_sizes {
        a0     {2380.0 3368.0}
        a1     {1684.0 2380.0}
        a2     {1190.0 1684.0}
        a3     { 842.0 1190.0}
        a4     { 595.0  842.0}
        a5     { 421.0  595.0}
        a6     { 297.0  421.0}
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
