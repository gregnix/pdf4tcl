###############################################################################
# pdf4tcl - Encryption support
#
# AES-128: Standard Security Handler V=4 R=4 (PDF 1.5+, ISO 32000-1 §7.6)
# AES-256: Standard Security Handler V=5 R=6 (PDF 2.0, ISO 32000-2 §7.6.4)
#
# AES-128 algorithms:
#   Alg 1  - Encrypt data per object  (§7.6.2)
#   Alg 2  - Derive encryption key    (§7.6.3.3)
#   Alg 3  - Compute O entry          (§7.6.3.4)
#   Alg 5  - Compute U entry (R≥3)    (§7.6.3.4)
#
# AES-256 algorithms:
#   Alg 2.B - Iterative hash (SHA-256/384/512)    (§7.6.4.3.3)
#   Alg 3   - Compute O and OE entries            (§7.6.4.4.3)
#   Alg 4   - Compute U and UE entries            (§7.6.4.4.4)
#   Alg 5   - Compute Perms entry                 (§7.6.4.4.5)
#   Alg 6   - Authenticate user password          (§7.6.4.4.6)
#   Alg 7   - Authenticate owner password         (§7.6.4.4.7)
#   Alg 9   - Recover file key via U/UE           (§7.6.4.4.9)
###############################################################################

