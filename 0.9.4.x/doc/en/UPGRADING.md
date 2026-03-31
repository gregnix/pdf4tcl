# UPGRADING -- pdf4tcl gregnix fork

Upgrade notes for users switching from an older version of pdf4tcl
to the gregnix fork (0.9.4.x series).

Each section covers one version and lists only changes that affect
existing code. New features that do not break existing code are
not listed here -- see the CHANGES section in the manpage.

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
