# How-to: Canvas export (Tk / tkpath / tko)

## Runnable script

```bash
tclsh doc/en/howtos/howto-canvas.tcl
# PDF -> doc/en/out/
```

Companion: [`howto-canvas.tcl`](howto-canvas.tcl).

Demos: `demo-canvas-0.9.4.24.tcl`, `demo-canvas-tkpath.tcl`  
Guide: `../reference/pdf4tcl-canvas.md`

## Problem

Dump a drawn Tk canvas (or tko::path) into the PDF.

## Recipe

Needs **wish** / a display (`DISPLAY` set).

```tcl
package require Tk
package require pdf4tcl 0.9

canvas .c -width 400 -height 200 -background white
.c create rectangle 20 20 120 80 -fill #4472c4 -outline black
.c create text 200 100 -text "Hello canvas" -font {Helvetica 14}

set pdf [::pdf4tcl::new %AUTO% -paper a4 -orient 1]
$pdf startPage
$pdf canvas .c -x 50 -y 50 -width 400 -height 200
$pdf endPage
$pdf write -file canvas.pdf
$pdf destroy
exit 0
```

Useful options: `-bbox`, `-sticky`, `-bg`, `-fontmap`, `-textscale`.

## Text that is not Latin-1

Load the font under the name of the Tk family, and nothing else is needed
(0.9.4.60 and newer):

```tcl
pdf4tcl::loadBaseTrueTypeFont Base tahoma.ttf
pdf4tcl::createFontSpecCID Base Tahoma       ;# named like the Tk family
.tp create ptext 20 30 -text "\u0395\u03bb\u03bb\u03ac\u03b4\u03b1" \
        -fontfamily Tahoma -fontsize 14
$pdf canvas .tp -bbox [.tp bbox all]         ;# no -fontmap
$pdf getSubstCount        ;# 0 = every character had a glyph
```

For a `tk::canvas` item the family is the one written in the font
specification -- `Tahoma` in `-font {Tahoma 14}`.

Where the name cannot be chosen freely, map the Tk font onto a PDF font
instead. A mapping always wins over the lookup above:

```tcl
pdf4tcl::loadBaseTrueTypeFont Base DejaVuSans.ttf
pdf4tcl::createFontSpecCID Base Uni
font create DocText -family Helvetica -size 14
.c create text 20 30 -text "\u0395\u03bb\u03bb\u03ac\u03b4\u03b1" -font DocText

$pdf canvas .c -bbox [.c bbox all] -fontmap {DocText Uni}
$pdf getSubstCount        ;# 0 = every character had a glyph
```

**The mapping key is not the same for both canvases.** A `tk::canvas` item
is looked up under its *whole* font specification, so `{Helvetica 14}` is
not found under `Helvetica` -- a named font is easier to get right. A
`tko::path` item is looked up under its *family* alone. Getting it wrong
gives question marks and no error, which is what `getSubstCount` is for.
The family lookup has no such trap: it takes the family either way.

See [`../reference/pdf4tcl-canvas.md`](../reference/pdf4tcl-canvas.md), and
`demo/demo-canvas-0.9.4.24.tcl` and `demo/demo-canvas-tko.tcl` for both
forms side by side.

## Notes

- `tko::path` uses the same `$pdf canvas .path ...` entry point.
- Window items: coordinates are taken before rasterising (fixed in 0.9.4.38).
