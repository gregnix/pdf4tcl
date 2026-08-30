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

A soft hyphen (U+00AD) does not count towards the width — see *Where a
Line May Break* below. Measured with Helvetica 10, `Sil<AD>ben` and
`Silben` are both 27.79 pt. Anyone wrapping text themselves and
measuring with `getStringWidth` would otherwise be given the width of a
hyphen nobody sees.

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
pdf4tcl does not support for standard fonts. Which route to take --
standard font, 256-character subset or full CID font -- is compared with
measured file sizes in
[`pdf4tcl-fonts-and-unicode.md`](pdf4tcl-fonts-and-unicode.md).

The substitution is counted by `getSubstCount`, but only under Tcl 9:

```
Tcl 9.0.4    encoding convertto cp1252 "<Greek>"  ->  error, pdf4tcl counts
Tcl 8.6.14   the same call                        ->  "??????", no error
```

Both write `??????` onto the page. On 8.6 the counter stays at zero, so it
cannot be used as a safety net there.

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

### Where a Line May Break

A **soft hyphen**, U+00AD, is a suggestion, not a character. Since
0.9.4.61 `drawTextBox` prints it only where the line actually breaks,
and then as a hyphen; everywhere else it leaves no trace and adds
nothing to the width. A text full of suggestions therefore wraps exactly
like the same text without them.

```tcl
set wort "Silben\u00ADtrennung"
$pdf drawTextBox 50 100 200 300 $wort
```

The hyphen added at a break is counted against the box while a soft
break is pending, so the line does not stick out by its width.

Up to 0.9.4.60 the character was printed wherever it stood and did not
break: `Silben<AD>trennung` came out as one word with a stray hyphen in
the middle.

**The same rule holds in three places, and that is the point.**
`getStringWidth` does not count it, and `text` does not print it —
`text` does not wrap at all, so there is no position at which the
character could legitimately become visible. Whoever wants a dash writes
U+002D. `tests/consistency.test` checks that the three agree.

A **hard hyphen** between two characters still breaks and stays, and a
sign before a number does not break — that rule is from 0.9.4.60 and is
unchanged.

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

## Characters that do not fit the encoding (0.9.4.35)

A base-14 font such as Helvetica can only carry Latin-1. Drawing text that
does not fit does not raise an error -- the PDF stays valid, the text does
not. pdf4tcl handles it in two steps.

**Transliteration first.** Codepoints above U+00FF are replaced by an ASCII
equivalent where one makes sense. `::pdf4tcl::asciiMap` holds 31 such pairs:
dashes, quotation marks, ellipsis, arrows, comparison signs, euro,
trademark. Measured:

```tcl
% ::pdf4tcl::QuoteString "Zitat \u201Ctest\u201D \u2014 Ende \u2192 x"
(Zitat "test" - Ende -> x)
```

The typography is lost, the meaning survives. Nothing is reported, because
nothing was lost that a reader would miss.

**Replacement second.** Anything without an equivalent becomes `?` (or
`.notdef` in a subset without `?`). This *is* a loss, and `getSubstCount`
reports it:

```tcl
$pdf setFont 12 Helvetica
$pdf text "Hallo \u4F60\u597D Welt" -x 50 -y 50
$pdf endPage
puts [$pdf getSubstCount]      ;# 2
```

The counter runs per document and starts at zero. A non-zero value almost
always means Unicode text was drawn with a Latin-1 base font; a CID font
(see `pdf4tcl-cidfont-manual.md`) is the cure, not a different encoding.

### The catch under Tcl 8.6

Measured with the same script on both runtimes:

| | `getSubstCount` |
|---|---|
| Tcl 9.0.4 | 2 |
| Tcl 8.6.14 | **0** |

Under Tcl 8.6, `encoding convertto` performs its own silent replacement and
returns without an error, so pdf4tcl never learns that a character was lost.
The characters are gone in both cases; only the reporting differs. This is a
property of the Tcl release, not of pdf4tcl.

So under Tcl 8.6 a zero counter proves nothing. If a document may contain
text from outside your control, either use a CID font from the start, or
check the count under Tcl 9 during development.

### Control characters

Control characters would break the PDF string syntax and are dropped. Unlike
transliteration this is reported, once per document, in
`::pdf4tcl::warnings`:

```tcl
set ::pdf4tcl::warnings {}
::pdf4tcl::QuoteString "a\u0001b"        ;# -> (ab)
puts $::pdf4tcl::warnings
;# quoteString: control character in a PDF string was replaced
;# (further occurrences are not reported)
```

Worth checking after generating a document from data you did not write
yourself.

## The text cursor

`text` with `-x` and `-y` places a string at an absolute position. For
running text there is a cursor instead, which saves computing every line
position by hand:

```tcl
$pdf setFont 12 Helvetica
$pdf setTextPosition 0 20
$pdf text "Line 1"
$pdf newLine
$pdf text "Line 2"
```

`newLine` moves down by one line height and back to the left edge of the
text block. Measured with 12 point Helvetica, starting at `0 20`:

| after | `getTextPosition` |
|---|---|
| `text "Line 1"` | `36.012 32.0` |
| `newLine` + `text "Line 2"` | -- |
| `setLineSpacing 1.5`, `newLine`, `text` | `71.352 50.0` |

Note what `getTextPosition` returns: the position *after* the last string,
so the x value has advanced by the text width. It is the pen position, not
the start of the line.

`getLineHeight` returns the current line height -- 12.0 for a 12 point font
at the default spacing of 1.0. `setLineSpacing` multiplies it: after
`setLineSpacing 1.5` the step from line to line grew from 12 to 18 points
(32.0 to 50.0 in the measurement above).

`moveTextPosition` shifts the cursor relative to where it is, which is how
an indent or a hanging label is done without recomputing absolute
coordinates.

For font metrics beyond the line height, `getFontMetric` answers with the
values of the current font; `ascend` gave 8.616 for 12 point Helvetica.
