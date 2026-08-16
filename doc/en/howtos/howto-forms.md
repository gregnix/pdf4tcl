# How-to: Interactive forms

## Runnable script

```bash
tclsh doc/en/howtos/howto-forms.tcl
# PDF -> doc/en/out/
```

Companion: [`howto-forms.tcl`](howto-forms.tcl).

Demos: `demo-forms.tcl`, `demo-forms-calc.tcl`, `demo-forms-tk.tcl`

## Problem

Collect typed input, or show a live sum in a capable PDF viewer.

## Text fields and buttons

```tcl
set pdf [::pdf4tcl::new %AUTO% -paper a4 -orient 1 -margin 50]
$pdf startPage
$pdf setFont 12 Helvetica
$pdf text "Name:" -x 0 -y 40
$pdf addForm text 60 28 200 16 -id f_name

$pdf addForm pushbutton 0 70 90 20 -id f_reset \
        -caption "Reset" -action reset
$pdf addForm pushbutton 100 70 90 20 -id f_go \
        -caption "Submit" -action submit \
        -url "mailto:orders@example.com"
$pdf endPage
$pdf write -file form.pdf
$pdf destroy
```

## Calculated sum (needs JS in the viewer)

```tcl
$pdf addForm text 400 200 90 16 -id b1 -align right -init 120
$pdf addForm text 400 220 90 16 -id b2 -align right -init 80
$pdf addForm text 400 250 90 16 -id f_sum -align right \
        -calculate {sum {b1 b2}} -init 200 \
        -borderwidth 1 -bgcolor {0.95 0.95 0.85}
```

`-init` shows a static value everywhere; `-calculate` updates in Acrobat,
Firefox, Chromium, Foxit, etc.

## Limits

- Form text is practically Base-14 / Latin-1 (CID in AcroForm is hard).
- Styling: `-color`, `-bgcolor`, `-bordercolor`, `-borderwidth`, `-align`.
- Full guide: `../reference/pdf4tcl-forms-manual.md`.
