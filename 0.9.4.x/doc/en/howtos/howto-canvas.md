# How-to: Canvas export (Tk / tkpath / tko)

## Runnable script

```bash
tclsh 0.9.4.x/doc/en/howtos/howto-canvas.tcl
# PDF -> 0.9.4.x/doc/en/out/
```

Companion: [`howto-canvas.tcl`](howto-canvas.tcl).

Demos: `demo-canvas-0.9.4.24.tcl`, `demo-canvas-tkpath.tcl`  
Guide: `../pdf4tcl-canvas.md`

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

## Notes

- `tko::path` uses the same `$pdf canvas .path …` entry point.
- Under **tko 0.4**, closing the interpreter can crash on exit (refcount bug
  outside pdf4tcl). Demos often end with `exit 0`; details in
  `pdf4tcl-canvas.md`.
- Window items: coordinates are taken before rasterising (fixed in 0.9.4.38).
