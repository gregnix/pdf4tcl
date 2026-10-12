# How-to: Encrypted forms (AES-128 / AES-256)

## Runnable script

```bash
tclsh doc/en/howtos/howto-encrypted-forms.tcl
# PDF -> doc/en/out/
```

Companion: [`howto-encrypted-forms.tcl`](howto-encrypted-forms.tcl).

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

## Read and fill an encrypted form (0.9.4.71)

`getForms`, `fillForms` and `exportForms` take `-password`, the user or
the owner password:

```tcl
set f [pdf4tcl::getForms form-aes128.pdf -password geheim]
pdf4tcl::fillForms form-aes128.pdf filled.pdf {f_name "Meier"} \
        -password geheim
pdf4tcl::exportForms filled.pdf data.xfdf -format xfdf -password geheim
```

- Without `-password` the empty password is tried, as every viewer
  does. A form with only an owner password opens that way; one with a
  user password raises `PDF4TCL PASSWORD` and names the option.
- `filled.pdf` is encrypted like the input -- same `/Encrypt`, same
  `/ID`, same password. Objects `fillForms` did not change go out byte
  for byte; the new value is encrypted, in `/V` and in the appearance
  stream.
- Read: RC4 40/128, AES-128 and AES-256 (revision 2 to 6), with or
  without object streams. That covers files from qpdf, Acrobat and
  LibreOffice as well as pdf4tcl's own.
- AES-256 takes a few seconds per password check in pure Tcl.

Up to 0.9.4.70 all three read an encrypted file as plain text and found
no field: an empty dict, "no such field", an empty export.

## Check

Open with the user password and confirm fields still work. Also:

```bash
qpdf --password=geheim --show-encryption form-aes128.pdf
```

See `howto-encrypt.md`, `howto-forms.md`, `howto-permissions.md`, and
`../reference/pdf4tcl-encryption.md`.
