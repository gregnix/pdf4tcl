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
    set reporoot [file normalize [file join $here ../../../..]]
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
