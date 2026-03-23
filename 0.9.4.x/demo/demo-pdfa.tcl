#!/usr/bin/env tclsh
# demo-pdfa.tcl -- PDF/A-Features Demonstration (pdf4tcl 0.9.4.23)
#
# Zeigt: -pdfa Option, XMP-Metadaten, pdfaid-Schema, OutputIntent,
#        /Group-Unterdrueckung, Metadaten-Synchronisation.
#
# Aufruf:
#   tclsh demo-pdfa.tcl
#   tclsh demo-pdfa.tcl --out /tmp
#   tclsh demo-pdfa.tcl --icc /usr/share/color/icc/ghostscript/srgb.icc
#   tclsh demo-pdfa.tcl --font /usr/share/fonts/truetype/dejavu/DejaVuSans.ttf
#
# Abhaengigkeiten:
#   pdf4tcl 0.9.4.20 (im uebergeordneten Verzeichnis)
#   DejaVuSans.ttf  (Debian/Ubuntu: apt install fonts-dejavu-core)
#   veraPDF (optional, fuer Validierung): https://verapdf.org
#
# Ausgabe:
#   demo-pdfa-1b.pdf   -- PDF/A-1b
#   demo-pdfa-2b.pdf   -- PDF/A-2b
#   demo-pdfa-none.pdf -- regulaeres PDF (Vergleich)

set demodir  [file dirname [file normalize [info script]]]
set reporoot [file normalize [file join $demodir ../..]]
set auto_path [linsert $auto_path 0 $reporoot]

package require pdf4tcl
set pkgver [package require pdf4tcl]

# -----------------------------------------------------------------------------
# Argumente verarbeiten
# -----------------------------------------------------------------------------

set out_dir      $demodir
set icc_override ""
set font_override ""

for {set i 0} {$i < [llength $argv]} {incr i} {
    set arg [lindex $argv $i]
    switch -- $arg {
        --out  { set out_dir      [lindex $argv [incr i]] }
        --icc  { set icc_override [lindex $argv [incr i]] }
        --font { set font_override [lindex $argv [incr i]] }
        default {
            puts stderr "Unbekanntes Argument: $arg"
            puts stderr "Aufruf: tclsh demo-pdfa.tcl \[--out dir\] \[--icc pfad\] \[--font pfad\]"
            exit 1
        }
    }
}

file mkdir $out_dir

# -----------------------------------------------------------------------------
# DejaVuSans TTF-Font suchen
# -----------------------------------------------------------------------------

set font_path $font_override
if {$font_path eq ""} {
    foreach candidate {
        /usr/share/fonts/truetype/dejavu/DejaVuSans.ttf
        /usr/share/fonts/TTF/DejaVuSans.ttf
        /usr/share/fonts/dejavu/DejaVuSans.ttf
        /Library/Fonts/DejaVuSans.ttf
        C:/Windows/Fonts/DejaVuSans.ttf
    } {
        if {[file exists $candidate]} { set font_path $candidate; break }
    }
}
if {$font_path eq "" || ![file exists $font_path]} {
    puts stderr "Fehler: DejaVuSans.ttf nicht gefunden."
    puts stderr "  Debian/Ubuntu: apt install fonts-dejavu-core"
    puts stderr "  Oder: tclsh demo-pdfa.tcl --font /pfad/zu/DejaVuSans.ttf"
    exit 1
}
puts "Font: $font_path"
pdf4tcl::loadBaseTrueTypeFont DejaVuSans $font_path
pdf4tcl::createFontSpecCID DejaVuSans cidSans

# -----------------------------------------------------------------------------
# sRGB ICC-Profil suchen
# -----------------------------------------------------------------------------

set icc_file $icc_override
if {$icc_file eq ""} {
    foreach candidate {
        /usr/share/color/icc/ghostscript/srgb.icc
        /usr/share/color/icc/ghostscript/sRGB.icc
        /usr/share/color/icc/sRGB.icc
        /usr/share/color/icc/colord/sRGB.icc
        /Library/ColorSync/Profiles/sRGB\ Profile.icc
    } {
        if {[file exists $candidate]} { set icc_file $candidate; break }
    }
}

