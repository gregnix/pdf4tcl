#!/usr/bin/env tclsh
# diagnose.tcl -- Check which pdf4tcl is loaded and verify v2.1 features.
# Run from the tests/ directory:  tclsh diagnose.tcl

set tmp [file join [pwd] ..]
set ::auto_path [concat [list $tmp] $::auto_path]
package require pdf4tcl

puts "=== pdf4tcl Diagnostic ==="
puts "Package version: [package present pdf4tcl]"
puts "Loaded from:     [package ifneeded pdf4tcl [package present pdf4tcl]]"
puts "Working dir:     [pwd]"
puts "Parent dir:      $tmp"
puts ""

# Check key files
puts "=== Files ==="
foreach f [list $tmp/pdf4tcl.tcl $tmp/pkgIndex.tcl] {
    if {[file exists $f]} {
        puts "  $f  ([file size $f] bytes)"
    } else {
        puts "  $f  MISSING!"
    }
}
puts ""

# Feature tests
puts "=== Feature Tests ==="
set pdf [pdf4tcl::new %AUTO% -compress 0 -paper a4 -orient 1]
$pdf setFont 10 Helvetica
$pdf startPage

set pass 0
set fail 0

proc check {desc script} {
    upvar pass pass fail fail
    if {[catch {uplevel 1 $script} err]} {
        puts "  FAIL: $desc -- $err"
        incr fail
    } else {
        puts "  OK:   $desc"
        incr pass
    }
}

check "-required on text" {
    $pdf addForm text 10 10 100 18 -id diag_rq -required 1
}
check "-required rejected for pushbutton" {
    set ok [catch {$pdf addForm pushbutton 10 40 80 20 -caption X -action reset -required 1} err]
    if {!$ok || $err ne "-required is not valid for pushbutton"} {
        error "expected rejection, got: $err"
    }
}
check "-label on signature" {
    $pdf addForm signature 10 70 100 40 -label "Sign here"
}
check "-label rejected for text" {
    set ok [catch {$pdf addForm text 10 120 100 18 -label "test"} err]
    if {!$ok || $err ne "-label is only valid for signature fields"} {
        error "expected rejection, got: $err"
    }
}
check "signature auto-id = Signature<N>" {
    $pdf addForm signature 10 170 100 40
    set data [$pdf get]
    if {![regexp {/T \(Signature\d+\)} $data]} {
        error "auto-id not Signature<N>, got: [regexp -inline {/T \([^)]+\)} $data]"
    }
}

$pdf destroy

puts ""
puts "=== Result: $pass passed, $fail failed ==="
if {$fail > 0} {
    puts ""
    puts "If features fail, you may have an older pdf4tcl in your auto_path."
    puts "Check: package ifneeded pdf4tcl \[package present pdf4tcl\]"
    puts "Make sure the v2.1 pdf4tcl.tcl is in the parent directory."
}
