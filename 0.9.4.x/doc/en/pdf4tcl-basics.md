# pdf4tcl Basics

This document covers installation, the coordinate system, units, and first
steps with pdf4tcl. It is aimed at developers already familiar with Tcl/Tk
who want to generate PDF documents.

## Installation

### Requirements

pdf4tcl requires Tcl/Tk 8.6 or Tcl 9.0. The recommended version of pdf4tcl
is 0.9.4.19. The following tools can optionally be installed:

- poppler-utils: `pdfinfo` and `pdftotext` for PDF validation
- mupdf: lightweight PDF viewer
- ghostscript: for PDF/A conversion
- tcl-sha: fast SHA-384/512 implementation for AES-256 (optional)

### Installation via Package Manager

```bash
# Debian/Ubuntu
sudo apt-get install tcllib

# Fedora
sudo dnf install tcllib

# macOS
brew install tcllib
```

### Local Installation (project-specific)

```tcl
#!/usr/bin/env tclsh

# Load local version
lappend auto_path [file join [file dirname [info script]] pdf4tcl094]
package require pdf4tcl 0.9
```

### System-wide Installation

```bash
mkdir -p ~/.local/lib/tcl8.6/pdf4tcl0.9

cp pdf4tcl.tcl ~/.local/lib/tcl8.6/pdf4tcl0.9/
echo "package ifneeded pdf4tcl 0.9 [list source [file join \$dir pdf4tcl.tcl]]" \
    > ~/.local/lib/tcl8.6/pdf4tcl0.9/pkgIndex.tcl
```

### Verifying the Installation

```tcl
#!/usr/bin/env tclsh

if {[catch {package require pdf4tcl 0.9} err]} {
    puts "ERROR: pdf4tcl not found - $err"
    exit 1
}

puts "pdf4tcl version: [package require pdf4tcl]"

set pdf [::pdf4tcl::new %AUTO% -paper a4 -orient true]
$pdf startPage
$pdf setFont 18 Helvetica-Bold
$pdf text "Installation successful!" -x 50 -y 50
$pdf endPage

set outfile "test-installation.pdf"
$pdf write -file $outfile
$pdf destroy

puts "Test PDF created: $outfile"
```

## Coordinate System

The coordinate system is the most common source of errors for beginners.
pdf4tcl supports two modes, controlled by the `-orient` option.

### Mode 1: orient true (recommended)

The origin (0,0) is at the top left. Y increases downward, X to the right.
This matches the behavior of Tk Canvas and HTML.

```
(0,0) ---------------------> X
  |
  |    Document
  |
  v
  Y
```

```tcl
set pdf [pdf4tcl::pdf4tcl create %AUTO% -paper a4 -orient true]
$pdf startPage

# Text near the top
$pdf text "Top" -x 50 -y 50      ;# Y=50 --> near the top edge

# Text near the bottom
$pdf text "Bottom" -x 50 -y 800  ;# Y=800 --> near the bottom edge

$pdf endPage
```

### Mode 2: orient false (mathematical)

The origin (0,0) is at the bottom left. Y increases upward.
This matches the Cartesian coordinate system.

```
  Y
  ^
  |
  |    Document
  |
(0,0) ---------------------> X
```

```tcl
set pdf [pdf4tcl::pdf4tcl create %AUTO% -paper a4 -orient false]
$pdf startPage

# Text near the bottom
$pdf text "Bottom" -x 50 -y 50   ;# Y=50 --> near the bottom edge

# Text near the top
$pdf text "Top" -x 50 -y 800     ;# Y=800 --> near the top edge

$pdf endPage
```

### Recommendation

Always set `-orient` explicitly. The default value is `1` (orient true),
but this is not obvious. Code that assumes the default may behave
incorrectly after version upgrades.

```tcl
# CORRECT - always explicit
set pdf [::pdf4tcl::new %AUTO% -paper a4 -orient true]

# INCORRECT - depends on default
set pdf [::pdf4tcl::new %AUTO% -paper a4]
```

### drawTextBox and orient

The `y` argument of `drawTextBox` depends on the orient mode:

- With `-orient true`: `y` is the **top edge** of the box (text fills downward)
- With `-orient false`: `y` is the **bottom edge** of the box (text fills upward)

```tcl
# orient true (recommended): y = top edge
set pdf [::pdf4tcl::new %AUTO% -paper a4 -orient true]
$pdf startPage
$pdf setFont 11 Helvetica
$pdf text "Heading" -x 50 -y 100
$pdf drawTextBox 50 120 400 60 "This text starts at y=120." -align left

# orient false: y = bottom edge -- box fills from y upward to y+height
set pdf [::pdf4tcl::new %AUTO% -paper a4 -orient false]
$pdf startPage
$pdf setFont 11 Helvetica
$pdf text "Heading" -x 50 -y 700
# Top edge = 680, bottom edge = 620, height 60
$pdf drawTextBox 50 620 400 60 "Text between 620 and 680." -align left
```

