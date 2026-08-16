# How-to: Permissions (`-permissions`)

## Runnable script

```bash
tclsh doc/en/howtos/howto-permissions.tcl
# PDF -> doc/en/out/
```

Companion: [`howto-permissions.tcl`](howto-permissions.tcl).

Demo: `demo/demo-permissions.tcl`

## Problem

Restrict printing, copying, or editing **after** the file is opened.

## Important

`-permissions` alone does **not** lock the file. Without `-userpassword`,
any viewer can open it; `/P` is only a hint to conforming readers. Always
set passwords when you care about enforcement:

```tcl
set pdf [::pdf4tcl::new %AUTO% -paper a4 -orient 1 \
        -userpassword "user" \
        -ownerpassword "admin" \
        -permissions print]
```

| Password | Effect |
|---|---|
| user | Opens the file; `/P` restrictions apply |
| owner | Full rights; `/P` ignored |

`-permissions` accepts symbolic lists, presets, or a raw `/P` integer
(see manpage / encryption guide).

## Verify

```bash
qpdf --password=user --show-encryption out.pdf
tclsh demo/demo-permissions.tcl out
```

Related: `howto-encrypt.md`, `howto-encrypted-forms.md`.
