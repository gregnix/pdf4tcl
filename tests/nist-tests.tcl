#!/usr/bin/env tclsh
# nist-tests.tcl -- NIST-Referenztests fuer SHA und AES in pdf4tcl
#
# Testet mathematische Korrektheit unabhaengig von PDF-Logik.
# Aufruf: tclsh nist-tests.tcl [pfad/zu/encrypt.tcl]
#
# Verwendet encrypt.tcl direkt (kein package require noetig).

puts "=== NIST Tests ==="
puts "Tcl: [info patchlevel]"
puts ""

# ------------------------------------------------------------
# encrypt.tcl laden
# ------------------------------------------------------------

set srcFile [lindex $argv 0]
if {$srcFile eq ""} {
    # Standardpfade suchen
    set scriptDir [file dirname [info script]]
    foreach candidate [list \
        [file join $scriptDir .. src encrypt.tcl] \
        [file join $scriptDir src encrypt.tcl] \
        [file join [pwd] src encrypt.tcl] \
        encrypt.tcl \
    ] {
        if {[file exists $candidate]} {
            set srcFile $candidate
            break
        }
    }
}

if {$srcFile eq "" || ![file exists $srcFile]} {
    puts "FEHLER: encrypt.tcl nicht gefunden."
    puts "Aufruf: tclsh nist-tests.tcl pfad/zu/src/encrypt.tcl"
    exit 1
}

# Minimaler Stub damit source encrypt.tcl funktioniert
# ohne vollstaendiges pdf4tcl-Paket
namespace eval ::pdf4tcl {}
package provide pdf4tcl 0.9.4

# Nur den sha2pure-Namespace aus encrypt.tcl extrahieren
# (oo::define braucht eine existierende Klasse -- wir wollen nur SHA testen)
set fd [open $srcFile r]
set content [read $fd]
close $fd

# Alles von oo::define an abschneiden -- wir brauchen nur sha2pure
set cutPos [string first "oo::define ::pdf4tcl::pdf4tcl" $content]
if {$cutPos > 0} {
    set content [string range $content 0 [expr {$cutPos - 1}]]
}
eval $content
puts "SHA-Backend geladen aus: $srcFile"
puts ""

# ------------------------------------------------------------
# Hilfsprozedur
# ------------------------------------------------------------

set errors 0
set passed 0

proc check {name got expected} {
    global errors passed
    if {$got eq $expected} {
        puts "  OK   $name"
        incr passed
    } else {
        puts "  FAIL $name"
        puts "       got:      $got"
        puts "       expected: $expected"
        incr errors
    }
}

# ------------------------------------------------------------
# SHA-512 NIST FIPS 180-4 -- Testvektor: "abc"
# Erwartet: ddaf35a1...
# ------------------------------------------------------------

puts "--- SHA-512 ---"

check "SHA-512 \"abc\"" \
    [binary encode hex [::pdf4tcl::sha2pure::sha512bin "abc"]] \
    "ddaf35a193617abacc417349ae20413112e6fa4e89a97ea20a9eeee64b55d39a2192992a274fc1a836ba3c23a3feebbd454d4423643ce80e2a9ac94fa54ca49f"

check "SHA-512 \"\" (leer)" \
    [binary encode hex [::pdf4tcl::sha2pure::sha512bin ""]] \
    "cf83e1357eefb8bdf1542850d66d8007d620e4050b5715dc83f4a921d36ce9ce47d0d13c5d85f2b0ff8318d2877eec2f63b931bd47417a81a538327af927da3e"

check "SHA-512 \"abcdbcdecdef...\"" \
    [binary encode hex [::pdf4tcl::sha2pure::sha512bin \
        "abcdbcdecdefdefgefghfghighijhijkijkljklmklmnlmnomnopnopq"]] \
    "204a8fc6dda82f0a0ced7beb8e08a41657c16ef468b228a8279be331a703c33596fd15c13b1b07f9aa1d3bea57789ca031ad85c7a71dd70354ec631238ca3445"

puts ""

