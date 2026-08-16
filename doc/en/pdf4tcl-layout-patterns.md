# pdf4tcl Layout Patterns

This document covers reusable layout patterns, a helper library, and
professional page design. It shows how to structure pdf4tcl code so that
it stays organized and maintainable.

## The Problem

pdf4tcl is intentionally kept low-level. Recurring tasks such as margin
calculations, centering on the page, and page numbers require the same
boilerplate over and over:

```tcl
# Repeated everywhere: convert mm to pt
set x_pt [expr {20.0 / 25.4 * 72.0}]

# Repeated everywhere: calculate margins
set margin_pt [expr {20.0 / 25.4 * 72.0}]
set sx $margin_pt
set ex [expr {595.276 - $margin_pt}]
```

The solution is helper functions and the Page Context Pattern.

## Page Context Pattern

### Central Layout Dictionary

The most important pattern: a dictionary that holds all layout information.

```tcl
proc create_page_context {paper margin_mm orient} {
    array set sizes {
        a4     {595.276 841.890}
        letter {612 792}
        a3     {842 1191}
        a5     {420 595}
    }

    lassign $sizes($paper) pw ph

    set margin_pt [expr {$margin_mm * 72.0 / 25.4}]

    set sx $margin_pt
    set sy $margin_pt
    set sw [expr {$pw - 2 * $margin_pt}]
    set sh [expr {$ph - 2 * $margin_pt}]

    return [dict create \
        PW $pw \
        PH $ph \
        margin_pt $margin_pt \
        SX $sx \
        SY $sy \
        SW $sw \
        SH $sh \
        orient $orient]
}
```

### Usage

```tcl
set ctx [create_page_context a4 20 true]

set sx [dict get $ctx SX]    ;# safe X (left margin)
set sy [dict get $ctx SY]    ;# safe Y (top margin)
set sw [dict get $ctx SW]    ;# safe width (usable width)
set sh [dict get $ctx SH]    ;# safe height (usable height)

# Text within the safe area
$pdf text "In the safe area" -x $sx -y $sy
```

Advantage: no magic numbers in the code. All dimensions defined in one place.

## Helper Functions

### Unit Conversion

```tcl
proc mm {mm} {
    return [expr {$mm / 25.4 * 72.0}]
}

proc cm {cm} {
    return [expr {$cm / 2.54 * 72.0}]
}
```

### Centered Text

```tcl
proc center_text {pdf ctx text y} {
    set centerX [expr {[dict get $ctx PW] / 2.0}]
    $pdf text $text -x $centerX -y $y -align center
}
```

### Page Number

```tcl
proc add_page_number {pdf ctx pagenum {total ""}} {
    set centerX [expr {[dict get $ctx PW] / 2.0}]
    set bottomY [expr {[dict get $ctx PH] - 25}]
    $pdf setFont 9 Helvetica
    if {$total ne ""} {
        $pdf text "Page $pagenum of $total" \
            -x $centerX -y $bottomY -align center
    } else {
        $pdf text "Page $pagenum" \
            -x $centerX -y $bottomY -align center
    }
}
```

### Horizontal Rule

```tcl
proc draw_hr {pdf ctx y {color {0.6 0.6 0.6}}} {
    lassign $color r g b
    set sx [dict get $ctx SX]
    set sw [dict get $ctx SW]
    $pdf setStrokeColor $r $g $b
    $pdf setLineWidth 0.5
    $pdf line $sx $y [expr {$sx + $sw}] $y
    $pdf setStrokeColor 0 0 0
}
```

### Debug Grid

