#!/usr/bin/env tclsh
# nroff2md.tcl -- standalone nroff/man-page to Markdown converter
#
# Version:  0.1
# Requires: Tcl 8.6+
# Source:   https://github.com/gregnix/man-viewer
#
# Embedded modules:
#   nroffparser-0.2  -- nroff parser (AST v1)
#   ast2md-0.1       -- AST to Markdown renderer
#   debug-0.2        -- debug/trace toolkit
#
# Copyright (c) 2026 Gregor Ebbing <gregnix@github>
# All rights reserved.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions
# are met:
#
# 1. Redistributions of source code must retain the above copyright
#    notice, this list of conditions and the following disclaimer.
#
# 2. Redistributions in binary form must reproduce the above copyright
#    notice, this list of conditions and the following disclaimer in
#    the documentation and/or other materials provided with the
#    distribution.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
# "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
# LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS
# FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE
# COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT,
# INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING,
# BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
# LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
# CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
# LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN
# ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
# POSSIBILITY OF SUCH DAMAGE.
#
# Usage:
#   tclsh nroff2md.tcl input.n                    # to stdout
#   tclsh nroff2md.tcl input.n output.md          # to file
#   tclsh nroff2md.tcl input.n -lang tcl          # code block language
#   tclsh nroff2md.tcl --batch dir/ outdir/       # batch convert
#   cat input.n | tclsh nroff2md.tcl -            # from stdin

package require Tcl 8.6-

# ===========================================================================
# EMBEDDED: debug-0.2.tm
# ===========================================================================

# debug-0.2.tm -- Generic debug toolkit for Tcl applications
#
# Project-independent debugging, tracing, and AST inspection.
# No external dependencies. Tk optional (for GUI console).
#
# Modules:
#   debug::         Logging, assertions, timers
#   debug::trace    Configurable trace categories
#   debug::ast      AST dump, diff, save/load, validate
#
# Usage:
#   package require debug 0.2
#   debug::setLevel 2
#   debug::log 1 "Application started"
#
#   debug::trace::register parser 2
#   debug::trace parser "Macro detected: .SH"
#
#   debug::ast::dump $ast -file /tmp/ast.txt
#   debug::ast::diff $ast1 $ast2

catch {package provide debug 0.2}

# ============================================================
# Core: Logging
# ============================================================

namespace eval debug {
    variable level 0
    variable guiWidget ""
    variable logFileHandle ""
    variable logFile ""

    namespace export setLevel getLevel log assert
    namespace export openLogFile closeLogFile getLogFile
    namespace export setGuiWidget clearGui
    namespace export startTimer stopTimer
}

# setLevel --
#   Set debug verbosity.
#   0 = off, 1 = info, 2 = detail, 3 = verbose, 4 = trace
proc debug::setLevel {lvl} {
    variable level
    if {$lvl < 0 || $lvl > 4} {
        error "debug::setLevel: level must be 0-4, got $lvl"
    }
    set level $lvl
}

# getLevel --
#   Returns current debug level.
proc debug::getLevel {} {
    variable level
    return $level
}

# log --
#   Log message if current level >= lvl.
#   Args:
#     lvl  - minimum level for this message (0-4)
#     msg  - message text
proc debug::log {lvl msg} {
    variable level
    variable guiWidget
    variable logFileHandle

    if {$lvl > $level} return

    set ts [clock format [clock seconds] -format "%H:%M:%S"]
    set line "\[$ts\] \[$lvl\] $msg"

    # File logging (highest priority)
    if {$logFileHandle ne ""} {
        puts $logFileHandle $line
        flush $logFileHandle
    }

    # GUI console (if available)
    if {$guiWidget ne ""} {
        if {[catch {winfo exists $guiWidget} exists] == 0 && $exists} {
            $guiWidget insert end "$line\n"
            $guiWidget see end
            return
        }
    }

    # Fallback: stderr (only if no file logging)
    if {$logFileHandle eq ""} {
        puts stderr $line
    }
}

# ============================================================
# File Logging
# ============================================================

# openLogFile --
#   Open a debug log file. Does NOT change the debug level.
#   Args:
#     ?file?  - filename (auto-generated if empty)
#   Returns:
#     filename
proc debug::openLogFile {{file ""}} {
    variable logFile
    variable logFileHandle

    # Close previous file if open
    if {$logFileHandle ne ""} {
        catch {close $logFileHandle}
        set logFileHandle ""
    }

    # Auto-generate filename
    if {$file eq ""} {
        set file "debug_[clock format [clock seconds] -format %Y%m%d_%H%M%S].log"
    }

    set logFile $file
    set logFileHandle [open $file w]
    log 1 "Log file opened: $file"
    return $file
}

# closeLogFile --
#   Close the current log file.
proc debug::closeLogFile {} {
    variable logFileHandle
    variable logFile

    if {$logFileHandle ne ""} {
        log 1 "Closing log file: $logFile"
        catch {close $logFileHandle}
        set logFileHandle ""
        set logFile ""
    }
}

# getLogFile --
#   Returns current log filename, or "" if none.
proc debug::getLogFile {} {
    variable logFile
    return $logFile
}

# ============================================================
# GUI Console (optional, requires Tk)
# ============================================================

# setGuiWidget --
#   Set a Tk text widget for debug output.
#   Args:
#     widget - path to text widget (e.g. ".debug")
proc debug::setGuiWidget {widget} {
    variable guiWidget
    set guiWidget $widget
    log 1 "GUI debug widget set: $widget"
}

# clearGui --
#   Clear the GUI debug console.
proc debug::clearGui {} {
    variable guiWidget
    if {$guiWidget ne ""} {
        catch {
            if {[winfo exists $guiWidget]} {
                $guiWidget delete 1.0 end
            }
        }
    }
}

# ============================================================
# Assertions
# ============================================================

# assert --
#   Throws error if condition is false.
#   Args:
#     condition - boolean expression
#     message   - error message on failure
proc debug::assert {condition message} {
    if {![uplevel 1 [list expr $condition]]} {
        set msg "ASSERTION FAILED: $message"
        log 0 $msg
        error $msg
    }
}

# ============================================================
# Performance Timers
# ============================================================

namespace eval debug {
    variable timers {}
}

# startTimer --
#   Start a named timer.
proc debug::startTimer {name} {
    variable timers
    dict set timers $name [clock milliseconds]
}

# stopTimer --
#   Stop timer, log elapsed time, return milliseconds.
proc debug::stopTimer {name} {
    variable timers
    if {![dict exists $timers $name]} {
        error "debug::stopTimer: timer '$name' not started"
    }
    set elapsed [expr {[clock milliseconds] - [dict get $timers $name]}]
    dict unset timers $name
    log 1 "TIMER $name: ${elapsed}ms"
    return $elapsed
}

# ============================================================
# Configurable Trace System
# ============================================================

namespace eval debug::trace {
    variable categories {}
    ;# dict: category -> level

    namespace export register emit list reset
    namespace ensemble create
}

# debug::trace register --
#   Register a trace category with a minimum level.
#   Messages for this category are logged when debug level >= registered level.
#
#   Example:
#     debug::trace register parser 1
#     debug::trace register renderer 2
#     debug::trace register inline 3
proc debug::trace::register {category {lvl 1}} {
    variable categories
    dict set categories $category $lvl
}

# debug::trace emit --
#   Emit a trace message for a category.
#   Only logged if the category is registered and debug level is sufficient.
#
#   Example:
#     debug::trace emit parser "Macro: .SH"
#     debug::trace emit parser "State: mode=normal" detail
proc debug::trace::emit {category msg {detail ""}} {
    variable categories
    if {![dict exists $categories $category]} return
    set lvl [dict get $categories $category]
    if {$detail ne ""} {
        debug::log $lvl "[string toupper $category]: $msg ($detail)"
    } else {
        debug::log $lvl "[string toupper $category]: $msg"
    }
}

# debug::trace list --
#   Returns dict of registered categories and their levels.
proc debug::trace::list {} {
    variable categories
    return $categories
}

# debug::trace reset --
#   Remove all registered trace categories.
proc debug::trace::reset {} {
    variable categories
    set categories {}
}

# ============================================================
# Convenience: pre-register common categories
# ============================================================
# Users can override levels or add their own categories.

debug::trace::register info    1
debug::trace::register warning 0
debug::trace::register error   0

# ============================================================
# AST Tools
# ============================================================

namespace eval debug::ast {
    namespace export dump save load diff validate
    namespace ensemble create
}

# debug::ast dump --
#   Pretty-print an AST to stderr, log, or file.
#   Works with any AST that is a list of dicts with 'type' keys.
#
#   Args:
#     ast           - list of AST nodes (dicts)
#     ?-file path?  - write to file instead of log
#     ?-indent n?   - indentation depth (default 0)
#
#   Example:
#     debug::ast dump $ast
#     debug::ast dump $ast -file /tmp/ast.txt
proc debug::ast::dump {ast args} {
    # Parse options
    set file ""
    set indent 0
    foreach {opt val} $args {
        switch -- $opt {
            -file   { set file $val }
            -indent { set indent $val }
            default { error "debug::ast::dump: unknown option $opt" }
        }
    }

    set lines {}
    lappend lines "AST Dump ([llength $ast] nodes)"
    lappend lines [string repeat "=" 40]
    lappend lines ""

    set num 0
    foreach node $ast {
        incr num
        set prefix [string repeat "  " $indent]

        if {![dict exists $node type]} {
            lappend lines "${prefix}#$num: \[INVALID: $node\]"
            lappend lines ""
            continue
        }

        set type [dict get $node type]
        lappend lines "${prefix}#$num: $type"

        if {[dict exists $node content]} {
            set content [dict get $node content]
            lappend lines [_formatContent $content "${prefix}  "]
        }

        if {[dict exists $node meta]} {
            set meta [dict get $node meta]
            if {[llength $meta] > 0} {
                lappend lines "${prefix}  meta: $meta"
            }
        }

        lappend lines ""
    }

    set output [join $lines "\n"]

    if {$file ne ""} {
        set fh [open $file w]
        puts $fh $output
        close $fh
        debug::log 1 "AST dump saved: $file"
        return $file
    } else {
        debug::log 3 $output
        return $output
    }
}

# _formatContent --
#   Internal: format node content for display.
proc debug::ast::_formatContent {content prefix} {
    # Check if content is a list of inline nodes
    if {[string is list $content] && [llength $content] > 0} {
        set first [lindex $content 0]
        if {[catch {dict exists $first type} isDict] == 0 && $isDict} {
            # List of inline nodes
            set parts {}
            foreach inline $content {
                set t [expr {[dict exists $inline type] ? [dict get $inline type] : "?"}]
                set v ""
                if {[dict exists $inline text]} {
                    set v [dict get $inline text]
                } elseif {[dict exists $inline value]} {
                    set v [dict get $inline value]
                }
                lappend parts "$t:\"[_truncate $v 30]\""
            }
            return "${prefix}content: \[[join $parts {, }]\]"
        }
        if {[catch {dict exists $first term} hasTerm] == 0 && $hasTerm} {
            # List of items
            return "${prefix}content: [llength $content] items"
        }
    }

    # Plain string
    return "${prefix}content: \"[_truncate $content 60]\""
}

# _truncate --
#   Internal: truncate string with ellipsis.
proc debug::ast::_truncate {str maxlen} {
    if {[string length $str] > $maxlen} {
        return "[string range $str 0 [expr {$maxlen - 4}]]..."
    }
    return $str
}

# debug::ast save --
#   Save AST to file as valid Tcl list (safe serialization).
#   Args:
#     file - output filename
#     ast  - list of AST nodes
proc debug::ast::save {file ast} {
    set fh [open $file w]
    puts $fh "# AST saved: [clock format [clock seconds] -format {%Y-%m-%d %H:%M:%S}]"
    puts $fh "# Nodes: [llength $ast]"
    puts $fh ""
    # Serialize as a proper Tcl list -- handles all special characters
    puts $fh [list $ast]
    close $fh
    debug::log 1 "AST saved: $file ([llength $ast] nodes)"
    return $file
}

# debug::ast load --
#   Load AST from file (saved by debug::ast save).
#   Returns:
#     list of AST nodes
proc debug::ast::load {file} {
    set fh [open $file r]
    set data [read $fh]
    close $fh

    # Skip comment lines, find the Tcl list
    foreach line [split $data "\n"] {
        set trimmed [string trim $line]
        if {$trimmed eq "" || [string index $trimmed 0] eq "#"} continue
        # First non-comment line is the serialized AST
        set ast [lindex $trimmed 0]
        debug::log 1 "AST loaded: $file ([llength $ast] nodes)"
        return $ast
    }

    return {}
}

# debug::ast diff --
#   Compare two ASTs and report differences.
#   Args:
#     ast1          - first AST
#     ast2          - second AST
#     ?-typesonly?  - compare only node types (faster)
#     ?-file path?  - write diff to file
#   Returns:
#     dict with keys: equal (bool), differences (int), details (list)
proc debug::ast::diff {ast1 ast2 args} {
    set typesOnly 0
    set file ""
    foreach arg $args {
        switch -- $arg {
            -typesonly { set typesOnly 1 }
            default {
                if {$file eq "" && [string index $arg 0] ne "-"} {
                    error "debug::ast::diff: unknown option $arg"
                }
            }
        }
    }
    # Handle -file option
    set idx [lsearch $args "-file"]
    if {$idx >= 0} {
        set file [lindex $args [expr {$idx + 1}]]
    }

    set n1 [llength $ast1]
    set n2 [llength $ast2]
    set max [expr {$n1 > $n2 ? $n1 : $n2}]
    set diffs 0
    set details {}

    for {set i 0} {$i < $max} {incr i} {
        if {$i >= $n1} {
            incr diffs
            lappend details "node $i: MISSING in ast1, ast2=[_nodeType [lindex $ast2 $i]]"
            continue
        }
        if {$i >= $n2} {
            incr diffs
            lappend details "node $i: ast1=[_nodeType [lindex $ast1 $i]], MISSING in ast2"
            continue
        }

        set node1 [lindex $ast1 $i]
        set node2 [lindex $ast2 $i]
        set t1 [_nodeType $node1]
        set t2 [_nodeType $node2]

        if {$typesOnly} {
            if {$t1 ne $t2} {
                incr diffs
                lappend details "node $i: type $t1 -> $t2"
            }
        } else {
            if {$node1 ne $node2} {
                incr diffs
                set msg "node $i: type $t1"
                if {$t1 ne $t2} {
                    append msg " -> $t2"
                }
                lappend details $msg
            }
        }
    }

    set result [dict create \
        equal    [expr {$diffs == 0}] \
        differences $diffs \
        nodes1   $n1 \
        nodes2   $n2 \
        details  $details]

    # Output
    if {$file ne ""} {
        set fh [open $file w]
        puts $fh "AST Diff: $n1 vs $n2 nodes, $diffs differences"
        foreach d $details { puts $fh "  $d" }
        close $fh
        debug::log 1 "AST diff saved: $file"
    }

    return $result
}

