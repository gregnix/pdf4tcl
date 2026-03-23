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

## Limitations

- pdf4tcl can write encrypted PDFs but cannot read or decrypt them.
- `-encversion` and `-permissions` are read-only after object creation.
- AES-256 with the pure-Tcl SHA backend is slow (~24 s/PDF).
  Install tcl-sha for production use.
