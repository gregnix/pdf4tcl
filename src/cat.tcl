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
# Unpack the object streams of a file and add what is in them.
#
# An object stream (/Type /ObjStm, ISO 32000-1 clause 7.5.7) holds several
# objects in one compressed stream: a header of "number offset" pairs, then
# the objects as text, starting at /First.
#
# Files with a cross-reference stream use them by default -- qpdf does,
# and so does anything from PDF 1.5 on -- so without this every second
# archival document is unreadable.
#
# Returns the xrefs dict with an entry for each unpacked object. Since
# those have no byte offset in the file, the TEXT is stored under a
# separate key and ReadPdf picks it up from there.
# Undo the PNG row filter of a cross-reference stream.
#
# Each row starts with a filter byte, then $columns data bytes stored as a
# difference. Only filter 2 (Up: difference to the row above) appears in
# practice, but 0 and 1 cost nothing to handle.
proc pdf4tcl::cat::UndoPngPredictor {daten spalten} {
    binary scan $daten cu* bytes
    set zeilenLen [expr {$spalten + 1}]
    set anzahl [expr {[llength $bytes] / $zeilenLen}]
    set vorige [lrepeat $spalten 0]
    set aus {}

    for {set r 0} {$r < $anzahl} {incr r} {
        set off [expr {$r * $zeilenLen}]
        set filter [lindex $bytes $off]
        set zeile {}
        for {set i 0} {$i < $spalten} {incr i} {
            set b [lindex $bytes [expr {$off + 1 + $i}]]
            switch -- $filter {
                0 { }
                1 {
                    # Sub: difference to the byte on the left.
                    if {$i > 0} {
                        set b [expr {($b + [lindex $zeile [expr {$i-1}]]) % 256}]
                    }
                }
                2 {
                    # Up: difference to the byte above.
                    set b [expr {($b + [lindex $vorige $i]) % 256}]
                }
                default {
                    throw {PDF4TCL} "catPdf: PNG predictor filter $filter is\
                            not supported"
                }
            }
            lappend zeile $b
        }
        foreach b $zeile { append aus [binary format cu $b] }
        set vorige $zeile
    }
    return $aus
}

proc pdf4tcl::cat::UnpackObjStreams {data xrefs container file} {
    variable objStmBodies
    array unset objStmBodies

    dict for {stmNo objList} $container {
        if {![dict exists $xrefs $stmNo]} {
            throw {PDF4TCL} "catPdf: \"$file\" names object stream $stmNo,\
                    which is not in the cross-reference table"
        }
        set start [dict get $xrefs $stmNo]
        set sp [string first "stream" $data $start]
        if {$sp < 0} {
            throw {PDF4TCL} "catPdf: object stream $stmNo in \"$file\" has\
                    no stream data"
        }
        set hdr [string range $data $start [expr {$sp - 1}]]

        if {![regexp {/N\s+(\d+)} $hdr -> anzahl]
                || ![regexp {/First\s+(\d+)} $hdr -> first]
                || ![regexp {/Length\s+(\d+)} $hdr -> len]} {
            throw {PDF4TCL} "catPdf: object stream $stmNo in \"$file\" is\
                    missing /N, /First or /Length"
        }
        if {[regexp {/Filter\s*/(\w+)} $hdr -> filter]
                && $filter ne "FlateDecode"} {
            throw {PDF4TCL} "catPdf: object stream $stmNo in \"$file\" uses\
                    /$filter, only /FlateDecode is supported"
        }

        # Exactly ONE line ending after "stream".
        set b [expr {$sp + 6}]
        if {[string index $data $b] eq "\r"} { incr b }
        if {[string index $data $b] eq "\n"} { incr b }
        set roh [string range $data $b [expr {$b + $len - 1}]]
        if {[info exists filter] && $filter eq "FlateDecode"} {
            if {[catch {zlib decompress $roh} plain]} {
                throw {PDF4TCL} "catPdf: cannot decompress object stream\
                        $stmNo in \"$file\": $plain"
            }
        } else {
            set plain $roh
        }

        # Header: 2N integers, "number offset" per object. The offsets are
        # relative to /First.
        set kopf [string range $plain 0 [expr {$first - 1}]]
        set paare [regexp -all -inline {\d+} $kopf]
        if {[llength $paare] < $anzahl * 2} {
            throw {PDF4TCL} "catPdf: object stream $stmNo in \"$file\"\
                    promises $anzahl objects but its header lists\
                    [expr {[llength $paare] / 2}]"
        }

        for {set i 0} {$i < $anzahl} {incr i} {
            set nr  [lindex $paare [expr {$i * 2}]]
            set von [expr {$first + [lindex $paare [expr {$i * 2 + 1}]]}]
            if {$i + 1 < $anzahl} {
                set bis [expr {$first + [lindex $paare [expr {($i+1) * 2 + 1}]] - 1}]
            } else {
                set bis end
            }
            set text [string trim [string range $plain $von $bis]]
            # The rest of the reader expects "N 0 obj ... endobj" around it.
            set objStmBodies($nr) "$nr 0 obj\n$text\nendobj\n"
            dict set xrefs $nr -2      ;# -2: liegt in objStmBodies, nicht im File
        }
    }
    return $xrefs
}

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

    # /DecodeParms with a Predictor: the rows are PNG-filtered, each one
    # prefixed with a filter byte and stored as the difference to the row
    # above. Without undoing that every row after the first is wrong --
    # and the file still parses, so the error shows up as nonsense object
    # numbers rather than as a failure.
    #
    # qpdf writes Predictor 12 by default, so this is the normal case, not
    # an exotic one.
    if {[regexp {/Predictor\s+(\d+)} $hdr -> predictor] && $predictor >= 10} {
        set spalten 1
        if {[regexp {/Columns\s+(\d+)} $hdr -> c]} { set spalten $c }
        set plain [UndoPngPredictor $plain $spalten]
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
    # Container-Nummer -> Liste der Objekte darin.
    set inObjStm {}
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
                2 {
                    # Type 2: the object lives inside an object stream.
                    # Field 2 is the number of the container, field 3 the
                    # position within it -- which is not needed, the header
                    # of the container gives the offsets.
                    dict lappend inObjStm $f2 $objNo
                }
                default { }
            }
        }
    }

    # Objekte aus den Containern holen. Die Container selbst stehen als
    # Typ 1 in derselben Tabelle, sind also schon bekannt.
    if {[dict size $inObjStm]} {
        set xrefs [UnpackObjStreams $data $xrefs $inObjStm $file]
    }

    # The stream dictionary IS the trailer here.
    set dictTxt ""
    if {[regexp {<<(.*)>>} $hdr -> inner]} { set dictTxt "<<$inner>>" }
    return [list [PdfDictToTclDict $dictTxt] $xrefs]
}

