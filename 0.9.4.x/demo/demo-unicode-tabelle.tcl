#!/usr/bin/env tclsh
# demo-unicode-tabelle.tcl -- Unicode-Nachschlagetabelle als PDF
#
# Pro Font wird eine eigene PDF erzeugt.
#
# Aufruf:
#   tclsh demo-unicode-tabelle.tcl font1.ttf font2.ttf ...
#   tclsh demo-unicode-tabelle.tcl /pfad/zu/fontverzeichnis/
#   tclsh demo-unicode-tabelle.tcl          (sucht automatisch)
#
# Ausgabe: unicode-tabelle-<FontName>.pdf  im Skript-Verzeichnis
#
# Benoetigt: pdf4tcl mit glyph2unicode (im pdf4tcl-Repo enthalten)
#
# Empfohlene Fonts fuer beste Unicode-Abdeckung (Debian/Ubuntu):
#
#   Symbola        beste Abdeckung: Symbole, Pfeile, Mathematik, Dingbats
#                  apt install fonts-symbola
#
#   GNU Unifont    nahezu vollstaendige BMP-Abdeckung (65000+ Glyphen)
#                  apt install fonts-unifont
#
#   FreeSerif      breit: latein, griechisch, kyrillisch, arabisch, hebraeisch
#                  apt install fonts-freefont-ttf
#
#   STIX Two Math  beste Abdeckung fuer Mathematik-Bloecke (U+2200..U+2AFF)
#                  apt install fonts-stix
#
#   Noto Sans/Serif  latein, kyrillisch, griechisch
#                  apt install fonts-noto-core
#
# Empfohlene Fonts fuer beste Unicode-Abdeckung (Windows):
#
#   Arial Unicode MS  breite Abdeckung (nur mit Office installiert)
#                  C:/Windows/Fonts/arialuni.ttf
#
#   Microsoft YaHei   CJK (Chinesisch vereinfacht)
#                  C:/Windows/Fonts/msyh.ttc   (Sub-Font 0)
#
#   Meiryo            Japanisch
#                  C:/Windows/Fonts/meiryo.ttc  (Sub-Font 0)
#
#   Malgun Gothic     Koreanisch
#                  C:/Windows/Fonts/malgun.ttf
#
#   Arial             Latein, Griechisch, Kyrillisch
#                  C:/Windows/Fonts/arial.ttf
#
# Hinweis: .TTC-Dateien (TrueType Collections) werden automatisch
# unterstuetzt -- es wird immer Sub-Font 0 geladen.
#
# Diese Fonts werden automatisch gesucht und benoetigen keinen expliziten
# Aufrufparameter. Als Fallback dient DejaVuSans bzw. FreeSans aus examples/.
#
# Automatisch durchsuchtes lokales Verzeichnis (relativ zum Skript):
#   ../fonts/   (Struktur: demo/demo-unicode-tabelle.tcl + fonts/*.ttf)

set auto_path [linsert $auto_path 0 \
    [file normalize [file join [file dirname [info script]] ../..]] \
    [file normalize [file join [file dirname [info script]] ../../..]]]
package require pdf4tcl
package require pdf4tcl::glyph2unicode

# ---------------------------------------------------------------------------
# GlyphName-Lookup einmalig aufbauen: Codepoint -> GlyphName
# ---------------------------------------------------------------------------
array set cpToGlyph {}
foreach {gname cp} [array get pdf4tcl::GlName2Uni] {
    if {![info exists cpToGlyph($cp)] ||
        [string length $gname] < [string length $cpToGlyph($cp)]} {
        set cpToGlyph($cp) $gname
    }
}
puts "GlyphName-Eintraege: [array size cpToGlyph]"

# ---------------------------------------------------------------------------
# Font-Liste aufbauen
# ---------------------------------------------------------------------------
set fontList {}

# Hilfsproc: Font nur einmal hinzufuegen (kein Duplikat)
proc addFont {path} {
    global fontList
    set path [file normalize $path]
    if {[file exists $path] && $path ni $fontList} {
        lappend fontList $path
    }
}

