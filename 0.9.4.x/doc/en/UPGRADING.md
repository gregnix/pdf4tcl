# UPGRADING -- pdf4tcl gregnix fork

Upgrade notes for users switching from an older version of pdf4tcl
to the gregnix fork (0.9.4.x series).

Each section covers one version and lists only changes that affect
existing code. New features that do not break existing code are
not listed here -- see the CHANGES section in the manpage.

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

See `0.9.4.x/doc/en/TAGGED.md` for what tagging does and where it stops.

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
