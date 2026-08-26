# How-to: PDF/A (1b/2b/3b and 1a/2a/3a)

## Runnable script

```bash
tclsh doc/en/howtos/howto-pdfa.tcl
# PDF -> doc/en/out/
```

Companion: [`howto-pdfa.tcl`](howto-pdfa.tcl).

## Problem

Archival or e-invoice workflows need a PDF/A flavour.

## Level B (no tagging required)

```tcl
pdf4tcl::loadBaseTrueTypeFont BaseDejaVu /path/to/DejaVuSans.ttf
pdf4tcl::createFont BaseDejaVu Body iso8859-1

set pdf [::pdf4tcl::new %AUTO% -paper a4 -orient 1 -margin 50 \
        -pdfa 2b]
# optional: -pdfa-icc /path/to/srgb.icc

$pdf metadata -title "Archive sample" -author "pdf4tcl"
$pdf startPage
$pdf setFont 12 Body
$pdf text "This file claims PDF/A-2b." -x 0 -y 24
$pdf endPage
$pdf write -file archive-2b.pdf
$pdf destroy
```

## Level U (since 0.9.4.56)

Between B and A. The visual appearance is preservable **and** the text can
be extracted as Unicode -- but no tagging is required.

```tcl
set pdf [::pdf4tcl::new %AUTO% -paper a4 -pdfa 3u]
```

U sits between B and A: it adds the requirement that the text be
extractable as Unicode, and stops short of the logical structure that A
wants. The three levels are defined in ISO 19005-2, clause 5.4.

**In practice there is nothing extra to do.** pdf4tcl writes a ToUnicode
map for every CID font, so a document that passes level B with an embedded
font passes level U as well -- measured, veraPDF accepts `2u` and `3u`.

There is no `1u`: the level was introduced with part 2 (clause 5.4
note 3).

**When to use it:** an archive that has to stay searchable, without the
effort of a full structure tree. A scanned document with an OCR text layer
is the usual case.

## Level A (since 0.9.4.41)

Level A adds tagged PDF and a document language on top of level B. Both are
**checked at `finish`**; missing either raises an error (so the file cannot
claim `pdfaid:conformance A` falsely):

```tcl
pdf4tcl::loadBaseTrueTypeFont BaseFreeSans /path/to/FreeSans.ttf
pdf4tcl::createFont BaseFreeSans Body iso8859-1

set pdf [::pdf4tcl::new %AUTO% -paper a4 -orient 1 -margin 50 -pdfa 3a]
$pdf tagged 1 -lang en-GB -ua 1
$pdf metadata -title "Accessible archive" -author "pdf4tcl"
$pdf viewerPreferences -displaydoctitle 1

$pdf startPage
$pdf setFont 12 Body
$pdf tagText H1 "Title" -x 0 -y 24
$pdf tagBegin P
$pdf text "Tagged body text." -x 0 -y 50
$pdf tagEnd
$pdf endPage
$pdf write -file archive-3a.pdf
$pdf destroy
```

Combining `-pdfa` and `-ua 1` is supported; since 0.9.4.41 the XMP packet
declares `pdfuaid` through a `pdfaExtension` schema so veraPDF accepts both.

| Flavour | Typical use |
|---|---|
| `1b` / `1a` | Older archival; no transparency; no embedded files |
| `2b` / `2a` | Modern archival; XRef stream |
| `3b` / `3a` | Plus embedded files (Factur-X / ZUGFeRD) |

## Check

```bash
verapdf -f 2b archive-2b.pdf
verapdf -f 3a archive-3a.pdf
verapdf -f ua1 archive-3a.pdf
```

## Traps

- **Embed a real font.** Base-14 has no embeddable program. Since 0.9.4.41
  using Helvetica (etc.) with `-pdfa` appends a warning to
  `::pdf4tcl::warnings`; the file still will not validate as PDF/A.
- `setAlpha` &lt; 1 with `-pdfa 1b`/`1a` violates PDF/A-1 (warning).
- Embedded files are forbidden in PDF/A-1; use 3b/3a for Factur-X.
- Level A does **not** check that tagging is sensible -- only that tagging
  and `-lang` are present. See `../reference/TAGGED.md` and tutorial 03.

## Demos

- `demo/demo-pdfa.tcl` -- native `-pdfa`
- `examples/facturx.tcl` -- PDF/A-3b + embedded XML
- Ghostscript path (optional): `demo-pdfa-gs.tcl`
