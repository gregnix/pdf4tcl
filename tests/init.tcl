# Common initialization for each test
#
# $Id$
#
# The mytest page has this default look:
#
# --------------------------
# |       w=800 h=1000     |
# | -----------------------|
# | |(100,900)   (800,900)||
# | |                     ||
# | |                     ||
# | |                     ||
# | |(100,200)   (800,200)||
# | -----------------------|
# |                        |
# --------------------------

if {[lsearch [namespace children] ::tcltest] == -1} {
    package require tcltest
    namespace import -force ::tcltest::*
}

set tmp [file join [pwd] ..]
set ::auto_path [concat [list $tmp] $::auto_path]
if {[file exists $tmp/pdf4tcl.tcl_i]} {
    source $tmp/pdf4tcl.tcl_i
}
package require pdf4tcl 0.9.4.14

proc myexec {args} {
    set ch [open "|$args"]
    set ::myexec 0
    fileevent $ch readable [string map "%ch $ch" {
        gets %ch line
        if {[eof %ch]} {
            close %ch
            set ::myexec 1
        }
    }]
    vwait ::myexec
}

proc mytest {args} {
    set pattern [lindex $args end]
    set args [lrange $args 0 end-1]

    set cmds {}
    # Default paper has a simple size. Compress is off to see what happens.
    set opts {-compress 0 -orient 0 -paper {800 1000} -margin {100 0 100 200}}
    set isopt ""
    set debug 0
    set checkall 0
    set createfile 0
    set returnvalues 0
    set myTestReturnValues {}
    foreach arg $args {
        if {$isopt ne ""} {
            dict set opts $isopt $arg
            set isopt ""
        } elseif {[string match "-debug" $arg]} {
            set debug 1
        } elseif {[string match "-file" $arg]} {
            set createfile 1
        } elseif {[string match "-all" $arg]} {
            set checkall 1
        } elseif {[string match "-return" $arg]} {
            set returnvalues 1
        } elseif {[string match "-*" $arg]} {
            set isopt $arg
        } else {
            lappend cmds $arg
        }
    }
    set pdf [eval pdf4tcl::new %AUTO% $opts]
    $pdf setFont 12 Helvetica
    $pdf startPage
    if {$debug} {
        # Draw a grid to see better in debug mode
        foreach {w h} [$pdf getDrawableArea] break
        $pdf gsave
        $pdf setStrokeColor 0.5 0.5 0.5
        $pdf setLineStyle 0.1 0.1 2
        $pdf polygon 0 0 $w 0 $w $h 0 $h
        for {set t 100} {$t < $w} {incr t 100} {
            $pdf line $t 0 $t $h
        }
        for {set t 100} {$t < $h} {incr t 100} {
            $pdf line 0 $t $w $t
        }
        $pdf grestore
    }
    foreach cmd $cmds {
        lappend myTestReturnValues [eval \$pdf $cmd]
    }
    set res [$pdf get]
    $pdf destroy

    if {$debug || $createfile} {
        set ch [open testdebug.pdf w]
        fconfigure $ch -translation binary
        puts -nonewline $ch $res
        close $ch
    }
    if {$debug} {
        foreach app {acroread kpdf xpdf kghostview} {
            if {[auto_execok $app] ne ""} {
                myexec $app testdebug.pdf
                break
            }
        }
        file copy -force testdebug.pdf ..
        #file delete testdebug.pdf

        set pat [string map {" * " " *\n"} $pattern]
        regsub -line -all {(?: |^)([[:alpha:]]+) } $pat " \\1\n" pat
        regsub -line -all {^\s+} $pat "" pat
        set ch [open ../testdebug.txt w]
        fconfigure $ch -translation binary
        puts -nonewline $ch $pat
        close $ch
    }
    # Normally we just check the stream part
    if {!$checkall} {
        regexp {stream.*endstream} $res res
    }
    regsub -all {\s+} $res " " res

    set pattern *[string trim $pattern]*
    regsub -all {\s+} $pattern " " pattern
    # After whitespace collapse every separator is a single space.
    # A glob " * " needs space-wildcard-space which fails when two PDF
    # tokens are directly adjacent (only one space between them).
    # Replace " * " with "*" so that wildcards match zero-or-more tokens.
    regsub -all { \* } $pattern {*} pattern

    if {[string match $pattern $res]} {
        if {$returnvalues} {
            set result [list 1]
            # Flatten and beautify
            foreach rv $myTestReturnValues {
                if {[string is list $rv] && [llength $rv] > 1} {
                    foreach rv2 $rv {
                        if {[string is double $rv2]} {
                            set rv2 [pdf4tcl::Nf $rv2]
                        }
                        lappend result $rv2
                    }
                } else {
                    lappend result $rv
                }
            }
            return $result
        } else {
            return 1
        }
    } else {
        return $res
    }
}