# 1) Bevorzugte Fonts fuer Unicode-Abdeckung -- immer automatisch suchen
#    Symbola:   beste Abdeckung Symbole/Pfeile/Math/Dingbats
#    Unifont:   nahezu vollstaendige BMP-Abdeckung
#    FreeSerif: breite Abdeckung latein/griechisch/kyrillisch/arabisch
#    STIXTwo:   beste Abdeckung Mathematik-Bloecke
#    NotoSans:  gute latein/kyrillisch/griechisch-Abdeckung
set ::autoFonts {
    /usr/share/fonts/truetype/ancient-scripts/Symbola_hint.ttf
    /usr/share/fonts/truetype/ancient-scripts/Symbola.ttf
    /usr/share/fonts/truetype/unifont/unifont.ttf
    /usr/share/fonts/unifont/unifont.ttf
    /usr/share/fonts/truetype/freefont/FreeSerif.ttf
    /usr/share/fonts/TTF/FreeSerif.ttf
    /usr/share/fonts/stix-fonts/STIXTwoMath-Regular.ttf
    /usr/share/fonts/truetype/stix/STIXTwoMath-Regular.ttf
    /usr/share/fonts/opentype/stix-word/STIXTwoMath-Regular.ttf
    /usr/share/fonts/truetype/noto/NotoSans-Regular.ttf
    /usr/share/fonts/TTF/NotoSans-Regular.ttf
    /usr/share/fonts/truetype/noto/NotoSerif-Regular.ttf
    /usr/share/fonts/TTF/NotoSerif-Regular.ttf
    C:/Windows/Fonts/arialuni.ttf
    C:/Windows/Fonts/arial.ttf
    C:/Windows/Fonts/msyh.ttc
    C:/Windows/Fonts/meiryo.ttc
    C:/Windows/Fonts/malgun.ttf
    C:/Windows/Fonts/Calibri.ttf
}
foreach _f $::autoFonts { addFont $_f }

# 1b) Lokales Font-Verzeichnis relativ zum Skript: ../fonts/
#     Struktur: demo/demo-unicode-tabelle.tcl  +  fonts/*.ttf
set _scriptDir [file dirname [file normalize [info script]]]
set _localFonts [file normalize [file join $_scriptDir ../fonts]]
if {[file isdirectory $_localFonts]} {
    foreach _f [lsort [glob -nocomplain \
            -directory $_localFonts *.ttf *.TTF *.ttc *.TTC]] {
        addFont $_f
    }
}
unset -nocomplain _scriptDir _localFonts _f

# 2) Explizite Argumente oder Fallback
if {[llength $argv] == 0} {
    # Kein Argument: DejaVuSans oder FreeSans als Basisbeispiel
    foreach c {
        /usr/share/fonts/truetype/dejavu/DejaVuSans.ttf
        /usr/share/fonts/TTF/DejaVuSans.ttf
        /Library/Fonts/DejaVuSans.ttf
        C:/Windows/Fonts/DejaVuSans.ttf
        C:/Windows/Fonts/arial.ttf
    } {
        if {[file exists $c]} { addFont $c; break }
    }
    set _fb [file normalize \
        [file join [file dirname [info script]] ../../examples/FreeSans.ttf]]
    addFont $_fb
} else {
    foreach arg $argv {
        if {[file isdirectory $arg]} {
            foreach f [lsort [glob -nocomplain \
                    -directory $arg *.ttf *.TTF *.ttc *.TTC]] {
                addFont $f
            }
        } else {
            addFont $arg
            if {![file exists $arg]} {
                puts stderr "Warnung: nicht gefunden: $arg"
            }
        }
    }
}

if {[llength $fontList] == 0} {
    puts stderr "Fehler: keine TTF-Fonts gefunden."
    puts stderr "Aufruf: tclsh demo-unicode-tabelle.tcl font.ttf ..."
    exit 1
}

