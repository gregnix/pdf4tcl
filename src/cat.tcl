#######################################################################
# Implementation of pdf4tcl::catPdf resides below
#######################################################################

# Put all helpers in a namespace
namespace eval pdf4tcl::cat {}

# Parse a PDF dictionary in <<>> and put its elements and values in a tcl dict
proc pdf4tcl::cat::PdfDictToTclDict {dict} {
    # Remove surrounding <<>>
    regexp {^\s*<<\s*(.*?)\s*>>\s*$} $dict -> values
    if {![info exists values]} {
        #puts DICT??
        return {}
    }
    # Parser
    set state none
    set key ""
    set value ""
    set result {}
    set i 0
    set len [string length $values]
    set bracketDepth 0
    set firstVal 1
    while {$i < $len} {
        set c [string index $values $i]
        switch $state {
            none {
                if {$c eq "/"} {
                    set key $c
                    set state name
                    incr i
                }
            }
            name {
                if {[string is alnum $c]} {
                    append key $c
                    incr i
                } elseif {[string is space $c]} {
                    set state space
                    incr i
                } else {
                    # Do not consume the first value char here
                    set value ""
                    set state val
                    set firstVal 1
                }
            }
            space {
                if {[string is space $c]} {
                    incr i
                } else {
                    # Do not consume the first value char here
                    set value ""
                    set state val
                    set firstVal 1
                }
            }
            valbr {
                append value $c
                incr i
                if {$c eq "\]"} {
                    incr bracketDepth -1
                    if {$bracketDepth <= 0} {
                        set state val
                    }
                } elseif {$c eq "\["} {
                    incr bracketDepth
                }
            }
            val {
                if {$c eq "\["} {
                    append value $c
                    incr i
                    set bracketDepth 1
                    set state valbr
                } elseif {$c eq "/" && !$firstVal} {
                    # Start of a new key, unless it is first in the value
                    dict set result $key [string trim $value]
                    set key $c
                    set value ""
                    set state name
                    incr i
                } elseif {0} {
                    # TODO: take care of << [ ( etc.
                } else {
                    append value $c
                    incr i
                }
                set firstVal 0
            }
        }
    }
    if {$key ne ""} {
        dict set result $key $value
    }
    return $result
}

# Parse a PDF object's dictionary and put its elements and values in a
# tcl dict
proc pdf4tcl::cat::PdfObjToTclDict {obj {streamName {}}} {
    # Optional out parameter
    if {$streamName ne ""} {
        upvar 1 $streamName stream
    }
    #set apa $dict
    # Remove surrounding obj
    regexp {^\s*\d+\s+0\s+obj\s*(.*)$} $obj -> obj
    set obj [string trim $obj]
    # Remove endobj
    set dict [string range $obj 0 end-6]
    # Stream after dict:
    set stream ""
    if {[regexp -indices {>>\s*\nstream\s*\n} $dict ixs]} {
        lassign $ixs sIndex eIndex
        incr sIndex
        incr eIndex
        set stream [string range $dict $eIndex end]
        set dict [string range $dict 0 $sIndex]
    }
    if {[regexp -indices {endstream\s*$} $stream ixs]} {
        lassign $ixs sIndex eIndex
        incr sIndex -1
        set stream [string range $stream 0 $sIndex]
    }
    # TODO, only stream handled?
    # TODO: remove any stream?
    return [PdfDictToTclDict $dict]
}

# Make a tcl dict into a PDF dictionary in <<>>
proc pdf4tcl::cat::TclDictToPdfDict {dict} {
    set res "<<"
    foreach {key val} $dict {
        append res $key " " $val \n
    }
    append res ">>"
    return $res
}

# Read a PDF and organise its data into a dict with the following elements
# N : Number of objects + 1  (i.e. they go from 1 to N-1)
# trailer: trailer dictionary defining e.g. Root object
# root: Dictionary from root object
# rootid : Object number of root object
# info: Dictionary from info object, if any
# infoid : Object number of info object, if any
# <n> : Object <n> from "n 0 obj" through "endobj". A dict with keys:
#       full: entire object
#       dict: main dictionary, if any, converted to tcl dict
#       stream: any stream
# Read a cross-reference STREAM (PDF 1.5+, ISO 32000-1 clause 7.5.8).
#
# Such a file has no "trailer" keyword: the dictionary that would follow it
# sits in the stream object itself, and the table is packed into the stream
# data. PDF/A-1 forbids this form and PDF/A-2 and -3 require it, so every
# archival document from 2b upwards arrives here.
#
# Returns a two-element list: the trailer dictionary, and a dict mapping
# object number to byte offset -- the same shape the table branch produces,
# so the caller does not care which form the file used.
#
# Objects of type 2 live inside an object stream. Those are not resolved
# here; the caller is told so rather than silently losing them.
proc pdf4tcl::cat::ReadXrefStream {data startxref file} {
    set objStart [string first "obj" $data $startxref]
    if {$objStart < 0} {
        throw {PDF4TCL} "catPdf: xref stream in \"$file\" has no object header"
    }
    set sp [string first "stream" $data $objStart]
    if {$sp < 0} {
        throw {PDF4TCL} "catPdf: xref stream in \"$file\" has no stream data"
    }
    set hdr [string range $data $objStart [expr {$sp - 1}]]

    if {![regexp {/W\s*\[([^\]]*)\]} $hdr -> wSpec]} {
        throw {PDF4TCL} "catPdf: xref stream in \"$file\" has no /W"
    }
    set widths [regexp -all -inline {\d+} $wSpec]
    if {[llength $widths] < 3} {
        throw {PDF4TCL} "catPdf: /W in \"$file\" needs three fields,\
                got \"$wSpec\""
    }

    # Only Flate is handled. A filter this reader does not know would be
    # decoded into nonsense, so say it instead.
    if {[regexp {/Filter\s*/(\w+)} $hdr -> filter]} {
        if {$filter ne "FlateDecode"} {
            throw {PDF4TCL} "catPdf: xref stream in \"$file\" uses\
                    /$filter, only /FlateDecode is supported"
        }
    } else {
        set filter ""
    }

    if {![regexp {/Length\s+(\d+)} $hdr -> len]} {
        throw {PDF4TCL} "catPdf: xref stream in \"$file\" has no /Length"
    }

    # Exactly ONE line ending follows "stream" (clause 7.3.8.1). Skipping
    # every \r and \n in a loop would eat the first data byte.
    set b [expr {$sp + 6}]
    if {[string index $data $b] eq "\r"} { incr b }
    if {[string index $data $b] eq "\n"} { incr b }
    set raw [string range $data $b [expr {$b + $len - 1}]]

    if {$filter eq "FlateDecode"} {
        # decompress, NOT inflate: the stream carries a zlib header, and
        # inflate expects raw deflate and reports "data error".
        if {[catch {zlib decompress $raw} plain]} {
            throw {PDF4TCL} "catPdf: cannot decompress the xref stream in\
                    \"$file\": $plain"
        }
    } else {
        set plain $raw
    }

    lassign $widths w1 w2 w3
    set rowLen [expr {$w1 + $w2 + $w3}]
    if {$rowLen == 0} {
        throw {PDF4TCL} "catPdf: /W in \"$file\" is all zero"
    }
    binary scan $plain cu* bytes
    set nRows [expr {[llength $bytes] / $rowLen}]

    # /Index says which object numbers the rows describe; without it the
    # table starts at 0 and runs to /Size.
    if {[regexp {/Index\s*\[([^\]]*)\]} $hdr -> idxSpec]} {
        set index [regexp -all -inline {\d+} $idxSpec]
    } else {
        if {![regexp {/Size\s+(\d+)} $hdr -> size]} { set size $nRows }
        set index [list 0 $size]
    }

    set xrefs {}
    set inObjStm 0
    set row 0
    foreach {first count} $index {
        for {set k 0} {$k < $count && $row < $nRows} {incr k; incr row} {
            set off [expr {$row * $rowLen}]
            # A zero-width first field means type 1 by default.
            if {$w1 == 0} {
                set type 1
            } else {
                set type 0
                for {set i 0} {$i < $w1} {incr i} {
                    set type [expr {$type * 256 + [lindex $bytes [expr {$off + $i}]]}]
                }
            }
            set f2 0
            for {set i 0} {$i < $w2} {incr i} {
                set f2 [expr {$f2 * 256 + [lindex $bytes [expr {$off + $w1 + $i}]]}]
            }
            set objNo [expr {$first + $k}]
            switch -- $type {
                1 { dict set xrefs $objNo $f2 }
                2 { incr inObjStm }
                default { }
            }
        }
    }

    if {$inObjStm} {
        throw {PDF4TCL} "catPdf: \"$file\" keeps $inObjStm object(s) inside\
                object streams (/ObjStm), which this reader does not unpack"
    }

    # The stream dictionary IS the trailer here.
    set dictTxt ""
    if {[regexp {<<(.*)>>} $hdr -> inner]} { set dictTxt "<<$inner>>" }
    return [list [PdfDictToTclDict $dictTxt] $xrefs]
}

