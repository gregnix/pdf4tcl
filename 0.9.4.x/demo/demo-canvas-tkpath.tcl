#!/usr/bin/env wish
# demo-canvas-tkpath.tcl -- tkpath (::tkp::canvas, PathCanvas) PDF export
#
# tkpath 0.4.2 item types: pline, polyline, ppolygon, prect, circle, ellipse,
#                          path, group, ptext, pimage
# PDF export: $pdf canvas .c  -- identisch wie bei tk::canvas
#
# Usage: wish demo-canvas-tkpath.tcl [outputdir]

package require Tk
puts [package require tkpath ]

set demodir  [file dirname [file normalize [info script]]]
set reporoot [file normalize [file join $demodir ../..]]
set auto_path [linsert $auto_path 0 $reporoot]
package require pdf4tcl

set outdir [expr {$argc > 0 ? [lindex $argv 0] : \
    [file join $demodir out]}]
file mkdir $outdir
set outfile [file join $outdir demo-canvas-tkpath.pdf]

set pdf [::pdf4tcl::new %AUTO% -paper a4 -orient true]

# ---------------------------------------------------------------------------
# Seite 1: Grundformen
# ---------------------------------------------------------------------------
$pdf startPage
$pdf setFont 16 Helvetica-Bold
$pdf text "tkpath Export -- Grundformen" -x 50 -y 50
$pdf setFont 9 Helvetica
$pdf setFillColor 0.4 0.4 0.4
$pdf text \
    "prect (-rx), circle, ellipse, pline, polyline, ppolygon, path, ptext" \
    -x 50 -y 65
$pdf setFillColor 0 0 0

tkp::canvas .tp1 -width 480 -height 510 \
    -background white -highlightthickness 0
pack .tp1

# prect mit -rx (abgerundete Ecken)
.tp1 create text 10 6 -text "prect (abgerundete Ecken, dash)" \
    -font {Helvetica 9 bold} -anchor w
.tp1 create prect 10 20 160 70 -rx 10 \
    -fill "#b3d1f0" -stroke "#0055aa" -strokewidth 2
.tp1 create prect 170 20 330 70 -rx 10 \
    -fill "" -stroke "#cc3300" -strokewidth 2 \
    -strokedasharray {6 3}
.tp1 create prect 340 20 470 70 -rx 20 \
    -fill "#f0e68c" -stroke "#8b6914" -strokewidth 1

# circle + ellipse
.tp1 create text 10 84 -text "circle, ellipse" \
    -font {Helvetica 9 bold} -anchor w
.tp1 create circle  55 130 -r 40 \
    -fill "#ffcccc" -stroke "#cc0000" -strokewidth 2
.tp1 create circle 155 130 -r 40 \
    -fill "" -stroke "#0000cc" -strokewidth 2
.tp1 create ellipse 280 130 -rx 80 -ry 35 \
    -fill "#ccffcc" -stroke "#006600" -strokewidth 2
.tp1 create ellipse 420 130 -rx 30 -ry 50 \
    -fill "#e0d0ff" -stroke "#550088" -strokewidth 2

# pline + polyline + Pfeilspitzen (0.3.3+)
.tp1 create text 10 182 -text "pline, polyline, Pfeilspitzen" \
    -font {Helvetica 9 bold} -anchor w
.tp1 create pline 10 198 200 198 \
    -stroke black -strokewidth 1
.tp1 create pline 10 212 200 212 \
    -stroke "#0055aa" -strokewidth 2 -strokedasharray {8 3}
.tp1 create pline 220 198 420 230 \
    -stroke "#cc3300" -strokewidth 2
.tp1 create polyline 10 240 60 220 110 250 160 225 210 250 260 225 \
    -stroke "#006600" -strokewidth 2 -fill "" 

# ppolygon
.tp1 create text 10 268 -text "ppolygon" \
    -font {Helvetica 9 bold} -anchor w
.tp1 create ppolygon \
    60 320  20 290  35 245  90 245  105 290 \
    -fill "#ddeeff" -stroke "#003399" -strokewidth 2
.tp1 create ppolygon \
    200 320  160 290  175 245  230 245  245 290 \
    -fill "#ffeedd" -stroke "#993300" -strokewidth 2
.tp1 create ppolygon \
    340 320  300 290  315 245  370 245  385 290 \
    -fill "#eeffee" -stroke "#009933" -strokewidth 2

