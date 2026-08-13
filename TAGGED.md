# Tagged PDF in pdf4tcl

Status: prototype, added in 0.9.4.36. See `src/tagged.tcl`.

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

An annotation created outside such an element stays unattached. That is the
one case worth being careful about, because it fails quietly: the link still
works when clicked, and no error is raised, but assistive technology cannot
reach it. Nothing is inferred automatically -- guessing which paragraph a
link belongs to would be wrong as often as right. `tools/check-tagged.py`
reports unattached annotations.

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
logical structure. veraPDF would be the tool for actual PDF/UA conformance;
it has not been run against this code yet.

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

Tcl 8.6.14:

- `tests/tagged.test`: 47 cases, all green.
- Full suite `tests/all.tcl`: 887 total, 861 passed, 26 skipped, 0 failed.

Tcl 9.0.4 (built from `core-9-0-4`):

- `tests/tagged.test`: 47 green.
- Full suite `tests/all.tcl`: 841 total, 825 passed, 16 skipped, 0 failed.
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
- Tagging combined with `-pdfa 1b` and `-pdfa 2b`: `qpdf --check` clean,
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

## Merging tagged documents

`pdf4tcl::catPdf` removes the logical structure and appends a note to
`::pdf4tcl::warnings`.

This is not caution, it is a repair. Every page carries a `/StructParents`
key indexing the parent tree of its own document, and every document numbers
its pages from 0. `AppendPdf` keeps the first document's catalog, so the
merged file claimed to be tagged while the second document's pages pointed
into the first document's parent tree. Measured on two one-page documents:
two pages both carrying `/StructParents 0`, a structure tree holding only the
first document's heading, the second document's content orphaned, and no
error raised anywhere.

A file that lies about its structure is worse than one that has none: a
screen reader trusts `/MarkInfo` and reads the wrong tree instead of falling
back to the paint order.

The orphaned `StructElem` objects stay in the file. Removing them would mean
renumbering every object again; unreferenced, they are inert. This is why
`tests/tagged.test` reads the catalog back with `pdf4tcl::cat::ReadPdf`
instead of searching the raw bytes, which would still find their
`/Type /StructTreeRoot`.

Proper merging needs the parent trees remapped and the two `/Document`
subtrees combined under one root. Not implemented.

## Open

- No manual page. `pdf4tcl.man` has no section on tagging yet, so
  `pdf4tcl.n` and `pdf4tcl.html` do not describe the new methods.
- Untagged content stays untagged. That is legal PDF but not PDF/UA
  conformant -- PDF/UA wants every piece of content either tagged or marked
  as an artifact. There is no check for leftover content yet.
- No table validation. `/TD` outside a `/TR` is accepted and produces a tree
  no checker will like. Same for `/LI` outside `/L`.
- `/Attributes` covers `/Scope`, `/Headers`, `/ID` and `/ListNumbering`.
  Other attribute owners (`/Layout`, `/PrintField`) are not implemented.
- Tagging inside an XObject (`startPage -xobject 1`) is refused rather than
  supported.
- `catPdf` discards structure rather than merging it, see above.
- Not checked with a real screen reader. veraPDF verifies that the file obeys
  the standard; it cannot tell whether the tagging is *sensible*. A document
  where every paragraph is `/P` and every heading is `/H1` passes just as
  cleanly as a well structured one.
- Nothing enforces that content is tagged in the first place. A caller who
  never calls `tagBegin` gets a valid untagged PDF, and a caller who tags
  only half the page gets a file that validates but reads badly.

## veraPDF

Measured with veraPDF 1.28.2, profile PDF/UA-1, against `examples/tagged.tcl`:
99 rules passed, 7 failed, 1382 checks passed, 8 failed. The structure tree
itself was not faulted -- no complaint about `/StructTreeRoot`, `/ParentTree`,
`/StructParents`, the MCR references or the roles.

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
