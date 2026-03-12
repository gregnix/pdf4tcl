#!/usr/bin/env tclsh
# demo-pdfa-gs.tcl -- PDF/A-Konvertierung via Ghostscript (pdf4tcl 0.9.4.9)
#
# Erzeugt zuerst ein regulaeres PDF mit pdf4tcl, konvertiert es dann mit
# Ghostscript in PDF/A-1b bzw. PDF/A-2b.
#
# Benoetigt:
#   pdf4tcl 0.9.4.9  (im uebergeordneten Verzeichnis)
#   DejaVuSans.ttf   (Debian/Ubuntu: apt install fonts-dejavu-core)
#   Ghostscript      (Debian/Ubuntu: apt install ghostscript)
#                    Lizenz: AGPL-3 -- separat zu installieren
#                    https://ghostscript.com
#
# Aufruf:
#   tclsh demo-pdfa-gs.tcl
#   tclsh demo-pdfa-gs.tcl --out /tmp
#   tclsh demo-pdfa-gs.tcl --font /pfad/DejaVuSans.ttf
#   tclsh demo-pdfa-gs.tcl --flavour 2b
#
# Ausgabe:
#   demo-pdfa-gs-src.pdf  -- Eingabe fuer Ghostscript
#   demo-pdfa-gs-1b.pdf   -- PDF/A-1b via Ghostscript
#   demo-pdfa-gs-2b.pdf   -- PDF/A-2b via Ghostscript

set demodir  [file dirname [file normalize [info script]]]
set reporoot [file normalize [file join $demodir ../..]]
set auto_path [linsert $auto_path 0 $reporoot]

package require pdf4tcl
set pkgver [package require pdf4tcl]

# -----------------------------------------------------------------------------
# Argumente verarbeiten
# -----------------------------------------------------------------------------

set out_dir      $demodir
set font_override ""
set flavours     {1b 2b}

for {set i 0} {$i < [llength $argv]} {incr i} {
    set arg [lindex $argv $i]
    switch -- $arg {
        --out     { set out_dir      [lindex $argv [incr i]] }
        --font    { set font_override [lindex $argv [incr i]] }
        --flavour { set flavours [list [lindex $argv [incr i]]] }
        default {
            puts stderr "Unbekanntes Argument: $arg"
            puts stderr "Aufruf: tclsh demo-pdfa-gs.tcl \[--out dir\] \[--font pfad\] \[--flavour 1b|2b\]"
            exit 1
        }
    }
}

file mkdir $out_dir

# -----------------------------------------------------------------------------
# Ghostscript pruefen
# -----------------------------------------------------------------------------

set gs_bin ""
foreach candidate {gs gswin64c gswin32c} {
    if {[auto_execok $candidate] ne ""} {
        set gs_bin $candidate
        break
    }
}
if {$gs_bin eq ""} {
    puts stderr "Fehler: Ghostscript nicht gefunden."
    puts stderr "  Debian/Ubuntu: apt install ghostscript"
    puts stderr "  Download:      https://ghostscript.com"
    exit 1
}
puts "Ghostscript: [auto_execok $gs_bin]"

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
    puts stderr "  Oder: tclsh demo-pdfa-gs.tcl --font /pfad/zu/DejaVuSans.ttf"
    exit 1
}
puts "Font:        $font_path"

pdf4tcl::loadBaseTrueTypeFont DejaVuSans $font_path
pdf4tcl::createFontSpecCID DejaVuSans cidSans

# -----------------------------------------------------------------------------
# Hilfsprozeduren
# -----------------------------------------------------------------------------

