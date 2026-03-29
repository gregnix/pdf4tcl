#!/usr/bin/env wish
# demo-canvas-0.9.4.24.tcl -- demonstrate canvas + tko::path export (0.9.4.24)
#
# 0.9.4.24 fix: CanvasDoTkoPathItem no longer crashes when a tko::path
# item returns empty coords (window items, group items, items with -matrix).
#
# This demo shows:
#   1. tk::canvas export -- all standard item types
#   2. tko::path export  -- vector items via $pdf canvas .p -bbox [$p bbox all]
#   3. tko::path window item -- previously crashed, now silently skipped
#   4. Mixed canvas: normal items + window item on same canvas
#
# Usage: wish demo-canvas-0.9.4.24.tcl [outputdir]

package require Tk
set demodir  [file dirname [file normalize [info script]]]
set reporoot [file normalize [file join $demodir ../..]]
set auto_path [linsert $auto_path 0 $reporoot]

package require pdf4tcl

set hasTko [expr {![catch {package require tko}]}]
catch { set ::path::antialias 1 }

set outdir [expr {$argc > 0 ? [lindex $argv 0] : [file join $demodir out]}]
file mkdir $outdir
set outfile [file join $outdir demo-canvas-0.9.4.24.pdf]

# ===========================================================================
# PDF erzeugen
# ===========================================================================

set pdf [::pdf4tcl::new %AUTO% -paper a4 -orient true]

# ---------------------------------------------------------------------------
# Seite 1: tk::canvas -- Standarditems
# ---------------------------------------------------------------------------
$pdf startPage

$pdf setFont 16 Helvetica-Bold
$pdf text "Demo canvas-Export (0.9.4.24)" -x 50 -y 50

$pdf setFont 10 Helvetica
$pdf setFillColor 0.3 0.3 0.3
$pdf text "tk::canvas mit rectangle, oval, line, polygon, arc, text" \
    -x 50 -y 68
$pdf setFillColor 0 0 0

canvas .c1 -width 480 -height 520 -background white -highlightthickness 0
pack .c1

# Rechtecke
.c1 create text 10 10 -text "Rechtecke" -font {Helvetica 10 bold} -anchor w
.c1 create rectangle 10 28 150 80 \
    -fill "#b3d1f0" -outline "#0055aa" -width 2
.c1 create rectangle 160 28 300 80 \
    -fill "" -outline "#cc3300" -width 2 -dash {6 3}
.c1 create rectangle 310 28 450 80 \
    -fill "#f0e68c" -outline "#8b6914" -width 1

# Linien + capstyle
.c1 create text 10 92 -text "Linien + capstyle + dash" \
    -font {Helvetica 10 bold} -anchor w
.c1 create line 10 110 200 110 -fill black -width 2
.c1 create line 10 125 200 125 -fill "#0055aa" -width 2 -dash {8 3}
.c1 create line 10 140 200 140 \
    -fill "#cc3300" -width 2 -arrow last
.c1 create line 220 110 450 140 \
    -fill "#006600" -width 3 -arrow both
# capstyle
.c1 create line 10 158 100 158 -fill "#880088" -width 8 -capstyle butt
.c1 create line 120 158 210 158 -fill "#006699" -width 8 -capstyle round
.c1 create line 230 158 320 158 -fill "#996600" -width 8 -capstyle projecting

# Ovals
.c1 create text 10 178 -text "Ovals" -font {Helvetica 10 bold} -anchor w
.c1 create oval 10  195 130 255 -fill "#ffcccc" -outline "#cc0000" -width 2
.c1 create oval 145 195 265 255 -fill "" -outline "#0000cc" -width 2
.c1 create oval 280 195 450 240 -fill "#ccffcc" -outline "#006600" -width 1

# Polygone + joinstyle
.c1 create text 10 268 -text "Polygone + joinstyle" \
    -font {Helvetica 10 bold} -anchor w
.c1 create polygon 10 340 60 280 120 340 \
    -fill "#ddeeff" -outline "#003399" -width 2 -joinstyle miter
.c1 create polygon 140 340 190 280 250 340 \
    -fill "#ffeedd" -outline "#993300" -width 2 -joinstyle round
