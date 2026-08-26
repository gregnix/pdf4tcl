# How-to: form XObjects

## Runnable script

```bash
tclsh doc/en/howtos/howto-xobject.tcl
# PDF -> doc/en/out/
```

Companion: [`howto-xobject.tcl`](howto-xobject.tcl).

## Problem

A letterhead on every page, a stamp, a logo, a form background: the same
drawing over and over. Written out each time it sits in the file as often
as it appears.

A form XObject is drawn once and *placed* as often as needed.

## Recipe

```tcl
set head [$pdf startXObject -paper a4 -margin 40 -orient 1]
# ... draw as on a page ...
$pdf endXObject

foreach page {1 2 3} {
    $pdf startPage
    $pdf putImage $head 0 0
}
```

An XObject is created **between** pages -- `startXObject` ends any page in
progress. Inside it you draw exactly as on a page, and all page settings
apply.

## What it saves, and when

Less than people expect, and only from a certain point:

| pages | shared | repeated |
|---|---|---|
| 3 | 4059 | 3994 |
| 12 | 9769 | 10599 |
| 20 | 10469 | 12428 |

At three pages the shared file is **larger**: the XObject costs an object
of its own, with a dictionary and a length. That is paid back at around
ten repetitions.

So the argument for an XObject is rarely the file size. It is that the
drawing exists once and is changed in one place.

## Structure inside an XObject

Since 0.9.4.46 the content can carry structure, with one condition: the
XObject has to be placed **exactly once**.

```tcl
set intro [$pdf startXObject -paper a4 -margin 40 -orient 1]
$pdf tagBegin P
$pdf text "This paragraph lives inside an XObject." -x 10 -y 15
$pdf tagEnd
$pdf endXObject

$pdf startPage
$pdf putImage $intro 0 40        ;# once
```

The reason is not an oversight in pdf4tcl. The structure tree knows **one**
occurrence of each element, and an XObject may be placed many times: one
tree, several appearances, and nothing says which one the element means.

pdf4tcl does not refuse the second placement -- the file is valid PDF. It
warns at write time:

```
XObject 4 is drawn more than once. Valid PDF, but not PDF/UA: veraPDF
reports rule 7.20-2 once per extra placement, whatever the content is
marked as.
```

**Whatever the content is marked as** -- an artifact placed twice is
counted too. For a conformant document, give each placement its own
XObject.

An XObject keeps its own markers, and pdf4tcl records for each one both the
stream it lives in and the page it appears on -- otherwise a reader could
not tell where content placed twice actually is. See
[`../reference/TAGGED.md`](../reference/TAGGED.md).

## Artifacts

A frame, a rule, a background tint carry no meaning and belong outside the
tree:

```tcl
$pdf tagArtifact
$pdf rectangle 0 0 495 700
$pdf tagArtifactEnd
```

That is the usual case for a letterhead: it is decoration, and a reader
should not announce it on every page.

## Limits

- Placed more than once, an XObject is valid PDF but not PDF/UA -- with
  structure **or** as an artifact.
- The size only pays off from around ten repetitions.
- An XObject cannot contain another XObject.

## See also

- [`howto-tagged.md`](howto-tagged.md) -- structure in the rest of the
  document
- [`../reference/TAGGED.md`](../reference/TAGGED.md) -- what is written
  into the file
- `tests/new-0.9.4.46.test` -- 15 tests for tagging inside XObjects