# path (SVG-Syntax)
.tp1 create text 10 338 -text "path (SVG-Syntax: M L C Q A Z)" \
    -font {Helvetica 9 bold} -anchor w
.tp1 create path "M 10 400 C 60 340 120 440 180 400 \
    C 240 340 300 440 360 400 L 420 400" \
    -fill "" -stroke "#880088" -strokewidth 2
.tp1 create path "M 10 460 L 80 430 L 80 490 Z" \
    -fill "#ffd0a0" -stroke "#cc6600" -strokewidth 2
.tp1 create path "M 120 460 Q 180 410 240 460 Q 300 510 360 460" \
    -fill "" -stroke "#0055cc" -strokewidth 2
# Bogen A
.tp1 create path "M 380 430 A 40 40 0 0 1 460 430 Z" \
    -fill "#ccffcc" -stroke "#009900" -strokewidth 2

# ptext
.tp1 create text 10 480 -text "ptext" \
    -font {Helvetica 9 bold} -anchor w
.tp1 create ptext 80 500 -text "tkpath" \
    -fontfamily Helvetica -fontsize 20 -fontweight bold \
    -fill "#1a3f7a" -textanchor middle
.tp1 create ptext 220 500 -text "SVG-Text" \
    -fontfamily Helvetica -fontsize 16 \
    -fill "#cc3300" -textanchor middle
.tp1 create ptext 370 500 -text "Italic" \
    -fontfamily Helvetica -fontsize 18 -fontslant italic \
    -fill "#006600" -textanchor middle

update
set bb [.tp1 bbox all]
$pdf canvas .tp1 -bbox $bb -x 50 -y 80 -width 480 -height 510
destroy .tp1
$pdf endPage

# ---------------------------------------------------------------------------
# Seite 2: Gradienten, Gruppen, Transformationen
# ---------------------------------------------------------------------------
$pdf startPage
$pdf setFont 16 Helvetica-Bold
$pdf text "tkpath Export -- Gradienten + Gruppen" -x 50 -y 50
$pdf setFont 9 Helvetica
$pdf setFillColor 0.4 0.4 0.4
$pdf text "gradient create linear/radial, group mit parent, -matrix" \
    -x 50 -y 65
$pdf setFillColor 0 0 0

tkp::canvas .tp2 -width 480 -height 460 \
    -background white -highlightthickness 0
pack .tp2

# Lineare Gradienten
.tp2 create text 10 6 -text "Lineare Gradienten" \
    -font {Helvetica 9 bold} -anchor w
set g1 [.tp2 gradient create linear \
    -stops {{0 "#b3d1f0"} {1 "#0055aa"}}]
.tp2 create prect 10 20 220 65 -fill $g1 -stroke "" -rx 6

set g2 [.tp2 gradient create linear \
    -stops {{0 "#ffcccc"} {0.5 "#ff6600"} {1 "#cc0000"}}]
.tp2 create prect 240 20 470 65 -fill $g2 -stroke "" -rx 6

set g3 [.tp2 gradient create linear \
    -stops {{0 "#ccffcc"} {1 "#006600"}} \
    -lineartransition {0 0 0 1}]
.tp2 create prect 10 75 220 120 -fill $g3 -stroke "" -rx 6

set g4 [.tp2 gradient create linear \
    -stops {{0 "#f0e68c"} {0.4 "#ff6600"} {1 "#8b0000"}}]
.tp2 create prect 240 75 470 120 -fill $g4 -stroke "" -rx 6

# Radiale Gradienten
.tp2 create text 10 132 -text "Radiale Gradienten" \
    -font {Helvetica 9 bold} -anchor w
set r1 [.tp2 gradient create radial \
    -stops {{0 white} {1 "#0055aa"}}]
.tp2 create circle 70 180 -r 45 -fill $r1 -stroke ""

set r2 [.tp2 gradient create radial \
    -stops {{0 white} {0.6 "#ff6600"} {1 "#cc0000"}}]
.tp2 create circle 190 180 -r 45 -fill $r2 -stroke ""

set r3 [.tp2 gradient create radial \
    -stops {{0 "#ffff00"} {1 "#006600"}}]
.tp2 create ellipse 330 180 -rx 80 -ry 45 -fill $r3 -stroke ""

# Gruppen mit group + parent
.tp2 create text 10 238 -text "Gruppen (group + parent)" \
    -font {Helvetica 9 bold} -anchor w

