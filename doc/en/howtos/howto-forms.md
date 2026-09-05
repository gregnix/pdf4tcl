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

## Reading and filling (0.9.4.50)

Three calls work on an existing file rather than on a document being
built:

```tcl
set fields [pdf4tcl::getForms "order.pdf"]
pdf4tcl::fillForms "order.pdf" "filled.pdf" {f_name "Meier & Co"}
pdf4tcl::exportForms "filled.pdf" "filled.fdf"
```

`getForms` returns a dictionary of id to `{type value flags default}`.
`fillForms` writes values and returns how many fields it filled.
`exportForms` writes FDF or XFDF.

**`fillForms` writes the value, it does not draw it.** It sets `/V` and
turns on `/NeedAppearances`; the existing appearance stream stays as it
is. A viewer that honours the flag shows the new value -- Acrobat and the
common browsers do. A print path that renders the appearance shows the
**old** one.

Measured: a field created with `-init "Alt"` and then filled with
`"Meier"` carries `/V (Meier)` while its `/AP` still draws `Alt`.
`pdftotext` reads the value and reports `Meier`; on paper it would say
`Alt`.

`addForm` builds the streams as it goes, so a document produced in one
pass is unaffected. **Where it must not go wrong, produce the document
with its values instead of filling it afterwards.** Filling is for forms
that come from elsewhere and cannot be regenerated -- and there the result
belongs in the viewer that will print it, before the paper does.

A text field takes a string; a check box or radio button takes the state
name **with the slash**, as it appears in the file:

```tcl
pdf4tcl::fillForms in.pdf out.pdf {agreed /Yes}
```

Which states a field knows is in its appearance dictionary; `getForms`
reports the current one under `default`.

A name that is not in the form raises an error:

```
fillForms: no such field(s) in "order.pdf": no_such_field
```

Ignoring it would mean a form comes out empty and nobody knows why.
Fields present but not named keep what they had.

### The round trip

`getForms` hands a text value back **unpacked** -- exactly the form
`fillForms` takes in. So the obvious thing works:

```tcl
set fields [pdf4tcl::getForms "in.pdf"]
set values {}
dict for {id info} $fields {
    dict set values $id [dict get $info value]
}
dict set values f_name "Meier & Co (GmbH)"
pdf4tcl::fillForms "in.pdf" "out.pdf" $values
```

Until 0.9.4.55 the value came back raw, with its brackets and escapes,
and every pass doubled the escaping of every field the caller did not
touch:

```
Meier & Co (GmbH)
(Meier & Co \(GmbH\))
(\(Meier & Co \\\(GmbH\\\)\)))
```

A **name** value (`/Yes`, `/Off`) is left as it is -- that is the form
`fillForms` expects for check boxes and radio buttons.

### The value is written, not drawn

`fillForms` sets `/NeedAppearances`, which tells the viewer to render the
value. A viewer that honours the flag -- Acrobat and the common browsers
do -- shows it; one that ignores it shows the field as it was, with the
value present but invisible.

Building an appearance stream per field would need the font metrics of
the target document, which is more than a string. It is on the list.

## Forms and PDF/A

A check box is drawn with a ZapfDingbats glyph, and ZapfDingbats is one of
the fourteen standard faces -- it has no font program to embed. PDF/A wants
every font program in the file, so **a document with a single check box was
non-conformant the moment it was written**, before anyone filled anything
in.

Since 0.9.4.55 the mark is drawn with lines and curves wherever the
document claims PDF/UA or **any** PDF/A level. Measured with veraPDF on a
document whose only form field is one check box:

```
with the glyph:   -pdfa 1b, 2b, 3b  ->  all FAIL, clause 6.2.11.4.1
with the vector:  -pdfa 1b, 2b, 3b  ->  all PASS
```

A document that claims nothing keeps the glyph and looks exactly as it did.
`-markstyle font` forces the glyph, `-markstyle vector` the drawing.

The text in the fields is a separate matter: it needs an embedded font like
any other text. See [`howto-pdfa.md`](howto-pdfa.md).

## Limits

- Form text is practically Base-14 / Latin-1 (CID in AcroForm is hard).
- Styling: `-color`, `-bgcolor`, `-bordercolor`, `-borderwidth`, `-align`.
- Full guide: `../reference/pdf4tcl-forms-manual.md`.
