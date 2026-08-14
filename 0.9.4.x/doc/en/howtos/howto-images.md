# How-to: Images (PNG / JPEG / TIFF)

## Runnable script

```bash
tclsh 0.9.4.x/doc/en/howtos/howto-images.tcl
# PDF -> 0.9.4.x/doc/en/out/
```

Companion: [`howto-images.tcl`](howto-images.tcl).

Demos: `demo-interlaced-png.tcl`, guide `../pdf4tcl-images.md`

## Problem

Place a raster image on the page.

## Recipe

```tcl
set id [$pdf addImage /path/to/photo.png]
# or: $pdf addImage $path -id logo
$pdf putImage $id 50 100 -width 200
# height follows aspect ratio unless -height is given
```

JPEG and many PNG/TIFF variants are supported. Since **0.9.4.28**, Adam7
**interlaced PNG** works (de-interlaced on embed). Sub-8-bit interlaced PNG
is still refused with a clear error.

## Raw path

Unsupported formats: load via Tk/Img, then `addRawImage` / `putRawImage`
(see the images guide).

## Tagged / PDF/UA

Figures need a structure element with `-alt`:

```tcl
$pdf tagBegin Figure -alt "Company logo"
$pdf putImage $id 50 100 -width 120
$pdf tagEnd
```
