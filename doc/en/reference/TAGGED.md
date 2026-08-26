# Tagged PDF in pdf4tcl

Added in 0.9.4.36, extended with annotation support in 0.9.4.37.
See `src/tagged.tcl`.

`examples/tagged.tcl` validates as PDF/UA-1 conformant with veraPDF 1.28.2.
That says the file obeys the standard, not that the tagging is sensible --
see the Open section at the end.

## What a tagged PDF is

An ordinary PDF records only where glyphs are painted. Nothing in the file
says which run of glyphs is a heading, a paragraph, a table cell or a page
number, and the reading order is whatever order the content stream happens to
use -- which is wrong as soon as the page has more than one column.

A tagged PDF adds a tree of structure elements next to the content:

    /StructTreeRoot
      /Document
        /H1   -> marked content 0 on page 1
        /P    -> marked content 1 on page 1, marked content 0 on page 2
        /Figure  /Alt (Red square next to a blue circle)

The link between tree and content is the marked content operator pair
`BDC ... EMC` carrying an `/MCID`, plus `/StructParents` on the page and a
`/ParentTree` that maps the pair (page, MCID) back to the owning element.

This matters for:

1. Accessibility. A screen reader walks the tree, not the paint order.
   Required by PDF/UA (ISO 14289) and, in the EU, by EN 301 549 / BITV 2.0
   for public bodies.
2. Reliable text extraction and copy/paste in the intended order.
3. Reflow on small screens.
4. Structure preserving export to HTML or Word.

Tagged is not the same as accessible: a file where everything is `/P` is
formally tagged and practically useless. Tagged is also independent of
PDF/A -- PDF/A-1a and -2a/-3a require tags, the `b` levels do not.

## API

    $pdf tagged 1 ?-lang de-DE? ?-ua 1?

Enable tagging. Must be called before the first `tagBegin`. Raises the PDF
version to 1.4. Without any `tagBegin` no structure tree is written at all.

`-ua 1` writes the PDF/UA identification schema (`pdfuaid:part`) into the XMP
packet. It is opt-in on purpose: that entry asserts conformance, and nothing
in pdf4tcl can verify it. Embedded fonts, a document title, complete tagging
of every piece of content and a sane heading order are the caller's
responsibility. A file that claims PDF/UA and then fails veraPDF is worse
than one that claims nothing.

    $pdf tagBegin type ?-alt text? ?-actualtext text? ?-title text? ?-lang tag?
                       ?-scope Row|Column|Both? ?-id name? ?-headers list?
                       ?-colspan n? ?-rowspan n? ?-summary text?
                       ?-listnumbering style?
    $pdf tagEnd

Open and close a structure element. Everything painted in between belongs to
it. Elements nest; the nesting of `tagBegin`/`tagEnd` is the nesting of the
tree.

- `-alt` replaces the content for a screen reader. The only thing that makes
  a `/Figure` readable at all.
- `-actualtext` replaces the content for text extraction, e.g. for a ligature
  drawn as one glyph.
- `-title` becomes `/T`, a human readable label.
- `-lang` marks a passage in another language than the document.
- `-scope` applies to `TH` only and becomes an `/A <</O /Table /Scope ...>>`
  dictionary. ISO 14289-1 clause 7.5 requires it wherever the relation
  between a header cell and its data cells cannot be derived algorithmically.
- `-id` names a table cell, `-headers` lists the `-id`s of the header cells
  that apply to it. `-headers` is what works for irregular tables, where
  `-scope` alone cannot express the relation.
- `-colspan` and `-rowspan` apply to `TH` and `TD` and give the number of
  columns or rows the cell spans. A value of 1 is the default and is not
  written.
- `-summary` applies to `Table` and becomes `/Summary`: what the table is
  for and how it is built, meant for speech or braille. A reader announces
  it before the cells.
- `-listnumbering` applies to `L` only and becomes
  `/A <</O /List /ListNumbering ...>>`, so a reader can announce the list
  style instead of reading the painted bullet glyph.

    $pdf tagText type str ?tag options? ?text options?

