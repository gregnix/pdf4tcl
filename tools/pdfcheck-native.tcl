#!/usr/bin/env tclsh
#
# pdfcheck-native.tcl -- checks that read the file itself
#
# The external tools each answer one question well and stay silent on
# everything outside their remit. These procedures fill the gaps that
# were measured, not guessed:
#
#   * veraPDF does not look at the encoding of the XMP packet.
#   * Only the PDF/A-1 profile compares /Info against the XMP; from
#     part 2 on, a contradiction goes unnoticed.
#   * No validator notices that an attachment cannot be found by name.
#   * A file that claims no conformance is "checked" by veraPDF without
#     anything being checked at all.
#
# Every procedure returns the same dict as pdfcheck.tcl:
#     status      PASS | WARN | FAIL | SKIP
#     description one line, what was checked
#     output      the detail, empty when there is nothing to say
#
# Intended to be sourced by pdfcheck.tcl, but runnable on its own:
#     tclsh pdfcheck-native.tcl datei.pdf

namespace eval ::pdfcheck::native {
    variable version 0.1
    namespace export check*
}

# ---------------------------------------------------------------------
# helpers
# ---------------------------------------------------------------------

proc ::pdfcheck::native::result {status description {output ""}} {
    return [dict create status $status description $description output $output]
}

# Read the whole file as bytes. A PDF is not text; anything that goes
# through a translating channel is already wrong before the first check.
proc ::pdfcheck::native::slurp {file} {
    set fh [open $file rb]
    set data [read $fh]
    close $fh
    return $data
}

# Find object N in the raw body and return its body text.
#
# Deliberately index-based rather than a regexp: a non-greedy pattern
# over a megabyte of binary data backtracks itself to a standstill and
# never returns. Measured -- the call did not come back within 120 s.
proc ::pdfcheck::native::objectBody {data oid} {
    set marke "\n$oid 0 obj"
    set i [string first $marke $data]
    if {$i < 0} { return "" }
    set start [expr {$i + [string length $marke]}]
    set ende [string first "endobj" $data $start]
    if {$ende < 0} { return "" }
    return [string range $data $start $ende-1]
}

# The value of a key in the trailer or in a dictionary, as an object
# number. Returns "" when the key is absent or not an indirect reference.
proc ::pdfcheck::native::refOf {data key} {
    if {[regexp "/$key\\s+(\\d+)\\s+0\\s+R" $data -> n]} { return $n }
    return ""
}

# ---------------------------------------------------------------------
# 1. the encoding of the XMP packet
# ---------------------------------------------------------------------
#
# XMP Specification Part 3, clause 1.6.1: the packet "must be encoded as
# UTF-8". veraPDF does not check it -- a packet holding raw Latin-1
# bytes passes -f 1b without a word. Measured.

proc ::pdfcheck::native::checkXmpEncoding {file} {
    set data [slurp $file]
    set i [string first "<?xpacket begin" $data]
    if {$i < 0} {
        return [result SKIP "XMP encoding (UTF-8)" "no XMP packet in the file"]
    }
    set j [string first "<?xpacket end" $data $i]
    if {$j < 0} {
        return [result FAIL "XMP encoding (UTF-8)" \
                "packet starts at $i but has no end marker"]
    }
    set paket [string range $data $i $j]

    # A byte sequence is valid UTF-8 if decoding and re-encoding it
    # yields the same bytes.
    #
    # Under Tcl 9 the decode THROWS on an invalid sequence and names the
    # offending index; under 8.6 it substitutes silently and the round
    # trip comes back different. Both cases are handled, because the
    # check has to work on either interpreter.
    if {[catch {encoding convertfrom utf-8 $paket} zeichen]} {
        set stelle ""
        if {[regexp {index (\d+)} $zeichen -> k]} {
            binary scan [string index $paket $k] cu byte
            set stelle [format ": byte 0x%02X at offset %d (%d bytes into\
                    the packet)" $byte [expr {$i + $k}] $k]
        }
        return [result FAIL "XMP encoding (UTF-8)" \
                "packet is not valid UTF-8$stelle"]
    }
    set zurueck [encoding convertto utf-8 $zeichen]
    if {$zurueck eq $paket} {
        return [result PASS "XMP encoding (UTF-8)"]
    }

    # Say where, not just that. The first byte that differs is the one
    # to look at.
    set n [string length $paket]
    for {set k 0} {$k < $n} {incr k} {
        if {[string index $paket $k] ne [string index $zurueck $k]} { break }
    }
    binary scan [string index $paket $k] cu byte
    set stelle [expr {$i + $k}]
    return [result FAIL "XMP encoding (UTF-8)" \
            [format "packet is not valid UTF-8: byte 0x%02X at offset %d\
                    (%d bytes into the packet)" $byte $stelle $k]]
}

