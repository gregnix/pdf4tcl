###############################################################################
# pdf4tcl - AES-128 encryption support
# Standard Security Handler, V=4 R=4 (PDF 1.5+, ISO 32000-1:2008 §7.6)
#
# Algorithms implemented:
#   Alg 1  - Encrypt data per object  (§7.6.2)
#   Alg 2  - Derive encryption key    (§7.6.3.3)
#   Alg 3  - Compute O entry          (§7.6.3.4)
#   Alg 5  - Compute U entry (R≥3)    (§7.6.3.4)
###############################################################################

oo::define ::pdf4tcl::pdf4tcl {

    ###########################################################################
    # PDF password padding string (ISO 32000 §7.6.3.3 step a)
    ###########################################################################
    method _EncPadStr {} {
        # NOTE: PDF spec §7.6.3.3 byte 31 = 0x72, but qpdf/pikepdf use 0x7a
        # (de-facto standard) – use 0x7a for interoperability.
        return [binary format H64 \
            28BF4E5E4E758A4164004E56FFFA01082E2E00B6D0683E802F0CA9FE6453697A]
    }

    ###########################################################################
    # RC4 stream cipher (pure Tcl)
    # Used only for O/U entry computation (not for content encryption).
    # key  : binary string (n bytes)
    # data : binary string to encrypt/decrypt
    # Returns encrypted/decrypted binary string.
    ###########################################################################
    method _RC4 {key data} {
        set klen [string length $key]
        set dlen [string length $data]

        # KSA
        for {set i 0} {$i < 256} {incr i} {
            lappend S $i
        }
        set j 0
        for {set i 0} {$i < 256} {incr i} {
            set ki [scan [string index $key [expr {$i % $klen}]] %c]
            set j  [expr {($j + [lindex $S $i] + $ki) & 0xFF}]
            set tmp [lindex $S $i]
            lset S $i [lindex $S $j]
            lset S $j $tmp
        }

        # PRGA
        set i 0 ; set j 0
        set out {}
        for {set n 0} {$n < $dlen} {incr n} {
            set i [expr {($i + 1) & 0xFF}]
            set j [expr {($j + [lindex $S $i]) & 0xFF}]
            set tmp [lindex $S $i]
            lset S $i [lindex $S $j]
            lset S $j $tmp
            set ks [lindex $S [expr {([lindex $S $i] + [lindex $S $j]) & 0xFF}]]
            set db [scan [string index $data $n] %c]
            append out [format %c [expr {$db ^ $ks}]]
        }
        return $out
    }

    ###########################################################################
    # Algorithm 2: Compute the encryption key
    # password : user password (binary or plain string, max 32 bytes used)
    # O        : computed O entry (32 bytes) -- pass "" if not yet available
    # P        : permissions integer
    # fileId   : first element of /ID array (binary, 16 bytes)
    # Returns 16-byte AES-128 key (binary).
    ###########################################################################
    method _EncKey {password O P fileId} {
        set padstr [my _EncPadStr]

        # Step a: pad/truncate password to 32 bytes
        set pwd [string range ${password}${padstr} 0 31]

        # Steps b-g: MD5 accumulation
        package require md5
        set ctx [md5::MD5Init]
        md5::MD5Update $ctx $pwd
        md5::MD5Update $ctx $O
        # P as 4-byte little-endian signed integer
        md5::MD5Update $ctx [binary format i $P]
        md5::MD5Update $ctx $fileId
        # Step f: R=4, EncryptMetadata=true → skip the 0xFFFFFFFF padding
        set hash [md5::MD5Final $ctx]

        # Step h: 50 iterations (R=4 ≥ 3)
        for {set i 0} {$i < 50} {incr i} {
            set hash [md5::md5 [string range $hash 0 15]]
        }

        # Step i: first 16 bytes (128-bit key)
        return [string range $hash 0 15]
    }

    ###########################################################################
    # Algorithm 3: Compute the O (owner password) entry
    # ownerPwd : owner password string  (use userPwd if empty)
    # userPwd  : user  password string
    # Returns 32-byte binary O entry.
    ###########################################################################
    method _EncComputeO {ownerPwd userPwd} {
        set padstr [my _EncPadStr]
        package require md5

        # Step a: pad/truncate owner password (or user if none)
        set opwd [expr {$ownerPwd eq {} ? $userPwd : $ownerPwd}]
        set opwd [string range ${opwd}${padstr} 0 31]

        # Steps b-c: MD5 + 50 iterations
        set hash [md5::md5 $opwd]
        for {set i 0} {$i < 50} {incr i} {
            set hash [md5::md5 $hash]
        }

        # Step d: RC4 key = first 16 bytes
        set rc4key [string range $hash 0 15]

        # Step e: pad/truncate user password
        set upwd [string range ${userPwd}${padstr} 0 31]

        # Step f: RC4 encrypt with rc4key
        set out [my _RC4 $rc4key $upwd]

        # Step g: 19 more iterations with XOR'd keys
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

    ###########################################################################
    # Algorithm 5: Compute the U (user password) entry (R=4)
    # encKey   : 16-byte encryption key from _EncKey
    # fileId   : first /ID element (binary, 16 bytes)
    # Returns 32-byte binary U entry.
    ###########################################################################
    method _EncComputeU {encKey fileId} {
        binary scan $fileId H* fileIdHex
        set padstr [my _EncPadStr]
        package require md5

        # Step b: MD5(padstr || fileId)
        set ctx [md5::MD5Init]
        md5::MD5Update $ctx $padstr
        md5::MD5Update $ctx $fileId
        set hash [md5::MD5Final $ctx]

        # Step d: RC4 encrypt 16-byte hash with encKey
        set out [my _RC4 $encKey $hash]

        # Step e: 19 more RC4 iterations with XOR'd keys
        for {set i 1} {$i <= 19} {incr i} {
            set xkey ""
            for {set b 0} {$b < 16} {incr b} {
                append xkey [format %c \
                    [expr {[scan [string index $encKey $b] %c] ^ $i}]]
            }
            set out [my _RC4 $xkey $out]
        }

        # Step f: append 16 bytes of arbitrary padding
        append out [string repeat "\x00" 16]
        return $out
    }

    ###########################################################################
    # Algorithm 1 (AES variant): Per-object encryption key
    # oid : object number (integer)
    # Returns 16-byte binary key.
    ###########################################################################
    method _ObjKey {oid} {
        package require md5
        # Extend enc key with low-order 3 bytes of oid + 2 bytes of gen (=0)
        # Plus 4-byte AES salt "sAlT"
        set inp ""
        append inp $pdf(encKey)
        append inp [binary format ccc \
            [expr {$oid & 0xFF}] \
            [expr {($oid >> 8) & 0xFF}] \
            [expr {($oid >> 16) & 0xFF}]]
        append inp "\x00\x00"
        append inp "sAlT"
        set hash [md5::md5 $inp]
        return [string range $hash 0 15]
    }

    ###########################################################################
    # Encrypt binary data for a given object using AES-128-CBC.
    # Prepends 16-byte random IV per spec.
    # PKCS5 padding is applied (spec §7.6.2).
    # oid  : object number
    # data : plaintext binary string
    # Returns ciphertext (IV + encrypted data).
    ###########################################################################
    method EncryptBytes {oid data} {
        package require aes
        set key [my _ObjKey $oid]

        # PKCS5 padding: pad = 16 - (len mod 16), min 1
        set dlen [string length $data]
        set padlen [expr {16 - ($dlen % 16)}]
        append data [string repeat [format %c $padlen] $padlen]

        # Random 16-byte IV
        set iv [my _EncRandBytes 16]

        set ct [aes::aes -mode cbc -dir encrypt -key $key -iv $iv $data]
        return ${iv}${ct}
    }

    ###########################################################################
    # Generate n cryptographically random bytes.
    # Falls back to expr-based PRNG if /dev/urandom is unavailable.
    ###########################################################################
    method _EncRandBytes {n} {
        if {[catch {
            set fh [open /dev/urandom rb]
            set bytes [read $fh $n]
            close $fh
        }]} {
            # Fallback: clock + rand (not cryptographic, acceptable for IV)
            set bytes ""
            for {set i 0} {$i < $n} {incr i} {
                append bytes [format %c [expr {int(rand()*256)}]]
            }
        }
        return $bytes
    }

    ###########################################################################
    # Initialize encryption state.
    # Called from InitPdf when -userpassword or -ownerpassword is set.
    ###########################################################################
    method InitEncrypt {} {
        if {!$pdf(encrypt)} { return }

        # Random 16-byte file ID (used in key derivation + trailer /ID)
        set pdf(encFileId) [my _EncRandBytes 16]
        binary scan $pdf(encFileId) H* encFileIdHex

        # Compute O entry (Algorithm 3)
        set pdf(encO) [my _EncComputeO \
            $options(-ownerpassword) \
            $options(-userpassword)]

        # Compute encryption key (Algorithm 2)
        set pdf(encKey) [my _EncKey \
            $options(-userpassword) \
            $pdf(encO) \
            $pdf(encP) \
            $pdf(encFileId)]

        # Compute U entry (Algorithm 5)
        binary scan $pdf(encFileId) H* fileIdHexBeforeU
        set pdf(encU) [my _EncComputeU $pdf(encKey) $pdf(encFileId)]
        binary scan $pdf(encU) H* uHex
    }

    ###########################################################################
    # Scan an object body (as built by AddObject / FlushObjects) for an
    # embedded stream and encrypt its content.  The /Length value is updated.
    # oid  : object number
    # body : full object body string  (between "N 0 obj\n" ... "endobj")
    # Returns modified body, or original body if no stream found.
    ###########################################################################
    method EncryptStreamBody {oid body} {
        # Locate stream delimiters
        set sstart [string first "stream\n" $body]
        if {$sstart < 0} { return $body }
        incr sstart 7  ;# skip "stream\n"

        set send [string first "\nendstream" $body $sstart]
        if {$send < 0} { return $body }

        set plaintext [string range $body $sstart ${send}-1]
        set ciphertext [my EncryptBytes $oid $plaintext]
        set newlen [string length $ciphertext]

        # Replace stream content
        set newbody [string replace $body $sstart ${send}-1 $ciphertext]

        # Update /Length value in stream dictionary
        # Pattern: /Length <integer>  (not an indirect ref like /Length N 0 R)
        regsub {/Length\s+[0-9]+\M} $newbody "/Length $newlen" newbody

        return $newbody
    }

    ###########################################################################
    # Write the Encrypt dictionary object and return its OID.
    # Caller must invoke StoreXref before Pdfout.
    ###########################################################################
    method WriteEncryptDict {} {
        binary scan $pdf(encO) H* ohex
        binary scan $pdf(encU) H* uhex

        set oid [my GetOid 1]
        my StoreXref $oid
        my Pdfout "$oid 0 obj\n"
        my Pdfout "<<\n"
        my Pdfout "/Filter /Standard\n"
        my Pdfout "/V 4\n"
        my Pdfout "/R 4\n"
        my Pdfout "/Length 128\n"
        my Pdfout "/P $pdf(encP)\n"
        my Pdfout "/O <$ohex>\n"
        my Pdfout "/U <$uhex>\n"
        my Pdfout "/EncryptMetadata true\n"
        # Crypt filter: AES-128 for streams and strings
        my Pdfout "/CF << /StdCF << /AuthEvent /DocOpen /CFM /AESV2 /Length 16 >> >>\n"
        my Pdfout "/StmF /StdCF\n"
        my Pdfout "/StrF /StdCF\n"
        my Pdfout ">>\n"
        my Pdfout "endobj\n\n"
        return $oid
    }

}
