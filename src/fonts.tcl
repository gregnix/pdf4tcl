namespace eval pdf4tcl {
    # Font Variables

    variable ttfpos 0
    variable ttfdata
    # Base font attributes:
    variable BFA
    # BaseFontParts for TTF fonts:
    variable BFP
    # List of all created fonts:
    variable Fonts
    variable FontsAttrs
    # For currently processed font:
    variable ttfname ""
    variable ttftables
    variable type1AFM
    variable type1PFB


    # ===== Procs for TrueType fonts processing =====

    proc createBaseTrueTypeFont {basefontname ttf_data {validate 0}} {
        variable BFP
        variable ttfname $basefontname
        variable ttfdata $ttf_data
        set BFP($basefontname,rawttf) $ttf_data
        InitBaseTTF $validate
    }

    proc loadBaseTrueTypeFont {basefontname filename {validate 0}} {
        variable BFP
        variable ttfname $basefontname
        variable ttfdata
        set fd [open $filename]
        fconfigure $fd -translation binary
        set ttfdata [read $fd]
        close $fd
        set BFP($basefontname,rawttf)  $ttfdata
        set BFP($basefontname,filename) $filename
        InitBaseTTF $validate
    }

    proc InitBaseTTF {validate} {
        variable BFA
        variable BFP
        variable ttfname
        variable ttfdata
        variable ttftables
        variable ttfpos 0

        set BFA($ttfname,FontType) TTF
        set subfontIndex 0

        if {[ReadHeader]} {
            ReadTTCHeader
            GetSubfont $subfontIndex $validate
        } else {
            ChecksumFile
            ReadTableDirectory $validate
            set BFA($ttfname,subfontNameX) ""
        }

        # Detect color/bitmap-only fonts -- not supported by pdf4tcl.
        # Check before ExtractInfo since these fonts may lack required
        # outline tables (loca, glyf) causing confusing errors later.
        # CBDT/CBLC: color bitmap glyphs (NotoColorEmoji)
        # sbix:      Apple bitmap glyphs (macOS system emoji)
        # COLR/CPAL: layered color vector glyphs (Segoe UI Emoji)
        foreach bitmapTable {CBDT CBLC sbix COLR} {
            if {[info exists ttftables($bitmapTable)]} {
                unset -nocomplain ttfdata
                unset -nocomplain ttftables
                throw {PDF4TCL} \
                    "TTF: color/bitmap font detected (table '$bitmapTable'\
                     in font '$ttfname'). Only outline fonts are supported.\
                     Use NotoEmoji-Regular.ttf (vector outlines) instead of\
                     NotoColorEmoji.ttf."
            }
        }

        ExtractInfo

        unset -nocomplain ttfdata
        unset -nocomplain ttftables
        set BFA($ttfname,SubFontIdx) 0
    }

    # Pad data with zero bytes to: len % 4 == 0
    proc CalcTTFCheckSum {data pos len} {
        binary scan $data "@${pos}Iu[expr {$len >> 2}]" datalst

        if {$len & 3} {
            set s [expr {$pos + (($len >> 2) << 2)}]
            set e [expr {$s + ($len & 3)}]
            set lc "[string range $data $s $e][string repeat "\0" 3]"
            binary scan $lc "Iu" lastb
            lappend datalst $lastb
        }

        set sum 0
        foreach u_int32 $datalst {
            incr sum $u_int32
        }
        set sum [expr {$sum & 0xFFFFFFFF}]
        return $sum
    }

    # read the sfnt header at the current position:
    proc ReadHeader {} {
        variable ttfpos
        variable ttfdata
        set ttfVersions [list 65536 1953658213 1953784678]

        binary scan $ttfdata "@${ttfpos}Iu" version
        incr ttfpos 4
        if {$version == 0x4F54544F} {
            throw {PDF4TCL} "TTF: postscript outlines are not supported"
        }
        if {$version ni $ttfVersions} {
            throw {PDF4TCL} "not a TrueType font: version=$version"
        }
        return [expr {$version == [lindex $ttfVersions end]}]
    }

    proc ChecksumFile {} {
        variable ttfdata
        set checksum [CalcTTFCheckSum $ttfdata 0 [string length $ttfdata]]
        if {$checksum != 0xB1B0AFBA} {
            throw {PDF4TCL} "invalid TTF file checksum [format %X $checksum]"
        }
    }

    proc ReadTTCHeader {} {
        variable ttfname
        variable ttfpos
        variable ttfdata
        variable BFA
        variable ttfSubFontOffsets
        set ttcVersions [list 65536 131072]

        binary scan $ttfdata "@${ttfpos}IuIu" \
                ttcVersion BFA($ttfname,numSubfonts)
        incr ttfpos 8

        if {$ttcVersion ni $ttcVersions} {
            throw {PDF4TCL} "not a TTC file"
        }

        binary scan $ttfdata "@${ttfpos}Iu$BFA($ttfname,numSubfonts)" \
                ttfSubFontOffsets
        incr ttfpos [expr {$BFA($ttfname,numSubfonts) * 4}]
    }

    proc GetSubfont {subfontIndex {validate 0}} {
        variable ttfpos
        variable ttfSubFontOffsets
        if {$subfontIndex >= [llength $ttfSubFontOffsets]} {
            throw {PDF4TCL} "bad subfontIndex $subfontIndex"
        }
        set ttfpos [lindex $ttfSubFontOffsets $subfontIndex]
        ReadHeader
        ReadTableDirectory $validate
    }

    proc ReadTableDirectory {validate} {
        variable ttfdata
        variable ttfpos
        variable ttftables
        variable ttfname
        variable BFP
        variable BFA
        # Must copy only needed tables here, if they exist:
        set NT [list "name" "OS/2" "cvt " "fpgm" "prep" \
                "glyf" "post" "hhea" "maxp" "head"]

        # 'srange', 'esel' and 'rshift' are UNUSED
        binary scan $ttfdata "@${ttfpos}SuSuSuSu" numTables srange esel rshift
        incr ttfpos 8

        for {set f 0} {$f < $numTables} {incr f} {
            # list is 'checksum offset length'
            binary scan $ttfdata "@${ttfpos}a4Iu3" tag rlist
            incr ttfpos 16
            set ttftables($tag) $rlist
            if {$tag in $NT} {
                foreach {cksum offset len} $rlist break
                set last [expr {$offset + $len - 1}]
                set BFP($ttfname,$tag) [string range $ttfdata $offset $last]
                lappend BFA($ttfname,tables) $tag
            }
        }
        if {$validate} ChecksumTables
    }

    # Check the checksums for all tables
    proc ChecksumTables {} {
        variable ttftables
        variable ttfdata

        foreach t [array names ttftables] {
            foreach {checksum offset length} $ttftables($t) break
            set RCkSum [CalcTTFCheckSum $ttfdata $offset $length]
            if {$t eq "head"} {
                incr offset 8
                binary scan $ttfdata "@${offset}Iu" adjustment
                set RCkSum [expr {($RCkSum - $adjustment) & 0xFFFFFFFF}]
            }
            if {$RCkSum != $checksum} {
                throw {PDF4TCL} "TTF: invalid checksum of table $t"
            }
        }
    }

    # Extract typographic information from the loaded font file.
    #
    # The following attributes will be set::
    #
    #    name         PostScript font name
    #    flags        Font flags
    #    ascend       Typographic ascender in 1/1000ths of a point
    #    descend      Typographic descender in 1/1000ths of a point
    #    CapHeight    Cap height in 1/1000ths of a point (0 if not available)
    #    bbox         Glyph bounding box [l,b,r,t] in 1/1000ths of a point
    #    _bbox        Glyph bounding box [l,b,r,t] in unitsPerEm
    #    unitsPerEm   Glyph units per em
    #    ItalicAngle  Italic angle in degrees ccw
    #    stemV        stem weight in 1/1000ths of a point (approximate)
    #
    # If charInfo is true, the following will also be set::
    #
    #    defaultWidth   default glyph width in 1/1000ths of a point
    #    charWidths     dictionary of character widths for every supported UCS
    #                   character code
    #
    # This will only work if the font has a Unicode cmap (platform 3,
    # encoding 1, format 4 or platform 0 any encoding format 4).  Setting
    # charInfo to false avoids this requirement
    proc ExtractInfo {{charInfo 1}} {
        variable ttfdata
        variable ttftables
        variable ttfpos
        variable ttfname
        variable BFA

        # name - Naming table
        set name_pos [lindex $ttftables(name) 1]
        set ttfpos $name_pos
        binary scan $ttfdata "@${ttfpos}SuSuSu" fmt NumRecords SDoffset
        if {$fmt != 0} {
            throw {PDF4TCL} "TTF: Unknown name table format $fmt"
        }
        incr ttfpos 6
        set SDoffset [expr {$name_pos + $SDoffset}]
        array set names {1 "" 2 "" 3 "" 4 "" 6 ""}
        set NIDS [array names names]
        set nameCount [llength $NIDS]

        for {set f 0} {$f < $NumRecords} {incr f} {
            binary scan $ttfdata "@${ttfpos}SuSuSuSuSuSu" PlId EncId LangId \
                    nameId length offset
            incr ttfpos 12
            if {$nameId ni $NIDS} {
                continue
            }
            set npos [expr {$SDoffset + $offset}]
            set nend [expr {$npos + $length - 1}]
            set Nstr [string range $ttfdata $npos $nend]
            set N ""

            if {$PlId == 3 && $EncId == 1 && $LangId == 0x409} {
                # Microsoft, Unicode, US English, PS Name
                if {$length & 1} {
                    throw {PDF4TCL} \
                            "PostScript name is UTF-16 string of odd length"
                }
                # Try to read a string of unicode chars:
                set N [encoding convertfrom unicode $Nstr]
            } elseif {$PlId == 1 && $EncId == 0 && $LangId == 0} {
                # Macintosh, Roman, English, PS Name
                # According to OpenType spec, if PS name exists, it must exist
                # both in MS Unicode and Macintosh Roman formats. Apparently,
                # you can find live TTF fonts which only have Macintosh format.
                set N [encoding convertfrom iso8859-1 $Nstr]
            }
            if {[string length $N] && $names($nameId) == ""} {
                set names($nameId) $N
                incr nameCount -1
                if {$nameCount == 0} break
            }
        }

        set BFA($ttfname,psName) [string map {" " -} $names(6)]
        if {$BFA($ttfname,psName) eq ""} {
            # Font has no PostScript name (NameID 6) in its name table.
            # This violates the OpenType spec but occurs in some fonts
            # (e.g. DroidSansFallback). Derive a fallback name from the
            # base font name. The resulting PDF is valid for normal use
            # but NOT suitable for PDF/A (ISO 19005 requires FontName to
            # match the embedded font's internal PostScript name).
            variable BFP
            if {[info exists BFP($ttfname,filename)]} {
                set _base [file rootname [file tail $BFP($ttfname,filename)]]
            } else {
                set _base $ttfname
            }
            # Strip characters not allowed in PS names
            set BFA($ttfname,psName) \
                [regsub -all {[^A-Za-z0-9_-]} $_base {}]
            set BFA($ttfname,psNameFallback) 1
            puts stderr "pdf4tcl warning: font \"$ttfname\" has no PostScript\
name (NameID 6). Using fallback \"$BFA($ttfname,psName)\".\
Not suitable for PDF/A.\
Note: some fonts without a PS name (e.g. DroidSansFallback) also have\
an invisible .notdef glyph -- missing characters will show as blank\
space instead of the usual empty rectangle."
        }

        #----------------------------------
        # head - Font header table
        set ttfpos [lindex $ttftables(head) 1]
        binary scan $ttfdata "@${ttfpos}SuSuSux6Iux2Sux16SSSSx6SuSu" \
                ver_maj ver_min fnt_rev magic \
                BFA($ttfname,unitsPerEm) xMin yMin xMax yMax \
                indexToLocFormat glyphDataFormat

        if {$ver_maj != 1} {
            throw {PDF4TCL} "unknown head table version $ver_maj"
        }
        if {$magic != 0x5F0F3CF5} {
            throw {PDF4TCL} "invalid head table magic $magic"
        }

        set BFA($ttfname,bbox) [list \
                [Rescale $xMin] [Rescale $yMin] [Rescale $xMax] [Rescale $yMax]]

        # OS/2 - OS/2 and Windows metrics table (needs data from head table)
        if {[info exists ttftables(OS/2)]} {
            set ttfpos [lindex $ttftables(OS/2) 1]
            binary scan $ttfdata "@${ttfpos}Sux2Sux2Sux58SS" \
                    version usWeightClass fsType sTypoAscender sTypoDescender
            incr ttfpos 88

            set BFA($ttfname,ascend) [Rescale $sTypoAscender]
            set BFA($ttfname,descend) [Rescale $sTypoDescender]

            if {$version > 1} {
                binary scan $ttfdata "@${ttfpos}Su" sCapHeight
                set BFA($ttfname,CapHeight) [Rescale $sCapHeight]
            } else {
                set BFA($ttfname,CapHeight) $BFA($ttfname,ascend)
            }
        } else {
            # Microsoft TTFs require an OS/2 table; Apple ones do not.  Try to
            # cope. The data is not very important anyway.
            set usWeightClass 500
            set BFA($ttfname,ascend) [Rescale $yMax]
            set BFA($ttfname,descend) [Rescale $yMin]
            set BFA($ttfname,CapHeight) $BFA($ttfname,ascend)
        }

        set BFA($ttfname,stemV) [expr {50 + int(pow($usWeightClass / 65.0, 2))}]

        #----------------------
        # post - PostScript table (needs data from OS/2 table)
        set ttfpos [lindex $ttftables(post) 1]
        binary scan $ttfdata "@${ttfpos}SuSuSSuSSIu" \
                ver_maj ver_min itan0 itan1 ulpos ulthick isFixedPitch

        set BFA($ttfname,ItalicAngle) [expr {$itan0 + $itan1 / 65536.0}]

        set flags 4 ; # "symbolic".
        if {$BFA($ttfname,ItalicAngle) != 0} {set flags [expr {$flags | 64}]}
        if {$usWeightClass >= 600} {set flags [expr {$flags | (1 << 18)}]}
        if {$isFixedPitch} {set flags [expr {$flags | 1}]}
        set BFA($ttfname,flags) $flags
        set BFA($ttfname,fixed) $isFixedPitch

        # hhea - Horizontal header table
        set ttfpos [lindex $ttftables(hhea) 1]
        binary scan $ttfdata "@${ttfpos}SuSux28SuSu" \
                ver_maj ver_min metricDataFormat numberOfHMetrics
        if {$ver_maj != 1} {
            throw {PDF4TCL} "unknown hhea table version"
        }
        if {$metricDataFormat != 0} {
            throw {PDF4TCL} "unknown horizontal metric data format"
        }
        if {$numberOfHMetrics == 0} {
            throw {PDF4TCL} "number of horizontal metrics is 0"
        }

        # maxp - Maximum profile table
        set ttfpos [lindex $ttftables(maxp) 1]
        binary scan $ttfdata "@${ttfpos}SuSuSu" \
                ver_maj ver_min numGlyphs
        if {$ver_maj != 1} {
            throw {PDF4TCL} "unknown maxp table version"
        }
        if {!$charInfo} return

        # We don't care of this earlier:
        if {$glyphDataFormat != 0} {
            throw {PDF4TCL} "unknown glyph data format"
        }

        # cmap - Character to glyph index mapping table
        set ttfpos [lindex $ttftables(cmap) 1]
        set cmap_offset $ttfpos
        binary scan $ttfdata "@${ttfpos}x2Su" cmapTableCount
        incr ttfpos 4

        set priority 0
        for {set f 0} {$f < $cmapTableCount} {incr f} {
            binary scan $ttfdata "@${ttfpos}SuSuIu" platformID encodingID offset
            incr ttfpos 8

            binary scan $ttfdata "@[expr {$cmap_offset+$offset}]Su" format
            if {$format ni [list 4 6 10 12 13]} continue

            switch -glob -- $platformID,$encodingID,$priority {
                3,10,* {set stoffset $offset; break}
                0,4,* - 0,6,* {set stoffset $offset; set priority 3}
                3,1,0 - 3,1,1 {set stoffset $offset; set priority 2}
                3,*,0 {set stoffset $offset; set priority 1}
                0,5,0 {continue}
                0,*,0 - 1,0,0 - 1,1,0 {set stoffset $offset}
            }
        }

        if {![info exists stoffset]} {
            throw {PDF4TCL} "font does not have cmap for Unicode"
        }

        set unicode_cmap_offset [expr {$cmap_offset + $stoffset}]
        binary scan $ttfdata "@${unicode_cmap_offset}Su" format

        switch -exact -- $format {
            4 {
                binary scan $ttfdata "@${unicode_cmap_offset}x2Su" length
                set ttfpos [expr {$unicode_cmap_offset + 6}]
                binary scan $ttfdata "@${ttfpos}Su" segCount
                set segCount [expr {$segCount / 2}]
                set limit [expr {$unicode_cmap_offset + $length}]
                set ttfpos [expr {$unicode_cmap_offset + 14}]
                binary scan $ttfdata "@${ttfpos}Su$segCount" endCount
                set ttfpos [expr {$ttfpos + 2*$segCount + 2}]
                binary scan $ttfdata "@${ttfpos}Su$segCount" startCount
                set ttfpos [expr {$ttfpos + 2*$segCount}]
                binary scan $ttfdata "@${ttfpos}S$segCount" idDelta
                set ttfpos [expr {$ttfpos + 2*$segCount}]
                set idRangeOffset_start $ttfpos
                binary scan $ttfdata "@${ttfpos}Su$segCount" idRangeOffset

                # Now it gets tricky.
                for {set f 0} {$f < $segCount} {incr f} {
                    set r_start [lindex $startCount $f]
                    set r_end   [lindex $endCount   $f]
                    for {set unichar $r_start} {$unichar <= $r_end} {incr unichar} {
                        set r_offset [lindex $idRangeOffset $f]
                        set r_delta [lindex $idDelta $f]
                        if {$r_offset == 0} {
                            set glyph [expr {($unichar + $r_delta) & 0xFFFF}]
                        } else {
                            set offset [expr {($unichar - $r_start) * 2 + $r_offset}]
                            set offset [expr {$idRangeOffset_start + 2 * $f + $offset}]
                            if {$offset > $limit} {
                                # workaround for broken fonts (like Thryomanes)
                                set glyph 0
                            } else {
                                binary scan $ttfdata "@${offset}Su" glyph
                                if {$glyph != 0} {
                                    set glyph [expr {($glyph + $r_delta) & 0xFFFF}]
                                }
                            }
                        }
                        dict set BFA($ttfname,charToGlyph) $unichar $glyph
                        lappend glyphToChar($glyph) $unichar
                    }
                }
            }
            6 {
                set ttfpos [expr {$unicode_cmap_offset + 6}]
                binary scan $ttfdata "@${ttfpos}SuSu" first count
                set last [expr {$first + $count}]
                incr ttfpos 4
                for {set unichar $first} {$unichar < $last} {incr unichar} {
                    binary scan $ttfdata "@${ttfpos}Su" glyph
                    dict set BFA($ttfname,charToGlyph) $unichar $glyph
                    lappend glyphToChar($glyph) $unichar
                    incr ttfpos 2
                }
            }
            10 {
                set ttfpos [expr {$unicode_cmap_offset + 12}]
                binary scan $ttfdata "@${ttfpos}IuIu" first count
                set last [expr {$first + $count}]
                incr ttfpos 4
                for {set unichar $first} {$unichar < $last} {incr unichar} {
                    binary scan $ttfdata "@${ttfpos}Su" glyph
                    dict set BFA($ttfname,charToGlyph) $unichar $glyph
                    lappend glyphToChar($glyph) $unichar
                    incr ttfpos 2
                }
            }
            12 {
                set ttfpos [expr {$unicode_cmap_offset + 12}]
                binary scan $ttfdata "@${ttfpos}Iu" segCount
                incr ttfpos 4
                for {set f 0} {$f < $segCount} {incr f} {
                    binary scan $ttfdata "@${ttfpos}IuIuIu" start end glyph
                    for {set unichar $start} {$unichar <= $end} {incr unichar} {
                        dict set BFA($ttfname,charToGlyph) $unichar $glyph
                        lappend glyphToChar($glyph) $unichar
                        incr glyph
                    }
                    incr ttfpos 12
                }
            }
            13 {
                set ttfpos [expr {$unicode_cmap_offset + 12}]
                binary scan $ttfdata "@${ttfpos}Iu" segCount
                incr ttfpos 4
                for {set f 0} {$f < $segCount} {incr f} {
                    binary scan $ttfdata "@${ttfpos}IuIuIu" start end glyph
                    for {set unichar $start} {$unichar <= $end} {incr unichar} {
                        dict set BFA($ttfname,charToGlyph) $unichar $glyph
                        lappend glyphToChar($glyph) $unichar
                    }
                    incr ttfpos 12
                }
            }
        }

        #-----------------------------------------------------
        # hmtx - Horizontal metrics table
        # (needs data from hhea, maxp, and cmap tables)
        set ttfpos [lindex $ttftables(hmtx) 1]
        for {set glyph 0} {$glyph < $numberOfHMetrics} {incr glyph} {
            # advance width and left side bearing. lsb is actually signed
            # short, but we don't need it anyway (except for subsetting)
            binary scan $ttfdata "@${ttfpos}SuSu" aw lsb
            incr ttfpos 4
            lappend BFA($ttfname,hmetrics) [list $aw $lsb]
            set aws [Rescale $aw]
            if {$glyph == 0} {set BFA($ttfname,defaultWidth) $aws}
            if {[info exists glyphToChar($glyph)]} {
                foreach char $glyphToChar($glyph) {
                    dict set BFA($ttfname,charWidths) $char $aws
                }
            }
        }

        # The rest of the table only lists advance left side bearings.
        # so we reuse aw set by the last iteration of the previous loop.
        # -- BUG (in reportlab) fixed here: aw used scaled in hmetrics,
        # -- i.e. float (must be int)
        for {set glyph $numberOfHMetrics} {$glyph < $numGlyphs} {incr glyph} {
            binary scan $ttfdata "@${ttfpos}Su" lsb
            incr ttfpos 2
            lappend BFA($ttfname,hmetrics) [list $aw $lsb]
            if {[info exists glyphToChar($glyph)]} {
                foreach char $glyphToChar($glyph) {
                    dict set BFA($ttfname,charWidths) $char $aws
                }
            }
        }

        # loca - Index to location
        if {![info exists ttftables(loca)]} {
            throw {PDF4TCL} "font does not have \"loca\" part"
        }
        set ttfpos [lindex $ttftables(loca) 1]
        incr numGlyphs
        if {$indexToLocFormat == 0} {
            binary scan $ttfdata "@${ttfpos}Su$numGlyphs" glyphPositions
            foreach el $glyphPositions {
                lappend BFA($ttfname,glyphPos) [expr {$el << 1}]
            }
        } elseif {$indexToLocFormat == 1} {
            binary scan $ttfdata "@${ttfpos}Iu$numGlyphs" BFA($ttfname,glyphPos)
        } else {
            throw {PDF4TCL} "unknown location table format $indexToLocFormat"
        }
    }

    proc Rescale {x} {
        variable BFA
        variable ttfname
        return [expr {$x * 1000.0 / $BFA($ttfname,unitsPerEm)}]
    }

    proc ConvertToUTF16BE {uchar} {
        if {$uchar < 65536} {
            return $uchar
        }
        set uchar [expr {$uchar - 0x010000}]
        return [expr {((0xD800 + ($uchar >> 10)) << 16) + (0xDC00 + ($uchar & 0x3FF))}]
    }

    # Creates a ToUnicode CMap for WinAnsiEncoding (Standard Type1 fonts).
    # Maps all 256 cp1252 byte values to their Unicode codepoints.
    # Undefined cp1252 bytes (0x81 0x8D 0x8F 0x90 0x9D) map to U+FFFD.
    # Result is a complete CMap stream string ready for MakeStream.
    proc MakeStdToUnicodeCMap {fontname} {
        # Build cp1252 -> Unicode table byte-by-byte (Tcl 9.0 safe)
        set subset {}
        for {set i 0} {$i < 256} {incr i} {
            if {[catch {
                set ch [encoding convertfrom cp1252 [binary format cu $i]]
                lappend subset [scan $ch %c]
            }]} {
                lappend subset 0xFFFD
            }
        }
        set cmap "/CIDInit /ProcSet findresource begin\n"
        append cmap "12 dict begin\n"
        append cmap "begincmap\n"
        append cmap "/CIDSystemInfo\n"
        append cmap "<< /Registry ($fontname)\n"
        append cmap "/Ordering (UCS)\n"
        append cmap "/Supplement 0\n"
        append cmap ">> def\n"
        append cmap "/CMapName /Adobe-Identity-UCS def\n"
        append cmap "/CMapType 1 def\n"
        append cmap "1 begincodespacerange\n"
        append cmap "<00> <FF>\n"
        append cmap "endcodespacerange\n"
        # Max 100 entries per block (PDF spec SS9.10.3)
        set f 0
        set remaining 256
        while {$remaining > 0} {
            set n [expr {$remaining > 100 ? 100 : $remaining}]
            append cmap "$n beginbfchar\n"
            for {set i 0} {$i < $n} {incr i} {
                set ucp [lindex $subset $f]
                if {$ucp <= 0xFFFF} {
                    append cmap [format "<%02X> <%04X>\n" $f $ucp]
                } else {
                    # SMP: UTF-16BE surrogate pair
                    append cmap [format "<%02X> <%08X>\n" $f [ConvertToUTF16BE $ucp]]
                }
                incr f
            }
            append cmap "endbfchar\n"
            incr remaining -100
        }
        append cmap "endcmap\n"
        append cmap "CMapName currentdict /CMap defineresource pop\n"
        append cmap "end\n"
        append cmap "end\n"
        return $cmap
    }

    # Creates a ToUnicode CMap for a given subset.
    proc MakeToUnicodeCMap {fontname subset} {
        set len [llength $subset]
        set cmap "/CIDInit /ProcSet findresource begin\n"
        append cmap "12 dict begin\n"
        append cmap "begincmap\n"
        append cmap "/CIDSystemInfo\n"
        append cmap "<< /Registry ($fontname)\n"
        append cmap "/Ordering ($fontname)\n"
        append cmap "/Supplement 0\n"
        append cmap ">> def\n"
        append cmap "/CMapName /$fontname def\n"
        append cmap "/CMapType 2 def\n"
        append cmap "1 begincodespacerange\n"
        append cmap "<00> <[format %02X [expr {$len-1}]]>\n"
        append cmap "endcodespacerange\n"
        # PDF spec §9.10.3: max 100 entries per beginbfchar block.
        set f 0
        set remaining $len
        while {$remaining > 0} {
            set n [expr {$remaining > 100 ? 100 : $remaining}]
            append cmap "$n beginbfchar\n"
            for {set i 0} {$i < $n} {incr i} {
                set uchar [lindex $subset $f]
                append cmap [format "<%02X> <%04X>\n" $f [ConvertToUTF16BE $uchar]]
                incr f
            }
            append cmap "endbfchar\n"
            incr remaining -100
        }
        append cmap "endcmap\n"
        append cmap "CMapName currentdict /CMap defineresource pop\n"
        append cmap "end\n"
        append cmap "end\n"
        return $cmap
    }

    # Create a subset of a TrueType font. Subset is a list of unicode values.
    proc MakeTTFSubset {bfname fontname subset} {
        variable BFA
        variable BFP
        variable FontsAttrs

        set GF_ARG_1_AND_2_ARE_WORDS     [expr {1 << 0}]
        set GF_WE_HAVE_A_SCALE           [expr {1 << 3}]
        set GF_MORE_COMPONENTS           [expr {1 << 5}]
        set GF_WE_HAVE_AN_X_AND_Y_SCALE  [expr {1 << 6}]
        set GF_WE_HAVE_A_TWO_BY_TWO      [expr {1 << 7}]

        # Build a mapping of glyphs in the subset to glyph numbers in
        # the original font.  Also build a mapping of UCS codes to
        # glyph values in the new font.

        # Start with 0 -> 0: "missing character"
        set glyphMap [list 0] ; # new glyph index -> old glyph index
        set glyphSet(0) 0     ; # old glyph index -> new glyph index
        #codeToGlyph            # unicode -> new glyph index
        foreach code $subset {
            if {[dict exists $BFA($bfname,charToGlyph) $code]} {
                set originalGlyphIdx [dict get $BFA($bfname,charToGlyph) $code]
            } else {
                set originalGlyphIdx 0
            }
            if {![info exists glyphSet($originalGlyphIdx)]} {
                set glyphSet($originalGlyphIdx) [llength $glyphMap]
                lappend glyphMap $originalGlyphIdx
            }
            set codeToGlyph($code) $glyphSet($originalGlyphIdx)
        }

        # Also include glyphs that are parts of composite glyphs
        set n 0
        while {$n < [llength $glyphMap]} {
            set originalGlyphIdx [lindex $glyphMap $n]
            set glyphPos [lindex $BFA($bfname,glyphPos) $originalGlyphIdx]
            set glyphEnd [lindex $BFA($bfname,glyphPos) $originalGlyphIdx+1]
            set glyphLen [expr {$glyphEnd - $glyphPos}]
            set cpos $glyphPos
            binary scan $BFP($bfname,glyf) "@${cpos}S" numberOfContours
            if {$numberOfContours < 0} {
                # composite glyph
                incr cpos 10
                set flags $GF_MORE_COMPONENTS
                while {$flags & $GF_MORE_COMPONENTS} {
                    binary scan $BFP($bfname,glyf) "@${cpos}SuSu" flags glyphIdx
                    incr cpos 4
                    if {![info exists glyphSet($glyphIdx)]} {
                        set glyphSet($glyphIdx) [llength $glyphMap]
                        lappend glyphMap $glyphIdx
                    }

                    if {$flags & $GF_ARG_1_AND_2_ARE_WORDS} {
                        incr cpos 4
                    } else {
                        incr cpos 2
                    }

                    if {$flags & $GF_WE_HAVE_A_SCALE} {
                        incr cpos 2
                    } elseif {$flags & $GF_WE_HAVE_AN_X_AND_Y_SCALE} {
                        incr cpos 4
                    } elseif {$flags & $GF_WE_HAVE_A_TWO_BY_TWO} {
                        incr cpos 8
                    }
                }
            }
            incr n
        }

        set n [llength $glyphMap]
        set numGlyphs $n

        while {$n > 1 && \
                [lindex $BFA($bfname,hmetrics) $n 0] == \
                [lindex $BFA($bfname,hmetrics) $n-1 0]} {
            incr n -1
        }
        set numberOfHMetrics $n

        # post - PostScript
        set    t(post) "\x00\x03\x00\x00"
        append t(post) [string range $BFP($bfname,post) 4 15]
        append t(post) [string repeat "\0" 16]

        # hhea - Horizontal Header
        set    t(hhea) [string range $BFP($bfname,hhea) 0 33]
        append t(hhea) [binary format Su $numberOfHMetrics]
        append t(hhea) [string range $BFP($bfname,hhea) 36 end]

        # maxp - Maximum Profile
        set    t(maxp) [string range $BFP($bfname,maxp) 0 3]
        append t(maxp) [binary format Su $numGlyphs]
        append t(maxp) [string range $BFP($bfname,maxp) 6 end]

        # cmap - Character to glyph mapping
        set entryCount [llength $subset]
        set length [expr {10 + $entryCount * 2}]
        foreach char $subset {lappend tlist $codeToGlyph($char)}
        set t(cmap) [binary format "SuSuSuSuSuSuSuSuSuSuSuSu*" 0 1 1 0 0 12 6 \
                $length 0 0 $entryCount $tlist]

        # hmtx - Horizontal Metrics
        for {set f 0} {$f < $numGlyphs} {incr f} {
            set originalGlyphIdx [lindex $glyphMap $f]
            foreach {aw lsb} [lindex $BFA($bfname,hmetrics) $originalGlyphIdx] break
            if {$f < $numberOfHMetrics} {
                append t(hmtx) [binary format Su $aw]
            }
            append t(hmtx) [binary format Su $lsb]
        }

        # glyf - Glyph data
        set pos 0
        for {set f 0} {$f < $numGlyphs} {incr f} {
            lappend offsets $pos
            set originalGlyphIdx [lindex $glyphMap $f]
            set glyphPos [lindex $BFA($bfname,glyphPos) $originalGlyphIdx]
            set glyphEnd [lindex $BFA($bfname,glyphPos) $originalGlyphIdx+1]
            set glyphLen [expr {$glyphEnd - $glyphPos}]
            set glyphEndPos [expr {$glyphPos + $glyphLen - 1}]
            set data [string range $BFP($bfname,glyf) $glyphPos $glyphEndPos]
            # Fix references in composite glyphs
            if {$glyphLen > 2} {
                binary scan $data "S" compos
                if {$compos < 0} {
                    set pos_in_glyph 10
                    set flags $GF_MORE_COMPONENTS
                    while {$flags & $GF_MORE_COMPONENTS} {
                        binary scan $data "@${pos_in_glyph}SuSu" flags glyphIdx
                        set odata $data
                        set data    [string range $odata 0 $pos_in_glyph+1]
                        append data [binary format Su $glyphSet($glyphIdx)]
                        append data [string range $odata $pos_in_glyph+4 end]
                        incr pos_in_glyph 4
                        if {$flags & $GF_ARG_1_AND_2_ARE_WORDS} {
                            incr pos_in_glyph 4
                        } else {
                            incr pos_in_glyph 2
                        }
                        if {$flags & $GF_WE_HAVE_A_SCALE} {
                            incr pos_in_glyph 2
                        } elseif {$flags & $GF_WE_HAVE_AN_X_AND_Y_SCALE} {
                            incr pos_in_glyph 4
                        } elseif {$flags & $GF_WE_HAVE_A_TWO_BY_TWO} {
                            incr pos_in_glyph 8
                        }
                    }
                }
            }
            append t(glyf) $data
            incr pos $glyphLen
            if {$pos % 4 != 0}  {
                set padding [expr {4 - $pos % 4}]
                append t(glyf) [string repeat "\0" $padding]
                incr pos $padding
            }

        }
        lappend offsets $pos

        # loca - Index to location
        if {(($pos + 1) >> 1) > 0xFFFF} {
            set indexToLocFormat 1 ; # long format
            set t(loca) [binary format "Iu*" $offsets]
        } else {
            set indexToLocFormat 0 ; # short format
            foreach offset $offsets {
                append t(loca) [binary format "Su" [expr {$offset >> 1}]]
            }
        }

        # head - Font header
        set    t(head) [string range $BFP($bfname,head) 0 7]
        append t(head) [string repeat "\0" 4]
        append t(head) [string range $BFP($bfname,head) 12 49]
        append t(head) [binary format Su $indexToLocFormat]
        append t(head) [string range $BFP($bfname,head) 52 end]
        #----------------------------------------------------------------------
        set tables [lsort -unique [concat $BFA($bfname,tables) [array names t]]]
        set numTables [llength $tables]

        set searchRange 1
        set entrySelector 0

        while {$searchRange * 2 <= $numTables} {
            set searchRange [expr {$searchRange * 2}]
            incr entrySelector
        }
        set searchRange [expr {$searchRange * 16}]
        set rangeShift [expr {$numTables * 16 - $searchRange}]

        # Header
        set res [binary format "IuSuSuSuSu" [expr {0x00010000}] $numTables \
                $searchRange $entrySelector $rangeShift]

        # Table directory
        set offset [expr {12 + $numTables * 16}]
        foreach tag $tables {
            if {$tag eq "head"} {set head_start $offset}
            if {[info exists t($tag)]} {
                set len [string length $t($tag)]
                set checksum [CalcTTFCheckSum $t($tag) 0 $len]
            } else {
                set len [string length $BFP($bfname,$tag)]
                set checksum [CalcTTFCheckSum $BFP($bfname,$tag) 0 $len]
            }
            append res [binary format a4IuIuIu $tag $checksum $offset $len]
            incr offset [expr {($len + 3) & ~3}]
        }

        # Table data.
        foreach tag $tables {
            if {[info exists t($tag)]} {
                set len [string length $t($tag)]
                append res $t($tag)
            } else {
                set len [string length $BFP($bfname,$tag)]
                append res $BFP($bfname,$tag)
            }
            append res [string repeat "\0" [expr {(4 - ($len & 3)) & 3}]]
        }

        set len [string length $res]
        set checksum [CalcTTFCheckSum $res 0 $len]
        incr head_start 7

        set checksum [expr {(0xB1B0AFBA - $checksum) & 0xFFFFFFFF}]
        set res "[string range $res 0 $head_start][binary format Iu $checksum][string range $res $head_start+5 end]"

        set FontsAttrs($fontname,data) $res
        set FontsAttrs($fontname,SubFontIdx) $BFA($bfname,SubFontIdx)
        incr BFA($bfname,SubFontIdx)
    }

    # make subfont name
    proc MakeSFNamePrefix {idx} {
        string map {0 A 1 B 2 C 3 D 4 E 5 F 6 G 7 H 8 I 9 J} [format %06d $idx]
    }

    # ----- General font support -----
    # Create Font from BaseFont:
    proc createFont {bfname fontname enc_name} {
        variable FontsAttrs
        variable BFA
        variable Fonts

        set subset [list]
        for {set f 0} {$f < 256} {incr f} {
            # Convert byte-by-byte: Tcl 9.0 is strict and rejects
            # undefined bytes (e.g. 0x81 in cp1252) when converting
            # a full 256-byte block at once.
            if {[catch {
                set unichar [encoding convertfrom $enc_name [binary format cu $f]]
                lappend subset [scan $unichar %c]
            }]} {
                lappend subset 0  ;# undefined byte -> .notdef
            }
        }

        if {$BFA($bfname,FontType) eq "TTF"} {
            # Create TTF subset here:
            MakeTTFSubset $bfname $fontname $subset
            set FontsAttrs($fontname,type) TTF
        } else {
            set FontsAttrs($fontname,type) Type1
        }

        lappend Fonts $fontname
        set FontsAttrs($fontname,basefontname) $bfname
        set FontsAttrs($fontname,uniset) $subset
        set FontsAttrs($fontname,specialencoding) 0
        set FontsAttrs($fontname,encoding) $enc_name
    }

    # Give list of available fonts
    proc getFonts {} {
        variable Fonts
        return $Fonts
    }

    # subset must be a list of unicode values:
    proc createFontSpecEnc {bfname fontname subset} {
        variable FontsAttrs
        variable BFA
        variable Fonts

        if {[llength $subset] > 256} {
            throw {PDF4TCL} "createFontSpecEnc: subset must not exceed 256 codepoints\
                (got [llength $subset])"
        }

        if {$BFA($bfname,FontType) eq "TTF"} {
            # Create TTF subset here:
            MakeTTFSubset $bfname $fontname $subset
            set FontsAttrs($fontname,type) TTF
        } else {
            set FontsAttrs($fontname,type) Type1
        }

        lappend Fonts $fontname
        set FontsAttrs($fontname,basefontname) $bfname
        set FontsAttrs($fontname,uniset) $subset
        set FontsAttrs($fontname,specialencoding) 1
        set FontsAttrs($fontname,encoding) {}

        set symcode 0
        foreach ucode $subset {
            set uchar [format %c $ucode]
            dict set FontsAttrs($fontname,encoding) $uchar \
                    [binary format cu $symcode]
            incr symcode
        }
    }

    # ===== Procs for Type1 fonts processing =====

    # Create encoding differences list:
    proc MakeEncDiff {BFN fontname} {
        variable BFA

        # get WinAnsiEncoding unicodes:
        # Byte-for-byte conversion with catch for Tcl 9.0 strict UTF-8 mode.
        # CP1252 bytes 0x81 0x8D 0x8F 0x90 0x9D are undefined -- they raise
        # an error in Tcl 9.0; map them to 0 (.notdef) instead.
        set bset [list]
        for {set f 0} {$f < 256} {incr f} {
            if {[catch {
                set unichar [encoding convertfrom cp1252 [binary format cu $f]]
                lappend bset [scan $unichar %c]
            }]} {
                lappend bset 0
            }
        }

        set f 0
        set res [list]
        set eqflag 1
        foreach ucode $::pdf4tcl::FontsAttrs($fontname,uniset) bcode $bset {
            if {$ucode != $bcode} {
                if {$eqflag} {lappend res $f}
                if {[dict exists $BFA($BFN,uni2glyph) $ucode]} {
                    lappend res "/[dict get $BFA($BFN,uni2glyph) $ucode]"
                } else {
                    lappend res "/.notdef"
                }
                set eqflag 0
            } else {
                set eqflag 1
            }
            incr f
        }
        return $res
    }

    proc PfbCheck {pos data mark} {
        binary scan $data "@${pos}cucu" d0 d1
        if {($d0 != 0x80) || ($d1 != $mark)} {
            throw {PDF4TCL} "bad pfb data at $pos"
        }
        if {$mark == 3} return; #PFB_EOF
        incr pos 2
        binary scan $data "@${pos}iu" l
        incr pos 4
        set npos [expr {$pos + $l}]
        if {$npos > [string length $data]} {
            throw {PDF4TCL} "pfb data is too short"
        }
        return $npos
    }

    # There's no need to create NEW binary stream, use font as is:
    proc ParsePFB {} {
        variable type1PFB
        variable type1name
        variable BFA
        set p1 [PfbCheck 0 $type1PFB 1]
        set p2 [PfbCheck $p1 $type1PFB 2]
        set p3 [PfbCheck $p2 $type1PFB 1]
        PfbCheck $p3 $type1PFB 3
        set BFA($type1name,Length1) [expr {$p1-6}]
        set BFA($type1name,Length2) [expr {$p2-$p1-6}]
        set BFA($type1name,Length3) [expr {$p3-$p2-6}]
        # Extract the type 1 font from PFB
        set d1 [string range $type1PFB 6 [expr {$p1 - 1}]]
        set d2 [string range $type1PFB [expr {$p1 + 6}] [expr {$p2 - 1}]]
        set d3 [string range $type1PFB [expr {$p2 + 6}] [expr {$p3 - 1}]]
        set BFA($type1name,data) $d1$d2$d3
    }

    # Creates charWidths and mapping 'unicode=>glyph_name' for this font.
    proc ParseAFM {} {
        variable type1AFM
        variable type1name
        variable BFA
        variable GlName2Uni

        array set nmap {Ascender ascend Descender descend FontBBox bbox}
        set BFA($type1name,ascend) 1000
        set BFA($type1name,descend) 0
        set BFA($type1name,CapHeight) 1000
        set BFA($type1name,ItalicAngle) 0
        set BFA($type1name,stemV) 0
        set BFA($type1name,bbox) [list 0 0 1000 1000]

        set lineslst [split $type1AFM "\n"]
        if {[llength $lineslst] < 2} {
            throw {PDF4TCL} "AFM hasn't enough data"
        }

        set InMetrics 0
        set InHeader 0
        foreach line $lineslst {
            if {[string equal -nocase -length 7 $line comment]} continue
            # StartCharMetrics terminates header:
            switch -nocase -glob -- $line {
                "StartCharMetrics*" {set InMetrics 1; continue}
                "StartFontMetrics*" {set InHeader 1; continue}
                "EndCharMetrics*"   {break}
            }

            if {$InMetrics} {
                set toklst [list]
                set reslst [list]
                # Create toklst -- list of needed tokens (only starting three):
                foreach chunk [lrange [split $line ";"] 0 2] {
                    foreach el $chunk {
                        lappend toklst $el
                    }
                }
                # Convert and store tokens:
                foreach {l r} $toklst {et ss} [list C %d WX %d N %s] {
                    if {$l != $et} {
                        throw {PDF4TCL} "bad line in font AFM ($et)"
                    }
                    if {![scan $r $ss val]} {
                        throw {PDF4TCL} "incorrect '$et' value in font AFM"
                    }
                    lappend reslst $val
                }
                # Must create charWidths and font's Uni2Glyph here:
                set N  [lindex $reslst 2]
                set WX [lindex $reslst 1]

                set ucode -1
                if {$N ne ".notdef"} {
                    catch {set ucode $GlName2Uni($N)}
                } else {
                    set ucode 0
                }
                if {($ucode == -1) && [string equal -length 3 $N "uni"]} {
                    scan $N "uni%x" ucode
                }

                if {$ucode != -1} {
                    dict set BFA($type1name,charWidths) $ucode $WX
                    dict set BFA($type1name,uni2glyph) $ucode $N
                }
            } elseif {$InHeader} {
                # Split into 2 parts on first space:
                set idx [string first " " $line]
                set l [string range $line 0 $idx-1]
                set r [string range $line $idx+1 end]
                if {[info exists nmap($l)]} {
                    set l $nmap($l)
                }
                set BFA($type1name,$l) $r
            }
        }
    }

    proc createBaseType1Font {basefontname afm_data pfb_data} {
        variable type1name $basefontname
        variable type1AFM $afm_data
        variable type1PFB $pfb_data
        InitBaseType1
    }

    proc loadBaseType1Font {basefontname AFMfilename PFBfilename} {
        variable type1name $basefontname
        variable type1AFM
        variable type1PFB
        set fd [open $AFMfilename "r"]
        set type1AFM [read $fd]
        close $fd
        set fd [open $PFBfilename "rb"]
        set type1PFB [read $fd]
        close $fd
        InitBaseType1
    }

    proc InitBaseType1 {} {
        variable type1name
        variable type1AFM
        variable type1PFB
        ParseAFM
        ParsePFB
        set ::pdf4tcl::BFA($type1name,FontType) Type1
        unset -nocomplain type1PFB
        unset -nocomplain type1AFM
        unset -nocomplain type1name
    }

    # Get the width of a character. "ch" must be exactly one char long.
    # Create a CID (Unicode/CJK) font spec for a previously loaded TTF base font.
    # Embeds the full font with Identity-H encoding; no 256-char limit.
    proc createFontSpecCID {bfname fontname} {
        variable FontsAttrs
        variable BFA
        variable Fonts

        if {![info exists BFA($bfname,FontType)]} {
            throw {PDF4TCL} "createFontSpecCID: base font '$bfname' not loaded (use loadBaseTrueTypeFont first)"
        }
        if {$BFA($bfname,FontType) ne "TTF"} {
            throw {PDF4TCL} "createFontSpecCID: only TTF base fonts are supported (got $BFA($bfname,FontType))"
        }

        set FontsAttrs($fontname,type)         CID
        set FontsAttrs($fontname,basefontname) $bfname
        # usedUnicode: dict mapping Unicode codepoint (int) -> GlyphID
        set FontsAttrs($fontname,usedUnicode)  {}
        lappend Fonts $fontname
    }

    proc GetCharWidth {font ch} {
        if {$ch eq "\n"} {
            return 0.0
        }
        # CID fonts: use charToGlyph + hmetrics for width lookup
        if {[info exists ::pdf4tcl::FontsAttrs($font,type)] &&
            $::pdf4tcl::FontsAttrs($font,type) eq "CID"} {
            scan $ch %c n
            set BFN $::pdf4tcl::FontsAttrs($font,basefontname)
            set res 0.0
            if {[dict exists $::pdf4tcl::BFA($BFN,charToGlyph) $n]} {
                set glyph [dict get $::pdf4tcl::BFA($BFN,charToGlyph) $n]
                set metrics [lindex $::pdf4tcl::BFA($BFN,hmetrics) $glyph]
                if {$metrics ne ""} {
                    set aw [lindex $metrics 0]
                    set res [expr {$aw * 1000.0 / $::pdf4tcl::BFA($BFN,unitsPerEm) * 0.001}]
                }
            } else {
                # Glyph not in font -- render as .notdef (GlyphID 0).
                # Use the actual .notdef advance width from hmetrics[0]
                # so getStringWidth is consistent with what the viewer shows.
                set metrics [lindex $::pdf4tcl::BFA($BFN,hmetrics) 0]
                if {$metrics ne ""} {
                    set aw [lindex $metrics 0]
                    set res [expr {$aw * 1000.0 / $::pdf4tcl::BFA($BFN,unitsPerEm) * 0.001}]
                }
            }
            return $res
        }
        # This can't fail since ch is always 1 char long
        scan $ch %c n

        set BFN $::pdf4tcl::FontsAttrs($font,basefontname)
        set res 0.0
        catch {set res [dict get $::pdf4tcl::BFA($BFN,charWidths) $n]}
        # Ticket #17: unmappable codepoint (res still 0.0) -- fall back to
        # width of '?' (codepoint 63) which is what CleanText actually renders.
        if {$res == 0.0 && $n != 32} {
            catch {set res [dict get $::pdf4tcl::BFA($BFN,charWidths) 63]}
        }
        set res [expr {$res * 0.001}]
        return $res
    }
}