# ---------------------------------------------------------------------
# 2. /Info against XMP
# ---------------------------------------------------------------------
#
# ISO 19005-1 clause 6.7.3 requires the two to agree. Parts 2 and 3
# dropped the rule, so "verapdf -f 2b" says PASS on a file that
# contradicts itself. Measured on the same file: -f 1b FAIL, -f 2b PASS.

proc ::pdfcheck::native::checkInfoXmp {file} {
    set data [slurp $file]
    if {[string first "<?xpacket begin" $data] < 0} {
        return [result SKIP "Info vs XMP" "no XMP packet in the file"]
    }

    # /Info values. Only unencrypted literal strings can be compared
    # here; anything else is skipped rather than guessed at.
    #
    # Go through the trailer to the /Info OBJECT rather than searching the
    # whole file. /Title is not unique in a PDF: every bookmark carries
    # one, and in a document with an outline the first hit is the first
    # bookmark, not the document title.
    #
    # Measured on doc/en/out/tutorial-06-pack-body.pdf: five /Title
    # entries, the document's own last. The check reported
    # "Info \"Cover\" vs XMP \"Reading pack\"" -- Cover being the first
    # bookmark. Both were right.
    array set info {}
    set infoBody ""
    if {[regexp -all -inline {/Info\s+(\d+)\s+\d+\s+R} $data] ne ""} {
        # The last trailer wins, as with any incremental update.
        set treffer [regexp -all -inline {/Info\s+(\d+)\s+\d+\s+R} $data]
        set infoId [lindex $treffer end]
        if {[regexp "(?:^|\n)$infoId\\s+\\d+\\s+obj(.*?)endobj" \
                $data -> infoBody]} {
            # gefunden
        }
    }
    if {$infoBody eq ""} {
        return [result SKIP "Info vs XMP" \
                "no /Info object reachable from the trailer"]
    }
    foreach schluessel {Title Author Subject Keywords} {
        if {[regexp "/$schluessel\\s*\\(((?:\[^\\\\()\]|\\\\.)*)\\)" \
                $infoBody -> wert]} {
            set info($schluessel) [unquote $wert]
        }
    }
    if {![array size info]} {
        return [result SKIP "Info vs XMP" \
                "no comparable /Info entries (encrypted or absent)"]
    }

    # The XMP counterparts. dc:title and dc:description are language
    # alternatives, dc:creator is an ordered list -- in each case the
    # FIRST entry is the one that maps to /Info
    # (XMP Specification Part 3, clause 2.2).
    array set xmp {}
    if {[regexp {<dc:title>.*?<rdf:li[^>]*>(.*?)</rdf:li>} $data -> v]} {
        set xmp(Title) $v
    }
    if {[regexp {<dc:creator>.*?<rdf:li[^>]*>(.*?)</rdf:li>} $data -> v]} {
        set xmp(Author) $v
    }
    if {[regexp {<dc:description>.*?<rdf:li[^>]*>(.*?)</rdf:li>} $data -> v]} {
        set xmp(Subject) $v
    }
    if {[regexp {<pdf:Keywords>(.*?)</pdf:Keywords>} $data -> v]} {
        set xmp(Keywords) $v
    }

    set abweichung {}
    set luecke {}
    set verglichen 0
    foreach schluessel {Title Author Subject Keywords} {
        if {![info exists info($schluessel)]} continue
        if {![info exists xmp($schluessel)]} {
            # Absent is not the same as contradictory. PDF/A-1 clause
            # 6.7.3 asks the two to AGREE where both are present; an
            # entry that exists only in /Info is a gap, not a conflict,
            # and outside PDF/A-1 not even that.
            lappend luecke "/$schluessel"
            continue
        }
        incr verglichen
        if {$info($schluessel) ne $xmp($schluessel)} {
            lappend abweichung \
                "/$schluessel: Info \"$info($schluessel)\" vs XMP \"$xmp($schluessel)\""
        }
    }

    if {[llength $abweichung]} {
        return [result FAIL "Info vs XMP" [join $abweichung "\n"]]
    }
    if {[llength $luecke]} {
        # Only PDF/A-1 requires the pair to be complete. Elsewhere this
        # is worth knowing, not worth failing over.
        set text "in /Info but not in the XMP: [join $luecke {, }]"
        if {[regexp {<pdfaid:part>\s*1\s*</pdfaid:part>} $data]} {
            return [result FAIL "Info vs XMP" \
                    "$text\nthe file claims PDF/A-1, where clause 6.7.3\
                     requires both to carry the same values"]
        }
        return [result WARN "Info vs XMP" $text]
    }
    if {!$verglichen} {
        return [result SKIP "Info vs XMP" "nothing comparable"]
    }
    return [result PASS "Info vs XMP" "$verglichen entry/entries agree"]
}

