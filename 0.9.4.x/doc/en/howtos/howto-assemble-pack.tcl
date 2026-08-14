#!/usr/bin/env tclsh
# Companion to howto-assemble-pack.md -- delegates to the full tutorial script
set tut [file join [file dirname [info script]] \
        ../tutorials/tutorial-06-assemble-pack.tcl]
puts "Running tutorial assemble script:"
puts "  $tut"
set rc [catch {exec [info nameofexecutable] $tut {*}$argv 2>@1} out]
puts $out
exit $rc
