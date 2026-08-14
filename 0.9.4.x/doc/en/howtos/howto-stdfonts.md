# How-to: Standard (Base-14) fonts and ToUnicode

## Runnable script

```bash
tclsh 0.9.4.x/doc/en/howtos/howto-stdfonts.tcl
# PDF -> 0.9.4.x/doc/en/out/
```

Companion: [`howto-stdfonts.tcl`](howto-stdfonts.tcl).

Demos:
- `demo-stdfonts-tounicode.tcl` -- all 14 fonts with sample text
- `demo-stdfonts-tabelle.tcl` -- full WinAnsi code-page grid per font
- `fonts.tcl` -- minimal Base-14 usage

## Problem

Use Helvetica / Times / Courier without embedding a TTF, and still allow
copy-paste of Latin-1 text.

## Recipe

```tcl
set pdf [::pdf4tcl::new %AUTO% -paper a4 -orient 1 -margin 50]
$pdf startPage
$pdf setFont 18 Helvetica-Bold
$pdf text "Title" -x 0 -y 24
$pdf setFont 12 Times-Roman
$pdf text "Body with umlauts: äöü ÄÖÜ ß" -x 0 -y 50
$pdf setFont 10 Courier
$pdf text "mono 0123456789" -x 0 -y 70
$pdf endPage
$pdf write -file stdfonts.pdf
$pdf destroy
```

Correct style names matter: Helvetica uses **-Oblique**, Times uses
**-Italic**.

## ToUnicode (since 0.9.4.9)

Standard fonts embed a WinAnsi/cp1252 **ToUnicode** CMap so extraction and
copy-paste work for that encoding. They still cannot print characters outside
Latin-1 -- use CID (`howto-unicode.md`) for that.

## Generate the reference PDFs

```bash
tclsh 0.9.4.x/demo/demo-stdfonts-tounicode.tcl out
tclsh 0.9.4.x/demo/demo-stdfonts-tabelle.tcl out
```

PDF/UA and long-term archival still want an **embedded** TrueType/OTF, not
Base-14 alone.