Convenience for a single `text` call. Options are split by name: `-alt`,
`-actualtext`, `-title` and `-lang` go to `tagBegin`, everything else to
`text`.

    $pdf tagArtifact ?-type Pagination|Layout|Page|Background? ?-subtype Header|Footer|Watermark?
    $pdf tagArtifactEnd

Mark content that is not part of the document: running heads, page numbers,
rules, background decoration. Artifacts carry no MCID and are skipped by
assistive technology.

The types `tagBegin` accepts are listed in `src/tagged.tcl`, variable
`StdStructTypes` -- that list is what the check runs against, so it is the
one to read. It covers the standard structure types of ISO 32000-1.

Anything outside it is refused. A non-standard type would need a `/RoleMap`
entry, and without one a reader silently ignores the element.

## Example

    package require pdf4tcl
    set pdf [pdf4tcl::new %AUTO% -paper a4]
    $pdf tagged 1 -lang de-DE
    $pdf startPage

    $pdf tagArtifact -type Pagination -subtype Footer
    $pdf setFont 8 Helvetica
    $pdf text "Seite 1" -x 500 -y 40
    $pdf tagArtifactEnd

    $pdf setFont 18 Helvetica-Bold
    $pdf tagText H1 "Kapitel 1" -x 50 -y 780

    $pdf setFont 11 Helvetica
    $pdf tagBegin P
    $pdf text "Erste Zeile" -x 50 -y 750
    $pdf text "Zweite Zeile desselben Absatzes" -x 50 -y 735
    $pdf tagEnd

    $pdf tagBegin Figure -alt "Rotes Quadrat"
    $pdf setFillColor 0.8 0.1 0.1
    $pdf rectangle 50 600 60 60 -filled 1
    $pdf tagEnd

    $pdf write -file tagged.pdf
    $pdf destroy

A larger example is `examples/tagged.tcl` (headings, list, table, figure,
artifacts, and a paragraph spanning a page break).

## Annotations

Links from `hyperlinkAdd`, fields from `addForm` and the `addAnnot...` family
are attached to the structure tree only when they are created while a `Link`
or `Annot` element is open:

    $pdf tagBegin P
    $pdf text "Mehr dazu auf der" -x 50 -y 700
    $pdf tagBegin Link -alt "pdf4tcl project page"
    $pdf tagText Span "Projektseite" -x 155 -y 700
    $pdf hyperlinkAdd 155 698 65 14 "https://github.com/gregnix/pdf4tcl"
    $pdf tagEnd
    $pdf tagEnd

The element then gets an `/OBJR` entry and the annotation a `/StructParent`
key pointing back (ISO 32000-1 clause 14.7.4.4). PDF/UA also wants the
annotation itself to carry `/Contents`, since that is what a reader
announces; it is filled from the element's `-alt` when the annotation has
none, and an explicit `/Contents` always wins.

While tagging is on, a page carrying annotations is written with `/Tabs /S`
rather than `/Tabs /R`, so that tabbing follows the structure tree
(ISO 14289-1 clause 7.18.3). Untagged documents keep `/R`, which is what a
plain form wants.

An annotation created outside such an element stays unattached: the link
still works when clicked, but assistive technology cannot reach it and
PDF/UA rule 7.18 cannot be met. Since 0.9.4.39 this is reported in
`::pdf4tcl::warnings`, once per document:

    tagged: an annotation was created while the open element is /P, so it is
    not part of the structure tree and assistive technology cannot reach it.
    Wrap it in "tagBegin Link -alt ..." ... "tagEnd".

A warning rather than an error, because an untagged annotation is legal PDF
and existing code may rely on it. Nothing is inferred automatically --
guessing which paragraph a link belongs to would be wrong as often as right.
`tools/check-tagged.py` reports the same case when checking a finished file.

So check the warnings after generating a tagged document:

```tcl
set ::pdf4tcl::warnings {}
...
foreach w $::pdf4tcl::warnings { puts stderr $w }
```

Every annotation now goes through `AddAnnot` in `src/main.tcl` rather than
`AddObject`, which is what gives the tagging module a chance to see it. A new
kind of annotation added later must use `AddAnnot` too, or it will silently
be missing from the structure tree.

