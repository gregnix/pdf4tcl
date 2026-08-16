# How-to: Validate output

## Runnable script

```bash
tclsh 0.9.4.x/doc/en/howtos/howto-validate.tcl
# PDF -> 0.9.4.x/doc/en/out/
```

Companion: [`howto-validate.tcl`](howto-validate.tcl).

## Problem

You wrote a PDF and need a quick go/no-go before shipping.

## Tools

```bash
# Syntax and streams (not semantics)
qpdf --check out.pdf

# PDF/A flavour
verapdf -f 1b out.pdf
verapdf -f 2b out.pdf
verapdf -f 3b out.pdf

# PDF/UA-1
verapdf -f ua1 out.pdf

# Logical structure consistency (needs pypdf)
python3 tools/check-tagged.py out.pdf
```

## What each tool does *not* do

| Tool | Blind spot |
|---|---|
| `qpdf` | Structure tree, PDF/A, accessibility |
| `veraPDF` | Whether tagging is *sensible*; layout upside-down still can pass UA |
| `check-tagged.py` | Full PDF/UA rule set; use alongside veraPDF |

A file where every paragraph is `/P` and every heading is `/H1` can pass
PDF/UA and still be useless to a reader.

## Suggested local habit

```bash
tclsh examples/tagged.tcl
python3 tools/check-tagged.py examples/tagged.pdf && verapdf -f ua1 examples/tagged.pdf
```

See also the parent `README.md` section "Checking the output".