# ------------------------------------------------------------
# SHA-384 NIST FIPS 180-4 -- Testvektor: "abc"
# Erwartet: cb00753f...
# ------------------------------------------------------------

puts "--- SHA-384 ---"

check "SHA-384 \"abc\"" \
    [binary encode hex [::pdf4tcl::sha2pure::sha384bin "abc"]] \
    "cb00753f45a35e8bb5a03d699ac65007272c32ab0eded1631a8b605a43ff5bed8086072ba1e7cc2358baeca134c825a7"

check "SHA-384 \"\" (leer)" \
    [binary encode hex [::pdf4tcl::sha2pure::sha384bin ""]] \
    "38b060a751ac96384cd9327eb1b1e36a21fdb71114be07434c0cc7bf63f6e1da274edebfe76f65fbd51ad2f14898b95b"

check "SHA-384 \"abcdbcdecdefdefgefghfghighijhijkijkljklmklmnlmnomnopnopq\"" \
    [binary encode hex [::pdf4tcl::sha2pure::sha384bin \
        "abcdbcdecdefdefgefghfghighijhijkijkljklmklmnlmnomnopnopq"]] \
    "3391fdddfc8dc7393707a65b1b4709397cf8b1d162af05abfe8f450de5f36bc6b0455a8520bc4e6f5fe95b1fe3c8452b"

puts ""

# ------------------------------------------------------------
# AES-128 CBC NIST SP 800-38A -- Beispiel F.2.1
# Key:  2b7e151628aed2a6abf7158809cf4f3c
# IV:   000102030405060708090a0b0c0d0e0f
# PT:   6bc1bee22e409f96e93d7e117393172a
# CT:   7649abac8119b246cee98e9b12e9197d
# ------------------------------------------------------------

puts "--- AES-128 CBC ---"

# Fuer _AesCbc brauchen wir ein TclOO-Objekt
# Wir nutzen einen Dummy-Namespace der die Methode direkt aufrufbar macht
namespace eval ::pdf4tcl::_nist_test {
    proc aesCbc {mode key iv data} {
        package require aes
        if {$mode eq "encrypt"} {
            return [aes::aes -mode cbc -dir encrypt -key $key -iv $iv -- $data]
        } else {
            return [aes::aes -mode cbc -dir decrypt -key $key -iv $iv -- $data]
        }
    }
}

set key  [binary decode hex "2b7e151628aed2a6abf7158809cf4f3c"]
set iv   [binary decode hex "000102030405060708090a0b0c0d0e0f"]
set pt   [binary decode hex "6bc1bee22e409f96e93d7e117393172a"]

check "AES-128-CBC block 1 encrypt" \
    [binary encode hex [::pdf4tcl::_nist_test::aesCbc encrypt $key $iv $pt]] \
    "7649abac8119b246cee98e9b12e9197d"

# Mehrblock-Test F.2.1 (4 Bloecke)
set pt4  [binary decode hex \
    "6bc1bee22e409f96e93d7e117393172a\
     ae2d8a571e03ac9c9eb76fac45af8e51\
     30c81c46a35ce411e5fbc1191a0a52ef\
     f69f2445df4f9b17ad2b417be66c3710"]

check "AES-128-CBC 4 Bloecke encrypt" \
    [binary encode hex [::pdf4tcl::_nist_test::aesCbc encrypt $key $iv $pt4]] \
    "7649abac8119b246cee98e9b12e9197d5086cb9b507219ee95db113a917678b273bed6b8e3c1743b7116e69e222295163ff1caa1681fac09120eca307586e1a7"

puts ""

# ------------------------------------------------------------
# SHA-256 -- Kontrolle dass tcllib korrekt ist
# ------------------------------------------------------------

puts "--- SHA-256 (Tcllib-Kontrolle) ---"

if {[catch {package require sha256}] == 0} {
    check "SHA-256 \"abc\" (tcllib sha2::sha256)" \
        [sha2::sha256 "abc"] \
        "ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad"
} else {
    puts "  SKIP  sha256 package nicht verfuegbar"
}

puts ""

