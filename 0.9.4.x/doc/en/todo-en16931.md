# TODO: Complete EN 16931 invoice profile

Status of the `examples/facturx.tcl` demo and what is still needed to turn its
embedded XML into a fully compliant EN 16931 (and XRechnung) invoice.

## Scope

pdf4tcl produces the **PDF/A-3 container** and embeds the invoice XML plus the
Factur-X XMP extension. That side is **done and validated** (veraPDF PDF/A-3B:
`isCompliant=true`, 0 failed checks).

This TODO is about the **embedded CII XML content** (`factur-x.xml`), which is an
application-level concern, not a pdf4tcl feature. The demo's `buildCII` currently
emits a **minimal, illustrative skeleton** that would NOT pass EN 16931 Schematron
validation yet.

Two layers of validation exist and are independent:

- **veraPDF** -> checks the PDF/A-3 + Factur-X *container*. Already green.
- **Schematron (KoSIT)** -> checks the *invoice content* against the EN 16931
  business rules (BR-*). Not addressed yet. This is the harder layer.