# Unpack a literal PDF string. [string trim $v "()"] is not an unpacker:
# on "(Meier & Co \(GmbH\))" it drops the closing paren and leaves a
# backslash standing.
proc ::pdfcheck::native::unquote {s} {
    set aus ""
    set n [string length $s]
    for {set i 0} {$i < $n} {incr i} {
        set c [string index $s $i]
        if {$c ne "\\"} { append aus $c ; continue }
        incr i
        set d [string index $s $i]
        switch -- $d {
            n { append aus "\n" }
            r { append aus "\r" }
            t { append aus "\t" }
            b { append aus "\b" }
            f { append aus "\f" }
            "(" - ")" - "\\" { append aus $d }
            default {
                if {[string is digit $d]} {
                    set okt $d
                    while {[string length $okt] < 3 \
                            && [string is digit [string index $s $i+1]]} {
                        incr i
                        append okt [string index $s $i]
                    }
                    append aus [format %c [scan $okt %o]]
                } else {
                    append aus $d
                }
            }
        }
    }
    return $aus
}

# ---------------------------------------------------------------------
# 3. is an attachment findable by name?
# ---------------------------------------------------------------------
#
# The name tree holds the name, the file specification holds it again in
# /F and /UF. If the two are encrypted differently -- or one of them not
# at all -- a reader looking up by name comes away empty. Measured:
# "qpdf --list-attachments" printed an empty name and the attachment was
# unreachable, while the file was otherwise sound.

proc ::pdfcheck::native::checkAttachmentNames {file} {
    set data [slurp $file]
    set n [refOf $data EmbeddedFiles]
    if {$n eq ""} {
        return [result SKIP "attachment reachable by name" \
                "no embedded files"]
    }
    set baum [objectBody $data $n]
    if {![regexp {/Names\s*\[(.*?)\]} $baum -> namen]} {
        return [result WARN "attachment reachable by name" \
                "name tree has no /Names array (nested tree?)"]
    }

    set befund {}
    set gezaehlt 0
    set rest $namen
    while {[regexp {\(((?:[^\\()]|\\.)*)\)\s+(\d+)\s+0\s+R(.*)$} \
            $rest -> name oid rest]} {
        incr gezaehlt
        set name [unquote $name]
        set spec [objectBody $data $oid]
        if {$spec eq ""} {
            lappend befund "name \"$name\" points at object $oid, which is absent"
            continue
        }
        if {![regexp {/F\s*\(((?:[^\\()]|\\.)*)\)} $spec -> f]} {
            lappend befund "\"$name\": file specification has no /F"
            continue
        }
        set f [unquote $f]
        if {$f ne $name} {
            lappend befund \
                "\"$name\" in the name tree, but /F is \"$f\" -- a reader\
                 looking up by name will not find it"
        }
    }

    if {[llength $befund]} {
        return [result FAIL "attachment reachable by name" [join $befund "\n"]]
    }
    if {!$gezaehlt} {
        return [result WARN "attachment reachable by name" \
                "name tree present but no entries parsed"]
    }
    return [result PASS "attachment reachable by name" \
            "$gezaehlt attachment(s), name and /F agree"]
}

