# How-to: Encrypt a PDF

## Runnable script

```bash
tclsh doc/en/howtos/howto-encrypt.tcl
# PDF -> doc/en/out/
```

Companion: [`howto-encrypt.tcl`](howto-encrypt.tcl).

## Problem

Require a password to open (or to change) the file.

## Recipe (AES-128)

```tcl
set pdf [::pdf4tcl::new %AUTO% -paper a4 -orient 1 \
        -userpassword "open-me" \
        -ownerpassword "change-me" \
        -permissions print]
$pdf startPage
$pdf setFont 12 Helvetica
$pdf text "Confidential." -x 50 -y 50
$pdf endPage
$pdf write -file secret.pdf
$pdf destroy
```

- If `-ownerpassword` is empty, the user password is used for both.
- `-permissions` accepts symbolic lists, presets, or a raw `/P` integer.
  Default is effectively "all allowed".
- AES-256: set `-encversion 5` (needs a SHA-384 backend; see the encryption
  guide). Slow under pure Tcllib AES -- prefer a faster crypto package in
  production.

## Check

Open `secret.pdf` in a viewer and confirm the password prompt. For automated
checks, use the encryption demos under `demo/`.

Full reference: `../reference/pdf4tcl-encryption.md`.
