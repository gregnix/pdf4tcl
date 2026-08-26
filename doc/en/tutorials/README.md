# Tutorials

Short walkthroughs that produce a real PDF. Read them in order if you are new
to pdf4tcl; otherwise pick the one that matches the job.

| # | Document | Outcome | Related demo |
|---|---|---|---|
| 1 | `tutorial-01-hello-pdf.md` | One-page PDF with text, colour, line | `minimalPdf.tcl` |
| 2 | `tutorial-02-simple-report.md` | Multi-page report with header/footer/table | `demo-all.tcl` (partial) |
| 3 | `tutorial-03-accessible-pdf.md` | Tagged PDF/UA-1 sketch | `demo-tagged.tcl` |
| 4 | `tutorial-04-forms.md` | Order form with calculated sum | `demo-forms-calc.tcl` |
| 5 | `tutorial-05-graphics-lab.md` | Alpha + gradient + transform | `demo-alpha` / `gradients` / `transform` |
| 6 | `tutorial-06-assemble-pack.md` | Reading pack: images + text + catPdf | -- |
| 7 | `tutorial-07-multilingual.md` | One page in five scripts; font choice and its limits | `demo-cidfont.tcl`, `demo-symbole.tcl` |

After these, use the feature guides in the parent directory and the recipes
under `../howtos/`. Full demo list: `demo/run-all-demos.tcl`.

Assumes pdf4tcl **0.9.4.41** or newer on the `auto_path`, Tcl 8.6 or 9.

## Runnable scripts

Each tutorial has a matching `.tcl` file. Output goes to `../out/`.

```bash
tclsh doc/en/tutorials/tutorial-01-hello-pdf.tcl
tclsh doc/en/run-all-examples.tcl
```