# ---------------------------------------------------------------------
# 4. what does the file claim?
# ---------------------------------------------------------------------
#
# "verapdf datei.pdf" without -f reads the claim from the XMP. A file
# claiming nothing is then validated against nothing and reports no
# problem. Measured on a documentation directory: 44 of 64 files
# claimed nothing.

proc ::pdfcheck::native::checkClaim {file} {
    set data [slurp $file]
    set teile {}
    if {[regexp {<pdfaid:part>\s*(\d+)\s*</pdfaid:part>} $data -> p]} {
        set stufe ""
        if {[regexp {<pdfaid:conformance>\s*(\w)\s*</pdfaid:conformance>} \
                $data -> c]} {
            set stufe [string tolower $c]
        }
        if {[regexp {<pdfaid:rev>\s*(\d+)\s*</pdfaid:rev>} $data -> r]} {
            lappend teile "PDF/A-$p (rev $r)"
        } else {
            lappend teile "PDF/A-$p$stufe"
        }
    }
    if {[regexp {<pdfuaid:part>\s*(\d+)\s*</pdfuaid:part>} $data -> p]} {
        lappend teile "PDF/UA-$p"
    }

    if {![llength $teile]} {
        return [result WARN "conformance claim" \
                "the file claims nothing -- a validator run without an\
                 explicit profile checks nothing"]
    }
    return [result PASS "conformance claim" [join $teile ", "]]
}

# ---------------------------------------------------------------------
# 5. /Version in the catalog is a name
# ---------------------------------------------------------------------
#
# ISO 32000 clause 7.7.2 lists the entry as "name". pdf4tcl wrote a
# number there, in every file above version 1.4. The file stays
# readable, which is why it went unnoticed for so long; veraPDF says
# nothing, qpdf warns.

proc ::pdfcheck::native::checkCatalogVersion {file} {
    set data [slurp $file]
    set n [refOf $data Root]
    if {$n eq ""} {
        return [result SKIP "/Version is a name" "no /Root in the trailer"]
    }
    set katalog [objectBody $data $n]
    if {![regexp {/Version\s*(/?)([0-9.]+)} $katalog -> schraegstrich wert]} {
        return [result SKIP "/Version is a name" \
                "the catalog has no /Version entry"]
    }
    if {$schraegstrich eq "/"} {
        return [result PASS "/Version is a name" "/Version /$wert"]
    }
    return [result FAIL "/Version is a name" \
            "/Version $wert is a number; ISO 32000 clause 7.7.2 says name\
             -- write /Version /$wert"]
}

# ---------------------------------------------------------------------
# 6. /Length in the encryption dictionary
# ---------------------------------------------------------------------
#
# Table 20 in both ISO 32000-1 and -2: "Optional; PDF 1.4; only if V is
# 2 or 3". The /Length inside the crypt filter is a different table and
# stays.
#
# Note the direction: qpdf 12 WARNS when the entry is absent, because it
# reads it unconditionally. Here the standard decides.

proc ::pdfcheck::native::checkEncryptLength {file} {
    set data [slurp $file]
    set n [refOf $data Encrypt]
    if {$n eq ""} {
        return [result SKIP "/Length in the encryption dictionary" \
                "the file is not encrypted"]
    }
    set dict [objectBody $data $n]
    if {![regexp {/V\s+(\d+)} $dict -> v]} {
        return [result WARN "/Length in the encryption dictionary" \
                "no /V in the encryption dictionary"]
    }

    # Only look outside /CF -- the /Length in there is Table 25.
    set ohneCf $dict
    regsub {/CF\s*<<.*?>>\s*>>} $ohneCf "" ohneCf
    set hat [regexp {/Length\s+\d+} $ohneCf]

    if {$v in {2 3}} {
        if {$hat} {
            return [result PASS "/Length in the encryption dictionary" \
                    "V $v, /Length allowed"]
        }
        return [result PASS "/Length in the encryption dictionary" \
                "V $v, /Length absent (optional)"]
    }
    if {$hat} {
        return [result FAIL "/Length in the encryption dictionary" \
                "V $v carries /Length; Table 20 allows it only for V 2 or 3"]
    }
    return [result PASS "/Length in the encryption dictionary" \
            "V $v, no /Length -- correct"]
}

