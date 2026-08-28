# Choosing a font: standard, subset or CID

Three ways to get characters onto a page, and the choice decides file size,
which characters appear at all, and whether the text can be copied out again.
This document compares them on measured numbers. For the API itself see
`pdf4tcl-text-and-fonts.md` (standard fonts) and `pdf4tcl-cidfont-manual.md`
(embedded fonts).

Applies to 0.9.4.43.

---

## The three ways at a glance

```tcl
# 1. Standard font -- nothing to load, nothing embedded
$pdf setFont 12 Helvetica

# 2. Subset of an embedded font -- up to 256 codepoints, chosen by you
pdf4tcl::loadBaseTrueTypeFont Base /path/DejaVuSans.ttf
pdf4tcl::createFontSpecEnc Base Sub {63 65 66 67 ...}
$pdf setFont 12 Sub

# 3. CID font -- every character the font has
pdf4tcl::loadBaseTrueTypeFont Base /path/DejaVuSans.ttf
pdf4tcl::createFontSpecCID Base Uni
$pdf setFont 12 Uni
```

The same line of text, written three times with DejaVu Sans as the embedded
font. Measured, not estimated -- `Gruesse Ellada Priwet arrow check` in its
proper spelling, one page, uncompressed:

| Way | What comes out when copied | File |
|---|---|---|
| `Helvetica` | `Grüße ?????? ?????? ? ?` | 5 027 bytes |
| `createFontSpecEnc` (11 codepoints) | `Grüße GGGGGG ПGGGGG → ✓` | 22 732 bytes |
| `createFontSpecCID` | `Grüße Ελλάδα Привет → ✓` | 137 060 bytes |

Three things to read out of that table.

**The standard font substitutes visibly.** Anything outside WinAnsi becomes
`?`, both on the page and in the clipboard. Ugly, but honest -- you can see
the problem.

**The subset substituted wrongly here.** `Ελλάδα` came out as `GGGGGG`. That
is not a bug, it is the fallback: characters missing from the subset are
replaced by `?` *if `?` is part of the subset*, and otherwise by slot 0 --
the first codepoint you listed. Text that reads like real text and is not.
See the trap below.

**The CID font is right and, since 0.9.4.57, no longer large.** The figures
in the table are uncompressed, which is what makes them comparable; with
`-compress 1` the same line comes to about 50 KB. Before 0.9.4.57 it was
762 698 uncompressed and 386 728 compressed, because the entire font went in
whatever the document drew.

---

## The trap in the subset: always include `?`

`createFontSpecEnc` takes the codepoints you want. Characters outside that
list fall back in two steps -- and only the first step is any good:

```tcl
# Without 63 (?) in the subset
pdf4tcl::createFontSpecEnc Base E1 {71 114 252 223 101 32}
$pdf setFont 12 E1
$pdf text "Grüße Ελλάδα" -x 50 -y 700
# -> "Grüße GGGGGG"        the missing characters became slot 0, which is "G"

# With 63 (?) in the subset
pdf4tcl::createFontSpecEnc Base E2 {63 71 114 252 223 101 32}
$pdf text "Grüße Ελλάδα" -x 50 -y 700
# -> "Grüße ??????"        recognisable as missing
```

Both measured. The difference is one number in the list.

`getSubstCount` counts the replacements in both cases. It counts up over the
life of the object and is never reset:

```tcl
$pdf text $line -x 50 -y 700
if {[$pdf getSubstCount] > 0} {
    puts stderr "[$pdf getSubstCount] characters were replaced"
}
```

That counter is the only signal you get. Nothing throws, nothing warns.

**And under Tcl 8.6 it does not count at all.** The counter is incremented in
the error path of `encoding convertto`, and the two generations behave
differently there:

```
Tcl 9.0.4    encoding convertto cp1252 "Ελλάδα"  ->  error
Tcl 8.6.14   the same call                       ->  "??????", no error
```