foreach {gx col stroke} {
    10  "#ddeeff" "#003399"
    170 "#ffeedd" "#993300"
    330 "#eeffee" "#009933"
} {
    set gid [.tp2 create group]
    .tp2 create prect 0 0 140 120 -rx 8 \
        -fill $col -stroke $stroke -strokewidth 1 -parent $gid
    .tp2 create circle 70 40 -r 28 \
        -fill $stroke -stroke "" -parent $gid
    .tp2 create ptext 70 100 -text "Gruppe" \
        -fontfamily Helvetica -fontsize 12 -fontweight bold \
        -fill $stroke -textanchor middle -parent $gid
    .tp2 move $gid $gx 252
}

# path mit -matrix (Transformation)
.tp2 create text 10 386 -text "path mit -matrix (Rotation)" \
    -font {Helvetica 9 bold} -anchor w
set pi 3.14159265358979
foreach {angle col cx cy} {
    0    "#cc0000" 80  420
    45   "#0055aa" 200 420
    90   "#006600" 320 420
    135  "#880088" 440 420
} {
    set rad [expr {$angle * $pi / 180.0}]
    set c   [expr {cos($rad)}]
    set s   [expr {sin($rad)}]
    .tp2 create path "M -30 -10 L 30 -10 L 30 10 L -30 10 Z" \
        -fill $col -stroke "" \
        -matrix [list [list $c [expr {-$s}]] [list $s $c] [list $cx $cy]]
}

update
set bb [.tp2 bbox all]
$pdf canvas .tp2 -bbox $bb -x 50 -y 80 -width 480 -height 460
destroy .tp2
$pdf endPage

# ---------------------------------------------------------------------------
# Seite 3: SVG path, Pfeilspitzen, pimage
# ---------------------------------------------------------------------------
$pdf startPage
$pdf setFont 16 Helvetica-Bold
$pdf text "tkpath Export -- Pfeilspitzen + Opacity" -x 50 -y 50
$pdf setFont 9 Helvetica
$pdf setFillColor 0.4 0.4 0.4
$pdf text "pline/path -startarrow/-endarrow, -fillopacity/-strokeopacity" \
    -x 50 -y 65
$pdf setFillColor 0 0 0

tkp::canvas .tp3 -width 480 -height 300 \
    -background white -highlightthickness 0
pack .tp3

# Pfeilspitzen (0.3.3+) -- -startarrow/-endarrow sind Boolean (0/1)
.tp3 create text 10 6 -text "Pfeilspitzen (-startarrow -endarrow)" \
    -font {Helvetica 9 bold} -anchor w
foreach {y ea sa col} {
    28  0 0 black
    48  1 0 "#0055aa"
    68  0 1 "#cc3300"
    88  1 1 "#006600"
} {
    .tp3 create pline 30 $y 440 $y \
        -stroke $col -strokewidth 2 \
        -startarrow $sa -endarrow $ea \
        -startarrowlength 12 -endarrowlength 12
}

# Opacity
.tp3 create text 10 108 -text "Opacity (-fillopacity -strokeopacity)" \
    -font {Helvetica 9 bold} -anchor w
foreach {x op} {10 1.0  110 0.75  210 0.5  310 0.25  390 0.1} {
    .tp3 create prect $x 122 [expr {$x+90}] 180 -rx 6 \
        -fill "#0055aa" -stroke "#cc0000" -strokewidth 3 \
        -fillopacity $op -strokeopacity $op
    .tp3 create ptext [expr {$x+45}] 200 \
        -text [format "%.2f" $op] \
        -fontfamily Helvetica -fontsize 9 \
        -fill "#333333" -textanchor middle
}

# Overlapping Opacity (zeigt Blending)
.tp3 create text 10 218 -text "Überlappende Formen mit Opacity" \
    -font {Helvetica 9 bold} -anchor w
foreach {x col} {
    30  "#cc0000"
    90  "#0055aa"
    150 "#006600"
    210 "#880088"
} {
    .tp3 create circle $x 265 -r 45 \
        -fill $col -stroke "" -fillopacity 0.5
}

update
set bb [.tp3 bbox all]
$pdf canvas .tp3 -bbox $bb -x 50 -y 80 -width 480 -height 300
destroy .tp3
$pdf endPage

$pdf write -file $outfile
$pdf destroy

puts "tkpath demo geschrieben: $outfile"