proc pdf4tcl::cat::ReadPdf {file} {
    set ch [open $file rb]
    set data [read $ch]
    close $ch

    # Remember the header version. WritePdf used to hardcode 1.4, which
    # silently downgraded the header of anything newer -- pdf4tcl writes 1.7
    # as soon as a document needs it.
    if {[regexp {^%PDF-(\d+\.\d+)} $data -> hdrVersion]} {
        set pdfVersion $hdrVersion
    } else {
        set pdfVersion 1.4
    }

    # Locate all incremental xref tables
    set allXref {}
    set xrefIndices {}
    # Tabellen aus xref-Streams, in Lesereihenfolge. Bleibt leer, wenn die
    # Datei die klassische Form benutzt.
    set streamTables {}
    # Locate last xref table
    if {![regexp {startxref\s+(\d+)\s+%%EOF\s*$} $data -> startxref]} {
        throw {PDF4TCL} "catPdf: no startxref at the end of \"$file\" --\
                the file is damaged or not a PDF"
    }
    while 1 {
        set endpart [string range $data $startxref end]
        lappend xrefIndices $startxref
        # Extract trailer
        #
        # A file may carry a cross-reference STREAM instead of a table
        # (PDF 1.5+). Then there is no "trailer" keyword at all, and the
        # entries sit compressed in an object of /Type /XRef.
        #
        # This reader does not handle that, and it used to fail with
        #   can't read "trailertxt": no such variable
        # which names a Tcl variable instead of the cause. It matters
        # more than it looks: PDF/A-1 FORBIDS xref streams, PDF/A-2 and
        # -3 REQUIRE them -- so every archival document from 2b upwards,
        # and every ZUGFeRD invoice, lands here.
        if {![regexp {(?:trailer\s+(.*?)\s+startxref){1,1}?} $endpart -> trailertxt]} {
            if {[regexp {/Type\s*/XRef} $endpart]} {
                # Cross-reference stream: the dictionary that a table
                # would put after "trailer" sits in the stream object
                # itself, and the entries are packed into its data.
                lassign [ReadXrefStream $data $startxref $file] \
                        trailer streamXrefs
                lappend streamTables $streamXrefs
                lappend allXref "" $trailer
                if {[dict exists $trailer /Prev]} {
                    set startxref [dict get $trailer /Prev]
                    continue
                }
                break
            }
            throw {PDF4TCL} "catPdf: no trailer found in \"$file\""
        }
        set trailer [PdfDictToTclDict $trailertxt]
        # Store
        lappend allXref $endpart $trailer
        # Fetch previous if there is one
        if {[dict exists $trailer /Prev]} {
            set startxref [dict get $trailer /Prev]
            #puts "New startxref $startxref"
        } else {
            break
        }
    }
    set xrefIndices [lsort -integer $xrefIndices]
    #puts "[llength $allXref]"

    # Go through xref tables from front
    set allTrailer {}
    set xrefs {}
    set unusedIndices {}
    foreach {trailer endpart} [lreverse $allXref] {
        # Merge the trailer dictionaries
        set allTrailer [dict merge $allTrailer $trailer]
        # Extract xrefs
        set obj 0
        foreach line [split $endpart \n] {
            if {[string match *trailer* $line]} break
            if {[regexp {(\d+) (\d+)\s*$}  $line -> objNo nObjs]} {
                #puts "OBJS $objNo $nObjs"
                set obj $objNo
                continue
            }
            if {[regexp {(\d+) (\d+) (n|f)} $line -> index _rev flag]} {
                # If we overwrite a reference, keep the index for later
                if {[dict exists $xrefs $obj]} {
                    lappend unusedIndices [dict get $xrefs $obj]
                }
                if {$flag eq "n"} {
                    dict set xrefs $obj [string trimleft $index 0]
                } elseif {$flag eq "f"} {
                    # TBD handle deleted objs?
                    dict set xrefs $obj -1
                }
                incr obj
            }
        }
    }
    # Eintraege aus xref-Streams dazu. Von hinten nach vorn, damit ein
    # neuerer Abschnitt einen aelteren ueberschreibt -- dieselbe Regel wie
    # bei den Tabellen.
    foreach tbl [lreverse $streamTables] {
        dict for {objNo offset} $tbl {
            dict set xrefs $objNo $offset
        }
    }

    # Extract unused into dummy object numbers
    set obj -1
    foreach index $unusedIndices {
        dict set xrefs $obj $index
        incr obj -1
    }

    # Do not keep any Prev in final trailer
    set trailer $allTrailer
    dict unset trailer /Prev
    #puts $trailer

    # Highest object number
    set obj [lindex [lsort -stride 2 -integer -decreasing -index 0 $xrefs] 0]
    ##nagelfar ignore Found constant
    dict set pdfdata version $pdfVersion
    dict set pdfdata N [expr {$obj + 1}]
    dict set pdfdata "trailer" $trailer
    # Cut out objects, from the end
    set xrefs [lsort -stride 2 -integer -decreasing -index 1 $xrefs]
    #puts $xrefs
    foreach {obj index} $xrefs {
        # Negative index is a deleted object
        if {$index < 0} continue
        # See if there is an xref after this object
        set xxx [lsearch -integer -bisect $xrefIndices $index]
        set nextIx [lindex $xrefIndices [expr {$xxx + 1}]]
        if {$nextIx eq ""} {
            # Kein weiterer Abschnitt dahinter -- das Objekt reicht bis
            # ans Ende. Tritt bei xref-Streams auf, wo die Liste nur
            # einen Eintrag hat; vorher endete es in
            # "cannot use non-numeric string as left operand of -".
            set xrefIx end
        } else {
            set xrefIx [expr {$nextIx - 1}]
        }
        # Limit object extaction to xref
        set fullObj [string trim [string range $data $index $xrefIx]]
        set data [string range $data 0 [expr {$index - 1}]]
        if {$obj >= 0} {
            # TBD limit length properly on the full string
            if {![string match *endobj $fullObj]} {
                # This should not happen if the xref limit above works
                #puts "XXXX $obj [regexp -all -inline {endobj} $fullObj]"
            }
            dict set pdfdata $obj full $fullObj
        }
    }
    # Get root object
    set rval [dict get $trailer /Root]
    set rootid [lindex $rval 0]
    dict set pdfdata "rootid" $rootid
    dict set pdfdata root [PdfObjToTclDict [dict get $pdfdata $rootid full]]
    # Any info object?
    if {[dict exists $trailer /Info]} {
        set rval [dict get $trailer /Info]
        set infoid [lindex $rval 0]
        dict set pdfdata "infoid" $infoid
        dict set pdfdata info [PdfObjToTclDict [dict get $pdfdata $infoid full]]
    }

    return $pdfdata
}

# Development aid, not part of the interface.
#
# Prints the object dictionary of a document being merged. Referenced only
# from commented-out calls in AppendPdf, kept because they are the quickest
# way to see what a merge is working on. Writes to stdout, so nothing that
# runs unattended should call it.
proc pdf4tcl::cat::Dump {pdfdata} {
    array set d $pdfdata
    parray d {[a-zA-Z]*}
    # lowest id
    set ix [lindex [lsort -dictionary [dict keys $pdfdata]] 0]
    puts "Lowest id: $ix"
    parray d $ix
    parray d 6
    parray d 285
}