Rule of thumb: with `-orient false` and fixed y values, always allow
sufficient distance between labels and the box's y position.

### setFont and -unit

`setFont size fontname` interprets `size` in the configured unit, not
always in points:

```tcl
# -unit mm: setFont 9 = 9 mm = approx. 25.5 pt -- far too large!
set pdf [::pdf4tcl::new %AUTO% -paper a4 -orient true -unit mm]
$pdf setFont 9 Helvetica     ;# WRONG: 9 mm font

# Correct 1: specify points explicitly
$pdf setFont 9p Helvetica    ;# CORRECT: 9 pt

# Correct 2: no -unit, everything in points
set pdf [::pdf4tcl::new %AUTO% -paper a4 -orient true]
$pdf setFont 9 Helvetica     ;# CORRECT: 9 pt
```

## Units

### Points as the Base Unit

pdf4tcl works internally in points (pt). One point equals 1/72 inch.
Conversion factors:

| From    | To   | Factor |
|---------|------|--------|
| 1 inch  | pt   | 72     |
| 1 mm    | pt   | 2.8346 |
| 1 pt    | mm   | 0.3528 |
| 1 cm    | pt   | 28.346 |

### Conversion Functions

```tcl
proc mm_to_pt {mm} {
    return [expr {$mm / 25.4 * 72.0}]
}

proc cm_to_pt {cm} {
    return [expr {$cm / 2.54 * 72.0}]
}

proc pt_to_mm {pt} {
    return [expr {$pt * 25.4 / 72.0}]
}
```

### Typical Values for A4

```tcl
mm_to_pt 210    ;# --> 595.276 pt (A4 width)
mm_to_pt 297    ;# --> 841.890 pt (A4 height)
mm_to_pt 20     ;# --> 56.693 pt (2 cm margin)
mm_to_pt 10     ;# --> 28.346 pt (1 cm margin)
```

### Page Dimensions

| Format | mm          | pt                  | inch           |
|--------|-------------|---------------------|----------------|
| A4     | 210 x 297   | 595.276 x 841.890   | 8.27 x 11.69   |
| A3     | 297 x 420   | 842 x 1191          | 11.69 x 16.54  |
| A5     | 148 x 210   | 420 x 595           | 5.83 x 8.27    |
| Letter | 216 x 279   | 612 x 792           | 8.5 x 11       |

## First Steps

### The Minimal PDF

```tcl
#!/usr/bin/env tclsh
package require pdf4tcl 0.9

set pdf [::pdf4tcl::new %AUTO% -paper a4 -orient true]
$pdf startPage
$pdf setFont 18 Helvetica-Bold
$pdf text "Hello World!" -x 50 -y 100
$pdf endPage
$pdf write -file hello.pdf
$pdf destroy
```

### Line-by-Line Explanation

`::pdf4tcl::new` creates a new PDF object. `%AUTO%` generates an automatic
command name (e.g. `pdf1`). `-paper a4` sets the paper size to A4
(595 x 842 pt). `-orient true` places the coordinate origin at the top left.

`startPage` begins a new page. `setFont` sets the font size and typeface.
`text` writes text at the given position. `endPage` closes the page.
`write -file` saves the PDF. `destroy` releases the object.

### Text with Different Fonts

```tcl
#!/usr/bin/env tclsh
package require pdf4tcl 0.9

set pdf [::pdf4tcl::new %AUTO% -paper a4 -orient true]
$pdf startPage

# Heading
$pdf setFont 24 Helvetica-Bold
$pdf text "My Document" -x 50 -y 60

# Body text
$pdf setFont 12 Times-Roman
$pdf text "This is a paragraph in Times Roman." -x 50 -y 100

# Emphasized text
$pdf setFont 12 Helvetica-Bold
$pdf text "Important:" -x 50 -y 130
$pdf setFont 12 Helvetica
$pdf text "Normal text after the emphasis." -x 110 -y 130

# Monospace for code
$pdf setFont 10 Courier
$pdf text "puts \"Hello World\"" -x 50 -y 170

$pdf endPage
$pdf write -file fonts-demo.pdf
$pdf destroy
```

### Colors and Shapes

