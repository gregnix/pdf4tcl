# How-to: Generate API cheat sheets

Demo: `0.9.4.x/demo/demo-make-cheatsheets.tcl`

## Problem

Print compact two-column PDF reference sheets for the current pdf4tcl API.

## Recipe

```bash
cd /path/to/pdf4tcl
tclsh 0.9.4.x/demo/demo-make-cheatsheets.tcl
# writes under 0.9.4.x/demo/out/
```

The script builds several cheat-sheet PDFs (methods, options, patterns) using
only Base-14 fonts. It always targets `demo/out/` and does **not** follow
`run-all-demos.tcl --outdir` (same class as other `argschema none` demos).

## When to regenerate

After a version bump or when onboarding someone who wants a printable API
map. For authoritative option lists, prefer `pdf4tcl.man` / `pdf4tcl.md`
from `make` / `make md`.