# Write to an output stream, keep track of number of chars
proc pdf4tcl::cat::WriteCh {ch str cntName} {
    upvar 1 $cntName cnt
    incr cnt [string length $str]
    puts -nonewline $ch $str
}

# Given a dictionary like the one from ReadPdf, create a PDF
proc pdf4tcl::cat::WritePdf {filename pdfd} {
    set ch [open $filename wb]
    set pos 0
    set xref {}
    # Header version: the highest of the inputs, not a fixed 1.4. AppendPdf
    # keeps the first document's value and raises it in MergeVersion.
    set version 1.4
    ##nagelfar ignore #2 Found constant
    if {[dict exists $pdfd version]} {
        set version [dict get $pdfd version]
    }
    WriteCh $ch "%PDF-$version\n" pos
    # The binary comment needs at least FOUR bytes above 127. This wrote
    # three, which is enough for a reader but not for PDF/A: ISO 19005-3
    # clause 6.1.2 requires four, and veraPDF fails the file over it --
    # measured, the only rule a merged PDF/A-3a document failed.
    WriteCh $ch "%\xE5\xE4\xF6\xE7\n" pos
    foreach obj [lreverse [dict keys $pdfd]] {
        if {![string is digit -strict $obj]} continue
        dict set xref $obj $pos
        # TODO: do not take the full if parts exist
        WriteCh $ch [dict get $pdfd $obj full]\n pos
    }
    set xref_pos $pos
    set N [dict get $pdfd N]
    WriteCh $ch "xref\n" pos
    WriteCh $ch "0 $N\n" pos
    WriteCh $ch "0000000000 65535 f \n" pos
    for {set a 1} {$a < $N} {incr a} {
        # TBD handle missing objects?
        WriteCh $ch [format "%010ld 00000 n \n" [dict get $xref $a]] pos
    }
    WriteCh $ch "trailer\n" pos
    WriteCh $ch [TclDictToPdfDict [dict get $pdfd trailer]]\n pos
    WriteCh $ch "startxref\n" pos
    WriteCh $ch "$xref_pos\n" pos
    WriteCh $ch "%%EOF\n" pos

    close $ch
}

# renumber any " N 0 R" reference found
# TODO: detect stream in an object??
proc pdf4tcl::cat::RenumberRef {val delta {refmapping {}}} {
    set rest $val
    set result ""
    while {$rest ne ""} {
        # Locate first reference
        if {[regexp -indices {^\d+ 0 R} $rest ixs]} {
            lassign $ixs is ie
            incr is -1
        } elseif {[regexp -indices {\W\d+ 0 R} $rest ixs]} {
            lassign $ixs is ie
        } else {
            append result $rest
            break
        }

        append result [string range $rest 0 $is]
        incr is
        set ref [string range $rest $is $ie]
        incr ie
        set rest [string range $rest $ie end]

        set ref [lindex $ref 0]
        set new [expr {$ref + $delta}]
        if {[dict exists $refmapping $ref]} {
            set new [dict get $refmapping $ref]
        }
        append result "$new 0 R"
    }
    return $result
}

# renumber Tcl dict version of a dict
proc pdf4tcl::cat::RenumberDict {d delta {refmapping {}}} {
    foreach {key val} $d {
        # refmapping has to be passed on. Without it the redirection of
        # pdf2's Pages object to pdf1's was silently skipped for the
        # trailer, root and info dictionaries -- the only reason it never
        # showed is that AppendPdf rebuilds the Pages object afterwards.
        dict set d $key [RenumberRef $val $delta $refmapping]
    }
    return $d
}

# Renumber a complete object
proc pdf4tcl::cat::RenumberObj {obj delta {refmapping {}}} {
    # Extract initial obj part
    if {![regexp {^\s*(\d+)\s+0\s+obj\s*(.*)$} $obj -> objid objbody]} {
        #puts OBJ??
        #puts '$obj'
        return $obj
    }
    # TODO, remove any stream before passing it to RenumberRef
    set objbody [RenumberRef $objbody $delta $refmapping]
    set objid [expr {$objid + $delta}]
    set result "$objid 0 obj\n$objbody"
    return $result
}

proc pdf4tcl::cat::RenumberPdf {pdfd delta {refmapping {}}} {
    set newd {}
    foreach {key val} $pdfd {
        if {[string is digit $key]} {
            set val [dict get $val full] ;# TBD if stream identified?
            dict set newd [expr {$key + $delta}] \
                    full [RenumberObj $val $delta $refmapping]
            continue
        }
        switch $key {
            N {
                # N will represent end of object numbers
                dict set newd $key [expr {$val + $delta}]
            }
            trailer - root - info {# Dictionary
                dict set newd $key [RenumberDict $val $delta]
            }
            rootid - infoid {
                dict set newd $key [expr {$val + $delta}]
            }
        }
    }
    return $newd
}

# Add one pdf's contents to another
# Merge the interactive form of pdf2 into pdf1.
#
# Called from AppendPdf AFTER pdf2 has been renumbered, so every reference
# in pdf2 already carries its final number.
#
# Until 0.9.4.44 this was a stub -- the code read both dictionaries and
# ended in the comment "How to do this???". The consequence was measurable
# and silent: merging two one-field documents produced a file whose root
# catalog kept the /AcroForm of the FIRST document only. The second
# document's widget sat on its page, fully formed, and no reader offered it
# for filling. pdftk dump_data_fields listed one field where two had gone
# in. Nothing warned.
#
# What is merged:
#   /Fields    the two arrays are concatenated -- this is the point
#   /DR        resource dictionaries are combined per sub-dictionary
#              (/Font, /Encoding, ...); on a name collision pdf1 wins,
#              because its objects are the ones the first document's
#              appearance streams refer to
#   /SigFlags  bitwise OR, so a signature flag from either survives
#   /DA /Q     kept from pdf1 if it has them, otherwise taken from pdf2
#
# What is NOT set: /NeedAppearances. It damages digital signatures, and
# every field type here writes its own appearance stream.
#
# Field names are NOT made unique. Two fields of the same name are one
# field to a reader, with one shared value -- that is what the standard
# says (ISO 32000-1 clause 12.7.3.2) and it is sometimes what the caller
# wants. Renaming would break the /T reference in any JavaScript that
# comes with the document. A collision is reported through
# ::pdf4tcl::warnings so it is at least visible.
proc pdf4tcl::cat::MergeAcroForm {pdf1 pdf2} {
    set has1 [dict exists $pdf1 root /AcroForm]
    set has2 [dict exists $pdf2 root /AcroForm]
    if {!$has2} { return $pdf1 }

    set ob2 [lindex [dict get $pdf2 root /AcroForm] 0]
    if {![dict exists $pdf2 $ob2]} { return $pdf1 }
    set d2 [PdfObjToTclDict [dict get $pdf2 $ob2 full]]

    # Only pdf2 has a form: adopt its object, which is already renumbered.
    if {!$has1} {
        set rootid [dict get $pdf1 rootid]
        set body [dict get $pdf1 $rootid full]
        if {[regexp {/AcroForm} $body]} { return $pdf1 }
        regsub {>>\s*endobj\s*$} $body "/AcroForm $ob2 0 R\n>>\nendobj" body
        dict set pdf1 $rootid full $body
        dict set pdf1 root /AcroForm [list $ob2 0 R]
        return $pdf1
    }

    set ob1 [lindex [dict get $pdf1 root /AcroForm] 0]
    if {![dict exists $pdf1 $ob1]} { return $pdf1 }
    set d1 [PdfObjToTclDict [dict get $pdf1 $ob1 full]]

    # --- /Fields ---------------------------------------------------------
    set f1 [AcroFieldRefs $d1]
    set f2 [AcroFieldRefs $d2]
    if {[llength $f2]} {
        WarnDuplicateFieldNames $pdf1 $pdf2 $f1 $f2
        dict set d1 /Fields "\[[join [concat $f1 $f2] { }]\]"
    }

    # --- /DR -------------------------------------------------------------
    if {[dict exists $d2 /DR]} {
        if {![dict exists $d1 /DR]} {
            dict set d1 /DR [dict get $d2 /DR]
        } else {
            set dr1 [lindex [dict get $d1 /DR] 0]
            set dr2 [lindex [dict get $d2 /DR] 0]
            if {[string is digit -strict $dr1] && [string is digit -strict $dr2]
                    && [dict exists $pdf1 $dr1] && [dict exists $pdf2 $dr2]} {
                set pdf1 [MergeResourceDicts $pdf1 $dr1 $pdf2 $dr2]
            }
        }
    }

    # --- /SigFlags, /DA, /Q ----------------------------------------------
    if {[dict exists $d2 /SigFlags]} {
        set s2 [dict get $d2 /SigFlags]
        set s1 [expr {[dict exists $d1 /SigFlags] ? [dict get $d1 /SigFlags] : 0}]
        if {[string is integer -strict $s1] && [string is integer -strict $s2]} {
            dict set d1 /SigFlags [expr {$s1 | $s2}]
        }
    }
    foreach key {/DA /Q} {
        if {![dict exists $d1 $key] && [dict exists $d2 $key]} {
            dict set d1 $key [dict get $d2 $key]
        }
    }

    dict set pdf1 $ob1 full "$ob1 0 obj\n[TclDictToPdfDict $d1]\nendobj"
    return $pdf1
}

