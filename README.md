# pdf4tcl fork (0.9.4.12)

**This is an unofficial personal fork** of
[pdf4tcl 0.9.4](https://sourceforge.net/projects/pdf4tcl/)
by Peter Spjuth. It is not affiliated with or endorsed by the original
project. New features and bug fixes are submitted as tickets to the
upstream project where appropriate.

## Goals

This fork started as a personal working environment -- features and
fixes developed for own projects, submitted upstream where appropriate.

The focus is on extending the 0.9.4.x line with practical features:
full Unicode via CID fonts, PDF/A-1b/2b support, transparency, and
AES-256 encryption -- covering real-world PDF generation needs in Tcl.

There are no plans to diverge from the upstream versioning scheme or
to replace the official project.

## Requirements

- Tcl/Tk 8.6 or newer (Tcl 9.0 compatible)
- `make` and standard Unix tools for building

## Build

`pdf4tcl.tcl` is assembled from the source files in `src/`. Always run
`make` after cloning or modifying source files:

```bash
make
```

This runs:

```bash
cat src/prologue.tcl src/fonts.tcl src/helpers.tcl \
    src/options.tcl src/main.tcl src/cat.tcl > pdf4tcl.tcl
```

Do not edit `pdf4tcl.tcl` directly -- changes will be lost on the next build.

## Tests

```bash
make test
```

Tcl 8.6: 397 tests, 393 passed, 4 skipped (demo, knownbug, notoColorEmoji, runin87p).

## Usage

```tcl
lappend auto_path /path/to/pdf4tcl
package require pdf4tcl 0.9.4.9

set pdf [::pdf4tcl::new %AUTO% -paper a4 -orient true -compress 1]
$pdf startPage
$pdf setFont 12 Helvetica
$pdf text "Hello World" -x 50 -y 50
$pdf endPage
$pdf write -file output.pdf
$pdf destroy
```

## Features added in this fork

### addForm v2.1 (Ticket #9)

Eight interactive form field types: `text`, `password`, `checkbox`,
`combobox`, `listbox`, `radiobutton`, `pushbutton`, `signature`.
Options: `-required`, `-readonly`, `-label`, `-group`/`-value` for
radio buttons, `-action`/`-url` for push buttons.

### hyperlinkAdd (Ticket #15)

URI hyperlink annotations with configurable border, color, dash pattern
and highlight mode.

```tcl
$pdf hyperlinkAdd 50 100 200 15 "https://example.com"
```

### CID Font / Unicode support (Ticket #16)

Full Unicode text output via TrueType fonts (e.g. DejaVu Sans).
Covers Latin Extended, Greek, Cyrillic, CJK, mathematics, arrows and more.
No 256-character limit.

```tcl
pdf4tcl::loadBaseTrueTypeFont DejaVuSans /path/to/DejaVuSans.ttf
pdf4tcl::createFontSpecCID DejaVuSans cidSans
$pdf setFont 12 cidSans
$pdf text "\u03b1\u03b2\u03b3 \u041f\u0440\u0438\u0432\u0435\u0442" -x 50 -y 100
```

### PDF/A-1b and PDF/A-2b support (0.9.4.8)

Produces archival PDF with embedded fonts, XMP metadata, OutputIntent
and pdfaid identification schema. Verified with veraPDF.

```tcl
pdf4tcl::new mypdf -paper a4 -pdfa 1b \
    -pdfa-icc /usr/share/color/icc/sRGB.icc
```

Note: PDF/A requires all fonts to be embedded. Use CID fonts (TrueType)
instead of the built-in standard fonts (Helvetica, Times-Roman, Courier).

### ToUnicode CMap for standard fonts (0.9.4.9)

Standard fonts (Helvetica, Times-Roman, Courier and variants) now include
a ToUnicode CMap stream. This enables copy-paste and text extraction in
PDF viewers and fixes veraPDF rule 6.3.9 in PDF/A mode.

### Further fixes and additions

- `getLineHeight` method (Ticket #18)
- `viewerPreferences`, `metadata -moddate` (Ticket #19)
- `pageLabel` for custom page numbering in viewer (Ticket #23)
- `GetCharWidth` fallback for unmappable characters -- fixes `-align right/center` (Ticket #17)
- `SafeQuoteString` -- fixes Tcl 9.0 EILSEQ in `bookmarkAdd`/`metadata` with titles containing characters above U+00FF
- CID font `.notdef` width uses actual advance width from `hmetrics[0]`
- Fonts without a PostScript name (NameID 6) now produce a warning and
  a fallback name instead of an error (note: not suitable for PDF/A)
- `createFontSpecEnc` enforces 256-codepoint limit (Ticket #14)
- Metadata and bookmark fixes (Tickets #20, #21, #22)
- Tcl 9.0 compatibility fixes throughout

## Demos

```bash
cd 0.9.4.x/demo
tclsh demo-all.tcl
tclsh demo-cidfont.tcl /path/to/DejaVuSans.ttf
tclsh demo-pdfa.tcl --font /path/to/DejaVuSans.ttf
tclsh demo-unicode-tabelle.tcl        # auto-detects fonts in ../fonts/
```

## Documentation

- `0.9.4.x/doc/en/pdf4tcl-forms-manual.md` -- addForm user manual
- `0.9.4.x/doc/en/pdf4tcl-cidfont-manual.md` -- CID font user manual
- `0.9.4.x/doc/de/` -- German documentation
- `pdf4tcl.html` -- API reference (generated from `pdf4tcl.man`)

## Upstream

Patches for individual tickets are in `0.9.4.x/ticket*/` and can be
applied independently to a clean upstream clone.

Original project: https://sourceforge.net/projects/pdf4tcl/

## Changelog

### 0.9.4.12 (2026-03-15)

- `roundedRect` method: rectangle with rounded corners, Bezier approximation,
  options `-radius`, `-filled`, `-stroke`
- Unit conversion procs: `pdf4tcl::mm`, `pdf4tcl::cm`, `pdf4tcl::in`,
  `pdf4tcl::pt` — convert to PDF points
- `_ValidatePdfDate`: validate and normalise PDF date strings in `metadata`
  method; throws `PDF4TCL BADDATE` on invalid format
- 17 new tests in `tests/new-0.9.4.12.test`

