# How-to: Merge PDFs (`catPdf`) including tagged structure

## Runnable script

```bash
tclsh 0.9.4.x/doc/en/howtos/howto-catpdf.tcl
# PDF -> 0.9.4.x/doc/en/out/
```

Companion: [`howto-catpdf.tcl`](howto-catpdf.tcl).

Guide: `../TAGGED.md`, `../pdf4tcl-annotations.md`  
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

## Limits that still apply

- **First catalog wins** -- title/metadata of `part1` remain; rename or set
  metadata on the first file if the combined title must change.
- Embedded fonts are **not** deduplicated -- file size grows roughly with the
  sum of the inputs.
- Untagged-only merges behave as before.

## Upgrade note

Code written against 0.9.4.36–0.9.4.39 that expected structure to disappear
now gets a tagged result. See `../UPGRADING.md` (0.9.4.40).