# The /Fields entry is an array of references. Returns them as a flat list
# of "N 0 R" triples, ready to be joined.
proc pdf4tcl::cat::AcroFieldRefs {d} {
    if {![dict exists $d /Fields]} { return {} }
    set raw [dict get $d /Fields]
    set out {}
    foreach {full num} [regexp -all -inline {(\d+)\s+\d+\s+R} $raw] {
        lappend out $num 0 R
    }
    return $out
}

# Two fields of the same name are one field to a reader. Say so.
proc pdf4tcl::cat::WarnDuplicateFieldNames {pdf1 pdf2 refs1 refs2} {
    set names1 {}
    foreach {num z r} $refs1 {
        if {[dict exists $pdf1 $num]
                && [regexp {/T\s*\(([^)]*)\)} [dict get $pdf1 $num full] -> n]} {
            lappend names1 $n
        }
    }
    set dups {}
    foreach {num z r} $refs2 {
        set src [expr {[dict exists $pdf2 $num] ? $pdf2 : $pdf1}]
        if {[dict exists $src $num]
                && [regexp {/T\s*\(([^)]*)\)} [dict get $src $num full] -> n]} {
            if {$n in $names1 && $n ni $dups} { lappend dups $n }
        }
    }
    if {[llength $dups]} {
        lappend ::pdf4tcl::warnings "catPdf: form field name(s) appear in\
                both documents and will act as one field with one shared\
                value: [join $dups {, }]"
    }
}

# Combine two resource dictionaries entry by entry. Sub-dictionaries such
# as /Font are merged key by key; on a collision pdf1 keeps its object,
# because its appearance streams already point at it.
proc pdf4tcl::cat::MergeResourceDicts {pdf1 id1 pdf2 id2} {
    set r1 [PdfObjToTclDict [dict get $pdf1 $id1 full]]
    set r2 [PdfObjToTclDict [dict get $pdf2 $id2 full]]
    set changed 0
    foreach {key val2} $r2 {
        if {![dict exists $r1 $key]} {
            dict set r1 $key $val2
            set changed 1
            continue
        }
        set val1 [dict get $r1 $key]
        # Both inline sub-dictionaries? Merge their entries.
        if {[string match "<<*" [string trim $val1]]
                && [string match "<<*" [string trim $val2]]} {
            set sub1 [PdfDictToTclDict $val1]
            set sub2 [PdfDictToTclDict $val2]
            foreach {k v} $sub2 {
                if {![dict exists $sub1 $k]} {
                    dict set sub1 $k $v
                    set changed 1
                }
            }
            dict set r1 $key [TclDictToPdfDict $sub1]
        }
    }
    if {$changed} {
        dict set pdf1 $id1 full "$id1 0 obj\n[TclDictToPdfDict $r1]\nendobj"
    }
    return $pdf1
}

proc pdf4tcl::cat::AppendPdf {pdf1 pdf2} {
    # Get the pages from first pdf
    set pages1id [lindex [dict get $pdf1 root /Pages] 0]
    regexp {/Kids\s*\[([^\]]*)\]} [dict get $pdf1 $pages1id full] -> kids1vec

    # Get the pages id from second pdf
    set pages2id [lindex [dict get $pdf2 root /Pages] 0]
    # References in pdf2 to its Pages object should be redirected
    # to pdf1's Pages object instead,
    set refmapping [list $pages2id $pages1id]

    # Now, renumber all objects in pdf2 to put them after all objs in pdf1
    set delta [expr {[dict get $pdf1 N] - 1}]
    set pdf2 [RenumberPdf $pdf2 $delta $refmapping]
    #Dump $pdf2

    # Get the list of pages from second pdf, after renumbering
    set pages2id [lindex [dict get $pdf2 root /Pages] 0]
    regexp {/Kids\s*\[([^\]]*)\]} [dict get $pdf2 $pages2id full] -> kids2vec
    #puts "PAGE2 $pages2id $kids2vec"

    # Recreate the pages object and replace it in pdf1
    set kids "$kids1vec $kids2vec"
    set count [expr {[llength $kids] / 3}]
    set newobj "$pages1id 0 obj\n<<\n"
    append newobj "/Type /Pages\n"
    append newobj "/Count $count\n"
    append newobj "/Kids \[ $kids \]\n"
    append newobj ">>\nendobj"
    dict set pdf1 $pages1id full $newobj

    # The interactive form of the result is the union of both.
    set pdf1 [MergeAcroForm $pdf1 $pdf2]

    # Merge the logical structure before the objects are transferred, since
    # it rewrites objects on both sides.
    set merged [MergeStructure $pdf1 $pdf2]
    if {[llength $merged] == 2} {
        lassign $merged pdf1 pdf2
    } else {
        set pdf1 $merged
    }

    # Transfer all objects from 2 to 1
    foreach {key val} $pdf2 {
        if {[string is digit $key]} {
            dict set pdf1 $key full [dict get $val full]
        }
    }
    # Keep the higher of the two header versions
    if {[dict exists $pdf2 version]} {
        set v2 [dict get $pdf2 version]
        set v1 [expr {[dict exists $pdf1 version] ? [dict get $pdf1 version] : 1.4}]
        if {[package vcompare $v2 $v1] > 0} {
            ##nagelfar ignore Found constant
            dict set pdf1 version $v2
        }
    }

    # Update size in trailer
    dict set pdf1 trailer /Size [dict get $pdf2 N]
    dict set pdf1 N [dict get $pdf2 N]

    return $pdf1
}

# Extract page objects from pdf dictionary (from ReadPdf)
# Return type is a list of page streams, uncompressed
proc pdf4tcl::cat::GetPages {pdf} {
    # Get the pages from Kids vector
    set pages1id [lindex [dict get $pdf root /Pages] 0]
    regexp {/Kids\s*\[([^\]]*)\]} [dict get $pdf $pages1id full] -> kidsvec

    set pages {}
    foreach {id _ _} $kidsvec {
        # Page object to get contents reference
        set pObj [dict get $pdf $id]
        set fullObj [dict get $pObj full]
        set d [PdfObjToTclDict $fullObj]
        set contentsRef [dict get $d /Contents]
        set contentsRef [string trim $contentsRef "\[\]"]
        lassign $contentsRef contentsId

        # Contents object
        set cObj [dict get $pdf $contentsId]
        set fullObj [dict get $cObj full]
        set d [PdfObjToTclDict $fullObj stream]
        if {[dict exists $d /Filter]} {
            set filter [dict get $d /Filter]
            # TODO: Other filters?
            if {[string match "*/FlateDecode*" $filter]} {
                set stream [zlib decompress $stream]
            }
        }
        lappend pages $stream
    }
    return $pages
}

