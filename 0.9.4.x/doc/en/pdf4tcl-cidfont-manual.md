# pdf4tcl CID Fonts – User Manual

## Introduction

pdf4tcl 0.9.4.5 adds `createFontSpecCID`, a new font creation command that
embeds a TrueType font as a CID (Character ID) font. CID fonts use a direct
Unicode-to-GlyphID mapping and are not limited to the 256-character WinAnsi
encoding used by `createFont`.

This manual covers the new API, usage patterns, font selection, and known
limitations.

---

## When to Use CID Fonts

`createFont` with WinAnsi encoding covers the Latin-1 range (U+0000..U+00FF)
and is sufficient for German, French, Spanish, and other Western European
languages.

Use `createFontSpecCID` when the document requires characters outside that
range:

| Language or use case         | Example characters        |
|------------------------------|---------------------------|
| Polish, Czech, Slovak        | ą ę ś ż ź č ž š ł        |
| Greek                        | α β γ δ π σ Σ Ω           |
| Russian, Ukrainian, Bulgarian | А Б В Г а б в г          |
| Mathematical notation        | ∀ ∃ ∑ ∫ √ ∞ ≤ ≠ ≥        |
| Arrows and symbols           | ← → ↑ ↓ ⇒ ⇔ ✓ ✗ ★       |
| Box drawing                  | ─ │ ┼ ╔ ╗ ╚ ╝            |
| Japanese, Chinese, Korean    | requires a CJK TTF        |

---

## API Reference

### loadBaseTrueTypeFont

```tcl
pdf4tcl::loadBaseTrueTypeFont baseName /path/to/font.ttf
```

Loads a TrueType font file and stores it under `baseName`. Required before
calling `createFontSpecCID`. The same base font can be shared by multiple
CID font instances.

| Parameter  | Description                                      |
|------------|--------------------------------------------------|
| `baseName` | Internal identifier for this font file           |
| path       | Absolute path to a TrueType (.ttf) font file     |

### createFontSpecCID

```tcl
pdf4tcl::createFontSpecCID baseName fontName
```

Creates a CID font instance from a loaded base font. `fontName` is the
identifier used in subsequent `setFont` calls.

| Parameter  | Description                                      |
|------------|--------------------------------------------------|
| `baseName` | Name passed to `loadBaseTrueTypeFont`            |
| `fontName` | Font identifier for `setFont`                    |

**Errors:**

- `baseName not loaded` – `loadBaseTrueTypeFont` was not called first.
- `baseName is not a TTF font` – Type1 base fonts are not supported.

---

## Usage

### Basic Example

```tcl
package require pdf4tcl

pdf4tcl::loadBaseTrueTypeFont DejaVuBase \
    /usr/share/fonts/truetype/dejavu/DejaVuSans.ttf
pdf4tcl::createFontSpecCID DejaVuBase cidSans

set pdf [pdf4tcl::new %AUTO% -paper a4 -orient true]
$pdf startPage
$pdf setFont 12 cidSans

$pdf text "German:    Aerger, Oel, Uebung, ss"    -x 50 -y 100
$pdf text "Polish:    Lodz, wazny, sroda"          -x 50 -y 120
$pdf text "Greek:     alpha beta gamma sigma"      -x 50 -y 140
$pdf text "Cyrillic:  Privyet mir"                 -x 50 -y 160
$pdf text "Math:      forall exists sum integral"  -x 50 -y 180

$pdf write -file output.pdf
$pdf destroy
```

### Mixed Fonts on One Page

A CID font and a standard font can coexist on the same page. Each `setFont`
call switches the active font.

```tcl
$pdf setFont 11 Helvetica
$pdf text "Standard Western text" -x 50 -y 100

$pdf setFont 11 cidSans
$pdf text "Greek: alpha beta gamma" -x 50 -y 120

$pdf setFont 11 Helvetica
$pdf text "Back to standard" -x 50 -y 140
```

### String Width

`getStringWidth` returns correct values for CID fonts. Widths are read from
the TTF hmtx table.

```tcl
$pdf setFont 12 cidSans
set w [$pdf getStringWidth "some text"]
puts "Width: [format %.2f $w] pt"
```

### Text Boxes and Automatic Line Breaking

`drawTextBox` works with CID fonts. Line breaking uses `getStringWidth`
internally, which produces correct results for all scripts including CJK
(when a CJK font is loaded).

```tcl
$pdf setFont 11 cidSans
$pdf drawTextBox "Long text with Cyrillic and Greek..." \
    50 100 400 200 -align left
```

### Multiple TTF Files

Each TTF file requires one `loadBaseTrueTypeFont` call. Multiple CID font
instances can share the same base font.