Both documents come out with `??????` on the page -- the substitution happens
either way. Only Tcl 9 reports it. On 8.6, compare the text against the
encoding yourself if the number matters:

```tcl
proc unmappable {text enc} {
    set n 0
    foreach ch [split $text {}] {
        if {[catch {encoding convertto $enc $ch} out] || $out eq "?" && $ch ne "?"} {
            incr n
        }
    }
    return $n
}
```

---

## The trap in the CID font: a missing glyph is silent

A CID font covers every character *the font file has*. DejaVu Sans has no CJK,
so this happens:

```tcl
pdf4tcl::createFontSpecCID Base Uni
$pdf setFont 12 Uni
$pdf getStringWidth "\u65E5\u672C"     ;# -> 14.4, a real number
$pdf text "\u65E5\u672C" -x 50 -y 680  ;# no error, no warning
```

In the content stream the result is:

```
<00240025> Tj      "AB"     -- two real glyph IDs
<00000000> Tj      CJK      -- twice glyph 0, .notdef
```

Glyph 0 is the empty box. `getSubstCount` stays at zero -- it counts encoding
substitutions, and a CID font encodes everything, it just has no picture for
it. The page looks broken and nothing in the API said so.

It costs the text as well. `text "AB日本CD"` written in DejaVu Sans
produces `<002400250000000000260027>`, and `pdftotext` recovers **`AB`** --
not `ABCD`, not `AB??CD`. The run of glyph 0 ends the extractable text.
So a missing glyph is not merely invisible: it takes the rest of that string
with it.

Check coverage before writing, not after:

```tcl
proc glyphAvailable {baseName codepoint} {
    return [dict exists $::pdf4tcl::BFA($baseName,charToGlyph) $codepoint]
}

foreach ch [split $text {}] {
    scan $ch %c n
    if {![glyphAvailable Base $n]} {
        puts stderr "U+[format %04X $n] is not in this font"
    }
}
```

Measured against DejaVu Sans: `A`, `ü`, `Ω`, `Ж`, `→`, `✓` all present,
`日` absent. A ready-made script is in
[`howtos/howto-font-coverage.md`](../howtos/howto-font-coverage.md).

---

## Size: what a subset saves

Same document, one line of text, compressed:

| Font | File |
|---|---|
| subset, 5 codepoints | 8 860 bytes |
| subset, 50 codepoints | 15 140 bytes |
| subset, 200 codepoints | 29 761 bytes |
| CID | 50 004 bytes |

Both paths build a real TrueType subset -- the file grows with what the
document uses, not with the size of the face. Before 0.9.4.57 the CID row
read 386 728 bytes.

### Why the CID font stays larger

The two subsetters solve different problems.

`createFontSpecEnc` **renumbers**: the subset gets glyphs 0 to N-1 and the
encoding maps character codes onto them. Nothing outside the font object
refers to a glyph number, so the numbering is free.

`createFontSpecCID` **cannot renumber.** With `/CIDToGIDMap /Identity` the
glyph number *is* what stands in the content stream, and that stream is
written while you draw -- long before the font goes out. So the numbering is
kept: `loca` keeps an entry for every glyph of the original face, `hmtx` its
metrics, and only `glyf` is emptied out.

That is where the bytes are. Measured on DejaVuSans, 759 720 bytes:

| Table | Bytes | |
|---|---|---|
| `glyf` | 557 508 | 73% -- this is what shrinks |
| `GPOS` | 40 586 | dropped; read into memory at load time |
| `loca` | 25 016 | kept in full |
| `hmtx` | 24 982 | kept in full |

`cmap` goes too: Identity-H addresses glyphs directly and never consults it.

### What comes along besides the glyphs you drew

