#!/usr/bin/env tclsh
# tests/test-aes256.tcl -- AES-256 Einzeltest
# Testet beide Backends (tcl-sha und openssl) separat wenn verfuegbar.
# Aufruf: tclsh tests/test-aes256.tcl

set scriptDir [file dirname [file normalize [info script]]]
lappend auto_path [file join $scriptDir ..]

package require pdf4tcl 0.9.4

set pass 0
set fail 0
set skip 0

proc check {desc result expected} {
    global pass fail
    if {$result eq $expected} {
        puts "  OK  $desc"
        incr pass
    } else {
        puts "  FAIL $desc"
        puts "       erwartet: $expected"
        puts "       erhalten: $result"
        incr fail
    }
}

proc testWithBackend {backend} {
    global pass fail skip scriptDir

    puts "\n--- Backend: $backend ---"

    # Backend erzwingen
    catch {unset ::pdf4tcl::_shaBackend}
    set ::pdf4tcl::_shaBackend $backend

    if {[catch {
        set p [pdf4tcl::new %AUTO% -paper a4 \
            -userpassword "geheim" -ownerpassword "admin" -encversion 5]
        $p startPage
        $p setFont 12 Helvetica
        $p text "AES-256 Test ($backend)" -x 72 -y 72
        $p endPage
        set data [$p get]
        $p destroy
    } err]} {
        puts "  FAIL PDF erzeugen: $err"
        incr fail
        return
    }

    check "Encrypt-Dict vorhanden" [regexp {/Filter /Standard} $data] 1
    check "V=5"                    [regexp {/V 5\y} $data]            1
    check "R=6"                    [regexp {/R 6\y} $data]            1
    check "PDF 2.0"                [regexp {^%PDF-2\.0} $data]        1
    check "/T nicht im Klartext"   [string match *geheim* $data]      0

    if {[auto_execok qpdf] ne ""} {
        set tmpf [file join $scriptDir _aes256_${backend}.pdf]
        set fh [open $tmpf wb]
        puts -nonewline $fh $data
        close $fh
        if {[catch {exec qpdf --password=geheim --check $tmpf} out]} {
            puts "  FAIL qpdf: $out"
            incr fail
        } else {
            if {[string match {*User password = geheim*} $out]} {
                puts "  OK  qpdf: Passwort korrekt"
                incr pass
            } else {
                puts "  FAIL qpdf: Passwort nicht erkannt"
                incr fail
            }
        }
        file delete -force $tmpf
    } else {
        puts "  SKIP qpdf (nicht im PATH)"
        incr skip
    }
}

puts "\n=== AES-256 Test ==="
puts "Tcl [info patchlevel]"

if {![catch {package require sha}]} {
    testWithBackend tcl-sha
} else {
    puts "\n--- Backend: tcl-sha ---"
    puts "  SKIP tcl-sha (nicht verfuegbar)"
    incr skip
}

if {[auto_execok openssl] ne ""} {
    testWithBackend openssl
} else {
    puts "\n--- Backend: openssl ---"
    puts "  SKIP openssl (nicht im PATH)"
    incr skip
}

puts "\n=== Ergebnis: $pass bestanden, $fail fehlgeschlagen, $skip uebersprungen ===\n"
exit $fail
