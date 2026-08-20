# Tutorial 6 -- Assemble a reading pack

A frequent need: take a screenshot, one or two text notes, some images, maybe
an existing one-page PDF, and put them **in order into one PDF** -- not as
attachments -- so a colleague can read top to bottom without unzipping or
guessing the order.

This tutorial builds that pack with pdf4tcl. Word/Excel/ODT are out of scope
here: convert those to PDF or plain text first (LibreOffice, export, …), then
include them.

## Runnable script

```bash
tclsh doc/en/tutorials/tutorial-06-assemble-pack.tcl
# PDF -> doc/en/out/tutorial-06-reading-pack.pdf
```

Companion: [`tutorial-06-assemble-pack.tcl`](tutorial-06-assemble-pack.tcl).
It creates tiny sample assets under `../out/assemble-samples/` then builds
the pack.

## Strategy

| Source | Approach |
|---|---|
| Screenshots / photos (PNG, JPEG, …) | `addImage` + `putImage` on their own page(s) |
| Plain text / notes (`.txt`) | `drawTextBox` with a loop over the remainder |
| Existing PDF pages | Build the rest, then `pdf4tcl::catPdf` (structure merge since 0.9.4.40) |
| Cover / order | First page: title + numbered contents |

Do **not** use `addEmbeddedFile` for this job -- that hides files in the
catalog. Your reader should see every page.

## Cover page

```tcl
$pdf startPage
$pdf setFont 20 Helvetica-Bold
$pdf text "Reading pack" -x 0 -y 40
$pdf setFont 11 Helvetica
set y 80
set n 1
foreach item {
    "1. Screenshot -- UI after login"
    "2. Notes -- meeting follow-ups"
    "3. Diagram -- architecture sketch"
    "4. Appendix -- existing one-page PDF"
} {
    $pdf text $item -x 0 -y $y
    incr y 18
}
$pdf bookmarkAdd -title "Cover" -level 0
$pdf endPage
```

## Image page (screenshot)

Fit the image into the drawable area, preserve aspect ratio:

```tcl
$pdf startPage
$pdf bookmarkAdd -title "Screenshot" -level 0
$pdf setFont 12 Helvetica-Bold
$pdf text "1. Screenshot" -x 0 -y 20
set id [$pdf addImage $screenshotPath]
lassign [$pdf getDrawableArea] W H
set maxW $W
set maxH [expr {$H - 50}]
# putImage scales with -width; height follows aspect
$pdf putImage $id 0 40 -width $maxW
$pdf endPage
```

If the image is taller than wide, pass `-height $maxH` instead (or compute
both -- the sample script picks the limiting dimension).

## Text file pages

```tcl
set fh [open $notesPath r]
fconfigure $fh -encoding utf-8
set body [read $fh]
close $fh

set rest $body
set part 0
while {$rest ne ""} {
    incr part
    $pdf startPage
    if {$part == 1} {
        $pdf bookmarkAdd -title "Notes" -level 0
        $pdf setFont 12 Helvetica-Bold
        $pdf text "2. Notes" -x 0 -y 20
    }
    $pdf setFont 10 Helvetica
    lassign [$pdf getDrawableArea] W H
    set top [expr {$part == 1 ? 40 : 20}]
    set rest [$pdf drawTextBox 0 $top $W [expr {$H - $top - 10}] $rest]
    $pdf endPage
}
```

`drawTextBox` returns the unused remainder. Empty remainder means done.

For non-Latin-1 text, embed a TTF and use a CID font (`howto-unicode.md`).

## Append an existing PDF

Write your assembled pages to `pack-body.pdf`, then:

```tcl
pdf4tcl::catPdf $packBody $appendixPdf $finalOut
```

Since 0.9.4.40, tagged inputs keep a merged structure tree. Mixed
tagged/untagged warns -- keep the style consistent. See `howto-catpdf.md`.

Metadata of the **first** file wins, so say what the result is called
(0.9.4.48):

```tcl
pdf4tcl::catPdf -title "Reading pack" $packBody $appendixPdf $finalOut
```

Since 0.9.4.51 that writes both places a PDF keeps the title -- `/Info` and
the XMP `dc:title` -- which is what ISO 19005-1 clause 6.7.3 asks for. And
since 0.9.4.49 `catPdf` reads an input whose object table is a stream, as
every PDF/A from 2b upwards has; 0.9.4.50 added the objects packed inside
`/ObjStm` containers.

## What the sample produces

1. Cover with contents  
2. Screenshot page (sample PNG)  
3. Notes from a generated `.txt` (may span pages)  
4. Second image page  
5. Appended one-page appendix PDF via `catPdf`

## Limits

- pdf4tcl does not rasterise `.docx` / `.odt` / `.xlsx`. Convert first.
- Huge screenshots: consider scaling down before embed (file size).
- Layout engines (columns, automatic TOC page numbers) live in libraries
  such as pdf4tcllib -- this tutorial stays on the engine API.

## Next

- Short recipe: [`../howtos/howto-assemble-pack.md`](../howtos/howto-assemble-pack.md)
- Images: `../howtos/howto-images.md`
- Merge only PDFs: `../howtos/howto-catpdf.md`
- Bookmarks: `../howtos/howto-links-and-bookmarks.md`
