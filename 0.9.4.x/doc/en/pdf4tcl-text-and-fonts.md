# pdf4tcl Text and Fonts

This document covers the text API, the 14 standard PDF fonts, and encoding
in pdf4tcl. After reading it you will be able to position, align, and
format text reliably.

## Writing Text

### Basic Text Output

```tcl
$pdf setFont 12 Helvetica
$pdf text "Hello World" -x 50 -y 100
```

The font stays active until the next `setFont` call. The Y position
refers to the text baseline, not the top edge of the glyphs.

### The Baseline

The Y position given to `$pdf text` is always the baseline. Characters
like "g", "y", or "p" extend below the baseline (descenders). Characters
like "A" or "h" extend above it (ascenders).

```
     "Hello World"
Y=100 ----------------  <-- baseline (where Y points)
          g  y           <-- descenders below baseline
```

Consequence: the Y position must be at least as large as the font size
for the text to be fully visible.

```tcl
# WRONG - text will be clipped
$pdf setFont 18 Helvetica
$pdf text "Test" -x 50 -y 0

# CORRECT - minimum Y value equals font size
$pdf setFont 18 Helvetica
$pdf text "Test" -x 50 -y 20
```

### Text Alignment

```tcl
# Left (default)
$pdf text "Left" -x 50 -y 100

# Centered
$pdf text "Centered" -x 297 -y 100 -align center

# Right
$pdf text "Right" -x 545 -y 100 -align right
```

With `-align center` the X position is the center of the text.
With `-align right` the X position is the right end.

### Calculating Text Width

```tcl
$pdf setFont 12 Helvetica
set width [$pdf getStringWidth "Sample text"]
# --> width in points
```

The text width depends on the currently active font and size. It is needed
for manual centering, tables, and layout calculations.

### Line Height and Spacing

```tcl
set fontSize 12
set lineHeight [expr {$fontSize * 1.4}]  ;# 140% of font size

# Multiple lines
for {set i 0} {$i < 10} {incr i} {
    set y [expr {50 + $i * $lineHeight}]
    $pdf text "Line $i" -x 50 -y $y
}
```

The rule of thumb for line height is 120% to 150% of the font size.
For 12 pt text that gives approximately 14 to 18 pt line spacing.

## The 14 Standard Fonts

PDF defines 14 standard fonts that are present in every PDF viewer.
These fonts are not embedded in the PDF, which guarantees small file
sizes and universal availability.

### Helvetica (Sans-Serif)

| Font Name             | Usage                       |
|-----------------------|-----------------------------|
| Helvetica             | Body text, forms            |
| Helvetica-Bold        | Headings                    |
| Helvetica-Oblique     | Emphasis                    |
| Helvetica-BoldOblique | Strong emphasis             |

Note: Helvetica uses `-Oblique`, not `-Italic`.

```tcl
$pdf setFont 12 Helvetica
$pdf setFont 12 Helvetica-Bold
$pdf setFont 12 Helvetica-Oblique
$pdf setFont 12 Helvetica-BoldOblique
```

### Times (Serif)

| Font Name          | Usage                       |
|--------------------|-----------------------------|
| Times-Roman        | Formal documents            |
| Times-Bold         | Headings                    |
| Times-Italic       | Emphasis                    |
| Times-BoldItalic   | Strong emphasis             |

Note: Times uses `-Italic`, not `-Oblique`.

```tcl
$pdf setFont 12 Times-Roman
$pdf setFont 12 Times-Bold
$pdf setFont 12 Times-Italic
$pdf setFont 12 Times-BoldItalic
```

### Courier (Monospace)

| Font Name            | Usage                       |
|----------------------|-----------------------------|
| Courier              | Code, tables                |
| Courier-Bold         | Highlighted code            |
| Courier-Oblique      | Italic code                 |
| Courier-BoldOblique  | Bold italic code            |

```tcl
$pdf setFont 10 Courier
$pdf setFont 10 Courier-Bold
$pdf setFont 10 Courier-Oblique
$pdf setFont 10 Courier-BoldOblique
```

### Special Fonts

| Font Name    | Usage                   |
|--------------|-------------------------|
| Symbol       | Greek characters        |
| ZapfDingbats | Special symbols         |

### Common Font Name Errors

```tcl
# WRONG - these names do not exist
$pdf setFont 12 Helvetica-Italic     ;# it's Oblique!
$pdf setFont 12 Times-Oblique        ;# it's Italic!
$pdf setFont 12 helvetica            ;# case-sensitive!
$pdf setFont 12 "Helvetica Bold"     ;# no space!

# CORRECT
$pdf setFont 12 Helvetica-Oblique
$pdf setFont 12 Times-Italic
$pdf setFont 12 Helvetica
$pdf setFont 12 Helvetica-Bold
```

## Encoding

### WinAnsi / CP1252

The standard fonts support WinAnsi/CP1252. This covers Western European
characters including German umlauts (ae, oe, ue, ss), French accents,
and Scandinavian characters.

From version 0.9.4.9, standard fonts automatically include a ToUnicode
CMap stream. This enables correct text extraction and copy-paste from
PDF viewers (previously: only question marks when copying special characters).

