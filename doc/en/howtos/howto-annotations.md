# How-to: Markup annotations

## Runnable script

```bash
tclsh doc/en/howtos/howto-annotations.tcl
# PDF -> doc/en/out/
```

Companion: [`howto-annotations.tcl`](howto-annotations.tcl).

Demo: `demo/demo-annotations.tcl`

## Problem

Add sticky notes, stamps, highlights, or a free-text box (beyond hyperlinks).

## Common calls

```tcl
$pdf addAnnotNote 100 100 20 20 -content "Review this" -author "Editor" \
        -icon Comment -color {0.6 0.8 1.0}
$pdf addAnnotFreeText 50 200 200 40 "Always visible" \
        -color {0 0 0} -bgcolor {1 1 0.8}
$pdf addAnnotStamp 300 500 80 30 -name Approved -color {1 0 0}
$pdf addAnnotHighlight 50 300 200 14 -color {1 1 0}
$pdf addAnnotUnderline 50 320 200 14
$pdf addAnnotStrikeOut 50 340 200 14 -color {1 0 0}
$pdf addAnnotLine 50 400 200 400 -color {0 0 0}
```

Exact option names and defaults: `../reference/pdf4tcl-annotations.md` and the demo.

## Not every annotation draws itself

An annotation carries **what** is meant. Whether a viewer can draw it
from that alone depends on the kind:

| Kind | Drawn from |
|---|---|
| Highlight, Underline, StrikeOut | `/QuadPoints` and `/C` -- every viewer |
| FreeText | `/DA` and the colours |
| Note | the viewer's own icon set |
| **Stamp** | the appearance stream only |
| **Line** | the appearance stream only |

A stamp says `/Name /Draft`, and that is a hint at what was meant, not a
drawing (ISO 32000-1 12.5.6.12). Acrobat has artwork for the named
stamps; **PDFium does not, and PDFium is the viewer in Chrome and
Edge.** The same holds for a line: the end points say where, not how.

Since **0.9.4.64** `addAnnotStamp` and `addAnnotLine` write an
appearance stream, so both are visible everywhere. Measured on
`demo/demo-annotations.pdf`: `/AP` appeared **zero** times before and
none of six stamps and five lines was visible in PDFium; now eleven
streams, all visible.

Two consequences worth knowing:

**A stamp needs a font.** Its stream has to name one in `/Resources`, so
it is written only after `setFont`. Without one the annotation is
written as before rather than the call failing.

**Arrow heads** are drawn for `OpenArrow`, `ClosedArrow`, `ROpenArrow`,
`RClosedArrow`, `Circle` and `Square`. Any other ending stays a plain
line -- a line without a head is half an answer, a wrongly drawn head is
a wrong one.

## Tagged documents

Annotations participate in the structure tree only inside an open
`tagBegin Link` or `tagBegin Annot` … `tagEnd`. Otherwise they stay
clickable but invisible to assistive technology.

Since **0.9.4.39** that case appends a message to `::pdf4tcl::warnings`
(once per document) instead of failing silently. It is still legal PDF; for
PDF/UA wrap the annotation. See `../reference/TAGGED.md`.

## Related

- URL rectangles: `howto-links-and-bookmarks.md`
- Demo pages cover Note / FreeText / Stamp / markup / Line in one PDF.