```tcl
pdf4tcl::loadBaseTrueTypeFont DejaVuBase     $regularPath
pdf4tcl::loadBaseTrueTypeFont DejaVuBaseBold $boldPath

pdf4tcl::createFontSpecCID DejaVuBase     cidRegular
pdf4tcl::createFontSpecCID DejaVuBaseBold cidBold

$pdf setFont 11 cidRegular
$pdf text "Normal weight" -x 50 -y 100

$pdf setFont 11 cidBold
$pdf text "Bold weight"   -x 50 -y 120
```

### Portable Font Path Detection

```tcl
proc findFont {candidates} {
    foreach path $candidates {
        if {[file exists $path]} { return $path }
    }
    return ""
}

set dejavuPath [findFont {
    /usr/share/fonts/truetype/dejavu/DejaVuSans.ttf
    /usr/share/fonts/TTF/DejaVuSans.ttf
    /Library/Fonts/DejaVuSans.ttf
    C:/Windows/Fonts/DejaVuSans.ttf
}]

if {$dejavuPath ne ""} {
    pdf4tcl::loadBaseTrueTypeFont DejaVuBase $dejavuPath
    pdf4tcl::createFontSpecCID DejaVuBase cidSans
    set bodyFont cidSans
} else {
    # Fallback: WinAnsi only, no extended Unicode
    set bodyFont Helvetica
}
```

---

## Font Coverage

The character coverage depends entirely on the TTF file. The following
tables list the Unicode blocks available in commonly used fonts.

### DejaVu Sans

Install on Debian/Ubuntu: `apt install fonts-dejavu-core`

**Scripts and Alphabets**

| Block                  | Range           | Glyphs | Notes                               |
|------------------------|-----------------|--------|-------------------------------------|
| Latin-1 Supplement     | U+00C0..U+00FF  |     63 | Western European, same as WinAnsi   |
| Latin Extended-A       | U+0100..U+017F  |    127 | Central European: PL, CZ, SK, HR    |
| Latin Extended-B       | U+0180..U+024F  |    207 | Rare Latin, African languages       |
| IPA                    | U+0250..U+02AF  |     95 | Phonetic transcription              |
| Greek and Coptic       | U+0370..U+03FF  |    134 | Greek alphabet and math symbols     |
| Cyrillic               | U+0400..U+04FF  |    255 | Russian, Ukrainian, Bulgarian, etc. |
| CJK                    | –               |      0 | Not covered, use a CJK font         |

**Mathematics and Numbers**

| Block                       | Range           | Glyphs | Notes                            |
|-----------------------------|-----------------|--------|----------------------------------|
| Superscripts and Subscripts | U+2070..U+209F  |     49 | Exponents, indices               |
| Letterlike Symbols          | U+2100..U+214F  |     54 | N R Z C, trade mark, etc.        |
| Number Forms                | U+2150..U+218F  |     31 | Fractions: 1/2 1/4 3/4           |
| Mathematical Operators      | U+2200..U+22FF  |    255 | Full coverage                    |
| Supplemental Math Operators | U+2A00..U+2AFF  |     73 | Extended operators               |

**Symbols**

| Block                       | Range           | Glyphs | Notes                            |
|-----------------------------|-----------------|--------|----------------------------------|
| Arrows                      | U+2190..U+21FF  |    111 | Single, double, diagonal arrows  |
| Technical Symbols           | U+2300..U+23FF  |     64 | Keyboard, clock, brackets        |
| Miscellaneous Symbols       | U+2600..U+26FF  |    188 | Weather, chess, cards, music     |
| Dingbats                    | U+2700..U+27BF  |    174 | Scissors, checkmarks, stars      |
| Misc. Symbols and Arrows    | U+2B00..U+2BFF  |     34 | Wide arrows, modern symbols      |

**Graphic Characters**

| Block                       | Range           | Glyphs | Notes                            |
|-----------------------------|-----------------|--------|----------------------------------|
| Box Drawing                 | U+2500..U+257F  |    127 | Single and double lines          |
| Block Elements              | U+2580..U+259F  |     32 | Block shading: full, 3/4, 1/2    |
| Geometric Shapes            | U+25A0..U+25FF  |     94 | Triangles, circles, squares      |

**Miscellaneous**

| Block                       | Range           | Glyphs | Notes                            |
|-----------------------------|-----------------|--------|----------------------------------|
| Currency Symbols            | U+20A0..U+20CF  |     25 | EUR GBP JPY RUB INR BTC          |
| Enclosed Alphanumerics      | U+2460..U+24FF  |      9 | Circled digits and letters       |

A visual overview of all available glyphs is provided by `demo-symbole.tcl`
(4 pages, in `0.9.4.x/demo/`).

### IPAGothic / IPAexGothic

Japanese fonts with full CJK coverage.
Install on Debian/Ubuntu: `apt install fonts-ipafont-gothic`

```tcl
pdf4tcl::loadBaseTrueTypeFont IPAGothic \
    /usr/share/fonts/opentype/ipafont-gothic/ipag.ttf
pdf4tcl::createFontSpecCID IPAGothic cidCJK
$pdf setFont 12 cidCJK
$pdf text "Japanese text" -x 50 -y 100
```

