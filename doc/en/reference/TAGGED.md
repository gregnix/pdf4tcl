## Merging tagged documents

`pdf4tcl::catPdf` merges the logical structure of the input documents.

`AppendPdf` already renumbers every object of the second document, so its
structure tree arrives intact, just detached. What the merge adds:

* the `/Document` children of the second root are appended to the first
  root's `/K`, and their `/P` is redirected
* the parent tree keys of the second document are shifted by the first
  document's `/ParentTreeNextKey`, in the tree itself and in every
  `/StructParents` on a page and `/StructParent` on an annotation
* the two `/Nums` arrays are merged and sorted, since ISO 32000-1
  clause 7.9.7 requires increasing keys

**MCIDs are deliberately not renumbered.** They are scoped to the content
stream of one page, and merging documents does not merge pages, so an MCID
of 0 in one document never meets an MCID of 0 in the other. Only the parent
tree keys have to be unique across the result. Measured on two two-page
documents, both using keys 0 and 1 before the merge: the result has four
pages with keys 0, 1, 2, 3, two `/Document` subtrees under one root, and
`tools/check-tagged.py` reports the full content of both documents.

Merging is chainable -- three documents give six pages with keys 0 to 5 and
three subtrees.

### When only one side is tagged

| combination | result |
|---|---|
| tagged + tagged | merged, no warning |
| tagged + untagged | first tree kept, warning |
| untagged + tagged | second structure dropped, warning |
| untagged + untagged | nothing to do, no warning |

The third row is the one worth explaining. Adopting the appended tree would
leave the first document's pages outside it, which is the same half state as
the second row but harder to notice, so the structure is dropped instead. In
both mixed cases the result is legal PDF and not PDF/UA conformant, and the
warning says which.

Both mixed cases append a note to `::pdf4tcl::warnings`, so check them after
a merge:

```tcl
set ::pdf4tcl::warnings {}
pdf4tcl::catPdf a.pdf b.pdf out.pdf
foreach w $::pdf4tcl::warnings { puts stderr $w }
```

A merged document keeps its conformance. Measured on two PDF/A-3a documents
that also claim PDF/UA: the result carries `pdfaid 3A`, `pdfuaid:part 1`, one
`pdfaExtension:schemas`, the OutputIntent and the joined structure tree, and
veraPDF passes it under both profiles.

That was not true before 0.9.4.41. The merged file failed PDF/A on a single
rule -- the binary comment in the header had three bytes above 127 where
ISO 19005 clause 6.1.2 requires four, which every reader accepts and no
other check notices. 154 of 155 rules passed.

### Form fields

A form field is an annotation, so it needs a structure element to be reachable
-- `Form` is the type ISO 32000-1 table 337 provides, and PDF/UA clause 7.18.4
requires exactly that nesting:

```tcl
$pdf tagBegin Form -alt "Surname"
$pdf addForm text 100 50 120 16 -id surname
$pdf tagEnd
```

The alternate text satisfies clause 7.18.1, which wants either a `/TU` entry
on the field or an `/Alt` on the enclosing element. With tagging on, pages
carrying annotations also get `/Tabs /S` automatically.

**Check boxes and radio buttons draw their mark with vectors where a
conformance is claimed.** Their appearance streams used to use a glyph from
ZapfDingbats, one of the 14 standard fonts, and clause 7.21.4.1 requires
every font program to be embedded -- which for a standard font is
impossible, so a single check box made the whole document non-conformant.

Since 0.9.4.42 the mark is two strokes and the radio dot four Bezier
segments, needing no font at all. The option `-markstyle` decides:

| value | |
|---|---|
| `auto` (default) | vectors where PDF/UA or a level A conformance is claimed, the glyph otherwise |
| `font` | always the glyph, as before |
| `vector` | always vectors |

The default leaves every existing document looking exactly as it did:
measured, a document without a claim still contains ZapfDingbats, one with
`-ua 1` or `-pdfa 3a` does not. The proportions follow the glyph closely
enough that a form does not visibly change.

### What a merge does not do

Two properties of `catPdf` predate this work and apply to untagged merges as
well, but they matter more once the result is meant to be PDF/UA:

**The metadata of the first document wins.** `catPdf` keeps the first
catalog, so the merged file carries the first document's `dc:title` --
measured, merging "Teil 1" and "Teil 2" gives a document titled "Teil 1".
PDF/UA is satisfied, because *a* title is present and `/DisplayDocTitle` is
set, but a reader announces the wrong one. There is no way to correct it
through `catPdf`, which reads and writes files without a pdf4tcl object. Where
the title matters, either build the whole document in one run instead of
merging, or fix the title afterwards with another tool.

**Embedded fonts are not shared.** Each input keeps its own font program.
Measured: two documents of 24729 bytes, each embedding FreeSans once, merge
into 49296 bytes with two `/FontFile2` objects. Merging twenty chapters
embeds the font twenty times. Nothing is wrong with the result, it is just
larger than it needs to be.

