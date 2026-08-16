# How-to: Feature tour (`demo-all` / `minimalPdf`)

## Runnable script

```bash
tclsh 0.9.4.x/doc/en/howtos/howto-feature-tour.tcl
# PDF -> 0.9.4.x/doc/en/out/
```

Companion: [`howto-feature-tour.tcl`](howto-feature-tour.tcl).

Demos:
- `minimalPdf.tcl` -- smallest Hello-World style PDF
- `demo-all.tcl` -- wide feature tour in one file (text, fonts, colours,
  graphics, images, forms, hyperlinks, metadata, bookmarks, `drawTextBox`,
  rotation, clipping, line styles, transparency, XObjects, …)

## Problem

See “what can pdf4tcl do” without opening every specialised demo.

## Recipe

```bash
tclsh 0.9.4.x/demo/minimalPdf.tcl out
tclsh 0.9.4.x/demo/demo-all.tcl out
# -> demo/out/minimalPdf.pdf (name depends on script)
# -> demo/out/demo-all-output.pdf
```

Use `demo-all` as a living catalogue; for production recipes prefer the
focused how-tos (forms, images, tagged, PDF/A, …). Tutorial path:
`../tutorials/tutorial-01-hello-pdf.md` then tutorial 02+.