# Extract text from a page stream, uncompressed
# Result is a list of lines in y coordinate order.
# Each line is a list of text chunks from the same y coordinate, in x order.
proc pdf4tcl::cat::GetTextFromPage {pageStream} {
    # TODO: Handle more complex stuff, this basically assumes being generated from
    # straightforward pdf4tcl usage.
    # Needs to handle transforms and other text commands than Tm/Tj.
    # Also, cannot assume linebreaks after each command?
    set textChunks {}
    set currX 0.0
    set currY 0.0
    foreach line [split $pageStream \n] {
        # Text Matrix
        if {[regexp { Tm\s*$} $line]} {
            lassign $line _ _ _ _ currX currY _
            continue
        }
        if {[regexp {\((.*)\)\s+Tj\s*$} $line -> text]} {
            # TODO: clean up from escapes
            # TODO: fix encoding issues with fonts (tricky)
            lappend textChunks $currX $currY $text
        }
    }
    # Sort in x first
    set textChunks [lsort -real -increasing -stride 3 -index 0 $textChunks]
    # Then in y to make it primary
    set textChunks [lsort -real -decreasing -stride 3 -index 1 $textChunks]

    set result {}
    set line {}
    set currY -100000
    foreach {x y t} $textChunks {
        if {$y != $currY} {
            if {[llength $line] != 0} {
                lappend result $line
            }
            set line [list $t]
            set currY $y
        } else {
            lappend line $t
        }
    }
    if {[llength $line] != 0} {
        lappend result $line
    }
    return $result
}

# Concatenate PDFs.
# Currently the implementation limits the PDFs a lot since not all details
# are taken care of yet. Straightforward ones like those created with pdf4tcl
# or ps2pdf should work mostly ok.
# Fold objects with an identical body onto one.
#
# Merging documents built from the same template duplicates everything they
# share -- above all the embedded font programs. Measured on two documents of
# 24729 bytes each, both embedding FreeSans: the result was 49296 bytes with
# the font twice in it, and three pairs of streams byte for byte identical,
# together about 39 KB of 57. Twenty chapters from one template embed the
# font twenty times.
#
# The comparison is over the complete object body, so two objects are folded
# together only when nothing distinguishes them. That is deliberately strict:
# two font subsets that merely look alike must stay apart, since their glyph
# indices need not agree. Where the bytes are equal there is nothing to get
# wrong.
#
# Objects that carry the document structure are left alone. The page tree,
# the catalog and the parent tree are legitimately similar between documents
# and folding them would join things that only look the same.
# Replace the document information dictionary of a merged document.
#
# Merging keeps the catalog of the FIRST document, and with it its /Info --
# so two documents joined end up carrying the title of part one. That is
# not wrong on its own; a merger cannot know what two documents are called
# together. But it is a surprise when nobody said so, which is why catPdf
# now takes -title and friends.
#
# Keys are given as they appear in the dictionary: Title, Author, Subject,
# Keywords, Creator, Producer. An empty value REMOVES the entry -- better
# no title than the wrong one.
proc pdf4tcl::cat::SetInfo {pdfd info} {
    if {![dict size $info]} { return $pdfd }

    # The existing dictionary, if there is one.
    set old [dict create]
    set infoId ""
    if {[dict exists $pdfd trailer /Info]} {
        set infoId [lindex [dict get $pdfd trailer /Info] 0]
        if {[dict exists $pdfd $infoId]} {
            set body [dict get $pdfd $infoId full]
            if {[regexp {<<(.*)>>} $body -> inner]} {
                set old [PdfDictToTclDict "<<$inner>>"]
            }
        }
    }

    dict for {key val} $info {
        set pdfKey "/$key"
        if {$val eq ""} {
            dict unset old $pdfKey
        } else {
            # Round brackets and backslashes have to be escaped inside a
            # PDF string, or a title with a bracket in it ends the object
            # early.
            dict set old $pdfKey "([string map {\\ \\\\ ( \\( ) \\)} $val])"
        }
    }

    if {![dict size $old]} {
        # Everything removed: drop the reference as well, rather than
        # leaving an empty dictionary behind.
        if {$infoId ne ""} { dict unset pdfd trailer /Info }
        return $pdfd
    }

    set body "<<"
    dict for {k v} $old { append body " $k $v" }
    append body " >>"

    if {$infoId eq ""} {
        # No /Info so far -- append a new object.
        set maxId 0
        foreach key [dict keys $pdfd] {
            if {[string is digit -strict $key] && $key > $maxId} { set maxId $key }
        }
        set infoId [expr {$maxId + 1}]
        dict set pdfd trailer /Info "$infoId 0 R"
    }
    dict set pdfd $infoId full "$infoId 0 obj\n$body\nendobj\n"
    return $pdfd
}

proc pdf4tcl::cat::DedupObjects {pdfd} {
    set bodies {}
    set mapping {}
    set saved 0

    # The dict also holds "trailer", "root" and "version", so filter before
    # sorting numerically.
    set numeric {}
    foreach key [dict keys $pdfd] {
        if {[string is digit -strict $key]} { lappend numeric $key }
    }
    foreach key [lsort -integer $numeric] {
        set body [dict get $pdfd $key full]

        # Strip the object header, which holds the number and would make
        # every object unique.
        if {![regexp {^\s*\d+\s+\d+\s+obj\s*(.*)$} $body -> rest]} continue

        # Never fold anything the document structure hangs on.
        if {[regexp {/Type\s*/(Page|Pages|Catalog|StructTreeRoot|StructElem)\M} $rest]} {
            continue
        }

        if {[dict exists $bodies $rest]} {
        ##nagelfar ignore Found constant
            dict set mapping $key [dict get $bodies $rest]
            incr saved [string length $rest]
        } else {
            ##nagelfar ignore Found constant
        dict set bodies $rest $key
        }
    }

    if {[dict size $mapping] == 0} {
        return $pdfd
    }

    # Dropping objects leaves gaps in the numbering, and WritePdf writes one
    # xref entry per number from 1 to N -- its own comment says "TBD handle
    # missing objects?". So renumber densely: the mapping gets a second half
    # that closes the gaps, and both are applied in one pass.
    set renumber {}
    set next 1
    foreach key [lsort -integer $numeric] {
        if {[dict exists $mapping $key]} continue
        ##nagelfar ignore Found constant
        dict set renumber $key $next
        incr next
    }
    # A folded object points at its survivor, which then points at its new
    # number.
    foreach {from to} $mapping {
        ##nagelfar ignore Found constant
        dict set renumber $from [dict get $renumber $to]
    }

    set out {}
    foreach {key val} $pdfd {
        if {![string is digit -strict $key]} {
        ##nagelfar ignore Found constant
            dict set out $key $val
            continue
        }
        if {[dict exists $mapping $key]} continue
        set body [RemapRefs [dict get $val full] $renumber]
        set newKey [dict get $renumber $key]
        # The object header carries the number as well.
        regsub {^\s*\d+(\s+\d+\s+obj)} $body "$newKey\\1" body
        ##nagelfar ignore Found constant
        dict set out $newKey full $body
    }
    ##nagelfar ignore Found constant
    dict set out trailer [RemapDict [dict get $pdfd trailer] $renumber]
    if {[dict exists $pdfd root]} {
        ##nagelfar ignore Found constant
        dict set out root [RemapDict [dict get $pdfd root] $renumber]
    }
    ##nagelfar ignore Found constant
    dict set out N $next
    ##nagelfar ignore Found constant
    dict set out trailer /Size $next
    return $out
}

# Rewrite "N 0 R" for every renumbered object.
#
# regsub cannot call a command per match -- the replacement is text, not
# code. Passing a script there writes the script itself into the document,
# which is what a first attempt did: the font dictionaries ended up
# containing "/FontFile2 apply {{mapping num rest} ...". So walk the matches
# and rebuild the string.
proc pdf4tcl::cat::RemapRefs {body mapping} {
    set out ""
    set rest $body
    while {[regexp -indices {(\m\d+)(\s+0\s+R\M)} $rest all num tail]} {
        lassign $all aStart aEnd
        lassign $num nStart nEnd
        append out [string range $rest 0 [expr {$nStart - 1}]]
        set n [string range $rest $nStart $nEnd]
        if {[dict exists $mapping $n]} {
            append out [dict get $mapping $n]
        } else {
            append out $n
        }
        append out [string range $rest [expr {$nEnd + 1}] $aEnd]
        set rest [string range $rest [expr {$aEnd + 1}] end]
    }
    append out $rest
    return $out
}