# -----------------------------------------------------------------------------
# Hilfsprozeduren
# -----------------------------------------------------------------------------

proc section_header {pdf title y} {
    $pdf setFillColor 0.15 0.35 0.60
    $pdf rectangle 40 [expr {$y - 12}] 515 22 -filled 1
    $pdf setFillColor 1 1 1
    $pdf setFont 12 cidSans
    $pdf text $title -x 46 -y $y
    $pdf setFillColor 0 0 0
    return [expr {$y - 32}]
}

proc info_line {pdf label value x y} {
    $pdf setFont 10 cidSans
    $pdf text $label -x $x -y $y
    $pdf text $value -x [expr {$x + 160}] -y $y
    return [expr {$y - 16}]
}

proc check_verapdf {pdffile flavour} {
    if {[auto_execok verapdf] eq ""} {
        return {status notfound}
    }
    set fd [open "|verapdf --flavour $flavour --format xml $pdffile 2>/dev/null" r]
    set xml [read $fd]
    catch {close $fd}
    if {[string first {isCompliant="true"} $xml] >= 0} {
        return {status pass}
    } elseif {[regexp {failedChecks="([0-9]+)"} $xml -> n]} {
        return [list status fail failedChecks $n]
    }
    return {status unknown}
}

# -----------------------------------------------------------------------------
# Proc: ein Demo-PDF erzeugen
# -----------------------------------------------------------------------------