## Coordinates in the examples

`pdf4tcl` defaults to `-orient 1`: y counts downward from the top margin and
x rightward from the left margin, so `(0,0)` is the top left corner of the
drawable area and the margins are already included.

The first version of `examples/tagged.tcl` was written as if the origin were
at the bottom left, with the heading at `y 780` and the running foot at
`y 40`. Measured afterwards, the heading sat 12 points above the bottom edge,
the foot at the top, and the page read from bottom to top. The x coordinates
were off by the margin as well, because it was added a second time.

veraPDF called that file PDF/UA-1 compliant. It validates the structure tree,
not the layout, and the structure tree really was correct -- the reading
order a screen reader follows comes from the tree, not from where the glyphs
landed. This is the clearest example of the point made further down: a green
validator run says the file obeys the standard, not that it is any good.

## Checking the result

### What was left untagged

    set open [$pdf getUntaggedCount]

Content painted while tagging is on, belonging to neither an element nor an
artifact, is **counted, not refused**. Anything above zero means part of the
document cannot be reached by a reader, and ISO 14289-1 clause 7.1 requires
every piece of content to be one or the other.

Only painting operators count -- setting a colour or a font outside an
element is not a defect. Since 0.9.4.46 content inside an XObject counts as
well.

It stays a warning rather than an error: untagged content is legal PDF, and
a caller who marks up only part of a page may mean it. Only PDF/UA and the
PDF/A a-levels rule it out.

`finish` also puts a message into `$::pdf4tcl::warnings` -- but only a caller
who reads that list will see it. **`getUntaggedCount` tells you how much, not
where.** Narrowing it down means commenting out drawing calls until the
number moves.

### The structure checker


    python3 tools/check-tagged.py tagged.pdf

The script walks the structure tree, reconstructs for every element the text
its marked content actually paints, and checks the consistency rules a broken
generator gets wrong:

- `BDC`/`EMC` balance in every content stream
- no MCID nested inside another MCID
- MCIDs numbered from 0 without gaps on each page
- `/StructParents` present on every page carrying an MCID
- `/StructParents` keys unique across pages
- the `/ParentTree` covering every MCID
- every marked content sequence claimed by exactly one structure element
- every annotation claimed by exactly one `/OBJR`, its `/StructParent`
  resolving back to that element, and link annotations carrying `/Contents`

The last two checks were added after the fact. The first version verified
everything per page, and the broken `catPdf` merge passed it cleanly: both
pages carried `/StructParents 0`, both resolved to the same parent tree
entry, and that entry happened to hold exactly one element, so the per-page
count matched. A verifier that only ever looks at one page at a time cannot
see a collision between pages.

Needs `pypdf`.

`qpdf --check` catches syntax and stream errors but knows nothing about
logical structure. veraPDF is the tool for actual PDF/UA conformance; see the
veraPDF section below for what it found and what it still does not cover.

## Implementation notes

`src/tagged.tcl` is concatenated into `pdf4tcl.tcl` by the Makefile, after
`src/encrypt.tcl`. It reopens the class with a second `oo::define`, the same
way `src/encrypt.tcl` does.

Two traps in that file worth repeating:

- It must not contain a `variable` declaration. `oo::define ... variable`
  replaces the class variable list rather than extending it, so declaring
  only `pdf` there would hide `options`, `fonts`, `images` and the rest from
  every method of the class.
- TclOO exports a method only when its name starts with a lowercase letter.
  The public API is therefore `tagBegin`, `tagEnd` ...; the hooks called from
  `main.tcl` are `TagPageStart`, `TagPageEnd` ... and stay private without an
  explicit `unexport`.

All state lives in the `pdf()` array, because `finish -dryRun` saves and
restores exactly that array.

`main.tcl` calls into the module in five places, each a single line that
returns immediately when tagging is off:

| Location | Hook | Purpose |
|---|---|---|
| end of `startPage`, after `Flush` | `TagPageStart` | reopen marked content across a page break |
| start of `endPage` | `TagPageEnd` | close marked content before the stream ends |
| page dictionary in `endPage` | `TagPageDict` | `/StructParents` |
| catalog in `finish` | `TagCatalogEntries` | `/StructTreeRoot`, `/MarkInfo`, `/Lang` |
| `finish`, before the last `FlushObjects` | `TagWriteObjects` | structure elements, parent tree, root |

