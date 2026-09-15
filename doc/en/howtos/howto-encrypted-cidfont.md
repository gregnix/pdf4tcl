# How-to: Encrypt a PDF that uses your own font

## Runnable script

```bash
tclsh doc/en/howtos/howto-encrypted-cidfont.tcl
# PDF -> doc/en/out/
```

Companion: [`howto-encrypted-cidfont.tcl`](howto-encrypted-cidfont.tcl).

## Problem

A password-protected document that needs an embedded TrueType font --
because of umlauts, Cyrillic, Greek, or simply a house font.

## Recipe

Nothing special. Load the font, set the passwords, write.

```tcl
pdf4tcl::loadBaseTrueTypeFont base /usr/share/fonts/truetype/dejavu/DejaVuSans.ttf
pdf4tcl::createFontSpecCID base mine

set pdf [::pdf4tcl::new %AUTO% -paper a4 \
        -userpassword "open-me" -ownerpassword "change-me" \
        -permissions {print}]
$pdf startPage
$pdf setFont 14 mine
$pdf text "Grüße aus München" -x 50 -y 750
$pdf write -file out.pdf
```

`-permissions {print}` allows printing and forbids copying the text --
useful for a sheet that is meant to be printed and not pasted
elsewhere.

## Check it

Two readers, no trust required:

```bash
qpdf --password=open-me --check out.pdf     # no stream errors
pdftotext out.pdf -                         # Incorrect password
pdftotext -upw open-me out.pdf -            # your text
```

**All three matter.** The first two alone would also pass for a
document that is encrypted but broken -- which is exactly what
0.9.4.66 produced.

## Requires 0.9.4.67

Up to and including 0.9.4.66 the font objects were written past the
encryption. The file came out, was tight without a password, and could
not be opened **with** one either:

```
qpdf:      error decoding stream data: inflate: incorrect header check
pdftotext: (empty)
```

If you built a workaround -- falling back to a standard font for
encrypted output -- you can drop it. Documents already produced carry
the defect and should be rebuilt.

Background:
[`pdf4tcl-encryption.md`](../reference/pdf4tcl-encryption.md#encryption-and-embedded-fonts).

## AES-256

`-encversion 5` works the same way. Note the runtime: with the pure-Tcl
SHA backend a document takes seconds rather than milliseconds -- see
the note in `pdf4tcl-encryption.md`.
