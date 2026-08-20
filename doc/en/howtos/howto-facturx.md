# How-to: Factur-X / ZUGFeRD container

## Runnable script

```bash
tclsh doc/en/howtos/howto-facturx.tcl
# PDF -> doc/en/out/
```

Companion: [`howto-facturx.tcl`](howto-facturx.tcl).

## Problem

Ship an electronic invoice as **PDF/A-3** with an embedded CII XML and the
Factur-X XMP extension.

## What pdf4tcl does

- PDF/A-3b container (`-pdfa 3b`)
- High-level **`facturx`** helper (embed XML + Factur-X XMP), as used by
  `examples/facturx.tcl`
- **`orderx`** for orders rather than invoices (0.9.4.50+)
- Lower-level **`addEmbeddedFile`** for generic attachments

## What pdf4tcl does *not* do

Validate the invoice **business content** against EN 16931 / XRechnung
Schematron. That is application data. See `../reference/todo-en16931.md`.

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

## Order-X: the same for an order (0.9.4.50)

Order-X is the ordering counterpart of Factur-X, published by the same
bodies. Same mechanism, same PDF/A-3 requirement; the namespace, the file
name and the document types differ.

```tcl
$pdf orderx -contents $xml -documenttype ORDER -conformance comfort
```

| | Factur-X | Order-X |
|---|---|---|
| method | `facturx` | `orderx` |
| attachment | `factur-x.xml` | `order-x.xml` |
| profiles | MINIMUM ... XRECHNUNG | basic, comfort, extended |
| document types | INVOICE | ORDER, ORDER_CHANGE, ORDER_RESPONSE |

**The profiles are not interchangeable.** An invoice level such as
`EN 16931` is refused by `orderx`, and `comfort` is refused by `facturx`:

```
orderx: invalid -conformance "EN 16931": must be basic, comfort, extended
```

Everything else is delegated to `facturx`, so attachment, XMP block and
`/AF` relationship come from one piece of code and cannot drift apart.

A partial order takes `-afrelationship Data` instead of the default
`Alternative`.

## Check

```bash
verapdf -f 3b invoice.pdf
# Separately: Schematron / KoSIT tools on the extracted XML
```

PDF/A-1b forbids embedded files; use **3b** for this use case.
