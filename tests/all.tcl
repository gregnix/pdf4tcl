# This file contains a top-level script to run all of the tests.
#
# $Id$

package require Tcl 8.4
package require tcltest 2.2
namespace import tcltest::*
eval configure $argv -testdir [list [file dir [info script]]]
workingDirectory [configure -testdir]
configure -tmpdir [configure -testdir]
#tcltest::configure -verbose t
#tcltest::configure -file font*
runAllTests
exit
