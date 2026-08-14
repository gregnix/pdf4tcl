# pdf4tcl fork (0.9.4.42)

**This is an unofficial personal fork** of
[pdf4tcl 0.9.4](https://sourceforge.net/projects/pdf4tcl/)
by Peter Spjuth. It is not affiliated with or endorsed by the original
project. New features and bug fixes are submitted as tickets to the
upstream project where appropriate.

## Goals

This fork started as a personal working environment -- features and
fixes developed for own projects, submitted upstream where appropriate.

The focus is on extending the 0.9.4.x line with practical features:
full Unicode via CID fonts, PDF/A-1b/2b/3b support, Tagged PDF with
PDF/UA-1 conformance, transparency, and AES-256 encryption -- covering
real-world PDF generation needs in Tcl.


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
    src/main.tcl src/encrypt.tcl src/tagged.tcl src/cat.tcl > pdf4tcl.tcl
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

`examples/tagged.tcl` produces a document that veraPDF 1.28.2 validates as
PDF/UA-1 conformant: 106 rules and 1492 checks passed, none failed. The
manual page describes the methods under *OBJECT METHODS, TAGGED PDF*,
`0.9.4.x/doc/en/TAGGED.md` goes into the background and the open ends, and
`tools/check-tagged.py` verifies the structure of a generated file.

Being tagged is not the same as being accessible. A document in which every
paragraph is `/P` and every heading is `/H1` validates just as cleanly and
still tells a reader nothing useful.


## Upstream

Patches for individual tickets are in `0.9.4.x/ticket*/` and can be
applied independently to a clean upstream clone.

Original project: https://sourceforge.net/projects/pdf4tcl/



