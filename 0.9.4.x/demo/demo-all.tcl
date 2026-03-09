#!/usr/bin/env tclsh
# demo-all.tcl -- Comprehensive demonstration of pdf4tcl features
# Shows: text, fonts, colors, graphics, images, forms, hyperlinks,
#        metadata, bookmarks, drawTextBox, rotated text, clipping,
#        line styles, fill colors, transparency areas, XObjects.
#
# Run from the demo/ directory:
#   tclsh demo-all.tcl
#
# Output: demo-all-output.pdf

set demodir  [file dirname [file normalize [info script]]]
set reporoot [file normalize [file join $demodir ../..]]
set auto_path [linsert $auto_path 0 $reporoot]

package require pdf4tcl

# Resolve exact file and version of loaded pdf4tcl
set pkgfile [lindex [package ifneeded pdf4tcl [package require pdf4tcl]] end]
set pkgver  [package require pdf4tcl]

set outfile [file join $demodir demo-all-output.pdf]

#puts "Written: $outfile"
#puts "Package: pdf4tcl $pkgver"
#puts "File:    $pkgfile"


# ------------------------------------------------------------------
# Helper: draw a section header band
proc sectionHeader {p title y {color {0.15 0.35 0.65}}} {
    $p setFillColor {*}$color
    $p rectangle 40 [expr {$y - 11}] 515 20 -filled 1
    $p setFillColor 1 1 1
    $p setFont 11 Helvetica-Bold
    $p text $title -x 45 -y $y
    $p setFillColor 0 0 0
    return [expr {$y + 22}]
}

# Helper: draw a thin separator line
proc separator {p y} {
    $p setStrokeColor 0.7 0.7 0.7
    $p setLineWidth 0.3
    $p line 40 $y 555 $y
    $p setStrokeColor 0 0 0
    $p setLineWidth 1
}

# ------------------------------------------------------------------
# Create document
pdf4tcl::new p -orient 1 -compress 0 -paper a4

p metadata \
    -title    "pdf4tcl Feature Overview" \
    -author   "pdf4tcl fork" \
    -subject  "Demonstration of all pdf4tcl capabilities" \
    -keywords "tcl,pdf,pdf4tcl,demo" \
    -creator  "demo-all.tcl" \
    -creationdate 0

# ------------------------------------------------------------------
# Page labels: page 1 = cover (roman "i"), pages 2-5 = arabic 1-4
# ------------------------------------------------------------------
p pageLabel 0 -style r
p pageLabel 1 -style D -start 1

# ==================================================================
# PAGE 1: Header info + Text & Fonts
# ==================================================================
p startPage
p bookmarkAdd -title "Page 1: Text and Fonts"

# -- Title bar --
p setFillColor 0.10 0.25 0.50
p rectangle 0 0 595 95 -filled 1
p setFillColor 1 1 1
p setFont 22 Helvetica-Bold
p text "pdf4tcl Feature Overview" -x 40 -y 30 -align left
p setFont 10 Helvetica
p text "Version: $pkgver" -x 40 -y 58
p text "File:    $pkgfile" -x 40 -y 72
p setFillColor 0 0 0

# Background for content area
p setFillColor 1 1 1
p rectangle 0 90 595 752 -filled 1
p setFillColor 0 0 0

set y 110
set y [sectionHeader p "1. Text and Fonts" $y]

# Serif fonts
p setFont 11 Times-Roman
p text "Times-Roman (normal)" -x 50 -y $y
incr y 16
p setFont 11 Times-Bold
p text "Times-Bold" -x 50 -y $y
incr y 16
p setFont 11 Times-Italic
p text "Times-Italic" -x 50 -y $y
incr y 16
p setFont 11 Times-BoldItalic
p text "Times-BoldItalic" -x 50 -y $y
incr y 22

# Sans fonts
p setFont 11 Helvetica
p text "Helvetica (normal)" -x 50 -y $y
incr y 16
p setFont 11 Helvetica-Bold
p text "Helvetica-Bold" -x 50 -y $y
incr y 16
p setFont 11 Helvetica-Oblique
p text "Helvetica-Oblique" -x 50 -y $y
incr y 16
p setFont 11 Helvetica-BoldOblique
p text "Helvetica-BoldOblique" -x 50 -y $y
incr y 22

# Monospace
p setFont 11 Courier
p text "Courier (normal)" -x 50 -y $y
incr y 16
p setFont 11 Courier-Bold
p text "Courier-Bold" -x 50 -y $y
incr y 22

# Font sizes
set y [sectionHeader p "1b. Font Sizes" $y]
foreach size {7 9 11 14 18 24} {
    p setFont $size Helvetica
    p text "${size}pt" -x 50 -y $y
    incr y [expr {$size + 6}]
}

incr y 6
separator p $y
incr y 8
set y [sectionHeader p "1c. Text Alignment and Rotation" $y]