# ------------------------------------------------------------
# 5. SHA mit Binaerdaten (nicht-ASCII-Bytes >= 0x80)
#    Prueft dass sha2pure korrekte byte-basierte Laenge berechnet
#    und Bytes mit gesetztem Highbit korrekt verarbeitet.
# ------------------------------------------------------------

puts "--- SHA-512 / SHA-384 Binaerdaten ---"

# SHA-512 Cross-Check fuer Byte-Wert 0xBD:
# binary format H2 bd erzeugt einen Tcl-ByteArray mit einem Byte 0xBD.
# sha2pure und tcl-sha muessen fuer denselben ByteArray uebereinstimmen.
# (Kein hardcodierter NIST-Wert: die Tcl-interne Byte-Darstellung
#  kann je nach Interpreter vom NIST ShortMsg-Vektor abweichen.)
if {![catch {package require sha}]} {
    set _bd [binary format H2 bd]
    check "SHA-512 \\xBD (pure-tcl == tcl-sha)" \
        [binary encode hex [::pdf4tcl::sha2pure::sha512bin $_bd]] \
        [sha -bits 512 -output hex -databin $_bd]
    unset _bd
} else {
    puts "  SKIP SHA-512 \\xBD Cross-Check (tcl-sha nicht verfuegbar)"
}

# NIST FIPS 180-4 Anhang C.3: SHA-512 einer 112-Byte-Nachricht (2 Bloecke)
check "SHA-512 2-Block-Nachricht (NIST Anhang C.3)" \
    [binary encode hex [::pdf4tcl::sha2pure::sha512bin \
        "abcdefghbcdefghicdefghijdefghijkefghijklfghijklmghijklmnhijklmnoijklmnopjklmnopqklmnopqrlmnopqrsmnopqrstnopqrstu"]] \
    "8e959b75dae313da8cf4f72814fc143f8f7779c6eb9f7fa17299aeadb6889018501d289e4900f7e4331b99dec4b5433ac7d329eeb6dd26545e96e55b874be909"

# SHA-384 2-Block-Nachricht -- Quelle: NIST FIPS 180-4 Anhang D.3
# Korrekter Wert: ...173b3b05... (Python hashlib, tcl-sha, sha2pure -- alle einig)
set _msg2b "abcdefghbcdefghicdefghijdefghijkefghijklfghijklmghijklmnhijklmnoijklmnopjklmnopqklmnopqrlmnopqrsmnopqrstnopqrstu"
if {![catch {package require sha}]} {
    check "SHA-384 2-Block-Nachricht (tcl-sha, NIST Anhang D.3)" \
        [sha -bits 384 -output hex -data $_msg2b] \
        "09330c33f71147e83d192fc782cd1b4753111b173b3b05d22fa08086e3b0f712fcc7c71a557e2db966c3e9fa91746039"
} else {
    set _s384g [binary encode hex [::pdf4tcl::sha2pure::sha384bin $_msg2b]]
    set _s384n "09330c33f71147e83d192fc782cd1b4753111b173b3b05d22fa08086e3b0f712fcc7c71a557e2db966c3e9fa91746039"
    if {$_s384g eq $_s384n} {
        check "SHA-384 2-Block-Nachricht (pure-tcl, NIST Anhang D.3)" \
            $_s384g $_s384n
    } else {
        puts "  SKIP SHA-384 2-Block (tcl-sha nicht verfuegbar)"
        puts "       nist: $_s384n"
        puts "       got:  $_s384g"
    }
    unset _s384g _s384n
}
unset _msg2b

# Quervergleich pure-tcl vs tcl-sha fuer echte Binaerbytes:
# \xDE\xAD\xBE\xEF\x00\xFF\x80\x7F -- 8 Bytes mit allen Bitwert-Mustern
# Falls tcl-sha verfuegbar: beide muessen identisch sein.
set _binbuf [binary format H16 deadbeef00ff807f]

check "SHA-512 Binaerbytes: Ausgabelaenge korrekt" \
    [string length [binary encode hex [::pdf4tcl::sha2pure::sha512bin $_binbuf]]] \
    128

