# How-to: Markup annotations

## Runnable script

```bash
tclsh 0.9.4.x/doc/en/howtos/howto-annotations.tcl
# PDF -> 0.9.4.x/doc/en/out/
```

Companion: [`howto-annotations.tcl`](howto-annotations.tcl).

Demo: `0.9.4.x/demo/demo-annotations.tcl`

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

Exact option names and defaults: `../pdf4tcl-annotations.md` and the demo.

## Tagged documents

Annotations participate in the structure tree only inside an open
`tagBegin Link` or `tagBegin Annot` … `tagEnd`. Otherwise they stay
clickable but invisible to assistive technology.

Since **0.9.4.39** that case appends a message to `::pdf4tcl::warnings`
(once per document) instead of failing silently. It is still legal PDF; for
PDF/UA wrap the annotation. See `../TAGGED.md`.

## Related

- URL rectangles: `howto-links-and-bookmarks.md`
- Demo pages cover Note / FreeText / Stamp / markup / Line in one PDF.
