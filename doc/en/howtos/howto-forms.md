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

`getForms` returns a dictionary of id to a dictionary per field:

| Key | Meaning |
|---|---|
| `type` | `/Tx`, `/Btn`, `/Ch`, `/Sig` |
| `value` | the current value, unpacked |
| `flags` | the `/Ff` bits |
| `default` | the current appearance state, for buttons |
| `maxlen` | `/MaxLen`, or empty (0.9.4.63) |
| `comb` | 1 for a comb field (0.9.4.63) |
| `widgets` | how many widgets the field has (0.9.4.64) |
| `description` | the field's `/TU` (0.9.4.65) |
| `options` | a choice field's permitted values (0.9.4.65) |

`fillForms` writes values and returns how many fields it filled.
`exportForms` writes FDF or XFDF.

**`fillForms` draws the value as well** (since 0.9.4.64), for a
single-line, multi-line or comb text field. It sets `/V`, turns on
`/NeedAppearances`, and rebuilds the field's appearance stream -- one per
widget, from that widget's own `/Rect`.

Up to 0.9.4.63 the stream was left alone: a viewer honouring the flag
showed the new value, a print path rendering the stream the **old** one,
and for an empty field nothing at all.

**Not rebuilt, deliberately:** password fields, because the value would
end up in clear text in the file; choice fields, because they have a box
and a border a text line would throw away; and comb fields without a
`/MaxLen`, where there is no divisor and hence no cells. There the value
is in `/V` and the appearance is the one it had.

`addForm` builds the streams as it goes, so a document produced in one
pass is unaffected either way.

A text field takes a string; a check box or radio button takes the state
name **with the slash**, as it appears in the file:

```tcl
pdf4tcl::fillForms in.pdf out.pdf {agreed /Yes}
```

Which states a field knows is in its appearance dictionary; `getForms`
reports the current one under `default`.

A **choice field** takes one of its options -- either the export value or
the label:

```tcl
pdf4tcl::fillForms in.pdf out.pdf {land Niederlande}
```

Anything else is refused, with the permitted values named:

```
fillForms: "Frankreich" is not an option of "land";
allowed: Deutschland Niederlande Belgien
```

The **empty** value is allowed -- it means "nothing selected", and that
is what a freshly created choice field carries. A round trip that reads
every field and writes it back must not fail on it.

Up to 0.9.4.64 any value was written and a success reported; the field
then carried a state no viewer can show.

A field can carry more than one widget -- the same field on four sheets
of a consignment note. `fillForms` fills them all in one call, and
`getForms` reports how many under `widgets` (0.9.4.64). The field name
is composed from the `/Parent` chain, so a nested field is
`person.city`, not `city`.

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

### Which fields get a rebuilt stream (0.9.4.64, 0.9.4.65)

| Field | Stream |
|---|---|
| text, single-line | rebuilt, `/Q` honoured |
| text, multi-line | rebuilt, wrapped |
| comb with `/MaxLen` | rebuilt, one character per cell |
| comb without `/MaxLen` | kept -- no divisor, no cells |
| password | kept -- a stream would hold the value in clear text |
| choice | kept -- it has a box and a border |
| check box, radio | `/AS` switches between the states it already has |

A field with several widgets gets one stream **per widget**, from that
widget's own `/Rect`. One stream for all of them would sit in the wrong
place on every sheet but the first.

0.9.4.63 made sure an empty field carries a stream too, so that there is
something here to overwrite.

### Dynamic XFA forms are refused (0.9.4.64)

If the catalogue carries `/NeedsRendering true` (ISO 32000-1 table 28)
and the form dictionary a `/XFA` entry (table 218), the AcroForm fields
are a placeholder: the viewer builds its pages from the XML, and setting
`/V` changes nothing visible. `fillForms` refuses and says why.

**Hybrid** XFA forms -- XFA together with usable AcroForm fields -- are
filled as before, because there a viewer without XFA takes the AcroForm
side and the value does work.

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