# ---------------------------------------------------------------------
# 7. clear text in an encrypted file
# ---------------------------------------------------------------------
#
# ISO 32000-2 clause 7.6.2 names four exceptions from encryption: the
# trailer /ID, strings in the encryption dictionary, strings inside
# already encrypted streams, and a signature's Contents. Anything else
# readable is a string that slipped past.
#
# This is a heuristic and says so: it reports what it finds and leaves
# the judgement to the reader.

proc ::pdfcheck::native::checkClearText {file} {
    set data [slurp $file]
    if {[refOf $data Encrypt] eq ""} {
        return [result SKIP "clear text in an encrypted file" \
                "the file is not encrypted"]
    }

    # Cut out what is allowed to be readable.
    set rest $data
    set n [refOf $data Encrypt]
    set dict [objectBody $data $n]
    if {$dict ne ""} { set rest [string map [list $dict ""] $rest] }
    regsub -all {/ID\s*\[[^\]]*\]} $rest "" rest
    regsub -all {stream\r?\n.*?endstream} $rest "" rest

    set gefunden {}
    set idx 0
    while {[regexp -start $idx -indices {\(((?:[^\\()]|\\.)*)\)} \
            $rest bereich inhalt]} {
        set idx [expr {[lindex $bereich 1] + 1}]
        set s [string range $rest {*}$inhalt]
        if {[string length $s] < 4 || [string length $s] > 80} continue
        # printable ASCII only -- encrypted strings are binary
        if {![regexp {^[\x20-\x7E]+$} $s]} continue
        lappend gefunden $s
    }

    if {[llength $gefunden]} {
        return [result WARN "clear text in an encrypted file" \
                "readable strings outside the four exceptions of clause\
                 7.6.2:\n  [join [lrange $gefunden 0 9] "\n  "]"]
    }
    return [result PASS "clear text in an encrypted file" \
            "no readable strings outside the exceptions"]
}

# ---------------------------------------------------------------------
# 8. how many XMP packets?
# ---------------------------------------------------------------------
#
# An incremental save appends a new packet and leaves the old one in
# place. Whoever searches for "xpacket" then finds several; the one the
# catalog points at is the one in force. Worth knowing before editing.

proc ::pdfcheck::native::checkXmpCount {file} {
    set data [slurp $file]
    set n 0
    set idx 0
    while {[set i [string first "<?xpacket begin" $data $idx]] >= 0} {
        incr n
        set idx [expr {$i + 15}]
    }
    if {$n == 0} {
        return [result SKIP "number of XMP packets" "no XMP packet"]
    }
    if {$n == 1} {
        return [result PASS "number of XMP packets" "one packet"]
    }
    return [result WARN "number of XMP packets" \
            "$n packets -- the one referenced by the catalog is in force;\
             a plain packet scanner may pick the wrong one"]
}

# ---------------------------------------------------------------------
# 9. fonts: embedded, and reachable back to Unicode
# ---------------------------------------------------------------------
#
# Two questions per font, and neither has anything to do with the
# validity of the file:
#
#   Is the font program in the file? Without it the reader substitutes,
#   and the page no longer looks the way it was written. PDF/A demands
#   it (clause 6.3.4); outside PDF/A nobody asks.
#
#   Is there a ToUnicode map? Without one the text cannot be copied,
#   searched or read aloud. PDF/A level u demands it; level b does not.
#
# pdffonts answers both, but needs poppler. This reads the font objects
# instead -- same answer, no external tool.
#
# The three standard-font families never carry a program: whoever uses
# Helvetica has decided against embedding, knowingly or not.

