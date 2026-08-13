# How-to: PDF/A-1b, 2b, 3b

## Problem

Archival or e-invoice workflows need a PDF/A flavour. pdf4tcl can emit
**1b**, **2b**, and **3b** directly via `-pdfa`. The **a** levels (1a/2a/3a)
are not available; they imply tagging plus stricter embedding/XMP rules (see
`0.9.4.x/nogit/OFFEN.md` in a full checkout, or `../TAGGED.md`).

## Recipe

```tcl
pdf4tcl::loadBaseTrueTypeFont BaseDejaVu /path/to/DejaVuSans.ttf
pdf4tcl::createFont BaseDejaVu Body iso8859-1

set pdf [::pdf4tcl::new %AUTO% -paper a4 -orient 1 -margin 50 \
        -pdfa 2b]
# optional: -pdfa-icc /path/to/srgb.icc

$pdf metadata -title "Archive sample" -author "pdf4tcl" \
        -subject "PDF/A demo"
$pdf startPage
$pdf setFont 12 Body
$pdf text "This file claims PDF/A-2b." -x 0 -y 24
$pdf endPage
$pdf write -file archive-2b.pdf
$pdf destroy
```

| Flavour | Typical use |
|---|---|
| `1b` | Older archival; no transparency; no embedded files |
| `2b` | Modern archival; XRef stream; layers rules apply |
| `3b` | Like 2b plus embedded files (Factur-X / ZUGFeRD) |

## Check

```bash
verapdf -f 2b archive-2b.pdf
# or: verapdf -f 1b ... / verapdf -f 3b ...
```

## Demos

- `0.9.4.x/demo/demo-pdfa.tcl` -- native `-pdfa`
- `examples/facturx.tcl` -- PDF/A-3b + embedded XML
- Ghostscript path (optional): `demo-pdfa-gs.tcl`

## Traps

- Prefer embedded TrueType over Base-14 for long-term rendering fidelity.
- `setAlpha` below 1.0 with `-pdfa 1b` violates PDF/A-1; pdf4tcl appends a
  warning to `::pdf4tcl::warnings`.
- Embedded files are forbidden in PDF/A-1b; use 3b for Factur-X.