```tcl
# Works (WinAnsi)
$pdf text "Greetings from Munich" -x 50 -y 100
$pdf text "Cafe, Noel, Resume" -x 50 -y 120

# Does NOT work (outside WinAnsi)
$pdf text "Chinese characters" -x 50 -y 140    ;# question marks only
```

### Avoiding Unicode Problems

Characters outside WinAnsi/CP1252 are not rendered correctly.
For full Unicode support, TrueType fonts must be embedded, which
pdf4tcl does not support for standard fonts.

Typical problematic characters and their substitutes:

| Character    | Description       | Substitute |
|--------------|-------------------|------------|
| Box drawing  | Table borders     | `+ - \|`   |
| Check mark   | Checkboxes        | `[x] [ ]`  |
| Bullet       | List marker       | `*`        |
| Ellipsis     | Omission          | `...`      |

```tcl
# Sanitization function for standard fonts
proc sanitize_for_pdf {text} {
    set map {
        "\u2502" "|"   "\u2500" "-"   "\u253C" "+"
        "\u2611" "[x]" "\u2610" "[ ]"
        "\u2022" "*"   "\u2026" "..."
    }
    return [string map $map $text]
}
```

## TextBox (Text Block with Word Wrap)

### drawTextBox

For longer texts with automatic line wrapping:

```tcl
$pdf setFont 12 Helvetica
$pdf drawTextBox 50 100 200 300 "This is a longer text that \
    wraps automatically when it exceeds the width \
    of the text box." -align left
```

Parameters: X position, Y position, width, height, text.

### Alignment Options

```tcl
# Left-aligned (default)
$pdf drawTextBox 50 100 200 300 $text -align left

# Centered
$pdf drawTextBox 50 100 200 300 $text -align center

# Right-aligned
$pdf drawTextBox 50 100 200 300 $text -align right

# Justified
$pdf drawTextBox 50 100 200 300 $text -align justify
```

### Retrieving Line Count

```tcl
$pdf drawTextBox 50 100 200 300 $text -linesvar numLines
puts "Number of lines: $numLines"
```

### Dry Run

```tcl
# Calculate only, do not draw
$pdf drawTextBox 50 100 200 300 $text \
    -linesvar numLines -dryrun 1

# Calculate required height
set requiredHeight [expr {$numLines * $lineHeight}]
```

## Practical Tips

### Heading Hierarchy

```tcl
proc setHeadingFont {pdf level} {
    set sizes {24 20 16 14 12 11}
    set size [lindex $sizes [expr {$level - 1}]]
    $pdf setFont $size Helvetica-Bold
}

proc setBodyFont {pdf} {
    $pdf setFont 11 Times-Roman
}
```

### Drawing a Page Number

```tcl
proc drawPageNumber {pdf pagenum ctx} {
    set centerX [expr {[dict get $ctx PW] / 2.0}]
    set bottomY [expr {[dict get $ctx PH] - 30}]
    $pdf setFont 10 Helvetica
    $pdf text "Page $pagenum" -x $centerX -y $bottomY -align center
}
```

### Positioning Text in Table Cells

Baseline positioning requires special attention in table cells. Naive
centering places the text too high.

```tcl
# WRONG - text overflows the cell border at the top
set textY [expr {$y0 + int(($cellH - $fontSize) / 2.0)}]

# CORRECT - baseline set low enough
set textY [expr {$y0 + int(($cellH - $fontSize) / 0.45)}]
```

The ascent (height above baseline) for Helvetica is approximately 70–80%
of the fontSize. Dividing by 2.0 places the baseline too close to the
top of the cell.

## ToUnicode for Standard Fonts (0.9.4.13)

From 0.9.4.13, pdf4tcl automatically generates a ToUnicode CMap stream for
all 14 standard fonts (Helvetica, Times, Courier, and their variants) with
the complete WinAnsi/CP1252 encoding.

**Note:** This is a pdf4tcl feature — the PDF standard does not require
ToUnicode CMaps for standard fonts. Without this entry, copy-paste of
special characters fails in many viewers, and veraPDF reports error 6.3.9
in PDF/A mode.

For applications that use only standard fonts and 7-bit ASCII, no change
is required. The difference becomes apparent when copying text containing
umlauts or special characters from a PDF viewer.

## OTF/CFF Fonts in CIDFont Context (0.9.4.15)

From 0.9.4.15, `loadBaseTrueTypeFont` also accepts OpenType fonts with CFF
outlines (`.otf` files, magic `OTTO`). Previously such fonts produced the
error `TTF: postscript outlines are not supported`.

```tcl
# TTF (TrueType outlines) -- always supported
$pdf loadBaseTrueTypeFont "DejaVuSans" \
    /usr/share/fonts/truetype/dejavu/DejaVuSans.ttf

# OTF (CFF/PostScript outlines) -- new in 0.9.4.15
$pdf loadBaseTrueTypeFont "NotoSans" \
    /usr/share/fonts/opentype/noto/NotoSans-Regular.otf
```

Both types are fully embedded. In the PDF object model, an OTF font
produces `/CIDFontType0` (instead of `/CIDFontType2` for TTF) and uses
`/FontFile3 /Subtype /OpenType` for the embedded font binary.

The remaining CIDFont API (`createFontSpecCID`, glyph widths, text output,
`getStringWidth`) works identically for TTF and OTF.