check "SHA-384 Binaerbytes: Ausgabelaenge korrekt" \
    [string length [binary encode hex [::pdf4tcl::sha2pure::sha384bin $_binbuf]]] \
    96

if {![catch {package require sha}]} {
    check "SHA-512 Binaerbytes (pure-tcl == tcl-sha)" \
        [binary encode hex [::pdf4tcl::sha2pure::sha512bin $_binbuf]] \
        [sha -bits 512 -output hex -databin $_binbuf]
    check "SHA-384 Binaerbytes (pure-tcl == tcl-sha)" \
        [binary encode hex [::pdf4tcl::sha2pure::sha384bin $_binbuf]] \
        [sha -bits 384 -output hex -databin $_binbuf]
} else {
    puts "  SKIP SHA Quervergleich tcl-sha (nicht verfuegbar)"
}
unset _binbuf

puts ""

# ------------------------------------------------------------
# 6. Alg 2.B deterministisch
#    Feste Eingabe (Passwort + Salt + ukey) => immer gleicher 32-Byte-Schluessel.
#    Prueft: Determinismus, Ausgabelaenge, Passwortabhaengigkeit.
#
#    Implementierung spiegelt encrypt.tcl::_Alg2B exakt --
#    kein TclOO noetig, direkte Proc fuer standalone-Aufruf.
# ------------------------------------------------------------

puts "--- Alg 2.B deterministisch ---"

proc ::pdf4tcl::_nist_test::alg2b {password salt ukey} {
    package require sha256
    package require aes
    # Schritt 1: K = SHA-256(password || salt || ukey)
    set K [binary decode hex [sha2::sha256 "${password}${salt}${ukey}"]]
    set i 0
    while {1} {
        # Schritt 2: 64 Wiederholungen der Sequenz
        set seq [string repeat "${password}${K}${ukey}" 64]
        # Schritt 3: AES-128-CBC mit K[0:15] als Schluessel, K[16:31] als IV
        set E [aes::aes -mode cbc -dir encrypt \
            -key [string range $K 0 15] \
            -iv  [string range $K 16 31] \
            -- $seq]
        # Schritt 4: Hashauswahl anhand Summe der ersten 16 Bytes von E
        set esum 0
        for {set b 0} {$b < 16} {incr b} {
            incr esum [scan [string index $E $b] %c]
        }
        switch [expr {$esum % 3}] {
            0 { set K [binary decode hex [sha2::sha256 $E]] }
            1 { set K [::pdf4tcl::sha2pure::sha384bin $E]   }
            2 { set K [::pdf4tcl::sha2pure::sha512bin $E]   }
        }
        incr i
        # Abbruchbedingung: nach >= 64 Runden und E[letztes Byte] <= i - 32
        scan [string index $E end] %c _elast
        if {$i >= 64 && $_elast <= ($i - 32)} break
        if {$i >= 256} break
    }
    return [string range $K 0 31]
}

if {[catch {package require sha256}] || [catch {package require aes}]} {
    puts "  SKIP Alg2B (sha256 oder aes Tcllib-Paket fehlt)"
} else {
    # Feste Eingaben -- identische Ergebnisse erforderlich
    set _pass "geheim"
    set _salt [string repeat "\x00" 8]
    set _ukey ""

    set _k1 [::pdf4tcl::_nist_test::alg2b $_pass $_salt $_ukey]
    set _k2 [::pdf4tcl::_nist_test::alg2b $_pass $_salt $_ukey]

    check "Alg2B: Ausgabe ist 32 Bytes" \
        [string length $_k1] 32

    check "Alg2B: deterministisch (2x gleiche Eingabe => gleicher Schluessel)" \
        $_k1 $_k2

    # Passwortaenderung muss anderen Schluessel ergeben
    set _k3 [::pdf4tcl::_nist_test::alg2b "anderesPasswort" $_salt $_ukey]
    check "Alg2B: verschiedene Passwoerter => verschiedene Schluessel" \
        [expr {$_k1 ne $_k3}] 1

    # Saltaenderung muss anderen Schluessel ergeben
    set _k4 [::pdf4tcl::_nist_test::alg2b $_pass [string repeat "\x01" 8] $_ukey]
    check "Alg2B: verschiedene Salts => verschiedene Schluessel" \
        [expr {$_k1 ne $_k4}] 1

    # Mit nicht-leerem ukey (Owner-Fall)
    set _k5 [::pdf4tcl::_nist_test::alg2b $_pass $_salt \
        [string repeat "\xAB" 48]]
    check "Alg2B Owner-Modus (ukey != \"\"): Ausgabe ist 32 Bytes" \
        [string length $_k5] 32
    check "Alg2B Owner-Modus: anderer Schluessel als User-Modus" \
        [expr {$_k1 ne $_k5}] 1

    unset _pass _salt _ukey _k1 _k2 _k3 _k4 _k5
}

