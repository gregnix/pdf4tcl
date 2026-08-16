# How-to: check which characters a font can paint

## Runnable script

```bash
tclsh doc/en/howtos/howto-font-coverage.tcl
# PDF -> doc/en/out/

# a different font
tclsh doc/en/howtos/howto-font-coverage.tcl "" \
      /usr/share/fonts/truetype/freefont/FreeSerif.ttf
```

Companion: [`howto-font-coverage.tcl`](howto-font-coverage.tcl).

## Problem

A CID font encodes every codepoint you give it. Whether the font file has a
picture for that codepoint is a different question, and nothing in the API
raises it: no error, no warning, and `getSubstCount` stays at zero. The page
comes out with empty boxes where the characters should be.

Measured, DejaVu Sans, `text "\u65E5\u672C"`:

```
<00240025> Tj      "AB"      -- two real glyph IDs
<00000000> Tj      CJK       -- twice glyph 0, .notdef
```

`pdftotext` recovers the characters from either document -- the ToUnicode
CMap is written from the codepoint, not from the glyph. Extraction is
therefore no proof that anything is visible.

## Recipe

```tcl
proc glyphAvailable {baseName codepoint} {
    return [dict exists $::pdf4tcl::BFA($baseName,charToGlyph) $codepoint]
}

proc missingGlyphs {baseName text} {
    set missing {}
    foreach ch [split $text {}] {
        scan $ch %c n
        if {![glyphAvailable $baseName $n]} { lappend missing $n }
    }
    return $missing
}

pdf4tcl::loadBaseTrueTypeFont Base /usr/share/fonts/truetype/dejavu/DejaVuSans.ttf

set missing [missingGlyphs Base $line]
if {[llength $missing] > 0} {
    foreach n $missing { puts stderr "U+[format %04X $n] not in this font" }
}
```

`BFA($base,charToGlyph)` is filled by `loadBaseTrueTypeFont`, so the check
works before a single page exists.

## What the script reports

DejaVu Sans 2.37, measured:

| Block | Result |
|---|---|
| Latin, Latin ext, Greek, Cyrillic | complete |
| maths, arrows, box drawing, dingbats | complete |
| Hebrew, Arabic | complete (letters; shaping is another matter, see below) |
| CJK | 5 missing out of 5 |
| Emoticons | partly present -- `U+1F600` is glyph 5857 |

The emoji result surprises people. DejaVu carries part of the Emoticons block
as black-and-white outlines; the highest codepoint in the file is `U+1F643`.
Colour emoji live in CBDT/COLR fonts, which pdf4tcl does not embed.

## Present is not the same as readable

Coverage answers one question: does the font have a picture. Two things it
does not answer.

**Shaping.** Arabic letters have initial, medial and final forms, and Indic
scripts reorder. pdf4tcl writes glyphs in the order the codepoints arrive.
Hebrew and Arabic therefore *report* as complete and still come out wrong --
unjoined, and in visual rather than logical order.

**Direction.** Right-to-left text needs to be reversed by the caller.

For those scripts the honest answer is that pdf4tcl draws glyphs, not
paragraphs. See `pdf4tcl-cidfont-manual.md`, "Bidirectional Text".

## When a font is missing characters

Three ways out, in order of how often they are right:

1. **A different font.** FreeSerif covers more scripts than DejaVu;
   `fonts-unifont` covers nearly the whole BMP at the cost of looks.
2. **A second font for the exception.** Switch fonts for the one line that
   needs it -- see `pdf4tcl-fonts-and-unicode.md`.
3. **Substitute in the text.** For box drawing and typographic characters a
   `string map` to ASCII is often better than a font change.

## See also

- [`pdf4tcl-fonts-and-unicode.md`](../reference/pdf4tcl-fonts-and-unicode.md) --
  choosing between standard font, subset and CID
- [`howto-symbols.md`](howto-symbols.md) -- printed coverage charts
- [`howto-unicode.md`](howto-unicode.md) -- the CID recipe itself
- `demo/demo-unicode-tabelle.tcl` -- full tables per font
