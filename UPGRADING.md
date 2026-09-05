# UPGRADING -- pdf4tcl gregnix fork

## 0.9.4.63 -- same output on 8.6 and 9.0, layers that stay off the paper

### Nothing to change in your code

Everything below alters what pdf4tcl **writes** or what it reports, not
how it is called. New options only.

### Output changes

**CP1252.** The five bytes CP1252 leaves undefined (`0x81 0x8D 0x8F 0x90
0x9D`) now map to `U+FFFD` under Tcl 8.6 as well; before, 8.6 wrote
`U+0081`. Files written under 8.6 differ from older ones at exactly those
five positions, in the ToUnicode CMap and in `/Differences`. Under Tcl 9
nothing changes.

**Empty text fields carry an appearance stream.** A text field created
without `-init` used to get no `/AP` at all outside PDF/A. It now gets an
empty one (length 0, as the PDF/A path has always written), so a later
`fillForms` has something to overwrite. Every empty field costs one more
object.

**`/AS` appears without PDF/A.** As soon as one layer carries a `/Usage`
entry, the default configuration gets an `/AS` array -- without it no
viewer applies `/Usage`. Each category names only the layers that have
the matching entry.

### Two error messages changed

```
before   can't read "FontsAttrs(,specialencoding)": no such element in array
now      no font set

before   unknown color: 1
now      unknown color: "1" -- expected a name like "red", "#rrggbb", ...
```

`addForm` demands a font only where one is really needed. `text`,
`password`, `checkbutton` and `radiobutton` still work before `setFont`;
`combobox`, `listbox`, `pushbutton` and `signature` do not.

A test that pins the exact wording of the colour error will fail. In this
tree `color-6.2` was such a test; it now matches the head of the message.

### getForms returns two more keys

`maxlen` and `comb`. Code that reads individual keys is unaffected; code
that compares the whole dict against a literal will fail.

### New options

```tcl
$pdf addLayer "Vordruck" -print 0        ;# on screen, not on paper
$pdf addLayer "Detail"   -zoom {2.0 {}}  ;# only above 2x
$pdf addLayer "Kopf DE"  -group kopf     ;# at most one of the group
$pdf layers                              ;# what is there
$pdf addForm text 20 20 200 20 -id kfz -maxlen 8 -comb 1
$pdf addForm text 20 60 100 20 -id datum -format date
$pdf addForm text 20 90 100 20 -id feld  -layer $l
```

`-print 0` writes `/Usage << /Print << /PrintState /OFF >> >>`. **Where
this works is defined, not unknown:** ISO 32000-1 8.11.4.4 says usage
application dictionaries shall only be used by *interactive* conforming
readers, and not by applications that use PDF as final form output.
Printing out of a viewer honours it; a RIP does not, and that is
conforming. Where it must not go wrong, keep the artwork out of the file.

`-comb` divides the field width into `-maxlen` cells and centres one
character in each. It requires `-maxlen`, excludes `-multiline`, and
honours `-align`. `-layer` on `addForm` writes `/OC` into the annotation
dictionary -- an annotation lives outside the content stream, so
`beginLayer` cannot reach it.

### beginLayer and endLayer are counted

`endLayer` without `beginLayer` raises an error where it used to write a
stray `EMC`, and `endPage` refuses a page with a layer still open
(ISO 32000-1 14.6). Code that relied on the old silence will now fail
loudly.

### fillForms still writes the value, not the appearance

Unchanged, but now stated plainly in the manual: `fillForms` sets `/V`
and turns on `/NeedAppearances`; the existing appearance stream stays.
A viewer honouring the flag shows the new value, a print path rendering
the appearance shows the **old** one -- not nothing, the previous value.
Where it must not go wrong, produce the document with its values instead
of filling it afterwards.

## 0.9.4.62 -- gsave and grestore close an open text object

`text` leaves the text object open on purpose so several calls share one
`BT`. `gsave` and `grestore` wrote their `q` and `Q` straight into it,
producing `BT ... q ... ET Q`. Adobe Reader showed a **blank page without
a message**; Poppler, MuPDF and pdftotext drew the invalid stream anyway.

Nothing to change in your code. If you compare generated files, the `q`
and `Q` now sit outside `BT`/`ET`, and an `ET` may appear where there was
none.

