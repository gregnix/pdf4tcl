# pdf4tcl Encryption: AES-128 and AES-256

This document describes the PDF encryption support in pdf4tcl from
version 0.9.4.16 onward (fork gregnix/pdf4tcl).

## Overview

pdf4tcl supports two encryption levels:

| Option | Default | Algorithm | PDF version | Dependencies |
|--------|---------|-----------|-------------|--------------|
| `-encversion 4` | yes | AES-128 (V=4/R=4) | 1.5+ | Tcllib only |
| `-encversion 5` | no | AES-256 (V=5/R=6) | 2.0 | Tcllib (SHA via pure-Tcl, tcl-sha, or openssl) |

## AES-128 (Default)

AES-128 is the default and requires no external programs.
It uses only Tcllib (md5, aes).

```tcl
package require pdf4tcl

set p [pdf4tcl::new %AUTO% -paper a4 -orient true \
    -userpassword  "secret" \
    -ownerpassword "admin"]

$p startPage
$p setFont 12 Helvetica
$p text "Encrypted content" -x 72 -y 72
$p endPage
$p write -file output.pdf
$p destroy
```

qpdf verification:

```bash
qpdf --password=secret --check output.pdf
```

## AES-256

AES-256 is activated with `-encversion 5`. It produces PDF 2.0 compliant
files per ISO 32000-2 and is readable by Adobe Reader, qpdf, and pikepdf.

```tcl
set p [pdf4tcl::new %AUTO% -paper a4 -orient true \
    -userpassword  "secret" \
    -ownerpassword "admin" \
    -encversion    5]
```

### Runtime and SHA Backend (from 0.9.4.18)

AES-256 requires SHA-384 and SHA-512 for the key derivation algorithm
(ISO 32000-2 §7.6.4.3.3, Alg. 2.B). From version 0.9.4.18 no external
program is needed — SHA-384/512 is included as a pure-Tcl implementation
directly in pdf4tcl.

The SHA backend is selected automatically (priority order):

1. **tcl-sha** — C extension, fast (~0.1 s/PDF), optional
2. **openssl** — used automatically if found in PATH
3. **pure-tcl** — always available, no installation needed (~24 s/PDF)

Typical timings:

| Backend  | Time per PDF | Requirement |
|----------|-------------|-------------|
| tcl-sha  | < 0.5 s     | tcl-sha installed |
| openssl  | 2–4 s       | openssl in PATH |
| pure-tcl | ~24 s       | none (always available) |

Query the active backend:

```tcl
package require pdf4tcl 0.9.4
puts $::pdf4tcl::_shaBackend   ;# tcl-sha | openssl | pure-tcl
```

For time-critical applications, AES-128 remains the recommended choice
(under 100 ms, no SHA-384/512 required).

## Options

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `-userpassword` | String | `""` | Opens the PDF (empty = no password) |
| `-ownerpassword` | String | `""` | Full access; if empty = userpassword |
| `-encversion` | 4 or 5 | `4` | Encryption level |

If only `-ownerpassword` is set without `-userpassword`, the owner
password is also used as the user password.

## Technical Details

### AES-128 (V=4/R=4)

- Key derivation: MD5 with 50 iterations (ISO 32000-1 §7.6.3)
- Per-object key derived from object number and generation number
- Padding constant: `28BF...697A` (qpdf-compatible)
- Tcllib only: md5, aes

### AES-256 (V=5/R=6)

- Key derivation: Alg. 2.B with SHA-256/384/512
- A single file encryption key (FEK, 32 bytes) for all objects
- Per object: a random 16-byte IV is prepended to each encrypted stream
  and string (same AES-CBC padding scheme as AES-128)
- Fields: U, UE, O, OE (32–48 bytes each), Perms (16 bytes)
- Implementation **compatible with qpdf (de-facto reference)**,
  not the literal ISO text:
  - Sequence order: `password || K || userkey`
  - Hash selector: `sum(E[0:16]) % 3`
  - K retains full 48/64 bytes after SHA-384/512 within the loop
- Validated against qpdf: `qpdf --check` with the correct password must
  output `User password = <pw>`
- Tcllib for SHA-256 and AES-CBC; SHA-384/512 via backend chain
  (tcl-sha / openssl / pure-tcl)

**SHA-384/512 pure Tcl (from 0.9.4.18):**
Namespace `::pdf4tcl::sha2pure`, NIST FIPS 180-4 compliant, tested with
NIST test vectors (nist-tests.tcl, 25/25). No external tool or package
install required. Performance: SHA itself < 1 s; the bottleneck is
Tcllib AES (~24 s/PDF).

## Limitations

- AES-256 is a write-only implementation. pdf4tcl cannot read or decrypt
  encrypted PDFs.
- The `-encversion` parameter is `readonly` and cannot be changed after
  object creation.
- Permissions (`/P`) are fixed at `-196` (all rights allowed).

## Diagnostic Tools

### verify_enc3.py

Verifies AES-256 PDFs independently of pdf4tcl:

```bash
python3 verify_enc3.py output.pdf secret
```

Shows: U/O hash comparison, iteration count of Alg. 2.B, FEK,
Perms validation.

### qpdf

```bash
# Check password
qpdf --password=secret --check output.pdf

# Decrypt
qpdf --password=secret --decrypt output.pdf plain.pdf

# Show encryption dictionary
qpdf --show-encryption --password=secret output.pdf
```

## Encrypted Strings and Forms (§7.6.5)

pdf4tcl encrypts all PDF literal strings `(...)` in dictionaries
per ISO 32000 §7.6.5. This covers AcroForm fields (`/T`, `/DA`, `/V`,
`/TU`, `/CA`), metadata (`/Author`, `/Title`), and bookmarks (`/Title`).

**Forms + encryption interactions — known points:**

- Field names `/T` are encrypted → each field has a unique internal name,
  no overlap
- Appearance streams (AP dictionaries) are streams → encrypted by
  `EncryptStreamBody`
- Default values `/V` are encrypted as literal strings
- Pushbutton captions `/CA` are encrypted

**Validation:** Tested with Evince, Firefox (PDF.js), and
`qpdf --check --password=...`. Chrome does not display AcroForm at all
(viewer-side limitation, independent of encryption).