proc pdf4tcl::cat::RemapDict {d mapping} {
    foreach {key val} $d {
        if {[llength $val] == 3 && [lindex $val 2] eq "R"} {
            set num [lindex $val 0]
            if {[dict exists $mapping $num]} {
                dict set d $key [lreplace $val 0 0 [dict get $mapping $num]]
            }
        }
    }
    return $d
}

proc pdf4tcl::catPdf {args} {
    # Options first, then the files. Keeping the file names positional
    # means every existing call still works:
    #
    #   catPdf a.pdf b.pdf out.pdf
    #   catPdf -title "Complete file" a.pdf b.pdf out.pdf
    #
    # Why the options exist: merging keeps the catalog of the FIRST
    # document, so the result carries the title of part one. A merger
    # cannot know what two documents are called together -- so it asks.
    set info [dict create]
    set known {-title Title -author Author -subject Subject \
               -keywords Keywords -creator Creator -producer Producer}
    while {[llength $args] && [string match {-*} [lindex $args 0]]} {
        set opt [lindex $args 0]
        if {![dict exists $known $opt]} {
            throw {PDF4TCL} "catPdf: unknown option \"$opt\": must be\
                    [join [lsort [dict keys $known]] {, }]"
        }
        if {[llength $args] < 2} {
            throw {PDF4TCL} "catPdf: value for \"$opt\" missing"
        }
        dict set info [dict get $known $opt] [lindex $args 1]
        set args [lrange $args 2 end]
    }

    if {[llength $args] < 3} {
        throw {PDF4TCL} "wrong # args: should be \"catPdf ?options?\
                infile ?infile ...? outfile\""
    }
    set outfile [lindex $args end]
    set infile1 [lindex $args 0]
    set infiles [lrange $args 1 end-1]

    set pdf1 [pdf4tcl::cat::ReadPdf $infile1]
    #pdf4tcl::cat::Dump $pdf1
    foreach f $infiles {
        set pdf2 [pdf4tcl::cat::ReadPdf $f]
        #pdf4tcl::cat::Dump $pdf2
        set pdf1 [pdf4tcl::cat::AppendPdf $pdf1 $pdf2]
    }
    # Structure trees are merged in AppendPdf. StripStructure remains for the
    # case where the merge could not be completed; it is called from there.
    #
    # Folding identical objects happens once at the end rather than per
    # append, so a font shared by five documents collapses to one copy and
    # not to four.
    set pdf1 [pdf4tcl::cat::DedupObjects $pdf1]
    # After the folding, so a rewritten /Info is not folded away against
    # the original of the first document.
    set pdf1 [pdf4tcl::cat::SetInfo $pdf1 $info]
    pdf4tcl::cat::WritePdf $outfile $pdf1
}

# Remove the logical structure from a merged document.
#
# Merging tagged PDFs is not a matter of renumbering objects. Every page
# carries a /StructParents key indexing the /ParentTree of ITS document, and
# both documents number their pages from 0. AppendPdf keeps the catalog of
# the first document, so the result claims to be tagged while the second
# document's pages point at the first document's parent tree: page 2 of the
# merge resolved to the structure of page 1 of the original. Measured on two
# one-page documents, the merge produced two pages both carrying
# /StructParents 0, a tree containing only the first document's heading, and
# no error anywhere.
#
# A file that lies about its structure is worse than one that has none: a
# screen reader trusts /MarkInfo and reads the wrong tree instead of falling
# back to the paint order. So the structure is removed and the caller told.
#
# Proper merging needs the parent trees remapped and the two /Document
# subtrees combined under one root. See TAGGED.md.
# Merge the logical structure of pdf2 into pdf1.
#
# Called from AppendPdf after pdf2 has been renumbered, so every object of
# pdf2 already carries its final number and its internal references are
# consistent. What is left to do is join the two trees:
#
#   1. the /Document children of pdf2's StructTreeRoot are appended to
#      pdf1's /K, and their /P is redirected to pdf1's root
#   2. the parent tree keys of pdf2 are shifted by pdf1's
#      /ParentTreeNextKey, in the tree itself and in every /StructParents
#      on a page and /StructParent on an annotation
#   3. the two /Nums arrays are merged and sorted -- ISO 32000-1 clause
#      7.9.7 requires increasing keys
#
# MCIDs are deliberately NOT renumbered. They are scoped to the content
# stream of one page, and merging documents does not merge pages, so an MCID
# of 0 on a page of pdf1 and an MCID of 0 on a page of pdf2 never meet. Only
# the parent tree keys have to be unique across the result.
#
# Returns the merged pdf1, or the unchanged pdf1 if there is nothing to do.
proc pdf4tcl::cat::MergeStructure {pdf1 pdf2} {
    set root1 [lindex [dict get $pdf1 trailer /Root] 0]
    set root2 [lindex [dict get $pdf2 trailer /Root] 0]
    if {![dict exists $pdf1 $root1] || ![dict exists $pdf2 $root2]} {
        return $pdf1
    }
    set cat1 [dict get $pdf1 $root1 full]
    set cat2 [dict get $pdf2 $root2 full]

    set has1 [regexp {/StructTreeRoot\s+(\d+)\s+0\s+R} $cat1 -> st1]
    set has2 [regexp {/StructTreeRoot\s+(\d+)\s+0\s+R} $cat2 -> st2]

    if {!$has2} {
        # Nothing to bring over. If pdf1 is tagged its tree stays valid; the
        # pages coming from pdf2 simply carry no structure, which is legal
        # but not PDF/UA conformant.
        if {$has1} {
            lappend ::pdf4tcl::warnings "catPdf: a document without logical\
                    structure was appended to a tagged one. The result keeps\
                    the structure of the first document, so the appended\
                    pages are not in the tree."
        }
        return $pdf1
    }
    if {!$has1} {
        # pdf1 untagged, pdf2 tagged. Adopting pdf2's tree would leave
        # pdf1's pages outside it, which is the same half state as above and
        # harder to see. Drop pdf2's structure instead and say so.
        lappend ::pdf4tcl::warnings "catPdf: a tagged document was appended\
                to one without logical structure. The structure of the\
                appended document was dropped, because keeping it would\
                leave the first document's pages outside the tree."
        return $pdf1
    }

    # --- the two structure tree roots ------------------------------------
    set body1 [dict get $pdf1 $st1 full]
    set body2 [dict get $pdf2 $st2 full]

    if {![regexp {/K\s*\[([^\]]*)\]} $body1 -> kids1]} { set kids1 "" }
    if {![regexp {/K\s*\[([^\]]*)\]} $body2 -> kids2]} { set kids2 "" }

    # Every top level element of pdf2 now hangs under pdf1's root
    foreach {oid _ _} $kids2 {
        if {![dict exists $pdf2 $oid]} continue
        set elem [dict get $pdf2 $oid full]
        regsub {/P\s+\d+\s+0\s+R} $elem "/P $st1 0 R" elem
        ##nagelfar ignore Found constant
        dict set pdf2 $oid full $elem
    }

    # --- parent tree keys -------------------------------------------------
    set next1 0
    regexp {/ParentTreeNextKey\s+(\d+)} $body1 -> next1
    set next2 0
    regexp {/ParentTreeNextKey\s+(\d+)} $body2 -> next2

    set pt1 ""
    set pt2 ""
    regexp {/ParentTree\s+(\d+)\s+0\s+R} $body1 -> pt1
    regexp {/ParentTree\s+(\d+)\s+0\s+R} $body2 -> pt2
    if {$pt1 eq "" || $pt2 eq ""} {
        lappend ::pdf4tcl::warnings "catPdf: a structure tree without a\
                /ParentTree was found. The structure of the appended document\
                was dropped."
        return $pdf1
    }

    # Shift /StructParents on pages and /StructParent on annotations of pdf2
    foreach {key val} $pdf2 {
        if {![string is digit -strict $key]} continue
        set obj [dict get $val full]
        set changed 0
        if {[regexp {/StructParents\s+(\d+)} $obj -> old]} {
            regsub {/StructParents\s+\d+} $obj \
                    "/StructParents [expr {$old + $next1}]" obj
            set changed 1
        }
        if {[regexp {/StructParent\s+(\d+)} $obj -> old]} {
            regsub {/StructParent\s+\d+} $obj \
                    "/StructParent [expr {$old + $next1}]" obj
            set changed 1
        }
        if {$changed} {
            ##nagelfar ignore Found constant
            dict set pdf2 $key full $obj
        }
    }

    # Merge the two number trees
    set nums [dict merge [ParseNums [dict get $pdf1 $pt1 full]] \
            [ShiftNums [ParseNums [dict get $pdf2 $pt2 full]] $next1]]
    set out ""
    foreach key [lsort -integer [dict keys $nums]] {
        append out "$key [dict get $nums $key]\n"
    }
    dict set pdf1 $pt1 full "$pt1 0 obj\n<</Nums \[\n$out\]>>\nendobj"

    # --- write back the merged root --------------------------------------
    set kids [string trim "$kids1 $kids2"]
    set body "$st1 0 obj\n<</Type /StructTreeRoot\n"
    append body "/K \[$kids\]\n"
    append body "/ParentTree $pt1 0 R\n"
    append body "/ParentTreeNextKey [expr {$next1 + $next2}]\n"
    append body ">>\nendobj"
    dict set pdf1 $st1 full $body

    # pdf2's own StructTreeRoot and ParentTree objects are now unreferenced.
    # They stay in the file; removing them would mean renumbering everything
    # again, and unreferenced objects are inert.
    dict set pdf1 __mergedstructure 1
    return [list $pdf1 $pdf2]
}