Found through `pdf4tcllib::labels::render` with `-clip 1`.
`tests/nesting.test` checks the class, not one string.

## 0.9.4.61 -- the soft hyphen is a suggestion, not a character

`text`, `drawTextBox` and `getStringWidth` disagreed about `U+00AD`: one
drew it, one measured it, one dropped it. All three now treat it as a
break suggestion. Measured: `getStringWidth` for Helvetica 10 returns
27.79 for `Sil\u00ADben` and for `Silben` -- the same number.

**What this means for you:** a string containing soft hyphens comes out
narrower than before, and the glyph no longer appears in the output.
`tests/consistency.test` holds the three against each other.

## 0.9.4.48 -- catPdf names the merged document, and says what it cannot read

### The merged document can be given a title

Merging keeps the catalog of the first input, so the result used to carry
the title of part one with no way to change it. Now:

```tcl
::pdf4tcl::catPdf -title "Complete file" -author "" \
        part1.pdf part2.pdf complete.pdf
```

`-title -author -subject -keywords -creator -producer`, all **before** the
file names. Existing calls are unaffected -- the file names stay positional
and no option is required.

An empty value removes the entry; entries not named keep what the first
document had. Since 0.9.4.51 each value goes to both `/Info` and the XMP
`dc:title` and its relatives -- before that, `/Info` only.

### Cross-reference streams are refused, not mis-parsed

A file may keep its object table as a stream rather than a table (PDF 1.5+).
`catPdf` never handled those; until now it failed inside the parser with

```
can't read "trailertxt": no such variable
```

which names a Tcl variable rather than the cause. It now says what is wrong,
and a missing `startxref` is reported too.

Nothing that worked before stops working. But if you have code that catches
the old error and treats it as "damaged file", the message has changed --
and it is worth knowing which files are affected: ISO 19005-1 forbids xref
streams, PDF/A-2 and -3 require them, so **no PDF/A from 2b upwards and no
ZUGFeRD invoice can be merged.** PDF/A-1b can.

## 0.9.4.46 -- structure inside XObjects

`tagBegin` works inside a form XObject now. Two things follow for existing
code.

**`getUntaggedCount` counts more.** Content inside an XObject used to be
exempt, because it could not be tagged. It can now, so a raw XObject placed
under a tagged `Do` is reported. Nothing about your documents changed --
the number did. If it went up, the content was always outside the structure
tree; tag it, or mark it as an artifact.

**An XObject with tagged content may be drawn only once.** Doing it twice
now raises an error when the document is written:

```
XObject 4 carries tagged content and is drawn more than once.
```

**And if you claim PDF/UA, do not reuse a form XObject at all.** Measured
with veraPDF 1.30.2: every placement beyond the first fails rule 7.20-2,
one check per extra placement, no matter how the content is marked. That is
not new in this release -- it has always been so -- but pdf4tcl now says it:

```
XObject 4 is drawn more than once. Valid PDF, but not PDF/UA: veraPDF
reports rule 7.20-2 once per extra placement ...
```

A warning, not an error. Reuse is good PDF and saves the copy; it is the
conformance claim that rules it out. See `doc/en/reference/TAGGED.md`.

## 0.9.4.45 -- directory layout

Nothing in the library changed. This affects anyone who builds from the
tree or scripts against it.

**`0.9.4.x/` is gone.** `demo/`, `doc/`, `fonts/` and `nogit/` are at the
top level now. Paths in your own scripts change accordingly:

```
demo/run-all-demos.tcl   ->  demo/run-all-demos.tcl
doc/en/...               ->  doc/en/...
```

**`make web` and `make webt` no longer exist**, and neither does `web/`.
The page was uploaded by rsync to `pspjuth@web.sourceforge.net`, the
upstream account. A call now ends with

```
make: *** No rule to make target 'web'.  Stop.
```

**`contrib/` and `exp.tcl` are removed.** Nothing in the Makefile, the
tests or the demos referred to them.

**New targets `clean` and `distclean`.** There was no `clean` before.
`clean` removes generated output but keeps `pdf4tcl.tcl` and
`examples/*.pdf`; `distclean` also removes the assembled files, after
which `make` is required before anything runs.

**`pkg/` is a symlink directory.** After cloning, and after
`make distclean`, run

```bash
tclsh tools/restore-pkg-symlinks.tcl
```