```tcl
#!/usr/bin/env tclsh
package require pdf4tcl 0.9

set pdf [::pdf4tcl::new %AUTO% -paper a4 -orient true]
$pdf startPage

# Colored text
$pdf setFont 16 Helvetica-Bold
$pdf setFillColor 0.8 0.0 0.0
$pdf text "Red text" -x 50 -y 50

# Line
$pdf setStrokeColor 0.0 0.0 0.0
$pdf setLineWidth 1
$pdf line 50 70 300 70

# Filled rectangle
$pdf setFillColor 0.9 0.9 0.9
$pdf rectangle 50 90 250 80 -filled 1

# Text on rectangle
$pdf setFillColor 0.0 0.0 0.0
$pdf setFont 12 Helvetica
$pdf text "Text on gray background" -x 60 -y 120

$pdf endPage
$pdf write -file colors-demo.pdf
$pdf destroy
```

### Saving and Output

```tcl
# Save to file
$pdf write -file output.pdf

# Return as string
set pdfdata [$pdf get]

# Ensure directory exists
file mkdir output
$pdf write -file [file join output document.pdf]
```

## Project Structure

A recommended project structure for pdf4tcl projects:

```
myproject/
|-- src/
|   |-- generate.tcl        # main script
|   |-- helpers.tcl         # helper functions
|-- output/                 # generated PDFs
|-- data/                   # input data
|-- images/                 # logos and images
```

## Encryption

pdf4tcl supports two encryption levels:

### AES-128 (default, from 0.9.4.11)

AES-128 (V=4, R=4, PDF 1.6) works without external dependencies
and is suitable for production use:

```tcl
# User password only
set pdf [::pdf4tcl::new %AUTO% -paper a4 \
    -userpassword "secret"]

# User + owner password
set pdf [::pdf4tcl::new %AUTO% -paper a4 \
    -userpassword  "user" \
    -ownerpassword "admin"]
```

### AES-256 (from 0.9.4.16)

AES-256 (V=5, R=6, PDF 2.0) is activated with `-encversion 5`.
From version 0.9.4.18 no external backend is required — SHA-384/512
is included as a pure-Tcl implementation:

```tcl
set pdf [::pdf4tcl::new %AUTO% -paper a4 \
    -userpassword "secret" \
    -encversion 5]
```

SHA backend chain (automatic, no configuration needed):

1. tcl-sha — fast C extension (optional)
2. openssl — if available in PATH (usually present on Linux/macOS)
3. pure-tcl — always available, no external tool required

Note: AES-256 with pure-tcl takes approximately 24 seconds per PDF
(Tcllib AES is not optimized). For time-critical applications,
AES-128 remains the recommended choice.

Note: Encryption and PDF/A (`-pdfa`) cannot be combined — PDF/A
prohibits encryption per ISO 19005.


## PDF/A Conformance

pdf4tcl generates PDF/A-1b and PDF/A-2b compliant documents using the
`-pdfa` option:

```tcl
set pdf [::pdf4tcl::new %AUTO% -paper a4 \
    -pdfa 1b \
    -pdfa-icc /usr/share/color/icc/ghostscript/srgb.icc]
```

pdf4tcl automatically adds an XMP metadata stream with the pdfaid schema,
an OutputIntent with an sRGB ICC profile, and suppresses
`/Group /S /Transparency` on all pages.

**Important:** For PDF/A all fonts must be embedded. Standard fonts
(Helvetica, Times, Courier) are not embedded and violate PDF/A.
Use CIDFonts exclusively (see `pdf4tcl-cid-fonts.md`).

Validation:
```bash
verapdf --flavour 1b --format text my.pdf
```


## Coordinate Transformations (0.9.4.20)

`translate`, `rotate`, `scale`, and `transform` apply PDF coordinate
transformations. Always use with `gsave`/`grestore`.

```tcl
set y 200; set h 20
$pdf gsave
$pdf translate 100 [expr {$y + $h}]   ;# bottom edge at user-y
$pdf rotate 45
$pdf rectangle 0 0 50 $h -filled 1
$pdf grestore
```

**Important:** `$pdf text` uses absolute `Tm` positioning and is **not**
affected by transformations. Only graphics commands (`line`, `rectangle`,
`circle`) respond to `cm` transforms.

`getPageSize` returns `{width height}` in the current unit:

```tcl
set sz [$pdf getPageSize]
# A4 -unit mm: {210.0 297.0}   A4 -unit p: {595.0 842.0}
```

## Permissions (0.9.4.20)

`-permissions` controls user rights after opening an encrypted PDF.
Requires `-userpassword`.

```tcl
set pdf [::pdf4tcl::new %AUTO% -paper a4     -userpassword "readonly"     -ownerpassword "admin"     -permissions  {print}]
```

Presets: `all`, `none`, `readonly`. Or a list of rights:
`print`, `copy`, `modify`, `annotations`, `fill-forms`, `extract`,
`assemble`, `print-high`.

## Next Steps

- Text API and fonts: see pdf4tcl-text-and-fonts.md
- Graphics and colors: see pdf4tcl-graphics-and-colors.md
- Layout patterns: see pdf4tcl-layout-patterns.md