p setFont 11 Helvetica
p text "Left aligned"   -x 50  -y $y -align left
p text "Center"         -x 297 -y $y -align center
p text "Right aligned"  -x 545 -y $y -align right
incr y 20
p text "Rotated 30 deg" -x 100 -y $y -angle 30
p text "Rotated 45 deg" -x 220 -y $y -angle 45
p text "Rotated -15 deg" -x 360 -y $y -angle -15
incr y 30

separator p $y
incr y 8
set y [sectionHeader p "1d. drawTextBox (auto word wrap)" $y]

p setFont 10 Times-Roman
set txt "The drawTextBox method wraps long text automatically within a defined \
rectangular area. It supports left, center and right alignment. \
This text is long enough to demonstrate the wrapping behavior across multiple lines \
in a fixed-width box."
p rectangle 50 $y 240 60
p drawTextBox 50 $y 240 60 $txt -align left
p rectangle 305 $y 240 60
p drawTextBox 305 $y 240 60 $txt -align right

# ==================================================================
# PAGE 2: Colors and Graphics
# ==================================================================
p startPage
p bookmarkAdd -title "Page 2: Colors and Graphics"

set y 30
set y [sectionHeader p "2. Colors -- RGB and Named" $y]

# Color swatches
set colors {
    "1 0 0"       "Red"
    "0 0.6 0"     "Green"
    "0 0 1"       "Blue"
    "1 0.5 0"     "Orange"
    "0.5 0 0.5"   "Purple"
    "0 0.7 0.7"   "Cyan"
    "1 1 0"       "Yellow"
    "0.3 0.3 0.3" "Gray"
}
set cx 50
foreach {rgb label} $colors {
    p setFillColor {*}$rgb
    p rectangle $cx $y 35 20 -filled 1
    p setFillColor 0 0 0
    p setFont 7 Helvetica
    p text $label -x $cx -y [expr {$y + 24}]
    incr cx 45
}
incr y 40

separator p $y
incr y 8
set y [sectionHeader p "3. Lines and Line Styles" $y]

p setFont 9 Helvetica

# Solid lines of different widths
foreach {lw label} {0.5 "0.5pt" 1 "1pt" 2 "2pt" 4 "4pt"} {
    p setLineWidth $lw
    p setStrokeColor 0 0 0
    p line 50 $y 250 $y
    p text $label -x 255 -y [expr {$y - 3}]
    incr y 12
}
p setLineWidth 1

incr y 4
# Dashed lines
foreach {dash label} {
    "4 4"   "dash {4 4}"
    "8 3"   "dash {8 3}"
    "2 2"   "dot {2 2}"
    "8 3 2 3" "dash-dot {8 3 2 3}"
} {
    p setLineDash {*}$dash
    p line 50 $y 250 $y
    p text $label -x 255 -y [expr {$y - 3}]
    incr y 12
}
p setLineDash  ;# reset

incr y 4
separator p $y
incr y 8
set y [sectionHeader p "4. Shapes" $y]

# Rectangle (outline)
p setLineWidth 1
p setStrokeColor 0 0 0.8
p rectangle 50 $y 80 40
p setFont 8 Helvetica
p text "rectangle" -x 50 -y [expr {$y + 50}]

# Filled rectangle
p setFillColor 0.8 0.9 1
p rectangle 145 $y 80 40 -filled 1
p setFillColor 0 0 0
p text "filled rect" -x 145 -y [expr {$y + 50}]

# Circle
p setStrokeColor 0.8 0 0
p circle 285 [expr {$y + 20}] 20
p text "circle" -x 265 -y [expr {$y + 50}]

# Filled circle
p setFillColor 1 0.8 0.8
p circle 365 [expr {$y + 20}] 20 -filled 1
p setFillColor 0 0 0
p text "filled circle" -x 348 -y [expr {$y + 50}]

# Oval  -- oval x y rx ry  (Mittelpunkt, Radien)
p setStrokeColor 0 0.6 0
p oval 480 [expr {$y + 20}] 40 20
p text "oval" -x 440 -y [expr {$y + 50}]

incr y 66

# Arc
p setStrokeColor 0 0 0.6
p setLineWidth 2
p arc 90 [expr {$y + 25}] 25 25 0 270
p setFont 8 Helvetica
p text "arc 0-270" -x 60 -y [expr {$y + 60}]

# Polygon
p setStrokeColor 0.5 0 0.5
p setLineWidth 1
p polygon 185 $y 220 $y 235 [expr {$y+40}] 200 [expr {$y+50}] 170 [expr {$y+40}]
p text "polygon" -x 180 -y [expr {$y + 60}]

# Curve (bezier)
p setStrokeColor 0.8 0.4 0
p setLineWidth 1.5
p curve 280 [expr {$y+40}] 300 $y 340 [expr {$y+50}] 360 $y
p text "bezier curve" -x 295 -y [expr {$y + 60}]

