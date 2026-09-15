# pdf4tcl Encryption: AES-128 and AES-256

PDF encryption support in pdf4tcl from version 0.9.4.16 onward
(fork gregnix/pdf4tcl).

## Overview

| Option | Default | Algorithm | PDF version | Dependencies |
|--------|---------|-----------|-------------|--------------|
| `-encversion 4` | yes | AES-128 | 1.5+ | Tcllib only |
| `-encversion 5` | no | AES-256 | 2.0 | Tcllib + SHA backend (see below) |

## AES-128 (Default)

No external programs required. Tcllib (md5, aes) is sufficient.

```tcl
set p [pdf4tcl::new %AUTO% -paper a4 -orient 1 \
    -userpassword  "secret" \
    -ownerpassword "admin"]
$p startPage
$p setFont 12 Helvetica
$p text "Encrypted content" -x 50 -y 50
$p endPage
$p write -file output.pdf
$p destroy
```

## AES-256

Activated with `-encversion 5`. Produces PDF 2.0 files, compatible with
Adobe Reader, Evince, qpdf, and pikepdf.

```tcl
set p [pdf4tcl::new %AUTO% -paper a4 -orient 1 \
    -userpassword  "secret" \
    -ownerpassword "admin" \
    -encversion    5]
```

### SHA Backend for AES-256

AES-256 requires SHA-384/512 for key derivation. pdf4tcl selects the
fastest available backend automatically:

| Backend | Speed | Requirement |
|---------|-------|-------------|
| tcl-sha | fast (~0.5 s/PDF) | install tcl-sha package |
| openssl | medium (2-4 s/PDF) | openssl in PATH |
| pure-tcl | slow (~24 s/PDF) | none, always available |

For time-critical use, install tcl-sha or ensure openssl is in PATH.
For occasional use, the pure-Tcl fallback works without any installation.

AES-128 has no such dependency and is recommended when performance matters.

## Options

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `-userpassword` | String | `""` | Password to open the PDF |
| `-ownerpassword` | String | `""` | Owner password (full access) |
| `-encversion` | 4 or 5 | `4` | Encryption level |
| `-permissions` | list/string/int | `all` | Access rights after opening |

If only `-ownerpassword` is set, it also serves as the user password.

## Permissions

`-permissions` controls what a user may do **after** opening the PDF.
It does not protect against opening -- that is the role of `-userpassword`.

### The Two-Password Model

| Password | Role | May do |
|----------|------|--------|
| user password | reader | only what `-permissions` permits |
| owner password | owner | everything, regardless of `-permissions` |

`-permissions` is only meaningful in combination with `-userpassword`.
Without a user password the file opens without any barrier, and
`-permissions` is merely a hint to the viewer.

```tcl
# Lock the file AND restrict what the reader may do:
set p [pdf4tcl::new %AUTO% -paper a4 -orient 1 \
    -userpassword  "readonly" \
    -ownerpassword "admin" \
    -permissions   {print}]
# reader opens with "readonly" -> print only
# owner opens with "admin"    -> all rights
```

### Presets

| Value | Rights |
|-------|--------|
| `all` | all allowed (default) |
| `none` | none allowed |
| `readonly` | print only |

### Symbolic Flags

```tcl
-permissions {print copy fill-forms}
```

Available flags: `print`, `hq-print`, `modify`, `copy`, `annotate`,
`fill-forms`, `accessibility`, `assemble`.

### Direct Integer

```tcl
-permissions -196   ;# direct /P value
```

### Note

`-permissions` is respected by conforming viewers (Adobe Acrobat, Foxit).
It is not a technical barrier -- the owner password always grants full access.

## Encryption and Forms

When encryption is active, pdf4tcl encrypts all string values in
dictionaries (AcroForm fields, metadata, bookmarks) in addition to
page content streams. This ensures that field names, values, labels,
and tooltips are protected alongside the document content.

## Encryption and embedded fonts

Nothing to do: an encrypted document with a CID/TrueType font of your own
is produced like any other.

```tcl
pdf4tcl::loadBaseTrueTypeFont dejavu /path/DejaVuSans.ttf
pdf4tcl::createFontSpecCID dejavu mine

set p [pdf4tcl::new %AUTO% -paper a4 -userpassword secret -permissions {print}]
$p startPage
$p setFont 12 mine
$p text "Grusse aus Munchen" -x 50 -y 700
$p write -file out.pdf
```

**Up to and including 0.9.4.66 this was broken.** The five objects of
the font -- the font program, the CID set, the ToUnicode map and the two
dictionaries -- were written straight to the file and never encrypted.
The result looked right: the document was produced, and without a
password nothing could be read from it. But **with** the password it
could not be read either:

```
qpdf --password=secret --check
    error decoding stream data: inflate: incorrect header check
pdftotext -upw secret
    (empty)
```

The font stream was byte-identical to the one in an unencrypted file,
and a reader that obeys `/Encrypt` decrypts it anyway -- and gets
garbage. ISO 32000-1 clause 7.6.2 leaves no room here: all strings and
streams of a document are encrypted, with a short, named list of
exceptions that a font program is not part of.

Fixed in **0.9.4.67**. If you worked around it -- by falling back to a
standard font for encrypted output -- you can drop the workaround.
Documents produced with 0.9.4.66 or earlier carry the defect; rebuild
them.

The same applied to the XMP metadata stream, which was written in the
clear while the file states `/EncryptMetadata true`.

> **Checking it yourself.** `qpdf --check` finds an unencrypted
> **compressed** stream, because the inflate fails. It stays silent for
> an **un**compressed one -- that is why the XMP stream went unnoticed
> for so long. Look at the raw bytes as well: no string of the plain
> file may appear in the encrypted one.

## Limitations

- pdf4tcl can write encrypted PDFs but cannot read or decrypt them.
- `-encversion` and `-permissions` are read-only after object creation.
- AES-256 with the pure-Tcl SHA backend is slow (~24 s/PDF).
  Install tcl-sha for production use.

## Where the random bytes come from (0.9.4.35)

The AES file key, the initialisation vectors and the salts must come from a
cryptographic source. pdf4tcl looks for one on first use and records the
result in `::pdf4tcl::_randBackend`, which is read-only and meant for
diagnostics:

| value | source |
|---|---|
| `urandom` | reads `/dev/urandom` |
| `twapi` | `::twapi::random_bytes` |
| `powershell` | `RandomNumberGenerator` via `exec powershell` |
| `none` | nothing usable found |

```tcl
set p [pdf4tcl::new %AUTO% -paper a4 -userpassword "secret" -encversion 5]
$p startPage
$p endPage
$p write -file out.pdf
puts $::pdf4tcl::_randBackend      ;# urandom on a normal Linux box
```

If none of the three is available, **encryption raises an error** rather than
falling back to `expr rand()`. That fallback would look like it worked: a 31
bit state seeded from the clock gives an AES-256 key at most 31 bits of
entropy, which is a document that only appears to be encrypted. A file that
cannot be written is the better outcome, because the failure is visible.

Worth checking on locked-down Windows machines where `exec powershell` is
blocked and twapi is not installed. There the error appears at `write` time,
not at `new`.
