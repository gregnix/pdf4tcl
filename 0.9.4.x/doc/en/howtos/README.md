# How-tos

Task-oriented recipes. Each page answers one question with a minimal working
snippet and points at the matching demo under `0.9.4.x/demo/`. For longer
walkthroughs see `../tutorials/`. For full option lists see the manual page
(`pdf4tcl.man` / `pdf4tcl.md`).

## By topic

| Document | Question | Demo |
|---|---|---|
| `howto-run-demos.md` | Run the whole demo suite? | `run-all-demos.tcl` |
| `howto-feature-tour.md` | One-file feature overview? | `demo-all.tcl`, `minimalPdf.tcl` |
| `howto-shapes.md` | Coloured text / boxes / lines? | `FarbenundFormen.tcl` |
| `howto-unicode.md` | Non-Latin-1 text? | `demo-cidfont.tcl`, `demo-api-vergleich.tcl`, `demo-unicode-tabelle.tcl` |
| `howto-symbols.md` | Symbol / Unicode coverage charts? | `demo-symbole.tcl`, `demo-unicode-tabelle.tcl` |
| `howto-stdfonts.md` | Base-14 + ToUnicode? | `demo-stdfonts-tabelle.tcl`, `demo-stdfonts-tounicode.tcl`, `fonts.tcl` |
| `howto-otf.md` | OpenType/CFF fonts? | `demo-otf.tcl` |
| `howto-pdfa.md` | PDF/A-1b/2b/3b and 1a/2a/3a? | `demo-pdfa.tcl`, `demo-pdfa-gs.tcl` |
| `howto-catpdf.md` | Merge PDFs / keep tags? | (API `catPdf`; see TAGGED.md) |
| `howto-validate.md` | Check the PDF? | (tools) |
| `howto-links-and-bookmarks.md` | URLs and outline? | (annotations / bookmarks) |
| `howto-headers-footers.md` | Repeating chrome? | `demo-tagged.tcl` (artifacts) |
| `howto-encrypt.md` | Passwords? | `demo-encryption.tcl`, `demo-aes256.tcl` |
| `howto-permissions.md` | Restrict print/copy after open? | `demo-permissions.tcl` |
| `howto-encrypted-forms.md` | Encrypted AcroForms? | `demo-forms-aes128.tcl`, `demo-forms-aes256.tcl`, `demo-forms-enc.tcl` |
| `howto-facturx.md` | Factur-X container? | `examples/facturx.tcl` |
| `howto-cmyk.md` | DeviceCMYK? | — |
| `howto-colors.md` | Colour inputs / range / names? | (see graphics guide; 0.9.4.39) |
| `howto-alpha.md` | Transparency? | `demo-alpha.tcl` |
| `howto-gradients.md` | Gradients / blend? | `demo-gradients.tcl` |
| `howto-layers.md` | Optional content? | `demo-layers.tcl` |
| `howto-forms.md` | AcroForm fields? | `demo-forms.tcl`, `demo-forms-calc.tcl`, `demo-forms-tk.tcl` |
| `howto-annotations.md` | Notes / stamps / markup? | `demo-annotations.tcl` |
| `howto-images.md` | PNG/JPEG/TIFF? | `demo-interlaced-png.tcl` |
| `howto-canvas.md` | Export a Tk canvas? | `demo-canvas-0.9.4.24.tcl`, `demo-canvas-tkpath.tcl` |
| `howto-transform.md` | rotate/scale/translate? | `demo-transform.tcl` |
| `howto-write-chan.md` | Write to a channel? | `demo-write-chan.tcl` |
| `howto-embed-file.md` | Catalog attachments? | `demo-embedfile.tcl` |
| `howto-paper-sizes.md` | Paper / units? | `demo-paper-sizes.tcl` |
| `howto-cheatsheets.md` | Printable API cheat sheets? | `demo-make-cheatsheets.tcl` |

Assumes pdf4tcl **0.9.4.41** or newer. Run the suite with
`tclsh 0.9.4.x/demo/run-all-demos.tcl` (output under `demo/out/`; see
`howto-run-demos.md`).

## Runnable scripts

Every how-to above has a companion `.tcl` next to the markdown file.
Shared bootstrap: `../_bootstrap.tcl`. PDFs land in `../out/`.

```bash
tclsh 0.9.4.x/doc/en/howtos/howto-colors.tcl
tclsh 0.9.4.x/doc/en/run-all-examples.tcl          # tutorials + howtos
tclsh 0.9.4.x/doc/en/run-all-examples.tcl --alle   # + canvas, cheatsheets
```
