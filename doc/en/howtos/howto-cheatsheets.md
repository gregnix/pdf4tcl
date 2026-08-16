# How-to: Generate API cheat sheets

## Runnable script

```bash
tclsh doc/en/howtos/howto-cheatsheets.tcl
# PDF -> doc/en/out/
```

Companion: [`howto-cheatsheets.tcl`](howto-cheatsheets.tcl).

Demo: `demo/demo-make-cheatsheets.tcl`

## Problem

Print compact two-column PDF reference sheets for the current pdf4tcl API.

## Recipe

```bash
cd /path/to/pdf4tcl
tclsh demo/demo-make-cheatsheets.tcl
# writes under demo/out/
```

The script builds several cheat-sheet PDFs (methods, options, patterns) using
only Base-14 fonts. It always targets `demo/out/` and does **not** follow
`run-all-demos.tcl --outdir` (same class as other `argschema none` demos).

## When to regenerate

After a version bump or when onboarding someone who wants a printable API
map. For authoritative option lists, prefer `pdf4tcl.man` / `pdf4tcl.md`
from `make` / `make md`.
