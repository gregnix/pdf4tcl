# How-to: Run the demo suite

## Runnable script

```bash
tclsh 0.9.4.x/doc/en/howtos/howto-run-demos.tcl
# PDF -> 0.9.4.x/doc/en/out/
```

Companion: [`howto-run-demos.tcl`](howto-run-demos.tcl).

Script: `0.9.4.x/demo/run-all-demos.tcl`

## Problem

Regenerate every demo PDF after a change, or smoke-test the install.

## Recipe

```bash
cd /path/to/pdf4tcl
tclsh 0.9.4.x/demo/run-all-demos.tcl
# PDFs land in 0.9.4.x/demo/out/

tclsh 0.9.4.x/demo/run-all-demos.tcl --outdir /tmp/pdfout
tclsh 0.9.4.x/demo/run-all-demos.tcl --alle    # include slow / optional demos
```

## Behaviour

| Flag / case | Effect |
|---|---|
| (default) | Runs demos listed in `DEMOS`; skips entries that have a reason string |
| `--alle` | Also runs AES-heavy, OTF-missing, etc. |
| no `DISPLAY` | Skips Tk canvas demos |
| `argschema none` | Some demos ignore `--outdir` and always write under `demo/out/` |

Each list entry documents whether it needs Tk and which argument schema it
uses (`dir`, `file`, `--out`, `none`). Deliberate skips carry an explicit
reason so a missing file is not confused with “forgotten”.

Individual demos: see the mapping table in `README.md` in this folder.
