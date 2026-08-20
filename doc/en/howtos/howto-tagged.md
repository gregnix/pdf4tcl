# How-to: tagged PDF

## Runnable script

```bash
tclsh doc/en/howtos/howto-tagged.tcl
# PDF -> doc/en/out/
```

Companion: [`howto-tagged.tcl`](howto-tagged.tcl).

## Problem

A PDF is a set of drawing instructions. "Revenue" in bold at the top of a
page looks like a heading, but nothing in the file says it is one -- a
screen reader finds text at coordinates and reads it in the order it was
drawn, which is not necessarily the order it should be read in.

Tagging adds a second layer: a tree that says *this is a heading, that is
a table, this rule is decoration*. The page looks the same; what changes
is what a reader can do with it.

## Recipe

Four calls, before the first page:

```tcl
$pdf tagged 1 -lang en-GB -ua 1
$pdf metadata -title "Quarterly report" -author "pdf4tcl"
$pdf viewerPreferences -displaydoctitle 1
$pdf startPage
```

`tagged 1` has to come **before** the first `startPage`, or the content of
that page has nowhere to go. `-lang` is not optional for PDF/UA: a reader
has to know which language to pronounce. `-displaydoctitle 1` makes the
viewer show the title rather than the file name.

Then wrap what is drawn:

```tcl
$pdf tagText H1 "Quarterly report" -x 0 -y 40
$pdf tagText P  "Sales rose in every region." -x 0 -y 80
```

`tagText` is one element, one draw. Where several draws belong together:

```tcl
$pdf tagBegin P
$pdf text "A paragraph can be drawn in pieces --" -x 0 -y 110
$pdf text "they still form one element." -x 0 -y 126
$pdf tagEnd
```

## Tables

This is where tagging earns its keep. Without it a table is a grid of
text at coordinates; with it a reader can say "row 3, Revenue column".

```tcl
$pdf tagBegin Table
$pdf tagBegin TR
foreach {head x} {Region 0 Revenue 150 Change 260} {
    $pdf tagText TH $head -scope Column -x $x -y 170
}
$pdf tagEnd
# ... TR/TD rows ...
$pdf tagEnd
```

`-scope Column` on a `TH` says the heading applies down the column, not
across the row. A reader uses it to announce the right heading with each
cell.

The nesting is checked: a `TD` outside a `TR`, or a `TR` outside a
`Table`, is refused rather than written into the tree. ISO 32000-1 tables
335 and 337 fix which element may sit where; no validator reports a
violation and no reader repairs it, so the check happens here.

## Decoration is not content

A rule, a frame, a background tint carry no meaning. Marked as artifacts
they stay out of the tree -- and out of what a reader announces:

```tcl
$pdf tagArtifact
$pdf line 0 260 400 260
$pdf tagArtifactEnd
```

An image is the opposite: it is content, and it needs a description.

```tcl
$pdf tagBegin Figure -alt "Bar chart: revenue by region, North highest"
# ... draw it ...
$pdf tagEnd
```

Without `-alt` a reader announces "graphic" and moves on. The text should
say what the picture *shows*, not that it is a picture.

## What was left out?

This is the part people miss. Content drawn while tagging is on, without
being wrapped in either an element or an artifact, is unreachable -- and
it is **counted, not refused**:

```tcl
set untagged [$pdf getUntaggedCount]
```

Anything above zero means part of the document cannot be read. ISO 14289-1
clause 7.1 wants every painting operation to be one or the other, so such
a file fails veraPDF -- measured, at exactly that clause.

A warning is also appended to `::pdf4tcl::warnings` at `write` time, but
only a caller who reads the list will see it.

`getUntaggedCount` says **how many**, not **where**. Narrowing it down
means commenting out draws until the number moves.

## Fonts

PDF/UA needs every font programme embedded, and the fourteen standard
faces have none. A tagged document set in Helvetica claims a level it
cannot keep -- pdf4tcl warns, and veraPDF fails it:

```tcl
pdf4tcl::loadBaseTrueTypeFont BaseTag $font
pdf4tcl::createFontSpecCID BaseTag Body
```

## Checking the result

```bash
verapdf -f ua1 doc/en/out/howto-tagged.pdf
```

The script's output passes. What veraPDF cannot tell you is whether the
tree makes *sense* -- whether the headings are in the right order, whether
the alt text describes the picture. For that, `structure-dump.tcl` in
tclpdfium prints the tree with the text beside it, and beyond that only a
person with a screen reader can say.

## Limits

- Structure inside a form XObject works since 0.9.4.46, but an XObject
  drawn twice has one tree and two appearances. `tagBegin` is refused
  there; `tagArtifact` is allowed.
- `getUntaggedCount` counts, it does not locate.
- No test with a real screen reader has been done.

## See also

- [`../reference/TAGGED.md`](../reference/TAGGED.md) -- what is written
  into the file, and why
- [`howto-pdfa.md`](howto-pdfa.md) -- PDF/A-3a combines both
- [`howto-validate.md`](howto-validate.md) -- veraPDF and qpdf
- `tests/tagged.test` -- 64 tests
