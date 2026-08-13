# How-to: Embed arbitrary files

Demo: `0.9.4.x/demo/demo-embedfile.tcl`  
Factur-X-specific: `howto-facturx.md`, `examples/facturx.tcl`

## Problem

Attach a file to the PDF catalog (no visible paperclip annotation).

## Recipe

```tcl
set pdf [::pdf4tcl::new %AUTO% -paper a4 -orient 1 -pdfa 3b]
$pdf startPage
# ... draw human-readable page ...
$pdf endPage

$pdf addEmbeddedFile "notes.txt" \
        -contents "plain attachment\n" \
        -mimetype "text/plain" \
        -description "Side notes" \
        -afrelationship Data

$pdf write -file with-attachment.pdf
$pdf destroy
```

`-afrelationship`: `Alternative` | `Data` | `Source` | `Supplement` |
`Unspecified`.

## Rules

- Forbidden with `-pdfa 1b` (raises an error).
- PDF/A-3b adds the file to the catalog `/AF` array automatically.
- For Factur-X XMP + naming conventions, use the `facturx` method instead of
  inventing the packet by hand.