# Parse the /Nums array of a number tree into a key -> value dict.
# The value is kept as written, since it is either an array of references or
# a single reference and both are copied verbatim.
proc pdf4tcl::cat::ParseNums {obj} {
    if {![regexp {/Nums\s*\[(.*)\]\s*>>} $obj -> body]} {
        return {}
    }
    set res {}
    # Entries are "key [refs]" or "key n 0 R"
    set rest [string trim $body]
    while {[regexp {^(\d+)\s*(.*)$} $rest -> key rest]} {
        set rest [string trimleft $rest]
        if {[string index $rest 0] eq "\["} {
            set close [string first "\]" $rest]
            set val [string range $rest 0 $close]
            set rest [string range $rest $close+1 end]
        } elseif {[regexp {^(\d+\s+0\s+R)\s*(.*)$} $rest -> val rest]} {
            # single reference
        } else {
            break
        }
        ##nagelfar ignore Found constant
        dict set res $key [string trim $val]
        set rest [string trimleft $rest]
    }
    return $res
}

proc pdf4tcl::cat::ShiftNums {nums delta} {
    set res {}
    foreach {key val} $nums {
        ##nagelfar ignore Found constant
        dict set res [expr {$key + $delta}] $val
    }
    return $res
}

proc pdf4tcl::cat::StripStructure {pdfd} {
    set rootId [lindex [dict get $pdfd trailer /Root] 0]
    if {![dict exists $pdfd $rootId]} {
        return $pdfd
    }
    set catalog [dict get $pdfd $rootId full]
    if {![regexp {/StructTreeRoot|/MarkInfo} $catalog]} {
        return $pdfd
    }

    # Drop the catalog entries. The StructElem objects themselves stay in the
    # file as unreferenced objects; they are harmless once nothing points at
    # them, and removing them would mean renumbering everything again.
    #
    # The locals here are deliberately not called "full": a variable of that
    # name makes nagelfar flag the pre-existing "dict set pdf1 $key full ..."
    # in AppendPdf as a constant that is also a variable.
    regsub -all {/StructTreeRoot\s+\d+\s+0\s+R\s*} $catalog "" catalog
    regsub -all {/MarkInfo\s*<<[^>]*>>\s*} $catalog "" catalog
    ##nagelfar ignore Found constant
    dict set pdfd $rootId full $catalog

    # /StructParents on the pages is now dangling as well.
    foreach {key val} $pdfd {
        if {![string is digit -strict $key]} continue
        set obj [dict get $val full]
        if {[regsub -all {/StructParents\s+\d+\s*} $obj "" obj]} {
            ##nagelfar ignore Found constant
            dict set pdfd $key full $obj
        }
    }

    variable ::pdf4tcl::warnings
    lappend ::pdf4tcl::warnings "catPdf: the logical structure (tagged PDF)\
            was removed. Merging structure trees is not supported; keeping\
            it would have produced a document whose pages resolve to the\
            wrong structure elements."
    return $pdfd
}

# Extract form data from a PDF file
# Return value is a dictionary of id/info pairs.
#  info is a dictionary containing these fields:
#   type    : Field type.
#   value   : Form value.
#   flags   : Value of form flags field.
#   default : Default value, if any.
# ---------------------------------------------------------------------------
# exportForms -- FDF/XFDF-Export von Formulardaten (0.9.4.23)
#
# Schreibt Formulardaten eines ausgefuellten PDFs als FDF oder XFDF.
#
# Usage:
#   pdf4tcl::exportForms infile outfile ?options?
#
# Options:
#   -format fdf|xfdf    Ausgabeformat (Standard: fdf)
#   -password pw        Passwort fuer verschluesselte PDFs
#
# Rueckgabe: Anzahl exportierter Felder.
# ---------------------------------------------------------------------------

proc pdf4tcl::exportForms {pdfFile outFile args} {
    set format   fdf
    set password {}

    foreach {k v} $args {
        switch -- $k {
            -format   { set format   $v }
            -password { set password $v }
            default   { throw {PDF4TCL} "unknown option \"$k\"" }
        }
    }
    if {$format ni {fdf xfdf}} {
        throw {PDF4TCL} "invalid -format \"$format\": must be fdf or xfdf"
    }

    # Formulardaten einlesen
    set formData [pdf4tcl::getForms $pdfFile]
    if {[llength $formData] == 0} {
        # Leeres Dict -> 0 Felder
        set ch [open $outFile w]
        fconfigure $ch -encoding utf-8 -translation lf
        if {$format eq "fdf"} {
            puts $ch "%FDF-1.2"
            puts $ch "1 0 obj<</FDF<</Fields[]>>>endobj"
            puts $ch "trailer<</Root 1 0 R>>"
            puts $ch "%%EOF"
        } else {
            puts $ch {<?xml version="1.0" encoding="UTF-8"?>}
            puts $ch {<xfdf xmlns="http://ns.adobe.com/xfdf/" xml:space="preserve">}
            puts $ch "  <fields/>"
            puts $ch {</xfdf>}
        }
        close $ch
        return 0
    }

    if {$format eq "fdf"} {
        _exportFormsFDF $pdfFile $outFile $formData
    } else {
        _exportFormsXFDF $pdfFile $outFile $formData
    }
    return [expr {[dict size $formData]}]
}

proc pdf4tcl::_exportFormsFDF {pdfFile outFile formData} {
    # FDF: Forms Data Format (ISO 32000 SS12.7.7)
    # Einfaches Textformat: Objekt 1 enthaelt /Fields-Array
    set fields {}
    dict for {id info} $formData {
        set val [expr {[dict exists $info value] ? [dict get $info value] : {}}]
        # Wert bereinigen: Klammern entfernen wenn vorhanden
        set val [string trim $val "()"]
        # FDF-String-Escaping: Backslash und Klammern
        set val [regsub -all {[\\\(\)]} $val {\\&}]
        lappend fields "<</T($id)/V($val)>>"
    }

    set ch [open $outFile w]
    fconfigure $ch -encoding utf-8 -translation lf
    puts $ch "%FDF-1.2"
    puts $ch "% FDF export from pdf4tcl -- [clock format [clock seconds]]"
    puts $ch "1 0 obj"
    puts $ch "<<"
    puts $ch "  /FDF"
    puts $ch "  <<"
    puts $ch "    /F ([file tail $pdfFile])"
    puts $ch "    /Fields \["
    foreach f $fields {
        puts $ch "      $f"
    }
    puts $ch "    \]"
    puts $ch "  >>"
    puts $ch ">>"
    puts $ch "endobj"
    puts $ch "trailer"
    puts $ch "<</Root 1 0 R>>"
    puts $ch "%%EOF"
    close $ch
}

