# How-to: Merge PDFs (`catPdf`) including tagged structure

## Runnable script

```bash
tclsh doc/en/howtos/howto-catpdf.tcl
# PDF -> doc/en/out/
```

Companion: [`howto-catpdf.tcl`](howto-catpdf.tcl).

Guide: `../reference/TAGGED.md`, `../reference/pdf4tcl-annotations.md`  
Since **0.9.4.40** structure trees are merged instead of dropped.

## Problem

Concatenate several PDFs into one without losing logical structure.

## Recipe

```tcl
package require pdf4tcl 0.9
pdf4tcl::catPdf part1.pdf part2.pdf combined.pdf
```

Both inputs tagged → one `/StructTreeRoot`, parent-tree keys of the second
document shifted, `/Document` children joined. MCIDs stay per page (not
renumbered).

```bash
python3 tools/check-tagged.py combined.pdf
verapdf -f ua1 combined.pdf   ;# if the parts were UA-oriented
```

## Mixed tagged / untagged

Cannot be merged cleanly. pdf4tcl keeps a valid PDF and appends a note to
`::pdf4tcl::warnings`:

- tagged + untagged → later pages outside the tree
- untagged + tagged → structure of the second document is dropped

Prefer tagging all parts the same way before merging.

## Interactive forms (since 0.9.4.44)

`/Fields` is the union of all inputs, so a merged document keeps every field.
Before 0.9.4.44 only the first document's `/AcroForm` survived: the other
documents' widgets sat on their pages, fully formed, and no reader offered
them for filling — `pdftk dump_data_fields` reported one field where two had
gone in.

**Field names are not made unique.** Two fields of the same name are one
field with one shared value (ISO 32000-1 clause 12.7.3.2). That is sometimes
what you want, and renaming would break the `/T` reference in any JavaScript
shipped with the document. The collision is reported instead:

```
catPdf: form field name(s) appear in both documents and will act as one
field with one shared value: name
```

Check `::pdf4tcl::warnings` after merging if that matters to you.

## Limits that still apply

- **First catalog wins** — title and `/Metadata` of `part1` remain; set them
  on the first file if the combined title must change.
- **Font dictionaries stay duplicated.** The embedded font *streams* are
  shared where they are byte-identical: measured on two documents using the
  same CID font, 772348 bytes of input produced 387881 in the merge. The
  dictionaries around them differ after renumbering, which costs a few
  hundred bytes per font.
- The catalog and pages objects of the appended documents remain in the file
  as dead objects. Nothing references them; they cost about 100 bytes each.
- Untagged-only merges behave as before.

## Upgrade note

Code written against 0.9.4.36–0.9.4.39 that expected structure to disappear
now gets a tagged result. See `../reference/UPGRADING.md` (0.9.4.40).

Code that merged form documents in a separate step because `catPdf` lost the
fields no longer needs that workaround (0.9.4.44).
