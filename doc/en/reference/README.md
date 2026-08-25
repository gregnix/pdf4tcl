# Reference

Longer pieces that explain one area in depth. The howtos in
[`../howtos/`](../howtos/README.md) answer "how do I do X"; these answer
"how does X work and what does it cost".

| File | Read it when |
|---|---|
| [`pdf4tcl-basics.md`](pdf4tcl-basics.md) | Starting out: coordinates, units, pages |
| [`pdf4tcl-text-and-fonts.md`](pdf4tcl-text-and-fonts.md) | Placing text, the fourteen standard fonts, the baseline |
| [`pdf4tcl-fonts-and-unicode.md`](pdf4tcl-fonts-and-unicode.md) | **Which font mechanism to pick** -- standard, subset or CID, with what each one costs |
| [`pdf4tcl-cidfont-manual.md`](pdf4tcl-cidfont-manual.md) | Working with CID fonts in detail |
| [`pdf4tcl-graphics-and-colors.md`](pdf4tcl-graphics-and-colors.md) | Lines, shapes, colours, transformations |
| [`pdf4tcl-images.md`](pdf4tcl-images.md) | Embedding images, formats, placement |
| [`pdf4tcl-canvas.md`](pdf4tcl-canvas.md) | Putting a Tk canvas onto a page |
| [`pdf4tcl-forms-manual.md`](pdf4tcl-forms-manual.md) | Interactive form fields |
| [`pdf4tcl-annotations.md`](pdf4tcl-annotations.md) | Notes, links, bookmarks, document level entries |
| [`pdf4tcl-encryption.md`](pdf4tcl-encryption.md) | AES-128 and AES-256, permissions |
| [`TAGGED.md`](TAGGED.md) | Tagged PDF: the structure tree, what goes into the file |
| [`UPGRADING.md`](UPGRADING.md) | Moving from an older pdf4tcl |
| [`todo-en16931.md`](todo-en16931.md) | What is still missing from the EN 16931 invoice profile |

## The question that comes up most

**"Which font do I use for characters outside Latin-1?"**

Three mechanisms, and the choice is a trade-off rather than a ranking:

| | Characters | File size |
|---|---|---|
| standard font | Latin-1 only | smallest, nothing embedded |
| `createFontSpecEnc` | 256, chosen by you | subset embedded |
| `createFontSpecCID` | anything the font covers | **whole font embedded** |

pdf4tcl does not subset on the CID path. Measured on the same page with
DejaVuSans: 31 kB through `createFontSpecEnc` against 386 kB through
`createFontSpecCID`.

So for a handful of symbols the 256-codepoint route stays smaller; for real
multilingual text CID is the only one that works. The numbers and a worked
example are in
[`pdf4tcl-fonts-and-unicode.md`](pdf4tcl-fonts-and-unicode.md).