# ---------------------------------------------------------------------------
# Layout-Konstanten (global)
# ---------------------------------------------------------------------------
set mL   15.0 ;# Rand links mm
set mT   20.0 ;# Rand oben mm
set mB   15.0 ;# Rand unten mm
set pH  297.0 ;# A4-Hoehe mm
set pW  210.0 ;# A4-Breite mm
set rowH  5.0 ;# Zeilenhoehe mm
set fSym  3.5 ;# Schriftgroesse Glyph pt
set fTxt  4.0 ;# Schriftgroesse Text pt
set fHead 5.0 ;# Schriftgroesse Kopfzeile pt
set cCode  10.0
set cGlyph 10.0
set cName  60.0
set blockW [expr {$cCode + $cGlyph + $cName}]
set gap    10.0
set x0L    $mL
set x0R    [expr {$mL + $blockW + $gap}]

# ---------------------------------------------------------------------------
# Hilfsprozeduren
# ---------------------------------------------------------------------------
proc newPage {pdf title fontName} {
    global mL mT pW fHead
    $pdf startPage
    $pdf setFont $fHead Helvetica-Bold
    $pdf text "$title  \[$fontName\]" -x $mL -y $mT
    $pdf line $mL [expr {$mT + 2.5}] [expr {$pW - $mL}] [expr {$mT + 2.5}]
}

proc tableHeader {pdf y} {
    global x0L x0R cCode cGlyph fTxt
    $pdf setFont $fTxt Helvetica-Bold
    foreach x [list $x0L $x0R] {
        $pdf text "U+"   -x $x -y $y
        $pdf text "Gl."  -x [expr {$x + $cCode}] -y $y
        $pdf text "Name" -x [expr {$x + $cCode + $cGlyph}] -y $y
    }
}

proc drawRow {pdf x y cp symFont} {
    global cCode cGlyph fTxt fSym cpToGlyph
    $pdf setFont $fTxt Helvetica
    $pdf text [format "%04X" $cp] -x $x -y $y
    $pdf setFont $fSym $symFont
    $pdf text [format "%c" $cp] -x [expr {$x + $cCode + 1.5}] -y $y
    set name [expr {[info exists cpToGlyph($cp)] ? $cpToGlyph($cp) : ""}]
    if {$name ne ""} {
        $pdf setFont $fTxt Helvetica
        $pdf text $name -x [expr {$x + $cCode + $cGlyph}] -y $y
    }
}

proc groupBookmark {label} {
    global nextGroupLabel
    set nextGroupLabel $label
}

# Prueft ob der Font mindestens einen Glyph im Bereich from..to hat.
proc fontHasGlyphs {baseName from to} {
    set d $pdf4tcl::BFA($baseName,charToGlyph)
    for {set cp $from} {$cp <= $to} {incr cp} {
        if {[dict exists $d $cp] && [dict get $d $cp] != 0} {
            return 1
        }
    }
    return 0
}

proc rangePage {pdf title from to symFont fontName} {
    global mT mB pH rowH x0L x0R nextGroupLabel
    set yStart [expr {$mT + 9.0}]
    set yMax   [expr {$pH - $mB}]
    set perPage [expr {int(($yMax - $yStart) / $rowH) * 2}]
    set chars {}
    for {set cp $from} {$cp <= $to} {incr cp} { lappend chars $cp }
    set i 0; set total [llength $chars]; set firstPage 1
    while {$i < $total} {
        newPage $pdf $title $fontName
        if {$firstPage} {
            if {[info exists nextGroupLabel] && $nextGroupLabel ne ""} {
                $pdf bookmarkAdd -title $nextGroupLabel -level 0
                set nextGroupLabel ""
            }
            $pdf bookmarkAdd -title $title -level 1
            set firstPage 0
        }
        tableHeader $pdf [expr {$mT + 5.5}]
        set y $yStart; set col 0; set n 0
        while {$i < $total && $n < $perPage} {
            set x [expr {$col == 0 ? $x0L : $x0R}]
            drawRow $pdf $x $y [lindex $chars $i] $symFont
            incr col
            if {$col == 2} { set col 0; set y [expr {$y + $rowH}] }
            incr i; incr n
        }
        $pdf endPage
    }
}

