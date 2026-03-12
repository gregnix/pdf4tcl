#######################################################################
# Mixin Object used for Snit-like option handling
#######################################################################
catch {oo::class create ::pdf4tcl::options}
oo::define ::pdf4tcl::options {
    variable options

    # Define an option
    # Should be called from constructor
    method Option {option args} {
        my variable optiondefs
        my variable optiondeflist

        dict set optiondefs $option -readonly 0
        dict set optiondefs $option -default ""
        dict set optiondefs $option -validatemethod ""
        dict set optiondefs $option -configuremethod ""
        dict set optiondefs $option _Initialised 0

        foreach {opt val} $args {
            dict set optiondefs $option $opt $val
        }
        set options($option) [dict get $optiondefs $option -default]
        # Keep a nice list available
        set optiondeflist [lsort -dictionary [dict keys $optiondefs]]
    }

    # Handle a configuration command.
    # Should always be called from constructor
    method Configurelist {lst} {
        my variable optiondefs
        my variable optiondeflist
        if {[llength $lst] % 2 != 0} {
            throw {PDF4TCL} "wrong number of args"
        }
        foreach {option value} $lst {
            # TODO: recode to use prefix matching
            #tcl::prefix match $optiondeflist $option
            if {![dict exists $optiondefs $option]} {
                throw {PDF4TCL} "unknown option \"$option\""
            }
            if {[dict get $optiondefs $option -readonly] && \
                        [dict get $optiondefs $option _Initialised]} {
                throw {PDF4TCL} \
                        "option $option can only be set at instance creation"
            }
            if {[dict get $optiondefs $option -validatemethod] ne ""} {
                ##nagelfar ignore Non static subcommand
                my [dict get $optiondefs $option -validatemethod] \
                        $option $value
            }
            if {[dict get $optiondefs $option -configuremethod] ne ""} {
                ##nagelfar ignore Non static subcommand
                my [dict get $optiondefs $option -configuremethod] \
                        $option $value
            } else {
                set options($option) $value
            }
            dict set optiondefs $option _Initialised 1
        }
        foreach option [dict keys $optiondefs] {
            if {![dict get $optiondefs $option _Initialised]} {
                # Uninitialised options should get their defaults through
                # configuremethod if there is any.
                if {[dict get $optiondefs $option -configuremethod] ne ""} {
                    ##nagelfar ignore Non static subcommand
                    my [dict get $optiondefs $option -configuremethod] \
                            $option [dict get $optiondefs $option -default]
                }
                dict set optiondefs $option _Initialised 1
            }
        }
    }

    method cget {option} {
        return $options($option)
    }

    method configure {args} {
        if {$args eq {}} {
            return [array get options]
        }
        if {[llength $args] == 1} {
            return $options([lindex $args 0])
        }
        my Configurelist $args
    }

    # Validator for -paper
    method CheckPaper {option value} {
        set papersize [pdf4tcl::getPaperSize $value]
        if {[llength $papersize] == 0} {
            throw {PDF4TCL} "papersize \"$value\" is unknown"
        }
    }

    # Validator for -unit
    method CheckUnit {option value} {
        if {![info exists ::pdf4tcl::units($value)]} {
            throw {PDF4TCL} "unit \"$value\" is unknown"
        }
    }

    # Validator for -margin
    method CheckMargin {option value} {
        switch [llength $value] {
            1 - 2 - 4 {
                foreach elem $value {
                    if {[catch {pdf4tcl::getPoints $elem}]} {
                        throw {PDF4TCL} "bad margin value \"$elem\""
                    }
                }
            }
            default {
                throw {PDF4TCL} "bad margin list \"$value\""
            }
        }
    }
    # Validator for boolean options
    method CheckBoolean {option value} {
        if {![string is boolean -strict $value]} {
            throw {PDF4TCL} "option $option must have a boolean value"
        }
    }

    # Validator for word restricted options
    method CheckWord {option value} {
        if {![string is wordchar -strict $value]} {
            throw {PDF4TCL} "option $option must be alphanumeric"
        }
    }

    # Validator for -rotate
    method CheckRotation {option value} {
        my CheckNumeric $value rotation -nonnegative -integer
        if { $value % 90  } {
            throw {PDF4TCL} "rotation $value not a multiple of 90"
        }
    }

    # Validator for -pdfa: accepts "", "1b", "2b"
    method CheckPdfa {option value} {
        if {$value ne "" && $value ne "1b" && $value ne "2b"} {
            throw {PDF4TCL} \
                "invalid -pdfa value \"$value\": must be \"\", \"1b\", or \"2b\""
        }
    }

    # Validator helper for numerics
    ##nagelfar syntax _obj,pdf4tcl\ CheckNumeric x x o*
    ##nagelfar option _obj,pdf4tcl\ CheckNumeric \
            -nonnegative -positive -integer -unit
    ##nagelfar option _obj,pdf4tcl\ CheckNumeric\ -unit x
    method CheckNumeric {val what args} {
        set origVal $val
        # If -unit is given, the value should be interpreted by getPoints
        set i [lsearch -exact $args -unit]
        if {$i >= 0} {
            set unit [lindex $args [expr {$i + 1}]]
            if {[catch {pdf4tcl::getPoints $val $unit} p]} {
                throw {PDF4TCL} "bad $what \"$val\", must be numeric"
            }
            set val $p
        }
        if {![string is double -strict $val]} {
            throw {PDF4TCL} "bad $what \"$origVal\", must be numeric"
        }
        set nonneg [lsearch -exact $args -nonnegative]
        set pos    [lsearch -exact $args -positive]
        set int    [lsearch -exact $args -integer]
        if {$nonneg >= 0 && $val < 0} {
            throw {PDF4TCL} "bad $what \"$origVal\", may not be negative"
        }
        if {$pos >= 0 && $val <= 0} {
            throw {PDF4TCL} "bad $what \"$origVal\", must be positive"
        }
        if {$int >= 0 && ![string is integer -strict $val]} {
            throw {PDF4TCL} "bad $what \"$origVal\", must be integer"
        }
        return $val
    }
} ;# end of class pdf4tcl::options