Without it, `pkg/` is a set of copies that go stale: on the tree this
release was cut from, `pkg/pdf4tcl.man` was four versions behind
`pdf4tcl.man`, and a release built from it would have shipped that manual.
`make checkbuild` does not catch this -- it only compares `pdf4tcl.tcl`.

See `INSTALL.md` for the whole build, test and packaging story.

## 0.9.4.44 -- drawTextBox -newyvar, and catPdf merges the form

### catPdf merges the interactive form

Merging two documents that both carry form fields used to keep the
`/AcroForm` of the first one only. The second document's fields were in the
file and on the page, and no reader offered them for filling.

They are now merged. **If you worked around this** -- by merging forms in a
separate step, or by putting all fields in the first document -- that
workaround is no longer needed, and a document that carries the same field
name twice will now produce a warning in `::pdf4tcl::warnings`.

Two fields of the same name remain one field with one shared value, as the
standard prescribes. pdf4tcl does not rename them.

### drawTextBox -newyvar

`-newyvar` now reports the Y position in the coordinates the caller uses.

Before, it returned the internal page coordinate: under the default
`-orient 1` a box starting at `y=200` answered `633.5`, and the documented
example

```tcl
$pdf drawTextBox $x $y $w $h $text -newyvar nextY
$pdf line $x $nextY [expr {$x+$w}] $nextY
```

drew its line at the wrong end of the page. The value returned was
`pageHeight - (y + height)`, constant offset at any y.

**If you worked around it** -- say by computing `pageHeight - $nextY`
yourself -- that correction has to go, or the position is wrong the other
way. `grep -n newyvar` over your code is the whole migration.

**If you never used the value**, nothing changes. That was true of every
caller we could find, which is why the fault survived from 0.9.4.23.



Upgrade notes for users switching from an older version of pdf4tcl
to the gregnix fork (0.9.4.x series).

Each section covers one version and lists only changes that affect
existing code. New features that do not break existing code are
not listed here -- see the CHANGES section in the manpage.

---

## From any version to 0.9.4.43

Two checks that refuse calls which used to be accepted, one new warning, and
two fixes that change the bytes of existing documents.

**`tagBegin` refuses a structure element the standard does not allow there.**
ISO 32000-1 tables 335 and 337 fix where a few types may appear:

```
LI                    in L
LBody                 in LI
THead, TBody, TFoot   in Table
TR                    in Table, THead, TBody or TFoot
TH, TD                in TR
TOCI                  in TOC
```

Every other type is unrestricted, and `NonStruct` is transparent -- a row
wrapped in one is still a row. Code that produced a cell outside a row now
gets an error where it previously got a document that passed every validator
and told a screen reader nothing.

**`tagEnd` refuses to close a container that must hold something.** The other
half of the same rule: `Table` needs rows, `L` needs items, `TR` needs cells.
Marked content does not count -- a table holding only text is still a table
without rows. A refused `tagEnd` leaves the element open, so the missing
content can be added and the element closed afterwards.

If existing code marked up an empty table or list, it now raises an error.
Such documents validated but were unusable, so the break is deliberate.

**An element closed with no content at all is reported, not refused.** No
marked content, no child element, no annotation -- the entry goes to
`::pdf4tcl::warnings`. `TD` and `TH` are exempt: a blank cell belongs in the
tree, and a missing one shifts the column mapping. An element holding only an
annotation is not empty, since `Link` and `Form` consist of an `/OBJR` and
never carry an MCID.

**Leftover content is reported at `finish`.** Painting operations that belong
to neither a structure element nor an artifact are counted, and a document
that has any gets an entry in `::pdf4tcl::warnings`. ISO 14289-1 clause 7.1
requires every piece of content to be one or the other; nothing said so
before. Existing code that tags only part of a page will now hear about it --
the output itself is unchanged. `getUntaggedCount` asks the same question
before finishing.

Only painting operators count (ISO 32000-1 table 51). Setting a colour or a
font outside an element is not a defect, and content inside an XObject is
covered by the tag on the `Do` that places it.

**`tagArtifact` works inside an XObject now.** An artifact carries no MCID,
so it needs neither a parent tree entry nor `/Stm` in an `/MCR`. `tagBegin`
inside an XObject stays refused.

**Two fixes that change output.** Both affect documents produced by 0.9.4.42:

* An encrypted document with a form field lost the ciphertext of empty
  appearance streams while `/Length` claimed its size. Readers opened such
  files anyway; `qpdf --check` reported `expected endstream`.
* A text field with an initial value carried `/AP` twice, which ISO 32000-1
  7.3.7 does not allow.

Documents written with 0.9.4.42 are worth regenerating for both reasons.

---

## From any version to 0.9.4.42

**Form fields can be part of the structure tree.** `tagBegin Form` was
accepted before, but annotations only attached to `Link` and `Annot`, so the
element stood in the tree and the field stayed unreachable. Existing tagged
forms gain the attachment automatically; the warning about an unattached
annotation stops appearing.

**The standard-font warning now applies to `tagged -ua` as well**, not only
to `-pdfa`. PDF/UA requires embedded fonts just as PDF/A does (7.21.4.1
against 6.3.5).

**Checkboxes and radio buttons draw their mark as vectors** where conformance
is claimed, instead of using a ZapfDingbats glyph that cannot be embedded.
The appearance changes slightly.

**Text fields get an `/AP` dictionary, checkboxes no longer write `/D` beside
`/N`.** ISO 19005 6.3.3 requires the dictionary and permits only `/N`.

---

## From any version to 0.9.4.41

Two additions, one of which may produce warnings in existing code.

**`-pdfa` accepts the level A values `1a`, `2a` and `3a`.** Level A wants
tagged PDF, a document language and Unicode mappings. pdf4tcl writes the
mappings itself; the other two are checked when the document is finished, and
a missing one raises an error rather than writing `pdfaid:conformance A` into
a file that has neither:

```tcl
$pdf tagged 1 -lang de-DE      ;# both required for -pdfa 3a
```

**Standard fonts with `-pdfa` now warn.** The 14 standard fonts have no
embeddable font program, and every PDF/A level requires one, so a document
using them cannot validate. That was true before as well -- the file simply
failed validation with nothing in pdf4tcl having mentioned it. Existing code
that produced non-conformant PDF/A output will now say so in
`::pdf4tcl::warnings`. The output itself is unchanged.

---

## From any version to 0.9.4.40

`pdf4tcl::catPdf` merges the logical structure of tagged input documents
instead of dropping it. Nothing in the API changes; the result simply keeps
its structure where it used to lose it.

Two cases still cannot be merged and warn in `::pdf4tcl::warnings`: an
untagged document appended to a tagged one, and a tagged one appended to an
untagged one. Code that relied on the structure being dropped -- there is no
good reason for that, but it was the behaviour of 0.9.4.36 to 0.9.4.39 --
gets a tagged result now.

---

## From any version to 0.9.4.39

**Color components are now range checked.** This is the one change here that
can break working code.

Components must be between 0.0 and 1.0. Values outside that range used to be
written into the PDF verbatim; they now raise an error. The most likely way
to hit this is code that passes 0 to 255:

```tcl
$pdf setFillColor 255 0 0        ;# was accepted, wrote "255 0 0 rg"
$pdf setFillColor 1 0 0          ;# correct
```

Such code was already producing the wrong color -- ISO 32000-1 clause 8.6.4
requires 0 to 1, and readers clamp anything else silently. The error makes a
long standing bug visible rather than introducing a new restriction. Divide by
255, or use the hex form `#ff0000`.

Everything else in this release only adds:

- Color names no longer need Tk. The 147 standard X11 and CSS names resolve
  from a built-in table, so `setFillColor red` works in a headless script.
  Names outside the table still ask Tk, so nothing that worked before stopped
  working.
- `linearGradient` and `radialGradient` accept everything `setFillColor`
  accepts. Their old parser knew eight names plus hex, so `navy` and CMYK
  lists were errors in a document where `setFillColor` took both. The shading
  now declares `/DeviceCMYK` rather than a fixed `/DeviceRGB` in a `-cmyk 1`
  document, which is a change in the generated file but not in the API.
- Gradient color components are written through `::pdf4tcl::Nf` like every
  other number, so `/C0 [1.0 0.0 0.0]` reads `/C0 [1 0 0]`. Same value,
  different notation. Only relevant if you compare generated PDFs literally.
- Tagged PDF: an annotation created while no `Link` or `Annot` element is
  open is now reported in `::pdf4tcl::warnings`. Nothing changes in the
  output; the annotation was unreachable from the structure tree before too,
  just silently.

