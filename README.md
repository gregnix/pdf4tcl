# pdf4tcl fork (0.9.4.21)

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
    src/options.tcl src/main.tcl src/encrypt.tcl src/cat.tcl > pdf4tcl.tcl
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



## Upstream

Patches for individual tickets are in `0.9.4.x/ticket*/` and can be
applied independently to a clean upstream clone.

Original project: https://sourceforge.net/projects/pdf4tcl/