```tcl
proc draw_grid {pdf ctx {step 50}} {
    set pw [dict get $ctx PW]
    set ph [dict get $ctx PH]

    $pdf setStrokeColor 0.9 0.9 0.9
    $pdf setLineWidth 0.25

    # Vertical lines
    for {set x 0} {$x <= $pw} {incr x $step} {
        $pdf line $x 0 $x $ph
    }

    # Horizontal lines
    for {set y 0} {$y <= $ph} {incr y $step} {
        $pdf line 0 $y $pw $y
    }

    # Labels
    $pdf setFont 6 Helvetica
    $pdf setFillColor 0.7 0.7 0.7
    for {set x 0} {$x <= $pw} {incr x $step} {
        $pdf text $x -x $x -y 8
    }
    for {set y $step} {$y <= $ph} {incr y $step} {
        $pdf text $y -x 2 -y $y
    }

    $pdf setFillColor 0 0 0
    $pdf setStrokeColor 0 0 0
}
```

## Column Layouts

### Two Columns

```tcl
proc two_columns {pdf ctx leftText rightText y {gap 20}} {
    set sx [dict get $ctx SX]
    set sw [dict get $ctx SW]
    set colW [expr {($sw - $gap) / 2.0}]

    set leftX $sx
    set rightX [expr {$sx + $colW + $gap}]

    $pdf drawTextBox $leftX $y $colW 500 $leftText -align left
    $pdf drawTextBox $rightX $y $colW 500 $rightText -align left
}
```

### Three Columns

```tcl
proc three_columns {pdf ctx texts y {gap 15}} {
    set sx [dict get $ctx SX]
    set sw [dict get $ctx SW]
    set colW [expr {($sw - 2 * $gap) / 3.0}]

    for {set i 0} {$i < 3} {incr i} {
        set x [expr {$sx + $i * ($colW + $gap)}]
        $pdf drawTextBox $x $y $colW 500 [lindex $texts $i] -align left
    }
}
```

## Headers and Footers

### Header Function

```tcl
proc draw_header {pdf ctx title {subtitle ""}} {
    set sx [dict get $ctx SX]
    set sy [dict get $ctx SY]
    set sw [dict get $ctx SW]

    $pdf setFont 14 Helvetica-Bold
    $pdf text $title -x $sx -y $sy

    if {$subtitle ne ""} {
        $pdf setFont 10 Helvetica
        $pdf setFillColor 0.4 0.4 0.4
        $pdf text $subtitle -x $sx -y [expr {$sy + 18}]
        $pdf setFillColor 0 0 0
    }

    # Rule
    set lineY [expr {$sy + 25}]
    draw_hr $pdf $ctx $lineY

    return [expr {$lineY + 15}]
}
```

### Footer Function

```tcl
proc draw_footer {pdf ctx pagenum {text ""}} {
    set sx [dict get $ctx SX]
    set sw [dict get $ctx SW]
    set ph [dict get $ctx PH]

    set footerY [expr {$ph - 35}]

    # Rule
    draw_hr $pdf $ctx $footerY

    $pdf setFont 8 Helvetica
    set textY [expr {$footerY + 10}]

    if {$text ne ""} {
        $pdf text $text -x $sx -y $textY
    }

    # Page number right-aligned
    $pdf text "Page $pagenum" \
        -x [expr {$sx + $sw}] -y $textY -align right
}
```

## Page Break Management

### Manual Page Break

```tcl
proc check_page_break {pdf ctx y_var lineHeight pagenum_var} {
    upvar $y_var y
    upvar $pagenum_var pagenum

    set maxY [expr {[dict get $ctx PH] - [dict get $ctx margin_pt] - 40}]

    if {($y + $lineHeight) > $maxY} {
        draw_footer $pdf $ctx $pagenum
        $pdf endPage

        incr pagenum
        $pdf startPage

        set startY [draw_header $pdf $ctx "Continued"]
        set y $startY
    }
}
```

### Usage

```tcl
set ctx [create_page_context a4 20 true]
set pdf [::pdf4tcl::new %AUTO% -paper a4 -orient true -compress 1]

$pdf startPage
set pagenum 1
set y [draw_header $pdf $ctx "My Document"]

$pdf setFont 12 Times-Roman
set lineHeight 16

foreach line $data {
    check_page_break $pdf $ctx y $lineHeight pagenum
    $pdf text $line -x [dict get $ctx SX] -y $y
    incr y $lineHeight
}

draw_footer $pdf $ctx $pagenum
$pdf endPage
$pdf write -file document.pdf
$pdf destroy
```

