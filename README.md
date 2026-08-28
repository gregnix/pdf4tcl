# pdf4tcl fork (0.9.4.60)

**This is an unofficial personal fork** of
[pdf4tcl 0.9.4](https://sourceforge.net/projects/pdf4tcl/)
by Peter Spjuth. It is not affiliated with or endorsed by the original
project. New features and bug fixes are submitted as tickets to the
upstream project where appropriate.

## Goals

This fork started as a personal working environment -- features and
fixes developed for own projects, submitted upstream where appropriate.

The focus is on extending the 0.9.4.x line with practical features:
full Unicode via subsetted CID fonts, PDF/A at every level from 1b to
3u, Tagged PDF with PDF/UA-1 conformance, transparency, interactive
forms, and AES-256 encryption -- covering real-world PDF generation
needs in Tcl.


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
cat src/prologue.tcl src/fonts.tcl src/helpers.tcl src/options.tcl \
    src/main.tcl src/color.tcl src/encrypt.tcl src/tagged.tcl \
    src/cat.tcl > pdf4tcl.tcl
```

Do not edit `pdf4tcl.tcl` directly -- changes will be lost on the next build.


## Usage

```tcl
lappend auto_path /path/to/pdf4tcl
package require pdf4tcl 

set pdf [::pdf4tcl::new %AUTO% -paper a4 -orient true -compress 1]
$pdf startPage
$pdf setFont 12 Helvetica
$pdf text "Hello World" -x 50 -y 50
$pdf endPage
$pdf write -file output.pdf
$pdf destroy
```



## pdf4tcllib -- the companion library

pdf4tcl draws; it does not lay out. Line wrapping, tables with page
breaks, form layout, a table of contents with real page numbers, charts,
label sheets -- those live in a separate project built on top of it:

**[pdf4tcllib](https://github.com/gregnix/pdf4tcllib)**

```tcl
package require pdf4tcllib          ;# fonts, text, tables, page, drawing, form
package require pdf4tcltable        ;# export a Tk tablelist widget
package require pdf4tcltext         ;# export a Tk text widget
package require pdf4tclforms        ;# declarative AcroForm layouts
package require pdf4tcllabels       ;# label sheets and roll labels
package require pdf4tcltoc          ;# contents page, two-pass layout
package require pdf4tclchart        ;# bar, line and pie charts
package require pdf4tclflow         ;# text through columns and pages
```

Each module is usable on its own; the only shared dependency is
`pdf4tcllib` itself, and its only external dependency is pdf4tcl.

The two projects are developed together. Several features in this fork
exist because pdf4tcllib needed them -- `getUntaggedCount`, the structure
nesting checks and the `-newyvar` fix all came from building something on
top and finding out what was missing. Tagging works best with pdf4tcl
0.9.4.43 or later, where the building blocks mark up what they draw.

## Tagged PDF

Since 0.9.4.36 documents can carry a logical structure (ISO 32000-1
clause 14.7/14.8), which is what assistive technology reads instead of the
order in which glyphs happen to be painted. It also makes text extraction
and reflow reliable.

```tcl
$pdf tagged 1 -lang de-DE -ua 1
$pdf startPage
$pdf tagText H1 "Chapter 1" -x 0 -y 20
$pdf tagBegin P
$pdf text "First line" -x 0 -y 50
$pdf text "Second line of the same paragraph" -x 0 -y 65
$pdf tagEnd
```

`examples/tagged.tcl` produces a document that veraPDF validates as PDF/UA-1
conformant. The manual page describes the methods under *OBJECT METHODS,
TAGGED PDF*, [`doc/en/reference/TAGGED.md`](doc/en/reference/TAGGED.md) goes
into the structure tree and the table attributes, and
`tools/check-tagged.py` verifies the structure of a generated file.

Being tagged is not the same as being accessible. A document in which every
paragraph is `/P` and every heading is `/H1` validates just as cleanly and
still tells a reader nothing useful.


## Documentation

| | |
|---|---|
| [`doc/en/tutorials/`](doc/en/tutorials/README.md) | Follow along from a first page to a tagged, multilingual document |
| [`doc/en/howtos/`](doc/en/howtos/README.md) | "How do I do X" -- one task per file, each with a runnable script |
| [`doc/en/reference/`](doc/en/reference/README.md) | How an area works and what it costs |
| [`demo/`](demo/README.md) | 39 small programs, one feature each, run end to end |
| `pdf4tcl.man`, `pdf4tcl.html` | The manual page: every method and option |

Every howto and tutorial ships the script it describes, and
`doc/en/run-all-examples.tcl` runs all of them -- so what the documentation
shows is what the current code produces, not what it produced once.

## Checking what you generated

```bash
tclsh tools/pdfcheck-native.tcl out.pdf     # structures, fonts, metadata
tclsh tools/layout-check.tcl    out.pdf     # overlapping text, margins
python3 tools/check-tagged.py   out.pdf     # the structure tree
verapdf -f 2b                   out.pdf     # the conformance claim
```

The first two need no external tools beyond poppler and report what they
find rather than passing judgement -- a finding on a deliberately dense page
is not a defect. Their file headers say where the limits are.

Over a directory of ordinary PDFs, `pdfcheck-native.tcl` warns on nearly
every file that it claims no conformance and uses standard fonts -- true,
but not news. `--plain` drops those two for files that claim nothing, and
leaves everything else alone:

```bash
tclsh tools/pdfcheck-native.tcl --plain demo/out/   # 64 PASS, 6 WARN
tclsh tools/pdfcheck-native.tcl         demo/out/   # 12 PASS, 58 WARN
```

A file that does claim PDF/A is checked unchanged, where an unembedded font
is a FAIL under clause 6.3.4.

## Where the parts come from

This fork continues Frank Richter's and Peter Spjuth's pdf4tcl; the
copyright notices at the top of every source file name them and Yaroslav
Schekin, and they stay there. Beyond that:

- **The silent substitution** (fixed in 0.9.4.49 -- a character the font
  has no glyph for used to vanish without a word) was pointed out in a
  comparison with tclpdf posted to a newsgroup on 2026-08-18. The finding
  came from there; no code did. The ChangeLog entry says so at the place
  it belongs.

- **`/Length` in the encryption dictionary** (fixed in 0.9.4.53) was
  pointed out by Alexander Schoepe of tclpdf on 2026-08-22: the entry
  belongs only to V 2 or 3, and pdf4tcl wrote it beside V 4 and V 5.

- **Strings that bypassed encryption** (fixed in 0.9.4.54) came out of
  checking a remark of his about the EFF entry: EFF made no difference,
  but the attachment name in the name tree was going out in the clear
  while the file specification around it was encrypted -- which left the
  attachment unreachable.

Those are findings, not code. If code from tclpdf is ever taken over, the
copyright notice comes with it -- the one condition the MIT licence makes,
and the least this project owes a second implementation written from the
ISO standards rather than from someone else's source.

Having a second implementation to compare against is worth more than it
looks: a validator says whether a file is conformant, not whether the
library does the sensible thing. That defect was found by neither the test
suite nor veraPDF.

## Upstream

Patches for the individual SourceForge tickets (9 to 24, fixed in
0.9.4.1 through 0.9.4.24) were kept as `0.9.4.x/ticket*/` directories until
0.9.4.45. They are all in the released code by now; the patches
themselves remain in the git history.

Original project: https://sourceforge.net/projects/pdf4tcl/