.c1 create polygon 270 340 320 280 380 340 \
    -fill "#eeffee" -outline "#009933" -width 2 -joinstyle bevel

# Arc
.c1 create text 10 355 -text "Arc + smooth" \
    -font {Helvetica 10 bold} -anchor w
.c1 create arc 10 370 130 450 \
    -start 30 -extent 240 -style pieslice \
    -fill "#ffd0a0" -outline "#cc6600" -width 2
.c1 create arc 145 370 265 450 \
    -start 0 -extent 180 -style chord \
    -fill "#a0d0ff" -outline "#0055cc" -width 2
.c1 create arc 280 370 390 450 \
    -start 45 -extent 270 -style arc \
    -outline "#008800" -width 3

# smooth line
.c1 create line 10 470 80 390 150 470 220 390 290 470 \
    -fill "#cc0088" -width 2 -smooth 1

# Text mit angle
.c1 create text 360 420 -text "Rotiert 30°" \
    -font {Helvetica 11 bold} -fill "#003399" \
    -angle 30 -anchor center

update
$pdf canvas .c1 -x 50 -y 80 -width 480 -height 520
destroy .c1

$pdf endPage

# ---------------------------------------------------------------------------
# Seite 2: tko::path -- wenn vorhanden
# ---------------------------------------------------------------------------
$pdf startPage

$pdf setFont 16 Helvetica-Bold
$pdf text "tko::path Export (0.9.4.24 Fix)" -x 50 -y 50

if {$hasTko} {
    $pdf setFont 10 Helvetica
    $pdf setFillColor 0.3 0.3 0.3
    $pdf text "tko::path: rect, circle, ellipse, polygon, path, text" \
        -x 50 -y 68
    $pdf setFillColor 0 0 0

    tko::path .p1 -width 480 -height 260 \
        -background white -highlightthickness 0
    pack .p1

    # rect mit abgerundeten Ecken
    .p1 create rect 10 10 160 70 -rx 12 \
        -fill "#b3d1f0" -stroke "#0055aa" -strokewidth 2
    .p1 create rect 170 10 330 70 \
        -fill "" -stroke "#cc3300" -strokewidth 2 \
        -strokedasharray {6 3}

    # circle + ellipse
    .p1 create circle 60 130 -r 45 \
        -fill "#ffcccc" -stroke "#cc0000" -strokewidth 2
    .p1 create ellipse 220 130 -rx 70 -ry 40 \
        -fill "#ccffcc" -stroke "#006600" -strokewidth 2
    .p1 create circle 380 130 -r 45 \
        -fill "" -stroke "#0000cc" -strokewidth 2

    # path (SVG-Syntax)
    .p1 create path "M 10 200 C 60 150 120 250 180 200 \
        C 240 150 300 250 360 200 L 470 200" \
        -fill "" -stroke "#880088" -strokewidth 2

    # text
    .p1 create text 240 60 -text "tko::path" \
        -fontsize 14 -fontweight bold \
        -fill "#1a3f7a" -textanchor middle

    update
    set bb [.p1 bbox all]
    $pdf canvas .p1 -bbox $bb -x 50 -y 80 -width 480 -height 260
    destroy .p1

    # -----------
    # tko window item -- 0.9.4.24 fix: kein crash mehr
    # -----------
    $pdf setFont 12 Helvetica-Bold
    $pdf setFillColor 0.8 0.1 0.1
    $pdf text "tko::path window item -- 0.9.4.24 Fix" -x 50 -y 360
    $pdf setFillColor 0 0 0

    $pdf setFont 9 Helvetica
    $pdf text "Vorher (0.9.4.23): crash \"can't read x1: no such variable\"" \
        -x 50 -y 378
    $pdf text "Jetzt (0.9.4.24): window item wird still übersprungen," \
        -x 50 -y 393
    $pdf text "alle anderen Items werden korrekt exportiert." \
        -x 50 -y 408

    tko::path .p2 -width 300 -height 100 \
        -background white -highlightthickness 0
    pack .p2

    # Normale Items
    .p2 create rect 5 5 145 95 \
        -fill "#ddeeff" -stroke "#003399" -strokewidth 2
    .p2 create circle 230 50 -r 40 \
        -fill "#ffeedd" -stroke "#993300" -strokewidth 2

    # window Item -- das war der Crasher
    button .p2.b -text "Button (window)" -font {Helvetica 8}
    .p2 create window 165 30 -window .p2.b

    .p2 create text 230 50 -text "OK" \
        -fontsize 11 -fontweight bold \
        -fill "#006600" -textanchor middle

    update
    set bb2 [.p2 bbox all]
    # Dieser Aufruf crashte in 0.9.4.23 -- jetzt OK:
    set err ""
    if {[catch {
        $pdf canvas .p2 -bbox $bb2 -x 50 -y 420 -width 300 -height 100
    } err]} {
        $pdf setFillColor 0.8 0 0
        $pdf setFont 9 Helvetica-Bold
        $pdf text "Export-Fehler: $err" -x 50 -y 440
        $pdf setFillColor 0 0 0
    } else {
        $pdf setFont 9 Helvetica
        $pdf setFillColor 0 0.4 0
        $pdf text "✓ Kein Crash -- window item übersprungen, rect + circle exportiert" \
            -x 50 -y 540
        $pdf setFillColor 0 0 0
    }
    destroy .p2

} else {
    $pdf setFont 11 Helvetica
    $pdf setFillColor 0.4 0.4 0.4
    $pdf text "(tko::path nicht verfügbar -- package require tko fehlgeschlagen)" \
        -x 50 -y 100
    $pdf setFillColor 0 0 0
}