proc pdf4tcl::_exportFormsXFDF {pdfFile outFile formData} {
    # XFDF: XML Forms Data Format (ISO 32000 SS12.7.8)
    proc _xesc {s} {
        set s [string map {& &amp; < &lt; > &gt;} $s]
        regsub -all {"} $s {&quot;} s
        regsub -all {'} $s {&apos;} s
        return $s
    }

    set ch [open $outFile w]
    fconfigure $ch -encoding utf-8 -translation lf
    puts $ch {<?xml version="1.0" encoding="UTF-8"?>}
    puts $ch {<xfdf xmlns="http://ns.adobe.com/xfdf/" xml:space="preserve">}
    puts $ch "  <!-- XFDF export from pdf4tcl -- [clock format [clock seconds]] -->"
    set fname [_xesc [file tail $pdfFile]]
    puts $ch [format {  <f href="%s"/>} $fname]
    puts $ch {  <fields>}

    dict for {id info} $formData {
        set val [expr {[dict exists $info value] ? [dict get $info value] : {}}]
        set val [string trim $val "()"]
        set type [expr {[dict exists $info type] ? [dict get $info type] : {}}]
        set xid  [_xesc $id]
        set xval [_xesc $val]
        puts $ch [format {    <field name="%s">} $xid]
        puts $ch "      <!-- type: $type -->"
        puts $ch "      <value>$xval</value>"
        puts $ch "    </field>"
    }

    puts $ch {  </fields>}
    puts $ch {</xfdf>}
    close $ch
}


# Fill the form fields of an existing PDF and write it out again.
#
#   pdf4tcl::fillForms in.pdf out.pdf {name "Meier" gelesen /Yes}
#
# The counterpart to getForms: same search for /Widget objects, but the
# value is written rather than read. Returns the number of fields filled.
#
# A field named in the dict but not present in the file is reported --
# silently ignoring it would mean a form comes out empty and nobody knows
# why. Fields present but not named keep what they had.
#
# Text fields take a string. Check boxes and radio buttons take the state
# name as it appears in the file, with the slash: /Yes, /Off, /On. Which
# ones a field knows is in its /AP dictionary; getForms reports the
# current one under "default".
#
# What this does NOT do: build appearance streams. A viewer that honours
# /NeedAppearances -- which is set here -- draws the value itself. One
# that ignores the flag shows the field as it was, with the value present
# but invisible. Acrobat and most browsers honour it; some print paths do
# not.
proc pdf4tcl::fillForms {inFile outFile values} {
    if {![file exists $inFile]} {
        throw {PDF4TCL} "No such file: $inFile"
    }
    if {![dict size $values]} { return 0 }
    set pdf [pdf4tcl::cat::ReadPdf $inFile]

    set N [dict get $pdf N]
    set gefuellt 0
    set gesehen {}

    for {set o 1} {$o <= $N} {incr o} {
        if {![dict exists $pdf $o]} continue
        set body [dict get $pdf $o full]
        if {![string match {*/Widget*} $body]} continue
        set d [pdf4tcl::cat::PdfObjToTclDict $body]
        if {![dict exists $d /Subtype] || [dict get $d /Subtype] ne "/Widget"} {
            continue
        }
        if {![dict exists $d /T]} continue
        set id [string trim [dict get $d /T] "()"]
        lappend gesehen $id
        if {![dict exists $values $id]} continue

        set wert [dict get $values $id]
        set istBtn [expr {[dict exists $d /FT]
                && [dict get $d /FT] eq "/Btn"}]

        if {$istBtn} {
            # A state name, written as a name object. Also set /AS, or the
            # box keeps showing its old appearance.
            if {![string match {/*} $wert]} { set wert "/$wert" }
            set body [FormSetKey $body /V $wert]
            set body [FormSetKey $body /AS $wert]
        } else {
            # QuoteString liefert die Klammern schon mit -- sie noch einmal
            # zu setzen ergab ((Meier)) und damit einen Wert, den kein
            # Leser anzeigt.
            set body [FormSetKey $body /V [::pdf4tcl::QuoteString $wert]]
        }
        dict set pdf $o full $body
        incr gefuellt
    }

    # Names that are not in the file. Reporting them beats an empty form
    # nobody can explain.
    set fehlend {}
    dict for {k v} $values {
        if {$k ni $gesehen} { lappend fehlend $k }
    }
    if {[llength $fehlend]} {
        throw {PDF4TCL} "fillForms: no such field(s) in \"$inFile\":\
                [join [lsort $fehlend] {, }]"
    }

    # /NeedAppearances tells the viewer to draw the values. Without it a
    # field carries the value and shows the old appearance.
    set rootId [lindex [dict get $pdf trailer /Root] 0]
    if {[dict exists $pdf $rootId]} {
        set rootBody [dict get $pdf $rootId full]
        if {[regexp {/AcroForm\s+(\d+)\s+0\s+R} $rootBody -> acroId]} {
            if {[dict exists $pdf $acroId]} {
                set acroBody [dict get $pdf $acroId full]
                if {![string match {*NeedAppearances*} $acroBody]} {
                    set acroBody [FormSetKey $acroBody /NeedAppearances true]
                    dict set pdf $acroId full $acroBody
                }
            }
        }
    }

    pdf4tcl::cat::WritePdf $outFile $pdf
    return $gefuellt
}

# Set or replace one key in an object body. The value is written as given,
# so the caller decides between (string), /Name and a bare number.
proc pdf4tcl::FormSetKey {body key value} {
    # Replace an existing entry. The value may be a string in brackets, a
    # name, or a number -- each ends differently, so three patterns.
    set muster1 "${key}\\s*\\(\[^)\]*\\)"
    set muster2 "${key}\\s*/\\w+"
    set muster3 "${key}\\s+\\d+"
    foreach muster [list $muster1 $muster2 $muster3] {
        if {[regexp $muster $body]} {
            # Ein "&" im Ersatz waere ein Rueckverweis auf den Treffer.
            # Beim ersten Anlauf machte das aus "Meier & Co" ein
            # "Meier << Co" -- inzwischen greift ein anderes Muster und
            # der Fall tritt nicht mehr auf, aber die Maskierung bleibt:
            # sie kostet nichts und der naechste Wert koennte anders
            # aussehen.
            regsub -- $muster $body [string map {& \\& \\ \\\\} "$key $value"] body
            return $body
        }
    }
    # Not there yet -- put it after the opening << of the dictionary.
    if {[regexp {<<} $body]} {
        regsub -- {<<} $body [string map {& \\& \\ \\\\} "<<\n  $key $value"] body
    }
    return $body
}

proc pdf4tcl::getForms {pdfFile} {
    if {![file exists $pdfFile]} {
        throw {PDF4TCL} "No such file: $pdfFile"
    }
    set pdf [pdf4tcl::cat::ReadPdf $pdfFile]

    # Locate Forms
    set N [dict get $pdf N]
    set result {}
    for {set o 1} {$o <= $N} {incr o} {
        if {![dict exists $pdf $o]} continue
        set d [pdf4tcl::cat::PdfObjToTclDict [dict get $pdf $o full]]
        if {[dict exists $d /Subtype] && [dict get $d /Subtype] eq "/Widget"} {
            set id [dict get $d /T]
            # Remove parens from ID-string
            set id [string trim $id "()"]
            # Field Type (/Tx or /Btn)
            if {[dict exists $d /FT]} {
                dict set result $id type [dict get $d /FT]
            } else {
                dict set result $id type {}
            }
            # Default value, if any
            if {[dict exists $d /AS]} {
                dict set result $id default [dict get $d /AS]
            }
            # Value
            if {[dict exists $d /V]} {
                dict set result $id value [dict get $d /V]
            } else {
                dict set result $id value {}
            }
            # Flags
            if {[dict exists $d /Ff]} {
                dict set result $id flags [dict get $d /Ff]
            } else {
                dict set result $id flags 0
            }
        }
    }
    return $result
}