The rest of the catalog -- `AcroForm`, `Metadata` and the other entries --
is not merged either; that carries a TODO in `src/cat.tcl` and predates this
work.

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

Accepted structure types are the standard ones of ISO 32000-1 Table 333-337:

    Document Part Art Sect Div BlockQuote Caption TOC TOCI Index NonStruct
    Private P H H1..H6 L LI Lbl LBody Table TR TH TD THead TBody TFoot Span
    Quote Note Reference BibEntry Code Figure Formula Form

Anything else is refused. A non-standard type would need a `/RoleMap` entry,
and without one a reader silently ignores the element.

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

## Measured

The totals below come from a minimal container without Tk, tkpath, OTF fonts
or Ghostscript, so many tests are skipped there and the numbers are lower
than on a full workstation. What matters is the failure count, which is zero
in every combination; the totals are only comparable within one environment.

Tcl 8.6.14:

- `tests/tagged.test`: 57 cases, all green.
- Full suite `tests/all.tcl`: 851 total, 827 passed, 24 skipped, 0 failed.

Tcl 9.0.4 (built from `core-9-0-4`):

- `tests/tagged.test`: 46 green, 1 skipped.
- Full suite `tests/all.tcl`: 805 total, 792 passed, 13 skipped, 0 failed.
- The skip is `hasAes`. tcllib 1.21 cannot be loaded under Tcl 9 at all: its
  `pkgIndex.tcl` guards with `package vsatisfies [package provide Tcl] 8.5`
  without a trailing dash, which means "same major version" and is therefore
  false under Tcl 9. Measured: `vsatisfies 9.0.4 8.5` is 0, `vsatisfies
  9.0.4 8.5-` is 1. Nothing to do with pdf4tcl; a newer tcllib fixes it.
- `examples/tagged.tcl` produces the same document under both runtimes. The
  files are not byte identical because Tcl 8.6 and Tcl 9 deflate differently,
  but every decompressed content stream compares equal byte for byte.

Both runtimes:

- `examples/tagged.tcl` verified with `tools/check-tagged.py`: all checks
  pass, and the extracted per-element text matches the source, including the
  paragraph spanning the page break and the list and table nesting.
- Tagging combined with `-pdfa 1b`, `2b` and `3a`: `qpdf --check` clean,
  structure tree intact.
- `-userpassword` with `-encversion 4`: `/Alt` does not survive in the clear.
- `tools/check-ascii.tcl`: 54 files OK, 0 failures.

Nagelfar 1.3.x, same two-stage invocation the Makefile uses (generate the
header, then check), against the concatenated `pdf4tcl.tcl`:

| build | messages | distinct kinds |
|---|---|---|
| without this change | 747 | 28 |
| with `src/tagged.tcl` | 776 | 28 |

No new kind of message. The 29 extra ones are all `Unknown variable "pdf"`,
the same artefact `src/encrypt.tcl` already produces 26 times: nagelfar does
not see the class variables through a second `oo::define`. Two genuine false
positives (`dict set attrs`, `dict set props`) are silenced with
`##nagelfar ignore`. Note that the directive applies to the following line
only, not to the enclosing block.

## Checked since 0.9.4.43

`/TD` outside a `/TR` used to be accepted and produced a tree no checker
would like. Both directions are now refused:

| when | what |
|---|---|
| `tagBegin` | `LI` in `L`; `LBody` in `LI`; `THead`, `TBody`, `TFoot` in `Table`; `TR` in `Table`/`THead`/`TBody`/`TFoot`; `TH`, `TD` in `TR`; `TOCI` in `TOC` |
| `tagEnd` | `L` holds an `LI`; `LI` an `LBody`; `Table` a `TR` or a row group; a row group a `TR`; `TR` a `TH` or `TD` |

Only relations the standard fixes without exception are checked; `P`, `Span`,
`Figure` and the rest stay unrestricted. `NonStruct` is transparent in both
directions (clause 14.8.4.2). A refused `tagBegin` leaves no trace, and a
refused `tagEnd` leaves the element open so the missing content can be added.

An element closed with nothing in it at all -- no marked content, no child
element, no annotation -- is reported in `::pdf4tcl::warnings` rather than
refused. The standard permits it; it just designates nothing. `TD` and `TH`
are exempt, since a blank cell belongs in the tree.

## Open

- Untagged content is reported, not prevented. Since 0.9.4.43 pdf4tcl counts
  painting operations that belong to neither an element nor an artifact and
  says so once, at `finish`:

  ```
  tagged: 3 painting operation(s) on 1 page(s) belong to neither a structure
  element nor an artifact. ISO 14289-1 clause 7.1 requires every piece of
  content to be one or the other, so this document does not meet the level
  it claims.
  ```

  Ask before finishing with `[$pdf getUntaggedCount]`. Only painting
  operators count -- setting a colour or a font outside an element is not a
  defect -- and content inside an XObject is covered by the tag on the `Do`
  that places it. Measured: `examples/tagged.tcl` and the pdf4tcllib table
  export both report zero.

  It stays a warning. Untagged content is legal PDF, and a caller who marks
  up part of a page may mean it; only PDF/UA and level A rule it out.
