# How-to: Links and bookmarks

## Runnable script

```bash
tclsh doc/en/howtos/howto-links-and-bookmarks.tcl
# PDF -> doc/en/out/
```

Companion: [`howto-links-and-bookmarks.tcl`](howto-links-and-bookmarks.tcl).

## Problem

Add clickable URLs and an outline (bookmarks) so readers can jump sections.

## Hyperlink

```tcl
# Invisible hit area (common for inline text)
$pdf hyperlinkAdd $x $y $width $height "https://www.tcl.tk"

# Visible border
$pdf hyperlinkAdd 50 160 200 20 "https://github.com/gregnix/pdf4tcl" \
        -borderwidth 1 -bordercolor {0 0 1}
```

Coordinates use the same system as drawing (`-orient`). The rectangle is the
clickable box; it does not draw the label -- paint the text separately.

For **tagged / PDF/UA** documents, wrap the label and the annotation in a
`Link` element or the link stays invisible to assistive technology (since
0.9.4.39 also reported in `::pdf4tcl::warnings`):

```tcl
$pdf tagBegin Link -alt "Tcl home page"
$pdf tagText Span "tcl.tk" -x 50 -y 100
$pdf hyperlinkAdd 50 90 40 14 "https://www.tcl.tk"
$pdf tagEnd
```

Details: `../reference/TAGGED.md`, `../reference/pdf4tcl-annotations.md`.

## Bookmarks

Call after the page exists (bookmark targets the current last page):

```tcl
$pdf startPage
# ... draw chapter 1 ...
$pdf bookmarkAdd -title "Chapter 1" -level 0
$pdf endPage

$pdf startPage
# ... section ...
$pdf bookmarkAdd -title "Section 1.1" -level 1
$pdf endPage
```

`-level` nests the outline. Optional `-closed 1` collapses children by default.
Titles are Latin-1 oriented; prefer ASCII/Latin-1 for outline text.

## See also

- File attachments / embedded files: `addEmbeddedFile`, Factur-X howto
- Internal page links and other annot types: `../reference/pdf4tcl-annotations.md`
