# How-to: Symbol and Unicode coverage charts

Demos:
- `demo-symbole.tcl` -- DejaVu CID repertoire (Latin Ext, Greek, Cyrillic,
  maths, arrows, box drawing, dingbats, …)
- `demo-unicode-tabelle.tcl` -- broader Unicode tables (Tcl 8 vs 9 differ
  above U+FFFF; the demo detects replacement glyphs at runtime)

## Problem

See which characters a font actually paints before shipping a document.

## Recipe

```bash
# needs fonts-dejavu-core (or pass a path)
tclsh 0.9.4.x/demo/demo-symbole.tcl
tclsh 0.9.4.x/demo/demo-symbole.tcl /path/to/DejaVuSans.ttf

tclsh 0.9.4.x/demo/demo-unicode-tabelle.tcl
```

In your own code, load CID as usual:

```tcl
pdf4tcl::loadBaseTrueTypeFont BaseDejaVu /usr/share/fonts/truetype/dejavu/DejaVuSans.ttf
pdf4tcl::createFontSpecCID BaseDejaVu Uni
$pdf setFont 12 Uni
$pdf text "∑ ∫ → ★ ─ │ α β Я" -x 50 -y 50
```

Check substitutions with `getSubstCount` after drawing. For SMP emoji and
code points above U+FFFF, prefer Tcl 9 and an outline font that covers them;
bitmap emoji fonts are not supported.

See also `howto-unicode.md`, `howto-stdfonts.md`, `../pdf4tcl-cidfont-manual.md`.
