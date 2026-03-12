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
proc pdf4tcl::cat::ReadPdf {file} {
    set ch [open $file rb]
    set data [read $ch]
    close $ch

    # Locate all incremental xref tables
    set allXref {}
    set xrefIndices {}
    # Locate last xref table
    regexp {startxref\s+(\d+)\s+%%EOF\s*$} $data -> startxref
    while 1 {
        set endpart [string range $data $startxref end]
        lappend xrefIndices $startxref
        # Extract trailer
        regexp {(?:trailer\s+(.*?)\s+startxref){1,1}?} $endpart -> trailertxt
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
        set xrefIx [expr {[lindex $xrefIndices [expr {$xxx + 1}]] - 1}]
        # Limit object extaction to xref
        set fullObj [string trim [string range $data $index $xrefIx]]
        set data [string range $data 0 [expr {$index - 1}]]
        if {$obj >= 0} {
            # TBD limit length properly on the full string
            if {![string match *endobj $fullObj]} {
                # This should not happen if the xref limit above works
                puts "XXXX $obj [regexp -all -inline {endobj} $fullObj]"
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

# Debug
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
    WriteCh $ch "%PDF-1.4\n" pos
    WriteCh $ch "%\xE5\xE4\xF6\n" pos
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
    WriteCh $ch "%%EOF\n" po

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
        dict set d $key [RenumberRef $val $delta]
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

    # TODO: Merge other stuff in Catalog, like AcroForm or Metadata
    if {[dict exists $pdf1 root /AcroForm] && \
                [dict exists $pdf2 root /AcroForm]
    } {
        set ob1 [lindex [dict get $pdf1 root /AcroForm] 0]
        set ob2 [lindex [dict get $pdf2 root /AcroForm] 0]
        set d1 [PdfObjToTclDict [dict get $pdf1 $ob1 full]]
        set d2 [PdfObjToTclDict [dict get $pdf2 $ob2 full]]
        # How to do this???
        #puts $d1
        #puts $d2
    }

    # Transfer all objects from 2 to 1
    foreach {key val} $pdf2 {
        if {[string is digit $key]} {
            dict set pdf1 $key full [dict get $val full]
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
proc pdf4tcl::catPdf {args} {
    if {[llength $args] < 3} {
        throw {PDF4TCL} "wrong # args: should be \"catPdf infile ?infile ...? outfile\""
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
    pdf4tcl::cat::WritePdf $outfile $pdf1
}

# Extract form data from a PDF file
# Return value is a dictionary of id/info pairs.
#  info is a dictionary containing these fields:
#   type    : Field type.
#   value   : Form value.
#   flags   : Value of form flags field.
#   default : Default value, if any.
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