**Components of composite glyphs.** An a-umlaut is not one outline but two:
the base letter and the accent, each a glyph of its own. Keep only the
composite and a reader draws nothing. pdf4tcl walks the closure -- measured,
three umlauts in DejaVuSans end up as eight glyphs: the three composites,
four components between them, and glyph 0.

**Glyph 0.** A CID font needs a description for CID 0 -- the counterpart
of `.notdef` in a simple font. See ISO 32000-2, clause 9.7.4.2.

### What a subset has to declare

Two entries exist only because the font is a subset, and both were required
from the moment subsetting arrived:

`/BaseFont` and the descriptor's `/FontName` carry a tag of six uppercase
letters and a plus sign (ISO 32000-1 clause 9.6.4) -- `DCUEDB+DejaVuSans`.
Different subsets of one face in one file must carry different tags, which
is how a reader tells them apart and can merge them. pdf4tcl derives the
letters from the glyph set, so the same subset always gets the same tag.

`/CIDSet` names the CIDs present in the font programme (ISO 19005-1 clause
6.3.5). Measured: a PDF/A-1b document failed at that clause the moment the
tag appeared, because a tagged font is a subset and a subset needs the set.

### What is not subsetted

**CFF and OpenType/CFF.** The format differs enough to need its own writer;
`FontFile3` still carries the whole binary.

256 codepoints is not a limit you can raise: the subset way is capped by
the PDF simple-font model, not by pdf4tcl.

```tcl
# Refused, and rightly so
pdf4tcl::createFontSpecEnc Base Big [lrange $manyCodepoints 0 300]
# -> createFontSpecEnc: subset must not exceed 256 codepoints (got 301)
```

An empty subset is not handled gracefully -- `createFontSpecEnc Base X {}`
fails inside the subsetting code with `can't read "tlist"`. Pass at least the
characters you actually use.

---

## Which one to take

**Standard font** when the text is Latin-1 and the file should stay small:
invoices, letters, forms in one Western European language. Nothing to install
on the target machine, and since 0.9.4.9 the ToUnicode CMap makes the text
extractable.

Not usable for PDF/A or PDF/UA. The 14 standard fonts have no embeddable font
program, and both standards require embedding. pdf4tcl says so:

```tcl
set pdf [::pdf4tcl::new %AUTO% -pdfa 3b]
$pdf setFont 12 Helvetica
$pdf text "Test" -x 50 -y 700
$pdf finish
# ::pdf4tcl::warnings ->
#   PDF/A: the standard font Helvetica has no embeddable font program ...
```

With a CID font the same document produces no warning.

**Subset** when the character repertoire is known and closed: a form with
fixed labels, a report in one language, a document with a handful of symbols.
It is the only way to embed a font and stay under 30 KB.

**CID font** when the text is not known in advance -- user input, database
content, several scripts on one page. Also the way to go for anything
multilingual, and the only one that reaches beyond 256 characters.

Mixing is allowed and often right: standard font for the bulk of the text,
CID font for the one line that needs it.

```tcl
$pdf setFont 11 Helvetica
$pdf text "Customer: " -x 50 -y 700
$pdf setFont 11 Uni
$pdf text $nameFromDatabase -x 110 -y 700
```

---

## Characters beyond the BMP, and why Tcl 8.6 differs

Emoji, historic scripts and rare CJK live above U+FFFF. What arrives at
pdf4tcl depends on the Tcl generation *and* on how the text got into the
script.

Written as a literal in the source:

```tcl
set s "\U0001F600"
```

| | `string length` | first character | extracted from the PDF |
|---|---|---|---|
| Tcl 9.0.4 | 1 | U+1F600 | `F0 9F 98 80` -- correct |
| Tcl 8.6.14 | 1 | **U+FFFD** | `EF BF BD` -- replacement character |

Under 8.6 the character is lost in the literal, before pdf4tcl ever sees it.

Read from a UTF-8 file, the same text works in both:

```tcl
set ch [open text.txt r]
fconfigure $ch -encoding utf-8
set s [read $ch]
close $ch
```

