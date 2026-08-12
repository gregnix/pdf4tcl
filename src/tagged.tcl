###############################################################################
# pdf4tcl - Tagged PDF support (logical structure)
#
# ISO 32000-1 clause 14.7 (Logical Structure) and 14.8 (Tagged PDF).
#
# A normal PDF only records where glyphs are painted. A tagged PDF adds a tree
# of structure elements (/StructTreeRoot -> /Document -> /H1, /P, /Figure ...)
# and connects that tree to the content stream through marked content
# operators (BDC/EMC) carrying an /MCID. Screen readers, reflow and
# structure preserving export use that tree instead of the paint order.
#
# Scope of this module (prototype, 0.9.4.36):
#   - explicit tagging only: the caller brackets content with tagBegin/tagEnd
#   - grouping and BLSE types plus /Figure, /Formula, /Caption, /Span
#   - /Alt, /ActualText, /Lang, /T (title) per element
#   - artifacts (running heads, rules, decoration) via tagArtifact
#   - elements may span pages: the marked content is closed at endPage and
#     reopened on the next page with a new MCID
#
# Not covered yet -- see OFFEN in TAGGED.md:
#   - automatic tagging of untagged content (untagged content stays untagged;
#     that is legal PDF but not PDF/UA conformant)
#   - /Link and /Annot elements with /OBJR references to annotations
#   - table structure validation (/TR inside /Table etc. is not checked)
#   - tagging inside XObjects (startPage -xobject) -- refused with an error
#   - /RoleMap for non-standard types -- unknown types are refused instead
#
# NOTE ON CLASS VARIABLES
# This file reopens ::pdf4tcl::pdf4tcl with a second oo::define. It must NOT
# contain a "variable" declaration: oo::define variable REPLACES the class
# variable list, so re-declaring only "pdf" here would hide options, fonts,
# images ... from every method of the class. The declarations in main.tcl
# already apply to the methods below. src/encrypt.tcl works the same way.
#
# NOTE ON METHOD NAMES
# TclOO exports a method only if its name starts with a lowercase letter.
# Public API therefore uses tagBegin/tagEnd/..., internal hooks use
# TagPageStart/TagPageEnd/... and stay private without an explicit unexport.
###############################################################################

namespace eval pdf4tcl {
    # Standard structure types, ISO 32000-1 Table 333-337.
    # Anything outside this list would need a /RoleMap entry, so it is
    # refused rather than written out and silently ignored by readers.
    variable StdStructTypes {
        Document Part Art Sect Div BlockQuote Caption TOC TOCI Index
        NonStruct Private
        P H H1 H2 H3 H4 H5 H6
        L LI Lbl LBody
        Table TR TH TD THead TBody TFoot
        Span Quote Note Reference BibEntry Code
        Figure Formula Form
    }

    # Encode a Tcl string as a PDF text string (ISO 32000-1 clause 7.9.2.2).
    #
    # Pure ASCII is written as PDFDocEncoding, anything else as UTF-16BE with
    # a byte order mark. The result is always a *literal* string -- a hex
    # string would look nicer but EncryptStringsInBody only rewrites literals,
    # so a hex string would stay in the clear in an encrypted document.
    #
    # pdf4tcl::QuoteString is deliberately not used here: it transliterates
    # code points above U+00FF and replaces the rest with "?". That is
    # acceptable for a bookmark title but not for /Alt, which is the only
    # thing a screen reader gets to read.
    proc TagTextString {s} {
        if {[regexp {[^\x20-\x7E]} $s]} {
            set bytes "\xFE\xFF"
            foreach ch [split $s ""] {
                scan $ch %c cp
                if {$cp > 0xFFFF} {
                    set v [expr {$cp - 0x10000}]
                    append bytes [binary format S [expr {0xD800 | ($v >> 10)}]]
                    append bytes [binary format S [expr {0xDC00 | ($v & 0x3FF)}]]
                } else {
                    append bytes [binary format S $cp]
                }
            }
        } else {
            set bytes $s
        }
        binary scan $bytes cu* codes
        set out "("
        foreach c $codes {
            if {$c >= 0x20 && $c <= 0x7E} {
                switch -- $c {
                    40  { append out "\\(" }
                    41  { append out "\\)" }
                    92  { append out "\\\\" }
                    default { append out [format %c $c] }
                }
            } else {
                append out [format "\\%03o" $c]
            }
        }
        append out ")"
        return $out
    }
}

