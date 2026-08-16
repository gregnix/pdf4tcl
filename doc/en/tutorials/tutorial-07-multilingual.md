# Tutorial 7 -- A document in five scripts

## Runnable script

```bash
tclsh doc/en/tutorials/tutorial-07-multilingual.tcl
# PDF -> doc/en/out/
```

Companion: [`tutorial-07-multilingual.tcl`](tutorial-07-multilingual.tcl).

Put German, Polish, Greek, Russian and Japanese on one page, find out where
the font gives up, and mix an embedded font with a standard one. Needs a
TrueType font on the machine -- DejaVu Sans on Debian and Ubuntu comes from
`fonts-dejavu-core`.

Everything below was measured with the script, not assumed.

## Step 1 -- load the font and ask what it can do

```tcl
pdf4tcl::loadBaseTrueTypeFont Base $fontFile
pdf4tcl::createFontSpecCID Base Uni
```

`createFontSpecCID` gives a font that can encode any codepoint. That is not
the same as painting one, so ask before writing:

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
```

With DejaVu Sans the five European lines come back clean and the Japanese one
reports seven missing glyphs. The script prints that next to the line, so the
page itself shows where the font ends.

Why this matters more than it looks: a missing glyph is silent. No error, no
warning, and `getSubstCount` stays at zero -- a CID font *encodes* everything,
it simply has no picture. Worse, it takes the text with it:

```tcl
$pdf text "AB\u65E5\u672CCD" -x 50 -y 700
# content stream: <002400250000000000260027>
# pdftotext:      AB
```

Not `ABCD`, not `AB??CD`. The run of glyph 0 ends the extractable text.

## Step 2 -- the page

Nothing special once the font is in place:

```tcl
$pdf setFont 11 Uni
$pdf text "Καλημέρα -- Ελληνικά κείμενα" -x 90 -y $y
```

The same call carries every script. That is the whole point of the CID font,
and the reason the file is 760 KB: the entire font goes in. If the repertoire
is fixed and small, `createFontSpecEnc` embeds a subset instead and lands
under 30 KB -- see
[`../reference/pdf4tcl-fonts-and-unicode.md`](../reference/pdf4tcl-fonts-and-unicode.md).

## Step 3 -- mixing two fonts on one line

Standard font for the label, embedded font for the value:

```tcl
$pdf setFont 12 Helvetica
$pdf text "Mixed: Helvetica for the label, " -x 0 -y $y
set w [$pdf getStringWidth "Mixed: Helvetica for the label, "]
$pdf setFont 12 Uni
$pdf text "Ελλάδα for the value" -x $w -y $y
```

`getStringWidth` measures the *current* font in points, which is what makes
the second call land in the right place. Counting characters would not work:
under Tcl 8.6 a character above U+FFFF is a surrogate pair and counts as two,
under Tcl 9 as one. Measure in points whenever the number decides a position.

## Step 4 -- the same text in a standard font

```tcl
$pdf setFont 10 Helvetica
$pdf text "Ελληνικά κείμενα" -x 0 -y $y
```

Everything outside WinAnsi becomes `?` -- on the page and in the clipboard.
The script writes the substitution count onto the page, and here the two Tcl
generations part ways:

| | on the page | `getSubstCount` |
|---|---|---|
| Tcl 9.0.4 | `??????` | 61 |
| Tcl 8.6.14 | `??????` | **0** |

The substitution happens in both. Only Tcl 9 reports it, because
`encoding convertto` raises an error there and replaces silently on 8.6 --
and pdf4tcl counts in the error path. The script prints which case it is in
rather than pretending the zero means success.

## What to take away

1. Ask the font what it has before you write. Nothing else will tell you.
2. `pdftotext` proves the text is recoverable, not that it is visible. A row
   of empty boxes extracts as nothing at all.
3. Measure widths in points, never in characters.
4. On Tcl 8.6, `getSubstCount` is not a safety net.

## Next

- [`../reference/pdf4tcl-fonts-and-unicode.md`](../reference/pdf4tcl-fonts-and-unicode.md) --
  standard font against subset against CID, with sizes
- [`../howtos/howto-font-coverage.md`](../howtos/howto-font-coverage.md) --
  the coverage check as a standalone script
- [`../reference/pdf4tcl-cidfont-manual.md`](../reference/pdf4tcl-cidfont-manual.md) -- the CID
  API in full, including OTF/CFF
