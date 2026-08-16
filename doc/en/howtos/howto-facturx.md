# How-to: Factur-X / ZUGFeRD container

## Runnable script

```bash
tclsh 0.9.4.x/doc/en/howtos/howto-facturx.tcl
# PDF -> 0.9.4.x/doc/en/out/
```

Companion: [`howto-facturx.tcl`](howto-facturx.tcl).

## Problem

Ship an electronic invoice as **PDF/A-3** with an embedded CII XML and the
Factur-X XMP extension.

## What pdf4tcl does

- PDF/A-3b container (`-pdfa 3b`)
- High-level **`facturx`** helper (embed XML + Factur-X XMP), as used by
  `examples/facturx.tcl`
- Lower-level **`addEmbeddedFile`** for generic attachments

## What pdf4tcl does *not* do

Validate the invoice **business content** against EN 16931 / XRechnung
Schematron. That is application data. See `../todo-en16931.md`.

## Recipe

Prefer copying `examples/facturx.tcl` and replacing the data/XML builder.
Core shape:

```tcl
pdf4tcl::loadBaseTrueTypeFont BaseFreeSans /path/to/FreeSans.ttf
pdf4tcl::createFont BaseFreeSans InvoiceFont iso8859-1

pdf4tcl::new p1 -paper a4 -pdfa 3b -compress 1 -orient 1
p1 metadata -title "Invoice INV-2026-0001" -author "Muster GmbH"

p1 startPage
p1 setFont 12 InvoiceFont
p1 text "Human-readable invoice..." -x 50 -y 50
p1 endPage

set xml [buildYourCII]   ;# your EN 16931 XML -- not validated by pdf4tcl
p1 facturx -contents $xml \
        -filename "factur-x.xml" \
        -conformance "EN 16931" \
        -documenttype "INVOICE" \
        -version "1.0"

p1 write -file invoice.pdf
p1 destroy
```

For a plain embedded file without Factur-X XMP:

```tcl
$pdf addEmbeddedFile factur-x.xml \
        -contents $xml \
        -mimetype "text/xml" \
        -afrelationship Data
```

## Check

```bash
verapdf -f 3b invoice.pdf
# Separately: Schematron / KoSIT tools on the extracted XML
```

PDF/A-1b forbids embedded files; use **3b** for this use case.
