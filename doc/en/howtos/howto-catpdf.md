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

## Cross-reference streams (0.9.4.49)

A file may keep its object table as a *stream* rather than a table (PDF
1.5+). ISO 19005-1 **forbids** that form and PDF/A-2 and -3 **require** it,
so until 0.9.4.49 no archival document from 2b upwards and no ZUGFeRD
invoice could be merged at all.

| Input | Merges |
|---|---|
| plain PDF from pdf4tcl | yes |
| PDF/A-1b | yes |
| PDF/A-2b, -3b, -3a | yes, since 0.9.4.49 |
| a file with `/ObjStm` object streams | no -- refused with a count |

Measured: two PDF/A-2b files merge and the result passes veraPDF as 2b; two
tagged PDF/A-3a files merge and the result passes 3a and UA-1.

What is still refused, rather than silently mishandled:

```
catPdf: "x.pdf" keeps 3 object(s) inside object streams (/ObjStm),
which this reader does not unpack
```

pdf4tcl does not produce those; they come from other tools. `qpdf
--object-streams=generate` makes one to try it against.

## Naming the merged document (0.9.4.48)

Merging keeps the catalog of the first input, and with it its `/Info` —
otherwise two parts joined carry the title of part one:

```tcl
::pdf4tcl::catPdf -title "Complete file" -author "" \
        part1.pdf part2.pdf complete.pdf
```

`-title -author -subject -keywords -creator -producer`, all before the file
names, so existing calls are unaffected. An empty value **removes** the
entry; entries not named keep what the first document had.

**This writes `/Info` only, not `/Metadata` (XMP).** A reader preferring XMP
still shows the title of the first document, and PDF/A requires the two to
agree — which does not bite while PDF/A-2b cannot be read at all.

## Limits that still apply

- **`/Metadata` of `part1` remains** — see above. The `/Info` of the
  appended documents also stays in the file, unreferenced.
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