### Noto Sans

Google's Noto family covers almost all Unicode blocks. Each writing system
is provided as a separate TTF/OTF file:
`NotoSans-Regular.ttf`, `NotoSansCJKjp-Regular.otf`,
`NotoSansArabic-Regular.ttf`, and others.

---

## Checking Glyph Availability

To determine at runtime whether a specific character is present in a loaded
base font:

```tcl
proc glyphAvailable {baseName codepoint} {
    return [dict exists $::pdf4tcl::BFA($baseName,charToGlyph) $codepoint]
}

# Example: check before rendering
foreach ch [split $text {}] {
    scan $ch %c n
    if {![glyphAvailable DejaVuBase $n]} {
        puts "U+[format %04X $n] not in font"
    }
}
```

Missing glyphs render as an empty box (.notdef, GlyphID 0). No error is
raised.

---

## Comparing Font Creation Methods

| Criterion             | createFont    | createFontSpecEnc  | createFontSpecCID   |
|-----------------------|---------------|--------------------|---------------------|
| Character limit       | 256           | up to 256          | unlimited           |
| Encoding              | WinAnsi       | user-defined       | Identity-H          |
| TTF embedding         | subset        | subset             | complete TTF        |
| Type1 fonts           | yes           | yes                | no                  |
| CJK support           | no            | limited            | yes (with CJK TTF)  |
| AcroForm fields       | yes           | yes                | no                  |
| File size impact      | small         | small              | larger              |
| getStringWidth        | yes           | yes                | yes                 |
| Text copyable in PDF  | yes           | yes                | yes (ToUnicode CMap)|

---

## Limitations

### AcroForm Fields

CID fonts cannot be used with `addForm`. The PDF specification requires form
fields to reference fonts with a standard encoding. Use `createFont` or
`createFontSpecEnc` for form fields, even when the main document uses a CID
font.

### Bidirectional Text

pdf4tcl does not perform bidirectional reordering. Arabic and Hebrew text
must be provided in visual order. For programmatically assembled strings
this is often acceptable; for general-purpose user input it is not.

### OpenType Features

Ligatures, contextual substitution, and other OpenType GSUB/GPOS features
are not applied. Characters are mapped directly from Unicode codepoint to
GlyphID without shaping.

### Color Fonts and Emoji

Emoji and color fonts (CBDT/CBLC, SBIX, COLRv0/v1 tables) are not
supported. Characters above U+FFFF (outside the Basic Multilingual Plane)
require `\U` escaping in Tcl source and depend on the font containing those
glyphs.

### File Size

The complete TTF is embedded for each base font, regardless of how many
characters are actually used. A typical DejaVuSans.ttf adds approximately
750 KB to the PDF. Documents with multiple CID fonts grow accordingly.

---

## Technical Notes

### PDF Object Structure

For each CID font, pdf4tcl writes the following PDF objects:

```
Type0 Font
  /Subtype    /Type0
  /Encoding   /Identity-H
  /DescendantFonts  [CIDFontType2]
  /ToUnicode  ToUnicode CMap stream

CIDFontType2
  /CIDSystemInfo  << /Registry (Adobe) /Ordering (Identity) /Supplement 0 >>
  /CIDToGIDMap    /Identity
  /FontDescriptor FontDescriptor
  /W              [GlyphID [width] ...]

FontDescriptor
  /FontFile2  embedded TTF stream

ToUnicode CMap
  beginbfchar
  <GlyphID> <Unicode>
  endbfchar
```

The ToUnicode CMap is built from the glyphs actually used on all pages. This
enables text selection and search in PDF viewers. The W array likewise
contains only widths for glyphs that appear in the document.

Font objects are written during `finish` / `write`, not at `setFont` time.
Object IDs are reserved at `createFontSpecCID` so that the `/Font` dictionary
reference is valid before the actual data is written.

### String Width Calculation

For CID fonts, `getStringWidth` and `getCharWidth` look up each character in
the TTF hmtx table via the `charToGlyph` dictionary:

1. Unicode codepoint (`scan $char %c`)
2. GlyphID lookup in `BFA($baseName,charToGlyph)`
3. hmtx advance width for that GlyphID
4. Scale to points: `width / unitsPerEm * fontSize`

CJK characters are typically full-width (advance = unitsPerEm), which
`getStringWidth` returns correctly.

---

## Demo Files

| File                          | Description                                  |
|-------------------------------|----------------------------------------------|
| `demo-api-vergleich.tcl`      | Side-by-side: createFont vs createFontSpecCID|
| `demo-symbole.tcl`            | All DejaVu glyph blocks, 4 pages             |
| `demo-cidfont.tcl`            | Basic CID font usage example                 |

All demo files are located in `0.9.4.x/demo/` and require DejaVuSans.ttf.
