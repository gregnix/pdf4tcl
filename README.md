# pdf4tcl fork (0.9.4.6)

A fork of [pdf4tcl 0.9.4](https://sourceforge.net/projects/pdf4tcl/)
by Peter Spjuth. This fork adds new features and bug fixes submitted
as tickets to the upstream project.

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

Tcl 8.6: 314 tests, 311 passed, 3 skipped.
Tcl 9.0: 314 tests, 307 passed, 6 skipped, 1 known bug (canvas).

## Usage

```tcl
lappend auto_path /path/to/pdf4tcl
package require pdf4tcl 0.9.4.6

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
Covers Latin Extended, Greek, Cyrillic, mathematics, arrows and more.

```tcl
pdf4tcl::loadBaseTrueTypeFont DejaVuSans /path/to/DejaVuSans.ttf
pdf4tcl::createFontSpecCID DejaVuSans cidSans
$pdf setFont 12 cidSans
$pdf text "\u03b1\u03b2\u03b3 \u041f\u0440\u0438\u0432\u0435\u0442" -x 50 -y 100
```

### Further fixes and additions

- `getLineHeight` method (Ticket #18)
- `viewerPreferences`, `metadata -moddate` (Ticket #19)
- `pageLabel` for custom page numbering in viewer (Ticket #23)
- `GetCharWidth` fallback for unmappable characters -- fixes `-align right/center` (Ticket #17)
- `SafeQuoteString` -- fixes Tcl 9.0 EILSEQ in `bookmarkAdd`/`metadata` with titles containing characters above U+00FF
- CID font `.notdef` width now uses actual advance width from `hmetrics[0]`
- `createFontSpecEnc` enforces 256-codepoint limit (Ticket #14)
- Metadata and bookmark fixes (Tickets #20, #21, #22)
- Tcl 9.0 compatibility fixes throughout

## Demos

```bash
cd 0.9.4.x/demo
tclsh demo-all.tcl
tclsh demo-cidfont.tcl /path/to/DejaVuSans.ttf
```

## Documentation

- `0.9.4.x/doc/pdf4tcl-forms-manual.md` -- addForm user manual
- `0.9.4.x/doc/pdf4tcl-cidfont-manual.md` -- CID font user manual
- `0.9.4.x/doc/de/` -- German documentation
- `pdf4tcl.html` -- original API reference (generated from `pdf4tcl.man`)

## Upstream

Patches for individual tickets are in `0.9.4.x/ticket*/` and can be
applied independently to a clean upstream clone.

Original project: https://sourceforge.net/projects/pdf4tcl/