proc make_demo_pdf {outfile pdfa_variant icc_file pkgver} {
    set opts [list -compress 1 -paper a4 -orient 0]
    if {$pdfa_variant ne ""} {
        lappend opts -pdfa $pdfa_variant
        if {$icc_file ne ""} {
            lappend opts -pdfa-icc $icc_file
        }
    }

    set pdf [pdf4tcl::new %AUTO% {*}$opts]

    set variant_label [expr {$pdfa_variant eq "" ? "Standard PDF" : "PDF/A-$pdfa_variant"}]
    $pdf metadata \
        -title   "pdf4tcl PDF/A-Demo ($variant_label)" \
        -author  "pdf4tcl $pkgver" \
        -subject "Demonstration der PDF/A-Features" \
        -creator "pdf4tcl $pkgver"

    # -----------------------------------------------------------------------
    # Seite 1: Uebersicht
    # -----------------------------------------------------------------------
    $pdf startPage

    # Kopfzeile
    $pdf setFillColor 0.10 0.25 0.50
    $pdf rectangle 0 797 595 45 -filled 1
    $pdf setFillColor 1 1 1
    $pdf setFont 18 cidSans
    $pdf text "pdf4tcl $pkgver -- PDF/A Demo" -x 40 -y 812
    $pdf setFont 10 cidSans
    $pdf text $variant_label -x 40 -y 800
    $pdf setFillColor 0 0 0

    set y 760
    set y [section_header $pdf "1. Dokument-Modus" $y]

    set y [info_line $pdf "-pdfa Option:" \
        [expr {$pdfa_variant eq "" ? "(nicht gesetzt)" : $pdfa_variant}] 50 $y]
    # pdf(version) is set internally -- read via DebugGetInternalState
    set pdfver [dict get [$pdf DebugGetInternalState] version]
    set y [info_line $pdf "PDF-Standard:" \
        [expr {$pdfa_variant eq "" ? "PDF $pdfver (Standard)" : "PDF $pdfver (ISO 19005)"}] 50 $y]
    set y [info_line $pdf "XMP-Metadaten:" \
        [expr {$pdfa_variant ne "" ? "ja (pdfaid-Schema)" : "nein"}] 50 $y]
    set y [info_line $pdf "OutputIntent:" \
        [expr {$pdfa_variant ne "" ? "ja (sRGB IEC61966-2.1)" : "nein"}] 50 $y]
    set y [info_line $pdf "/Group Transparenz:" \
        [expr {[string match "1*" $pdfa_variant] ? "unterdrueckt (PDF/A-1)" : \
               ($pdfa_variant ne "" ? "erlaubt (PDF/A-2)" : "ja (Standard)")}] 50 $y]
    set y [info_line $pdf "Font-Einbettung:" \
        "CIDFont DejaVuSans (vollstaendig eingebettet)" 50 $y]

    incr y -10
    set y [section_header $pdf "2. XMP-Metadaten (ISO 19005-1 SS6.7.11)" $y]

    if {$pdfa_variant ne ""} {
        set part [string index $pdfa_variant 0]
        set conf [string toupper [string index $pdfa_variant 1]]
        set y [info_line $pdf "xmlns:pdfaid:" "http://www.aiim.org/pdfa/ns/id/" 50 $y]
        set y [info_line $pdf "pdfaid:part:" $part 50 $y]
        set y [info_line $pdf "pdfaid:conformance:" $conf 50 $y]
        set y [info_line $pdf "dc:title:" "pdf4tcl PDF/A-Demo ($variant_label)" 50 $y]
        set y [info_line $pdf "xmp:CreatorTool:" "pdf4tcl $pkgver" 50 $y]
    } else {
        $pdf setFont 10 cidSans
        $pdf text "Kein XMP-Stream -- -pdfa nicht gesetzt." -x 50 -y $y
        incr y -16
    }

    incr y -10
    set y [section_header $pdf "3. OutputIntent + sRGB-ICC (ISO 19005-1 SS6.2.2)" $y]

    if {$pdfa_variant ne ""} {
        set y [info_line $pdf "/S:" "/GTS_PDFA1" 50 $y]
        set y [info_line $pdf "/OutputConditionIdentifier:" "sRGB IEC61966-2.1" 50 $y]
        set y [info_line $pdf "/RegistryName:" "http://www.color.org" 50 $y]
        set y [info_line $pdf "/Info:" "sRGB IEC61966-2.1" 50 $y]
        if {$icc_file ne ""} {
            set y [info_line $pdf "/DestOutputProfile:" $icc_file 50 $y]
        } else {
            set y [info_line $pdf "/DestOutputProfile:" "(kein ICC-Profil gefunden)" 50 $y]
        }
    } else {
        $pdf setFont 10 cidSans
        $pdf text "Kein OutputIntent -- -pdfa nicht gesetzt." -x 50 -y $y
        incr y -16
    }

    incr y -10
    set y [section_header $pdf "4. Farben (DeviceRGB mit OutputIntent)" $y]

    set bx 50
    foreach {r g b label} {
        0.85 0.15 0.15 "Rot"
        0.15 0.65 0.15 "Gruen"
        0.15 0.35 0.85 "Blau"
        0.90 0.75 0.10 "Gelb"
        0.50 0.15 0.70 "Violett"
    } {
        $pdf setFillColor $r $g $b
        $pdf rectangle $bx [expr {$y - 10}] 88 18 -filled 1
        $pdf setFillColor 0 0 0
        $pdf setFont 8 cidSans
        $pdf text "DeviceRGB $label" -x $bx -y [expr {$y - 22}]
        incr bx 95
    }
    $pdf setFillColor 0 0 0

    $pdf endPage

    # -----------------------------------------------------------------------
    # Seite 2: Vergleichstabelle
    # -----------------------------------------------------------------------
    $pdf startPage

    $pdf setFillColor 0.10 0.25 0.50
    $pdf rectangle 0 797 595 45 -filled 1
    $pdf setFillColor 1 1 1
    $pdf setFont 14 cidSans
    $pdf text "PDF/A-Vergleich: 1b vs. 2b vs. Standard" -x 40 -y 816
    $pdf setFillColor 0 0 0

    set y 760

    # Tabellenkopf
    $pdf setFillColor 0.20 0.40 0.70
    $pdf rectangle 40 [expr {$y - 2}] 515 20 -filled 1
    $pdf setFillColor 1 1 1
    $pdf setFont 10 cidSans
    $pdf text "Merkmal"       -x  46 -y $y
    $pdf text "PDF/A-1b"     -x 210 -y $y
    $pdf text "PDF/A-2b"     -x 290 -y $y
    $pdf text "PDF/A-3b"     -x 370 -y $y
    $pdf text "Standard"     -x 455 -y $y
    $pdf setFillColor 0 0 0
    incr y -20

    set rows {
        "ISO-Norm"             "19005-1:2005"  "19005-2:2011" "19005-3:2012" "--"
        "PDF-Basis"            "PDF 1.4"       "PDF 1.7"      "PDF 1.7"      "PDF 1.4"
        "XMP-Stream"           "Pflicht"       "Pflicht"      "Pflicht"      "Optional"
        "pdfaid-Schema"        "Pflicht"       "Pflicht"      "Pflicht"      "Nein"
        "OutputIntent"         "Pflicht"       "Pflicht"      "Pflicht"      "Nein"
        "Font-Einbettung"      "Pflicht"       "Pflicht"      "Pflicht"      "Optional"
        "/Group Transparenz"   "Verboten"      "Erlaubt"      "Erlaubt"      "Erlaubt"
        "Eingebettete Dateien" "Verboten"      "Erlaubt"      "Pflicht*"     "Erlaubt"
        "Verschluesselung"     "Verboten"      "Verboten"     "Verboten"     "Erlaubt"
        "-pdfa Wert"           "1b"            "2b"           "3b"           "(leer)"
    }

    set alt 0
    foreach {merkmal v1b v2b v3b vstd} $rows {
        if {$alt} {
            $pdf setFillColor 0.94 0.94 0.94
            $pdf rectangle 40 [expr {$y - 5}] 515 17 -filled 1
            $pdf setFillColor 0 0 0
        }
        $pdf setFont 8 cidSans
        $pdf text $merkmal -x  46 -y $y
        $pdf text $v1b     -x 210 -y $y
        $pdf text $v2b     -x 290 -y $y
        $pdf text $v3b     -x 370 -y $y
        $pdf text $vstd    -x 455 -y $y
        incr y -16
        set alt [expr {!$alt}]
    }

    # Aktuellen Modus hervorheben
    set y [expr {$y - 20}]
    $pdf setFillColor 0.10 0.55 0.20
    $pdf rectangle 40 [expr {$y - 8}] 515 22 -filled 1
    $pdf setFillColor 1 1 1
    $pdf setFont 11 cidSans
    $pdf text "Dieses Dokument: $variant_label" -x 46 -y $y
    $pdf setFillColor 0 0 0

    # Code-Beispiel
    set y [expr {$y - 40}]
    $pdf setFillColor 0.95 0.95 0.95
    $pdf rectangle 40 [expr {$y - 138}] 515 152 -filled 1
    $pdf setFillColor 0.30 0.30 0.30
    $pdf setFont 10 cidSans
    $pdf text "Code-Beispiel: $variant_label erzeugen" -x 46 -y $y
    incr y -18
    $pdf setFont 9 cidSans
    $pdf text "package require pdf4tcl" -x 50 -y $y
    incr y -14
    $pdf text "pdf4tcl::loadBaseTrueTypeFont DejaVuSans /pfad/DejaVuSans.ttf" -x 50 -y $y
    incr y -14
    $pdf text "pdf4tcl::createFontSpecCID DejaVuSans cidSans" -x 50 -y $y
    incr y -14
    if {$pdfa_variant ne ""} {
        $pdf text "set pdf \[pdf4tcl::new %AUTO% -pdfa $pdfa_variant -file output.pdf\]" -x 50 -y $y
    } else {
        $pdf text "set pdf \[pdf4tcl::new %AUTO% -file output.pdf\]" -x 50 -y $y
    }
    incr y -14
    $pdf text "\$pdf startPage" -x 50 -y $y
    incr y -14
    $pdf text "\$pdf setFont 12 cidSans" -x 50 -y $y
    incr y -14
    $pdf text "\$pdf text \"Inhalt\" -x 50 -y 700" -x 50 -y $y
    incr y -14
    $pdf text "\$pdf endPage" -x 50 -y $y
    incr y -14
    $pdf text "\$pdf finish" -x 50 -y $y
    $pdf setFillColor 0 0 0

    $pdf endPage

    # -----------------------------------------------------------------------
    # Seite 3: Validierung mit veraPDF
    # -----------------------------------------------------------------------
    $pdf startPage

    $pdf setFillColor 0.10 0.25 0.50
    $pdf rectangle 0 797 595 45 -filled 1
    $pdf setFillColor 1 1 1
    $pdf setFont 14 cidSans
    $pdf text "PDF/A Validierung mit veraPDF" -x 40 -y 816
    $pdf setFillColor 0 0 0

    set y 755
    set y [section_header $pdf "veraPDF -- Empfohlenes Validierungswerkzeug" $y]

    $pdf setFont 10 cidSans
    foreach line {
        "veraPDF ist der offizielle PDF/A-Validator von PDF Association."
        "Download: https://verapdf.org"
        ""
        "Aufruf (Kommandozeile):"
    } {
        $pdf text $line -x 50 -y $y
        incr y -15
    }

    $pdf setFillColor 0.95 0.95 0.95
    $pdf rectangle 50 [expr {$y - 30}] 495 40 -filled 1
    $pdf setFont 9 cidSans
    $pdf setFillColor 0.20 0.20 0.20
    $pdf text "verapdf --flavour 1b --format text output.pdf" -x 55 -y $y
    incr y -16
    $pdf text "verapdf --flavour 2b --format xml  output.pdf" -x 55 -y $y
    $pdf setFillColor 0 0 0
    incr y -40

    set y [section_header $pdf "Behoben in pdf4tcl 0.9.4.x" $y]

    foreach {regel beschreibung version} {
        "6.7.11"  "pdfaid-Schema fehlt im XMP"                 "0.9.4.8"
        "6.2.2"   "OutputIntent fehlt oder kein ICC-Profil"     "0.9.4.8"
        "6.3.4"   "Font nicht eingebettet -- CIDFont verwenden" "0.9.4.5"
        "6.3.9"   "ToUnicode CMap fehlt"                        "0.9.4.9"
        "6.1.3"   "/Group /S /Transparency bei PDF/A-1"         "0.9.4.8"
        "6.1.7"   "/Length falsch berechnet"                    "0.9.4.8"
    } {
        $pdf setFont 10 cidSans
        $pdf text "SS$regel" -x 50 -y $y
        $pdf text $beschreibung -x 120 -y $y
        $pdf text "v$version" -x 460 -y $y
        incr y -16
    }

    $pdf endPage

    # -----------------------------------------------------------------------
    # Seite 4: XRef-Stream und PDF/A-2b (0.9.4.22)
    # -----------------------------------------------------------------------
    $pdf startPage

    $pdf setFillColor 0.10 0.25 0.50
    $pdf rectangle 0 797 595 45 -filled 1
    $pdf setFillColor 1 1 1
    $pdf setFont 14 cidSans
    $pdf text "XRef-Streams und PDF/A-2b (0.9.4.22)" -x 40 -y 816
    $pdf setFillColor 0 0 0

    set y 755
    set y [section_header $pdf "XRef-Streams (ISO 32000 SS7.5.8)" $y]

    $pdf setFont 10 cidSans
    foreach line {
        "Klassische PDFs verwenden eine Texttabelle fuer Objekt-Offsets (xref-Tabelle)."
        "Ab PDF 1.5 erlaubt der Standard XRef-Streams -- kompaktere binaere Form."
        ""
        "PDF/A-1b  -->  klassische xref-Tabelle (XRef-Streams verboten)"
        "PDF/A-2b  -->  XRef-Stream (SS6.1.4 der ISO 19005-2)"
    } {
        $pdf text $line -x 50 -y $y
        incr y -15
    }
    incr y -10

    set y [section_header $pdf "Struktur im PDF" $y]

    $pdf setFillColor 0.95 0.95 0.95
    $pdf rectangle 50 [expr {$y - 84}] 495 96 -filled 1
    $pdf setFont 9 cidSans
    $pdf setFillColor 0.20 0.20 0.20
    foreach line {
        "Klassisch:             XRef-Stream:"
        "xref                   10 0 obj"
        "0 6                    << /Type /XRef"
        "0000000000 65535 f         /Size 11"
        "0000000017 00000 n         /Root 1 0 R"
        "...                        /W \[1 4 2\]"
        "trailer                    /Length ..."
        "<< /Size 6  /Root 1 0 R >> >>"
    } {
        $pdf text $line -x 55 -y $y
        incr y -12
    }
    $pdf setFillColor 0 0 0
    incr y -16

    set y [section_header $pdf "Implementierung in pdf4tcl" $y]

    $pdf setFont 10 cidSans
    foreach line {
        "pdf4tcl waehlt automatisch den richtigen Modus:"
        "  -pdfa 1b  -->  _WriteXrefTable  (xref + trailer)"
        "  -pdfa 2b  -->  _WriteXrefStream (/Type /XRef Objekt)"
        "  Standard  -->  _WriteXrefTable  (maximale Kompatibilitaet)"
        ""
        "Das XRef-Stream-Objekt enthaelt Catalog-Eintraege (/Root, /Info, /ID)."
        "Ein separates trailer-Dict entfaellt vollstaendig."
    } {
        $pdf text $line -x 50 -y $y
        incr y -15
    }
    incr y -10

    set y [section_header $pdf "Behoben in pdf4tcl 0.9.4.22" $y]

    foreach {regel beschreibung version} {
        "6.1.4"    "XRef-Streams fuer PDF/A-2b"                    "0.9.4.22"
        "6.1.6"    "setAlpha < 1.0 bei PDF/A-1b: Warning"           "0.9.4.22"
        "--"       "MD5 pure-Tcl Fallback (FIPS-Systeme)"            "0.9.4.22"
        "6.2.10"   "OCG /AS-Array fuer PDF/A-2b/3b + Layer"         "0.9.4.23"
        "6.2.11.4" "/AF-Array fuer PDF/A-3b + addEmbeddedFile"      "0.9.4.23"
        "--"       "-pdfa 3b als gueltiger Wert"                     "0.9.4.23"
    } {
        $pdf setFont 10 cidSans
        $pdf text "SS$regel" -x 50 -y $y
        $pdf text $beschreibung -x 120 -y $y
        $pdf text "v$version" -x 460 -y $y
        incr y -16
    }

    $pdf endPage

    $pdf write -file $outfile
    $pdf destroy
    return $outfile
}