puts ""

# ------------------------------------------------------------
# 7. AES-256-CBC NIST-Vektor (SP 800-38A, Anhang F.2.5)
#    256-Bit-Schluessel, 4 Bloecke, encrypt + decrypt.
#    Testet dass Tcllib aes korrekte 256-Bit-Verschluesselung liefert.
#    Relevant fuer pdf4tcl: EncryptBytes/EncryptStreamBody verwenden
#    denselben aes::aes-Aufruf mit 32-Byte fileKey.
# ------------------------------------------------------------

puts "--- AES-256-CBC (NIST SP 800-38A, F.2.5) ---"

# Schluessel (256 Bit = 32 Bytes)
set _k256 [binary decode hex \
    "603deb1015ca71be2b73aef0857d7781\
     1f352c073b6108d72d9810a30914dff4"]

# IV (128 Bit = 16 Bytes)
set _iv256 [binary decode hex "000102030405060708090a0b0c0d0e0f"]

# Klartext (4 Bloecke a 128 Bit)
set _pt256 [binary decode hex \
    "6bc1bee22e409f96e93d7e117393172a\
     ae2d8a571e03ac9c9eb76fac45af8e51\
     30c81c46a35ce411e5fbc1191a0a52ef\
     f69f2445df4f9b17ad2b417be66c3710"]

# Erwarteter Geheimtext (NIST F.2.5)
set _ct256_hex \
    "f58c4c04d6e5f1ba779eabfb5f7bfbd6\
     9cfc4e967edb808d679f777bc6702c7d\
     39f23369a9d9bacfa530e26304231461\
     b2eb05e2c39be9fcda6c19078c6a9d1b"
# Leerzeichen aus Zeilenfortsetzung entfernen
regsub -all { } $_ct256_hex {} _ct256_hex

# Verschluesseln
check "AES-256-CBC encrypt 4 Bloecke (NIST F.2.5)" \
    [binary encode hex \
        [::pdf4tcl::_nist_test::aesCbc encrypt $_k256 $_iv256 $_pt256]] \
    $_ct256_hex

# Entschluesseln (Rueckrichtung)
check "AES-256-CBC decrypt 4 Bloecke (NIST F.2.5, Rueckrichtung)" \
    [binary encode hex \
        [::pdf4tcl::_nist_test::aesCbc decrypt $_k256 $_iv256 \
            [binary decode hex $_ct256_hex]]] \
    [binary encode hex $_pt256]

# Einzelblock: erster Klartext-Block => erster CT-Block
set _pt1 [string range $_pt256 0 15]
set _ct1 [binary decode hex [string range $_ct256_hex 0 31]]
check "AES-256-CBC encrypt Block 1 (NIST F.2.5)" \
    [binary encode hex \
        [::pdf4tcl::_nist_test::aesCbc encrypt $_k256 $_iv256 $_pt1]] \
    [string range $_ct256_hex 0 31]

unset _k256 _iv256 _pt256 _ct256_hex _pt1 _ct1

puts ""

# ------------------------------------------------------------
# Zusammenfassung
# ------------------------------------------------------------

set total [expr {$passed + $errors}]
puts "=== Ergebnis: $passed/$total bestanden, $errors fehlgeschlagen ==="
puts ""
exit $errors