$pdf endPage

# ---------------------------------------------------------------------------
# Seite 3: Zusammenfassung des Fixes
# ---------------------------------------------------------------------------
$pdf startPage

$pdf setFont 16 Helvetica-Bold
$pdf text "0.9.4.24 — Was wurde geändert" -x 50 -y 50

$pdf setFont 9 Helvetica-Bold
$pdf text "Datei:" -x 50 -y 80
$pdf setFont 9 Courier
$pdf text "src/main.tcl  (CanvasDoTkoPathItem, window-Zweig)" -x 100 -y 80

$pdf setFont 9 Helvetica-Bold
$pdf text "Vorher (buggy):" -x 50 -y 106
$pdf setFont 9 Courier
$pdf setFillColor 0.7 0.1 0.1
foreach {line txt} {
    120 "foreach \{x1 y1\} \[\$path coords \$id\] break"
    132 "# crash wenn coords leer -- x1/y1 undefiniert"
    144 "set x \[expr \{\$x1 - \$width * \$dx\}\]  ;# can't read x1"
} {
    $pdf text $txt -x 100 -y $line
}
$pdf setFillColor 0 0 0

$pdf setFont 9 Helvetica-Bold
$pdf text "Nachher (fix):" -x 50 -y 168
$pdf setFont 9 Courier
$pdf setFillColor 0 0.4 0
foreach {line txt} {
    182 "# BUG-C1 fix: coords may be empty for group/matrix items"
    194 "set _coords \[\$path coords \$id\]"
    206 "if \{\[llength \$_coords\] < 2\} return  ;# sicher"
    218 "foreach \{x1 y1\} \$_coords break"
} {
    $pdf text $txt -x 100 -y $line
}
$pdf setFillColor 0 0 0

$pdf setFont 9 Helvetica-Bold
$pdf text "Betroffen:" -x 50 -y 244
$pdf setFont 9 Helvetica
foreach {line txt} {
    258 "tko::path window items (Tk-Widget eingebettet)"
    270 "tko::path group items (falls coords leer)"
    282 "tko::path items mit -matrix (falls coords andere Länge)"
} {
    $pdf text "• $txt" -x 60 -y $line
}

$pdf setFont 9 Helvetica-Bold
$pdf text "Verhalten nach Fix:" -x 50 -y 308
$pdf setFont 9 Helvetica
$pdf text "• window item wird still übersprungen (kein Vektor möglich)" \
    -x 60 -y 322
$pdf text "• alle anderen Items auf demselben tko::path werden korrekt exportiert" \
    -x 60 -y 334
$pdf text "• kein Crash, kein Fehlermeldung" \
    -x 60 -y 346

$pdf endPage

$pdf write -file $outfile
$pdf destroy

puts "pdf4tcl 0.9.4.24 -- canvas demo"
puts "Geschrieben: $outfile"
