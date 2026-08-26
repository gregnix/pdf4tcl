# Demos

Small, runnable programs, one topic each. Where a how-to answers "how do I
do X", a demo shows a feature working end to end -- often with several
variants side by side so the difference is visible on the page.

    cd demo
    tclsh demo-cidfont.tcl          # one of them
    tclsh run-all-demos.tcl         # all of them, into out/
    make demos                      # the same, from the tree root

Output goes to `demo/out/`. The directory is rebuilt, not added to.

## Needs no Tk

| [`FarbenundFormen.tcl`](FarbenundFormen.tcl) | Farben und Formen |
| [`demo-aes256.tcl`](demo-aes256.tcl) | AES-256 Verschluesselung |
| [`demo-all.tcl`](demo-all.tcl) | Alle Features (Comprehensive) |
| [`demo-annotations.tcl`](demo-annotations.tcl) | Annotationen (Note/FreeText/Stamp/Markup/Line 0.9.4.23) |
| [`demo-alpha.tcl`](demo-alpha.tcl) | Transparenz (setAlpha/getAlpha) |
| [`demo-api-vergleich.tcl`](demo-api-vergleich.tcl) | API-Vergleich (Font-Demo) |
| [`demo-catpdf.tcl`](demo-catpdf.tcl) | PDFs zusammenfuehren (catPdf) |
| [`demo-cidfont.tcl`](demo-cidfont.tcl) | CIDFont Unicode-Support |
| [`demo-embedfile.tcl`](demo-embedfile.tcl) | Eingebettete Dateien (addEmbeddedFile) |
| [`demo-encryption.tcl`](demo-encryption.tcl) | AES-128 Verschluesselung + -permissions |
| [`demo-forms-aes128.tcl`](demo-forms-aes128.tcl) | Formular mit AES-128 |
| [`demo-forms-aes256.tcl`](demo-forms-aes256.tcl) | Formular mit AES-256 |
| [`demo-forms-calc.tcl`](demo-forms-calc.tcl) | Formular + Summenberechnung (-calculate 0.9.4.32) |
| [`demo-forms-enc.tcl`](demo-forms-enc.tcl) | Formular verschluesselt |
| [`demo-forms.tcl`](demo-forms.tcl) | Bestellformular ohne Verschluesselung |
| [`demo-gradients.tcl`](demo-gradients.tcl) | Verlaeufe und Blendmodi |
| [`demo-interlaced-png.tcl`](demo-interlaced-png.tcl) | Interlaced PNG (Adam7, 0.9.4.28) |
| [`demo-kerning-ligatures.tcl`](demo-kerning-ligatures.tcl) | Kerning und Ligaturen |
| [`demo-layers.tcl`](demo-layers.tcl) | Layer / OCG (0.9.4.21) |
| [`demo-make-cheatsheets.tcl`](demo-make-cheatsheets.tcl) | Cheat Sheets |
| [`demo-otf.tcl`](demo-otf.tcl) | OpenType-Fonts |
| [`demo-paper-sizes.tcl`](demo-paper-sizes.tcl) | Papierformate |
| [`demo-pdfa-3a.tcl`](demo-pdfa-3a.tcl) | PDF/A-3a und PDF/UA-1 |
| [`demo-pdfa-gs.tcl`](demo-pdfa-gs.tcl) | PDF/A via Ghostscript |
| [`demo-pdfa.tcl`](demo-pdfa.tcl) | PDF/A direkt |
| [`demo-permissions.tcl`](demo-permissions.tcl) | PDF-Berechtigungen (-permissions) |
| [`demo-stdfonts-tabelle.tcl`](demo-stdfonts-tabelle.tcl) | Standard-Fonts Tabelle |
| [`demo-stdfonts-tounicode.tcl`](demo-stdfonts-tounicode.tcl) | Standard-Fonts ToUnicode |
| [`demo-symbole.tcl`](demo-symbole.tcl) | Symbole |
| [`demo-tagged-xobject.tcl`](demo-tagged-xobject.tcl) | Struktur in einem Form-XObject (0.9.4.46) |
| [`demo-tagged.tcl`](demo-tagged.tcl) | Tagged PDF / PDF-UA (0.9.4.36+0.9.4.37) |
| [`demo-transform.tcl`](demo-transform.tcl) | transform + getPageSize (0.9.4.20) |
| [`demo-unicode-tabelle.tcl`](demo-unicode-tabelle.tcl) | Unicode-Tabelle |
| [`demo-write-chan.tcl`](demo-write-chan.tcl) | write -chan / -file / get |
| [`fonts.tcl`](fonts.tcl) | Font-Demo |
| [`minimalPdf.tcl`](minimalPdf.tcl) | Minimales PDF (Hello World) |

## Needs Tk

These open a window or export one, so they need `wish` or a display.

| [`demo-canvas-0.9.4.24.tcl`](demo-canvas-0.9.4.24.tcl) | Canvas-Export |
| [`demo-canvas-tkpath.tcl`](demo-canvas-tkpath.tcl) | Canvas-Export mit tkpath |
| [`demo-forms-tk.tcl`](demo-forms-tk.tcl) | Formulare (Tk-GUI) |

## Checking what they produce

```bash
tclsh ../tools/pdfcheck-native.tcl out/       # structures, fonts, metadata
python3 ../tools/check-conformance.py out/    # veraPDF where a claim is made
```

Most demos claim no conformance profile and are reported as such -- that is
not a defect, it is what an unclaimed document looks like.

`../tools/layout-check.tcl` is deliberately **not** part of this: dense
character tables, reference cards and rotated text all report findings that
are correct output. Its file header says why.

## If one fails

`demo-pdfa-gs.tcl` needs Ghostscript and says so. `make demos` does not
abort on it -- a missing tool is not a defect in the tree.