proc ::pdfcheck::native::checkFonts {file} {
    set data [slurp $file]

    set befund {}
    set gezaehlt 0
    set idx 0
    while {[set i [string first "/Type /Font" $data $idx]] >= 0} {
        set idx [expr {$i + 11}]
        # the object body around this /Type entry
        set anfang [string last " 0 obj" [string range $data 0 $i]]
        if {$anfang < 0} continue
        set ende [string first "endobj" $data $i]
        if {$ende < 0} continue
        set obj [string range $data $anfang $ende]

        # Type0 is the outer half of a CID font -- the descendant is
        # examined through it, so counting both would report twice.
        if {[regexp {/Subtype\s*/Type0} $obj]} {
            incr gezaehlt
            set name "?"
            regexp {/BaseFont\s*/([^\s/>\]]+)} $obj -> name
            if {![regexp {/ToUnicode\s+\d+\s+0\s+R} $obj]} {
                lappend befund "$name: no ToUnicode map -- text cannot be\
                        extracted"
            }
            # follow to the descendant and on to the descriptor
            if {[regexp {/DescendantFonts\s*\[\s*(\d+)} $obj -> dn]} {
                set nach [objectBody $data $dn]
                if {[regexp {/FontDescriptor\s+(\d+)} $nach -> fd]} {
                    set desc [objectBody $data $fd]
                    if {![regexp {/FontFile[23]?\s+\d+\s+0\s+R} $desc]} {
                        lappend befund "$name: font program not embedded"
                    }
                } else {
                    lappend befund "$name: descendant has no /FontDescriptor"
                }
            }
            continue
        }

        # A simple font: Type1, TrueType, Type3. CIDFontType2 is the
        # descendant and was already covered above.
        if {[regexp {/Subtype\s*/CIDFontType} $obj]} continue
        if {![regexp {/Subtype\s*/(Type1|TrueType|MMType1|Type3)} $obj -> st]} {
            continue
        }
        incr gezaehlt
        set name "?"
        regexp {/BaseFont\s*/([^\s/>\]]+)} $obj -> name

        if {![regexp {/ToUnicode\s+\d+\s+0\s+R} $obj]} {
            lappend befund "$name: no ToUnicode map -- text cannot be\
                    extracted"
        }
        if {$st eq "Type3"} {
            # A Type 3 font draws its glyphs from a CharProcs stream;
            # there is no font program to embed.
            continue
        }
        if {[regexp {/FontDescriptor\s+(\d+)} $obj -> fd]} {
            set desc [objectBody $data $fd]
            if {![regexp {/FontFile[23]?\s+\d+\s+0\s+R} $desc]} {
                lappend befund "$name: font program not embedded"
            }
        } else {
            # No descriptor at all is the signature of a standard font.
            lappend befund "$name: standard font, no program in the file"
        }
    }

    if {!$gezaehlt} {
        return [result SKIP "fonts embedded and mapped" "no fonts in the file"]
    }
    if {[llength $befund]} {
        # Whether this is a defect depends on what the file claims. Under
        # PDF/A an unembedded font breaks clause 6.3.4; elsewhere it is a
        # decision, and the reader should be told rather than overruled.
        set stufe WARN
        set zusatz ""
        if {[regexp {<pdfaid:part>} $data]} {
            set stufe FAIL
            set zusatz "\nthe file claims PDF/A, where clause 6.3.4 requires\
                    every font program to be embedded"
        }
        return [result $stufe "fonts embedded and mapped" \
                "[join $befund "\n"]$zusatz"]
    }
    return [result PASS "fonts embedded and mapped" \
            "$gezaehlt font(s), all embedded and mapped"]
}

# ---------------------------------------------------------------------
# runner
# ---------------------------------------------------------------------

proc ::pdfcheck::native::runAll {file} {
    return [dict create \
        claim         [checkClaim $file] \
        xmpEncoding   [checkXmpEncoding $file] \
        xmpCount      [checkXmpCount $file] \
        infoXmp       [checkInfoXmp $file] \
        attachments   [checkAttachmentNames $file] \
        catalogVer    [checkCatalogVersion $file] \
        encryptLength [checkEncryptLength $file] \
        clearText     [checkClearText $file] \
        fonts         [checkFonts $file]]
}

# One file, several files, or a directory. Reports a summary line at
# the end when more than one file was looked at, so a run over a whole
# directory says something without scrolling back.
proc ::pdfcheck::native::runFile {file {einzeln 1}} {
    if {$einzeln} {
        puts ""
        puts "Native checks: [file tail $file]"
        puts [string repeat = 70]
    } else {
        puts ""
        puts "== [file tail $file]"
    }
    set schlimm PASS
    dict for {name r} [runAll $file] {
        set s [dict get $r status]
        # A single file gets every line; a batch run only what needs
        # attention -- otherwise a directory of forty files scrolls the
        # findings off the screen.
        if {$einzeln || $s ni {PASS SKIP}} {
            puts [format "%-14s %-5s %s" $name $s [dict get $r description]]
            set aus [dict get $r output]
            if {$aus ne "" && $s ni {PASS SKIP}} {
                foreach z [split $aus "\n"] { puts "                     $z" }
            }
        }
        if {$s eq "FAIL" || ($s eq "WARN" && $schlimm eq "PASS")} {
            set schlimm $s
        }
    }
    if {$einzeln} {
        puts [string repeat - 70]
        puts [format "%-14s %s" OVERALL $schlimm]
        puts ""
    } elseif {$schlimm eq "PASS"} {
        puts "   nothing to report"
    }
    return $schlimm
}