# _nodeType --
#   Internal: extract type from node, or "?" if missing.
proc debug::ast::_nodeType {node} {
    if {[catch {dict get $node type} t]} {
        return "?"
    }
    return $t
}

# debug::ast validate --
#   Validate AST structure. Works with any AST that uses
#   type/content/meta node format.
#
#   Args:
#     ast             - list of AST nodes
#     ?-strict?       - treat warnings as errors
#     ?-types list?   - allowed node types (default: any)
#     ?-require list? - required keys per node (default: type)
#   Returns:
#     dict with keys: valid (bool), errors (list), warnings (list)
proc debug::ast::validate {ast args} {
    set strict 0
    set allowedTypes {}
    set requiredKeys {type}

    # Parse options
    set i 0
    while {$i < [llength $args]} {
        set opt [lindex $args $i]
        switch -- $opt {
            -strict  { set strict 1 }
            -types   { incr i; set allowedTypes [lindex $args $i] }
            -require { incr i; set requiredKeys [lindex $args $i] }
            default  { error "debug::ast::validate: unknown option $opt" }
        }
        incr i
    }

    set errors {}
    set warnings {}
    set num 0

    foreach node $ast {
        incr num

        # Check: is it a dict?
        if {[llength $node] == 0 || [llength $node] % 2 != 0} {
            lappend errors "node $num: not a valid dict"
            continue
        }

        # Check required keys
        foreach key $requiredKeys {
            if {![dict exists $node $key]} {
                lappend errors "node $num: missing required key '$key'"
            }
        }

        # Check allowed types
        if {[dict exists $node type] && [llength $allowedTypes] > 0} {
            set t [dict get $node type]
            if {$t ni $allowedTypes} {
                set msg "node $num: unknown type '$t'"
                if {$strict} {
                    lappend errors $msg
                } else {
                    lappend warnings $msg
                }
            }
        }

        # Check meta is a valid dict (if present)
        if {[dict exists $node meta]} {
            set meta [dict get $node meta]
            if {[llength $meta] % 2 != 0} {
                lappend errors "node $num: 'meta' is not a valid dict"
            }
        }
    }

    set valid [expr {[llength $errors] == 0}]

    # Log results
    if {[llength $errors] > 0} {
        foreach e $errors { debug::log 0 "AST ERROR: $e" }
    }
    if {[llength $warnings] > 0} {
        foreach w $warnings { debug::log 1 "AST WARNING: $w" }
    }
    if {$valid && [llength $warnings] == 0} {
        debug::log 2 "AST valid: $num nodes"
    }

    return [dict create valid $valid errors $errors warnings $warnings]
}

# ============================================================
# Compatibility layer for debug 0.1 API
# ============================================================
# Provides the old trace procs as thin wrappers around the new
# trace system. Load this to use debug 0.2 with code written
# for debug 0.1 (e.g. nroffparser, man-viewer).
#
# The old procs (traceMacro, traceLine, traceState, traceRender,
# traceInline) are mapped to trace categories automatically.

namespace eval debug::compat {
    namespace export install
}

# debug::compat::install --
#   Install backward-compatible procs in the debug:: namespace.
#   Call once after package require debug 0.2.
proc debug::compat::install {} {
    # Register default categories matching old trace levels
    debug::trace::register macro    1
    debug::trace::register line     2
    debug::trace::register state    2
    debug::trace::register render   2
    debug::trace::register inline   3

    # traceMacro macro ?args?
    proc ::debug::traceMacro {macro args} {
        if {[llength $args] > 0} {
            debug::trace emit macro "$macro [join $args { }]"
        } else {
            debug::trace emit macro $macro
        }
    }

    # traceLine lineno line
    proc ::debug::traceLine {lineno line} {
        set preview [string range $line 0 60]
        if {[string length $line] > 60} {
            set preview "[string range $line 0 57]..."
        }
        debug::trace emit line "LINE $lineno: $preview"
    }

    # traceState state
    proc ::debug::traceState {state} {
        set mode [dict get $state mode]
        set para [dict get $state currentParagraph]
        if {[string length $para] > 30} {
            set para "[string range $para 0 27]..."
        }
        debug::trace emit state "mode=$mode paragraph=\"$para\""
    }

    # traceRender type ?details?
    proc ::debug::traceRender {type {details ""}} {
        debug::trace emit render $type $details
    }

    # traceInline type text
    proc ::debug::traceInline {type text} {
        set preview [string range $text 0 40]
        if {[string length $text] > 40} {
            set preview "[string range $text 0 37]..."
        }
        debug::trace emit inline "$type \"$preview\""
    }

    # validateAST ast ?strict?
    proc ::debug::validateAST {ast {strict 1}} {
        set types {heading section subsection paragraph list pre blank hr doc_header}
        # Nodes ohne content/meta-Pflicht (strukturlose Nodes)
        set noContentTypes {blank hr}
        set errors {}
        set num 0
        foreach node $ast {
            incr num
            if {![dict exists $node type]} {
                lappend errors "node $num: missing required key 'type'"
                continue
            }
            set t [dict get $node type]
            if {$t ni $types} {
                lappend errors "node $num: unknown type '$t'"
                continue
            }
            if {$t ni $noContentTypes} {
                foreach key {content meta} {
                    if {![dict exists $node $key]} {
                        lappend errors "node $num: missing required key '$key'"
                    }
                }
            }
        }
        set valid [expr {[llength $errors] == 0}]
        foreach e $errors { debug::log 0 "AST ERROR: $e" }
        return [dict create valid $valid errors $errors]
    }

    # validateASTFile file ?strict?
    proc ::debug::validateASTFile {file {strict 1}} {
        set ast [debug::ast load $file]
        return [debug::validateAST $ast $strict]
    }

    # saveAST / loadAST / diffAST / diffTypes
    proc ::debug::saveAST {file ast} { debug::ast save $file $ast }
    proc ::debug::loadAST {file} { debug::ast load $file }
    proc ::debug::diffAST {ast1 ast2 {output ""}} {
        set args {}
        if {$output ne ""} { lappend args -file $output }
        return [debug::ast diff $ast1 $ast2 {*}$args]
    }
    proc ::debug::diffTypes {ast1 ast2 {output ""}} {
        set args {-typesonly}
        if {$output ne ""} { lappend args -file $output }
        return [debug::ast diff $ast1 $ast2 {*}$args]
    }

    # dumpAST / dumpASTToFile / exportAST
    proc ::debug::dumpAST {ast {indent 0}} {
        debug::ast dump $ast -indent $indent
    }
    proc ::debug::dumpASTToFile {{file ""} ast} {
        if {$file eq ""} {
            set file "ast_[clock format [clock seconds] -format %Y%m%d_%H%M%S].log"
        }
        debug::ast dump $ast -file $file
    }
    proc ::debug::exportAST {ast} {
        debug::ast dump $ast
    }
}

# Auto-install compat layer so debug 0.1 callers work without changes
debug::compat::install

# ============================================================
# nroff Parser Debug Extension
# ============================================================
# Nroff-specific debugging tools built on the generic toolkit.
# Provides macro tracking, state inspection, coverage analysis,
# and parser step-through support.
#
# Usage:
#   debug::nroff::setup         ;# register categories + reset stats
#   debug::nroff::state $state  ;# inspect parser state
#   debug::nroff::coverage      ;# show macro coverage report
#   debug::nroff::unhandled     ;# list macros that hit default case

namespace eval debug::nroff {
    # Macro statistics
    variable macroCount {}    ;# dict: macro -> count
    variable unhandledMacros {} ;# dict: macro -> count
    variable totalLines 0
    variable totalMacros 0

    # Known macros (parser handles these)
    variable knownMacros {
        .TH .SH .SS .PP .LP .P .TP .IP .OP
        .RS .RE .CS .CE .DS .DE .nf .fi
        .br .sp .ta .SO .SE .VS .VE .UL
        .QW .PQ .QR .AS .AE .AP .BS .BE .so
    }

    # Breakpoint support
    variable breakOnMacro {}   ;# list of macros to break on
    variable breakOnLine -1    ;# line number to break on (-1 = off)
    variable breakCallback ""  ;# proc to call on break

    namespace export setup reset state coverage unhandled
    namespace export macro line
    namespace export setBreak clearBreak
    namespace ensemble create
}

# debug::nroff setup --
#   Register nroff trace categories and reset statistics.
#   Call before parsing.
proc debug::nroff::setup {} {
    variable macroCount
    variable unhandledMacros
    variable totalLines
    variable totalMacros

    set macroCount {}
    set unhandledMacros {}
    set totalLines 0
    set totalMacros 0

    debug::trace::register macro   1
    debug::trace::register line    2
    debug::trace::register state   2
    debug::trace::register render  2
    debug::trace::register inline  3
}

# debug::nroff reset --
#   Reset statistics only (keep categories).
proc debug::nroff::reset {} {
    variable macroCount {}
    variable unhandledMacros {}
    variable totalLines 0
    variable totalMacros 0
}

# debug::nroff macro --
#   Track a macro call. Called from parser's handleMacro.
#   Records statistics and checks breakpoints.
#
#   Args:
#     macro - macro name (e.g. ".SH")
#     ?rest? - arguments
proc debug::nroff::macro {macro {rest ""}} {
    variable macroCount
    variable unhandledMacros
    variable knownMacros
    variable totalMacros
    variable breakOnMacro
    variable breakCallback

    incr totalMacros
    dict incr macroCount $macro

    # Track unhandled macros
    if {$macro ni $knownMacros} {
        dict incr unhandledMacros $macro
    }

    # Trace output
    if {$rest ne ""} {
        debug::trace emit macro "$macro $rest"
    } else {
        debug::trace emit macro $macro
    }

    # Breakpoint check
    if {$macro in $breakOnMacro && $breakCallback ne ""} {
        debug::log 0 "BREAK on macro $macro"
        uplevel #0 $breakCallback [list $macro $rest]
    }
}

# debug::nroff line --
#   Track a line being processed.
#   Args:
#     lineno - line number
#     line   - line content
proc debug::nroff::line {lineno line} {
    variable totalLines
    variable breakOnLine
    variable breakCallback

    incr totalLines

    set preview [string range $line 0 60]
    if {[string length $line] > 60} {
        set preview "[string range $line 0 57]..."
    }
    debug::trace emit line "L$lineno: $preview"

    # Breakpoint check
    if {$lineno == $breakOnLine && $breakCallback ne ""} {
        debug::log 0 "BREAK on line $lineno"
        uplevel #0 $breakCallback [list $lineno $line]
    }
}

# debug::nroff state --
#   Inspect and log parser state. Shows mode, current paragraph,
#   list state, indent level, and flags.
#
#   Args:
#     state - parser state dict
proc debug::nroff::state {state} {
    set mode [dict get $state mode]

    set para [dict get $state currentParagraph]
    if {[string length $para] > 40} {
        set para "[string range $para 0 37]..."
    }

    set parts [list "mode=$mode"]
    if {$para ne ""} {
        lappend parts "para=\"$para\""
    }

    # Optional state fields
    foreach {key label} {
        indentLevel indent
        waitingForTerm waitTP
        inVSBlock inVS
        listKind listKind
    } {
        if {[dict exists $state $key]} {
            set val [dict get $state $key]
            if {$val ne "" && $val ne "0"} {
                lappend parts "$label=$val"
            }
        }
    }

    if {[dict exists $state tabStops]} {
        set tabs [dict get $state tabStops]
        if {[llength $tabs] > 0} {
            lappend parts "tabs=\[[join $tabs ,]\]"
        }
    }

    if {[dict exists $state ast]} {
        lappend parts "nodes=[llength [dict get $state ast]]"
    }

    debug::trace emit state [join $parts " | "]
}

# debug::nroff coverage --
#   Returns a coverage report as a dict.
#   Keys: total_lines, total_macros, macros (dict), unhandled (dict),
#         coverage_pct (float)
#
#   With -print flag, also prints the report to log.
proc debug::nroff::coverage {args} {
    variable macroCount
    variable unhandledMacros
    variable totalLines
    variable totalMacros
    variable knownMacros

    set print [expr {"-print" in $args}]

    set handled 0
    set unhandled 0
    dict for {m c} $macroCount {
        if {$m in $knownMacros} {
            incr handled $c
        } else {
            incr unhandled $c
        }
    }

    set pct [expr {$totalMacros > 0 ? 100.0 * $handled / $totalMacros : 100.0}]

    set result [dict create \
        total_lines   $totalLines \
        total_macros  $totalMacros \
        handled       $handled \
        unhandled     $unhandled \
        coverage_pct  [format "%.1f" $pct] \
        macros        $macroCount \
        unhandled_macros $unhandledMacros]

    if {$print} {
        debug::log 1 "=== Macro Coverage ==="
        debug::log 1 "Lines: $totalLines, Macros: $totalMacros"
        debug::log 1 "Handled: $handled, Unhandled: $unhandled ([format %.1f $pct]%)"

        if {[dict size $macroCount] > 0} {
            debug::log 1 "--- Macro counts ---"
            foreach m [lsort [dict keys $macroCount]] {
                set c [dict get $macroCount $m]
                set tag [expr {$m in $knownMacros ? "" : " (UNHANDLED)"}]
                debug::log 1 "  $m: $c$tag"
            }
        }
    }

    return $result
}

# debug::nroff unhandled --
#   Returns list of unhandled macros (sorted by frequency, descending).
proc debug::nroff::unhandled {} {
    variable unhandledMacros
    set pairs {}
    dict for {m c} $unhandledMacros {
        lappend pairs [list $m $c]
    }
    return [lsort -index 1 -integer -decreasing $pairs]
}

# ============================================================
# Breakpoints
# ============================================================

# debug::nroff setBreak --
#   Set a breakpoint on a macro or line number.
#   When hit, calls the callback with context info.
#
#   Args:
#     ?-macro name?    - break when this macro is encountered
#     ?-line number?   - break at this line number
#     ?-callback proc? - proc to call (default: prints state)
#
#   Example:
#     debug::nroff setBreak -macro .TP -callback {apply {{macro rest} {
#         puts "Hit .TP with args: $rest"
#     }}}
proc debug::nroff::setBreak {args} {
    variable breakOnMacro
    variable breakOnLine
    variable breakCallback

    foreach {opt val} $args {
        switch -- $opt {
            -macro {
                if {$val ni $breakOnMacro} {
                    lappend breakOnMacro $val
                }
            }
            -line {
                set breakOnLine $val
            }
            -callback {
                set breakCallback $val
            }
            default {
                error "debug::nroff::setBreak: unknown option $opt"
            }
        }
    }

    # Default callback: log
    if {$breakCallback eq ""} {
        set breakCallback {apply {{args} {
            puts "BREAKPOINT: $args"
        }}}
    }
}

# debug::nroff clearBreak --
#   Clear all breakpoints.
proc debug::nroff::clearBreak {} {
    variable breakOnMacro {}
    variable breakOnLine -1
    variable breakCallback ""
}

# ============================================================
# Wire into compat layer
# ============================================================
# Override the compat traceMacro/traceLine/traceState to use
# the nroff-specific tracking (statistics + breakpoints).

proc ::debug::traceMacro {macro args} {
    debug::nroff::macro $macro [join $args " "]
}