oo::define ::pdf4tcl::pdf4tcl {

    ###########################################################################
    # SHA abstraction layer
    # Priority: tcl-sha → openssl exec
    #
    # Das SHA-Backend wird einmalig in _InitSHABackend ermittelt und in
    # der Namespace-Variable ::pdf4tcl::_shaBackend gecacht.
    # So wird package require sha nur einmal aufgerufen, nicht pro Iteration
    # der Alg.-2.B-Schleife (die 64-256 Mal laeuft = 500+ Aufrufe pro PDF).
    ###########################################################################

    method _InitSHABackend {} {
        if {[info exists ::pdf4tcl::_shaBackend]} { return }
        # twapi hat kein SHA-384/512 (nur md5/sha1/sha256) -- nicht versuchen.
        # 1. tcl-sha -- Tcl 9 benoetigt anderen Pfad als Tcl 8.6
        if {[package vsatisfies [info tclversion] 9.0-]} {
            # Unter Tcl 9: tcl8.6-Pfad aus auto_path entfernen,
            # tcl9.0-Pfad vorne einsetzen (analog zu demo01.tcl)
            set _p86 [file join $::env(HOME) lib share tcl8.6]
            set _p90 [file join $::env(HOME) lib share tcl9.0]
            set ::auto_path [lsearch -all -inline -not -exact $::auto_path $_p86]
            set ::auto_path [linsert $::auto_path 0 $_p90]
        }
        if {![catch {package require sha}]} {
            set ::pdf4tcl::_shaBackend tcl-sha
            return
        }
        # 2. openssl im PATH (plattformuebergreifend)
        if {[auto_execok openssl] ne ""} {
            set ::pdf4tcl::_shaBackend openssl
            return
        }
        set _msg "pdf4tcl AES-256: SHA-384/512 nicht verfuegbar"
        append _msg " (Tcl [info patchlevel], $::tcl_platform(os)).\n"
        append _msg "Bitte eines der folgenden installieren:\n"
        append _msg "  - tcl-sha (https://sourceforge.net/projects/tcl-sha/)\n"
        append _msg "  - openssl im PATH (Linux/macOS: meist vorhanden,"
        append _msg " Windows: https://slproweb.com/products/Win32OpenSSL.html)"
        throw {PDF4TCL} $_msg
    }

    method _SHA256 {data} {
        package require sha256
        binary decode hex [sha2::sha256 $data]
    }

    method _SHA384 {data} {
        my _InitSHABackend
        switch $::pdf4tcl::_shaBackend {
            tcl-sha { return [binary decode hex [sha -bits 384 -output hex -databin $data]] }
            default {
                set ch [open "|openssl dgst -sha384 -binary" w+b]
                puts -nonewline $ch $data
                catch {chan close $ch write}
                set result [read $ch]
                close $ch
                return $result
            }
        }
    }

    method _SHA512 {data} {
        my _InitSHABackend
        switch $::pdf4tcl::_shaBackend {
            tcl-sha { return [binary decode hex [sha -bits 512 -output hex -databin $data]] }
            default {
                set ch [open "|openssl dgst -sha512 -binary" w+b]
                puts -nonewline $ch $data
                catch {chan close $ch write}
                set result [read $ch]
                close $ch
                return $result
            }
        }
    }

    ###########################################################################
    # PDF password padding string (ISO 32000 §7.6.3.3 step a)
    # Used only for AES-128 (R=4).
    ###########################################################################
    method _EncPadStr {} {
        # NOTE: PDF spec §7.6.3.3 byte 31 = 0x72, but qpdf/pikepdf use 0x7a
        # (de-facto standard) – use 0x7a for interoperability.
        return [binary format H64 \
            28BF4E5E4E758A4164004E56FFFA01082E2E00B6D0683E802F0CA9FE6453697A]
    }

    ###########################################################################
    # RC4 stream cipher (pure Tcl)
    # Used only for O/U entry computation in AES-128 (R=4).
    ###########################################################################
    method _RC4 {key data} {
        set klen [string length $key]
        set dlen [string length $data]
        for {set i 0} {$i < 256} {incr i} { lappend S $i }
        set j 0
        for {set i 0} {$i < 256} {incr i} {
            set ki [scan [string index $key [expr {$i % $klen}]] %c]
            set j  [expr {($j + [lindex $S $i] + $ki) & 0xFF}]
            set tmp [lindex $S $i]; lset S $i [lindex $S $j]; lset S $j $tmp
        }
        set i 0; set j 0; set out {}
        for {set n 0} {$n < $dlen} {incr n} {
            set i [expr {($i + 1) & 0xFF}]
            set j [expr {($j + [lindex $S $i]) & 0xFF}]
            set tmp [lindex $S $i]; lset S $i [lindex $S $j]; lset S $j $tmp
            set ks [lindex $S [expr {([lindex $S $i] + [lindex $S $j]) & 0xFF}]]
            append out [format %c [expr {[scan [string index $data $n] %c] ^ $ks}]]
        }
        return $out
    }

    ###########################################################################
    # Generate n random bytes (used for IV, salts, file key)
    ###########################################################################
    method _EncRandBytes {n} {
        if {[catch {
            set fh [open /dev/urandom rb]
            set bytes [read $fh $n]
            close $fh
        }]} {
            set bytes ""
            for {set i 0} {$i < $n} {incr i} {
                append bytes [format %c [expr {int(rand()*256)}]]
            }
        }
        return $bytes
    }

    ###########################################################################
    # ===== AES-128 (V=4 R=4) algorithms =====
    ###########################################################################

    # Algorithm 2: Compute the encryption key (AES-128)
    method _EncKey {password O P fileId} {
        set padstr [my _EncPadStr]
        set pwd [string range ${password}${padstr} 0 31]
        package require md5
        set ctx [md5::MD5Init]
        md5::MD5Update $ctx $pwd
        md5::MD5Update $ctx $O
        md5::MD5Update $ctx [binary format i $P]
        md5::MD5Update $ctx $fileId
        set hash [md5::MD5Final $ctx]
        for {set i 0} {$i < 50} {incr i} {
            set hash [md5::md5 [string range $hash 0 15]]
        }
        return [string range $hash 0 15]
    }

    # Algorithm 3: Compute O entry (AES-128)
    method _EncComputeO {ownerPwd userPwd} {
        set padstr [my _EncPadStr]
        package require md5
        set opwd [expr {$ownerPwd eq {} ? $userPwd : $ownerPwd}]
        set opwd [string range ${opwd}${padstr} 0 31]
        set hash [md5::md5 $opwd]
        for {set i 0} {$i < 50} {incr i} { set hash [md5::md5 $hash] }
        set rc4key [string range $hash 0 15]
        set upwd [string range ${userPwd}${padstr} 0 31]
        set out [my _RC4 $rc4key $upwd]
        for {set i 1} {$i <= 19} {incr i} {
            set xkey ""
            for {set b 0} {$b < 16} {incr b} {
                append xkey [format %c \
                    [expr {[scan [string index $rc4key $b] %c] ^ $i}]]
            }
            set out [my _RC4 $xkey $out]
        }
        return $out
    }

    # Algorithm 5: Compute U entry (AES-128, R=4)
    method _EncComputeU {encKey fileId} {
        set padstr [my _EncPadStr]
        package require md5
        set ctx [md5::MD5Init]
        md5::MD5Update $ctx $padstr
        md5::MD5Update $ctx $fileId
        set hash [md5::MD5Final $ctx]
        set out [my _RC4 $encKey $hash]
        for {set i 1} {$i <= 19} {incr i} {
            set xkey ""
            for {set b 0} {$b < 16} {incr b} {
                append xkey [format %c \
                    [expr {[scan [string index $encKey $b] %c] ^ $i}]]
            }
            set out [my _RC4 $xkey $out]
        }
        append out [string repeat "\x00" 16]
        return $out
    }

    # Algorithm 1 (AES variant): Per-object key (AES-128)
    method _ObjKey128 {oid} {
        package require md5
        set inp "$pdf(encKey)"
        append inp [binary format ccc \
            [expr {$oid & 0xFF}] \
            [expr {($oid >> 8) & 0xFF}] \
            [expr {($oid >> 16) & 0xFF}]]
        append inp "\x00\x00sAlT"
        return [string range [md5::md5 $inp] 0 15]
    }

    # Alias for backward compatibility
    method _ObjKey {oid} { my _ObjKey128 $oid }

    ###########################################################################
    # ===== AES-256 (V=5 R=6) algorithms =====
    ###########################################################################

    # Algorithm 2.B: Key derivation for AES-256 (ISO 32000-2 §7.6.4.3.3)
    # password : UTF-8 bytes, max 127
    # salt     : 8 random bytes (validation-salt or key-salt)
    # ukey     : U entry (48 bytes) for owner hash, "" for user hash
    # returns  : 32-byte AES-256 key
    #
    # NOTE: ISO 32000-2 specifies an iterative SHA-256/384/512 loop here.
    # In practice qpdf, Adobe Reader, and all major PDF tools implement
    # only the first step: SHA-256(password || salt || ukey).
    # The full iterative loop produces ISO-correct but qpdf-incompatible PDFs.
    # We use SHA-256 directly for interoperability.
    # Algorithm 2.B: Key derivation for AES-256 (ISO 32000-2 §7.6.4.3.3)
    # password : UTF-8 bytes, max 127
    # salt     : 8 random bytes (validation-salt or key-salt from U/O)
    # ukey     : U entry (48 bytes) when computing O-hash, "" for U-hash
    # returns  : 32-byte derived key
    #
    # Implementation follows qpdf/pypdf/pikepdf/Adobe, NOT the literal ISO text:
    #   1. Concatenation order: password || K || ukey  (ISO says K || password || ukey)
    #   2. Hash selector:       sum(E[0:16]) % 3       (ISO says E[1] % 3)
    #   3. K length: K keeps full SHA-384 (48B) or SHA-512 (64B) size in loop
    # Only these three deviations produce PDFs accepted by qpdf and Adobe Reader.

    # _AesCbc: AES-CBC-Wrapper mit Tcl-9-kompatibler Byte-Konvertierung
    # Tcllib aes erwartet unter Tcl 9 iso8859-1-kodierte Strings (reine Bytes).
    method _AesCbc {mode key iv data} {
        if {[info tclversion] >= 9} {
            set key  [encoding convertto iso8859-1 $key]
            set iv   [encoding convertto iso8859-1 $iv]
            set data [encoding convertto iso8859-1 $data]
            set r [aes::aes -mode cbc -dir $mode -key $key -iv $iv $data]
            return [encoding convertfrom iso8859-1 $r]
        }
        return [aes::aes -mode cbc -dir $mode -key $key -iv $iv $data]
    }

    method _AesEcb {mode key data} {
        if {[info tclversion] >= 9} {
            set key  [encoding convertto iso8859-1 $key]
            set data [encoding convertto iso8859-1 $data]
            set r [aes::aes -mode ecb -dir $mode -key $key $data]
            return [encoding convertfrom iso8859-1 $r]
        }
        return [aes::aes -mode ecb -dir $mode -key $key $data]
    }

    method _Alg2B {password salt ukey} {
        # Alg. 2.B (ISO 32000-2 §7.6.4.3.3), qpdf-kompatibel.
        # Implementierung mit Tcllib aes (pure Tcl).
        # Bekannte Einschraenkung: AES-256-Erzeugung dauert ~20-25s
        # (Tcllib-AES auf grossen Bloecken in enger Schleife).
        # Tcl 9: aes::aes benoetigt Byte-Strings (encoding convertto iso8859-1)
        set K [my _SHA256 "${password}${salt}${ukey}"]
        set i 0
        while {1} {
            set seq [string repeat "${password}${K}${ukey}" 64]
            set E [my _AesCbc encrypt \
                [string range $K 0 15] [string range $K 16 31] $seq]
            set esum 0
            for {set b 0} {$b < 16} {incr b} {
                incr esum [scan [string index $E $b] %c]
            }
            switch [expr {$esum % 3}] {
                0 { set K [my _SHA256 $E] }
                1 { set K [my _SHA384 $E] }
                2 { set K [my _SHA512 $E] }
            }
            incr i
            scan [string index $E end] %c elast
            if {$i >= 64 && $elast <= ($i - 32)} break
            if {$i >= 256} break
        }
        return [string range $K 0 31]
    }

    # Algorithm 4: Compute U and UE entries (AES-256)
    # returns {U UE}  -- U=48 bytes, UE=32 bytes
    method _Alg4 {password fileKey} {
        set uvs [my _EncRandBytes 8]
        set uks [my _EncRandBytes 8]
        set hashU [my _Alg2B $password $uvs ""]
        set U "${hashU}${uvs}${uks}"
        set encKeyU [my _Alg2B $password $uks ""]
        set nullIV [string repeat \x00 16]
        set UE [my _AesCbc encrypt $encKeyU $nullIV $fileKey]
        return [list $U $UE]
    }

    # Algorithm 3: Compute O and OE entries (AES-256)
    # returns {O OE}  -- O=48 bytes, OE=32 bytes
    method _Alg3_256 {password fileKey U} {
        set ovs [my _EncRandBytes 8]
        set oks [my _EncRandBytes 8]
        set hashO [my _Alg2B $password $ovs $U]
        set O "${hashO}${ovs}${oks}"
        set encKeyO [my _Alg2B $password $oks $U]
        set nullIV [string repeat \x00 16]
        set OE [my _AesCbc encrypt $encKeyO $nullIV $fileKey]
        return [list $O $OE]
    }

    # Algorithm 5: Compute Perms entry (AES-256, 16 bytes)
    # ISO 32000-2 §7.6.4.4.5: encrypt with AES-256 in ECB mode (no IV).
    # Note: CBC with IV=0 produces the same result for exactly one 16-byte
    # block, but ECB is the spec-correct mode and must be used explicitly.
    method _Alg5_256 {fileKey P} {
        set perms [binary format i $P]   ;# bytes 0-3: P little-endian
        append perms "\xFF\xFF\xFF\xFF"   ;# bytes 4-7: high 32 bits all set
        append perms "T"                  ;# byte 8: EncryptMetadata = true
        append perms "adb"               ;# bytes 9-11: pad
        append perms [my _EncRandBytes 4] ;# bytes 12-15: random
        return [my _AesEcb encrypt $fileKey $perms]
    }

    ###########################################################################
    # Encrypt binary data for a given object
    # Dispatches to AES-128 or AES-256 based on pdf(encVersion)
    ###########################################################################
    method EncryptBytes {oid data} {
        package require aes
        if {$pdf(encVersion) == 5} {
            # AES-256-CBC: IV || ciphertext
            set key $pdf(encKey)  ;# 32-byte file key (same for all objects)
            set dlen [string length $data]
            set padlen [expr {16 - ($dlen % 16)}]
            append data [string repeat [format %c $padlen] $padlen]
            set iv [my _EncRandBytes 16]
            set ct [my _AesCbc encrypt $key $iv $data]
            return "${iv}${ct}"
        } else {
            # AES-128-CBC: per-object key, IV || ciphertext
            set key [my _ObjKey128 $oid]
            set dlen [string length $data]
            set padlen [expr {16 - ($dlen % 16)}]
            append data [string repeat [format %c $padlen] $padlen]
            set iv [my _EncRandBytes 16]
            set ct [my _AesCbc encrypt $key $iv $data]
            return "${iv}${ct}"
        }
    }

    ###########################################################################
    # Initialize encryption state
    # Called from InitPdf when -userpassword or -ownerpassword is set.
    ###########################################################################
    method InitEncrypt {} {
        if {!$pdf(encrypt)} { return }

        package require aes

        set pdf(encVersion) $options(-encversion)
        set pdf(encFileId)  [my _EncRandBytes 16]

        if {$pdf(encVersion) == 5} {
            # AES-256 (V=5 R=6)
            # Random 32-byte file encryption key
            set fileKey [my _EncRandBytes 32]
            set pdf(encKey) $fileKey

            set uPwd [encoding convertto utf-8 \
                [string range $options(-userpassword)  0 126]]
            set oPwd [encoding convertto utf-8 \
                [string range $options(-ownerpassword) 0 126]]
            if {$oPwd eq ""} { set oPwd $uPwd }

            lassign [my _Alg4 $uPwd $fileKey] pdf(encU) pdf(encUE)
            lassign [my _Alg3_256 $oPwd $fileKey $pdf(encU)] \
                pdf(encO) pdf(encOE)
            set pdf(encPerms) [my _Alg5_256 $fileKey $pdf(encP)]

        } else {
            # AES-128 (V=4 R=4)
            set pdf(encO) [my _EncComputeO \
                $options(-ownerpassword) \
                $options(-userpassword)]
            set pdf(encKey) [my _EncKey \
                $options(-userpassword) \
                $pdf(encO) \
                $pdf(encP) \
                $pdf(encFileId)]
            set pdf(encU) [my _EncComputeU \
                $pdf(encKey) $pdf(encFileId)]
            set pdf(encUE)    ""
            set pdf(encOE)    ""
            set pdf(encPerms) ""
        }
    }

    ###########################################################################
    # Encrypt stream body (finds stream, encrypts content, updates /Length)
    ###########################################################################
    method EncryptStreamBody {oid body} {
        set sstart [string first "stream\n" $body]
        if {$sstart < 0} { return $body }
        incr sstart 7
        set send [string first "\nendstream" $body $sstart]
        if {$send < 0} { return $body }
        set plaintext [string range $body $sstart ${send}-1]
        set ciphertext [my EncryptBytes $oid $plaintext]
        set newlen [string length $ciphertext]
        set newbody [string replace $body $sstart ${send}-1 $ciphertext]
        # /Length kann direkt (/Length 123) oder indirekt (/Length 6 0 R) sein.
        # Indirekten Fall vollstaendig ersetzen (inkl. "N 0 R").
        # Direkten Fall einfach ersetzen.
        if {![regsub {/Length\s+[0-9]+\s+0\s+R} $newbody "/Length $newlen" newbody]} {
            regsub {/Length\s+[0-9]+} $newbody "/Length $newlen" newbody
        }
        return $newbody
    }

    ###########################################################################
    # Decode PDF literal string escape sequences to raw bytes
    # Input:  content between outer parentheses, e.g. "hello\\(world\\)"
    # Output: raw byte string, e.g. "hello(world)"
    ###########################################################################
    method _PdfLiteralToBytes {inner} {
        set out ""
        set i 0
        set len [string length $inner]
        while {$i < $len} {
            set ch [string index $inner $i]
            if {$ch eq "\\"} {
                incr i
                if {$i >= $len} { append out "\\"; break }
                set esc [string index $inner $i]
                switch -- $esc {
                    n  { append out "\n" }
                    r  { append out "\r" }
                    t  { append out "\t" }
                    b  { append out "\b" }
                    f  { append out "\f" }
                    (  { append out "(" }
                    )  { append out ")" }
                    \\ { append out "\\" }
                    default {
                        # octal: up to 3 digits
                        if {[string match {[0-7]} $esc]} {
                            set oct $esc
                            for {set k 1} {$k < 3} {incr k} {
                                set ni [expr {$i + $k}]
                                if {$ni < $len &&
                                    [string match {[0-7]} \
                                         [string index $inner $ni]]} {
                                    append oct [string index $inner $ni]
                                } else {
                                    break
                                }
                            }
                            incr i [expr {[string length $oct] - 1}]
                            append out [format %c [scan $oct %o]]
                        } else {
                            # unknown escape: keep literally
                            append out $esc
                        }
                    }
                }
            } else {
                append out $ch
            }
            incr i
        }
        return $out
    }

    ###########################################################################
    # Encrypt all PDF literal strings (...)  in the dictionary part of a body.
    # Replaces (plaintext) with <encrypted-hex> per ISO 32000 §7.6.5.
    # The stream content is not touched here (EncryptStreamBody handles that).
    # Called from FlushObjects for every non-Encrypt-Dict object.
    ###########################################################################
    method EncryptStringsInBody {oid body} {
        if {!$pdf(encrypt)} { return $body }

        # Only process up to "stream\n" if present (stream handled separately)
        set sstart [string first "stream\n" $body]
        if {$sstart >= 0} {
            set dictpart [string range $body 0 $sstart-1]
            set restpart [string range $body $sstart end]
        } else {
            set dictpart $body
            set restpart ""
        }

        set result ""
        set i 0
        set len [string length $dictpart]

        while {$i < $len} {
            set ch [string index $dictpart $i]
            if {$ch eq "("} {
                # Parse balanced PDF string literal
                set depth 1
                set j [expr {$i + 1}]
                while {$j < $len && $depth > 0} {
                    set c [string index $dictpart $j]
                    if {$c eq "\\"} {
                        # skip next char (escape sequence)
                        incr j 2
                        continue
                    }
                    if {$c eq "("} { incr depth }
                    if {$c eq ")"} { incr depth -1 }
                    incr j
                }
                # inner = content between outer parens
                set inner [string range $dictpart [expr {$i+1}] [expr {$j-2}]]
                set plainbytes [my _PdfLiteralToBytes $inner]
                set cipher [my EncryptBytes $oid $plainbytes]
                binary scan $cipher H* hexstr
                append result "<$hexstr>"
                set i $j
            } else {
                append result $ch
                incr i
            }
        }

        return "${result}${restpart}"
    }

    ###########################################################################
    # Write the Encrypt dictionary object
    ###########################################################################
    method WriteEncryptDict {} {
        set oid [my GetOid 1]
        my StoreXref $oid
        my Pdfout "$oid 0 obj\n"
        my Pdfout "<<\n"
        my Pdfout "/Filter /Standard\n"

        if {$pdf(encVersion) == 5} {
            # AES-256 (V=5 R=6)
            binary scan $pdf(encO)     H* ohex
            binary scan $pdf(encOE)    H* oehex
            binary scan $pdf(encU)     H* uhex
            binary scan $pdf(encUE)    H* uehex
            binary scan $pdf(encPerms) H* permshex

            my Pdfout "/V 5\n"
            my Pdfout "/R 6\n"
            my Pdfout "/Length 256\n"
            my Pdfout "/P $pdf(encP)\n"
            my Pdfout "/O <$ohex>\n"
            my Pdfout "/OE <$oehex>\n"
            my Pdfout "/U <$uhex>\n"
            my Pdfout "/UE <$uehex>\n"
            my Pdfout "/Perms <$permshex>\n"
            my Pdfout "/EncryptMetadata true\n"
            my Pdfout "/CF << /StdCF << /AuthEvent /DocOpen /CFM /AESV3 /Length 32 >> >>\n"
            my Pdfout "/StmF /StdCF\n"
            my Pdfout "/StrF /StdCF\n"

        } else {
            # AES-128 (V=4 R=4)
            binary scan $pdf(encO) H* ohex
            binary scan $pdf(encU) H* uhex

            my Pdfout "/V 4\n"
            my Pdfout "/R 4\n"
            my Pdfout "/Length 128\n"
            my Pdfout "/P $pdf(encP)\n"
            my Pdfout "/O <$ohex>\n"
            my Pdfout "/U <$uhex>\n"
            my Pdfout "/EncryptMetadata true\n"
            my Pdfout "/CF << /StdCF << /AuthEvent /DocOpen /CFM /AESV2 /Length 16 >> >>\n"
            my Pdfout "/StmF /StdCF\n"
            my Pdfout "/StrF /StdCF\n"
        }

        my Pdfout ">>\n"
        my Pdfout "endobj\n\n"
        return $oid
    }

}
