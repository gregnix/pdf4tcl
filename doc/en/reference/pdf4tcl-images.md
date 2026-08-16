# Images

Everything measured here was run against 0.9.4.37 with the sample files that
ship with the fork.

---

## Which formats load directly

`addImage` reads a file from disk and returns an id:

```tcl
set id [$pdf addImage examples/smile.png]
```

Measured against the files in this repository:

| file | result |
|---|---|
| `examples/tcl.jpg` | loads, 51x75 |
| `examples/smile.png` | loads, 100x83 |
| `tests/images/logo125.gif` | `unknown image type` |
| `bitmaps/info.xbm` | `unknown image type` |

So: **JPEG and PNG only**, and not every variant of those -- the manual page
says "some JPEG, some PNG, and some TIFF formats", which is honest. A file
that the format reader does not understand raises an error rather than
producing a broken page, so a failure is visible immediately.

For anything else, go through Tk. `image create photo` reads GIF and, with
the `Img` package, most other formats; `addRawImage` takes the pixel data:

```tcl
package require Tk
set im [image create photo -file logo.gif]
set id [$pdf addRawImage [$im data]]
image delete $im
```

`$im data` produces a list of rows of colour names, so this route costs
memory and time proportional to the pixel count. It is the fallback, not the
default.

`putRawImage` does both steps at once for an image used only once:

```tcl
$pdf putRawImage [$im data] $x $y -width 90
```

It takes the same placement options as `putImage`. Use `addRawImage` plus
`putImage` whenever the same data appears more than once -- `putRawImage`
embeds it again on every call.

---

## Size and placement

`putImage` draws a loaded image on the current page:

```tcl
$pdf putImage $id $x $y
```

Measured with `smile.png` (100x83 pixels), reading the resulting `cm`
operators out of the content stream:

| call | drawn size |
|---|---|
| `putImage $id 0 0` | 100 x 83 |
| `putImage $id 0 100 -width 200` | 200 x 166 |
| `putImage $id 0 200 -width 200 -height 50` | 200 x 50 |

Three rules follow:

1. Without options, **one pixel becomes one point**. A 3000 pixel wide photo
   is drawn 3000 points wide, which is about four A4 sheets. Always give a
   size for anything coming from a camera.
2. Giving only `-width` or only `-height` scales the other side
   proportionally.
3. Giving both honours both and distorts the image. That is occasionally what
   you want; usually it is a bug.

`getImageSize` returns width and height in pixels, which is what you need to
compute a fit:

```tcl
lassign [$pdf getImageSize $id] w h
set scale [expr {min($maxW / double($w), $maxH / double($h))}]
$pdf putImage $id $x $y -width [expr {$w * $scale}]
```

`getImageWidth` and `getImageHeight` return the two values separately.

---

## Load once, place often

`addImage` puts the data into the PDF once and returns an id. Every
`putImage` with that id is a reference, not another copy:

```tcl
set logo [$pdf addImage logo.png]
foreach page $pages {
    $pdf startPage
    $pdf putImage $logo 0 0 -width 80
}
```

Calling `addImage` inside the loop instead would embed the file once per
page. With a 200 KB logo and 50 pages that is 10 MB of duplicated data, and
nothing warns about it.

---

## The coordinate trap

`putImage` places the image by its **upper left** corner under the default
`-orient 1`, in the same coordinate system as everything else: `y` counts
downward from the top margin. See `pdf4tcl-basics.md` if that is not already
familiar -- it is the single most common source of pages that look right in
the code and wrong on screen.

---

## See also

- `pdf4tcl-basics.md` -- the coordinate system every placement depends on
- `pdf4tcl-canvas.md` -- exporting a Tk canvas, which embeds images among
  everything else
- `demo/demo-interlaced-png.tcl` -- interlaced PNG handling