`src/main.tcl` also defines all six as no-ops, before the real ones in
`src/tagged.tcl` override them. Without that, a build whose CATFILES does not
include `src/tagged.tcl` -- or an older installed copy of the package
shadowing the freshly built one -- fails at the first `startPage` with
`unknown method "TagPageStart"` followed by every method the class does have,
which says nothing about the cause. This is not a silent fallback: if
`tagged.tcl` is missing then so is the `tagged` method, tagging cannot have
been switched on, and doing nothing is the correct behaviour. Covered by test
`tagged-11.1`.

The position of the first hook matters. `Flush` at the end of `startPage`
writes uncompressed, while `endPage` deflates whatever is still buffered and
derives `/Length` from that. Writing the reopened `BDC` before that `Flush`
put a few raw bytes in front of the deflate stream: the page inflated to
nothing, every reader showed it as empty, and no error was raised anywhere.
Covered by test `tagged-8.1a`.

`/Alt` and the other text strings are written as UTF-16BE literal strings
with octal escapes, not as hex strings. `EncryptStringsInBody` only rewrites
`(...)` literals, so a hex string would stay in the clear in an encrypted
document. `pdf4tcl::QuoteString` is deliberately not used: it transliterates
code points above U+00FF and replaces the rest with `?`, which is acceptable
for a bookmark title but not for the only text a screen reader gets.

## Table attributes

What `tagBegin` writes for a table, and where the rule lives:

| Option | Entry | Applies to |
|---|---|---|
| `-rowspan` | `/RowSpan` | `TH`, `TD` |
| `-colspan` | `/ColSpan` | `TH`, `TD` |
| `-headers` | `/Headers` | `TH`, `TD` |
| `-scope` | `/Scope` | `TH` |
| `-summary` | `/Summary` | `Table` |

The table attributes are specified in ISO 32000-1, clause 14.8.5.7.

### Why the spans matter

Without them a heading spanning two columns looks like a single cell in the
tree. A reader then names the wrong heading for everything under the second
column -- and **no validator reports it**, because the tree is well formed;
it simply does not describe the table on the page.

Clause 14.8.4.3.4 explains why the attributes exist at all: without them a
reader has to work the association out for itself, and that guesswork is
what fails on an irregular table.

```tcl
$pdf tagBegin Table -summary "Revenue by region, three rows"
$pdf tagBegin TR
$pdf tagText TH "Revenue" -colspan 2 -scope Column -x 200 -y 60
$pdf tagEnd
$pdf tagBegin TR
$pdf tagText TD "North" -rowspan 2 -x 50 -y 80
$pdf tagText TD "12400" -x 200 -y 80
$pdf tagEnd
$pdf tagEnd
```

Measured: veraPDF passes this as PDF/UA-1.


---

## Merging tagged documents

`pdf4tcl::catPdf` merges the logical structure of the input documents: the
second document's tree is appended to the first, its parent-tree keys are
renumbered, and page and annotation references follow. The result validates
as PDF/UA-1.

How that is done is in `src/cat.tcl`, at the procedures that do it; for
using `catPdf` see
[`../howtos/howto-catpdf.md`](../howtos/howto-catpdf.md).

Three things are worth knowing before you rely on it.

**When only one side is tagged**, the untagged pages end up outside the
tree. `getUntaggedCount` on the merged file says how much, and a document
that claims PDF/UA will fail on it -- correctly, because part of it cannot
be reached.

**Form fields need a `Form` element** to be reachable at all; the field on
its own is an annotation, not content. `-alt` on the element, or `/TU` on
the field, gives the reader something to announce.

**The metadata of the first document wins.** `catPdf -title` sets the title
of the result in both `/Info` and the XMP packet; everything else --
author, subject, keywords -- comes from the first input.

Embedded font programs are shared between the merged documents where they
are identical, so merging two documents that use the same face does not
embed it twice.
