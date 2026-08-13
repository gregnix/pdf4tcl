# Tutorial 3 -- Accessible (tagged) PDF

Build a small PDF/UA-1-oriented document: title metadata, embedded font,
headings, a paragraph, a tagged link, and an artifact footer. Full detail is
in `../TAGGED.md`; this page is the shortest path that usually validates.

## Requirements that trip people up

1. **Embed a real font.** Base-14 fonts have no embeddable program. PDF/UA
   clause 7.21.4.1 rejects them. Use FreeSans from `examples/` or DejaVu.
2. **Set a title and DisplayDocTitle.** Otherwise veraPDF fails even when the
   structure tree is fine.
3. **Wrap links.** A hyperlink outside a `Link` structure element still works
   when clicked but is invisible to assistive technology. Since 0.9.4.39
   pdf4tcl records that in `::pdf4tcl::warnings` (once per document). Use
   `tagBegin Link -alt "..."`.
4. **Mark running heads/feet as artifacts**, not as content.

## Minimal script

Paths assume you run from the repository root or adjust `auto_path` / the font
path. FreeSans ships under `examples/FreeSans.ttf`.

```tcl
#!/usr/bin/env tclsh
set root /path/to/pdf4tcl
lappend auto_path $root
package require pdf4tcl 0.9

pdf4tcl::loadBaseTrueTypeFont BaseFreeSans \
        [file join $root examples FreeSans.ttf]
pdf4tcl::createFont BaseFreeSans Body iso8859-1

set pdf [::pdf4tcl::new %AUTO% -paper a4 -orient 1 -margin 50]
$pdf tagged 1 -lang en-GB -ua 1
$pdf metadata -title "Accessible sample" -author "pdf4tcl tutorial"
$pdf viewerPreferences -displaydoctitle 1

lassign [$pdf getDrawableArea] W H

$pdf startPage

$pdf tagArtifact -type Pagination -subtype Footer
$pdf setFont 8 Body
$pdf text "1" -x [expr {$W - 20}] -y [expr {$H - 4}]
$pdf tagArtifactEnd

$pdf setFont 18 Body
$pdf tagText H1 "Accessible sample" -x 0 -y 24

$pdf setFont 11 Body
$pdf tagBegin P
$pdf text "This paragraph is one structure element." -x 0 -y 50
$pdf tagEnd

$pdf tagBegin P
$pdf text "More on the" -x 0 -y 74
$pdf tagBegin Link -alt "pdf4tcl on GitHub"
$pdf tagText Span "project page" -x 62 -y 74
$pdf hyperlinkAdd 62 65 70 12 "https://github.com/gregnix/pdf4tcl"
$pdf tagEnd
$pdf text "." -x 134 -y 74
$pdf tagEnd

$pdf endPage
$pdf write -file accessible.pdf
$pdf destroy
```

## Check it

```bash
python3 tools/check-tagged.py accessible.pdf
verapdf -f ua1 accessible.pdf
```

A green veraPDF run means the file obeys the profile. It does **not** mean the
tagging is sensible. Putting every line in `/H1` can still pass.

## Next

- Lists, tables, figures with `/Alt`: `examples/tagged.tcl` and
  `0.9.4.x/demo/demo-tagged.tcl`
- Theory and limits: `../TAGGED.md`
- Validation recipes: `../howtos/howto-validate.md`