# -----------------------------------------------------------------------------
# Hauptprogramm
# -----------------------------------------------------------------------------

puts "pdf4tcl $pkgver -- PDF/A Demo"
puts [string repeat = 50]
if {$icc_file ne ""} {
    puts "ICC-Profil:  $icc_file"
} else {
    puts "ICC-Profil:  (keines gefunden -- OutputIntent ohne /DestOutputProfile)"
}
puts ""

set results {}

foreach {variant label} {
    1b  "PDF/A-1b"
    2b  "PDF/A-2b"
    3b  "PDF/A-3b"
    ""  "Standard PDF"
} {
    set fname "demo-pdfa-[expr {$variant eq {} ? {none} : $variant}].pdf"
    set outfile [file join $out_dir $fname]
    set out [make_demo_pdf $outfile $variant $icc_file $pkgver]
    set kb [expr {[file size $outfile] / 1024}]
    puts "Erzeugt: $out ($kb KB)"
    if {$variant ne ""} {
        lappend results $variant $outfile
    }
}

puts ""
puts "veraPDF-Validierung:"
puts [string repeat - 50]

if {[auto_execok verapdf] eq ""} {
    puts "  veraPDF nicht gefunden."
    puts "  Download: https://verapdf.org/software/"
} else {
    foreach {variant outfile} $results {
        set r [check_verapdf $outfile $variant]
        set st [dict get $r status]
        if {$st eq "pass"} {
            puts "  PASS  PDF/A-$variant: [file tail $outfile]"
        } elseif {$st eq "fail"} {
            set n [dict get $r failedChecks]
            puts "  FAIL  PDF/A-$variant: [file tail $outfile] ($n Fehler)"
        } else {
            puts "  ???   PDF/A-$variant: [file tail $outfile]"
        }
    }
}

puts ""
puts "Fertig. Dateien in: $out_dir"