proc ::debug::traceLine {lineno line} {
    debug::nroff::line $lineno $line
}

proc ::debug::traceState {state} {
    debug::nroff::state $state
}

# ============================================================
# debug::scope – Call-Scope Tracing mit Indent
# ============================================================
#
# Verwendung:
#   debug::scope enter parseName      ;# ENTER: parseName
#   debug::scope leave parseName      ;# LEAVE: parseName
#   debug::scope enter parseName {arg val}  ;# mit Detail
#
#   Automatisch mit proc:
#   proc myproc {} {
#       debug::scope auto [info level 0]
#       # ... body ...
#   }
#
# Konfiguration:
#   debug::scope::setLevel 2   ;# ab Level 2 aktiv (default 3)
#   debug::scope::setEnabled 1 ;# ein/aus

namespace eval debug::scope {
    variable depth    0
    variable minLevel 3
    variable enabled  1
    variable timers   {}

    namespace export enter leave auto setLevel setEnabled reset depth
    namespace ensemble create
}

proc debug::scope::setLevel {lvl} {
    variable minLevel
    set minLevel $lvl
}

proc debug::scope::setEnabled {bool} {
    variable enabled
    set enabled $bool
}

proc debug::scope::reset {} {
    variable depth
    variable timers
    set depth  0
    set timers {}
}

proc debug::scope::depth {} {
    variable depth
    return $depth
}

proc debug::scope::enter {name {detail ""}} {
    variable depth
    variable minLevel
    variable enabled
    variable timers

    if {!$enabled} return
    set pad [string repeat "  " $depth]
    if {$detail ne ""} {
        debug::log $minLevel "${pad}→ ENTER $name  ($detail)"
    } else {
        debug::log $minLevel "${pad}→ ENTER $name"
    }
    incr depth
    dict set timers $name [clock microseconds]
}

proc debug::scope::leave {name {result ""}} {
    variable depth
    variable minLevel
    variable enabled
    variable timers

    if {!$enabled} return
    if {$depth > 0} { incr depth -1 }
    set pad [string repeat "  " $depth]

    # Elapsed Zeit wenn Timer vorhanden
    set elapsed ""
    if {[dict exists $timers $name]} {
        set us [expr {[clock microseconds] - [dict get $timers $name]}]
        dict unset timers $name
        if {$us >= 1000} {
            set elapsed [format "  %.1f ms" [expr {$us / 1000.0}]]
        } else {
            set elapsed "  ${us} µs"
        }
    }

    if {$result ne ""} {
        debug::log $minLevel "${pad}← LEAVE $name$elapsed  → $result"
    } else {
        debug::log $minLevel "${pad}← LEAVE $name$elapsed"
    }
}

# debug::scope::auto --
#   Automatisches ENTER + LEAVE via trace auf aktuellen Stack-Frame.
#   Aufruf am Anfang einer Proc:
#     proc myproc {args} {
#         debug::scope auto [info level 0]
#         ...
#     }
#
#   Nutzt Tcl's trace mechanism um LEAVE beim Return automatisch
#   zu triggern.
proc debug::scope::auto {callInfo} {
    variable enabled
    if {!$enabled} return

    # Proc-Name aus callInfo extrahieren
    set name [lindex $callInfo 0]
    set args [lrange $callInfo 1 end]

    set detail ""
    if {[llength $args] > 0} {
        # Erste 2 Argumente als Detail (gekürzt)
        set parts {}
        foreach a [lrange $args 0 1] {
            if {[string length $a] > 20} { set a "[string range $a 0 17]…" }
            lappend parts $a
        }
        set detail [join $parts " "]
    }

    debug::scope enter $name $detail

    # Trace für automatisches LEAVE beim Return des aufrufenden Frames
    # Level 1 = aufrufender Frame
    uplevel 1 [list trace add variable ___scope_dummy_[info level] write {}]
    set lvl [expr {[info level] - 1}]
    uplevel 1 [list trace add execution [lindex $callInfo 0] leave \
        [list ::debug::scope::_autoLeave $name]]
}

proc debug::scope::_autoLeave {name args} {
    debug::scope leave $name
    # Trace sich selbst entfernen
    catch {trace remove execution $name leave \
        [list ::debug::scope::_autoLeave $name]}
}

# ===========================================================================
# EMBEDDED: nroffparser-0.2.tm
# ===========================================================================

# nroffparser-0.2.tm
#
# Nroff parser that produces a Tcl-friendly AST (Nroff-AST v1).
#
# Architecture (refactored):
# - parse: public API, delegates to parseLines -> parseBlocks -> finalizeState
# - parseLines: file reading and preprocessing
# - parseBlocks: block-driven parser with explicit state
# - handleLine: central state machine
# - AST-Spec compliant: every node has type, content, meta
#
# Version: 0.2
# Author: Refactored according to AST-Spec

# Load debug module if available (try any version, then create stubs)
if {[catch {package require debug}]} {
    # Debug module not available - create minimal stubs
    namespace eval debug {
        proc log {lvl msg} {}
        proc traceLine {lineno line} {}
        proc traceMacro {macro args} {}
        proc traceState {state} {}
        proc assert {condition message} {}
        proc startTimer {name} {}
        proc stopTimer {name} {return 0}
        proc getLevel {} {return 0}
        proc validateAST {ast {strict 1}} {}
    }
}

namespace eval nroffparser {
    namespace export parse validate
    variable warnings {}
    variable lineNumber 0
    variable includeStack {}  ;# Track included files for cycle detection
    variable _specialCharMap  ;# Lazy-initialized special char dict
}

# ============================================================
# Public API (unchanged)
# ============================================================

proc nroffparser::parse {nroffText {sourceFile ""}} {
    variable warnings
    variable lineNumber
    variable includeStack
    set warnings {}
    set lineNumber 0
    set includeStack {}
    
    debug::startTimer "parse"
    debug::scope enter parse [expr {$sourceFile ne "" ? $sourceFile : "(string)"}]
    
    # Normalize line endings
    set nroffText [string map {"\r\n" "\n" "\r" "\n"} $nroffText]
    set lines [split $nroffText "\n"]
    
    debug::log 1 "Parsing [llength $lines] lines"
    if {$sourceFile ne ""} {
        debug::log 1 "Source file: $sourceFile"
    }
    
    # Preprocess lines (includes .so processing)
    set lines [nroffparser::parseLines $lines $sourceFile]
    
    # Phase 1: Parse blocks with explicit state (raw text)
    debug::scope enter parseBlocks "[llength $lines] lines"
    set ast [nroffparser::parseBlocks $lines]
    debug::scope leave parseBlocks "[llength $ast] nodes"
    
    debug::log 1 "Phase 1 complete: [llength $ast] nodes"
    
    # Phase 2: Parse inlines (convert raw text to inline structures)
    debug::scope enter parseInlines "[llength $ast] nodes"
    set ast [nroffparser::parseInlinesPhase $ast]
    debug::scope leave parseInlines "[llength $ast] nodes"
    
    debug::log 1 "Phase 2 complete: [llength $ast] nodes"
    
    # Validiere AST (wenn Debug-Level >= 1)
    if {[debug::getLevel] >= 1} {
        if {[catch {debug::validateAST $ast 0} result]} {
            debug::log 0 "AST validation failed: $result"
        }
    }
    
    debug::stopTimer "parse"
    debug::scope leave parse "[llength $ast] nodes"
    
    return $ast
}

proc nroffparser::validate {ast} {
    # AST-Spec: ast is a list of node-dicts
    if {![llength $ast]} {
        error "nroffparser::validate: empty AST"
    }
    
    set validTypes {heading section subsection paragraph list pre blank}
    set validInlineTypes {text strong emphasis underline}
    
    foreach node $ast {
        # Check: node is a dict
        if {![llength $node] || [llength $node] % 2 != 0} {
            error "nroffparser::validate: node is not a dict: $node"
        }
        
        # Check: required fields exist
        if {![dict exists $node type]} {
            error "nroffparser::validate: node missing 'type': $node"
        }
        if {![dict exists $node content]} {
            error "nroffparser::validate: node missing 'content': $node"
        }
        if {![dict exists $node meta]} {
            error "nroffparser::validate: node missing 'meta': $node"
        }
        
        # Check: type is valid
        set type [dict get $node type]
        if {$type ni $validTypes} {
            error "nroffparser::validate: invalid type '$type' (allowed: $validTypes)"
        }
        
        # Check: meta is a dict
        set meta [dict get $node meta]
        if {[llength $meta] % 2 != 0} {
            error "nroffparser::validate: 'meta' is not a dict: $meta"
        }
        
        # Check: content structure based on type
        set content [dict get $node content]
        
        switch $type {
            paragraph {
                # Content should be a list of inline nodes
                if {[llength $content] > 0} {
                    foreach inline $content {
                        if {![dict exists $inline type]} {
                            error "nroffparser::validate: inline missing 'type': $inline"
                        }
                        if {![dict exists $inline text]} {
                            error "nroffparser::validate: inline missing 'text': $inline"
                        }
                        set inlineType [dict get $inline type]
                        if {$inlineType ni $validInlineTypes} {
                            error "nroffparser::validate: invalid inline type '$inlineType'"
                        }
                    }
                }
            }
            list {
                # Content should be a list of items
                # Check if this is an .OP list (term is string, not inline)
                set isOPList 0
                if {[dict exists $meta listKind] && [dict get $meta listKind] eq "op"} {
                    set isOPList 1
                }
                
                foreach item $content {
                    if {![dict exists $item term]} {
                        error "nroffparser::validate: list item missing 'term': $item"
                    }
                    if {![dict exists $item desc]} {
                        error "nroffparser::validate: list item missing 'desc': $item"
                    }
                    set term [dict get $item term]
                    set desc [dict get $item desc]
                    
                    # For .OP lists, term is a string (pipe-separated), not inline
                    if {$isOPList} {
                        # term should be a string - skip inline validation
                        # Just check that it's not empty (optional check)
                    } else {
                        # Normal list: validate term as inline list
                        # Check if term is actually a list of inline dicts (not just any list)
                        if {[string is list $term] && [llength $term] > 0} {
                            set first [lindex $term 0]
                            # Only validate as inlines if first element is a dict with 'type' key
                            if {[dict exists $first type]} {
                                foreach in $term {
                                    if {![dict exists $in type]} {
                                        error "nroffparser::validate: inline missing 'type': $in"
                                    }
                                    if {![dict exists $in text]} {
                                        error "nroffparser::validate: inline missing 'text': $in"
                                    }
                                    set inlineType [dict get $in type]
                                    if {$inlineType ni $validInlineTypes} {
                                        error "nroffparser::validate: invalid inline type '$inlineType'"
                                    }
                                }
                            }
                            # If first element is not a dict with 'type', it's probably a string
                            # (like in .OP lists) - skip validation
                        }
                    }
                    
                    # Always validate desc as inline list (even for .OP)
                    # desc can be empty string or a list of inlines
                    if {$desc ne ""} {
                        if {[string is list $desc] && [llength $desc] > 0} {
                            foreach in $desc {
                                if {![dict exists $in type]} {
                                    error "nroffparser::validate: inline missing 'type': $in"
                                }
                                if {![dict exists $in text]} {
                                    error "nroffparser::validate: inline missing 'text': $in"
                                }
                                set inlineType [dict get $in type]
                                if {$inlineType ni $validInlineTypes} {
                                    error "nroffparser::validate: invalid inline type '$inlineType'"
                                }
                            }
                        }
                        # If desc is not a list, it might be a string (before parseInlinesPhase)
                        # This is OK - skip validation in that case
                    }
                }
            }
        }
    }
    
    return 1
}

# ============================================================
# Phase 1: Line preprocessing
# ============================================================

# resolveIncludePath --
# Resolve include file path for .so directive
# Args:
#   includeFile - File name from .so directive
#   sourceFile - Current source file (for relative path resolution)
# Returns:
#   Resolved absolute path, or empty string if not found
proc nroffparser::resolveIncludePath {includeFile {sourceFile ""}} {
    # If absolute path, use as-is
    if {[file pathtype $includeFile] eq "absolute"} {
        return $includeFile
    }
    
    # Try relative to source file directory
    if {$sourceFile ne "" && [file exists $sourceFile]} {
        set sourceDir [file dirname $sourceFile]
        set resolved [file join $sourceDir $includeFile]
        if {[file exists $resolved]} {
            return [file normalize $resolved]
        }
    }
    
    # Try current working directory
    if {[file exists $includeFile]} {
        return [file normalize $includeFile]
    }
    
    # Try common man page directories (if sourceFile is in a man page structure)
    if {$sourceFile ne ""} {
        set sourceDir [file dirname $sourceFile]
        # Check parent directories for common locations
        foreach checkDir [list $sourceDir [file dirname $sourceDir] [file dirname [file dirname $sourceDir]]] {
            set resolved [file join $checkDir $includeFile]
            if {[file exists $resolved]} {
                return [file normalize $resolved]
            }
        }
    }
    
    # Not found
    return ""
}

