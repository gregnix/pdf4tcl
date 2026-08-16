# Tutorial 4 -- Order form with a live sum

## Runnable script

```bash
tclsh 0.9.4.x/doc/en/tutorials/tutorial-04-forms.tcl
# PDF -> 0.9.4.x/doc/en/out/
```

Companion: [`tutorial-04-forms.tcl`](tutorial-04-forms.tcl).

Build an interactive order form: name fields, amount fields, a calculated
total, and submit/reset buttons. Based on `0.9.4.x/demo/demo-forms-calc.tcl`.

## Script

```tcl
#!/usr/bin/env tclsh
lappend auto_path /path/to/pdf4tcl
package require pdf4tcl 0.9

set pdf [::pdf4tcl::new %AUTO% -paper a4 -orient 1 -margin 50]
$pdf startPage

$pdf setFont 16 Helvetica-Bold
$pdf text "Order form" -x 0 -y 24
$pdf setStrokeColor 0.5 0.5 0.5
$pdf line 0 32 450 32
$pdf setStrokeColor 0 0 0

$pdf setFont 10 Helvetica
$pdf text "Name:" -x 0 -y 60
$pdf addForm text 50 48 280 16 -id f_name

$pdf setFont 12 Helvetica-Bold
$pdf text "Lines" -x 0 -y 100
$pdf setFont 10 Helvetica-Bold
$pdf text "Item" -x 0 -y 120
$pdf text "EUR" -x 320 -y 120
$pdf setFont 10 Helvetica

foreach {aid name bid amt y} {
    a1 "Item A" b1 120 140
    a2 "Item B" b2  80 165
    a3 "Item C" b3  50 190
} {
    $pdf addForm text 0 [expr {$y - 10}] 250 16 -id $aid -init $name
    $pdf addForm text 320 [expr {$y - 10}] 80 16 -id $bid -align right \
            -borderwidth 0.5 -init $amt
}

$pdf setFont 11 Helvetica-Bold
$pdf text "Total:" -x 250 -y 230
$pdf addForm text 320 218 80 16 -id f_sum -align right \
        -calculate {sum {b1 b2 b3}} -init 250 \
        -borderwidth 1 -bordercolor {0 0 0.5} -bgcolor {0.95 0.95 0.85}

$pdf addForm pushbutton 0 270 90 20 -id f_submit \
        -caption "Submit" -action submit \
        -url "mailto:orders@example.com"
$pdf addForm pushbutton 100 270 90 20 -id f_reset \
        -caption "Reset" -action reset

$pdf endPage
$pdf write -file order-form.pdf
$pdf destroy
puts "wrote order-form.pdf"
```

## What to expect

- Every viewer shows the `-init` values (static sum 250).
- Viewers with JavaScript recalculate `f_sum` when `b1`/`b2`/`b3` change.
- Encrypt the same form: see `demo-forms-aes128.tcl` / howto-encrypt.md.

## Next

- Styling options: `../howtos/howto-forms.md`
- Full forms manual: `../pdf4tcl-forms-manual.md`
- Graphics next: [Tutorial 5](tutorial-05-graphics-lab.md)