`::pdf4tcl::rgb2Cmyk` and `::pdf4tcl::cmyk2Rgb` moved from `src/helpers.tcl`
to `src/color.tcl`. Same namespace, same behaviour, still overridable.

---

## From any version to 0.9.4.36 and 0.9.4.37

Both releases only add features; existing code is unaffected.

One behaviour changed for documents that switch tagging on:

- A page carrying annotations is written with `/Tabs /S` instead of
  `/Tabs /R`, so that tabbing follows the structure tree. ISO 14289-1
  clause 7.18.3 requires this. Untagged documents keep `/R`, which is the
  row order a plain form wants.

And one for `pdf4tcl::catPdf`:

- If any input document is tagged, the logical structure is removed from the
  result and a note is appended to `::pdf4tcl::warnings`. Merging structure
  trees is not supported: every page carries a `/StructParents` key indexing
  the parent tree of its own document, and every document numbers its pages
  from zero, so keeping the structure would leave pages resolving to the
  wrong elements. Merging untagged documents is unchanged.

See `doc/en/TAGGED.md` for what tagging does and where it stops.

---

## From any version to 0.9.4.25

### Paper size: A3 height changed

```tcl
# Before 0.9.4.25:
pdf4tcl::getPaperSize a3   ;# -> {842.0 1190.0}

# 0.9.4.25+:
pdf4tcl::getPaperSize a3   ;# -> {842.0 1191.0}
```

The A3 height was corrected from 1190.0 to 1191.0 pt to match
the precise ISO 216 value. The same applies to other paper sizes
whose rounded values changed slightly.

**What to check:** Tests or layout code that hardcodes `1190.0`
for A3 height. Replace with `[lindex [pdf4tcl::getPaperSize a3] 1]`.

### New paper formats: B and C series, 4A0, 2A0

The B0–B10, C0–C10, 4A0 and 2A0 formats are new. Existing code
is not affected.

### New write option: -chan

```tcl
$pdf write -chan $channel
```

Writes to an open channel. Existing `-file` and plain `write`
(stdout) continue to work unchanged.

---

## From any version to 0.9.4.23

### drawTextBox: new option -newyvar

```tcl
# New in 0.9.4.23 -- returns Y position after last line
$pdf drawTextBox $x $y $w $h $text -newyvar nextY
```

Existing code using `-linesvar` only is not affected.

**Important:** `-newyvar` returns an internal PDF coordinate
(Y from bottom) when `-orient false`. With `-orient true`
(the default) the value is directly usable as the next Y.

### getStringWidth: new keyword arguments

```tcl
# New optional arguments (0.9.4.23+):
$pdf getStringWidth $text -font Helvetica -size 12
```

The legacy positional call `$pdf getStringWidth $text` and
`$pdf getStringWidth $text 1` (internal flag) still work unchanged.

**Benefit:** You can now measure text width without a prior
`setFont` call, and measure with a specific font/size without
changing the document's current font.

---

## From any version to 0.9.4.22

### setAlpha under PDF/A-1b: warning instead of silent violation

```tcl
set pdf [::pdf4tcl::new %AUTO% -paper a4 -pdfa 1b]
$pdf setAlpha 0.5   ;# was: silently written (invalid PDF/A-1b)
                    ;# now: warning added to ::pdf4tcl::warnings
```

No exception is raised -- the PDF is generated regardless.
Check `::pdf4tcl::warnings` after document creation if PDF/A-1b
compliance matters.

```tcl
$pdf write -file out.pdf
$pdf destroy
if {[llength $::pdf4tcl::warnings] > 0} {
    puts "Warnings: $::pdf4tcl::warnings"
}
```

### PDF/A-2b: XRef stream and PDF 1.7

Documents created with `-pdfa 2b` now write:
- A cross-reference stream (required by ISO 19005-2)
- `%PDF-1.7` header (required by ISO 19005-2)

Standard PDFs (no `-pdfa`) and PDF/A-1b continue to write
`%PDF-1.4` with a classic xref table. No action needed unless
your code inspects the raw PDF bytes.

---

## From any version to 0.9.4.20

### rotate / scale / translate: coordinate system

```tcl
$pdf rotate 45 -x $cx -y $cy
$pdf scale 2.0 2.0
$pdf translate $dx $dy
```