proc nroffparser::parseLines {lines {sourceFile ""}} {
    variable includeStack
    variable warnings
    set result {}
    set inMacroDef 0  ;# Track if we're inside a .de ... .. macro definition
    
    foreach line $lines {
        # Check for .so include directive
        if {[regexp {^\.so\s+(.+)$} $line -> includeFile]} {
            # Remove quotes if present
            set includeFile [string trim $includeFile "\""]
            set includeFile [string trim $includeFile "'"]
            
            # Resolve include file path
            set resolvedPath [nroffparser::resolveIncludePath $includeFile $sourceFile]
            
            if {$resolvedPath ne "" && [file exists $resolvedPath]} {
                # Check for cycles
                set normalizedPath [file normalize $resolvedPath]
                if {$normalizedPath in $includeStack} {
                    lappend warnings "Include cycle detected: $includeFile (already in stack)"
                    continue
                }
                
                # Load and process included file
                lappend includeStack $normalizedPath
                if {[catch {
                    set fh [open $resolvedPath r]
                    fconfigure $fh -encoding utf-8
                    set includeContent [read $fh]
                    close $fh
                    
                    # Normalize line endings
                    set includeContent [string map {"\r\n" "\n" "\r" "\n"} $includeContent]
                    set includeLines [split $includeContent "\n"]
                    
                    # Recursively process included file
                    set includeDir [file dirname $resolvedPath]
                    set processedInclude [nroffparser::parseLines $includeLines $resolvedPath]
                    
                    # Append processed lines to result
                    foreach incLine $processedInclude {
                        lappend result $incLine
                    }
                } err]} {
                    lappend warnings "Failed to load include file '$includeFile': $err"
                }
                set includeStack [lrange $includeStack 0 end-1]  ;# Remove from stack
            } else {
                lappend warnings "Include file not found: $includeFile"
            }
            continue
        }
        
        # Handle macro definition boundaries (.de ... ..)
        if {[regexp {^\.de\s} $line]} {
            set inMacroDef 1
            continue
        }
        if {[regexp {^\.\.$} $line]} {
            set inMacroDef 0
            continue
        }
        
        # If we're inside a macro definition, skip all lines until ..
        if {$inMacroDef} {
            continue
        }
        
        # Ignore other macro definition commands (from man.macros and similar files)
        # These are nroff/troff commands that define macros, not content
        # Use string match for simpler patterns (more reliable than regexp for these)
        set macroDefPrefixes {
            ".if " ".ie " ".el " ".nr " ".mk " ".ad " ".wh " ".ti " ".bp " ".ev " ".ft " ".ds " ".as " ".\\"
            "'ie " "'el " "'mc " "'nf " "'fi " "'ti " "'bp " "'ev "
        }
        set isMacroDef 0
        set matchedPrefix ""
        foreach prefix $macroDefPrefixes {
            if {[string match "${prefix}*" $line]} {
                set isMacroDef 1
                set matchedPrefix $prefix
                break
            }
        }
        if {$isMacroDef} {
            # Log debug warning about filtered macro (level 3 - only in debug mode)
            debug::log 3 "Filtered macro definition command: [string range $line 0 40]..."
            continue
        }
        
        # Remove comments
        # Pattern 1: .\" at start (standard nroff comment)
        if {[string match ".\\\"*" $line]} { continue }
        # Pattern 2: \" at start (nroff comment)
        if {[string match "\\\"*" $line]} { continue }
        # Pattern 3: '\" at start (man page comment with single quote)
        if {[regexp {^'\\"} $line]} { continue }
        # Pattern 4: Check for '\" at start (alternative pattern)
        if {[string length $line] >= 3} {
            set char0 [string index $line 0]
            set char1 [string index $line 1]
            set char2 [string index $line 2]
            if {$char0 eq "'" && $char1 eq "\\" && $char2 eq "\""} {
                continue
            }
        }
        # Pattern 5: .\" anywhere in line (inline comment) - remove comment part
        # But only if it's not part of an escape sequence
        if {[regexp {\.\\"[^\n]*} $line]} {
            set line [regsub {\.\\"[^\n]*} $line ""]
        }
        
        # Handle empty lines: create blank nodes instead of removing them
        set trimmed [string trimright $line]
        if {$trimmed eq ""} {
            # Create a blank node instead of skipping
            lappend result [dict create type blank meta [dict create lines 1]]
            continue
        }
        
        lappend result $trimmed
    }
    
    return $result
}

# ============================================================
# Phase 2: Block parsing with explicit state
# ============================================================

proc nroffparser::parseBlocks {lines} {
    # Initialize explicit parser state
    set state [dict create \
        mode normal \
        currentParagraph "" \
        currentList {} \
        listKind "" \
        preText "" \
        waitingForTerm 0 \
        justProcessedTPTerm 0 \
        indentLevel 0 \
        listStack {} \
        tabStops {} \
        inVSBlock 0 \
        vsVersion "" \
        inSeeAlso 0 \
        currentSection "" \
        ast {}]
    
    # Process each line
    foreach line $lines {
        # Check if this is already a blank node (from parseLines)
        if {[string is list $line] && [llength $line] > 0} {
            if {[catch {dict get $line type} type] == 0 && $type eq "blank"} {
                # This is a blank node - add directly to AST
                set ast [dict get $state ast]
                lappend ast $line
                dict set state ast $ast
                continue
            }
        }
        set state [nroffparser::handleLine $state $line]
    }
    
    # Finalize state (flush remaining content)
    set ast [nroffparser::finalizeState $state]
    
    # Merge consecutive blank nodes to reduce clutter
    # (especially after filtering macro definitions from man.macros)
    set mergedAst {}
    set lastWasBlank 0
    set blankLines 0
    
    foreach node $ast {
        set type [dict get $node type]
        if {$type eq "blank"} {
            set lastWasBlank 1
            incr blankLines
        } else {
            if {$lastWasBlank && $blankLines > 0} {
                # Add merged blank node (max 2 blank lines to avoid excessive whitespace)
                set mergedLines [expr {min($blankLines, 2)}]
                lappend mergedAst [dict create type blank meta [dict create lines $mergedLines]]
                set blankLines 0
                set lastWasBlank 0
            }
            lappend mergedAst $node
        }
    }
    
    # Handle trailing blank nodes
    if {$lastWasBlank && $blankLines > 0} {
        set mergedLines [expr {min($blankLines, 2)}]
        lappend mergedAst [dict create type blank meta [dict create lines $mergedLines]]
    }
    
    return $mergedAst
}

# ============================================================
# Central state machine: handleLine
# ============================================================

proc nroffparser::handleLine {state line} {
    variable lineNumber
    incr lineNumber
    
    set mode [dict get $state mode]
    
    debug::traceLine $lineNumber $line
    debug::traceState $state
    
    # Check if line is a macro FIRST (even in pre mode, some macros should be recognized)
    # But ignore single "." - it's not a macro, just a period
    if {[string match ".*" $line] && $line ne "."} {
        # In pre mode, only recognize closing macros and important block macros
        if {$mode eq "pre"} {
            set macro [lindex [split $line] 0]
            # Recognize closing macros
            if {$macro eq ".fi" || $macro eq ".CE" || $macro eq ".DE" || $macro eq ".BE" || $macro eq ".SE" || $macro eq ".VE"} {
                debug::traceMacro $macro "in pre mode"
                return [nroffparser::handleMacro $state $line]
            }
            # Also recognize section macros even in pre mode (they should break out)
            if {$macro eq ".SH" || $macro eq ".SS" || $macro eq ".TH"} {
                debug::traceMacro $macro "breaking out of pre mode"
                # Flush pre block and process macro
                set state [nroffparser::flushPre $state]
                dict set state mode normal
                return [nroffparser::handleMacro $state $line]
            }
            # Also recognize .sp in pre mode (it should create blank lines)
            if {$macro eq ".sp"} {
                debug::traceMacro $macro "in pre mode"
                return [nroffparser::handleMacro $state $line]
            }
            # Also recognize .ta in pre mode (it sets tab stops for following lines)
            if {$macro eq ".ta"} {
                debug::traceMacro $macro "in pre mode"
                return [nroffparser::handleMacro $state $line]
            }
            # Otherwise, treat as preformatted text
            return [nroffparser::handlePreLine $state $line]
        }
        return [nroffparser::handleMacro $state $line]
    }
    
    if {$mode eq "pre"} {
        return [nroffparser::handlePreLine $state $line]
    }
    
    # Regular text line
    return [nroffparser::handleText $state $line]
}

# ============================================================
# Macro handling (block level)
# ============================================================

proc nroffparser::handleMacro {state line} {
    # Split macro name and arguments
    set parts [split $line]
    set macro [lindex $parts 0]
    set rest [string trim [string range $line [string length $macro] end]]
    
    debug::traceMacro $macro $rest
    
    switch -- $macro {
        . {
            # Single dot - nroff macro that renders a period
            # BUT: Ignore if it comes right after a .TP term (it's a separator, not content)
            if {[dict exists $state justProcessedTPTerm] && [dict get $state justProcessedTPTerm]} {
                dict set state justProcessedTPTerm 0
                return $state
            }
            # Add period to current paragraph
            set cur [dict get $state currentParagraph]
            if {$cur eq ""} {
                dict set state currentParagraph "."
            } else {
                dict set state currentParagraph "$cur ."
            }
            return $state
        }
        .TH {
            set state [nroffparser::flushParagraph $state]
            set state [nroffparser::handleTH $state $rest]
        }
        .SH {
            set state [nroffparser::flushParagraph $state]
            set state [nroffparser::flushList $state]
            set state [nroffparser::handleSH $state $rest]
        }
        .SS {
            set state [nroffparser::flushParagraph $state]
            set state [nroffparser::flushList $state]
            set state [nroffparser::handleSS $state $rest]
        }
        .TP {
            set state [nroffparser::flushParagraph $state]
            # Start list if not already started, or if different kind
            set currentList [dict get $state currentList]
            if {[dict exists $state listKind]} {
                set listKind [dict get $state listKind]
            } else {
                set listKind ""
            }
            if {[llength $currentList] == 0 || $listKind ne "tp"} {
                set state [nroffparser::startList $state tp]
            }
            # .TP term is on next line, mark state
            dict set state waitingForTerm 1
        }
        .IP {
            set state [nroffparser::flushParagraph $state]
            set state [nroffparser::handleIP $state $rest]
        }
        .PP -
        .LP {
            set state [nroffparser::flushParagraph $state]
            # .PP/.LP just start a new paragraph (implicit)
        }
        .nf {
            set state [nroffparser::flushParagraph $state]
            set state [nroffparser::flushList $state]
            dict set state mode pre
            dict set state preText ""
        }
        .fi {
            set state [nroffparser::flushPre $state]
            dict set state mode normal
        }
        .CS {
            set state [nroffparser::flushParagraph $state]
            set state [nroffparser::flushList $state]
            dict set state mode pre
            dict set state preText ""
        }
        .CE {
            set state [nroffparser::flushPre $state]
            dict set state mode normal
        }
        .DS {
            set state [nroffparser::flushParagraph $state]
            set state [nroffparser::flushList $state]
            dict set state mode pre
            dict set state preText ""
        }
        .DE {
            set state [nroffparser::flushPre $state]
            dict set state mode normal
        }
        .br {
            set state [nroffparser::flushParagraph $state]
            set state [nroffparser::appendNode $state blank "" {}]
        }
        .sp {
            set state [nroffparser::flushParagraph $state]
            set lines 1
            if {[regexp {^\.sp\s+([0-9]+)} $line -> num]} {
                set lines $num
            }
            set state [nroffparser::appendNode $state blank "" [dict create lines $lines]]
        }
        .RS {
            # Relative start: aktuellen List-Kontext auf Stack sichern
            set state [nroffparser::flushParagraph $state]
            set indentLevel [dict get $state indentLevel]
            # Stack-Frame mit aktuellem Kontext
            set frame [dict create \
                indentLevel $indentLevel \
                currentList [dict get $state currentList] \
                listKind    [dict get $state listKind]]
            set listStack [dict get $state listStack]
            lappend listStack $frame
            dict set state listStack   $listStack
            dict set state indentLevel [expr {$indentLevel + 1}]
            dict set state currentList {}
            dict set state listKind    ""
        }
        .RE {
            # Relative end: Liste auf diesem Level flushen, Stack-Frame holen
            set state [nroffparser::flushParagraph $state]
            set state [nroffparser::flushList $state]
            set listStack [dict get $state listStack]
            if {[llength $listStack] > 0} {
                # Letzten Frame holen und wiederherstellen
                set frame    [lindex $listStack end]
                set listStack [lrange $listStack 0 end-1]
                dict set state listStack   $listStack
                dict set state indentLevel [dict get $frame indentLevel]
                dict set state currentList [dict get $frame currentList]
                dict set state listKind    [dict get $frame listKind]
            } else {
                # Kein Frame – nur indentLevel verringern
                set indentLevel [dict get $state indentLevel]
                if {$indentLevel > 0} {
                    dict set state indentLevel [expr {$indentLevel - 1}]
                }
            }
        }
        .BS {
            # Box start - for now, treat as pre
            set state [nroffparser::flushParagraph $state]
            set state [nroffparser::flushList $state]
            dict set state mode pre
            dict set state preText ""
        }
        .BE {
            # Box end
            set state [nroffparser::flushPre $state]
            dict set state mode normal
        }
        .OP {
            set state [nroffparser::flushParagraph $state]
            set state [nroffparser::handleOP $state $rest]
        }
        .ta {
            # Set tab stops
            # Format: .ta stop1 stop2 stop3 ...
            # Each stop can be a number (in basic units) or number+unit (e.g., 3i = 3 inches)
            set state [nroffparser::flushParagraph $state]
            set state [nroffparser::handleTA $state $rest]
        }
        .AP {
            # Argument parameter (Tcl/Tk specific) - skip it, content is on next line
            return $state
        }
        .AS {
            # Argument start (Tcl/Tk specific) - skip it
            return $state
        }
        .AE {
            # Argument end (Tcl/Tk specific) - skip it
            return $state
        }
        .so {
            # Source/include - already processed in parseLines
            # This case should not be reached, but keep for safety
            return $state
        }
        .VS {
            # Version Start - mark version-specific content
            # Format: .VS ?version?
            # Version can be quoted or unquoted (e.g., "TIP508" or TIP508)
            set state [nroffparser::handleVS $state $rest]
        }
        .VE {
            # Version End - end version-specific content
            # Format: .VE ?version?
            set state [nroffparser::handleVE $state $rest]
        }
        .UL {
            # Underline: .UL arg1 arg2
            # Print arg1 underlined, then print arg2 normally
            # Don't flush paragraph - .UL adds to current paragraph
            
            # Parse arguments - handle quoted strings properly
            set arg1 ""
            set arg2 ""
            set inQuotes 0
            set current ""
            set len [string length $rest]
            
            for {set i 0} {$i < $len} {incr i} {
                set char [string index $rest $i]
                if {$char eq "\""} {
                    if {$inQuotes} {
                        # End of quoted string
                        if {$arg1 eq ""} {
                            set arg1 $current
                        } else {
                            set arg2 $current
                        }
                        set current ""
                        set inQuotes 0
                    } else {
                        # Start of quoted string
                        set inQuotes 1
                    }
                } elseif {$char eq " " && !$inQuotes && $arg1 ne ""} {
                    # Space outside quotes - start arg2
                    set arg2 [string trim [string range $rest [expr {$i + 1}] end]]
                    break
                } else {
                    append current $char
                }
            }
            
            # If we're still in quotes, arg1 is current
            if {$inQuotes && $arg1 eq ""} {
                set arg1 $current
            } elseif {$arg1 eq "" && $current ne ""} {
                # No quotes, first argument
                set arg1 $current
            }
            
            # Remove outer quotes if present
            set arg1 [string trim $arg1 "\""]
            set arg2 [string trim $arg2 "\""]
            
            # Create text with underline marker
            # We'll use a special marker that parseInlines can recognize
            # Format: \UL[open]text[close]\UL[close] where [open]=123 and [close]=125
            # We need to check for \UL...\UL pattern in parseInlines
            set openBr [string index "\{" 0]
            set closeBr [string index "\}" 0]
            set underlineText "\\UL"
            append underlineText $openBr $arg1 $closeBr
            append underlineText "\\UL" $closeBr
            if {$arg2 ne ""} {
                append underlineText " " $arg2
            }
            
            # Add to current paragraph
            set cur [dict get $state currentParagraph]
            if {$cur eq ""} {
                dict set state currentParagraph $underlineText
            } else {
                dict set state currentParagraph "$cur $underlineText"
            }
            return $state
        }
        .UR {
            # URL Reference start: .UR url
            # Text until .UE becomes the link text
            set state [nroffparser::flushParagraph $state]
            dict set state inUR   1
            dict set state urHref [string trim $rest]
            dict set state urText ""
            return $state
        }
        .UE {
            # URL Reference end: .UE [punct]
            # Flush collected urText as a link inline into current paragraph
            set href    [dict get $state urHref]
            set urText  [string trim [dict get $state urText]]
            set punct   [string trim $rest]
            # Link-Text: urText wenn vorhanden, sonst href
            if {$urText eq ""} { set urText $href }
            # Als Inline-Node direkt in currentParagraph-Inlines speichern
            # Trick: wir speichern als speziellen Escape im Paragraph-Text
            # und lösen ihn im Inline-Parser auf – ODER wir hängen direkt
            # an eine pendingInlines-Liste.
            # Einfachste Lösung: URL-Link als Text-Markierung einfügen
            set linkMark "\[ur|$href|$urText\]"
            set cur [dict get $state currentParagraph]
            if {$cur eq ""} {
                dict set state currentParagraph $linkMark
            } else {
                dict set state currentParagraph "$cur $linkMark"
            }
            if {$punct ne ""} {
                dict set state currentParagraph                     "[dict get $state currentParagraph]$punct"
            }
            dict set state inUR   0
            dict set state urHref ""
            dict set state urText ""
            return $state
        }
        .MT {
            # Manual Title - empty string, just calls .QW ""
            # Don't flush paragraph - .MT adds to current paragraph
            set cur [dict get $state currentParagraph]
            if {$cur eq ""} {
                dict set state currentParagraph "\"\""
            } else {
                dict set state currentParagraph "$cur \"\""
            }
            return $state
        }
        .SO {
            # Standard Options start - create section and start pre block
            set state [nroffparser::flushParagraph $state]
            set state [nroffparser::flushList $state]
            set state [nroffparser::handleSO $state $rest]
        }
        .SE {
            # Standard Options end - end pre block and add reference
            set state [nroffparser::handleSE $state]
        }
        .QW {
            # Quote word: .QW arg1 ?arg2?
            # Print arg1 in quotes, then arg2 normally (for trailing punctuation)
            # Don't flush paragraph - .QW adds to current paragraph
            
            # Parse arguments - handle quoted strings properly
            set arg1 ""
            set arg2 ""
            set inQuotes 0
            set current ""
            set len [string length $rest]
            
            for {set i 0} {$i < $len} {incr i} {
                set char [string index $rest $i]
                if {$char eq "\""} {
                    if {$inQuotes} {
                        # End of quoted string
                        set arg1 $current
                        set current ""
                        set inQuotes 0
                    } else {
                        # Start of quoted string
                        set inQuotes 1
                    }
                } elseif {$char eq " " && !$inQuotes && $arg1 ne ""} {
                    # Space outside quotes - start arg2
                    set arg2 [string trim [string range $rest [expr {$i + 1}] end]]
                    break
                } else {
                    append current $char
                }
            }
            
            # If we're still in quotes, arg1 is current
            if {$inQuotes && $arg1 eq ""} {
                set arg1 $current
            }
            
            # Remove outer quotes from arg1 if present (they'll be added back)
            set arg1 [string trim $arg1 "\""]
            
            # Create quoted text: "arg1" arg2
            set quotedText "\"$arg1\""
            if {$arg2 ne ""} {
                append quotedText " $arg2"
            }
            
            # Add to current paragraph
            set cur [dict get $state currentParagraph]
            if {$cur eq ""} {
                dict set state currentParagraph $quotedText
            } else {
                dict set state currentParagraph "$cur $quotedText"
            }
            return $state
        }
        .PQ {
            # Parenthesized quote: .PQ arg1 ?arg2? ?arg3?
            # Print (arg1 in quotes arg2) arg3
            # Don't flush paragraph - .PQ adds to current paragraph
            
            # Parse similar to .QW
            set arg1 ""
            set arg2 ""
            set arg3 ""
            set inQuotes 0
            set current ""
            set len [string length $rest]
            set argNum 1
            
            for {set i 0} {$i < $len} {incr i} {
                set char [string index $rest $i]
                if {$char eq "\""} {
                    if {$inQuotes} {
                        if {$argNum == 1} {
                            set arg1 $current
                        } elseif {$argNum == 2} {
                            set arg2 $current
                        }
                        set current ""
                        set inQuotes 0
                        incr argNum
                    } else {
                        set inQuotes 1
                    }
                } elseif {$char eq " " && !$inQuotes} {
                    if {$current ne ""} {
                        if {$argNum == 1 && $arg1 eq ""} {
                            set arg1 $current
                        } elseif {$argNum == 2 && $arg2 eq ""} {
                            set arg2 $current
                        } elseif {$argNum == 3} {
                            set arg3 $current
                        }
                        set current ""
                        incr argNum
                    }
                } else {
                    append current $char
                }
            }
            
            if {$current ne ""} {
                if {$argNum == 1} {
                    set arg1 $current
                } elseif {$argNum == 2} {
                    set arg2 $current
                } else {
                    set arg3 $current
                }
            }
            
            set arg1 [string trim $arg1 "\""]
            set quotedText "(\"$arg1\""
            if {$arg2 ne ""} {
                append quotedText " $arg2"
            }
            append quotedText ")"
            if {$arg3 ne ""} {
                append quotedText " $arg3"
            }
            
            set cur [dict get $state currentParagraph]
            if {$cur eq ""} {
                dict set state currentParagraph $quotedText
            } else {
                dict set state currentParagraph "$cur $quotedText"
            }
            return $state
        }
        .QR {
            # Quoted range: .QR arg1 arg2 ?arg3?
            # Print "arg1" - "arg2" arg3
            # Don't flush paragraph - .QR adds to current paragraph
            
            # Parse two quoted arguments
            set arg1 ""
            set arg2 ""
            set arg3 ""
            set inQuotes 0
            set current ""
            set len [string length $rest]
            set argNum 1
            
            for {set i 0} {$i < $len} {incr i} {
                set char [string index $rest $i]
                if {$char eq "\""} {
                    if {$inQuotes} {
                        if {$argNum == 1} {
                            set arg1 $current
                        } elseif {$argNum == 2} {
                            set arg2 $current
                        }
                        set current ""
                        set inQuotes 0
                        incr argNum
                    } else {
                        set inQuotes 1
                    }
                } elseif {$char eq " " && !$inQuotes && $argNum > 2} {
                    set arg3 [string trim [string range $rest [expr {$i + 1}] end]]
                    break
                } elseif {$char ne " " || $inQuotes} {
                    append current $char
                }
            }
            
            set arg1 [string trim $arg1 "\""]
            set arg2 [string trim $arg2 "\""]
            set quotedText "\"$arg1\" - \"$arg2\""
            if {$arg3 ne ""} {
                append quotedText " $arg3"
            }
            
            set cur [dict get $state currentParagraph]
            if {$cur eq ""} {
                dict set state currentParagraph $quotedText
            } else {
                dict set state currentParagraph "$cur $quotedText"
            }
            return $state
        }
        default {
            # Unknown macro - treat as text
            return [nroffparser::handleText $state $line]
        }
    }
    
    return $state
}

# ============================================================
# Specific macro handlers
# ============================================================

proc nroffparser::handleTH {state rest} {
    # Parse .TH name section [volume] [date] [source] [manual]
    set parts {}
    set inQuotes 0
    set current ""
    set len [string length $rest]
    
    for {set j 0} {$j < $len} {incr j} {
        set char [string index $rest $j]
        if {$char eq "\""} {
            set inQuotes [expr {!$inQuotes}]
        } elseif {$char eq " " && !$inQuotes} {
            if {$current ne ""} {
                lappend parts $current
                set current ""
            }
        } else {
            append current $char
        }
    }
    if {$current ne ""} {
        lappend parts $current
    }
    
    set name [lindex $parts 0]
    set section [lindex $parts 1]
    set version [lindex $parts 2]
    set part [lindex $parts 3]
    set description [lrange $parts 4 end]
    
    # Remove quotes
    set name [string trim $name "\""]
    set section [string trim $section "\""]
    if {$version ne ""} {
        set version [string trim $version "\""]
    }
    if {$part ne ""} {
        set part [string trim $part "\""]
    }
    
    # AST-Spec: heading node
    return [nroffparser::appendNode $state heading $name [dict create \
        level 0 \
        name $name \
        section $section \
        version $version \
        part $part \
        description $description]]
}

proc nroffparser::handleSH {state rest} {
    # Handle quoted title: .SH "TITLE"
    set title ""
    if {[regexp {^"(.+)"} $rest -> title]} {
        set title [string trim $title]
    } elseif {$rest ne ""} {
        set title [string trim $rest]
    }

    # Track section for SEE ALSO link detection
    dict set state currentSection $title
    if {[string toupper $title] eq "SEE ALSO"} {
        dict set state inSeeAlso 1
    } else {
        dict set state inSeeAlso 0
    }

    # AST-Spec: section node
    return [nroffparser::appendNode $state section $title [dict create level 1]]
}

proc nroffparser::handleSS {state rest} {
    # Handle quoted title: .SS "TITLE"
    set title ""
    if {[regexp {^"(.+)"} $rest -> title]} {
        set title [string trim $title]
    } elseif {$rest ne ""} {
        set title [string trim $rest]
    }
    
    # AST-Spec: subsection node
    return [nroffparser::appendNode $state subsection $title [dict create level 2]]
}

proc nroffparser::handleOP {state rest} {
    # .OP cmdName dbName dbClass
    # Parse three arguments: command-line name, database name, database class
    set parts {}
    set inQuotes 0
    set current ""
    set len [string length $rest]
    
    for {set j 0} {$j < $len} {incr j} {
        set char [string index $rest $j]
        if {$char eq "\""} {
            set inQuotes [expr {!$inQuotes}]
        } elseif {$char eq " " && !$inQuotes} {
            if {$current ne ""} {
                lappend parts $current
                set current ""
            }
        } else {
            append current $char
        }
    }
    if {$current ne ""} {
        lappend parts $current
    }
    
    set cmdName [lindex $parts 0]
    set dbName [lindex $parts 1]
    set dbClass [lindex $parts 2]
    
    # Remove quotes if present
    set cmdName [string trim $cmdName "\""]
    set dbName [string trim $dbName "\""]
    set dbClass [string trim $dbClass "\""]
    
    # Start list if not already started or if different kind
    set currentList [dict get $state currentList]
    if {[dict exists $state listKind]} {
        set listKind [dict get $state listKind]
    } else {
        set listKind ""
    }
    if {[llength $currentList] == 0 || $listKind ne "op"} {
        set state [nroffparser::startList $state op]
        set currentList [dict get $state currentList]
    }
    
    # Store the three values as term (will be formatted by renderer)
    # Format: "cmdName|dbName|dbClass" for easy parsing in renderer
    set term "$cmdName|$dbName|$dbClass"
    lappend currentList [dict create term $term desc ""]
    dict set state currentList $currentList
    
    return $state
}

proc nroffparser::handleIP {state rest} {
    # .IP has term and optional width: .IP term [width]
    # Term can be quoted or unquoted, e.g. .IP "\fBR_OK\fR" or .IP path 10
    set term ""
    set width ""
    
    # Parse rest: handle quoted terms and optional width
    set rest [string trim $rest]
    if {$rest eq ""} {
        # Empty .IP - just start list
        set term ""
    } elseif {[regexp {^"([^"]+)"\s*(\d+)?} $rest -> term width]} {
        # Quoted term with optional width
        set term [string trim $term]
    } elseif {[regexp {^"([^"]+)"} $rest -> term]} {
        # Quoted term without width
        set term [string trim $term]
    } elseif {[regexp {^(.+?)\s+(\d+)$} $rest -> term width]} {
        # Unquoted term with width
        set term [string trim $term "\""]
    } else {
        # Just term, no width
        set term [string trim $rest "\""]
    }
    
    # Start list if not already started or if different kind
    set currentList [dict get $state currentList]
    if {[dict exists $state listKind]} {
        set listKind [dict get $state listKind]
    } else {
        set listKind ""
    }
    if {[llength $currentList] == 0 || $listKind ne "ip"} {
        set state [nroffparser::startList $state ip]
        set currentList [dict get $state currentList]
    }
    
    # Add item to current list
    lappend currentList [dict create term $term desc ""]
    dict set state currentList $currentList
    
    return $state
}

proc nroffparser::handleSO {state rest} {
    # .SO ?manpage?
    # Start of Standard Options - create section and start pre block
    set manpage [string trim $rest]
    if {$manpage eq ""} {
        set manpage "options"
    }
    
    # Remove quotes if present
    set manpage [string trim $manpage "\""]
    
    # Create section "STANDARD OPTIONS"
    set state [nroffparser::appendNode $state section "STANDARD OPTIONS" {}]
    
    # Start pre block (like .nf)
    dict set state mode pre
    dict set state preText ""
    
    # Store manpage reference for .SE
    dict set state soManpage $manpage
    
    return $state
}

proc nroffparser::handleVS {state rest} {
    # .VS - Version Start
    # Format: .VS ?version?
    # Version can be quoted (e.g., "TIP508") or unquoted (e.g., TIP508)
    # Marks the start of version-specific content
    
    # Parse version info (optional)
    set version ""
    if {$rest ne ""} {
        # Remove quotes if present
        set version [string trim $rest "\""]
    }
    
    # Mark that we're in a VS block
    dict set state inVSBlock 1
    dict set state vsVersion $version
    
    # Content will be processed normally (no mode change)
    # The version info is stored in state for potential use in rendering
    
    return $state
}

proc nroffparser::handleVE {state rest} {
    # .VE - Version End
    # Format: .VE ?version?
    # Ends version-specific content block
    
    # Check if we're actually in a VS block
    set inVSBlock 0
    if {[dict exists $state inVSBlock]} {
        set inVSBlock [dict get $state inVSBlock]
    }
    
    if {!$inVSBlock} {
        # Not in VS block - ignore (or warn?)
        return $state
    }
    
    # End VS block
    dict set state inVSBlock 0
    dict set state vsVersion ""
    
    # Content was processed normally, so no special cleanup needed
    
    return $state
}

proc nroffparser::handleSE {state} {
    # .SE - End of Standard Options
    # End pre block (like .fi)
    set state [nroffparser::flushPre $state]
    dict set state mode normal
    
    # Clear any pending paragraph (don't flush empty ones)
    dict set state currentParagraph ""
    
    # Add reference paragraph
    set manpage "options"
    if {[dict exists $state soManpage]} {
        set manpage [dict get $state soManpage]
        dict unset state soManpage
    }
    
    # Create reference paragraph
    set refText "See the $manpage manual entry for details on the standard options."
    set state [nroffparser::appendNode $state paragraph $refText {}]
    
    return $state
}

proc nroffparser::handleTA {state rest} {
    # .ta - Set tab stops
    # Format: .ta stop1 stop2 stop3 ...
    # Each stop can be a number (in basic units) or number+unit (e.g., 3i = 3 inches)
    # For now, we'll store the raw tab stops and use them for tab expansion
    # In a full implementation, we'd convert units to pixels/characters
    
    set tabStops {}
    if {$rest ne ""} {
        # Parse tab stops from rest
        set stops [split $rest]
        foreach stop $stops {
            set trimmed [string trim $stop]
            if {$trimmed ne ""} {
                lappend tabStops $trimmed
            }
        }
    }
    
    # Store tab stops in state
    dict set state tabStops $tabStops
    
    return $state
}

proc nroffparser::expandTabs {line tabStops} {
    # Expand tabs in line according to tab stops
    # For simplicity, we'll use a fixed tab width (8 characters) if no tab stops are set
    # or convert tab stops to character positions
    
    if {[llength $tabStops] == 0} {
        # No tab stops, use default tab width of 8
        return [string map {"\t" "        "} $line]
    }
    
    # Convert tab stops to character positions
    # For now, we'll use a simple conversion: 1i = 10 characters (approximate)
    set charPositions {}
    foreach stop $tabStops {
        # Use improved regex that supports floats and alignment suffixes
        if {[regexp {^([0-9]*\.?[0-9]+)([icm]?)([RCL]?)$} $stop -> numStr unit align]} {
            if {![string is double -strict $numStr]} {
                # Invalid number, skip this tab stop
                continue
            }
            set num [expr {double($numStr)}]
            set chars $num
            if {$unit eq "i"} {
                # Inches: approximate as 10 characters per inch
                set chars [expr {int($num * 10)}]
            } elseif {$unit eq "c"} {
                # Centimeters: approximate as 4 characters per cm
                set chars [expr {int($num * 4)}]
            } elseif {$unit eq "m"} {
                # Millimeters: approximate as 0.4 characters per mm
                set chars [expr {int($num * 0.4)}]
            } else {
                # No unit, use as-is (but ensure it's an integer)
                set chars [expr {int($num)}]
            }
            # Safety check: minimum 1 character
            if {$chars < 1} { set chars 1 }
            lappend charPositions $chars
        } elseif {[string is integer -strict $stop]} {
            # Simple integer tab stop
            set chars [expr {int($stop)}]
            if {$chars < 1} { set chars 1 }
            lappend charPositions $chars
        } else {
            # Invalid tab stop format, skip
            continue
        }
    }
    
    # Expand tabs
    set result ""
    set pos 0
    set tabIndex 0
    
    foreach char [split $line ""] {
        if {$char eq "\t"} {
            # Find next tab stop
            set nextStop 8
            if {$tabIndex < [llength $charPositions]} {
                set nextStop [lindex $charPositions $tabIndex]
                # Ensure nextStop is numeric
                if {![string is integer -strict $nextStop]} {
                    set nextStop 8
                } else {
                    set nextStop [expr {int($nextStop)}]
                }
                incr tabIndex
            } else {
                # Use last tab stop + default increment
                if {[llength $charPositions] > 0} {
                    set lastStop [lindex $charPositions end]
                    if {[string is integer -strict $lastStop]} {
                        set nextStop [expr {int($lastStop) + 8}]
                    }
                }
            }
            
            # Ensure pos is numeric
            if {![string is integer -strict $pos]} {
                set pos 0
            } else {
                set pos [expr {int($pos)}]
            }
            
            # Add spaces to reach next tab stop
            set spaces [expr {$nextStop - $pos}]
            if {$spaces > 0} {
                append result [string repeat " " $spaces]
                set pos $nextStop
            } else {
                append result " "
                incr pos
            }
        } else {
            append result $char
            incr pos
        }
    }
    
    return $result
}

# ============================================================
# Text handling (raw, no inline parsing)
# ============================================================

proc nroffparser::handleText {state line} {
    # Empty line flushes paragraph
    if {[string trim $line] eq ""} {
        return [nroffparser::flushParagraph $state]
    }
    
    # Check if we're waiting for .TP term
    if {[dict exists $state waitingForTerm] && [dict get $state waitingForTerm]} {
        dict set state waitingForTerm 0
        # This line is the term
        set currentList [dict get $state currentList]
        lappend currentList [dict create term $line desc ""]
        dict set state currentList $currentList
        # Mark that we just processed a .TP term (next line might be a "." separator)
        dict set state justProcessedTPTerm 1
        return $state
    }
    
    # Check if we're in a list
    set currentList [dict get $state currentList]
    if {[llength $currentList] > 0} {
        # Check if we just processed a .TP term and this line is just "."
        # If so, ignore it (it's a separator, not content)
        if {[dict exists $state justProcessedTPTerm] && [dict get $state justProcessedTPTerm]} {
            if {[string trim $line] eq "."} {
                dict set state justProcessedTPTerm 0
                return $state
            }
            dict set state justProcessedTPTerm 0
        }
        # Add to last item's description
        set lastIdx [expr {[llength $currentList] - 1}]
        set lastItem [lindex $currentList $lastIdx]
        set desc [dict get $lastItem desc]
        
        if {$desc eq ""} {
            dict set lastItem desc $line
        } else {
            dict set lastItem desc "$desc $line"
        }
        
        lset currentList $lastIdx $lastItem
        dict set state currentList $currentList
        return $state
    }
    
    # Expand tabs if tab stops are set
    if {[dict exists $state tabStops]} {
        set tabStops [dict get $state tabStops]
        if {[llength $tabStops] > 0} {
            set line [nroffparser::expandTabs $line $tabStops]
        }
    }
    
    # Expand tabs if tab stops are set
    if {[dict exists $state tabStops]} {
        set tabStops [dict get $state tabStops]
        if {[llength $tabStops] > 0} {
            set line [nroffparser::expandTabs $line $tabStops]
        }
    }
    
    # Trim leading whitespace from line (but preserve if it's intentional)
    # Only trim if line starts with a single space (common formatting issue)
    if {[string match " *" $line] && ![string match "  *" $line]} {
        # Single leading space - might be formatting, but usually it's a mistake
        # Only trim if it's not part of intentional indentation
        set trimmed [string trimleft $line]
        if {$trimmed ne ""} {
            set line $trimmed
        }
    }
    
    # Add to current paragraph (or urText if inside .UR/.UE block)
    if {[dict exists $state inUR] && [dict get $state inUR]} {
        set cur [dict get $state urText]
        dict set state urText [expr {$cur eq "" ? $line : "$cur $line"}]
    } else {
        set cur [dict get $state currentParagraph]
        if {$cur eq ""} {
            dict set state currentParagraph $line
        } else {
            dict set state currentParagraph "$cur $line"
        }
    }
    
    return $state
}

proc nroffparser::handlePreLine {state line} {
    # Expand tabs if tab stops are set
    if {[dict exists $state tabStops]} {
        set tabStops [dict get $state tabStops]
        if {[llength $tabStops] > 0} {
            set line [nroffparser::expandTabs $line $tabStops]
        }
    }
    
    set preText [dict get $state preText]
    if {$preText eq ""} {
        dict set state preText $line
    } else {
        dict set state preText "$preText\n$line"
    }
    return $state
}

# ============================================================
# State management: flush operations
# ============================================================

proc nroffparser::flushParagraph {state} {
    set text [dict get $state currentParagraph]
    # Only create paragraph if text is not empty
    set trimmedText [string trim $text]
    # Also check for empty quotes ""
    if {$trimmedText ne "" && $trimmedText ne "\"\""} {
        # Check if we're in a TP list - if so, add to description instead
        set currentList [dict get $state currentList]
        if {[llength $currentList] > 0} {
            # Check if we're in a TP list
            if {[dict exists $state listKind]} {
                set listKind [dict get $state listKind]
                if {$listKind eq "tp"} {
                    # Add to last item's description
                    set lastIdx [expr {[llength $currentList] - 1}]
                    set lastItem [lindex $currentList $lastIdx]
                    set desc [dict get $lastItem desc]
                    
                    # Trim leading whitespace from text before adding
                    set text [string trimleft $text]
                    
                    if {$desc eq ""} {
                        dict set lastItem desc $text
                    } else {
                        dict set lastItem desc "$desc $text"
                    }
                    
                    lset currentList $lastIdx $lastItem
                    dict set state currentList $currentList
                    dict set state currentParagraph ""
                    return $state
                }
            }
        }
        
        # Remove leading "" if present
        if {[string match "\"\"*" $text]} {
            set text [string range $text 2 end]
            set trimmedText [string trim $text]
            if {$trimmedText eq ""} {
                dict set state currentParagraph ""
                return $state
            }
        }
        
        # Trim leading whitespace from paragraph text
        set text [string trimleft $text]
        
        # AST-Spec: paragraph node with raw text
        # Include indent level in meta if > 0
        set meta {}
        if {[dict exists $state indentLevel]} {
            set indentLevel [dict get $state indentLevel]
            if {$indentLevel > 0} {
                dict set meta indentLevel $indentLevel
            }
        }
        set state [nroffparser::appendNode $state paragraph $text $meta]
        dict set state currentParagraph ""
    }
    return $state
}

proc nroffparser::flushPre {state} {
    set text [dict get $state preText]
    if {$text ne ""} {
        # AST-Spec: pre node
        set state [nroffparser::appendNode $state pre $text {}]
        dict set state preText ""
    }
    return $state
}

proc nroffparser::flushList {state} {
    set currentList [dict get $state currentList]
    if {[llength $currentList] > 0} {
        # Get list kind from state or default
        if {[dict exists $state listKind] && [dict get $state listKind] ne ""} {
            set kind [dict get $state listKind]
        } else {
            set kind tp
        }
        
        # AST-Spec: list node (include indentLevel in meta)
        set listMeta [dict create kind $kind]
        if {[dict exists $state indentLevel] && [dict get $state indentLevel] > 0} {
            dict set listMeta indentLevel [dict get $state indentLevel]
        }
        set state [nroffparser::appendNode $state list $currentList $listMeta]
        dict set state currentList {}
        dict set state listKind ""
        dict set state waitingForTerm 0
    }
    return $state
}

# ============================================================
# List management
# ============================================================

proc nroffparser::startList {state kind} {
    # Flush any existing list
    set state [nroffparser::flushList $state]
    
    # Start new list
    dict set state currentList {}
    dict set state listKind $kind
    
    return $state
}

# ============================================================
# Node creation (AST-Spec compliant)
# ============================================================

proc nroffparser::appendNode {state type content meta} {
    set ast [dict get $state ast]
    lappend ast [dict create \
        type $type \
        content $content \
        meta $meta]
    dict set state ast $ast
    
    return $state
}

# ============================================================
# Finalize state
# ============================================================

proc nroffparser::finalizeState {state} {
    # Flush remaining content (inkl. offener Stack-Frames)
    set state [nroffparser::flushParagraph $state]
    set state [nroffparser::flushPre $state]
    set state [nroffparser::flushList $state]
    # Offene listStack-Frames schliessen (unclosed .RS)
    while {[llength [dict get $state listStack]] > 0} {
        set listStack [dict get $state listStack]
        set frame     [lindex $listStack end]
        dict set state listStack   [lrange $listStack 0 end-1]
        dict set state indentLevel [dict get $frame indentLevel]
        dict set state currentList [dict get $frame currentList]
        dict set state listKind    [dict get $frame listKind]
        set state [nroffparser::flushList $state]
    }
    
    # Return AST
    return [dict get $state ast]
}

# ============================================================
# Phase 2: Inline parsing
# ============================================================

# parseInlinesPhase --
#   Phase 2: Convert raw text in nodes to inline structures
#   Processes: paragraph.content, list items (term, desc)
proc nroffparser::parseInlinesPhase {nodes} {
    set result {}
    set inSeeAlso 0

    foreach node $nodes {
        set type [dict get $node type]

        switch $type {
            section {
                # Track SEE ALSO section for link detection
                set text [dict get $node content]
                set inlines [nroffparser::parseInlines $text]
                dict set node content $inlines
                if {[string toupper [string trim $text]] eq "SEE ALSO"} {
                    set inSeeAlso 1
                } else {
                    set inSeeAlso 0
                }
                lappend result $node
            }
            subsection {
                # Subsection resets SEE ALSO context
                set inSeeAlso 0
                set text [dict get $node content]
                set inlines [nroffparser::parseInlines $text]
                dict set node content $inlines
                lappend result $node
            }
            paragraph {
                set text [dict get $node content]
                set inlines [nroffparser::parseInlines $text]
                if {$inSeeAlso} {
                    set inlines [nroffparser::detectLinks $inlines]
                }
                dict set node content $inlines
                lappend result $node
            }
            list {
                set items [dict get $node content]
                set meta [dict get $node meta]
                set newItems {}

                set isOPList 0
                if {[dict exists $meta kind] && [dict get $meta kind] eq "op"} {
                    set isOPList 1
                }

                foreach item $items {
                    set term [dict get $item term]
                    set desc [dict get $item desc]

                    if {$isOPList} {
                        set termInlines $term
                    } else {
                        set termInlines [nroffparser::parseInlines $term]
                        if {$inSeeAlso} {
                            set termInlines [nroffparser::detectLinks $termInlines]
                        }
                    }

                    set descInlines [nroffparser::parseInlines $desc]
                    if {$inSeeAlso} {
                        set descInlines [nroffparser::detectLinks $descInlines]
                    }

                    lappend newItems [dict create \
                        term $termInlines \
                        desc $descInlines]
                }
                dict set node content $newItems
                lappend result $node
            }
            pre {
                set text [dict get $node content]
                set inlines [nroffparser::parseInlines $text]
                dict set node content $inlines
                lappend result $node
            }
            heading {
                set text [dict get $node content]
                set inlines [nroffparser::parseInlines $text]
                dict set node content $inlines
                lappend result $node
            }
            default {
                lappend result $node
            }
        }
    }

    return $result
}

# detectLinks --
#   Scan inline list for name(section) patterns and replace with link nodes
#   Pattern: word immediately followed by (n) where n is a section number/letter
proc nroffparser::detectLinks {inlines} {
    set result {}
    foreach inline $inlines {
        set itype [dict get $inline type]
        if {$itype ne "text"} {
            lappend result $inline
            continue
        }
        set text [dict get $inline text]
        # Pattern: word(section) e.g. expr(n), canvas(3), Tcl_Eval(3TCL)
        # Allow alphanumeric + underscore + hyphen in name; section: digits+letters
        set pattern {([A-Za-z_:][A-Za-z0-9_:.-]*)(\([A-Za-z0-9][A-Za-z0-9]*\))}
        set pos 0
        set len [string length $text]
        while {$pos < $len} {
            if {[regexp -start $pos -indices $pattern $text idxs nameIdx secIdx]} {
                set start [lindex $idxs 0]
                set end   [lindex $idxs 1]
                # Text before the match
                if {$start > $pos} {
                    lappend result [dict create type text \
                        text [string range $text $pos $start-1]]
                }
                # The link itself
                set name    [string range $text [lindex $nameIdx 0] [lindex $nameIdx 1]]
                set secraw  [string range $text [lindex $secIdx 0]  [lindex $secIdx 1]]
                set section [string range $secraw 1 end-1] ;# strip parens
                set linkText "${name}${secraw}"
                lappend result [dict create type link text $linkText \
                    name $name section $section]
                set pos [expr {$end + 1}]
            } else {
                # No more matches - append rest
                lappend result [dict create type text \
                    text [string range $text $pos end]]
                break
            }
        }
    }
    return $result
}

# parseInlines --
#   Parse inline formatting: \fB, \fI, \fR, \fP
#   Also handles escape sequences: \-, \., \e, etc.
#   Removes inline comments: .\" ... (but not at start of line - handled earlier)
#   Returns list of inline AST nodes: {type text|strong|emphasis text "..."}
proc nroffparser::parseInlines {text} {
    # Remove inline comments (.\" ...) but preserve escape sequences
    # Pattern: .\" followed by anything until end of line
    # But we need to be careful - this should only match if .\" is not part of an escape sequence
    # Also remove leading "" if present
    set text [regsub -all {\.\\"[^\n]*} $text ""]
    if {[string match "\"\"*" $text]} {
        set text [string range $text 2 end]
    }
    
    # Handle .UL markers: \UL[open]text[close]\UL[close]
    # Replace with a temporary marker that we can process
    # Format: \UL[open]text[close]\UL[close] -> __UL_START__text__UL_END__
    # where [open]=123 and [close]=125 (ASCII codes for { and })
    set text [regsub -all {\\UL\173(.*?)\175\\UL\175} $text {__UL_START__\1__UL_END__}]

    # Handle .UR/.UE URL-Link-Marker: \[ur:href:linktext\]
    set _urNodes {}
    set _urIdx 0
    while {[regexp -indices {\[ur\|([^|]+)\|([^\]]*?)\]} $text idxs hrefIdx ltxtIdx]} {
        set before [string range $text 0 [expr {[lindex $idxs 0]-1}]]
        set href   [string range $text [lindex $hrefIdx 0] [lindex $hrefIdx 1]]
        set ltxt   [string range $text [lindex $ltxtIdx 0] [lindex $ltxtIdx 1]]
        set marker "__UR${_urIdx}__"
        lappend _urNodes [list $marker $href $ltxt]
        set text "$before$marker[string range $text [expr {[lindex $idxs 1]+1}] end]"
        incr _urIdx
    }

    set inlines {}
    set pos 0
    set len [string length $text]
    set currentStyle normal
    
    while {$pos < $len} {
        # Look for backslash escape sequences
        set nextPos [string first "\\" $text $pos]
        
        # Check for UR link markers (__URN__)
        set _urFound -1
        set _urFoundNode {}
        foreach _urN $_urNodes {
            set _m [lindex $_urN 0]
            set _p [string first $_m $text $pos]
            if {$_p != -1 && ($_urFound == -1 || $_p < $_urFound)} {
                set _urFound $_p
                set _urFoundNode $_urN
            }
        }
        if {$_urFound != -1 && ($nextPos == -1 || $_urFound < $nextPos)} {
            set _m    [lindex $_urFoundNode 0]
            set _href [lindex $_urFoundNode 1]
            set _lt   [lindex $_urFoundNode 2]
            # Text before marker
            if {$_urFound > $pos} {
                set before [string range $text $pos [expr {$_urFound-1}]]
                if {$before ne ""} {
                    lappend inlines [dict create type text text $before]
                }
            }
            # Link-Node mit href
            lappend inlines [dict create type link text $_lt                 name $_lt section "" href $_href]
            set pos [expr {$_urFound + [string length $_m]}]
            continue
        }

        # Check for UL markers first (before escape sequences)
        set ulStartPos [string first "__UL_START__" $text $pos]
        if {$ulStartPos != -1 && ($nextPos == -1 || $ulStartPos < $nextPos)} {
            # Found UL marker
            # Output text before marker
            if {$ulStartPos > $pos} {
                set before [string range $text $pos [expr {$ulStartPos - 1}]]
                if {$before ne ""} {
                    switch $currentStyle {
                        bold {
                            lappend inlines [dict create type strong text $before]
                        }
                        italic {
                            lappend inlines [dict create type emphasis text $before]
                        }
                        default {
                            lappend inlines [dict create type text text $before]
                        }
                    }
                }
            }
            
            # Find end marker
            set ulEndPos [string first "__UL_END__" $text $ulStartPos]
            if {$ulEndPos != -1} {
                # Extract underlined text
                # Marker length is 12 chars, so start after marker
                set ulTextStart [expr {$ulStartPos + 12}]
                set ulText [string range $text $ulTextStart [expr {$ulEndPos - 1}]]
                
                # Create underline node
                lappend inlines [dict create type underline text $ulText]
                
                # Move position past end marker
                # End marker length is 10 chars
                set pos [expr {$ulEndPos + 10}]
                
                # Check if there's more text after UL marker
                if {$pos < $len} {
                    set afterPos [string first "__UL_START__" $text $pos]
                    set afterEscPos [string first "\\" $text $pos]
                    if {$afterPos == -1 && $afterEscPos == -1} {
                        # No more markers, output rest
                        set remaining [string range $text $pos end]
                        if {$remaining ne ""} {
                            lappend inlines [dict create type text text $remaining]
                        }
                        break
                    }
                }
                continue
            } else {
                # No end marker found, treat as literal text
                set pos $ulStartPos
            }
        }
        
        if {$nextPos == -1} {
            # No more escape sequences, output rest
            set remaining [string range $text $pos end]
            if {$remaining ne ""} {
                switch $currentStyle {
                    bold {
                        lappend inlines [dict create type strong text $remaining]
                    }
                    italic {
                        lappend inlines [dict create type emphasis text $remaining]
                    }
                    default {
                        lappend inlines [dict create type text text $remaining]
                    }
                }
            }
            break
        }
        
        # Output text before escape sequence
        if {$nextPos > $pos} {
            set before [string range $text $pos [expr {$nextPos - 1}]]
            if {$before ne ""} {
                switch $currentStyle {
                    bold {
                        lappend inlines [dict create type strong text $before]
                    }
                    italic {
                        lappend inlines [dict create type emphasis text $before]
                    }
                    default {
                        lappend inlines [dict create type text text $before]
                    }
                }
            }
        }
        
        # Parse escape sequence
        set escapeEnd [expr {$nextPos + 1}]
        if {$escapeEnd < $len} {
            set escapeChar [string index $text $escapeEnd]
            
            switch $escapeChar {
                f {
                    # Font change: \fB, \fI, \fR, \fP
                    set fontEnd [expr {$escapeEnd + 1}]
                    if {$fontEnd < $len} {
                        set styleChar [string index $text $fontEnd]
                        switch $styleChar {
                            B {set currentStyle bold}
                            I {set currentStyle italic}
                            R - P {set currentStyle normal}
                            default {
                                # Unknown font, treat as literal \f
                                lappend inlines [dict create type text text "\\f"]
                                set pos $escapeEnd
                                continue
                            }
                        }
                        set pos [expr {$fontEnd + 1}]
                    } else {
                        # \f at end, treat as literal
                        lappend inlines [dict create type text text "\\f"]
                        set pos $escapeEnd
                    }
                }
                - {
                    # Hyphen/minus: \-
                    lappend inlines [dict create type text text "-"]
                    set pos [expr {$escapeEnd + 1}]
                }
                . {
                    # Period: \.
                    lappend inlines [dict create type text text "."]
                    set pos [expr {$escapeEnd + 1}]
                }
                e {
                    # Escape character: \e (usually ignored or treated as space)
                    # In man pages, \e is often used for line continuation
                    set pos [expr {$escapeEnd + 1}]
                }
                & {
                    # Non-breaking space: \& (zero-width space, usually ignored)
                    # In nroff, \& is used to prevent line breaks or as invisible character
                    # We'll ignore it (don't add anything to output)
                    set pos [expr {$escapeEnd + 1}]
                }
                N {
                    # Special character: \N'number' - ASCII character by octal number
                    # Example: \N'34' = " (double quote, ASCII 34 octal = 28 decimal)
                    # Note: In nroff, \N'34' means octal 34 = decimal 28 = FS (file separator)
                    # But in practice, \N'34' often means ASCII 34 decimal = "
                    # We'll interpret it as decimal for compatibility
                    # Look for pattern: \N'number'
                    set nEnd [expr {$escapeEnd + 1}]
                    if {$nEnd < $len && [string index $text $nEnd] eq "'"} {
                        # Find closing quote and number
                        set quoteEnd [string first "'" $text [expr {$nEnd + 1}]]
                        if {$quoteEnd != -1} {
                            set numberStr [string range $text [expr {$nEnd + 1}] [expr {$quoteEnd - 1}]]
                            # Convert octal to decimal, then to character
                            # In nroff, \N'34' means octal 34 = decimal 28
                            # But in practice, many man pages use \N'34' to mean ASCII 34 decimal = "
                            # We'll interpret as decimal for compatibility with common usage
                            if {[string is integer -strict $numberStr]} {
                                # Interpret as decimal (common usage in man pages)
                                set charCode $numberStr
                                set char [format %c $charCode]
                                lappend inlines [dict create type text text $char]
                                set pos [expr {$quoteEnd + 1}]
                            } else {
                                # Invalid number, treat as literal \N
                                lappend inlines [dict create type text text "\\N"]
                                set pos $escapeEnd
                            }
                        } else {
                            # No closing quote, treat as literal \N
                            lappend inlines [dict create type text text "\\N"]
                            set pos $escapeEnd
                        }
                    } else {
                        # Not \N'... pattern, treat as literal \N
                        lappend inlines [dict create type text text "\\N"]
                        set pos $escapeEnd
                    }
                }
                \\ {
                    # Literal backslash: \\
                    lappend inlines [dict create type text text "\\"]
                    set pos [expr {$escapeEnd + 1}]
                }
                ( {
                    # Special character escape: \(xx  (two-char code)
                    set codeEnd [expr {$escapeEnd + 2}]
                    if {$codeEnd <= $len} {
                        set code [string range $text [expr {$escapeEnd+1}] $codeEnd]
                        set mapped [nroffparser::_mapSpecialChar $code]
                        set out [expr {$currentStyle eq "bold" ? "strong"
                                     : $currentStyle eq "italic" ? "emphasis"
                                     : "text"}]
                        lappend inlines [dict create type $out text $mapped]
                        set pos [expr {$codeEnd + 1}]
                    } else {
                        lappend inlines [dict create type text text "\\("]
                        set pos [expr {$escapeEnd + 1}]
                    }
                }
                default {
                    # Unknown escape sequence, treat backslash as literal
                    lappend inlines [dict create type text text "\\"]
                    set pos $escapeEnd
                }
            }
        } else {
            # Backslash at end of string, treat as literal
            lappend inlines [dict create type text text "\\"]
            break
        }
    }
    
    # If no inlines were created, create at least one text node
    if {[llength $inlines] == 0 && $text ne ""} {
        lappend inlines [dict create type text text $text]
    }
    
    return $inlines
}

# ============================================================
# Special character map for \(xx escapes
# ============================================================

# _mapSpecialChar --
#   Map a two-character nroff special character code to Unicode.
#   Returns the Unicode character, or [code] for unknown codes.
proc nroffparser::_mapSpecialChar {code} {
    # Lazy-initialized dict (cached in namespace variable)
    variable _specialCharMap
    if {![info exists _specialCharMap]} {
        set _specialCharMap [dict create \
            bu  \u2022  \
            em  \u2014  \
            en  \u2013  \
            hy  \u2010  \
            lq  \u201C  \
            rq  \u201D  \
            oq  \u2018  \
            cq  \u2019  \
            dq  \"      \
            Bq  \u201E  \
            bq  \u201A  \
            Fo  \u00AB  \
            Fc  \u00BB  \
            la  <       \
            ra  >       \
            ul  _       \
            ru  _       \
            br  |       \
            ba  |       \
            bv  |       \
            ua  \u2191  \
            da  \u2193  \
            "<-"  \u2190  \
            "->"  \u2192  \
            mu  \u00D7  \
            di  \u00F7  \
            pl  +       \
            mi  -       \
            eq  =       \
            "!="  \u2260  \
            "<="  \u2264  \
            ">="  \u2265  \
            if  \u221E  \
            sr  \u221A  \
            no  \u00AC  \
            sc  \u00A7  \
            co  \u00A9  \
            rg  \u00AE  \
            tm  \u2122  \
            dg  \u2020  \
            dd  \u2021  \
            ct  \u00A2  \
            de  \u00B0  \
            14  \u00BC  \
            12  \u00BD  \
            34  \u00BE  \
            alpha \u03B1 \
            beta  \u03B2 \
            gamma \u03B3 \
            delta \u03B4 \
            pi    \u03C0 \
            mu    \u03BC \
            aa    \u00B4 \
            ga    \`     \
        ]
    }
    if {[dict exists $_specialCharMap $code]} {
        return [dict get $_specialCharMap $code]
    }
    # Unknown code – render as [code] rather than crashing
    return "\[$code\]"
}

# ===========================================================================
# EMBEDDED: ast2md-0.1.tm
# ===========================================================================

# ast2md-0.1.tm -- nroff AST to Markdown renderer
#
# Converts the AST produced by nroffparser into Markdown.
# The output is compatible with mdparser / mdstack.
#
# Usage:
#   package require ast2md
#   set md [ast2md::render $ast]
#   set md [ast2md::render $ast -lang tcl -tip700 false]

namespace eval ast2md {
    namespace export render
}

# ast2md::render --
#   Main entry point. Converts a nroff AST to Markdown string.
#
# Arguments:
#   ast   - List of AST nodes from nroffparser::parse
#   args  - Options: -lang LANG (code block language, default "tcl")
#                    -tip700 BOOL (emit TIP-700 spans, default false)
#
# Returns:
#   Markdown string
#
proc ast2md::render {ast args} {
    # Parse options
    set opts(-lang)     "tcl"
    set opts(-tip700)   false
    set opts(-linkmode) "none"
    foreach {k v} $args {
        if {![info exists opts($k)]} {
            error "unknown option $k, must be -lang, -tip700 or -linkmode"
        }
        set opts($k) $v
    }

    set lines {}
    foreach node $ast {
        set type [dict get $node type]
        switch -- $type {
            heading    { lappend lines [_renderHeading $node] }
            section    { lappend lines [_renderSection $node] }
            subsection { lappend lines [_renderSection $node] }
            paragraph  { lappend lines [_renderParagraph $node $opts(-linkmode)] }
            pre        { lappend lines [_renderPre $node $opts(-lang)] }
            list       { lappend lines [_renderList $node $opts(-linkmode)] }
            blank      { lappend lines "" }
            default    { lappend lines [_renderParagraph $node $opts(-linkmode)] }
        }
    }

    set result [join $lines \n]
    # Clean up triple+ blank lines to double
    regsub -all {\n\n\n+} $result "\n\n" result
    return $result
}

# --- Heading (.TH) ---

proc ast2md::_renderHeading {node} {
    set meta [dict get $node meta]
    set name [dict get $meta name]
    set section ""
    if {[dict exists $meta section]} {
        set section [dict get $meta section]
    }
    if {$section ne ""} {
        return "# $name\n"
    }
    return "# $name\n"
}

# --- Section (.SH / .SS) ---

proc ast2md::_renderSection {node} {
    set meta ""
    if {[dict exists $node meta]} {
        set meta [dict get $node meta]
    }
    set level 1
    if {$meta ne "" && [dict exists $meta level]} {
        set level [dict get $meta level]
    }
    set text [_renderInlines [dict get $node content]]

    if {$level == 1} {
        return "\n## $text\n"
    } else {
        return "\n### $text\n"
    }
}

# --- Paragraph ---

proc ast2md::_renderParagraph {node {linkmode none}} {
    set content [dict get $node content]
    set text [_renderInlines $content $linkmode]
    set indent ""
    if {[dict exists $node meta]} {
        set meta [dict get $node meta]
        if {$meta ne "" && [dict exists $meta indentLevel]} {
            set lvl [dict get $meta indentLevel]
            if {$lvl > 0} {
                set indent [string repeat "  " $lvl]
            }
        }
    }
    return "${indent}${text}\n"
}

# --- Pre (.CS/.CE, .nf/.fi) ---

proc ast2md::_renderPre {node lang} {
    set content [dict get $node content]
    set text ""
    if {[llength $content] > 0} {
        # content is an inline list
        set text [_renderInlinesPlain $content]
    }
    # Remove leading/trailing blank lines
    set text [string trim $text \n]
    return "\n```${lang}\n${text}\n```\n"
}

# --- List (TP, IP, OP, AP) ---

proc ast2md::_renderList {node {linkmode none}} {
    set meta [dict get $node meta]
    set kind [dict get $meta kind]
    set content [dict get $node content]
    set lines {}

    foreach item $content {
        set term ""
        if {[dict exists $item term]} {
            set term [dict get $item term]
        }
        set desc ""
        if {[dict exists $item desc]} {
            set desc [dict get $item desc]
        }
        set blocks {}
        if {[dict exists $item blocks]} {
            set blocks [dict get $item blocks]
        }

        switch -- $kind {
            tp - ap {
                # Definition list: term + description
                #
                # Split case: if desc is empty but term contains more than
                # one inline (e.g. {strong "auto"} {text " As the input..."}),
                # the parser stored term+desc on one line after .TP.
                # Split: first inline is the term, remainder is the desc.
                if {$desc eq "" && [llength $term] > 1} {
                    set firstInline [lindex $term 0]
                    if {[dict exists $firstInline type] &&
                        [dict get $firstInline type] in {strong emphasis text}} {
                        set desc  [lrange $term 1 end]
                        set term  [list $firstInline]
                        # Strip leading space from first desc inline
                        set di0 [lindex $desc 0]
                        if {[dict exists $di0 text]} {
                            set t [string trimleft [dict get $di0 text]]
                            dict set di0 text $t
                            lset desc 0 $di0
                        }
                    }
                }

                set termText [_renderInlinesPlain $term]
                if {$termText ne ""} {
                    lappend lines "**${termText}**"
                }
                if {$desc ne ""} {
                    set descText [_renderInlines $desc $linkmode]
                    lappend lines ": ${descText}"
                }
                # Render sub-blocks if any
                foreach block $blocks {
                    set btype [dict get $block type]
                    if {$btype eq "paragraph"} {
                        set btext [_renderInlines [dict get $block content] $linkmode]
                        lappend lines ": ${btext}"
                    } elseif {$btype eq "pre"} {
                        lappend lines ""
                        lappend lines [_renderPre $block "tcl"]
                    }
                }
                lappend lines ""
            }
            ip {
                # Bullet or numbered list
                set termText ""
                if {$term ne ""} {
                    set termText [_renderInlinesPlain $term]
                }
                set descText ""
                if {$desc ne ""} {
                    set descText [_renderInlines $desc $linkmode]
                }
                # Check if bullet
                set isBullet [expr {$termText eq "\u2022" || $termText eq "*" || $termText eq "\\(bu"}]
                if {$isBullet} {
                    lappend lines "- ${descText}"
                } elseif {$termText ne ""} {
                    # Numbered or custom term
                    lappend lines "**${termText}** ${descText}"
                } else {
                    lappend lines "- ${descText}"
                }
                # Sub-blocks
                foreach block $blocks {
                    set btype [dict get $block type]
                    if {$btype eq "paragraph"} {
                        set btext [_renderInlines [dict get $block content] $linkmode]
                        lappend lines "  ${btext}"
                    }
                }
            }
            op {
                # Option paragraph: term is "cmdName|dbName|dbClass"
                set termText ""
                if {$term ne ""} {
                    if {[string match "*|*" $term]} {
                        set parts [split $term |]
                        set cmd [lindex $parts 0]
                        set db [lindex $parts 1]
                        set cls [lindex $parts 2]
                        set termText "**${cmd}** (${db}/${cls})"
                    } else {
                        set termText [_renderInlines $term $linkmode]
                    }
                }
                set descText ""
                if {$desc ne ""} {
                    set descText [_renderInlines $desc $linkmode]
                }
                if {$termText ne ""} {
                    lappend lines "${termText}"
                }
                if {$descText ne ""} {
                    lappend lines ": ${descText}"
                }
                lappend lines ""
            }
            default {
                # Fallback: render as paragraphs
                if {$term ne ""} {
                    lappend lines [_renderInlines $term $linkmode]
                }
                if {$desc ne ""} {
                    lappend lines [_renderInlines $desc $linkmode]
                }
                lappend lines ""
            }
        }
    }

    return [join $lines \n]
}

# --- Check if inline list has formatting ---

proc ast2md::_hasFormatting {inlines} {
    if {$inlines eq ""} { return 0 }
    foreach inline $inlines {
        if {![dict exists $inline type]} continue
        set itype [dict get $inline type]
        if {$itype eq "strong" || $itype eq "emphasis"} {
            return 1
        }
    }
    return 0
}

# --- Inline rendering (with Markdown formatting) ---

proc ast2md::_renderInlines {inlines {linkmode none}} {
    if {$inlines eq ""} { return "" }
    set result ""
    foreach inline $inlines {
        if {![dict exists $inline type]} continue
        set itype [dict get $inline type]
        set itext ""
        if {[dict exists $inline text]} {
            set itext [dict get $inline text]
        } elseif {[dict exists $inline value]} {
            set itext [dict get $inline value]
        }
        switch -- $itype {
            text     { append result $itext }
            strong   { append result "**${itext}**" }
            emphasis { append result "*${itext}*" }
            link {
                set name [expr {[dict exists $inline name] ? [dict get $inline name] : $itext}]
                switch -- $linkmode {
                    server { append result "\[$itext](/$name)" }
                    file   { append result "\[$itext](${name}.md)" }
                    default { append result $itext }
                }
            }
            default  { append result $itext }
        }
    }
    # Clean up double spaces
    regsub -all {  +} $result { } result
    return [string trim $result]
}

# --- Inline rendering (plain text, no formatting) ---

proc ast2md::_renderInlinesPlain {inlines} {
    if {$inlines eq ""} { return "" }
    set result ""
    foreach inline $inlines {
        if {![dict exists $inline type]} continue
        set itext ""
        if {[dict exists $inline text]} {
            set itext [dict get $inline text]
        } elseif {[dict exists $inline value]} {
            set itext [dict get $inline value]
        }
        append result $itext
    }
    return [string trim $result]
}

# MAIN -- Argument-Verarbeitung und Konvertierung
# ===========================================================================

proc usage {} {
    puts "Usage: nroff2md.tcl \[input.n\] \[output.md\] \[options\]"
    puts ""
    puts "Options:"
    puts "  -lang LANG           Code block language (default: tcl)"
    puts "  --linkmode MODE      Link mode: none, server, file"
    puts "  --batch DIR OUT      Convert all .n/.3 files in DIR to OUT/"
    puts "  --no-index           Skip index.md generation in batch mode"
    puts "  --help               Show this help"
    puts ""
    puts "Link modes:"
    puts "  none     SEE ALSO as plain text (default)"
    puts "  server   SEE ALSO as /pagename  (for mdserver)"
    puts "  file     SEE ALSO as pagename.md (relative file links)"
}

proc convertFile {inputFile outputFile lang linkmode {indexLink ""}} {
    if {$inputFile eq "-"} {
        set nroff [read stdin]
        set sourceFile ""
    } else {
        if {![file exists $inputFile]} {
            puts stderr "Error: File not found: $inputFile"
            return {0 {}}
        }
        set fh [open $inputFile r]
        fconfigure $fh -encoding utf-8
        set nroff [read $fh]
        close $fh
        set sourceFile $inputFile
    }

    if {[catch {
        set ast [nroffparser::parse $nroff $sourceFile]
        set md  [ast2md::render $ast -lang $lang -linkmode $linkmode]
    } err]} {
        puts stderr "Error converting $inputFile: $err"
        return {0 {}}
    }

    # Metadaten aus dem TH-Node (level=0 heading)
    set meta {}
    foreach node $ast {
        if {[dict get $node type] eq "heading"} {
            set m [dict get $node meta]
            if {[dict exists $m level] && [dict get $m level] == 0} {
                set meta $m
                break
            }
        }
    }

    if {$outputFile eq ""} {
        puts -nonewline $md
    } else {
        file mkdir [file dirname $outputFile]
        set fh [open $outputFile w]
        fconfigure $fh -encoding utf-8
        if {$indexLink ne ""} {
            puts $fh "\[$indexLink\](index.md)\n"
        }
        puts -nonewline $fh $md
        close $fh
        puts stderr "Written: $outputFile"
    }
    return [list 1 $meta]
}

proc generateIndex {entries outputDir linkmode} {
    # Gruppieren: tcl_n = Tcl Commands, tk_n = Tk Commands, c = C API
    array set groups {}
    foreach e $entries {
        set sec     [dict get $e section]
        set srcpath [expr {[dict exists $e srcpath] ? [dict get $e srcpath] : ""}]
        # Pfad-Erkennung: tk9 oder /tk/ im Pfad → Tk
        set isTk [expr {[string match "*tk9*" $srcpath] || [string match "*/tk/*" $srcpath]}]
        if {[string match "3*" $sec]} {
            set grp c
        } elseif {[string match "n*" $sec] || $sec eq "n"} {
            set grp [expr {$isTk ? "tk_n" : "tcl_n"}]
        } else {
            # Sondersections (print, sysnotify, systray): nach Pfad einordnen
            set grp [expr {$isTk ? "tk_n" : "tcl_n"}]
        }
        lappend groups($grp) $e
    }

    set lines {}
    lappend lines "# Tcl/Tk Manual Pages"
    lappend lines ""
    set total [llength $entries]
    lappend lines "Total: $total pages."
    lappend lines ""

    set sortCmd {apply {{a b} {
        string compare [string tolower [dict get $a name]] \
                       [string tolower [dict get $b name]]
    }}}

    # Hilfsproc: eine Kategorie alphabetisch mit Sprungmarken ausgeben
    proc _renderCategory {lines_var entries_sorted title} {
        upvar $lines_var lines

        lappend lines "## $title"
        lappend lines ""

        # Alle vorhandenen Anfangsbuchstaben sammeln
        set letters {}
        foreach e $entries_sorted {
            set first [string toupper [string index [dict get $e name] 0]]
            if {[lsearch $letters $first] < 0} {
                lappend letters $first
            }
        }

        # Präfix für eindeutige Anchor-IDs (tcl-a, tk-a, c-a)
        set pfx [string trimright [string tolower [string map {" " "-"} [string range $title 0 2]]] "-"]

        # Sprungmarken-Zeile: [A](#tcl-a) | [B](#tcl-b) ...
        set jumpParts {}
        foreach l $letters {
            lappend jumpParts "\[${l}\](#${pfx}-[string tolower $l])"
        }
        lappend lines [join $jumpParts " | "]
        lappend lines ""

        # Einträge nach Buchstaben gruppiert
        set currentLetter ""
        foreach e $entries_sorted {
            set name     [dict get $e name]
            set filename [dict get $e filename]
            set section  [dict get $e section]
            set first    [string toupper [string index $name 0]]
            if {$first ne $currentLetter} {
                if {$currentLetter ne ""} { lappend lines "" }
                lappend lines "### ${pfx}-[string tolower $first]"
                lappend lines ""
                set currentLetter $first
            }
            lappend lines "- \[${name}(${section})\]($filename)"
        }
        lappend lines ""
    }

    foreach {grp title} {tcl_n "Tcl Commands" tk_n "Tk Commands" c "C API"} {
        if {![info exists groups($grp)]} continue
        set sorted [lsort -command $sortCmd $groups($grp)]
        _renderCategory lines $sorted $title
    }

    set indexFile [file join $outputDir index.md]
    set fh [open $indexFile w]
    fconfigure $fh -encoding utf-8
    puts -nonewline $fh [join $lines "\n"]
    close $fh
    puts stderr "Index:   $indexFile ([llength $entries] entries)"
}

# findNroffFiles -- findet .n und .3 Dateien rekursiv
proc findNroffFiles {dir} {
    set files {}
    foreach pattern {*.n *.3} {
        lappend files {*}[glob -nocomplain -directory $dir $pattern]
    }
    foreach subdir [glob -nocomplain -directory $dir -type d *] {
        lappend files {*}[findNroffFiles $subdir]
    }
    return $files
}

proc batchConvert {inputDir outputDir lang linkmode noIndex} {
    set files [findNroffFiles $inputDir]
    if {[llength $files] == 0} {
        puts stderr "No .n or .3 files found in $inputDir (recursive)"
        return
    }
    file mkdir $outputDir

    set ok 0; set fail 0
    set indexEntries {}

    foreach f [lsort $files] {
        set name    [file rootname [file tail $f]]
        set outFile [file join $outputDir ${name}.md]
        set result  [convertFile $f $outFile $lang $linkmode [expr {$noIndex ? "" : "<< Index"}]]

        if {[lindex $result 0]} {
            incr ok
            if {!$noIndex} {
                set meta [lindex $result 1]
                set pageName    [expr {[dict exists $meta name]    ? [dict get $meta name]    : $name}]
                set pageSection [expr {[dict exists $meta section] ? [dict get $meta section] : "n"}]
                set linkFile    [expr {$linkmode eq "server" ? "/$name" : "${name}.md"}]
                lappend indexEntries [dict create \
                    name     $pageName \
                    section  $pageSection \
                    filename $linkFile \
                    srcpath  $f]
            }
        } else {
            incr fail
        }
    }

    puts stderr "Converted: $ok  Failed: $fail  Total: [expr {$ok + $fail}]"
    if {!$noIndex && [llength $indexEntries] > 0} {
        generateIndex $indexEntries $outputDir $linkmode
    }
}

# Argument-Verarbeitung
set inputFile  ""
set outputFile ""
set lang       "tcl"
set linkmode   "none"
set batch      0
set batchIn    ""
set batchOut   ""
set noIndex    0

set i 0
while {$i < [llength $argv]} {
    set arg [lindex $argv $i]
    switch -- $arg {
        --help      { usage; exit 0 }
        -lang       { incr i; set lang     [lindex $argv $i] }
        --linkmode  { incr i; set linkmode [lindex $argv $i] }
        --no-index  { set noIndex 1 }
        --batch {
            set batch 1
            incr i; set batchIn  [lindex $argv $i]
            incr i; set batchOut [lindex $argv $i]
        }
        default {
            if {$inputFile eq ""}      { set inputFile  $arg } \
            elseif {$outputFile eq ""} { set outputFile $arg }
        }
    }
    incr i
}

if {$batch} {
    batchConvert $batchIn $batchOut $lang $linkmode $noIndex
} elseif {$inputFile ne ""} {
    convertFile $inputFile $outputFile $lang $linkmode
} else {
    convertFile "-" "" $lang $linkmode
}