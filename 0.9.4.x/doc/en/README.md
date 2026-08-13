# pdf4tcl documentation

Guides for the gregnix fork of pdf4tcl 0.9.4.x. The authoritative reference
is the manual page (`pdf4tcl.man`, rendered to `pdf4tcl.n`, `pdf4tcl.html`
and `pdf4tcl.md` by `make` and `make md`): it lists every method and every
option. The documents here are task oriented -- what to reach for, in which
order, and where the traps are.

## Getting started

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
| `UPGRADING.md` | What changes between versions and what breaks |
| `todo-en16931.md` | State of the Factur-X demo and what EN 16931 still needs |

PDF/A has no separate document yet; `-pdfa 1b|2b|3b` is covered in the manual
page and demonstrated by `0.9.4.x/demo/demo-pdfa.tcl` and
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
tells a reader nothing.

## Language

Only English documents live here. `../de/` is deliberately empty.