These methods are new in 0.9.4.20. They apply PDF `cm` operators
and set an internal `rawcoords` flag so subsequent drawing commands
work correctly in the transformed coordinate system.

**What to check:** Any code that previously applied transformations
via raw `$pdf rawpdf "... cm"` calls. The new methods handle
coordinate conversion and the rawcoords flag automatically.

---

## From any version to 0.9.4.13

### setBlendMode: new method

No impact on existing code. New method only.

### linearGradient / radialGradient

No impact on existing code. New methods only.

---

## From any version to 0.9.4.11

### Encryption: new constructor options

```tcl
::pdf4tcl::new pdf -paper a4 \
    -userpassword  "open"  \
    -ownerpassword "owner" \
    -encversion 4
```

No impact on existing code (options default to no encryption).

---

## From any version to 0.9.4.8

### PDF/A: new constructor option -pdfa

```tcl
::pdf4tcl::new pdf -paper a4 -pdfa 1b
```

No impact on existing code (-pdfa defaults to "", standard PDF).

---

## General notes

### package require and version checking

```tcl
# Safe -- works with any version:
package require pdf4tcl

# Requires gregnix 0.9.4.23+, fails on older versions:
package require pdf4tcl 0.9.4.23

# Defensive check:
package require pdf4tcl
if {[package vcompare [package version pdf4tcl] 0.9.4.23] < 0} {
    error "pdf4tcl 0.9.4.23 or newer required"
}
```

### Feature detection

> **Note:** `pdf4tcl::hasFeature` is planned for a future release
> and not yet available. Until then, use `package vcompare` directly
> (see example below).

`pdf4tcl::hasFeature` will return 1 if a feature is available in the
loaded version, 0 otherwise.

```tcl
# Example: use -newyvar if available, fall back to -linesvar
if {[pdf4tcl::hasFeature newyvar]} {
    $pdf drawTextBox $x $y $w $h $text -newyvar nextY
} else {
    set nlines 0
    $pdf drawTextBox $x $y $w $h $text -linesvar nlines
    set nextY [expr {$y + $nlines * $lineH}]
}
```

```tcl
# Example: use encryption only if available
if {[pdf4tcl::hasFeature encryption]} {
    set pdf [::pdf4tcl::new %AUTO% -paper a4 -userpassword "secret"]
} else {
    set pdf [::pdf4tcl::new %AUTO% -paper a4]
}
```

Available feature names:

| Feature | Available since | Description |
|---------|----------------|-------------|
| `pdfa-level-a` | 0.9.4.41 | -pdfa 1a/2a/3a, standard font warning |
| `struct-merge` | 0.9.4.40 | catPdf merges structure trees |
| `color-range` | 0.9.4.39 | color components validated, names without Tk, gradients share the pipeline |
| `tagged-annot` | 0.9.4.37 | `tagBegin Link/Annot`, `/OBJR`, `-listnumbering`, `-id`, `-headers` |
| `tagged` | 0.9.4.36 | Tagged PDF: `tagged`, `tagBegin`, `tagEnd`, `tagText`, `tagArtifact` |
| `write-chan` | 0.9.4.25 | `write -chan $channel` option |
| `b-c-paper` | 0.9.4.25 | ISO B/C paper sizes (b0-b10, c0-c10) |
| `newyvar` | 0.9.4.23 | `drawTextBox -newyvar` option |
| `annotations` | 0.9.4.23 | `addAnnotNote`, `addAnnotHighlight` etc. |
| `layers` | 0.9.4.21 | `addLayer`, `beginLayer`, `endLayer` |
| `transform` | 0.9.4.20 | `rotate`, `scale`, `translate`, `transform` |
| `aes256` | 0.9.4.16 | AES-256 encryption (V=5/R=6) |
| `gradients` | 0.9.4.13 | `linearGradient`, `radialGradient` |
| `encryption` | 0.9.4.11 | AES-128 encryption (V=4/R=4) |
| `alpha` | 0.9.4.10 | `setAlpha`, `getAlpha` |
| `pdfa` | 0.9.4.8 | `-pdfa 1b/2b/3b` constructor option |
| `cidfont` | 0.9.4.5 | CIDFont / Unicode TTF embedding |

Unknown feature names return 0 without error.