# SMP-Variante: ueberspringt den Block wenn der Font keine Glyphen hat.
# Gibt stattdessen eine einzelne Hinweisseite aus.
proc smpRangePage {pdf title from to symFont fontName baseName} {
    global mT mB pW fTxt nextGroupLabel
    if {![fontHasGlyphs $baseName $from $to]} {
        # Hinweisseite
        newPage $pdf $title $fontName
        if {[info exists nextGroupLabel] && $nextGroupLabel ne ""} {
            $pdf bookmarkAdd -title $nextGroupLabel -level 0
            set nextGroupLabel ""
        }
        $pdf bookmarkAdd -title "$title (kein Font)" -level 1
        set yMsg [expr {$mT + 30.0}]
        set xMsg [expr {$pW / 2.0 - 65.0}]
        $pdf setFont $fTxt Helvetica
        $pdf text "Kein Glyph fuer diesen Block -- Font unterstuetzt diesen Bereich nicht." \
            -x $xMsg -y $yMsg
        $pdf text "Tipp: apt install fonts-noto-extra  (NotoEmoji-Regular.ttf)" \
            -x $xMsg -y [expr {$yMsg + 7.0}]
        $pdf endPage
        return
    }
    rangePage $pdf $title $from $to $symFont $fontName
}

# ---------------------------------------------------------------------------
# PDF erzeugen fuer einen Font
# ---------------------------------------------------------------------------
proc generatePdf {fontPath outfile} {
    global nextGroupLabel
    # Eindeutiger interner Name pro Font
    set baseName "F[incr ::fontCounter]"
    set symFont  "sym${baseName}"
    pdf4tcl::loadBaseTrueTypeFont $baseName $fontPath
    pdf4tcl::createFontSpecCID    $baseName $symFont

    set fontName [file rootname [file tail $fontPath]]
    set pdf [pdf4tcl::new %AUTO% -paper a4 -orient 1 -compress 1 -unit mm]
    set nextGroupLabel ""

    # --- Lateinisch ---
    groupBookmark "Lateinisch"
    rangePage $pdf "Basis-Latein (U+0020..U+007F)"                      0x0020 0x007F $symFont $fontName
    rangePage $pdf "Latein-Ergaenzung (U+00A0..U+00FF)"                 0x00A0 0x00FF $symFont $fontName
    rangePage $pdf "Latein Erweitert A (U+0100..U+017F)"                0x0100 0x017F $symFont $fontName
    rangePage $pdf "Latein Erweitert B (U+0180..U+024F)"                0x0180 0x024F $symFont $fontName
    rangePage $pdf "IPA-Erweiterungen (U+0250..U+02AF)"                 0x0250 0x02AF $symFont $fontName
    rangePage $pdf "Modifikatorbuchstaben (U+02B0..U+02FF)"             0x02B0 0x02FF $symFont $fontName
    rangePage $pdf "Diakritische Zeichen (U+0300..U+036F)"              0x0300 0x036F $symFont $fontName
    rangePage $pdf "Phonetische Erw. (U+1D00..U+1DBF)"                  0x1D00 0x1DBF $symFont $fontName
    rangePage $pdf "Diakritika Ergaenzung (U+1DC0..U+1DFF)"             0x1DC0 0x1DFF $symFont $fontName
    rangePage $pdf "Latein Erw. Zusatz (U+1E00..U+1EFF)"                0x1E00 0x1EFF $symFont $fontName
    rangePage $pdf "Latein Erweitert C (U+2C60..U+2C7F)"                0x2C60 0x2C7F $symFont $fontName
    rangePage $pdf "Latein Erweitert D (U+A720..U+A7FF)"                0xA720 0xA7FF $symFont $fontName
    rangePage $pdf "Latein Erweitert E (U+AB30..U+AB6F)"                0xAB30 0xAB6F $symFont $fontName

    # --- Griechisch / Kyrillisch ---
    groupBookmark "Griechisch / Kyrillisch"
    rangePage $pdf "Griechisch und Koptisch (U+0370..U+03FF)"           0x0370 0x03FF $symFont $fontName
    rangePage $pdf "Griechisch Erweitert (U+1F00..U+1FFF)"              0x1F00 0x1FFF $symFont $fontName
    rangePage $pdf "Kyrillisch (U+0400..U+04FF)"                        0x0400 0x04FF $symFont $fontName
    rangePage $pdf "Kyrillisch Ergaenzung (U+0500..U+052F)"             0x0500 0x052F $symFont $fontName
    rangePage $pdf "Kyrillisch Erweitert A (U+2DE0..U+2DFF)"            0x2DE0 0x2DFF $symFont $fontName
    rangePage $pdf "Kyrillisch Erweitert B (U+A640..U+A69F)"            0xA640 0xA69F $symFont $fontName

    # --- Weitere europaeische Schriften ---
    groupBookmark "Europaeische Schriften"
    rangePage $pdf "Armenisch (U+0530..U+058F)"                         0x0530 0x058F $symFont $fontName
    rangePage $pdf "Georgisch (U+10A0..U+10FF)"                         0x10A0 0x10FF $symFont $fontName
    rangePage $pdf "Georgisch Ergaenzung (U+2D00..U+2D2F)"              0x2D00 0x2D2F $symFont $fontName
    rangePage $pdf "Cherokee (U+13A0..U+13FF)"                          0x13A0 0x13FF $symFont $fontName
    rangePage $pdf "Runen (U+16A0..U+16FF)"                             0x16A0 0x16FF $symFont $fontName
    rangePage $pdf "Ogham (U+1680..U+169F)"                             0x1680 0x169F $symFont $fontName

    # --- Semitische Schriften ---
    groupBookmark "Semitische Schriften"
    rangePage $pdf "Hebraeisch (U+0590..U+05FF)"                        0x0590 0x05FF $symFont $fontName
    rangePage $pdf "Arabisch (U+0600..U+06FF)"                          0x0600 0x06FF $symFont $fontName
    rangePage $pdf "Arabisch Ergaenzung (U+0750..U+077F)"               0x0750 0x077F $symFont $fontName
    rangePage $pdf "Arabisch Erweitert A (U+08A0..U+08FF)"              0x08A0 0x08FF $symFont $fontName
    rangePage $pdf "Syrisch (U+0700..U+074F)"                           0x0700 0x074F $symFont $fontName
    rangePage $pdf "Thaana (U+0780..U+07BF)"                            0x0780 0x07BF $symFont $fontName

    # --- Suedostasiatische Schriften ---
    groupBookmark "Suedostasiatische Schriften"
    rangePage $pdf "Devanagari (U+0900..U+097F)"                        0x0900 0x097F $symFont $fontName
    rangePage $pdf "Devanagari Erweitert (U+A8E0..U+A8FF)"              0xA8E0 0xA8FF $symFont $fontName
    rangePage $pdf "Bengalisch (U+0980..U+09FF)"                        0x0980 0x09FF $symFont $fontName
    rangePage $pdf "Gurmukhi (U+0A00..U+0A7F)"                          0x0A00 0x0A7F $symFont $fontName
    rangePage $pdf "Gujarati (U+0A80..U+0AFF)"                          0x0A80 0x0AFF $symFont $fontName
    rangePage $pdf "Oriya (U+0B00..U+0B7F)"                             0x0B00 0x0B7F $symFont $fontName
    rangePage $pdf "Tamil (U+0B80..U+0BFF)"                             0x0B80 0x0BFF $symFont $fontName
    rangePage $pdf "Telugu (U+0C00..U+0C7F)"                            0x0C00 0x0C7F $symFont $fontName
    rangePage $pdf "Kannada (U+0C80..U+0CFF)"                           0x0C80 0x0CFF $symFont $fontName
    rangePage $pdf "Malayalam (U+0D00..U+0D7F)"                         0x0D00 0x0D7F $symFont $fontName
    rangePage $pdf "Singhalesisch (U+0D80..U+0DFF)"                     0x0D80 0x0DFF $symFont $fontName
    rangePage $pdf "Thailaendisch (U+0E00..U+0E7F)"                     0x0E00 0x0E7F $symFont $fontName
    rangePage $pdf "Lao (U+0E80..U+0EFF)"                               0x0E80 0x0EFF $symFont $fontName
    rangePage $pdf "Tibetisch (U+0F00..U+0FFF)"                         0x0F00 0x0FFF $symFont $fontName
    rangePage $pdf "Myanmarisch (U+1000..U+109F)"                       0x1000 0x109F $symFont $fontName
    rangePage $pdf "Khmer (U+1780..U+17FF)"                             0x1780 0x17FF $symFont $fontName
    rangePage $pdf "Mongolisch (U+1800..U+18AF)"                        0x1800 0x18AF $symFont $fontName

    # --- Ostasiatisch / Japanisch / Koreanisch ---
    groupBookmark "Ostasiatisch / CJK"
    rangePage $pdf "Bopomofo (U+02EA..U+02EB + U+3100..U+312F)"         0x3100 0x312F $symFont $fontName
    rangePage $pdf "Hangul-Kompatibilitaet Jamo (U+3130..U+318F)"       0x3130 0x318F $symFont $fontName
    rangePage $pdf "Hiragana (U+3040..U+309F)"                          0x3040 0x309F $symFont $fontName
    rangePage $pdf "Katakana (U+30A0..U+30FF)"                          0x30A0 0x30FF $symFont $fontName
    rangePage $pdf "Katakana Phonetische Erw. (U+31F0..U+31FF)"         0x31F0 0x31FF $symFont $fontName
    rangePage $pdf "CJK-Radikale Ergaenzung (U+2E80..U+2EFF)"           0x2E80 0x2EFF $symFont $fontName
    rangePage $pdf "Kangxi-Radikale (U+2F00..U+2FDF)"                   0x2F00 0x2FDF $symFont $fontName
    rangePage $pdf "CJK-Symbole und Interpunktion (U+3000..U+303F)"     0x3000 0x303F $symFont $fontName
    rangePage $pdf "Eingeschlossenes CJK (U+3200..U+32FF)"              0x3200 0x32FF $symFont $fontName
    rangePage $pdf "CJK-Kompatibilitaet (U+3300..U+33FF)"               0x3300 0x33FF $symFont $fontName

    # --- Kanada / Afrika / Sonstige ---
    groupBookmark "Kanada / Afrika / Sonstige Schriften"
    rangePage $pdf "Unified Canadian Aboriginal (U+1400..U+167F)"       0x1400 0x167F $symFont $fontName
    rangePage $pdf "Hangul-Jamo (U+1100..U+11FF)"                       0x1100 0x11FF $symFont $fontName
    rangePage $pdf "Ethiopisch (U+1200..U+137F)"                        0x1200 0x137F $symFont $fontName
    rangePage $pdf "Ethiopisch Ergaenzung (U+1380..U+139F)"             0x1380 0x139F $symFont $fontName
    rangePage $pdf "Ethiopisch Erweitert (U+2D80..U+2DDF)"              0x2D80 0x2DDF $symFont $fontName
    rangePage $pdf "Tifinagh / Berber (U+2D30..U+2D7F)"                 0x2D30 0x2D7F $symFont $fontName
    rangePage $pdf "Koptisch (U+2C80..U+2CFF)"                          0x2C80 0x2CFF $symFont $fontName
    rangePage $pdf "N'Ko (U+07C0..U+07FF)"                              0x07C0 0x07FF $symFont $fontName
    rangePage $pdf "Mandaeisch (U+0840..U+085F)"                        0x0840 0x085F $symFont $fontName
    rangePage $pdf "Vai (U+A500..U+A63F)"                               0xA500 0xA63F $symFont $fontName
    rangePage $pdf "Bamum (U+A6A0..U+A6FF)"                             0xA6A0 0xA6FF $symFont $fontName
    smpRangePage $pdf "Adlam (U+1E900..U+1E95F)"                           0x1E900 0x1E95F $symFont $fontName $baseName

    # --- Interpunktion / Symbole / Zahlen ---
    groupBookmark "Interpunktion / Symbole / Zahlen"
    rangePage $pdf "Allg. Interpunktion (U+2000..U+206F)"               0x2000 0x206F $symFont $fontName
    rangePage $pdf "Ergaenzende Interpunktion (U+2E00..U+2E7F)"         0x2E00 0x2E7F $symFont $fontName
    rangePage $pdf "Hochgestellt/Tiefgestellt (U+2070..U+209F)"         0x2070 0x209F $symFont $fontName
    rangePage $pdf "Waehrungszeichen (U+20A0..U+20CF)"                  0x20A0 0x20CF $symFont $fontName
    rangePage $pdf "Buchstabenaehnliche Symbole (U+2100..U+214F)"       0x2100 0x214F $symFont $fontName
    rangePage $pdf "Zahlenformen (U+2150..U+218F)"                      0x2150 0x218F $symFont $fontName
    rangePage $pdf "Eingekreiste Zeichen (U+2460..U+24FF)"              0x2460 0x24FF $symFont $fontName
    rangePage $pdf "Verschiedene Symbole und Pfeile (U+2B00..U+2BFF)"   0x2B00 0x2BFF $symFont $fontName

    # --- Pfeile / Mathematik / Technik ---
    groupBookmark "Pfeile / Mathematik / Technik"
    rangePage $pdf "Pfeile (U+2190..U+21FF)"                            0x2190 0x21FF $symFont $fontName
    rangePage $pdf "Zusaetzliche Pfeile A (U+27F0..U+27FF)"             0x27F0 0x27FF $symFont $fontName
    rangePage $pdf "Zusaetzliche Pfeile B (U+2900..U+297F)"             0x2900 0x297F $symFont $fontName
    rangePage $pdf "Mathematische Operatoren (U+2200..U+22FF)"          0x2200 0x22FF $symFont $fontName
    rangePage $pdf "Verschiedene Mathematik A (U+27C0..U+27EF)"         0x27C0 0x27EF $symFont $fontName
    rangePage $pdf "Verschiedene Mathematik B (U+2980..U+29FF)"         0x2980 0x29FF $symFont $fontName
    rangePage $pdf "Ergaenzende Mathematik (U+2A00..U+2AFF)"            0x2A00 0x2AFF $symFont $fontName
    rangePage $pdf "Technische Zeichen (U+2300..U+23FF)"                0x2300 0x23FF $symFont $fontName
    rangePage $pdf "Steuerbilder (U+2400..U+243F)"                      0x2400 0x243F $symFont $fontName
    rangePage $pdf "Optische Zeichen (U+2440..U+245F)"                  0x2440 0x245F $symFont $fontName

    # --- Box / Geometrie / Symbole ---
    groupBookmark "Box / Geometrie / Symbole"
    rangePage $pdf "Box-Drawing (U+2500..U+257F)"                       0x2500 0x257F $symFont $fontName
    rangePage $pdf "Blockzeichen (U+2580..U+259F)"                      0x2580 0x259F $symFont $fontName
    rangePage $pdf "Geometrische Formen (U+25A0..U+25FF)"               0x25A0 0x25FF $symFont $fontName
    rangePage $pdf "Verschiedene Symbole (U+2600..U+26FF)"              0x2600 0x26FF $symFont $fontName
    rangePage $pdf "Dingbats (U+2700..U+27BF)"                          0x2700 0x27BF $symFont $fontName
    rangePage $pdf "Braille-Muster (U+2800..U+28FF)"                    0x2800 0x28FF $symFont $fontName

    # --- Symbole und Emoji (Supplementary Plane) ---
    groupBookmark "Symbole und Emoji (SMP)"
    smpRangePage $pdf "Verschiedene Symbole und Pfeile (U+2B00..U+2BFF)"   0x2B00 0x2BFF $symFont $fontName $baseName
    smpRangePage $pdf "Geometrische Formen Erweitert (U+1F780..U+1F7FF)"   0x1F780 0x1F7FF $symFont $fontName $baseName
    smpRangePage $pdf "Zusaetzliche Pfeile C (U+1F800..U+1F8FF)"           0x1F800 0x1F8FF $symFont $fontName $baseName
    smpRangePage $pdf "Verschiedene Symbole + Piktogramme (U+1F300..U+1F5FF)" 0x1F300 0x1F5FF $symFont $fontName $baseName
    smpRangePage $pdf "Emoticons (U+1F600..U+1F64F)"                       0x1F600 0x1F64F $symFont $fontName $baseName
    smpRangePage $pdf "Transport und Karte (U+1F680..U+1F6FF)"             0x1F680 0x1F6FF $symFont $fontName $baseName
    smpRangePage $pdf "Alchimie + Erweiterte Symbole (U+1F700..U+1F77F)"   0x1F700 0x1F77F $symFont $fontName $baseName
    smpRangePage $pdf "Mahjong + Spielkarten (U+1F000..U+1F0FF)"           0x1F000 0x1F0FF $symFont $fontName $baseName
    smpRangePage $pdf "Eingekreiste Zeichen Ergaenzung (U+1F100..U+1F1FF)" 0x1F100 0x1F1FF $symFont $fontName $baseName
    smpRangePage $pdf "Eingeschlossenes CJK Ergaenzung (U+1F200..U+1F2FF)" 0x1F200 0x1F2FF $symFont $fontName $baseName
    smpRangePage $pdf "Ergaenz. Symbole + Piktogramme (U+1F900..U+1F9FF)"  0x1F900 0x1F9FF $symFont $fontName $baseName
    smpRangePage $pdf "Symbole + Piktogramme Erweitert (U+1FA00..U+1FA6F)" 0x1FA00 0x1FA6F $symFont $fontName $baseName
    smpRangePage $pdf "Symbole fuer Legacy (U+1FB00..U+1FBFF)"             0x1FB00 0x1FBFF $symFont $fontName $baseName

    # --- Alphabetische Darstellungen ---
    groupBookmark "Alphabetische Darstellungen"
    rangePage $pdf "Alphabetische Praesentation (U+FB00..U+FB4F)"       0xFB00 0xFB4F $symFont $fontName
    rangePage $pdf "Arabisch Praesentation A (U+FB50..U+FDFF)"          0xFB50 0xFDFF $symFont $fontName
    rangePage $pdf "Arabisch Praesentation B (U+FE70..U+FEFF)"          0xFE70 0xFEFF $symFont $fontName
    rangePage $pdf "Kleine Formen (U+FE50..U+FE6F)"                     0xFE50 0xFE6F $symFont $fontName
    rangePage $pdf "Halbbreite/Vollbreite (U+FF00..U+FFEF)"             0xFF00 0xFFEF $symFont $fontName
    rangePage $pdf "Sonderzeichen (U+FFF0..U+FFFF)"                     0xFFF0 0xFFFF $symFont $fontName

    $pdf write -file $outfile
    $pdf destroy
}

# ---------------------------------------------------------------------------
# Hauptschleife: pro Font eine PDF
# ---------------------------------------------------------------------------
set fontCounter 0
set outDir [file dirname [file normalize [info script]]]

puts "\n[llength $fontList] Font(s) gefunden:"
foreach f $fontList { puts "  $f" }
puts ""

foreach fontPath $fontList {
    set fontName [file rootname [file tail $fontPath]]
    set outfile  [file join $outDir "unicode-tabelle-${fontName}.pdf"]
    puts "Erzeuge: [file tail $outfile]"
    if {[catch { generatePdf $fontPath $outfile } err]} {
        puts stderr "  FEHLER: $err"
        continue
    }
    puts "  OK -> $outfile"
}

puts "\nFertig. [llength $fontList] PDF(s) erzeugt."
