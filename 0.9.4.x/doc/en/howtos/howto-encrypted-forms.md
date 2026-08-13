# How-to: Encrypted forms (AES-128 / AES-256)

Demos (slow -- skipped by default in `run-all-demos.tcl`, use `--alle`):
- `demo-forms-aes128.tcl` -- AcroForm + AES-128 (`-encversion 4`)
- `demo-forms-aes256.tcl` -- AcroForm + AES-256 (`-encversion 5`)
- `demo-forms-enc.tcl` -- encrypted form variant
- `demo-aes256.tcl` -- encryption without forms

## Problem

Ship a fillable form that only opens with a password.

## Recipe (AES-128)

```tcl
set pdf [::pdf4tcl::new %AUTO% -paper a4 -orient 1 \
        -userpassword "geheim" \
        -ownerpassword "admin" \
        -encversion 4]

$pdf startPage
$pdf setFont 12 Helvetica
$pdf text "Name:" -x 50 -y 60
$pdf addForm text 100 48 250 16 -id f_name
$pdf endPage
$pdf write -file form-aes128.pdf
$pdf destroy
```

## AES-256

```tcl
set pdf [::pdf4tcl::new %AUTO% -paper a4 -orient 1 \
        -userpassword "geheim" \
        -ownerpassword "admin" \
        -encversion 5]
# ... same form fields ...
```

Needs a SHA-384/512 backend (OpenSSL helper or equivalent). Pure Tcllib AES
is too slow for the default test suite (~24 s per pass).

## Check

Open with the user password and confirm fields still work. Also:

```bash
qpdf --password=geheim --show-encryption form-aes128.pdf
```

See `howto-encrypt.md`, `howto-forms.md`, `howto-permissions.md`, and
`../pdf4tcl-encryption.md`.
