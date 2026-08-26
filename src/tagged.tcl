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
# images ... from all methods of the class. The declarations in main.tcl
# already apply to the methods below. src/encrypt.tcl works the same way.
#
# NOTE ON METHOD NAMES
# TclOO exports methods only when the name starts with a lowercase letter.
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
        Link Annot
    }

    # Where a structure type may appear, ISO 32000-1 Table 335 and 337.
    #
    # Only the relations the standard fixes without exception are listed.
    # A cell outside a row or a list item outside a list is a defect no
    # validator reports and no reader repairs: the element lands in the tree,
    # the file passes, and a screen reader announces a table with no rows.
    # Types absent from this dict are not restricted -- P, Span, Figure and
    # the rest may legitimately appear almost anywhere.
    variable StructParents {
        LI     {L}
        LBody  {LI}
        THead  {Table}
        TBody  {Table}
        TFoot  {Table}
        TR     {Table THead TBody TFoot}
        TH     {TR}
        TD     {TR}
        TOCI   {TOC}
    }

    # What a container must contain, ISO 32000-1 Table 335.
    #
    # The mirror image of StructParents. tagBegin catches a cell outside a
    # row; this catches a table with no rows at all. Both pass every
    # validator and both leave a screen reader with nothing to announce.
    # An entry means: at least one child of one of these types.
    variable StructChildren {
        L      {LI}
        LI     {LBody}
        Table  {TR THead TBody TFoot}
        THead  {TR}
        TBody  {TR}
        TFoot  {TR}
        TR     {TH TD}
    }

    # Operators that put marks on the page. Everything else in a content
    # stream sets state -- colour, font, matrix, graphics state -- and may
    # legitimately stand outside any structure element. Counting those as
    # untagged content would report every document, however careful.
    # ISO 32000-1 table 51: path-painting, text-showing, XObject and
    # shading operators.
    # The quote operators need escaping -- an unescaped " would break the
    # list, which is exactly what happened the first time round.
    variable PaintingOps {
        S s f F f* B B* b b*
        Tj TJ \' \"
        Do sh EI
    }

    # Types that carry no structural meaning of their own. ISO 32000-1
    # clause 14.8.4.2: NonStruct is skipped when the structure is examined,
    # so it must be skipped when the parent is determined as well --
    # otherwise wrapping a row in NonStruct would turn a legal document into
    # a rejected one.
    variable TransparentStructTypes {NonStruct}


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
        # Content inside a form XObject, ISO 32000-1 clause 14.7.4.4.
        #
        #   xobjplace,<oid>   page object the XObject was drawn on, or the
        #                     string "many" once it is drawn more than once
        #   xobjlist          every XObject that carries marked content
        set pdf(tag,xobjlist) {}
        set pdf(tag,pagelist) {}     ;# page object ids that carry MCIDs
        set pdf(tag,nextkey)  0      ;# next free key in the parent tree
        set pdf(tag,annotkeys) {}    ;# {key elementIndex} for annotations
        set pdf(tag,pendannot) ""    ;# key handed out but not yet bound
        set pdf(tag,annotwarned) 0   ;# unattached annotation reported once
        set pdf(tag,rootoid)  ""
        set pdf(tag,uapart)   ""   ;# pdfuaid:part, empty unless -ua given
        set pdf(tag,untagged) 0    ;# painting operations outside any element
        set pdf(tag,untagpage) {}  ;# page numbers where that happened
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
                -listnumbering {
                    # ISO 32000-1 Table 345. Lets a reader announce the list
                    # style instead of reading the painted bullet glyph.
                    if {$type ne "L"} {
                        throw {PDF4TCL} "-listnumbering applies to L, not $type"
                    }
                    if {$value ni {None Disc Circle Square Decimal
                                   UpperRoman LowerRoman UpperAlpha
                                   LowerAlpha}} {
                        throw {PDF4TCL} "invalid -listnumbering value\
                                \"$value\""
                    }
                    ##nagelfar ignore Found constant
                    dict set attrs $option $value
                }
                -id {
                    # Identifier of a header cell, referenced by -headers of
                    # the data cells it applies to.
                    if {$type ni {TH TD}} {
                        throw {PDF4TCL} "-id applies to TH or TD, not $type"
                    }
                    ##nagelfar ignore Found constant
                    dict set attrs $option $value
                }
                -headers {
                    # List of -id values naming the header cells for this
                    # cell. ISO 14289-1 clause 7.5 requires either this or
                    # -scope wherever the relation cannot be derived from the
                    # table layout, which is the case for any irregular table.
                    if {$type ni {TH TD}} {
                        throw {PDF4TCL} "-headers applies to TH or TD,\
                                not $type"
                    }
                    if {[llength $value] == 0} {
                        throw {PDF4TCL} "-headers must name at least one cell"
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
                -colspan - -rowspan {
                    # ISO 32000-1 table 349, standard table attributes
                    # (clause 14.8.5.7). /ColSpan and /RowSpan give the
                    # number of columns or rows the cell spans; a reader
                    # assumes 1 where the entry is absent, so 1 is not
                    # written.
                    #
                    # The spec restricts both to TH and TD, which is what
                    # the check below enforces.
                    #
                    # Clause 14.8.4.3.4 note 2 says the association of
                    # headers with rows and columns is determined
                    # heuristically and "may fail for complex tables" --
                    # the attributes exist to make it explicit. A merged
                    # cell is exactly such a case.
                    #
                    # Without them a heading spanning two columns looks
                    # like one cell in the tree, and a reader names the
                    # wrong heading for everything under the second. No
                    # validator reports it -- the tree is well formed, it
                    # just does not match the table.
                    if {$type ni {TH TD}} {
                        throw {PDF4TCL} "$option applies to TH or TD,\
                                not $type"
                    }
                    if {![string is integer -strict $value] || $value < 1} {
                        throw {PDF4TCL} "invalid $option value \"$value\":\
                                must be a positive integer"
                    }
                    ##nagelfar ignore Found constant
                    dict set attrs $option $value
                }
                -summary {
                    # ISO 32000-1 table 349: a summary of the table's
                    # purpose and structure, only on Table itself.
                    #
                    # The note there says what it is for: non-visual
                    # rendering -- speech or braille. A reader announces it
                    # before the cells, so someone who cannot see the shape
                    # of the table learns what to expect.
                    if {$type ne "Table"} {
                        throw {PDF4TCL} "-summary applies to Table,\
                                not $type"
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
        # Tagging inside a form XObject works (ISO 32000-1 clause 14.7.4.4):
        # MCIDs are scoped to the content stream, the XObject dictionary
        # carries its own /StructParents, and every MCR referring to that
        # content names the stream in /Stm.
        #
        # The limit is the one the standard cannot argue away: an XObject
        # drawn twice has ONE structure tree and TWO appearances, so an MCID
        # in it does not identify a place in the document. That is checked
        # when the document is written, not here -- at this point nobody
        # knows yet how often it will be placed.
        if {$pdf(tag,artdepth) > 0} {
            throw {PDF4TCL} "tagBegin inside an artifact"
        }
        if {[llength $pdf(tag,stack)] > 0} {
            set parent [lindex $pdf(tag,stack) end]
        } else {
            set parent $pdf(tag,root)
        }
        my TagCheckNesting $type $parent
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
        # Check before popping: if it fails the element stays open, so the
        # caller can add what is missing and close it afterwards.
        my TagCheckContent $idx
        set pdf(tag,stack) [lrange $pdf(tag,stack) 0 end-1]
        if {$pdf(tag,open) eq $idx} {
            my TagCloseMC
        }
        return
    }

    # Refuse to close a container the standard requires to hold something --
    # a table without rows, a list without items. tagBegin cannot see this:
    # at that point the element has no children yet.
    method TagCheckContent {idx} {
        variable ::pdf4tcl::StructChildren
        set type $pdf(tag,type,$idx)
        # An element with no content at all designates nothing: it passes
        # every check, and a reader announces a paragraph that holds
        # nothing. The standard does not forbid it, so this warns rather
        # than throwing.
        #
        # TD and TH are exempt: a blank cell is everyday and belongs in the
        # tree, otherwise the column mapping shifts. A missing TD is worse
        # than an empty one.
        #
        # Three things count as content: a child element (E), marked
        # content (M) and an object reference (O). The O matters -- a Link
        # or a form field legitimately consists of its /OBJR alone and
        # never carries an MCID. Checking marked content only would report
        # exactly the attachment 0.9.4.42 made possible.
        if {[llength $pdf(tag,kids,$idx)] == 0 && $type ni {TD TH}} {
            lappend ::pdf4tcl::warnings "tagged: the $type element is empty\
                    -- no content, no child element and no annotation. It\
                    passes every validator and tells a reader nothing."
        }
        if {![dict exists $::pdf4tcl::StructChildren $type]} { return }
        set wanted [dict get $::pdf4tcl::StructChildren $type]
        foreach kidType [my TagEffectiveKids $idx] {
            if {$kidType in $wanted} { return }
        }
        set names [join $wanted " or "]
        throw {PDF4TCL} "$type must contain at least one $names"
    }

    # Types of the child elements, looking through transparent ones: a row
    # wrapped in NonStruct still counts as a row for its table.
    method TagEffectiveKids {idx} {
        variable ::pdf4tcl::TransparentStructTypes
        set res {}
        foreach kid $pdf(tag,kids,$idx) {
            if {[lindex $kid 0] ne "E"} { continue }
            set kidIdx [lindex $kid 1]
            set kidType $pdf(tag,type,$kidIdx)
            if {$kidType in $::pdf4tcl::TransparentStructTypes} {
                lappend res {*}[my TagEffectiveKids $kidIdx]
            } else {
                lappend res $kidType
            }
        }
        return $res
    }

    # Convenience: a complete element around a single text call.
    #   $pdf tagText H1 "Chapter 1" -x 50 -y 700
    # Options are split: tag options go to tagBegin, the rest to text.
    method tagText {type str args} {
        set tagOpts {}
        set textOpts {}
        foreach {option value} $args {
            if {$option in {-alt -actualtext -title -lang -scope -colspan
                    -rowspan -summary
                            -listnumbering -id -headers}} {
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
        # Not refused inside an XObject: an artifact never carries an MCID,
        # because nothing refers to it. It needs neither a parent tree entry
        # nor /Stm in an /MCR -- which is precisely what structure inside an
        # XObject would need. For a purely decorative block
        # "/Artifact BMC ... EMC" is the correct and only marking required.
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

    # Refuse a structure element whose parent the standard does not allow.
    # Called from tagBegin before the element exists, so a rejected call
    # leaves the tree exactly as it was.
    method TagCheckNesting {type parent} {
        variable ::pdf4tcl::StructParents
        if {![dict exists $::pdf4tcl::StructParents $type]} { return }
        set allowed [dict get $::pdf4tcl::StructParents $type]
        set ptype [my TagEffectiveParent $parent]
        if {$ptype in $allowed} { return }
        set names [join $allowed " or "]
        throw {PDF4TCL} "$type must be inside $names, not $ptype"
    }

    # Type of the element a child is structurally attached to: the nearest
    # ancestor that is not transparent. The root element is a Document even
    # before anything is nested in it.
    method TagEffectiveParent {idx} {
        variable ::pdf4tcl::TransparentStructTypes
        while {$idx >= 0} {
            set type $pdf(tag,type,$idx)
            if {$type ni $::pdf4tcl::TransparentStructTypes} { return $type }
            set idx $pdf(tag,parent,$idx)
        }
        return Document
    }

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
    # Which object owns the marked content being written? For a page that is
    # the page object; inside a form XObject it is the XObject's own stream,
    # because MCIDs are scoped to the content stream, not to the page
    # (ISO 32000-1 clause 14.7.4.4). pdf(pageobjid) does not even exist
    # while an XObject is open -- pdf4tcl only sets it for real pages.
    method TagScopeOid {} {
        if {$pdf(inXObject)} { return $pdf(contentoid) }
        return $pdf(pageobjid)
    }

    method TagSyncPage {} {
        set page [my TagScopeOid]
        if {$pdf(tag,curpage) eq $page} { return }
        set pdf(tag,curpage)  $page
        set pdf(tag,nextmcid) 0
        if {![info exists pdf(tag,pagekids,$page)]} {
            set pdf(tag,pagekids,$page) {}
            set pdf(tag,spnum,$page) $pdf(tag,nextkey)
            incr pdf(tag,nextkey)
            lappend pdf(tag,pagelist) $page
            if {$pdf(inXObject) && $page ni $pdf(tag,xobjlist)} {
                lappend pdf(tag,xobjlist) $page
            }
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
    # Number of painting operations that belonged to neither a structure
    # element nor an artifact. Zero is what PDF/UA clause 7.1 asks for.
    method getUntaggedCount {} {
        my TagInit
        return $pdf(tag,untagged)
    }

    # Report leftover content once, when the document is finished. A warning
    # and not an error: untagged content is legal PDF, and a caller who tags
    # part of a page may well mean it. What it is not is PDF/UA conformant,
    # and nothing else in the toolchain says so -- veraPDF cannot know which
    # operators were meant to be content.
    method TagUntaggedReport {} {
        my TagInit
        if {!$pdf(tag,active)} { return }
        if {$pdf(tag,untagged) == 0} { return }
        set pages [llength $pdf(tag,untagpage)]
        set what "tagged: $pdf(tag,untagged) painting operation(s) on\
                $pages page(s) belong to neither a structure element nor an\
                artifact."
        if {$pdf(tag,uapart) ne "" || [string match {*a} $options(-pdfa)]} {
            append what " ISO 14289-1 clause 7.1 requires every piece of\
                    content to be one or the other, so this document does not\
                    meet the level it claims."
        } else {
            append what " That is legal PDF but not PDF/UA conformant."
        }
        append what " Wrap the content in tagBegin/tagEnd, or mark it with\
                tagArtifact if it carries no meaning."
        lappend ::pdf4tcl::warnings $what
    }

    method TagEnsureMC {{op ""}} {
        if {![my TagActive]} { return }
        # Artifacts own the marked content while they are open, and the guard
        # keeps the Pdfout calls below from re-entering this method.
        if {$pdf(tag,artdepth) > 0 || $pdf(tag,mcguard)} { return }
        if {[llength $pdf(tag,stack)] == 0} {
            # Nothing is open and no artifact is running: this painting
            # operation belongs to neither. ISO 14289-1 clause 7.1 wants
            # every piece of content either tagged or marked as an artifact,
            # so count it -- see TagUntaggedReport, called from finish.
            # Content inside an XObject counts too: since 0.9.4.46 it can
            # be tagged, so leaving it untagged is the same omission as on a
            # page. An XObject placed under a tagged "Do" and left untagged
            # inside is the usual case, and it is reported the same way --
            # as a warning, not an error.
            variable ::pdf4tcl::PaintingOps
            if {$pdf(inPage) && $op in $::pdf4tcl::PaintingOps} {
                incr pdf(tag,untagged)
                set pg [llength $pdf(tag,pagelist)]
                if {$pg ni $pdf(tag,untagpage)} {
                    lappend pdf(tag,untagpage) $pg
                }
            }
            return
        }
        if {!$pdf(inPage)} { return }
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
        # Also for an XObject: its content stream starts its own marked
        # content, and TagSyncPage keys on pdf(pageobjid), which startPage
        # has just set to the XObject's own object id.
        set pdf(tag,open) ""
    }

    # Start of endPage, before the content stream is flushed: close the
    # marked content sequence still open on this page. BDC/EMC may not cross
    # a stream boundary (ISO 32000-1 clause 14.6).
    method TagPageEnd {} {
        if {![my TagActive]} { return }
        if {$pdf(tag,artdepth) > 0} {
            throw {PDF4TCL} "page ended with $pdf(tag,artdepth) open artifact(s)"
        }
        my TagCloseMC
    }

    # Extra entries for an annotation dictionary, called from AddAnnot before
    # the object is written.
    #
    # An annotation is attached to the structure tree by an /OBJR entry in the
    # element's /K array plus a /StructParent key in the annotation pointing
    # back (ISO 32000-1 clause 14.7.4.4). Only /Link and /Annot elements take
    # annotations; a link inside a paragraph therefore has to be wrapped:
    #
    #     $pdf tagBegin Link -alt "pdf4tcl home page"
    #     $pdf tagText Span "pdf4tcl" -x 50 -y 700
    #     $pdf hyperlinkAdd 50 698 60 14 "https://..."
    #     $pdf tagEnd
    #
    # PDF/UA rule 7.18.1 also wants the annotation itself to carry /Contents,
    # because that is what a reader announces for the link. It is filled from
    # the element's -alt when the caller did not supply one; an explicit
    # /Contents in the annotation dictionary always wins.
    method TagAnnotEntries {andict} {
        set pdf(tag,pendannot) ""
        if {![my TagActive]} { return "" }
        if {[llength $pdf(tag,stack)] == 0} {
            my TagAnnotUnattached ""
            return ""
        }
        set idx [lindex $pdf(tag,stack) end]
        # Form belongs here as much as Link and Annot: ISO 32000-1 table 337
        # gives /Form as the structure type of an interactive field, and
        # PDF/UA clause 7.18.1 wants the widget annotation attached to it
        # through /OBJR. Leaving it out meant tagBegin accepted the type
        # while the field stayed unreachable -- the element was in the tree,
        # the annotation was not, and the warning below fired for a document
        # that had done everything right.
        if {$pdf(tag,type,$idx) ni {Link Annot Form}} {
            my TagAnnotUnattached $pdf(tag,type,$idx)
            return ""
        }

        set key $pdf(tag,nextkey)
        incr pdf(tag,nextkey)
        set pdf(tag,pendannot) [list $key $idx]

        set out "/StructParent $key\n"
        set attrs $pdf(tag,attr,$idx)
        if {![regexp {/Contents[\s(<\[/]} $andict] && [dict exists $attrs -alt]} {
            append out "/Contents\
                    [::pdf4tcl::TagTextString [dict get $attrs -alt]]\n"
        }
        return $out
    }

    # An annotation was created while tagging is on, but not inside a Link or
    # Annot element, so it cannot be reached from the structure tree.
    #
    # This is the one thing in the tagged path that fails quietly: the link
    # still works when clicked and no error is raised, but assistive
    # technology never sees it, and PDF/UA rule 7.18 cannot be met. Nothing is
    # inferred -- guessing which paragraph a link belongs to would be wrong as
    # often as right -- so the caller is told instead.
    #
    # A warning rather than an error, because an untagged annotation is legal
    # PDF and existing code may rely on it. Reported once per document, like
    # the control character warning in QuoteString, so a page full of links
    # does not bury the message.
    method TagAnnotUnattached {openType} {
        if {$pdf(tag,annotwarned)} { return }
        set pdf(tag,annotwarned) 1
        if {$openType eq ""} {
            set where "no structure element is open"
        } else {
            set where "the open element is /$openType"
        }
        lappend ::pdf4tcl::warnings "tagged: an annotation was created while\
                $where, so it is not part of the structure tree and assistive\
                technology cannot reach it. Wrap it in\
                \"tagBegin Link -alt ...\" ... \"tagEnd\".\
                (further occurrences are not reported)"
    }

    # Bind the annotation object just written to the element that claimed it.
    method TagAnnotRegister {oid} {
        if {$pdf(tag,pendannot) eq ""} { return }
        lassign $pdf(tag,pendannot) key idx
        set pdf(tag,pendannot) ""
        lappend pdf(tag,kids,$idx) [list O $oid]
        lappend pdf(tag,annotkeys) $key $idx
    }

    # Tab order for a page carrying annotations.
    #
    # ISO 14289-1 clause 7.18.3: every page with an annotation must have
    # /Tabs /S, so that tabbing follows the structure tree rather than the
    # geometric row order. Untagged documents keep /R, which is what a plain
    # form wants.
    method TagTabOrder {} {
        if {[my TagActive]} { return "S" }
        return "R"
    }

    # Extra entries for the XObject dictionary, called from startPage while
    # the dictionary is still open.
    #
    # The key has to be allocated HERE, because pdf4tcl writes an XObject's
    # dictionary before its content stream -- when nobody knows yet whether
    # any marked content will follow. An XObject that ends up carrying none
    # gets an empty entry in the parent tree, which is legal and costs two
    # numbers.
    method TagXObjectDict {} {
        if {![my TagActive]} { return "" }
        set oid $pdf(contentoid)
        if {![info exists pdf(tag,spnum,$oid)]} {
            set pdf(tag,pagekids,$oid) {}
            set pdf(tag,spnum,$oid) $pdf(tag,nextkey)
            incr pdf(tag,nextkey)
            lappend pdf(tag,pagelist) $oid
            lappend pdf(tag,xobjlist) $oid
        }
        return "/StructParents $pdf(tag,spnum,$oid)\n"
    }

    # Record where an XObject is drawn. Called from putImage.
    #
    # An MCR inside an XObject names the stream in /Stm, and the page in
    # /Pg -- and that page is only known when the XObject is placed. Placed
    # twice, there are two pages for one MCID, and the reference stops
    # identifying anything; that case is refused in TagCheckXObjects.
    method TagXObjectPlaced {oid} {
        if {![my TagActive]} { return }
        if {![info exists pdf(tag,xobjplace,$oid)]} {
            set pdf(tag,xobjplace,$oid) [my TagScopeOid]
        } elseif {$pdf(tag,xobjplace,$oid) ne [my TagScopeOid]
                || $pdf(tag,xobjplace,$oid) eq "many"} {
            set pdf(tag,xobjplace,$oid) "many"
        } else {
            # Same page twice: still ambiguous.
            set pdf(tag,xobjplace,$oid) "many"
        }
    }

    # Called from finish, before the structure is written.
    #
    # Two different things are checked here, and only one of them is fatal.
    #
    # 1. Tagged content in an XObject drawn more than once is refused: one
    #    structure tree cannot describe two appearances, and /Pg would have
    #    to name two pages (ISO 32000-1 clause 14.7.4.4).
    #
    # 2. ANY form XObject drawn more than once is reported, tagged or not.
    #    Measured with veraPDF 1.30.2: every placement beyond the first
    #    fails PDF/UA rule 7.20-2, "The content of Form XObjects shall be
    #    incorporated into structure elements" -- one failed check per
    #    extra placement (1 placement 0, 2 placements 1, 3 placements 2).
    #    It makes no difference how the content is marked: artifact inside
    #    the XObject, artifact around the Do, Figure around the Do, or
    #    nothing at all -- all four fail from the second placement on.
    #
    #    This matters because the obvious workaround for 1 -- leave the
    #    content untagged and tag the "Do" -- does not produce a conformant
    #    file either. It stays a warning: reuse is perfectly good PDF, and
    #    a document claiming neither PDF/UA nor level A may do it.
    method TagCheckXObjects {} {
        if {![my TagActive]} { return }
        foreach oid $pdf(tag,xobjlist) {
            if {![llength $pdf(tag,pagekids,$oid)]} { continue }
            if {![info exists pdf(tag,xobjplace,$oid)]} {
                lappend ::pdf4tcl::warnings "XObject $oid carries tagged\
                        content but is never drawn -- its structure elements
                        point at nothing"
                continue
            }
            if {$pdf(tag,xobjplace,$oid) eq "many"} {
                throw {PDF4TCL} "XObject $oid carries tagged content and is\
                        drawn more than once. One structure tree cannot\
                        describe two appearances (ISO 32000-1 clause\
                        14.7.4.4). Draw it once -- and note that under\
                        PDF/UA a form XObject may not be reused at all."
            }
        }
        foreach key [array names pdf tag,xobjplace,*] {
            if {$pdf($key) ne "many"} { continue }
            set num [lindex [split $key ,] 2]
            lappend ::pdf4tcl::warnings "XObject $num is drawn more than\
                    once. Valid PDF, but not PDF/UA: veraPDF reports rule\
                    7.20-2 once per extra placement, whatever the content\
                    is marked as. For a conformant document, give each\
                    placement its own XObject."
        }
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
                        if {$page in $pdf(tag,xobjlist)} {
                            # Content inside a form XObject: /Stm names the
                            # stream the MCID belongs to, /Pg the page the
                            # stream is drawn on (clause 14.7.4.4).
                            #
                            # An XObject that is never drawn has no page.
                            # TagCheckXObjects has already warned about it;
                            # the reference is written without /Pg rather
                            # than dropped, so the element still says which
                            # stream it belongs to instead of vanishing.
                            if {[info exists pdf(tag,xobjplace,$page)]
                                    && $pdf(tag,xobjplace,$page) ne "many"} {
                                set pg $pdf(tag,xobjplace,$page)
                                lappend kids "<</Type /MCR /Pg $pg 0 R\
                                        /Stm $page 0 R /MCID $mcid>>"
                            } else {
                                lappend kids "<</Type /MCR /Stm $page 0 R\
                                        /MCID $mcid>>"
                            }
                        } else {
                            lappend kids "<</Type /MCR /Pg $page 0 R /MCID $mcid>>"
                        }
                    }
                    O {
                        # Annotation attached to this element, ISO 32000-1
                        # clause 14.7.4.4. /Pg is omitted: the annotation is
                        # reached through the page's /Annots array anyway.
                        lappend kids "<</Type /OBJR /Obj [lindex $kid 1] 0 R>>"
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
            # /A entries. Table and List attributes live in different owner
            # dictionaries, so they cannot be merged into one.
            set aList {}
            set tableAttrs {}
            if {[dict exists $attrs -scope]} {
                lappend tableAttrs "/Scope /[dict get $attrs -scope]"
            }
            if {[dict exists $attrs -summary]} {
                lappend tableAttrs "/Summary\
                        [::pdf4tcl::TagTextString [dict get $attrs -summary]]"
            }
            foreach {opt name} {-colspan ColSpan -rowspan RowSpan} {
                if {[dict exists $attrs $opt]} {
                    # A span of 1 is the default and adds nothing.
                    if {[dict get $attrs $opt] > 1} {
                        lappend tableAttrs "/$name [dict get $attrs $opt]"
                    }
                }
            }
            if {[dict exists $attrs -headers]} {
                set ids {}
                foreach id [dict get $attrs -headers] {
                    lappend ids [::pdf4tcl::TagTextString $id]
                }
                lappend tableAttrs "/Headers \[[join $ids { }]\]"
            }
            if {[llength $tableAttrs] > 0} {
                lappend aList "<</O /Table [join $tableAttrs { }]>>"
            }
            if {[dict exists $attrs -listnumbering]} {
                lappend aList "<</O /List /ListNumbering\
                        /[dict get $attrs -listnumbering]>>"
            }
            if {[llength $aList] == 1} {
                append body "/A [lindex $aList 0]\n"
            } elseif {[llength $aList] > 1} {
                append body "/A \[[join $aList { }]\]\n"
            }
            if {[dict exists $attrs -id]} {
                append body "/ID\
                        [::pdf4tcl::TagTextString [dict get $attrs -id]]\n"
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
        # ISO 32000-1 clause 7.9.7: the keys of a number tree must appear in
        # increasing order, so page and annotation entries are merged rather
        # than written one group after the other.
        set entries {}
        foreach page $pdf(tag,pagelist) {
            set refs {}
            foreach idx $pdf(tag,pagekids,$page) {
                lappend refs "$pdf(tag,oid,$idx) 0 R"
            }
            ##nagelfar ignore Found constant
            dict set entries $pdf(tag,spnum,$page) "\[[join $refs { }]\]"
        }
        # An annotation is a single structure element, not a list of them, so
        # its entry is a plain reference (clause 14.7.4.4).
        foreach {key idx} $pdf(tag,annotkeys) {
            ##nagelfar ignore Found constant
            dict set entries $key "$pdf(tag,oid,$idx) 0 R"
        }
        my Pdfout "<</Nums \[\n"
        foreach key [lsort -integer [dict keys $entries]] {
            my Pdfout "$key [dict get $entries $key]\n"
        }
        my Pdfout "\]>>\n"
        my Pdfout "endobj\n\n"

        my StoreXref $pdf(tag,rootoid)
        my Pdfout "$pdf(tag,rootoid) 0 obj\n"
        my Pdfout "<</Type /StructTreeRoot\n"
        my Pdfout "/K \[$pdf(tag,oid,$pdf(tag,root)) 0 R\]\n"
        my Pdfout "/ParentTree $parentTreeOid 0 R\n"
        my Pdfout "/ParentTreeNextKey $pdf(tag,nextkey)\n"
        my Pdfout ">>\n"
        my Pdfout "endobj\n\n"
    }
}