proc pdf4tcl::cat::ReadPdf {file} {
    variable objStmBodies
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
        # -2 marks an object that came out of an object stream: it has no
        # byte offset in the file, its text is already in objStmBodies.
        if {$index == -2} {
            if {[info exists objStmBodies($obj)]} {
                dict set pdfdata $obj full $objStmBodies($obj)
            }
            continue
        }
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
    # /Size aus N ableiten statt aus dem Trailer.
    #
    # AppendPdf setzt beide, aber jeder Schritt danach -- DedupObjects,
    # DropUnreachable -- veraendert die Objektzahl und zieht nur N nach.
    # Der Trailer behielt den Wert vom Anhaengen, und qpdf meldete
    # "reported number of objects (19) is not one plus the highest object
    # number (16)". Lesbar blieb die Datei, falsch war sie trotzdem.
    dict set pdfd trailer /Size $N
    # FEHLENDE OBJEKTNUMMERN SIND ERLAUBT.
    #
    # Die Schleife lief von 1 bis N und verlangte jede Nummer. Fehlte
    # eine, brach das Schreiben ab mit
    #
    #     key "6" not known in dictionary
    #
    # Gemessen 07.09.2026 an einer Datei, die PDFium gespeichert hatte:
    # sie enthaelt die Objekte 1-5 und 7-8, die 6 und 9 nicht. Die
    # xref-Tabelle nennt das in TEILABSCHNITTEN ("0 6", dann "7 2"), und
    # das ist normgerecht -- ISO 32000-1 7.5.4 laesst mehrere
    # Teilabschnitte ausdruecklich zu, und ein Verweis auf ein nicht
    # vorhandenes Objekt gilt nach 7.3.10 als "null" und nicht als
    # Fehler. qpdf --check beanstandete die Datei nicht.
    #
    # Eine fehlende Nummer wird darum als FREI eingetragen, wie es die
    # Norm fuer Luecken vorsieht. Sie zu ueberspringen waere falsch: die
    # Tabelle ist positionsbezogen, jede ausgelassene Zeile verschoebe
    # alle folgenden Objektnummern.
    WriteCh $ch "xref\n" pos
    WriteCh $ch "0 $N\n" pos
    WriteCh $ch "0000000000 65535 f \n" pos
    for {set a 1} {$a < $N} {incr a} {
        if {[dict exists $xref $a]} {
            WriteCh $ch [format "%010ld 00000 n \n" [dict get $xref $a]] pos
        } else {
            WriteCh $ch "0000000000 65535 f \n" pos
        }
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
# Bring the XMP packet in line with the /Info dictionary.
#
# PDF carries title, author and their relatives in TWO places: the classic
# /Info dictionary and the XMP packet the catalog points at. Merging keeps
# the catalog of the FIRST document, so its XMP survives -- and a merge
# with -title used to end up claiming two different things at once.
#
# ISO 19005-1 clause 6.7.3 requires them to be equivalent. PDF/A-2 and -3
# dropped that rule, so veraPDF stays silent there however far the two
# drift apart. Measured 2026-08-20 on the same file:
#
#   verapdf -f 1b  ->  FAIL, clause 6.7.3 test 2
#   verapdf -f 2b  ->  PASS
#
# A proof run against 2b therefore measures nothing at all.
#
# THE PACKET IS EDITED, NOT REBUILT. A Factur-X packet carries 3039
# characters, ten namespaces and three rdf:Description blocks, one of them
# the pdfaExtension:schemas that makes the fx: namespace legal in PDF/A.
# Rebuilding from the six Info fields would silently drop it and the
# invoice would stop being an invoice. So: replace the property when it is
# there, insert it into the first rdf:Description when it is not, and
# leave every other byte alone.
#
# The metadata stream is uncompressed -- ISO 32000 clause 7.11.3 asks for
# that so a tool can find it without understanding PDF -- which is why
# plain text editing is enough here, with no XML parser and no inflate.
proc pdf4tcl::cat::SyncXmp {pdfd info} {
    if {![dict size $info]} { return $pdfd }
    if {![dict exists $pdfd trailer /Root]} { return $pdfd }

    set rootId [lindex [dict get $pdfd trailer /Root] 0]
    if {![dict exists $pdfd $rootId]} { return $pdfd }
    set root [dict get $pdfd $rootId full]
    if {![regexp {/Metadata\s+(\d+)\s+\d+\s+R} $root -> metaId]} { return $pdfd }
    if {![dict exists $pdfd $metaId]} { return $pdfd }

    set obj [dict get $pdfd $metaId]
    if {![dict exists $obj full]} { return $pdfd }
    # Nicht "full" nennen: derselbe Name ist auch der Woerterbuchschluessel,
    # und nagelfar meldet die Verwechslungsgefahr zu Recht.
    set paket [dict get $obj full]

    # An encrypted or compressed packet is not text -- leave it rather than
    # write nonsense into it.
    if {[string first "<?xpacket" $paket] < 0} { return $pdfd }

    # Info key -> XMP property. The shape differs per property, so each one
    # carries its own opening and closing text.
    #   Title     dc:title        Alt with x-default
    #   Author    dc:creator      Seq
    #   Subject   dc:description  Alt with x-default
    #   Keywords  pdf:Keywords    plain
    #   Creator   xmp:CreatorTool plain
    #   Producer  pdf:Producer    plain
    set formen {
        Title    {dc:title       {<dc:title><rdf:Alt>
    <rdf:li xml:lang="x-default">} {</rdf:li>
   </rdf:Alt></dc:title>}}
        Author   {dc:creator     {<dc:creator><rdf:Seq>
    <rdf:li>} {</rdf:li>
   </rdf:Seq></dc:creator>}}
        Subject  {dc:description {<dc:description><rdf:Alt>
    <rdf:li xml:lang="x-default">} {</rdf:li>
   </rdf:Alt></dc:description>}}
        Keywords {pdf:Keywords    <pdf:Keywords>    </pdf:Keywords>}
        Creator  {xmp:CreatorTool <xmp:CreatorTool> </xmp:CreatorTool>}
        Producer {pdf:Producer    <pdf:Producer>    </pdf:Producer>}
    }

    set neu $paket
    dict for {key val} $info {
        if {![dict exists $formen $key]} { continue }
        lassign [dict get $formen $key] tag auf zu
        # Everything from the opening tag to its closing counterpart,
        # whatever sits between -- rdf:Alt, rdf:Seq or plain text.
        set muster "<$tag>.*?</$tag>"
        if {$val eq ""} {
            # An empty value REMOVES the entry, in both places. A packet
            # that keeps claiming a title the /Info no longer has is worse
            # than one that says nothing.
            regsub -- "\[ \t\]*$muster\n?" $neu "" neu
            continue
        }
        # ALS UTF-8-BYTES EINSETZEN, nicht als Tcl-Zeichen. WritePdf
        # oeffnet den Kanal mit "wb"; ein Zeichen ueber 127 ginge dort als
        # EIN Byte hinaus, und ein XMP-Paket muss UTF-8 sein (ISO 32000
        # Klausel 7.11.3). Gemessen mit dem Titel "Grosse Uebergabe":
        # ohne die Umwandlung stehen 0xdf und 0xdc roh in der Datei, das
        # Paket ist kein gueltiges UTF-8 mehr, /Length nennt 663 Bytes bei
        # tatsaechlich 661, und veraPDF findet das endstream nicht mehr.
        # Dieselbe Vorkehrung steht in main.tcl an der Stelle, die das
        # Paket erzeugt.
        set text [encoding convertto utf-8 "$auf[XmlEsc $val]$zu"]
        if {[regexp -- $muster $neu]} {
            regsub -- $muster $neu [string map {\\ \\\\ & \\&} $text] neu
        } else {
            # Nothing to replace: the first document never had the
            # property. Plain replacement leaves the file inconsistent
            # anyway -- veraPDF then reports
            #   XMP dc:title['x-default'] = null
            # -- so insert it into the first rdf:Description instead.
            # Its opening tag ends at the first ">" after rdf:about, which
            # may sit several lines down because the namespaces are listed
            # one per line.
            if {[regexp -indices {<rdf:Description[^>]*>} $neu bereich]} {
                set ende [lindex $bereich 1]
                set neu [string replace $neu $ende $ende ">\n   $text"]
            }
        }
    }

    if {$neu eq $paket} { return $pdfd }

    # /Length counts BYTES, not characters. A title with an umlaut in it
    # makes the two differ, and a wrong /Length truncates the packet.
    # /Length zaehlt BYTES. Der Text ist oben bereits als UTF-8-Bytes
    # eingesetzt worden, deshalb ist "string length" hier schon die
    # Byteanzahl -- eine zweite Umwandlung wuerde die Umlaute ein zweites
    # Mal kodieren und die Zahl wieder verfaelschen.
    if {[regexp {stream\n(.*)\nendstream} $neu -> strom]} {
        regsub {/Length\s+\d+} $neu "/Length [string length $strom]" neu
    }

    dict set pdfd $metaId full $neu
    return $pdfd
}

# XML escaping for values that go into the packet. Without it a title
# containing "&" or "<" produces a packet no parser will read -- and an
# unreadable packet is worse than an inconsistent one.
proc pdf4tcl::cat::XmlEsc {s} {
    return [string map {& &amp; < &lt; > &gt; \" &quot;} $s]
}

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
        # N mitziehen, sonst schreibt WritePdf einen /Size, der das neue
        # Objekt nicht mitzaehlt.
        if {[dict exists $pdfd N] && [dict get $pdfd N] <= $infoId} {
            dict set pdfd N [expr {$infoId + 1}]
        }
        dict set pdfd trailer /Info "$infoId 0 R"
    }
    dict set pdfd $infoId full "$infoId 0 obj\n$body\nendobj\n"
    return $pdfd
}

# Drop objects nothing points at.
#
# Merging takes over every object of every input, including the /Info
# dictionary of the appended documents -- the trailer names only one, so
# the others stay behind. No reader sees them, but they cost a few hundred
# bytes each and anyone grepping the file finds a title that applies to
# nothing. A test of mine measured the wrong one because of it.
#
# Reachability from the trailer, not a list of types: whatever the merge
# leaves behind is caught, not just /Info.
#
# Pages and structure elements are kept whatever the scan says. They hang
# together through /Kids and /P chains that this simple reference scan can
# follow but should not be trusted to -- losing a page to save a hundred
# bytes is a bad trade.
proc pdf4tcl::cat::DropUnreachable {pdfd} {
    if {![dict exists $pdfd trailer]} { return $pdfd }

    # Start at the trailer and follow every "N 0 R" found.
    set offen {}
    foreach {k v} [dict get $pdfd trailer] {
        foreach ref [regexp -all -inline {(\d+)\s+\d+\s+R} $v] {
            if {[string is integer -strict $ref]} { lappend offen $ref }
        }
    }

    set erreichbar {}
    while {[llength $offen]} {
        set o [lindex $offen 0]
        set offen [lrange $offen 1 end]
        if {[dict exists $erreichbar $o]} { continue }
        if {![dict exists $pdfd $o]} { continue }
        dict set erreichbar $o 1
        foreach ref [regexp -all -inline {(\d+)\s+\d+\s+R} \
                [dict get $pdfd $o full]] {
            if {[string is integer -strict $ref]
                    && ![dict exists $erreichbar $ref]} {
                lappend offen $ref
            }
        }
    }

    set weg {}
    foreach key [dict keys $pdfd] {
        if {![string is digit -strict $key]} { continue }
        if {[dict exists $erreichbar $key]} { continue }
        set body [dict get $pdfd $key full]
        # Seiten und Strukturelemente bleiben, komme was wolle.
        if {[regexp {/Type\s*/(Page|Pages|Catalog|StructTreeRoot|StructElem)\M} \
                $body]} {
            continue
        }
        lappend weg $key
    }
    if {![llength $weg]} { return $pdfd }

    foreach key $weg { dict unset pdfd $key }

    # Dropping objects leaves gaps, and WritePdf writes one xref entry per
    # number from 1 to N. Renumber densely -- same reasoning as in
    # DedupObjects.
    set numerisch {}
    foreach key [dict keys $pdfd] {
        if {[string is digit -strict $key]} { lappend numerisch $key }
    }
    set renumber {}
    set next 1
    foreach key [lsort -integer $numerisch] {
        ##nagelfar ignore Found constant
        dict set renumber $key $next
        incr next
    }

    set out {}
    foreach {key val} $pdfd {
        if {![string is digit -strict $key]} {
            if {$key eq "trailer"} {
                set neu {}
                foreach {tk tv} $val {
                    lappend neu $tk [RemapRefs $tv $renumber]
                }
                set val $neu
            } elseif {$key eq "N"} {
                set val $next
            }
            lappend out $key $val
            continue
        }
        set neuNr [dict get $renumber $key]
        set body [RemapRefs [dict get $val full] $renumber]
        regsub {^\s*\d+\s+(\d+)\s+obj} $body "$neuNr \\1 obj" body
        lappend out $neuNr [dict create full $body]
    }
    set pdfd $out
    if {[dict exists $pdfd trailer /Root]} {
        dict set pdfd root [PdfObjToTclDict \
                [dict get $pdfd [lindex [dict get $pdfd trailer /Root] 0] full]]
    }
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
    # Vor SetInfo: das raeumt die verwaisten /Info der angehaengten
    # Dokumente weg, und SetInfo schreibt danach in das, worauf der
    # Trailer zeigt.
    set pdf1 [pdf4tcl::cat::DropUnreachable $pdf1]
    set pdf1 [pdf4tcl::cat::SetInfo $pdf1 $info]
    # Und dieselben Werte in das XMP-Paket, auf das der Katalog zeigt.
    # Nach SetInfo, damit beide Stellen aus derselben Quelle stammen;
    # ISO 19005-1 Klausel 6.7.3 verlangt Gleichheit.
    set pdf1 [pdf4tcl::cat::SyncXmp $pdf1 $info]
    # Ein leerer Wert loescht den Eintrag, und sind ALLE Eintraege weg,
    # nimmt SetInfo den /Info-Verweis aus dem Trailer. Das Objekt selbst
    # bleibt dann liegen -- der Durchgang oben lief, bevor es verwaist
    # war. Gemessen am 2026-08-20: nach `catPdf -title ""` stand
    # `/Title (Titel von Teil A)` weiterhin in der Datei, ohne dass ein
    # Leser es je zeigt. Genau der Fall, den DropUnreachable verhindern
    # soll: wer die Datei durchsucht, findet einen Titel, der fuer nichts
    # mehr gilt.
    #
    # Nur wenn tatsaechlich etwas entfernt wurde -- ein zweiter Durchgang
    # ueber jedes Objekt kostet bei grossen Zusammenfuehrungen Zeit und
    # brauecht sonst niemand.
    set entfernt 0
    dict for {k v} $info { if {$v eq ""} { set entfernt 1 } }
    if {$entfernt} {
        set pdf1 [pdf4tcl::cat::DropUnreachable $pdf1]
    }
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
# Since 0.9.4.64 the appearance stream is rebuilt along with /V, so a
# print path that renders the appearance puts the new value on the paper.
#
# /NeedAppearances is set ONLY where the stream stays old (see below).
# Setting it after drawing the stream throws the own work away, and
# worse: measured 08.09.2026, filling one text field made an UNTOUCHED
# check box lose its border, because PDFium rebuilds every Off
# appearance under that flag.
#
# NOT rebuilt, and deliberately so: comb fields WITHOUT /MaxLen (the
# cell width hangs on it, and a foreign form may omit it while carrying
# the flag), password fields (the value would sit in the file in clear),
# choice fields, and check boxes and radio buttons (they have two states
# and /AS switches between them, which fillForms already handles).
#
# REBUILT since 0.9.4.64, contrary to what this comment said until
# 0.9.4.66: multi-line fields (with the same line breaking addForm uses)
# and comb fields WITH /MaxLen. A dead comment is believed -- this one
# warned about that itself a few lines down.
#
# There the old stream stays as it was -- a half-drawn comb field would
# be worse
# than an undrawn one. In those cases the value is present in /V and the
# appearance is the old one, exactly as before .64.
#
# This comment used to say "What this does NOT do: build appearance
# streams." It was right until .63 and wrong afterwards -- a stale
# comment is worse than none, because it is believed.
proc pdf4tcl::fillForms {inFile outFile values} {
    if {![file exists $inFile]} {
        throw {PDF4TCL} "No such file: $inFile"
    }
    if {![dict size $values]} { return 0 }
    set pdf [pdf4tcl::cat::ReadPdf $inFile]

    set N [dict get $pdf N]
    set gefuellt 0
    # Musste irgendwo der alte Strom stehenbleiben? Nur dann wird
    # /NeedAppearances gesetzt -- siehe unten.
    set brauchtFlagge 0
    set gesehen {}

    # DYNAMISCHES XFA ablehnen.
    #
    # Bei einem XFA-Formular steht der Inhalt als XML unter /XFA. Es gibt
    # zwei Sorten, und nur bei einer ist das Fuellen sinnlos:
    #
    #   hybrid    XFA UND gueltige AcroForm-Felder. Ein Betrachter ohne
    #             XFA nimmt die AcroForm-Seite, /V wirkt. Das laeuft
    #             hier weiter wie bisher.
    #   dynamisch /NeedsRendering true im Katalog (ISO 32000-1 12.7.8,
    #             Tabelle 28). Die AcroForm-Felder sind eine Attrappe,
    #             der Betrachter baut die Seiten aus dem XML. Wer hier
    #             /V setzt, aendert am Sichtbaren NICHTS.
    #
    # Bis .63 lief der dynamische Fall klaglos durch und meldete einen
    # Erfolg, den es nicht gab -- gemessen an einer eigens gebauten
    # Datei. Ein stiller Fehlschlag ist schlimmer als eine Absage.
    # Die zwei Merkmale stehen an ZWEI Stellen, und nur eine davon ist der
    # Katalog:
    #
    #   /NeedsRendering   Katalog        (ISO 32000-1 Tabelle 28)
    #   /XFA              /AcroForm      (Tabelle 218)
    #
    # Der erste Anlauf suchte BEIDE im Katalogkoerper. Das trifft nur
    # eine Datei, die AcroForm direkt eingebettet hat -- pdf4tcl selbst
    # schreibt "/AcroForm 12 0 R", und die allermeisten Erzeuger auch.
    # Gemessen an einer Datei mit der normgerechten Lage: still
    # durchgelaufen, n=1. Die eigene Testdatei fing es nicht, weil sie
    # das Flag zum Katalog gelegt hatte -- ein Test, der den Fall
    # konstruiert, den der Code trifft, statt den, der vorkommt.
    #
    # /NeedsRendering wird auch am AcroForm-Objekt akzeptiert. Dort
    # gehoert es nicht hin, aber wer es dort schreibt, meint dasselbe --
    # beim LESEN grosszuegig zu sein kostet nichts und faengt einen Fall
    # mehr.
    set rootId1 [lindex [dict get $pdf trailer /Root] 0]
    if {[dict exists $pdf $rootId1]} {
        set rb1 [dict get $pdf $rootId1 full]
        set afBody $rb1
        if {[regexp {/AcroForm\s+(\d+)\s+0\s+R} $rb1 -> afId]
                && [dict exists $pdf $afId]} {
            append afBody "\n" [dict get $pdf $afId full]
        }
        if {[regexp {/NeedsRendering\s+true} $afBody]
                && [string match {*/XFA*} $afBody]} {
            throw {PDF4TCL} "fillForms: \"$inFile\" is a dynamic XFA form\
                    (/NeedsRendering true). Its AcroForm fields are a\
                    placeholder; the viewer builds the pages from the XML\
                    under /XFA, so setting /V would change nothing visible."
        }
    }

    # Die Schriften des Formulars aus /AcroForm /DR /Font.
    #
    # Ein Appearance-Strom muss die Schrift, die er benutzt, in seinen
    # eigenen /Resources nennen. Welche das ist, steht im /DA des Feldes
    # -- aber nur als RESSOURCENNAME ("/Helv"), und wo dieser Name
    # hinzeigt, weiss allein das /DR des Formulars. Ohne diese Tabelle
    # laesst sich kein gueltiger Strom bauen.
    # /AcroForm liegt entweder in einem eigenen Objekt ODER direkt im
    # Katalog. Beides kommt vor -- pdf4tcl schreibt "/AcroForm 12 0 R",
    # eine handgeschriebene Datei oft das Woerterbuch selbst. Der erste
    # Anlauf sah nur die indirekte Form, und dann blieb die Schrifttabelle
    # leer: /V wurde gesetzt, ein Strom entstand nicht, und gemeldet wurde
    # trotzdem "1 gefuellt". Gemessen an tests/fixtures/form-multiwidget.pdf.
    set drFonts [dict create]
    set rootId0 [lindex [dict get $pdf trailer /Root] 0]
    if {[dict exists $pdf $rootId0]} {
        set rb [dict get $pdf $rootId0 full]
        set ab $rb
        if {[regexp {/AcroForm\s+(\d+)\s+0\s+R} $rb -> acroId]
                && [dict exists $pdf $acroId]} {
            set ab [dict get $pdf $acroId full]
        }
        set dr ""
        if {[regexp {/DR\s+(\d+)\s+0\s+R} $ab -> drId]
                && [dict exists $pdf $drId]} {
            set dr [dict get $pdf $drId full]
        } elseif {[regexp {/DR\s*<<(.*)} $ab -> dr]} {
            # Direkt eingebettet: bis zum Ende des Objekts reicht, denn
            # gesucht wird nur nach "/Name n 0 R", und ausserhalb des /DR
            # stehen davon keine.
        }
        foreach {ganz nam num} [regexp -all -inline \
                {/([A-Za-z0-9#]+)\s+(\d+)\s+0\s+R} $dr] {
            dict set drFonts $nam "$num 0 R"
        }
    }

    # Ueber den FELDBAUM. Bis .64 wurde je Widget mit /T gesucht -- ein
    # Feld mit mehreren Widgets fiel ganz durch, ein verschachtelter Name
    # kam ohne seinen Vater. Siehe FormFieldTree.
    dict for {fo e} [pdf4tcl::FormFieldTree $pdf] {
        set id [dict get $e name]
        if {$id eq ""} continue
        lappend gesehen $id
        if {![dict exists $values $id]} continue

        set wert [dict get $values $id]
        set istBtn [expr {[dict get $e FT] eq "/Btn"}]
        set body [dict get $pdf $fo full]

        if {$istBtn} {
            # A state name, written as a name object. Also set /AS, or the
            # box keeps showing its old appearance.
            if {![string match {/*} $wert]} { set wert "/$wert" }
            set body [FormSetKey $body /V $wert]
            dict set pdf $fo full $body
            # /AS gehoert an JEDES Widget, nicht ans Feld: es sagt, welche
            # Erscheinung dieses eine Kaestchen gerade zeigt. Bei einem
            # Feld mit einem Widget ist das dasselbe Objekt.
            foreach w [dict get $e widgets] {
                if {![dict exists $pdf $w]} continue
                dict set pdf $w full \
                        [FormSetKey [dict get $pdf $w full] /AS $wert]
            }
            incr gefuellt
            continue
        }

        # QuoteString liefert die Klammern schon mit -- sie noch einmal
        # zu setzen ergab ((Meier)) und damit einen Wert, den kein
        # Leser anzeigt.
        set body [FormSetKey $body /V [::pdf4tcl::QuoteString $wert]]
        dict set pdf $fo full $body

        # Und den Appearance-Strom mitziehen, JE WIDGET.
        #
        # Jedes Widget hat sein eigenes /Rect und sein eigenes /AP -- beim
        # Durchschlagsatz vier verschiedene auf vier Blaettern. Ein Strom
        # fuer alle waere an drei Stellen falsch positioniert.
        set flags [dict get $e Ff]
        if {$flags eq ""} { set flags 0 }
        set mehrzeilig [expr {$flags & 4096}]
        set comb       [expr {$flags & 16777216}]
        # Bit 14: Kennwortfeld (ISO 32000-1 12.7.4.3, Tabelle 228).
        #
        # KEIN Strom fuer ein Kennwortfeld. Der Wert stuende sonst im
        # KLARTEXT in der Datei, waehrend der Bildschirm Punkte zeigt --
        # gemessen an demo-forms-tk.tcl: "(Muster pw_empty) Tj" stand im
        # Strom.
        #
        # Punkte statt Klartext zu zeichnen waere die andere
        # Moeglichkeit, aber sie ist schlechter: der Wert steht ohnehin
        # in /V, und ein gezeichneter Punktestrom taeuschte vor, die
        # Datei gaebe das Kennwort nicht preis. Wer ein Kennwort in eine
        # PDF-Datei schreibt, soll wissen, dass es darin steht -- und
        # nicht auch noch ein zweites Mal.
        set kennwort [expr {$flags & 8192}]
        # Comb und Kennwort bleiben aussen vor -- Comb, weil die
        # Zellenbreite an /MaxLen haengt, das ein fremdes Formular
        # weglassen kann; Kennwort, weil der Wert sonst im Klartext in
        # der Datei staende. MEHRZEILIG geht seit 0.9.4.64, mit
        # demselben Umbruch, den addForm beim Erzeugen benutzt.
        # Comb geht, WENN /MaxLen dasteht -- ohne Teiler gibt es keine
        # Zellen, und dann bleibt der alte Strom. Kennwort bleibt aussen
        # vor, sonst staende der Wert im Klartext in der Datei.
        set maxlen [dict get $e MaxLen]
        if {$comb && ![string is integer -strict $maxlen]} {
            set brauchtFlagge 1
            incr gefuellt ; continue
        }
        if {$kennwort} { set brauchtFlagge 1 ; incr gefuellt ; continue }

        # Ein Auswahlfeld nimmt nur, was in /Opt steht.
        #
        # Bis 0.9.4.64 schrieb fillForms JEDEN Wert in /V und meldete
        # einen Erfolg -- gemessen: {artikel "Gibt es nicht"} ergab
        # "1 gefuellt" und ein /V, das in keiner Optionsliste steht. Das
        # Feld traegt damit einen ungueltigen Zustand, und ein
        # Betrachter zeigt je nach Laune nichts oder den alten Eintrag.
        #
        # Geprueft wird gegen BEIDE Spalten: ein fremdes Formular kann
        # den Exportwert oder die Beschriftung meinen, und wer nur eine
        # davon nimmt, lehnt gueltige Werte ab.
        # Der LEERE Wert ist erlaubt: er heisst "nichts gewaehlt", und
        # /V () steht so in jedem frisch erzeugten Auswahlfeld.
        #
        # Meine erste Fassung lehnte ihn ab, und damit brach der
        # Rundlauf in demo/demo-forms.tcl: der liest ALLE Felder mit
        # getForms aus und schreibt sie zurueck, das leere
        # Auswahlfeld eingeschlossen. Gemeldet 07.09.2026.
        #
        # Eine Pruefung, die einen gueltigen Zustand verbietet, ist
        # schlimmer als keine -- sie bricht Arbeitsablaeufe, die vorher
        # liefen.
        if {$wert ne "" && [dict get $e FT] eq "/Ch"
                && [llength [dict get $e Opt]]} {
            set erlaubt {}
            set passt 0
            foreach paar [dict get $e Opt] {
                lassign $paar ex la
                lappend erlaubt $la
                if {$wert eq $ex || $wert eq $la} { set passt 1 }
            }
            if {!$passt} {
                throw {PDF4TCL} "fillForms: \"$wert\" is not an option of\
                        \"$id\"; allowed: $erlaubt"
            }
        }

        # NUR Textfelder. Ein Auswahlfeld (/Ch) hat einen ganz anderen
        # Strom: addForm zeichnet ihm einen weissen Kasten mit Rahmen,
        # beim Kombinationsfeld dazu die Pfeilflaeche.
        #
        # Bis hierher pruefte diese Stelle nur die FLAGGEN und nicht den
        # Typ -- ein Listenfeld lief als Textfeld durch, und der neue
        # Strom warf Kasten und Rahmen weg. Gemessen:
        #
        #   vorher:  /Tx BMC 1 1 1 rg 0 0 150 40 re f ... (Bremen) Tj
        #   nachher: /Tx BMC BT ... (Vreden) Tj
        #
        # Der Wert war richtig und das Feld sah aus wie nichts. Ein
        # Rueckschritt, den ich mit dem Strombauen selbst eingebaut
        # hatte.
        #
        # Auswahlfelder bleiben darum aussen vor. Beim
        # Kombinationsfeld ist das ohnehin richtig: addForm laesst dort
        # den Text mit Absicht aus dem Strom, weil der Betrachter ihn
        # aus /DA und /V zeichnet -- stuende er auch im Strom, erschiene
        # er doppelt.
        if {[dict get $e FT] ne "/Tx"} {
            # Auswahlfeld oder Knopf: /V ist gesetzt, der Strom bleibt
            # alt. Genau dafuer ist die Flagge da.
            if {[dict get $e FT] eq "/Ch"} { set brauchtFlagge 1 }
            incr gefuellt ; continue
        }

        set da [dict get $e DA]
        set da [string trim $da "()"]
        if {$da eq ""} { set brauchtFlagge 1 ; incr gefuellt ; continue }
        set resName ""
        regexp {/([A-Za-z0-9#]+)\s+[0-9.]+\s+Tf} $da -> resName
        if {$resName eq "" || ![dict exists $drFonts $resName]} {
            # Ohne auffindbare Schrift kein Strom -- dann muss der
            # Betrachter ran.
            set brauchtFlagge 1
            incr gefuellt ; continue
        }
        set q [dict get $e Q]
        if {![string is integer -strict $q]} { set q 0 }

        foreach w [dict get $e widgets] {
            if {![dict exists $pdf $w]} continue
            set wb [dict get $pdf $w full]
            if {![regexp {/AP\s*<<[^>]*?/N\s+(\d+)\s+0\s+R} $wb -> apId]} continue
            if {![dict exists $pdf $apId]} continue
            if {![regexp {/Rect\s*\[([^\]]*)\]} $wb -> rect]} continue
            set neuStrom [::pdf4tcl::FormBuildTextAP $da $rect $wert \
                    [dict get $drFonts $resName] $resName $q \
                    [expr {$mehrzeilig ? 1 : 0}] \
                    [expr {$comb ? $maxlen : 0}]]
            if {$neuStrom ne ""} {
                dict set pdf $apId full "$apId 0 obj\n$neuStrom\nendobj"
            } else {
                # Fuer dieses Feld ist der Strom ALT geblieben -- Comb
                # ohne /MaxLen, Kennwort, Auswahlfeld. Nur dann braucht
                # es die Flagge. Siehe unten.
                set brauchtFlagge 1
            }
        }
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

    # /NeedAppearances NUR, WENN WIR DEN STROM NICHT SELBST GEBAUT HABEN.
    #
    # Die Flagge sagt dem Betrachter: bau die Erscheinungen neu. Wer sie
    # setzt, obwohl er gerade selbst gezeichnet hat, wirft die eigene
    # Arbeit weg -- und mehr als das.
    #
    # Gemessen 08.09.2026: EIN Textfeld zu fuellen liess ein UNBERUEHRTES
    # Kaestchen seinen Rahmen verlieren.
    #
    #   vor  fillForms:  f_text 38   f_check 37   NeedApp 0
    #   nach fillForms:  f_text 114  f_check  4   NeedApp 1
    #
    # PDFium baut unter der Flagge die Off-Erscheinung neu und liefert
    # eine leere (tclpdfium 2.96). Der Strom stand unveraendert in der
    # Datei -- die Flagge allein hat ihn unsichtbar gemacht.
    #
    # Gebraucht wird sie weiterhin dort, wo fillForms den Strom NICHT
    # neu baut: Comb ohne /MaxLen, Kennwort, Auswahlfeld. Dann traegt
    # das Feld den neuen Wert und zeigt die alte Erscheinung, und ohne
    # die Flagge saehe man ihn nirgends.
    set rootId [lindex [dict get $pdf trailer /Root] 0]
    if {[dict exists $pdf $rootId]} {
        set rootBody [dict get $pdf $rootId full]
        if {[regexp {/AcroForm\s+(\d+)\s+0\s+R} $rootBody -> acroId]} {
            if {[dict exists $pdf $acroId] && $brauchtFlagge} {
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

# Den Feldbaum eines Formulars aufbauen.
#
# Rueckgabe: dict fieldObj -> {name N widgets {o1 o2 ...} body B}
#
# WARUM DAS NOETIG IST: getForms und fillForms suchten das /T am WIDGET.
# Das trifft den haeufigen Fall -- Feld und Widget in einem Objekt --, aber
# nicht die zwei anderen, die in der Norm stehen:
#
#   * EIN Feld, MEHRERE Widgets (ISO 32000-1 12.7.4.1). Der CMR-Frachtbrief:
#     ein Feld erscheint auf vier Blaettern, /T und /V stehen am Vater,
#     darunter haengen Widgets mit eigenem /Rect und eigenem /AP. Bis .64
#     wurde so ein Feld GAR NICHT gefunden -- getForms gab ein leeres dict,
#     fillForms meldete "no such field". Gemessen an
#     tests/fixtures/form-multiwidget.pdf.
#
#   * VERSCHACHTELTE Namen (12.7.3.2). Der volle Name ist die Kette der /T
#     vom Wurzelfeld herab: /T "person" am Vater und /T "city" am Kind
#     ergibt "person.city". Bis .64 kam nur "city" heraus -- und in einem
#     Formular mit "rechnung.betrag" und "lieferung.betrag" hiessen dann
#     BEIDE Felder "betrag", und eines ueberschrieb das andere im dict.
#
# /FT, /Ff, /V und /DA duerfen vom Vater geerbt werden (12.7.3.1); wer nur
# das Kind ansieht, haelt ein Textfeld fuer typenlos.
proc pdf4tcl::FormFieldTree {pdf} {
    set N [dict get $pdf N]
    set roh [dict create]
    for {set o 1} {$o <= $N} {incr o} {
        if {![dict exists $pdf $o]} continue
        set objtext [dict get $pdf $o full]
        # Nur Objekte, die ueberhaupt nach Formular aussehen.
        if {![string match {*/Widget*} $objtext]
                && ![string match {*/FT*} $objtext]
                && ![string match {*/Kids*} $objtext]} continue
        set eintrag [dict create body $objtext parent "" name ""]
        # /T aus dem ROHTEXT: PdfObjToTclDict zerlegt an Leerzeichen, und
        # ein Name mit Leerzeichen -- "Given Name Text Box", so schreibt
        # OpenOffice -- kaeme dort zerrissen an.
        if {[regexp {/T\s*\(((?:\\.|[^\\)])*)\)} $objtext -> t]} {
            dict set eintrag name [FormUnquoteString "($t)"]
        }
        if {[regexp {/Parent\s+(\d+)\s+0\s+R} $objtext -> pa]} {
            dict set eintrag parent $pa
        }
        dict set roh $o $eintrag
    }

    # Wer ist Widget, wer ist Feld?
    #
    # Ein Objekt mit /Kids hat Widgets unter sich. Ein Objekt mit
    # /Subtype /Widget ist eines -- und wenn es zugleich ein /T traegt,
    # ist es beides in einem.
    set felder [dict create]
    dict for {o e} $roh {
        set objtext [dict get $e body]
        set istWidget [string match {*/Subtype*/Widget*} $objtext]
        set hatKids   [string match {*/Kids*} $objtext]
        if {[dict get $e name] eq ""} continue
        if {$istWidget && !$hatKids} {
            dict set felder $o [dict create widgets [list $o]]
        } elseif {$hatKids} {
            set kids {}
            foreach {ganz num} [regexp -all -inline {(\d+)\s+0\s+R} \
                    [lindex [regexp -inline {/Kids\s*\[([^\]]*)\]} $objtext] 1]] {
                # Nur Kinder OHNE eigenes /T sind Widgets dieses Feldes;
                # ein Kind MIT /T ist ein eigenes Feld darunter.
                if {[dict exists $roh $num]
                        && [dict get $roh $num name] ne ""} continue
                lappend kids $num
            }
            if {[llength $kids]} {
                dict set felder $o [dict create widgets $kids]
            }
        }
    }

    # Den vollen Namen aus der /Parent-Kette bilden.
    set ergebnis [dict create]
    dict for {o f} $felder {
        set teile [list [dict get $roh $o name]]
        set p [dict get $roh $o parent]
        set tiefe 0
        # Die Zaehlung ist kein Schmuck: eine Datei mit einer Schleife in
        # der /Parent-Kette wuerde hier sonst haengen, und ein haengendes
        # getForms ist schlimmer als eines, das etwas Falsches meldet.
        while {$p ne "" && [dict exists $roh $p] && [incr tiefe] < 32} {
            set pn [dict get $roh $p name]
            if {$pn ne ""} { set teile [linsert $teile 0 $pn] }
            set p [dict get $roh $p parent]
        }
        dict set ergebnis $o name [join $teile "."]
        dict set ergebnis $o widgets [dict get $f widgets]
        dict set ergebnis $o body [dict get $roh $o body]
        # Geerbte Schluessel: erst am Feld, sonst die Kette hinauf.
        # /TU gehoert dazu: der Name FUER MENSCHEN, den ein Betrachter
        # als Erklaerung anzeigt. addForm schreibt ihn (-tooltip), und
        # getForms verschwieg ihn -- pdf4tcl schrieb also eine Auskunft,
        # die es selbst nicht wieder herausgab. Gemessen 07.09.2026.
        foreach schluessel {/FT /Ff /V /DA /Q /MaxLen /TU} {
            set wert ""
            set q $o
            set t2 0
            while {$q ne "" && [dict exists $roh $q] && [incr t2] < 32} {
                set objBody [dict get $roh $q body]
                if {[regexp "\\$schluessel\\s*(\\(((?:\\\\.|\[^\\\\)\])*)\\)|/\\w+|-?\\d+)" \
                        $objBody -> gefunden]} {
                    set wert $gefunden
                    break
                }
                set q [dict get $roh $q parent]
            }
            dict set ergebnis $o [string range $schluessel 1 end] $wert
        }
        # Die Auswahlwerte -- ebenfalls vererbbar, darum die Kette
        # hinauf.
        set opt {}
        set q2 $o
        set t3 0
        while {$q2 ne "" && [dict exists $roh $q2] && [incr t3] < 32} {
            set opt [FormReadOpt [dict get $roh $q2 body]]
            if {[llength $opt]} break
            set q2 [dict get $roh $q2 parent]
        }
        dict set ergebnis $o Opt $opt
    }
    return $ergebnis
}

# Textbreite aus den Metriken einer Standardschrift, in Punkt.
#
# 0, wenn die Schrift nicht dabei ist -- der Aufrufer bleibt dann
# linksbuendig. Ein geschaetzter Wert waere schlimmer: eine Ausrichtung,
# die falsch ist und richtig aussieht.
proc pdf4tcl::FormStdWidth {text size {basefont Helvetica}} {
    variable ::pdf4tcl::BFA
    if {![info exists BFA($basefont,charWidths)]} { return 0.0 }
    set breiten $BFA($basefont,charWidths)
    set summe 0.0
    foreach ch [split $text ""] {
        set cp [scan $ch %c]
        if {[dict exists $breiten $cp]} {
            set summe [expr {$summe + [dict get $breiten $cp]}]
        } else {
            # Ein Zeichen, das die Schrift nicht hat, zeichnet pdf4tcl als
            # "?" -- also hier auch dessen Breite zaehlen und nicht null.
            if {[dict exists $breiten 63]} {
                set summe [expr {$summe + [dict get $breiten 63]}]
            }
        }
    }
    return [expr {$summe * $size / 1000.0}]
}

# Die erlaubten Werte eines Auswahlfeldes aus /Opt.
#
# Rueckgabe: Liste von {exportwert beschriftung}. Bei der einfachen Form
# sind beide gleich.
#
# ZWEI SCHREIBWEISEN, beide erlaubt (ISO 32000-1 12.7.4.4):
#
#   /Opt [(Alpha) (Beta)]                  -- nur Beschriftungen
#   /Opt [[(a) (Alpha)] [(b) (Beta)]]      -- Exportwert und Beschriftung
#
# pdf4tcl schreibt nur die erste. getForms liest aber auch FREMDE
# Formulare, und dort kommt die zweite vor -- wer sie mit einem groben
# Muster liest, bekommt "a" und "Alpha" als zwei getrennte Werte und
# haelt ein Feld mit zwei Eintraegen fuer eines mit vieren.
proc pdf4tcl::FormReadOpt {body} {
    if {![regexp {/Opt\s*\[} $body]} { return {} }
    # Von der oeffnenden Klammer an zeichenweise bis zur passenden
    # schliessenden -- ein Muster mit [^\]]* bricht bei der
    # verschachtelten Form an der ersten inneren Klammer ab.
    set start [string first "/Opt" $body]
    set i [string first "\[" $body $start]
    if {$i < 0} { return {} }
    set tiefe 0
    set ende -1
    for {set j $i} {$j < [string length $body]} {incr j} {
        set ch [string index $body $j]
        if {$ch eq "\["} { incr tiefe }
        if {$ch eq "\]"} {
            incr tiefe -1
            if {$tiefe == 0} { set ende $j ; break }
        }
    }
    if {$ende < 0} { return {} }
    set inhalt [string range $body [expr {$i + 1}] [expr {$ende - 1}]]

    set aus {}
    # Erst die Paare: [(x) (y)]
    set rest $inhalt
    while {[regexp -indices {\[\s*\(((?:\\.|[^\\)])*)\)\s*\(((?:\\.|[^\\)])*)\)\s*\]} \
            $rest -> a b]} {
        set ex [string range $rest {*}$a]
        set la [string range $rest {*}$b]
        lappend aus [list [FormUnquoteString "($ex)"] \
                          [FormUnquoteString "($la)"]]
        set rest [string replace $rest 0 [lindex $b 1]]
    }
    if {[llength $aus]} { return $aus }

    # Sonst die einfache Form: nur Zeichenketten.
    foreach {ganz txt} [regexp -all -inline {\(((?:\\.|[^\\)])*)\)} $inhalt] {
        set w [FormUnquoteString "($txt)"]
        lappend aus [list $w $w]
    }
    return $aus
}

# Den Appearance-Strom eines Textfeldes neu bauen.
#
# DAS WAR DIE LUECKE: fillForms setzte /V und /NeedAppearances, liess den
# Strom aber, wie er war. Ein Betrachter, der die Flagge befolgt, zeigte
# den neuen Wert; eine Druckstrecke, die den Strom zeichnet, den ALTEN --
# bei einem leeren Feld also nichts, bei einem vorbelegten den alten
# Text. Auf Papier stand damit etwas anderes als in der Datei, und man
# sah es dem Bildschirm nicht an.
#
# .63 hat dafuer vorgesorgt: seither bekommt auch ein LEERES Feld einen
# (leeren) Strom, damit es hier etwas zum Ueberschreiben gibt. Genau das
# geschieht jetzt.
#
# Rueckgabe: der neue Objektkoerper, oder "" wenn nichts gebaut werden
# konnte -- dann bleibt alles wie bisher. Kein Rueckschritt gegen .63.
#
# WAS HIER NICHT GEHT und mit Absicht nicht versucht wird:
#   * Comb-Felder -- die Zellenbreite haengt an /MaxLen, und ein fremdes
#     Formular kann das Bit ohne die Laenge tragen
#   * mehrzeilige Felder -- der Umbruch braucht die Schriftbreiten
#   * Ankreuz- und Optionsfelder -- die haben zwei Zustaende, und /AS
#     schaltet zwischen ihnen; das tut fillForms schon richtig
#   * Auswahllisten
# In all diesen Faellen bleibt der alte Strom stehen, so wie bisher.
proc pdf4tcl::FormBuildTextAP {daString rect wert fontRef fontResName {quadding 0} {multiline 0} {combLen 0}} {
    lassign $rect x1 y1 x2 y2
    set width  [expr {abs($x2 - $x1)}]
    set height [expr {abs($y2 - $y1)}]
    if {$width <= 0 || $height <= 0} { return "" }

    # /DA sieht aus wie "/Helv 10 Tf 0 g". Die Groesse 0 heisst
    # "automatisch"; dann wird sie aus der Feldhoehe genommen, wie es ein
    # Betrachter auch taete.
    set fsize 0
    regexp {/[^\s]+\s+([0-9.]+)\s+Tf} $daString -> fsize
    if {$fsize <= 0} {
        set fsize [expr {$height * 0.65}]
        if {$fsize > 12.0} { set fsize 12.0 }
        if {$fsize < 4.0}  { set fsize 4.0 }
    }
    # Die Farbe aus /DA uebernehmen -- steht dort keine, ist es Schwarz.
    set farbe "0 g"
    if {[regexp {Tf\s+(.*)$} $daString -> rest]} {
        set rest [string trim $rest]
        if {$rest ne ""} { set farbe $rest }
    }

    # /Q beachten: 0 links, 1 mittig, 2 rechts (ISO 32000-1 12.7.4.3,
    # Tabelle 228). Ohne das rutschte ein rechtsbuendiges Feld nach dem
    # Fuellen nach links -- gemessen: /Q 2 stand im Feld, der Strom
    # setzte "2 1.1 Td". Die Option gab es, und sie tat nichts.
    #
    # Die Breite kommt aus getStringWidth mit DERSELBEN Schrift und
    # Groesse, die auch der Strom setzt. Eine geschaetzte Breite waere
    # eine zweite Rechnung, und zwei Rechnungen fuer dieselbe Sache
    # gehen auseinander.
    set tx 2.0
    if {$quadding == 1 || $quadding == 2} {
        # Die Breite kommt aus den Metriken der BASISSCHRIFT.
        #
        # Nur fuer die vierzehn Standardschriften: deren Breiten stehen in
        # stdmetrics.tcl und sind ueberall dieselben. Eine EINGEBETTETE
        # Fremdschrift kennt pdf4tcl beim Fuellen nicht -- ihre Metriken
        # stecken im Schriftprogramm des fremden Dokuments, und ein
        # geschaetzter Wert waere eine Ausrichtung, die falsch ist und
        # richtig aussieht. Dann bleibt es linksbuendig, wie bisher.
        set tw [FormStdWidth $wert $fsize]
        if {$tw > 0.0} {
            if {$quadding == 1} {
                set tx [expr {($width - $tw) / 2.0}]
            } else {
                set tx [expr {$width - $tw - 2.0}]
            }
            if {$tx < 2.0} { set tx 2.0 }
        }
    }
    set stream "/Tx BMC BT "
    append stream "/$fontResName [::pdf4tcl::Nf $fsize] Tf $farbe "
    if {$combLen > 0} {
        # Comb: die Feldbreite durch /MaxLen geteilt, jedes Zeichen
        # MITTIG in seiner Zelle (ISO 32000-1 12.7.4.3, Tabelle 228,
        # Bit 25). Dasselbe, was addForm beim Erzeugen tut.
        #
        # Die Bedingung dafuer ist MESSBAR und nicht geraten: /MaxLen ist
        # da oder nicht. Ein Formular kann Bit 25 ohne die Laenge tragen
        # -- dann gibt es keinen Teiler, keine Zellen, und der Aufrufer
        # laesst den alten Strom stehen. Genau deshalb wurde der Fall bis
        # hierher ausgelassen.
        #
        # Die Breite je Zeichen kommt aus den Metriken der Basisschrift.
        # Kennt pdf4tcl die Schrift nicht, misst FormStdWidth 0 -- dann
        # sitzt das Zeichen am linken Zellenrand statt mittig. Schief,
        # aber in der richtigen Zelle; eine geratene Breite waere in
        # keiner.
        set zelle [expr {double($width) / $combLen}]
        set frei [expr {$combLen - [string length $wert]}]
        if {$frei < 0} { set frei 0 }
        switch -- $quadding {
            1       { set i [expr {$frei / 2}] }
            2       { set i $frei }
            default { set i 0 }
        }
        foreach ch [split $wert ""] {
            if {$i >= $combLen} break
            set cw [FormStdWidth $ch $fsize]
            set cx [expr {$i * $zelle + ($zelle - $cw) / 2.0}]
            append stream "1 0 0 1 [::pdf4tcl::Nf $cx] 1.1 Tm "
            append stream "[::pdf4tcl::QuoteString $ch] Tj "
            incr i
        }
    } elseif {$multiline} {
        # Derselbe Umbruch wie beim Erzeugen -- FormWrapLines wird von
        # beiden Stellen gerufen. Die Breite kommt hier aus den Metriken
        # der Basisschrift; kennt pdf4tcl die Schrift nicht, misst
        # FormStdWidth 0, und dann bleibt jeder Absatz eine Zeile.
        # Das ist der ehrliche Rueckfall: lieber ungebrochen als an
        # geratener Stelle gebrochen.
        set zeilen [::pdf4tcl::FormWrapLines $wert [expr {$width - 4.0}] \
                [list apply {{size s} {::pdf4tcl::FormStdWidth $s $size}} $fsize]]
        set abstand [expr {$fsize * 1.15}]
        set y [expr {$height - $abstand}]
        foreach zeile $zeilen {
            if {$y < 0} break
            append stream "1 0 0 1 [::pdf4tcl::Nf $tx] [::pdf4tcl::Nf $y] Tm "
            append stream "[::pdf4tcl::QuoteString $zeile] Tj "
            set y [expr {$y - $abstand}]
        }
    } else {
        append stream "[::pdf4tcl::Nf $tx] 1.1 Td "
        append stream "[::pdf4tcl::QuoteString $wert] Tj "
    }
    append stream "ET EMC"

    set dict "<< /BBox \[ 0 0 [::pdf4tcl::Nf $width] [::pdf4tcl::Nf $height]\]\n"
    append dict "/Resources << /Font << /$fontResName $fontRef >> >>\n"
    append dict "/Subtype /Form\n/Type /XObject"
    # Unkomprimiert: der Strom ist kurz, und eine Datei, in der man den
    # gefuellten Wert im Klartext findet, ist beim Nachsehen mehr wert
    # als zweihundert gesparte Bytes.
    return [::pdf4tcl::MakeStream $dict $stream 0]
}

# Set or replace one key in an object body. The value is written as given,
# so the caller decides between (string), /Name and a bare number.
proc pdf4tcl::FormSetKey {body key value} {
    # Replace an existing entry. The value may be a string in brackets, a
    # name, or a number -- each ends differently, so three patterns.
    # A literal string may contain escaped brackets. "[^)]*" stops at the
    # first one of those, so replacing a value that held one left the rest
    # of the old string behind -- the other half of the round-trip defect
    # that FormUnquoteString fixes on the reading side. Measured: three
    # passes added one bracket each.
    #
    # This matches an escaped pair, or any character that is not a
    # backslash or a closing bracket.
    set muster1 "${key}\\s*\\((?:\\\\.|\[^\\\\)\])*\\)"
    # Hex string: /V <FEFF> -- what OpenOffice writes for an empty text
    # field. Without this pattern the key was not recognised as present and
    # a second one was appended, so the dictionary carried /V twice.
    # Measured on a foreign form: qpdf reported "dictionary has duplicated
    # key /V", and getForms read the older, empty one.
    set muster1b "${key}\\s*<\[0-9A-Fa-f\\s\]*>"
    set muster2 "${key}\\s*/\\w+"
    set muster3 "${key}\\s+\\d+"
    foreach muster [list $muster1 $muster1b $muster2 $muster3] {
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

# Unpack a PDF string the way fillForms takes one in.
#
# getForms used to hand the value back raw -- with its brackets and its
# escapes -- while fillForms expects a plain string. The obvious round
# trip, read a form, change one field, write it back, therefore doubled
# the escaping of every field it did NOT touch, on every pass. Measured
# over three passes:
#
#   Meier & Co (GmbH)
#   (Meier & Co \(GmbH\))
#   (\(Meier & Co \\\(GmbH\\\)\)))
#
# A NAME value (/Yes, /Off) is left alone: that is the form fillForms
# expects for check boxes and radio buttons.
#
# Handled: literal strings with escapes and octal, hex strings, and
# UTF-16BE with a byte order mark (ISO 32000 clauses 7.3.4.2, 7.3.4.3
# and 7.9.2.2).
proc pdf4tcl::FormUnquoteString {raw} {
    set raw [string trim $raw]
    if {$raw eq ""} { return "" }

    # A name object stays as it is.
    if {[string index $raw 0] eq "/"} { return $raw }

    # Hex string: <48656C6C6F>
    if {[string index $raw 0] eq "<" && [string index $raw end] eq ">"} {
        set hex [string range $raw 1 end-1]
        set hex [regsub -all {\s} $hex ""]
        # An odd number of digits is padded with a zero (clause 7.3.4.3).
        if {[string length $hex] % 2} { append hex 0 }
        if {![regexp {^[0-9A-Fa-f]*$} $hex]} { return $raw }
        set bytes [binary format H* $hex]
        return [FormDecodeText $bytes]
    }

    # Literal string: (Hello)
    if {[string index $raw 0] ne "(" || [string index $raw end] ne ")"} {
        return $raw
    }
    set body [string range $raw 1 end-1]

    set out ""
    set i 0
    set n [string length $body]
    while {$i < $n} {
        set c [string index $body $i]
        if {$c ne "\\"} {
            append out $c
            incr i
            continue
        }
        incr i
        set e [string index $body $i]
        switch -- $e {
            n { append out "\n"; incr i }
            r { append out "\r"; incr i }
            t { append out "\t"; incr i }
            b { append out "\b"; incr i }
            f { append out "\f"; incr i }
            "(" - ")" - "\\" { append out $e; incr i }
            "\n" { incr i }
            default {
                # Octal, one to three digits.
                if {[regexp {^([0-7]{1,3})} [string range $body $i end] -> okt]} {
                    append out [format %c [scan $okt %o]]
                    incr i [string length $okt]
                } else {
                    append out $e
                    incr i
                }
            }
        }
    }
    return [FormDecodeText $out]
}

# A PDF text string is either PDFDocEncoding or UTF-16BE with a byte
# order mark (clause 7.9.2.2).
proc pdf4tcl::FormDecodeText {bytes} {
    if {[string length $bytes] >= 2} {
        binary scan [string range $bytes 0 1] H4 bom
        if {[string equal -nocase $bom "feff"]} {
            return [encoding convertfrom unicode \
                    [_SwapBytes [string range $bytes 2 end]]]
        }
    }
    return $bytes
}

# UTF-16BE to the host order that [encoding convertfrom unicode] wants.
proc pdf4tcl::_SwapBytes {s} {
    binary scan $s cu* bytes
    set out ""
    foreach {hi lo} $bytes {
        if {$lo eq ""} { set lo 0 }
        append out [binary format cucu $lo $hi]
    }
    return $out
}

proc pdf4tcl::getForms {pdfFile} {
    if {![file exists $pdfFile]} {
        throw {PDF4TCL} "No such file: $pdfFile"
    }
    set pdf [pdf4tcl::cat::ReadPdf $pdfFile]

    # Ueber den FELDBAUM, nicht ueber die Widgets.
    #
    # Bis .64 wurde jedes Widget mit /T als eigenes Feld gemeldet. Das
    # trifft den haeufigen Fall, aber ein Feld mit mehreren Widgets fiel
    # ganz durch und ein verschachtelter Name kam ohne seinen Vater.
    # Siehe FormFieldTree.
    set result {}
    dict for {o e} [pdf4tcl::FormFieldTree $pdf] {
        set id [dict get $e name]
        if {$id eq ""} continue
        dict set result $id type [dict get $e FT]
        set v [dict get $e V]
        dict set result $id value [expr {$v eq "" ? "" : [FormUnquoteString $v]}]
        set ff [dict get $e Ff]
        dict set result $id flags [expr {$ff eq "" ? 0 : $ff}]
        set ml [dict get $e MaxLen]
        dict set result $id maxlen $ml
        # Comb ist Bit 25 und gilt nur zusammen mit /MaxLen -- ohne
        # Teiler gibt es keine Zellen (ISO 32000-1 12.7.4.3). Ein
        # gesetztes Bit ohne /MaxLen ist darum KEIN Kammfeld, und hier
        # steht 0, nicht 1: die Auskunft soll sagen, was die Datei
        # bewirkt, nicht was in ihr steht.
        dict set result $id comb [expr {
            ([dict get $result $id flags] & $::pdf4tcl::Ff_COMB)
            && $ml ne "" ? 1 : 0}]
        # /AS steht am WIDGET, nicht am Feld: bei einem Ankreuzfeld
        # sagt es, welche Erscheinung gerade gilt.
        #
        # NUR wenn es eines gibt -- wie bisher. Der Schluessel
        # unbedingt zu setzen waere eine stille Erweiterung der
        # Rueckgabe, und die ist eine Zusage: form-4.1 nagelt das ganze
        # dict fest und hat es gemeldet.
        foreach w [dict get $e widgets] {
            if {![dict exists $pdf $w]} continue
            if {[regexp {/AS\s*(/\w+)} [dict get $pdf $w full] -> as]} {
                dict set result $id default $as
                break
            }
        }
        # Wieviele Widgets -- beim Durchschlagsatz die entscheidende
        # Auskunft, und sonst immer 1. Wer sie nicht braucht, sieht sie
        # nicht.
        dict set result $id widgets [llength [dict get $e widgets]]
        # Der Name FUER MENSCHEN. addForm schreibt ihn ueber -tooltip,
        # und getForms gab ihn bis 0.9.4.65 nicht wieder heraus.
        set tu [dict get $e TU]
        dict set result $id description \
                [expr {$tu eq "" ? "" : [FormUnquoteString $tu]}]
        # Die erlaubten Werte eines Auswahlfeldes, {exportwert
        # beschriftung} je Eintrag. LEER bei allen anderen Feldarten --
        # aber DA, damit der Aufrufer nicht nach der Feldart
        # unterscheiden muss.
        dict set result $id options [dict get $e Opt]
    }
    return $result
}