# Arrow
p setStrokeColor 0 0.5 0
p setLineWidth 1
p arrow 420 [expr {$y+20}] 500 [expr {$y+20}] 8
p text "arrow" -x 445 -y [expr {$y + 40}]

incr y 76
separator p $y
incr y 8
set y [sectionHeader p "5. Clipping" $y]

# Draw colored rectangles clipped to a rectangular area
p gsave
p clip 50 $y 80 50
p setFillColor 1 0.8 0
p rectangle 50 $y 80 50 -filled 1
p setFillColor 0.8 0 0
p rectangle 65 [expr {$y+10}] 80 30 -filled 1
p setFillColor 0.2 0.2 0.8
p circle 90 [expr {$y+25}] 30 -filled 1
p grestore
p setFont 8 Helvetica
p text "clip rect" -x 52 -y [expr {$y + 54}]

# ==================================================================
# PAGE 3: Images + drawTextBox
# ==================================================================
p startPage
p bookmarkAdd -title "Page 3: Images"

set y 30
set y [sectionHeader p "6. Images (JPEG and PNG)" $y]

set imgdir [file join $reporoot examples]

if {[file exists [file join $imgdir smile.png]]} {
    p addImage [file join $imgdir smile.png] -id smile
    p putImage smile 50 $y -width 60 -height 60
    p setFont 8 Helvetica
    p text "PNG (smile.png)" -x 50 -y [expr {$y + 64}]
}
if {[file exists [file join $imgdir tcl.jpg]]} {
    p addImage [file join $imgdir tcl.jpg] -id tcllogo
    p putImage tcllogo 130 $y -width 90 -height 60
    p setFont 8 Helvetica
    p text "JPEG (tcl.jpg)" -x 130 -y [expr {$y + 64}]
}
if {[file exists [file join $imgdir gmarbles2.jpg]]} {
    p addImage [file join $imgdir gmarbles2.jpg] -id marbles
    p putImage marbles 240 $y -width 110 -height 75
    p setFont 8 Helvetica
    p text "JPEG (gmarbles2.jpg)" -x 240 -y [expr {$y + 79}]
}

incr y 100
separator p $y
incr y 8
set y [sectionHeader p "7. Repeated Graphics (logo drawn 4 times)" $y]

proc drawLogo {p x y} {
    $p setFillColor 0.1 0.3 0.6
    $p rectangle $x $y 80 36 -filled 1
    $p setFillColor 1 1 1
    $p setFont 12 Helvetica-Bold
    $p text "pdf4tcl" -x [expr {$x+10}] -y [expr {$y+22}]
    $p setFillColor 0 0 0
}
foreach cx {50 160 270 380} {
    drawLogo p $cx $y
}
p setFont 8 Helvetica
p text "Same logo proc called 4 times" -x 50 -y [expr {$y + 40}]

# ==================================================================
# PAGE 4: Forms (addForm)
# ==================================================================
p startPage
p bookmarkAdd -title "Page 4: Form Fields"

set y 30
set y [sectionHeader p "8. Form Fields (addForm)" $y]

p setFont 10 Helvetica

# Text fields
p text "Text field:"         -x 50 -y $y
p rectangle 160 [expr {$y-2}] 180 16
p addForm text 160 [expr {$y-2}] 180 16 -id demo_text -init "Type here"
incr y 24

p text "Password field:"     -x 50 -y $y
p rectangle 160 [expr {$y-2}] 120 16
p addForm password 160 [expr {$y-2}] 120 16 -id demo_pw
incr y 24

# Checkbox
p text "Checkbox (checked):" -x 50 -y $y
p rectangle 160 [expr {$y-2}] 14 14
p addForm checkbutton 160 [expr {$y-2}] 14 14 -id demo_chk -init 1
incr y 24

# Combobox
p text "Combobox:"           -x 50 -y $y
p rectangle 160 [expr {$y-2}] 180 16
p addForm combobox 160 [expr {$y-2}] 180 16 -id demo_combo \
    -options {Tcl Tk pdf4tcl "Open Source"} -init "pdf4tcl"
incr y 24

# Listbox
p text "Listbox:"            -x 50 -y $y
p rectangle 160 [expr {$y-2}] 180 60
p addForm listbox 160 [expr {$y-2}] 180 60 -id demo_list \
    -options {Tcl Tk pdf4tcl "Open Source" "SourceForge" GitHub}
incr y 70

# Radio buttons
p text "Radio group:"        -x 50 -y $y
foreach {label val xpos} {"Option A" A 160 "Option B" B 230 "Option C" C 300} {
    p rectangle $xpos [expr {$y-2}] 12 12
    p addForm radiobutton $xpos [expr {$y-2}] 12 12 \
        -id "radio_$val" -group demo_radio -value $val
    p text $label -x [expr {$xpos+16}] -y $y
}
incr y 24