- `/Attributes` covers `/Scope`, `/Headers`, `/ID` and `/ListNumbering`.
  Other attribute owners (`/Layout`, `/PrintField`) are not implemented.
- Structure inside an XObject is still refused. `tagArtifact` works there
  since 0.9.4.43 -- an artifact carries no MCID and therefore needs neither a
  parent tree entry nor `/Stm` in an `/MCR`, which is exactly what structure
  would need. Note that placing an XObject and tagging *that* has always
  worked and covers the whole block:

  ```tcl
  set xo [$pdf startXObject -paper {100p 50p}]
  $pdf text "Logo" -x 5 -y 10
  $pdf endXObject
  $pdf tagBegin Figure -alt "Company logo"
  $pdf putImage $xo 50 700
  $pdf tagEnd
  ```

  What remains impossible is several structure elements *within* one XObject.
  Beyond the bookkeeping, the real obstacle is reuse: an XObject drawn twice
  has one structure tree and two appearances, and where its content sits in
  the reading order is then undecidable.

Since 0.9.4.41 `-pdfa 1a`, `2a` and `3a` are available. They require tagging
and a document language, both checked when the document is finished; a
missing one raises an error rather than writing `pdfaid:conformance A` into a
file that has neither. What is not checked, and what the two entries above
describe, is whether the markup is any good.
- Not checked with a real screen reader. veraPDF verifies that the file obeys
  the standard; it cannot tell whether the tagging is *sensible*. A document
  where every paragraph is `/P` and every heading is `/H1` passes just as
  cleanly as a well structured one.
- Nothing *enforces* tagging. A caller who never calls `tagBegin` gets a
  valid untagged PDF; a caller who tags half the page now gets a warning,
  but the file is still written.

## veraPDF

Measured with veraPDF 1.28.2, profile PDF/UA-1, against `examples/tagged.tcl`.

**Result as of 0.9.4.37: compliant.** 106 rules and 1492 checks passed, none
failed, with a tagged link annotation in the tree. `examples/facturx.tcl`
remains PDF/A-3B compliant alongside it (146 rules, 1226 checks).

Getting there took four rounds:

| round | rules passed | rules failed | checks failed |
|---|---|---|---|
| first run | 99 | 7 | 8 |
| lazy marked content, artifact placement, title, DisplayDocTitle | 105 | 1 | 2 |
| `pdfuaid`, `/Scope`, embedded font | 106 | 0 | 0 |
| annotations added; `/Tabs /S` fixed | 106 | 0 | 0 |

The first run already left the structure tree itself unfaulted -- no complaint
about `/StructTreeRoot`, `/ParentTree`, `/StructParents`, the MCR references
or the roles.

Two of the failures were defects in this module and are fixed:

**Nested MCID.** veraPDF logged 21 warnings of the form
`Content stream (object 4 0 obj): Nested MCID - 4`. `tagBegin` opened marked
content for every element, so a container's MCID enclosed its children's:

    /L    <</MCID 3>> BDC
      /LI   <</MCID 4>> BDC
        /Lbl <</MCID 5>> BDC ... EMC

A grouping element paints nothing and must carry no marked content at all.
Marked content is now opened lazily, at the first painting operation, and
only for the innermost open element -- see `TagEnsureMC`, called from
`Pdfoutcmd` and `BeginTextObj`. An element that is interrupted by a nested
one simply gets a second `/MCR` when painting resumes.

**Artifact inside tagged content** (rules 7.1-1 and 7.1-2). The running foot
on page 2 of the demo was emitted while a paragraph spanning the page break
was still open, so it landed inside that paragraph's marked content.
`tagArtifact` now closes the open sequence first; the artifact sits between
two sequences of the element rather than inside one.

The verifier missed both. It checked `BDC`/`EMC` balance but not whether one
MCID sat inside another, and it had no notion of artifact placement. The
nesting check is now in `tools/check-tagged.py` and reports exactly the same
21 MCIDs veraPDF did.

The remaining failures were addressed one round at a time. Measured against
`examples/tagged.pdf` after each round, same tool and profile:

| round | rules passed | rules failed | checks failed |
|---|---|---|---|
| first run | 99 | 7 | 8 |
| lazy marked content, artifact placement, title, DisplayDocTitle | 105 | 1 | 2 |
| `pdfuaid`, `/Scope`, embedded font | see below | | |

The one remaining failure after the second round was rule 7.21.4.1, font
embedding: the demo still used the base 14 fonts, which have no embeddable
font program. It now loads `examples/FreeSans.ttf`, the same font
`examples/facturx.tcl` uses for PDF/A. Only one weight is available, so the
heading hierarchy is carried by size rather than boldness.

## Fixed along the way

`src/cat.tcl`, `WritePdf`: the last `WriteCh` passed `po` instead of `pos`.
`upvar` creates the variable silently and `incr` initialises it to 0, so the
position counter was updated in a variable nobody reads. Harmless today
because it is the final call, but it would become a data error the moment a
line is added below it.
