# _bootstrap.tcl -- shared helpers for doc/en tutorial and howto scripts
#
# Source from a script under tutorials/ or howtos/:
#   source [file join [file dirname [info script]] ../_bootstrap.tcl]
#   pdf4tcl::doc::init
#   set outfile [pdf4tcl::doc::outfile basename.pdf]

namespace eval ::pdf4tcl::doc {
    variable reporoot
    variable outdir
    variable freesans
    variable dejavu
}

proc ::pdf4tcl::doc::init {{scriptfile ""} {extraOut {}}} {
    variable reporoot
    variable outdir
    variable freesans
    variable dejavu

    if {$scriptfile eq ""} {
        # Caller forgot [info script]; try to recover from stack frame file
        set scriptfile [info script]
    }
    if {$scriptfile eq "" || [file tail $scriptfile] eq "_bootstrap.tcl"} {
        return -code error "pdf4tcl::doc::init requires the companion script path:\n  pdf4tcl::doc::init \[info script\]"
    }

    set here [file dirname [file normalize $scriptfile]]

    # Find the repository root by SEARCHING for it, not by counting "..".
    #
    # A fixed count is wrong the moment anything moves, and it was already
    # wrong in two ways at once: it assumed four levels, which fitted
    # 0.9.4.x/doc/en/howtos but not doc/en/run-all-examples.tcl one level
    # up. After the fork directory was flattened, the howtos resolved the
    # root one level too high and every script needing a font or the
    # package died with a path that pointed outside the tree
    # ("FreeSans.ttf missing at /home/.../tk/examples/FreeSans.ttf").
    #
    # The marker is pkgIndex.tcl beside src/ -- both exist only at the root.
    set reporoot ""
    set dir $here
    for {set i 0} {$i < 8} {incr i} {
        if {[file exists [file join $dir pkgIndex.tcl]]
                && [file isdirectory [file join $dir src]]} {
            set reporoot $dir
            break
        }
        set parent [file dirname $dir]
        if {$parent eq $dir} break
        set dir $parent
    }
    if {$reporoot eq ""} {
        return -code error "pdf4tcl::doc::init: no repository root above\
                $here -- looked for a directory holding pkgIndex.tcl and src/"
    }
    set ::auto_path [linsert $::auto_path 0 $reporoot]
    set pkg [file join $reporoot pkg]
    if {[file isdirectory $pkg]} {
        set ::auto_path [linsert $::auto_path 0 $pkg]
    }

    package require pdf4tcl 0.9

    set outdir [file join [file dirname $here] out]
    if {$extraOut ne ""} {
        set outdir $extraOut
    }
    if {[llength $::argv] > 0} {
        set a [lindex $::argv 0]
        if {[file isdirectory $a] || ![file exists $a]} {
            set outdir $a
        }
    }
    file mkdir $outdir

    set freesans [file join $reporoot examples FreeSans.ttf]
    set dejavu ""
    foreach c {
        /usr/share/fonts/truetype/dejavu/DejaVuSans.ttf
        /usr/share/fonts/TTF/DejaVuSans.ttf
    } {
        if {[file exists $c]} { set dejavu $c; break }
    }
    if {$dejavu eq "" && [file exists $freesans]} {
        set dejavu $freesans
    }

    return $reporoot
}

proc ::pdf4tcl::doc::outfile {name} {
    variable outdir
    return [file join $outdir $name]
}

proc ::pdf4tcl::doc::needFont {which} {
    variable freesans
    variable dejavu
    switch -- $which {
        freesans {
            if {![file exists $freesans]} {
                return -code error "FreeSans.ttf missing at $freesans"
            }
            return $freesans
        }
        dejavu - unicode {
            if {$dejavu eq "" || ![file exists $dejavu]} {
                return -code error "DejaVuSans.ttf (or FreeSans) not found"
            }
            return $dejavu
        }
        default { return -code error "unknown font key $which" }
    }
}

proc ::pdf4tcl::doc::done {path} {
    puts "wrote $path  (pdf4tcl [package present pdf4tcl])"
}
