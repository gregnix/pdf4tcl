#!/usr/bin/env tclsh

#lappend auto_path [pwd]/../..
set auto_path [linsert $auto_path 0 [file normalize [file join [file dirname [info script]] ..]]]
package require pdf4tcl

# Provide .afm and .pfb to dump type1 font:
proc dumpfontverbose {fname} {
    set name [string range $fname 0 end-4]
    set ext [string range $fname end-2 end]
    if {$ext eq "ttf"} {
        pdf4tcl::loadBaseTrueTypeFont BaseFont$fname $fname
    } elseif {$ext eq "afm"} {
        pdf4tcl::loadBaseType1Font BaseFont$fname $fname "${name}.pfb"
    } elseif {$ext eq "pfb"} {
        pdf4tcl::loadBaseType1Font BaseFont$fname "${name}.afm" $fname
    } else {
        error $ext
    }

    foreach {psname ucode} [array get ::pdf4tcl::GlName2Uni] {
        set U2PSname($ucode) $psname
    }

    # This requires poking into pdf4tcl internals:
    # Result is list of lists (for each subset).
    for {set f 0} {$f <= 32} {incr f} {
        lappend baseset $f
    }
    set Xchars 32
    set f 33
    set subsetN 1
    set currtxt ""
    set subtext ""
    set subset $baseset
    lappend res MyFont1
    foreach {ucode w} $::pdf4tcl::BFA(BaseFont$fname,charWidths) {
        lappend ucodes $ucode
    }
    set ucodes [lsort -integer $ucodes]

    foreach ucode $ucodes {
        if {$f == 256} {
            lappend res $subtext
            #Reinit:
            pdf4tcl::createFontSpecEnc BaseFont$fname MyFont$subsetN $subset
            incr subsetN
            lappend res MyFont$subsetN
            set f 33
            set currtxt ""
            set subtext ""
       set subset $baseset
        }
        lappend subset $ucode
        set psname ".notdef"
        catch {set psname $U2PSname($ucode)}
        lappend subtext [list $ucode $psname [format %c $ucode]]
        incr f
    }
    # Finish all:
    lappend res $subtext
    pdf4tcl::createFontSpecEnc BaseFont$fname MyFont$subsetN $subset

    pdf4tcl::new mypdf -paper a4 -compress 1
    mypdf startPage
    foreach {w h} [mypdf getDrawableArea] break
    set h [expr {$h-30.0}]
    set w [expr {$w-50.0}]

    set y 30
    set x 50
    foreach {fontname txtlist} $res {
        foreach symlst $txtlist {
            foreach {ucode psname char} $symlst break
            mypdf setFont 10 Courier
            mypdf text "$ucode $psname " -x $x -y $y
            mypdf setFont 12 $fontname
            mypdf text $char -bg #CCCCCC
            incr x 180
            if {$x>=$w} {
                set x 50
                incr y 22
                if {$y>=$h} {
                    mypdf endPage
                    mypdf startPage
                    mypdf setFont 10 $fontname
                    set y 30
                }
            }
        }
    }
    
    mypdf write -file ${name}_dump.pdf
    mypdf destroy
}

foreach fname $argv {
    dumpfontverbose $fname
}

