# Annotations, links and document level features

This document covers everything that sits *beside* the painted page: links,
annotations, attached files, page labels and viewer preferences. The manual
page lists every option of every method; this one shows what to reach for and
what the traps are.

Every example here was run against 0.9.4.37 and the resulting PDF inspected.

---

## Two kinds of attachment

pdf4tcl has two mechanisms for embedding a file, and they are not
interchangeable.

`embedFile` puts the data into the PDF stream and returns an id. That id is
what `attachFile` needs to place a visible paperclip icon on a page:

```tcl
set fid [$pdf embedFile data.csv]
$pdf attachFile 400 20 20 20 $fid "Measurement data"
```

`addEmbeddedFile` attaches the file to the *document* through the catalog
name tree, without any annotation on any page:

```tcl
$pdf addEmbeddedFile factur-x.xml -description "Invoice data"
```

This is the mechanism electronic invoices require (ZUGFeRD, Factur-X), and
`examples/facturx.tcl` uses it.

The trap: the value returned by `addEmbeddedFile` is **not** an `fid` for
`attachFile`. Passing it produces

    can't read "files()": no such element in array

Use `embedFile` when a page should show the attachment, `addEmbeddedFile`
when the document should carry it invisibly. Both in the same document is
fine.

---

## Links

```tcl
$pdf text "More on the" -x 0 -y 20
$pdf hyperlinkAdd 40 12 60 14 "https://example.org"
```

`hyperlinkAdd` takes a rectangle, not a text range: it does not know where
the text is. Position it yourself around the words it should cover, and
remember that with the default `-orient 1` the `y` you pass is the **top**
edge of the clickable area.

In a tagged document a link needs to be wrapped in a `Link` element, or
assistive technology cannot reach it even though clicking works:

```tcl
$pdf tagBegin Link -alt "Example site"
$pdf tagText Span "example.org" -x 40 -y 20
$pdf hyperlinkAdd 40 12 60 14 "https://example.org"
$pdf tagEnd
```

See `TAGGED.md` for what that produces and why nothing is inferred
automatically.

---

## Annotation types

All seven produce a real annotation object; verified in the output of a
single test document:

| Method | `/Subtype` | Visible without clicking |
|---|---|---|
| `addAnnotNote` | `/Text` | icon only, popup on click |
| `addAnnotFreeText` | `/FreeText` | yes |
| `addAnnotHighlight` | `/Highlight` | yes |
| `addAnnotUnderline` | `/Underline` | yes |
| `addAnnotStrikeOut` | `/StrikeOut` | yes |
| `addAnnotStamp` | `/Stamp` | yes |
| `addAnnotLine` | `/Line` | yes |

```tcl
$pdf addAnnotNote 300 20 20 20 -content "Check this" -author "greg" \
        -icon Comment
$pdf addAnnotFreeText 0 60 200 30 "Visible remark" -fontsize 9
$pdf addAnnotHighlight 0 110 120 14 -color {1 1 0}
$pdf addAnnotLine 0 150 200 150 -color {0 0 1}
```

`addAnnotNote` is the one to be careful with: popup behaviour differs between
viewers, some keep it open, some show no close button. Where the remark must
be readable everywhere, `addAnnotFreeText` is the safer choice.

The markup annotations (`Highlight`, `Underline`, `StrikeOut`) take a
rectangle as well, not a text range. They do not follow the text if the
layout changes.

---

## Page labels

A viewer normally shows the sheet number. Page labels let it show what is
printed on the page instead -- roman numerals for a preface, decimal numbers
for the body:

```tcl
$pdf pageLabel 0 -style R -prefix "" -start 1     ;# I, II, III ...
$pdf pageLabel 4 -style D -start 1                ;# 1, 2, 3 ...
$pdf pageLabel 40 -style D -prefix "App-" -start 1 ;# App-1, App-2 ...
```

`pageIndex` is zero based and marks where a range *starts*; a range runs
until the next one begins.

`-style` takes a single letter, not a word: `D` decimal, `r` roman
lowercase, `R` roman uppercase, `a` alpha lowercase, `A` alpha uppercase, or
the empty string for a prefix without a number. Passing `decimal` raises an
error.

---

## Viewer preferences

```tcl
$pdf viewerPreferences -displaydoctitle 1
```

`-displaydoctitle 1` makes a reader announce the document title from the
metadata rather than the file name. PDF/UA requires it (ISO 14289-1
clause 7.1-10), and it needs a title to announce:

```tcl
$pdf metadata -title "Quarterly report" -author "..." -subject "..."
```

Note that this is a method of its own -- `configure -displaydoctitle` does
not exist.

---

## Merging documents

`pdf4tcl::catPdf in1.pdf in2.pdf ... out.pdf` concatenates existing files.

If any input is tagged, the logical structure is **removed** from the result
and a note appended to `::pdf4tcl::warnings`. That is deliberate: every page
carries a `/StructParents` key indexing the parent tree of its own document,
and every document numbers its pages from zero, so keeping the structure
would leave pages resolving to the wrong elements. A file that misreports its
structure is worse than one without any, because a reader trusts `/MarkInfo`
and follows the wrong tree instead of the paint order.

Always check the warnings after a merge:

```tcl
set ::pdf4tcl::warnings {}
pdf4tcl::catPdf a.pdf b.pdf out.pdf
foreach w $::pdf4tcl::warnings { puts stderr $w }
```

---

## What to check in the result

`tools/check-tagged.py` verifies annotations against the structure tree of a
tagged document: every annotation claimed by exactly one `/OBJR`, its
`/StructParent` resolving back to that element, link annotations carrying
`/Contents`, and `/Tabs /S` on pages with annotations.

For anything else, `qpdf --check` catches syntax and stream errors, and
veraPDF checks conformance against a profile:

```bash
qpdf --check out.pdf
verapdf -f ua1 out.pdf      # PDF/UA-1
verapdf -f 3b out.pdf       # PDF/A-3B
```

---

## See also

- `pdf4tcl-forms-manual.md` -- interactive form fields, which are annotations
  too but have their own API
- `TAGGED.md` -- logical structure, and how annotations join it
- `pdf4tcl-basics.md` -- the coordinate system and `-orient`, which every
  rectangle on this page depends on
