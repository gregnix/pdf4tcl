# Exporting a Tk canvas

`$pdf canvas .c` draws the contents of a Tk canvas widget onto the current
page. This is what turns a plot, a diagram or a drawing tool built with Tk
into a printable document without redrawing it a second time in PDF calls.

All numbers below were measured against 0.9.4.37.

---

## The shortest version

```tcl
package require Tk
package require pdf4tcl

canvas .c -width 300 -height 150 -background "#eef"
.c create rectangle 20 20 280 130 -outline blue -width 2
.c create oval 40 40 120 120 -fill "#ffcccc"
.c create text 200 75 -text "Canvas" -anchor center
update

set pdf [pdf4tcl::new %AUTO% -paper a4 -margin 40]
$pdf startPage
$pdf canvas .c
$pdf write -file out.pdf
$pdf destroy
```

The `update` matters. Item coordinates and the widget geometry are only
settled once Tk has processed the pending events; exporting before that can
produce a page laid out from stale sizes.

---

## What gets drawn, and how big

Two rectangles are involved and mixing them up is the usual source of
surprise:

- **`-bbox`** is the area *of the canvas* to export. Default is
  `$path bbox all`, the bounding box of all items.
- **`-x -y -width -height`** is the area *on the page* to place it in.
  Default is the origin plus the whole drawable area.

The contents are scaled to fill the area in one direction while preserving
the aspect ratio. `-sticky` decides where they sit; default is `nw`.

Measured with a 300x150 canvas whose items span `19 19 281 134`, on A4 with
40 point margins:

| call | returned bounding box on the page |
|---|---|
| `$pdf canvas .c` | `0.0 0.0 515.0 226.05` |
| `$pdf canvas .c -width 150` | `0.0 0.0 150.0 65.84` |

Two things to read out of this. The default fills the full drawable width
(515 = 595 - 2*40), not the canvas' pixel size -- a small canvas is scaled
*up*. And the return value is the box actually covered, which is what you
need to place a caption underneath:

```tcl
lassign [$pdf canvas .c -width 300] x1 y1 x2 y2
$pdf setFont 9 Helvetica
$pdf text "Figure 1: measured values" -x $x1 -y [expr {$y2 + 12}]
```

---

## Background

By default only the items are drawn, not the widget background:

```tcl
$pdf canvas .c -bg 1
```

`-bg 1` fills the area with the canvas' background colour first. For a
diagram meant to be printed on white paper, leaving it off is usually right;
for a screenshot-like reproduction, switch it on.

---

## Fonts

Without a mapping, text items are limited to the PDF built-ins: Helvetica,
Times and Courier. pdf4tcl guesses which one comes closest to the Tk font.

Where that is not good enough -- and it will not be for anything with an
embedded or non-Latin font -- pass a mapping from Tk font names to PDF font
names:

```tcl
pdf4tcl::loadBaseTrueTypeFont BaseFree FreeSans.ttf
pdf4tcl::createFont BaseFree DocFont iso8859-1
$pdf canvas .c -fontmap [list {Helvetica 14 bold} DocFont]
```

`-textscale` overrides the automatic downsizing pdf4tcl applies to canvas
text items it considers too large; a value above 1 shrinks all text by that
factor.

---

## Item types beyond the classic canvas

pdf4tcl also exports `tkpath` and `tko::path` widgets, which is what the
demos `demo-canvas-tkpath.tcl` and `demo-canvas-0.9.4.24.tcl` show. Support
covers the usual item set -- rectangles with rounded corners, ellipses, SVG
paths, gradients, dash patterns.

Those two widgets are handled through an `itempdf` delegation: the widget
itself reports how each item should be drawn, rather than pdf4tcl knowing
every item type. An item type the widget does not describe that way is
skipped rather than guessed at.

One caveat that has nothing to do with pdf4tcl: with `tko` 0.4 under
`wish8.6`, closing the window through the window manager aborts the
interpreter *after* the PDF has been written:

    alloc: invalid block: 0x55aac2363ae0: f0 c2

The panic comes from Tcl's threaded allocator, `Ptr2Block` in
`generic/tclThreadAlloc.c`: `ckfree` is handed a pointer whose magic numbers
are gone. Pure Tcl cannot cause that, and pdf4tcl is pure Tcl. The cause is
in tko: `generic/tkoWidget.c` stores `clientdata->option` without taking a
reference, while `WidgetClientdataDelete` releases one and
`WidgetClientdataClone` acquires one. One line fixes it:

```c
clientdata->option = myObjv[3];
Tcl_IncrRefCount(clientdata->option);   /* was missing */
```

Reproducible in three lines without pdf4tcl at all:

```tcl
package require tko
after 400 {destroy .}
```

`tclsh` never shows it, because it ends without tearing Tk down; `wish9.0`
does not either, most likely because Tcl 9 no longer uses the threaded
allocator and simply does not notice. Until tko is patched,
`demo-canvas-0.9.4.24.tcl` works around it by ending with `exit 0`.

---

## Window items

A canvas item of type `window` embeds a real Tk widget. There is no way to
put a live widget into a PDF, so pdf4tcl takes a screenshot of it via
`image create photo -format window`, which needs the `img::window` package.
Without it, a black box of the right size is drawn instead.

Two consequences worth knowing before wondering about the result: the
embedded widget must be mapped and rendered for the screenshot to show
anything, and what it shows depends on when the export runs. Two consecutive
runs of the same script can produce PDFs of different size for that reason.

---

## See also

- `pdf4tcl-images.md` -- how images are placed and scaled generally
- `pdf4tcl-basics.md` -- the coordinate system the placement area uses
- `demo/demo-canvas-0.9.4.24.tcl` -- classic canvas and `tko::path`
- `demo/demo-canvas-tkpath.tcl` -- `tkpath` items