## Complete Example: Report Template

```tcl
#!/usr/bin/env tclsh
package require pdf4tcl 0.9

# Load helper functions (defined above)
# source helpers/pdf4tcl_helpers.tcl

set ctx [create_page_context a4 20 true]
set pdf [::pdf4tcl::new %AUTO% -paper a4 -orient true -compress 1]

# Title page
$pdf startPage
$pdf setFont 28 Helvetica-Bold
center_text $pdf $ctx "Annual Report 2025" 200
$pdf setFont 16 Helvetica
$pdf setFillColor 0.4 0.4 0.4
center_text $pdf $ctx "Development Department" 240
$pdf setFillColor 0 0 0
$pdf setFont 12 Helvetica
center_text $pdf $ctx "As of: October 2025" 280
$pdf endPage

# Content pages
set pagenum 1
$pdf startPage
set y [draw_header $pdf $ctx "Summary"]

$pdf setFont 12 Times-Roman
set lineHeight 16
set sx [dict get $ctx SX]
set sw [dict get $ctx SW]

set paragraphs {
    "The following report summarizes the key results."
    "Three new projects were launched in the first quarter."
    "Customer satisfaction rose 15 percent compared to the previous year."
}

foreach para $paragraphs {
    check_page_break $pdf $ctx y $lineHeight pagenum
    $pdf drawTextBox $sx $y $sw 100 $para -align justify \
        -linesvar numLines
    incr y [expr {int($numLines * $lineHeight + 10)}]
}

draw_footer $pdf $ctx $pagenum
$pdf endPage
$pdf write -file report-2025.pdf
$pdf destroy
```

## Architecture Note

pdf4tcl is intentionally designed as a PDF primitive layer. It provides
no built-in tables, automatic page breaks, or layout engines. That
functionality belongs in helper libraries and abstraction layers such as
pdfdoclib, pdfgrid, or pdftextboxlib.

| Layer             | Responsibility                           |
|-------------------|------------------------------------------|
| pdf4tcl (core)    | PDF primitives: text, lines, images      |
| Helper library    | Conversions, page context, utilities     |
| pdfdoclib         | Document abstraction, styles, layouts    |
| pdfgrid           | Tables with totals and formatting        |
| pdftextboxlib     | Extended TextBox with options            |

## Embedded Files (0.9.4.14)

`addEmbeddedFile` embeds a file invisibly in the PDF — without any visible
page annotation. The file is accessible via the PDF catalog under
`/Names /EmbeddedFiles`.

Main use case: ZUGFeRD/Factur-X invoices, where an XML file must be
delivered together with the PDF.

```tcl
# Simple embedding
$pdf addEmbeddedFile "invoice.xml" \
    [file join $scriptDir invoice.xml]

# With metadata
$pdf addEmbeddedFile "ZUGFeRD-invoice.xml" \
    [file join $scriptDir zugferd.xml] \
    -mimetype    "application/xml" \
    -description "ZUGFeRD 2.1 invoice" \
    -afrelationship "Alternative"
```

Options:

| Option | Default | Description |
|--------|---------|-------------|
| `-contents` | file contents | Alternative file content as string |
| `-mimetype` | `application/octet-stream` | MIME type |
| `-description` | `""` | File description |
| `-afrelationship` | `Unspecified` | `Alternative Data Source Supplement Unspecified` |

Restriction: with `-pdfa 1b`, `addEmbeddedFile` is not permitted
(ISO 19005-1 §6.1.7). With PDF/A-3 (`-pdfa 3b`) it is explicitly supported.


## Continuing below a text box (0.9.4.23)

`drawTextBox` wraps text into a rectangle. A caller usually needs to know
where the text actually ended -- a paragraph of unknown length cannot be
followed by a heading at a fixed position.

Two things help:

* the **return value** is the unused remainder of the string, empty when
  everything fitted. Checking it is how a multi-page flow is built: draw,
  take the remainder, start a new page, draw the rest.