# Pushbutton
p text "Pushbutton:"         -x 50 -y $y
p addForm pushbutton 160 [expr {$y-2}] 100 20 \
    -id demo_btn -caption "Click Me" \
    -action uri -url "https://github.com/gregnix/pdf4tcl"
incr y 30

# Signature
p text "Signature field:"    -x 50 -y $y
p rectangle 160 [expr {$y-2}] 200 40
p addForm signature 160 [expr {$y-2}] 200 40 -id demo_sig
incr y 50

# ==================================================================
# PAGE 5: Hyperlinks + Metadata + Bookmarks
# ==================================================================
p startPage
p bookmarkAdd -title "Page 5: Hyperlinks and Metadata"

set y 30
set y [sectionHeader p "9. hyperlinkAdd (SF ticket #15)" $y]

p setFont 10 Helvetica

# Invisible links
p text "Invisible link area (click to open):" -x 50 -y $y
incr y 18
foreach {label url} {
    "pdf4tcl on SourceForge"        "https://sourceforge.net/p/pdf4tcl"
    "Fork on GitHub (gregnix)"      "https://github.com/gregnix/pdf4tcl"
    "SF Ticket #9 (addForm)"        "https://sourceforge.net/p/pdf4tcl/tickets/9"
    "SF Ticket #15 (hyperlinkAdd)"  "https://sourceforge.net/p/pdf4tcl/tickets/15"
} {
    p setFont 10 Helvetica
    set w [p getStringWidth $label]
    p setFillColor 0.05 0.35 0.65
    p text $label -x 70 -y $y
    # Underline
    p setFillColor 0.05 0.35 0.65
    p rectangle 70 [expr {$y+2}] $w 0.75 -filled 1
    p setFillColor 0 0 0
    p hyperlinkAdd 70 [expr {$y-10}] $w 14 $url
    incr y 18
}

incr y 6
separator p $y
incr y 8
set y [sectionHeader p "9b. Visible link borders" $y]

p setFont 10 Helvetica
p text "Blue border (1pt):"    -x 50  -y $y
p hyperlinkAdd 180 [expr {$y-10}] 195 14 "https://sourceforge.net/p/pdf4tcl" \
    -borderwidth 1 -bordercolor {0 0 1}
p text "sourceforge.net/p/pdf4tcl"    -x 182 -y $y
incr y 20

p text "Thick red border:"     -x 50  -y $y
p hyperlinkAdd 180 [expr {$y-10}] 195 14 "https://sourceforge.net/p/pdf4tcl" \
    -borderwidth 3 -bordercolor {0.8 0 0}
p text "sourceforge.net/p/pdf4tcl"    -x 182 -y $y
incr y 20

p text "Dashed green border:"  -x 50  -y $y
p hyperlinkAdd 180 [expr {$y-10}] 195 14 "https://github.com/gregnix/pdf4tcl" \
    -borderwidth 1 -bordercolor {0 0.6 0} -borderdash {5 3}
p text "github.com/gregnix/pdf4tcl"    -x 182 -y $y
incr y 20

p text "Rounded corners:"      -x 50  -y $y
p hyperlinkAdd 180 [expr {$y-10}] 195 14 "https://github.com/gregnix/pdf4tcl" \
    -borderwidth 1 -bordercolor {0.5 0 0.5} -borderradius 5
p text "github.com/gregnix/pdf4tcl"    -x 182 -y $y
incr y 30

separator p $y
incr y 8
set y [sectionHeader p "10. Metadata (set at document creation)" $y]

p setFont 10 Helvetica
foreach {field value} {
    Title    "pdf4tcl Feature Overview"
    Author   "pdf4tcl fork"
    Subject  "Demonstration of all pdf4tcl capabilities"
    Keywords "tcl,pdf,pdf4tcl,demo"
    Creator  "demo-all.tcl"
} {
    p setFont 10 Helvetica-Bold
    p text "${field}:" -x 50 -y $y
    p setFont 10 Helvetica
    p text $value -x 160 -y $y
    incr y 16
}

incr y 8
separator p $y
incr y 8
set y [sectionHeader p "11. Bookmarks (visible in PDF reader sidebar)" $y]
p setFont 10 Helvetica
p text "This document has 5 bookmarks -- one per page." -x 50 -y $y
incr y 16
p text "Open the bookmarks panel in your PDF reader to see them." -x 50 -y $y

# ==================================================================
# Footer on every page: version + file info
# ==================================================================
# (Already printed on page 1 title bar; add a small footer to pages 2-5)
p write -file $outfile
p destroy

puts "Written: $outfile"
puts "Package: pdf4tcl $pkgver"
puts "File:    $pkgfile"