proc gs_convert {gs_bin src dst flavour} {
    # Ghostscript PDF/A-Konvertierung
    # PDFA_def.ps definiert Konformitaetsstufe und OutputIntent
    set pdfa_def [file join [file dirname $dst] _pdfa_def_[pid].ps]

    # PDFA_def.ps fuer Ghostscript (minimale Version)
    set part [string index $flavour 0]
    set conf [string toupper [string index $flavour 1]]

    set ps_content [string map [list %PART% $part %CONF% $conf] {
[ /Title (pdf4tcl PDF/A Demo)
  /Author (pdf4tcl)
  /DOCINFO pdfmark

[ /Marked false
  /DOCVIEW pdfmark

[ /CompatibilityLevel 1.4
  /ProcessColorModel /DeviceRGB
  /ColorConversionStrategy /sRGB
  /pdfmark
}]

    set fh [open $pdfa_def w]
    puts $fh $ps_content
    close $fh

    # PDFA_def.ps aus Ghostscript-Installation suchen
    set gs_pdfa ""
    foreach candidate {
        /usr/share/ghostscript/PDFA_def.ps
        /usr/share/ghostscript/10.0/lib/PDFA_def.ps
        /usr/share/ghostscript/10.02.1/lib/PDFA_def.ps
        /usr/share/ghostscript/10.03.1/lib/PDFA_def.ps
    } {
        if {[file exists $candidate]} { set gs_pdfa $candidate; break }
    }
    # Ghostscript lib automatisch finden
    if {$gs_pdfa eq ""} {
        catch {
            set gsver [exec $gs_bin --version]
            set gsver [string trim $gsver]
            set candidate "/usr/share/ghostscript/$gsver/lib/PDFA_def.ps"
            if {[file exists $candidate]} { set gs_pdfa $candidate }
        }
    }

    set gs_args [list \
        -dBATCH -dNOPAUSE -dNOSAFER \
        -sDEVICE=pdfwrite \
        -dPDFA=$part \
        -dPDFACompatibilityPolicy=1 \
        -sColorConversionStrategy=sRGB \
        -dCompatibilityLevel=1.4 \
        -sOutputFile=$dst \
    ]
    if {$gs_pdfa ne ""} {
        lappend gs_args $gs_pdfa
    }
    lappend gs_args $pdfa_def $src

    set rc [catch {exec $gs_bin {*}$gs_args 2>@1} out]
    file delete -force $pdfa_def

    if {$rc != 0} {
        return [list ok 0 msg $out]
    }
    return [list ok 1 msg ""]
}

# -----------------------------------------------------------------------------
# Quell-PDF mit pdf4tcl erzeugen
# -----------------------------------------------------------------------------

proc make_source_pdf {outfile pkgver} {
    set pdf [pdf4tcl::new %AUTO% -compress 1 -paper a4 -orient 0]

    $pdf metadata \
        -title   "pdf4tcl PDF/A-GS Demo" \
        -author  "pdf4tcl $pkgver" \
        -subject "Ghostscript PDF/A-Konvertierung" \
        -creator "pdf4tcl $pkgver"

    $pdf startPage

    # Kopfzeile
    $pdf setFillColor 0.10 0.25 0.50
    $pdf rectangle 0 797 595 45 -filled 1
    $pdf setFillColor 1 1 1
    $pdf setFont 18 cidSans
    $pdf text "pdf4tcl $pkgver -- PDF/A via Ghostscript" -x 40 -y 812
    $pdf setFont 10 cidSans
    $pdf text "Quell-PDF -- wird von Ghostscript nach PDF/A konvertiert" -x 40 -y 800
    $pdf setFillColor 0 0 0

    set y 750

    $pdf setFont 14 cidSans
    $pdf text "Workflow: pdf4tcl -> Ghostscript -> PDF/A" -x 50 -y $y
    incr y -30

    $pdf setFont 10 cidSans
    foreach line {
        "1. pdf4tcl erzeugt ein regulaeres PDF mit eingebetteten Fonts."
        "2. Ghostscript konvertiert das PDF nach PDF/A-1b oder PDF/A-2b."
        "3. Ghostscript fuegt OutputIntent (sRGB-ICC) und XMP hinzu."
        ""
        "Vorteil: Ghostscript uebernimmt die gesamte PDF/A-Validierung."
        "Nachteil: Ghostscript muss installiert sein (AGPL-3)."
        ""
        "Vorzuziehen fuer maximale Konformitaet wenn GS vorhanden."
        "pdf4tcl -pdfa vorzuziehen fuer GS-freie Deployments."
    } {
        $pdf text $line -x 50 -y $y
        incr y -16
    }

    incr y -10

    # Farbfelder
    $pdf setFont 11 cidSans
    $pdf text "DeviceRGB-Farben (werden von GS nach sRGB konvertiert):" -x 50 -y $y
    incr y -25

    set bx 50
    foreach {r g b label} {
        0.85 0.15 0.15 "Rot"
        0.15 0.65 0.15 "Gruen"
        0.15 0.35 0.85 "Blau"
        0.90 0.75 0.10 "Gelb"
        0.50 0.15 0.70 "Violett"
    } {
        $pdf setFillColor $r $g $b
        $pdf rectangle $bx [expr {$y - 10}] 88 22 -filled 1
        $pdf setFillColor 0 0 0
        $pdf setFont 8 cidSans
        $pdf text $label -x [expr {$bx + 5}] -y [expr {$y - 24}]
        incr bx 95
    }
    $pdf setFillColor 0 0 0

    $pdf endPage

    $pdf write -file $outfile
    $pdf destroy
    return $outfile
}

# -----------------------------------------------------------------------------
# Hauptprogramm
# -----------------------------------------------------------------------------

puts "pdf4tcl $pkgver -- PDF/A via Ghostscript"
puts [string repeat = 50]
puts ""

# Schritt 1: Quell-PDF erzeugen
set src_file [file join $out_dir demo-pdfa-gs-src.pdf]
make_source_pdf $src_file $pkgver
set kb [expr {[file size $src_file] / 1024}]
puts "Erzeugt: $src_file ($kb KB)"
puts ""

# Schritt 2: GS-Konvertierung
foreach flavour $flavours {
    set dst_file [file join $out_dir "demo-pdfa-gs-${flavour}.pdf"]
    puts -nonewline "Konvertiere nach PDF/A-$flavour ... "
    flush stdout

    set result [gs_convert $gs_bin $src_file $dst_file $flavour]

    if {[dict get $result ok]} {
        set kb [expr {[file size $dst_file] / 1024}]
        puts "OK ($kb KB)"
        puts "  -> $dst_file"
    } else {
        puts "FEHLER"
        puts "  [dict get $result msg]"
    }
}

puts ""
puts "Fertig. Dateien in: $out_dir"