# Expand what was given: files stay, directories contribute their PDFs.
proc ::pdfcheck::native::gatherFiles {argv} {
    set dateien {}
    foreach a $argv {
        if {[file isdirectory $a]} {
            lappend dateien {*}[lsort [glob -nocomplain -directory $a *.pdf]]
        } elseif {[file readable $a]} {
            lappend dateien $a
        } else {
            puts stderr "cannot read \"$a\" -- skipped"
        }
    }
    return $dateien
}

proc ::pdfcheck::native::usage {{kanal stdout}} {
    set n [file tail $::argv0]
    puts $kanal "pdfcheck-native $::pdfcheck::native::version -- checks that\
            read the PDF itself"
    puts $kanal ""
    puts $kanal "usage: $n \[options\] file.pdf ... | directory ..."
    puts $kanal ""
    puts $kanal "  -h, --help      this text"
    puts $kanal "  -v, --version   version and exit"
    puts $kanal ""
    puts $kanal "A directory contributes its *.pdf files. With one file every"
    puts $kanal "check is listed; with several, only what needs attention."
    puts $kanal "Exit status is 1 when any file fails, 0 otherwise."
    puts $kanal ""
    puts $kanal "What is checked, and why no other tool does it:"
    puts $kanal ""
    puts $kanal "  claim          does the file claim a conformance at all?"
    puts $kanal "                 A validator run without an explicit profile"
    puts $kanal "                 checks nothing when it does not."
    puts $kanal "  xmpEncoding    is the XMP packet valid UTF-8?"
    puts $kanal "                 veraPDF does not look at this."
    puts $kanal "  xmpCount       one packet, or several from incremental saves?"
    puts $kanal "  infoXmp        do /Info and the XMP agree?"
    puts $kanal "                 Only the PDF/A-1 profile compares them."
    puts $kanal "  attachments    is an attachment findable by its name?"
    puts $kanal "  catalogVer     is /Version a name, as ISO 32000 7.7.2 says?"
    puts $kanal "  encryptLength  /Length only for V 2 or 3 (Table 20)."
    puts $kanal "  fonts          font programs embedded, ToUnicode present?"
    puts $kanal "                 pdffonts answers this too, but needs poppler."
    puts $kanal "  clearText      strings that escaped encryption"
    puts $kanal "                 (ISO 32000-2 clause 7.6.2 lists four"
    puts $kanal "                 exceptions; anything else readable is one)."
    puts $kanal ""
}

if {[info exists argv0] && [file tail [info script]] eq [file tail $argv0]} {
    if {![llength $argv]} {
        ::pdfcheck::native::usage stderr
        exit 2
    }
    # Options first, so that --help works before anything is read.
    set rest {}
    foreach a $argv {
        switch -exact -- $a {
            -h - --help - help {
                ::pdfcheck::native::usage
                exit 0
            }
            -v - --version {
                puts "pdfcheck-native $::pdfcheck::native::version"
                exit 0
            }
            default {
                if {[string match "-*" $a]} {
                    puts stderr "unknown option \"$a\" -- try --help"
                    exit 2
                }
                lappend rest $a
            }
        }
    }
    set dateien [::pdfcheck::native::gatherFiles $rest]
    if {![llength $dateien]} {
        puts stderr "no PDF files found"
        exit 2
    }

    set einzeln [expr {[llength $dateien] == 1}]
    array set zaehler {PASS 0 WARN 0 FAIL 0}
    foreach d $dateien {
        incr zaehler([::pdfcheck::native::runFile $d $einzeln])
    }

    if {!$einzeln} {
        puts ""
        puts [string repeat = 70]
        puts [format "%d file(s): %d PASS, %d WARN, %d FAIL" \
                [llength $dateien] $zaehler(PASS) $zaehler(WARN) $zaehler(FAIL)]
        puts ""
    }
    exit [expr {$zaehler(FAIL) > 0 ? 1 : 0}]
}