* **`-linesvar`** names a variable receiving the number of lines written.

```tcl
set rest [$pdf drawTextBox 0 $y $w 200 $text -linesvar lines]
while {$rest ne ""} {
    $pdf startPage
    set rest [$pdf drawTextBox 0 0 $w 700 $rest]
}
```

### -newyvar needs care

`-newyvar` names a variable receiving the Y position after the last rendered
line. Measured with a three line paragraph, comparing the variable against
the baselines actually written into the content stream:

| `-orient` | baselines in the PDF | `-newyvar` |
|---|---|---|
| `1` | 793.475, 782.475, **771.475** | **771.475** |
| `0` | 91.475, 80.475, **69.475** | **69.475** |

The value is the last baseline in **PDF page coordinates**, counted from the
bottom left of the sheet, in both orient modes. It is *not* in the user
coordinate system that `drawTextBox` took its `y` from.

Feeding it straight back into a drawing call therefore misplaces the result.
Measured with `-orient 1`, margin 40, a box drawn at user `y 0`:

```tcl
$pdf drawTextBox 0 0 200 60 $text -newyvar ny   ;# ny = 771.475
$pdf line 0 $ny 200 $ny                          ;# lands at PDF y 30.525
```

The text ends at PDF y 771.475 and the line is drawn 741 points away from it.
Convert before using the value, or work out the position from `-linesvar` and
the line height (`getLineSpacing`) instead, which stays in the coordinate
system you started in.

## Bookmarks (document outline)

`bookmarkAdd` adds an entry to the outline pane that viewers show beside the
page. It always refers to the **current page**, so it belongs right after
`startPage`:

```tcl
$pdf startPage
$pdf bookmarkAdd -title "Chapter 1" -level 0
...
$pdf startPage
$pdf bookmarkAdd -title "Chapter 2" -level 0
$pdf bookmarkAdd -title "Section 2.1" -level 1
```

`-level` builds the hierarchy: a higher level nests under the preceding entry
of the level above. `-closed 1` starts a branch collapsed.

Verified in the output: three calls across two pages produce an `/Outlines`
dictionary in the catalog.

The title goes through `QuoteString`, so codepoints above U+00FF are
transliterated where possible and replaced with `?` otherwise -- see the
substitution section in `pdf4tcl-text-and-fonts.md`. For a document with
non-Latin headings, check what actually arrived in the outline.

Bookmarks are navigation, not structure. They do not make a document
accessible; that is what tagging does, see `TAGGED.md`.

## Reusable content with XObjects

A logo that appears on fifty pages should be described once. `startXObject`
opens a drawing context that behaves like a page and returns an id;
`putImage` then places it as often as needed:

```tcl
set logo [$pdf startXObject -paper {60p 30p}]
$pdf setFillColor 0.2 0.3 0.8
$pdf rectangle 0 0 60 30 -filled 1
$pdf setFillColor 1 1 1
$pdf setFont 10 Helvetica
$pdf text "LOGO" -x 12 -y 20
$pdf endXObject

$pdf startPage
$pdf putImage $logo 0 0
$pdf putImage $logo 200 0 -width 120
```

Everything that works on a page works here: text, shapes, colours, images.
The default paper is `{100p 100p}` with no margin, so give `-paper` the size
you actually want to draw in. Scaling at placement time works exactly as for
images, `-width` alone preserving the aspect ratio.

### The empty page trap

An XObject has to be created *between* pages, and any drawing command issued
while no page is open silently opens one. Measured:

```tcl
set id [$pdf startXObject -paper {60p 30p}]
$pdf rectangle 0 0 60 30 -filled 1
$pdf endXObject
$pdf setFillColor 0 0 0          ;# <- outside any page
$pdf startPage
```

| variant | pages in the result |
|---|---|
| without the `setFillColor` line | 1 |
| with it | **2**, the first one empty |

Nothing is reported; the document simply gains a blank sheet. Reset colours
and fonts *after* `startPage`, not between `endXObject` and it.
