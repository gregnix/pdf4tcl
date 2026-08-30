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

Since 0.9.4.60, a font loaded under the *name of the family* is used without
any mapping at all:

```tcl
pdf4tcl::loadBaseTrueTypeFont Base tahoma.ttf
pdf4tcl::createFontSpecCID Base Tahoma      ;# named like the Tk family
.tp create ptext 20 30 -text "..." -fontfamily Tahoma -fontsize 14
$pdf canvas .tp                             ;# no -fontmap
```

For a `tk::canvas` item the family is the one written in the font
specification -- `Tahoma` in `-font {Tahoma 14}` -- and, failing that, the
family Tk resolved it to. The written name comes first on purpose: whether
Tk resolves `Tahoma` to Tahoma depends on what is installed, so a lookup on
the resolved name alone would give a different result on another machine.

The 14 standard fonts are not searched here, so their weight and slant are
still chosen by the pattern match below. When bold or italic is asked for,
`<family>-Bold`, `<family>-Italic` and `<family>-Oblique` are tried before
the plain family name.

A font name is written into the PDF as a name object, so it may not contain
a space unescaped. pdf4tcl escapes it (`DejaVu Sans` becomes
`/DejaVu#20Sans`), which matters because Tk families such as `DejaVu Sans`
or `Nimbus Sans` carry one. Before 0.9.4.60 such a name produced a file
whose page stayed empty, with no error anywhere.

Without a mapping *and* without a font of that name, text items are limited
to the PDF built-ins: Helvetica, Times and Courier. pdf4tcl decides which
one comes closest by matching the family name against a list of patterns.

Since 0.9.4.61 this uses the same order as the lookup above -- the written
name first, the resolved family second. Before that it asked the resolved
family only, so `-font {Times 14 italic}` gave `Times-Italic` on a machine
with `urw-base35` installed, where Tk resolves `Times` to `Nimbus Roman`,
and `Helvetica-Oblique` on a plain Ubuntu, where it resolves to `TeX Gyre
Termes`. The same script, two different files.

Recognised are the PostScript names and their common substitutes:

| built-in | patterns |
|---|---|
| `Courier` | `*courier*`, `*fixed*`, and any font Tk reports as fixed |
| `Times` | `*times*`, `*nimbus roman*`, `*tex gyre termes*`, `*liberation serif*`, `*dejavu serif*`, `*freeserif*` |
| `Helvetica` | `*helvetica*`, `*arial*`, `*nimbus sans*`, `*tex gyre heros*`, `*liberation sans*`, `*dejavu sans*`, `*freesans*` |

Anything else becomes Helvetica. That fallback is deliberate and unchanged,
but it is now distinguishable from a match: a family that is *recognised* as
Helvetica and one that merely *ends up* there are two different things, and
only the first survives a change of machine. Before 0.9.4.61 the pattern
list held only the first two or three entries of each row, so on a
distribution shipping TeX Gyre or Liberation nothing matched at all -- of
the twelve standard names exactly one, Courier, was really recognised, and
the Helvetica ones came out right only because the fallback happened to be
Helvetica.

A fixed font stays Courier regardless of the written name.

Where that is not good enough -- and it will not be for anything with an
embedded or non-Latin font -- pass a mapping from Tk font names to PDF font
names. An explicit mapping always wins over the lookup above:

```tcl
pdf4tcl::loadBaseTrueTypeFont BaseFree FreeSans.ttf
pdf4tcl::createFont BaseFree DocFont iso8859-1
$pdf canvas .c -fontmap [list {Helvetica 14 bold} DocFont]
```

### The key is not the same for both canvases

**`tk::canvas`** looks up the *whole* font specification, exactly as
`itemcget -font` gives it back. `{Helvetica 14}` will not be found under
`Helvetica` -- as a *mapping key*, that is; the family lookup described
above does take `Helvetica` on its own. A named font is easier to get right,
since the name is the whole specification:

```tcl
font create DocText -family Helvetica -size 14
.c create text 20 30 -text "..." -font DocText
$pdf canvas .c -fontmap {DocText DocFont}
```

**`tko::path` and `tkpath`** map the font *family* on its own, because a
`ptext` item carries family, size and weight as separate options:

```tcl
.tp create ptext 20 30 -text "..." -fontfamily Tahoma -fontsize 14
$pdf canvas .tp -fontmap {Tahoma DocFont}
```

### Unicode on a canvas

Both accept a CID font, so text beyond Latin-1 works:

```tcl
pdf4tcl::loadBaseTrueTypeFont Base DejaVuSans.ttf
pdf4tcl::createFontSpecCID Base UniFont
$pdf canvas .c -fontmap {DocText UniFont}
$pdf getSubstCount                       ;# 0 = every character had a glyph
```

Through `tko::path` this needs pdf4tcl 0.9.4.59 or newer: the callback the
widget uses took the 8-bit path unconditionally before that.

### Weight and slant of a standard font

For the built-ins the pattern match picks the variant: bold gives `-Bold`,
italic gives `-Oblique` (`-Italic` for Times), both give `-BoldOblique`. Up to
0.9.4.59 italic alone gave `-BoldOblique` as well, so slanted canvas text
came out bold; fixed in 0.9.4.60. On a `tko::path` or `tkpath` item any
`-fontslant` other than `normal` counts as slanted, `oblique` included.

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
