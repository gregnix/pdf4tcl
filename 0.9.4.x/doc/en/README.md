# pdf4tcl documentation

Guides for the gregnix fork of pdf4tcl 0.9.4.x. The authoritative reference
is the manual page (`pdf4tcl.man`, rendered to `pdf4tcl.n`, `pdf4tcl.html`
and `pdf4tcl.md` by `make` and `make md`): it lists every method and every
option. The documents here are task oriented -- what to reach for, in which
order, and where the traps are.

## Tutorials

Start here if you want a working PDF before reading every option.
Full index: [`tutorials/README.md`](tutorials/README.md) (assumes **0.9.4.41+**).

| Document | Contents |
|---|---|
| [`tutorial-01-hello-pdf.md`](tutorials/tutorial-01-hello-pdf.md) | One-page PDF: text, colour, line |
| [`tutorial-02-simple-report.md`](tutorials/tutorial-02-simple-report.md) | Multi-page report with header/footer and a table |
| [`tutorial-03-accessible-pdf.md`](tutorials/tutorial-03-accessible-pdf.md) | Tagged PDF/UA-1 sketch with a link |
| [`tutorial-04-forms.md`](tutorials/tutorial-04-forms.md) | Order form with calculated sum |
| [`tutorial-05-graphics-lab.md`](tutorials/tutorial-05-graphics-lab.md) | Alpha + gradient + transform |
| [`tutorial-06-assemble-pack.md`](tutorials/tutorial-06-assemble-pack.md) | Reading pack from images, text, PDFs |

## How-tos

Short recipes for a single job, each linked to a demo under `0.9.4.x/demo/`.
Full index (with demo mapping): [`howtos/README.md`](howtos/README.md).

| Cluster | Examples |
|---|---|
| Demos / reference | `howto-run-demos.md`, `howto-feature-tour.md`, `howto-cheatsheets.md`, `howto-stdfonts.md`, `howto-symbols.md` |
| Text / fonts | `howto-unicode.md`, `howto-otf.md`, `howto-shapes.md` |
| Colour / graphics | `howto-colors.md` (0.9.4.39+), `howto-cmyk.md`, `howto-alpha.md`, `howto-gradients.md`, `howto-transform.md` |
| Standards | `howto-pdfa.md` (a-levels since **0.9.4.41**), `howto-catpdf.md` (**0.9.4.40**), `howto-validate.md`, `howto-facturx.md` |
| Navigation | `howto-links-and-bookmarks.md`, `howto-headers-footers.md`, `howto-assemble-pack.md` |
| Security | `howto-encrypt.md`, `howto-permissions.md`, `howto-encrypted-forms.md` |
| Structure | `howto-layers.md`, `howto-annotations.md` |
| Forms / files | `howto-forms.md`, `howto-embed-file.md`, `howto-images.md` |
| I/O / canvas | `howto-write-chan.md`, `howto-canvas.md`, `howto-paper-sizes.md` |

Run demos: `tclsh 0.9.4.x/demo/run-all-demos.tcl` → `demo/out/` (see
`howtos/howto-run-demos.md`).

Runnable tutorial/howto companions:

```bash
tclsh 0.9.4.x/doc/en/run-all-examples.tcl
# PDFs -> 0.9.4.x/doc/en/out/
```

## Getting started (reference guides)

| Document | Contents |
|---|---|
| `pdf4tcl-basics.md` | Installation, coordinate system, `-orient`, units, first steps |
| `pdf4tcl-text-and-fonts.md` | Text API, the 14 standard fonts, encoding |
| `pdf4tcl-graphics-and-colors.md` | Lines, shapes, arcs, colors, clipping, transformations, transparency |
| `pdf4tcl-images.md` | Loading, scaling and placing images |
| `pdf4tcl-layout-patterns.md` | Reusable layout patterns and page design |

Read `pdf4tcl-basics.md` first even when in a hurry. The `-orient` option
decides whether `y` counts from the top or the bottom, and getting it wrong
produces a page that looks plausible in the code and upside down on screen.

## Features

| Document | Contents |
|---|---|
| `pdf4tcl-cidfont-manual.md` | Unicode via CID fonts, embedding TrueType |
| `pdf4tcl-forms-manual.md` | Interactive form fields |
| `pdf4tcl-annotations.md` | Links, annotations, attachments, page labels, viewer preferences, merging |
| `pdf4tcl-canvas.md` | Exporting a Tk canvas, tkpath and tko::path |
| `pdf4tcl-encryption.md` | AES-128 and AES-256 encryption, permissions |
| `TAGGED.md` | Tagged PDF: logical structure, PDF/UA-1 |

## Standards and migration

| Document | Contents |
|---|---|
| `UPGRADING.md` | What changes between versions (0.9.4.39 colour, **0.9.4.40** catPdf merge, **0.9.4.41** PDF/A-a) |
| `todo-en16931.md` | State of the Factur-X demo and what EN 16931 still needs |
| `howtos/howto-pdfa.md` | PDF/A how-to including level A |
| `howtos/howto-catpdf.md` | Merging tagged PDFs |
| `howtos/howto-colors.md` | Colour inputs after 0.9.4.39 |

PDF/A is also demonstrated by `0.9.4.x/demo/demo-pdfa.tcl` and
`examples/facturx.tcl`.

## Checking the output

```bash
qpdf --check out.pdf                     # syntax and streams
verapdf -f 3b out.pdf                    # PDF/A-3B
verapdf -f ua1 out.pdf                   # PDF/UA-1
python3 tools/check-tagged.py out.pdf    # logical structure
```

None of these judge whether a document is any *good*. A file where every
paragraph is `/P` and every heading is `/H1` passes PDF/UA cleanly and still
tells a reader nothing. See `howtos/howto-validate.md`.

## Language

Only English documents live here. `../de/` is deliberately empty.
