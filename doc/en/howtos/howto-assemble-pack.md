# How-to: Assemble a reading pack (images + text + PDFs)

## Problem

Combine screenshots, notes, and maybe existing PDFs into **one** PDF so a
reader goes through them in order -- without attachments or a zip file.

## Runnable script

```bash
tclsh 0.9.4.x/doc/en/howtos/howto-assemble-pack.tcl
# or the fuller walkthrough:
tclsh 0.9.4.x/doc/en/tutorials/tutorial-06-assemble-pack.tcl
```

Companion: [`howto-assemble-pack.tcl`](howto-assemble-pack.tcl).  
Tutorial: [`../tutorials/tutorial-06-assemble-pack.md`](../tutorials/tutorial-06-assemble-pack.md).

## Recipe (outline)

```tcl
set pdf [::pdf4tcl::new %AUTO% -paper a4 -orient 1 -margin 40]
$pdf metadata -title "Reading pack" -author "you"

# 1) Cover + contents
$pdf startPage
# ... title, numbered list of sections, bookmarkAdd ...
$pdf endPage

# 2) Each screenshot / image on its own page
$pdf startPage
set id [$pdf addImage $pathToPng]
$pdf putImage $id 0 40 -width $drawableWidth
$pdf endPage

# 3) Plain-text notes with drawTextBox pagination
set rest $fileContents
while {$rest ne ""} {
    $pdf startPage
    set rest [$pdf drawTextBox 0 40 $W [expr {$H - 50}] $rest]
    $pdf endPage
}

$pdf write -file pack-body.pdf
$pdf destroy

# 4) Optional: append other PDFs (pages, not attachments)
pdf4tcl::catPdf pack-body.pdf other.pdf reading-pack.pdf
```

## Do / don't

| Do | Don't |
|---|---|
| Paint images and text on pages | Use `addEmbeddedFile` for the reading material |
| Fix the section order on a cover page | Rely on filesystem sort alone |
| Convert Office files to PDF/txt first | Expect pdf4tcl to open `.docx` |
| Use `catPdf` for finished PDF parts | Mix tagged and untagged if you need PDF/UA |

## Related

- `howto-images.md`, `howto-catpdf.md`, `howto-headers-footers.md`
- `howto-unicode.md` for non-Latin-1 notes