| | `string length` of `A<emoji>B` | extracted |
|---|---|---|
| Tcl 9.0.4 | 3 | `A F0 9F 98 80 B` -- correct |
| Tcl 8.6.14 | 4 | `A F0 9F 98 80 B` -- correct |

Both produce the right PDF. The lengths differ because 8.6 keeps the
character as a surrogate pair, and that leaks into anything counting
characters -- column widths, truncation, manual line breaking. `getStringWidth`
measures in points and is unaffected in practice (12.30 against 12.51 here,
the difference being the missing glyph's width, not the encoding).

Rules that follow:

* Do not write `\U`-escapes above U+FFFF in source that must run under 8.6.
  Read such text from a UTF-8 file.
* Count in points with `getStringWidth`, not in characters with
  `string length`, whenever the number decides a layout.
* Extraction is not proof of a visible glyph. The ToUnicode CMap is written
  from the codepoint, whether or not the font has a picture for it: CJK text
  set in DejaVu Sans extracts perfectly and is a row of empty boxes on the
  page. Check coverage, do not trust `pdftotext`.

A detail worth knowing before reaching for a second font: DejaVu Sans does
carry part of the Emoticons block. `U+1F600` maps to glyph 5857 and is
painted -- in black and white, as an outline. The highest codepoint in the
file is `U+1F643`. Colour emoji need CBDT/COLR fonts, which pdf4tcl does not
embed.

---

## Checking a finished document

```bash
pdftotext out.pdf -            # what a reader would copy out
qpdf --check out.pdf           # structure and streams
```

`pdftotext` answers one question only: is the text recoverable. It says
nothing about whether anything is visible. For that, check coverage before
writing (see above) or look at the rendered page.

For PDF/A and PDF/UA the font question is settled by embedding:

```bash
python3 tools/check-conformance.py out.pdf
```

---

## See also

| | |
|---|---|
| `pdf4tcl-text-and-fonts.md` | text API, the 14 standard fonts, WinAnsi |
| `pdf4tcl-cidfont-manual.md` | embedding TrueType and OTF, font coverage tables |
| `howtos/howto-stdfonts.md` | standard fonts and ToUnicode |
| `howtos/howto-unicode.md` | CID fonts, recipe |
| `howtos/howto-font-coverage.md` | check which characters a font paints |
| `howtos/howto-otf.md` | OpenType/CFF |
| `howtos/howto-kerning.md` | pair kerning, and does the width match |
| `howtos/howto-ligatures.md` | fi and fl, and is the text still searchable |
| `howtos/howto-symbols.md` | symbol and coverage charts |
| `tutorials/tutorial-07-multilingual.md` | a document in five scripts |

## The name you give a font

`createFont`, `createFontSpecEnc` and `createFontSpecCID` let you choose the
name. Two things depend on it.

**It ends up in the PDF as a name object.** A space is not allowed there
unescaped; pdf4tcl writes `DejaVu Sans` as `/DejaVu#20Sans` (ISO 32000-1
clause 7.3.5). Before 0.9.4.60 the space went in raw, and the page stayed
empty -- no error, no warning, and qpdf reporting `unknown token while
reading object`.

**On a canvas it is looked up as a family name.** Since 0.9.4.60 the canvas
export takes a font that is named like the Tk font family, so no `-fontmap`
is needed:

```tcl
pdf4tcl::loadBaseTrueTypeFont Base tahoma.ttf
pdf4tcl::createFontSpecCID Base Tahoma       ;# named like the Tk family
$pdf canvas .tp                              ;# no mapping
```

The 14 standard fonts are excluded from that lookup. Naming your own font
`Helvetica` therefore does replace the standard font on a canvas -- which is
presumably what you meant by the name, but worth knowing.

See [`pdf4tcl-canvas.md`](pdf4tcl-canvas.md) for which family name is used
on which canvas.