oo::define ::pdf4tcl::pdf4tcl {

    ###########################################################################
    # State
    #
    # Everything lives in the pdf() array on purpose. "finish -dryRun" saves
    # and restores that array; state kept anywhere else would survive a dry
    # run and corrupt the real one.
    ###########################################################################

    method TagInit {} {
        if {[info exists pdf(tag,active)]} { return }
        set pdf(tag,active)   0
        set pdf(tag,lang)     ""
        set pdf(tag,n)        0      ;# number of structure elements
        set pdf(tag,root)     -1     ;# index of the /Document element
        set pdf(tag,stack)    {}     ;# open elements, outermost first
        set pdf(tag,open)     ""     ;# element owning the open BDC, or ""
        set pdf(tag,artdepth) 0      ;# nesting depth of open artifacts
        set pdf(tag,mcguard)  0      ;# reentrancy guard for TagEnsureMC
        set pdf(tag,curpage)  ""     ;# page object id the counters belong to
        set pdf(tag,nextmcid) 0
        set pdf(tag,pagelist) {}     ;# page object ids that carry MCIDs
        set pdf(tag,rootoid)  ""
        set pdf(tag,uapart)   ""   ;# pdfuaid:part, empty unless -ua given
    }

    method TagActive {} {
        expr {[info exists pdf(tag,active)] && $pdf(tag,active)}
    }

    ###########################################################################
    # Public API
    ###########################################################################

    # Enable or disable tagging.
    #   $pdf tagged 1 -lang de-DE
    # Must be called before the first tagBegin. Disabling mid-document keeps
    # the structure collected so far; it is still written at finish.
    method tagged {{onOff 1} args} {
        my TagInit
        foreach {option value} $args {
            switch -- $option {
                -lang {
                    if {![regexp {^[A-Za-z]{2,3}(-[A-Za-z0-9]{1,8})*$} $value]} {
                        throw {PDF4TCL} "invalid language tag \"$value\""
                    }
                    set pdf(tag,lang) $value
                }
                -ua {
                    # Writing pdfuaid:part is an assertion of conformance, and
                    # nothing here can verify it: embedded fonts, a document
                    # title, complete tagging of all content and correct
                    # heading order are all the caller's responsibility. So it
                    # is opt-in rather than implied by "tagged 1" -- a file
                    # that fails veraPDF while claiming PDF/UA is worse than
                    # one that claims nothing.
                    if {$value ni {0 1 2}} {
                        throw {PDF4TCL} "invalid -ua value \"$value\":\
                                must be 0, 1 or 2"
                    }
                    set pdf(tag,uapart) [expr {$value == 0 ? "" : $value}]
                }
                default {
                    throw {PDF4TCL} "unknown option \"$option\""
                }
            }
        }
        my CheckBoolean tagged $onOff
        set pdf(tag,active) [expr {$onOff ? 1 : 0}]
        if {$pdf(tag,active)} {
            # Logical structure was introduced in PDF 1.3, Tagged PDF in 1.4.
            my RequireVersion 1.4
            if {$pdf(tag,root) < 0} {
                set pdf(tag,root) [my TagNewElem Document -1 {}]
            }
        }
        return
    }

    # Open a structure element and start marked content for it.
    # Returns the element index, which is only useful for debugging.
    method tagBegin {type args} {
        my TagInit
        if {![my TagActive]} {
            throw {PDF4TCL} "tagging is not enabled, call \"tagged 1\" first"
        }
        variable ::pdf4tcl::StdStructTypes
        if {$type ni $::pdf4tcl::StdStructTypes} {
            throw {PDF4TCL} "unknown structure type \"$type\""
        }
        set attrs {}
        foreach {option value} $args {
            switch -- $option {
                -alt - -actualtext - -title {
                    ##nagelfar ignore Found constant
                    dict set attrs $option $value
                }
                -lang {
                    if {![regexp {^[A-Za-z]{2,3}(-[A-Za-z0-9]{1,8})*$} $value]} {
                        throw {PDF4TCL} "invalid language tag \"$value\""
                    }
                    ##nagelfar ignore Found constant
                    dict set attrs $option $value
                }
                -scope {
                    # ISO 14289-1 clause 7.5: where a table's structure cannot
                    # be derived algorithmically, TH must carry /Scope. Written
                    # as an /Attributes dictionary with /O /Table.
                    if {$type ne "TH"} {
                        throw {PDF4TCL} "-scope applies to TH, not $type"
                    }
                    if {$value ni {Row Column Both}} {
                        throw {PDF4TCL} "invalid -scope value \"$value\":\
                                must be Row, Column or Both"
                    }
                    ##nagelfar ignore Found constant
                    dict set attrs $option $value
                }
                default {
                    throw {PDF4TCL} "unknown option \"$option\""
                }
            }
        }
        if {!$pdf(inPage)} { my startPage }
        if {$pdf(inXObject)} {
            throw {PDF4TCL} "tagging inside an XObject is not supported"
        }
        if {$pdf(tag,artdepth) > 0} {
            throw {PDF4TCL} "tagBegin inside an artifact"
        }
        if {[llength $pdf(tag,stack)] > 0} {
            set parent [lindex $pdf(tag,stack) end]
        } else {
            set parent $pdf(tag,root)
        }
        set idx [my TagNewElem $type $parent $attrs]
        lappend pdf(tag,stack) $idx
        return $idx
    }

    # Close the innermost open structure element.
    method tagEnd {} {
        my TagInit
        if {[llength $pdf(tag,stack)] == 0} {
            throw {PDF4TCL} "tagEnd without matching tagBegin"
        }
        set idx [lindex $pdf(tag,stack) end]
        set pdf(tag,stack) [lrange $pdf(tag,stack) 0 end-1]
        if {$pdf(tag,open) eq $idx} {
            my TagCloseMC
        }
        return
    }

    # Convenience: a complete element around a single text call.
    #   $pdf tagText H1 "Chapter 1" -x 50 -y 700
    # Options are split: tag options go to tagBegin, the rest to text.
    method tagText {type str args} {
        set tagOpts {}
        set textOpts {}
        foreach {option value} $args {
            if {$option in {-alt -actualtext -title -lang -scope}} {
                lappend tagOpts $option $value
            } else {
                lappend textOpts $option $value
            }
        }
        my tagBegin $type {*}$tagOpts
        set res [my text $str {*}$textOpts]
        my tagEnd
        return $res
    }

    # Mark content as an artifact: page numbers, running heads, rules,
    # background decoration. Artifacts carry no MCID and are skipped by
    # assistive technology. ISO 32000-1 clause 14.8.2.2.
    #   $pdf tagArtifact -type Pagination -subtype Header
    method tagArtifact {args} {
        my TagInit
        if {![my TagActive]} {
            throw {PDF4TCL} "tagging is not enabled, call \"tagged 1\" first"
        }
        set props {}
        foreach {option value} $args {
            switch -- $option {
                -type {
                    if {$value ni {Pagination Layout Page Background}} {
                        throw {PDF4TCL} "invalid artifact type \"$value\""
                    }
                    ##nagelfar ignore Found constant
                    dict set props Type $value
                }
                -subtype {
                    if {$value ni {Header Footer Watermark}} {
                        throw {PDF4TCL} "invalid artifact subtype \"$value\""
                    }
                    ##nagelfar ignore Found constant
                    dict set props Subtype $value
                }
                default {
                    throw {PDF4TCL} "unknown option \"$option\""
                }
            }
        }
        if {!$pdf(inPage)} { my startPage }
        if {$pdf(inXObject)} {
            throw {PDF4TCL} "tagging inside an XObject is not supported"
        }
        # PDF/UA forbids an artifact inside tagged content and tagged content
        # inside an artifact (ISO 14289-1 clause 7.1). An element may still be
        # open here -- a running foot on the second page of a paragraph that
        # spans the break is the normal case -- so the element's marked
        # content is closed first and reopened by the next painting call. The
        # artifact then sits between two sequences of the element, not inside
        # one. Measured before this: veraPDF reported both 7.1-1 and 7.1-2.
        my TagCloseMC
        my EndTextObj
        if {[dict size $props] == 0} {
            my Pdfout "/Artifact BMC\n"
        } else {
            set entries {}
            dict for {key value} $props {
                lappend entries "/$key /$value"
            }
            my Pdfout "/Artifact <<[join $entries { }]>> BDC\n"
        }
        incr pdf(tag,artdepth)
        return
    }

    method tagArtifactEnd {} {
        my TagInit
        if {$pdf(tag,artdepth) <= 0} {
            throw {PDF4TCL} "tagArtifactEnd without matching tagArtifact"
        }
        my EndTextObj
        my Pdfout "EMC\n"
        incr pdf(tag,artdepth) -1
        return
    }

    ###########################################################################
    # Structure tree bookkeeping
    ###########################################################################

    method TagNewElem {type parent attrs} {
        set idx $pdf(tag,n)
        incr pdf(tag,n)
        set pdf(tag,type,$idx)   $type
        set pdf(tag,parent,$idx) $parent
        set pdf(tag,kids,$idx)   {}
        set pdf(tag,attr,$idx)   $attrs
        if {$parent >= 0} {
            lappend pdf(tag,kids,$parent) [list E $idx]
        }
        return $idx
    }

    # Make sure the per page counters belong to the page being written.
    method TagSyncPage {} {
        set page $pdf(pageobjid)
        if {$pdf(tag,curpage) eq $page} { return }
        set pdf(tag,curpage)  $page
        set pdf(tag,nextmcid) 0
        if {![info exists pdf(tag,pagekids,$page)]} {
            set pdf(tag,pagekids,$page) {}
            set pdf(tag,spnum,$page) [llength $pdf(tag,pagelist)]
            lappend pdf(tag,pagelist) $page
        }
    }

    # Open marked content on the current page for element idx.
    method TagOpenMC {idx} {
        my TagSyncPage
        set page $pdf(tag,curpage)
        set mcid $pdf(tag,nextmcid)
        incr pdf(tag,nextmcid)
        lappend pdf(tag,kids,$idx) [list M $page $mcid]
        lappend pdf(tag,pagekids,$page) $idx
        my EndTextObj
        my Pdfout "/$pdf(tag,type,$idx) <</MCID $mcid>> BDC\n"
        set pdf(tag,open) $idx
    }

    method TagCloseMC {} {
        if {$pdf(tag,open) eq ""} { return }
        my EndTextObj
        my Pdfout "EMC\n"
        set pdf(tag,open) ""
    }

    # Called from the content stream writers just before anything is painted.
    #
    # Marked content is opened here rather than in tagBegin because only the
    # innermost element may own it. Opening it eagerly for every tagBegin put
    # a container's MCID around its children's -- veraPDF reports that as
    # "Nested MCID", and it is wrong: a grouping element such as /L or /TR
    # paints nothing itself and must not carry marked content at all.
    #
    # When a different element owns the currently open sequence, it is closed
    # and a new one opened. An element may therefore own several marked
    # content sequences on one page; that is normal and is what /K arrays with
    # multiple /MCR entries are for.
    method TagEnsureMC {} {
        if {![my TagActive]} { return }
        # Artifacts own the marked content while they are open, and the guard
        # keeps the Pdfout calls below from re-entering this method.
        if {$pdf(tag,artdepth) > 0 || $pdf(tag,mcguard)} { return }
        if {[llength $pdf(tag,stack)] == 0} { return }
        if {!$pdf(inPage) || $pdf(inXObject)} { return }
        set inner [lindex $pdf(tag,stack) end]
        if {$pdf(tag,open) eq $inner} { return }
        set pdf(tag,mcguard) 1
        try {
            my TagCloseMC
            my TagOpenMC $inner
        } finally {
            set pdf(tag,mcguard) 0
        }
    }

    ###########################################################################
    # Hooks called from main.tcl
    #
    # All four return immediately when tagging is off, so an untagged
    # document pays one [info exists] per page.
    ###########################################################################

    # End of startPage. Nothing is written here any more: with lazy marked
    # content the first painting operation on the new page opens a fresh
    # sequence for whatever element is still open, which is exactly what an
    # element spanning a page break needs. Only the per page state is reset.
    method TagPageStart {} {
        if {![my TagActive]} { return }
        if {$pdf(inXObject)} { return }
        set pdf(tag,open) ""
    }

    # Start of endPage, before the content stream is flushed: close the
    # marked content sequence still open on this page. BDC/EMC may not cross
    # a stream boundary (ISO 32000-1 clause 14.6).
    method TagPageEnd {} {
        if {![my TagActive]} { return }
        if {$pdf(inXObject)} { return }
        if {$pdf(tag,artdepth) > 0} {
            throw {PDF4TCL} "page ended with $pdf(tag,artdepth) open artifact(s)"
        }
        my TagCloseMC
    }

    # Extra entries for the page dictionary in endPage.
    method TagPageDict {} {
        if {![my TagActive]} { return "" }
        set page $pdf(pageobjid)
        if {![info exists pdf(tag,spnum,$page)]} { return "" }
        return "/StructParents $pdf(tag,spnum,$page)\n"
    }

    # Extra entries for the document catalog in finish.
    method TagCatalogEntries {} {
        if {![my TagActive]} { return }
        if {$pdf(tag,n) <= 1} { return }   ;# only the empty /Document
        if {[llength $pdf(tag,stack)] > 0} {
            throw {PDF4TCL} "document finished with\
                    [llength $pdf(tag,stack)] open structure element(s)"
        }
        set pdf(tag,rootoid) [my GetOid 1]
        my Pdfout "/StructTreeRoot $pdf(tag,rootoid) 0 R\n"
        my Pdfout "/MarkInfo <</Marked true>>\n"
        if {$pdf(tag,lang) ne ""} {
            my Pdfout "/Lang [::pdf4tcl::TagTextString $pdf(tag,lang)]\n"
        }
    }

    # Write the structure tree in finish, after the catalog and before the
    # final FlushObjects.
    method TagWriteObjects {} {
        if {![my TagActive]} { return }
        if {$pdf(tag,rootoid) eq ""} { return }

        # Reserve object ids first: /K and /P reference each other.
        for {set i 0} {$i < $pdf(tag,n)} {incr i} {
            set pdf(tag,oid,$i) [my GetOid 1]
        }
        set parentTreeOid [my GetOid 1]

        # Structure elements. Queued rather than written directly so that
        # FlushObjects applies string encryption to /Alt and /T.
        for {set i 0} {$i < $pdf(tag,n)} {incr i} {
            set parent $pdf(tag,parent,$i)
            if {$parent < 0} {
                set parentRef "$pdf(tag,rootoid) 0 R"
            } else {
                set parentRef "$pdf(tag,oid,$parent) 0 R"
            }
            set kids {}
            foreach kid $pdf(tag,kids,$i) {
                switch -- [lindex $kid 0] {
                    E {
                        lappend kids "$pdf(tag,oid,[lindex $kid 1]) 0 R"
                    }
                    M {
                        lassign $kid _ page mcid
                        lappend kids "<</Type /MCR /Pg $page 0 R /MCID $mcid>>"
                    }
                }
            }
            set body "<</Type /StructElem\n"
            append body "/S /$pdf(tag,type,$i)\n"
            append body "/P $parentRef\n"
            if {[llength $kids] > 0} {
                append body "/K \[[join $kids "\n"]\]\n"
            }
            set attrs $pdf(tag,attr,$i)
            if {[dict exists $attrs -scope]} {
                append body "/A <</O /Table /Scope /[dict get $attrs -scope]>>\n"
            }
            foreach {option key} {-alt Alt -actualtext ActualText
                                  -title T -lang Lang} {
                if {[dict exists $attrs $option]} {
                    append body "/$key\
                            [::pdf4tcl::TagTextString [dict get $attrs $option]]\n"
                }
            }
            append body ">>"
            lappend pdf(objects) $pdf(tag,oid,$i) \
                    "$pdf(tag,oid,$i) 0 obj\n$body\nendobj\n"
        }

        # Number tree mapping /StructParents of a page to its MCID owners.
        # No strings inside, so it is written directly.
        my StoreXref $parentTreeOid
        my Pdfout "$parentTreeOid 0 obj\n"
        my Pdfout "<</Nums \[\n"
        foreach page $pdf(tag,pagelist) {
            set refs {}
            foreach idx $pdf(tag,pagekids,$page) {
                lappend refs "$pdf(tag,oid,$idx) 0 R"
            }
            my Pdfout "$pdf(tag,spnum,$page) \[[join $refs { }]\]\n"
        }
        my Pdfout "\]>>\n"
        my Pdfout "endobj\n\n"

        my StoreXref $pdf(tag,rootoid)
        my Pdfout "$pdf(tag,rootoid) 0 obj\n"
        my Pdfout "<</Type /StructTreeRoot\n"
        my Pdfout "/K \[$pdf(tag,oid,$pdf(tag,root)) 0 R\]\n"
        my Pdfout "/ParentTree $parentTreeOid 0 R\n"
        my Pdfout "/ParentTreeNextKey [llength $pdf(tag,pagelist)]\n"
        my Pdfout ">>\n"
        my Pdfout "endobj\n\n"
    }
}
