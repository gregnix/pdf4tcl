# pdf4tcl addForm – Technical Reference

## Overview

This document describes the internal implementation of the `addForm` method
in pdf4tcl 0.9.4.1. It covers the PDF object model, appearance stream
generation, coordinate transformation, the AcroForm dictionary structure,
and the radiobutton group mechanism. Target audience: developers maintaining
or extending the forms implementation.

### Source Location

The entire forms implementation resides in `src/main.tcl` within the
`pdf4tcl::pdf4tcl` TclOO class. Key sections:

| Line Range | Content |
|-----------|---------|
| 95–100 | Instance variable initialization (`pdf(forms)`, `pdf(radiogroups)`, `pdf(needAppearances)`) |
| 541–543 | AcroForm reference in Catalog object |
| 659–700 | Radiogroup finalization and AcroForm dict emission |
| 1039–1058 | `SetupZaDbFont` helper (ZapfDingbats registration) |
| 3225–3775 | `addForm` method (the core implementation) |

---

## Method Signature and Option Parsing

```tcl
method addForm {ftype x y width height args}
```

### Type Normalization

The `checkbox` alias is resolved immediately at method entry:

```tcl
if {$ftype eq "checkbox"} {
    set ftype "checkbutton"
}
```

This is fully transparent to the rest of the implementation. The valid type
set after normalization is:

```tcl
{text checkbutton combobox listbox password radiobutton pushbutton signature}
```

### Default Values

```tcl
set initValue ""       ;# Pre-fill value
set idStr ""           ;# Field identifier
set multiline 0        ;# Text field: multi-line mode
set optionsList {}     ;# Choice fields: option list
set editable 0         ;# Combobox: allow free text
set sortopt 0          ;# Choice fields: sort options
set multiselect 0      ;# Listbox: allow multiple selection
set groupName ""       ;# Radiobutton: group name
set radioValue ""      ;# Radiobutton: value string
set actionType ""      ;# Pushbutton: action type
set actionValue ""     ;# Pushbutton: URL target
set caption ""         ;# Pushbutton: button label
set readonly 0         ;# All types: read-only flag
set label ""           ;# Signature: placeholder text
```

Checkbutton and radiobutton default `initValue` to `0` (boolean).

### Auto-Generated IDs

If no `-id` is given:

| Type | Generated ID |
|------|-------------|
| Most types | `${ftype}form${nextOid}` |
| radiobutton | `${groupName}_${radioValue}` |
| signature | `Signature${nextOid}` |

---

## Coordinate Transformation

After option parsing, coordinates are transformed from user space to PDF
page space:

```tcl
my Trans  $x $y x y           ;# Absolute: user coords → page coords
my TransR $width $height width height  ;# Relative: user dims → page dims
set x2 [expr {$x+$width}]
# Normalize: ensure positive height regardless of orient
if {$height < 0} {
    set y2 $y
    set y [expr {$y2+$height}]
    set height [expr {-$height}]
} else {
    set y2 [expr {$y+$height}]
}
```

### Trans Method

The `Trans` method converts absolute user coordinates to PDF page coordinates.
With `-orient 1`, the y-axis is flipped: `pdfY = pageHeight - userY`.
With `-orient 0`, coordinates pass through with only margin/unit adjustments.

### Height Normalization

When `-orient 1` is active, `TransR` returns a negative height (because
the y-axis is inverted). The normalization block swaps `y` and `y2` so
that `y < y2` always holds, which is required for the `/Rect` array in
the annotation dictionary.

This normalization is critical: appearance streams use `[0 0 width height]`
as their BBox and draw relative to the origin. The BBox is always in
standard PDF coordinates (origin at bottom-left of the field rectangle),
regardless of the document's orient setting.

---

## Appearance Stream Architecture

Each field type generates one or more Form XObjects that define the visual
representation. These are referenced via the `/AP` (Appearance) dictionary
in the annotation.

### Common Structure

All appearance streams follow this pattern:

```
<< /BBox [ 0 0 WIDTH HEIGHT ]
   /Resources 3 0 R
   /Subtype /Form
   /Type /XObject
   /Length NNN
>>
stream
... graphics operators ...
endstream
```

The BBox always starts at `[0 0 ...]`. The XObject is scaled/positioned
by the viewer to fit within the annotation's `/Rect`.

Resources reference object 3, which is the page resource dictionary
containing font definitions.

### Per-Type Details

#### text / password

Only generated when `-init` is non-empty. Uses `/Tx BMC ... EMC` marked
content wrapper.

```
/Tx BMC BT
  /Helvetica 10 Tf 0 g
  2 1.1 Td
  (initial value) Tj
ET EMC
```

For password fields, the init value is replaced with bullet characters:

```tcl
set masked [string repeat "\u2022" [string length $initValue]]
```

The text position `2 1.1 Td` is a fixed offset that approximately centers
text vertically in a standard 18-point field height. This is noted as a
TODO for improvement.

#### checkbutton

Two appearance streams: "on" (checkmark) and "off" (empty).

**On state** uses ZapfDingbats character 4 (checkmark ✔, Unicode U+2714):

```
/Tx BMC BT 0 Tc 0 Tw 100 Tz 0 g 0 Tr /ZaDb FS Tf
1 0 0 1 CX CY Tm
[(4)]TJ ET EMC
```

Font size is `height * 0.9`. Horizontal centering uses the known glyph
width metric (846/1000 em) of the checkmark character.

**Off state** is an empty stream (reused across all checkboxes via
`pdf(checkboxoffobj)`).

The ZapfDingbats font is registered via `SetupZaDbFont`:

```tcl
method SetupZaDbFont {} {
    if {[info exists pdf(zadbsetup)]} return
    set pdf(zadbsetup) 1
    set oid [my GetOid]
    set body "<< /Type /Font /Subtype /Type1"
    append body " /Name /ZaDb /BaseFont /ZapfDingbats >>"
    my Pdfout "$oid 0 obj\n$body\nendobj\n"
    append pdf(fonts) "/ZaDb $oid 0 R\n"
}
```

#### combobox

Generates a complete appearance with:

1. White background fill (`1 1 1 rg ... re f`)
2. Gray border stroke (`0.5 0.5 0.5 RG ... re S`)
3. Dropdown arrow area: gray rectangle on the right with a small triangle
4. Optional text showing the init value or first option

```
/Tx BMC
1 1 1 rg 0 0 W H re f
0.5 0.5 0.5 RG 0.5 w 0 0 W H re S
0.9 0.9 0.9 rg AX 0 AW H re f       // arrow area
0.5 0.5 0.5 RG AX 0 AW H re S
0.3 0.3 0.3 rg TX1 TY1 m TX2 TY2 l TX3 TY3 l f  // triangle
BT /Font FS Tf 0 g 2 1.1 Td (text) Tj ET
EMC
```

The arrow width is `min(18, width * 0.15)`. The triangle size is
`min(4, arrowWidth * 0.3)`.

#### listbox

Simpler than combobox: white background + gray border + optional text.
No dropdown arrow.

#### radiobutton

Two appearance streams per button: "on" (filled bullet) and "off" (empty).

**On state** uses ZapfDingbats character `l` (lowercase L = filled circle ●):

```
/Tx BMC BT 0 Tc 0 Tw 100 Tz 0 g 0 Tr /ZaDb FS Tf
1 0 0 1 CX CY Tm
[(l)]TJ ET EMC
```

Font size is `height * 0.8`. Horizontal offset accounts for the glyph
width (approximately `0.52 * fontSize`).

**Off state** is shared across all radio buttons via `pdf(radiobtnoffobj)`.

#### pushbutton

Gray button background with centered caption:

```
0.85 0.85 0.85 rg 0 0 W H re f      // background
0.4 0.4 0.4 RG 0.5 w 0 0 W H re S   // border
BT /Font FS Tf 0 g CX CY Td (Caption) Tj ET
```

Font size is `min(currentFontSize, height * 0.6)`. Horizontal centering
uses an estimated string width: `strlen * fontSize * 0.5`.

#### signature

Gray placeholder with dashed signature line and label text:

```
0.95 0.95 0.95 rg 0 0 W H re f      // light gray fill
0.6 0.6 0.6 RG 0.5 w 0 0 W H re S   // border
0.4 0.4 0.4 RG 0.5 w [3 2] 0 d      // dashed line style
LX1 LY m LX2 LY l S                  // signature line at 25% height
[] 0 d                                // reset dash
BT /Font FS Tf 0.5 0.5 0.5 rg        // gray text
LX1 TY Td (Label) Tj ET
```

The signature line spans from 10% to 90% of the field width at 25% height.
Label font size is `min(8.0, height * 0.2)`. Label text defaults to
"Signature" if not specified.

---

## Annotation Dictionary Construction

After appearance stream generation, the annotation dictionary is built.
All types share a common wrapper:

```
<<
  /Subtype /Widget
  /P PAGEOID 0 R          // reference to current page
  /Rect [x y x2 y2]       // field rectangle in page coords
  ... type-specific entries ...
  /F 4                     // Print flag (always set)
>>
```

### Type-Specific Annotation Entries

#### text / password (`/FT /Tx`)

```
/FT /Tx
/T (fieldId)
/Ff FLAGS              // Bit 1: ReadOnly, Bit 13: Multiline, Bit 14: Password
/DA (/Font SIZE Tf 0 g)
/Q 0                   // Left-justified
/V (initialValue)      // only if -init set
/AP << /N OID 0 R >>   // only if -init set
```

**Ff flag composition:**

```tcl
set ff 0
if {$readonly}  { set ff [expr {$ff | 0x1}] }     ;# Bit 1
if {$multiline} { set ff [expr {$ff | 0x1000}] }   ;# Bit 13
if {$password}  { set ff [expr {$ff | 0x2000}] }   ;# Bit 14
```

#### combobox / listbox (`/FT /Ch`)

```
/FT /Ch
/T (fieldId)
/Ff FLAGS              // Bits: 1=RO, 18=Combo, 19=Edit, 20=Sort, 22=MultiSel
/Opt [(opt1)(opt2)...]
/DA (/Font SIZE Tf 0 g)
/V (selectedValue)     // only if -init set
/AP << /N OID 0 R >>   // self-generated appearance
```

**Ff flag composition:**

```tcl
set ff 0
if {$readonly}    { set ff [expr {$ff | 0x1}] }       ;# Bit 1
if {$combobox}    { set ff [expr {$ff | 0x20000}] }    ;# Bit 18
if {$editable}    { set ff [expr {$ff | 0x40000}] }    ;# Bit 19
if {$sort}        { set ff [expr {$ff | 0x80000}] }    ;# Bit 20
if {$multiselect} { set ff [expr {$ff | 0x200000}] }   ;# Bit 22
```

#### checkbutton (`/FT /Btn`)

```
/FT /Btn
/T (fieldId)
/Ff 1                  // only if readonly
/AS /Yes or /Off       // current state
/V /Yes or /Off
/AP <<
  /N << /Yes ONOID 0 R /Off OFFOID 0 R >>
  /D << /Yes ONOID 0 R /Off OFFOID 0 R >>
>>
/H /P                  // Push highlight mode
```

The `/N` (normal) and `/D` (down) appearance dictionaries map state names
to XObject references.

#### radiobutton (child widget)

Radio button annotations differ from other types: they have a `/Parent`
reference instead of `/FT` and `/T`, and their appearance state names use
the radio value instead of "Yes":

```
/Parent PARENTOID 0 R
/AS /VALUE or /Off
/AP <<
  /N << /VALUE ONOID 0 R /Off OFFOID 0 R >>
  /D << /VALUE ONOID 0 R /Off OFFOID 0 R >>
>>
/H /P
/MK << /BC [0 0 0] >>    // circle border hint
```

The parent field object is created during document finalization (see below).

#### pushbutton (`/FT /Btn`)

```
/FT /Btn
/T (fieldId)
/Ff FLAGS              // Bit 17: Pushbutton (0x10000), optionally + Bit 1
/AP << /N OID 0 R >>
/MK << /CA (Caption) >>
/A << /Type /Action /S /URI /URI (url) >>    // or /S /ResetForm or /S /SubmitForm
/H /P
```

#### signature (`/FT /Sig`)

```
/FT /Sig
/T (fieldId)
/Ff 1                  // only if readonly
/AP << /N OID 0 R >>
```

Signature fields are minimal: field type, ID, optional readonly flag, and
appearance reference. No `/DA` or `/V` is needed.

---

## Radiobutton Group Architecture

Radio buttons use a parent-child hierarchy in the PDF object model.

### Data Flow

1. **First button in a group** → `pdf(radiogroups)` dict entry is created:

```tcl
dict set pdf(radiogroups) $groupName [dict create \
    parentOid $parentOid  kids {}  selectedValue ""  readonly 0]
```

The `parentOid` is reserved immediately via `GetOid 1` (the `1` flag
means "no xref yet" — the xref is stored later during finalization).

2. **Each button** → annotation ID is appended to the group's `kids` list:

```tcl
lappend kids $anid
dict set pdf(radiogroups) $groupName kids $kids
```

If any button has `-readonly 1`, the group's `readonly` flag is set to 1.

If a button has `-init 1`, its value becomes `selectedValue`.

3. **Document finalization** (in the `write` / `get` path) → parent objects
   are emitted:

```tcl
dict for {groupName groupData} $pdf(radiogroups) {
    # ... emit parent object:
    # /FT /Btn
    # /T (groupName)
    # /Ff 49152 (or 49153 if readonly)
    # /Kids [kid1 0 R kid2 0 R ...]
    # /V /selectedValue (or /Off)
}
```

### Parent Object Ff Flags

The parent field has Ff = 49152 (0xC000):

| Bit | Value | Meaning |
|-----|-------|---------|
| 15 | 0x4000 | NoToggleToOff — prevents deselecting all buttons |
| 16 | 0x8000 | Radio — identifies this as a radio group |
| 1 | 0x1 | ReadOnly (if any child has `-readonly 1`) |

### Object Hierarchy

```
AcroForm /Fields → [... ParentOID 0 R ...]

ParentOID 0 obj
  /FT /Btn
  /T (groupName)
  /Ff 49152
  /Kids [ChildOID1 0 R  ChildOID2 0 R  ChildOID3 0 R]
  /V /SelectedValue

ChildOID1 0 obj         (annotation widget)
  /Parent ParentOID 0 R
  /AS /Value1           (or /Off)
  /AP << /N << /Value1 OnOID 0 R /Off OffOID 0 R >> >>
```

Note: Individual radio button annotations are added to the page's `/Annots`
array, but they go into the radio group parent's `/Kids` — NOT directly
into the AcroForm's `/Fields` array.

---

## AcroForm Dictionary

The AcroForm dictionary is emitted during document finalization:

```
FORMOID 0 obj
<<
  /Fields [field1 0 R  field2 0 R  ... radioParent1 0 R ...]
  /DR 3 0 R
>>
endobj
```

### NeedAppearances

The `pdf(needAppearances)` flag is initialized to `0` and is **never set**
in the current implementation. Previous versions set it to `1` when combobox
or listbox fields were present, which caused the PDF viewer to regenerate
all appearance streams — including overriding the custom signature appearance
with nothing (since `/FT /Sig` has no standard viewer-generated appearance).

**Current behavior:** All field types generate their own appearance streams.
The NeedAppearances code path still exists but is effectively dead code:

```tcl
if {$pdf(needAppearances)} {
    my Pdfout "/NeedAppearances true\n"
}
```

### Catalog Reference

The AcroForm object ID is reserved before page content is written. The
Catalog object (object 1) includes:

```
/AcroForm FORMOID 0 R
```

This reference is only emitted if there are any form fields
(`[llength $pdf(forms)] > 0 || [dict size $pdf(radiogroups)] > 0`).

---

## Text Encoding

Field values and option strings pass through `CleanText` before being
written to the PDF:

```tcl
append stream "([CleanText $value $pdf(current_font)]) Tj"
```

`CleanText` handles:
- Escaping parentheses: `(` → `\(`, `)` → `\)`
- Escaping backslashes: `\` → `\\`
- Encoding non-ASCII characters according to the current font's encoding

For the 14 standard fonts, this means WinAnsiEncoding (a subset of Latin-1).
Characters outside this range may not render correctly in form fields.

---

## Object ID Management

### GetOid

```tcl
method GetOid {{noxref 0}} {
    if {!$noxref} { my StoreXref }
    set res $pdf(pdf_obj)
    incr pdf(pdf_obj)
    return $res
}
```

The `noxref` flag is used for radio group parent objects: their OID is
reserved early (when the first button in the group is created) but their
xref position is stored later during document finalization.

### AddObject

```tcl
method AddObject {body} {
    set oid [my GetOid]
    my Pdfout "$oid 0 obj\n$body\nendobj\n"
    return $oid
}
```

Returns the object ID. Used for appearance stream XObjects.

---

## Instance State

### pdf(forms)

A list of object references (e.g., `"10 0 R"`) for all top-level form
fields. Radio button children are NOT in this list — only the parent
group object is added during finalization.

### pdf(radiogroups)

A dict keyed by group name. Each value is a dict with:

| Key | Type | Description |
|-----|------|-------------|
| `parentOid` | integer | Reserved object ID for the parent field |
| `kids` | list | Annotation object IDs of child buttons |
| `selectedValue` | string | Value of the initially selected button |
| `readonly` | boolean | Whether any button in the group is readonly |

### pdf(needAppearances)

Boolean, initialized to `0`. Currently never set to `1`.
Retained for potential future use.

### pdf(checkboxoffobj)

Cached object ID for the shared empty checkbox "off" appearance.
Created on first checkbox and reused for all subsequent checkboxes.

### pdf(radiobtnoffobj)

Cached object ID for the shared empty radiobutton "off" appearance.
Same pattern as checkbox.

### pdf(zadbsetup)

Flag indicating ZapfDingbats font has been registered. Set by
`SetupZaDbFont`, checked to avoid duplicate registration.

---

## Error Handling

The method validates inputs and throws `PDF4TCL` errors:

| Condition | Error |
|-----------|-------|
| Unknown field type | `unknown form type $ftype` |
| Unknown option | `unknown option "$option"` |
| Checkbox init not boolean | `initial value for checkbutton must be boolean` |
| Bad `-on`/`-off` object | `bad id for -on` / `bad id for -off` |
| Combobox/listbox without `-options` | `-options is required for $ftype` |
| Radio without `-group` | `-group is required for radiobutton` |
| Radio without `-value` | `-value is required for radiobutton` |
| Push without action or caption | `-action or -caption is required for pushbutton` |
| Push URL action without URL | `-url is required when -action is url` |
| Invalid boolean option | (via `CheckBoolean`) |
| Invalid ID characters | (via `CheckWord`) |

---

## Extension Points

### Adding a New Field Type

1. Add the type name to the validation list (line ~3230).
2. Add any new options to the `switch` block in option parsing.
3. Add an appearance stream generation block (the `elseif` chain).
4. Add an annotation dictionary block (the second `elseif` chain).
5. Add the type to the insertion logic (radiobutton special case vs.
   direct addition to `pdf(forms)`).

### Custom Appearance Streams

Checkbox fields already support custom appearances via `-on` and `-off`
options pointing to xobject IDs. This pattern could be extended to other
types. The xobject must be created beforehand via `$pdf xobject`.

### Font Improvements

Current limitation: text positioning uses a fixed offset (`2 1.1 Td`).
A proper implementation would use font metrics to calculate baseline
position based on field height and font size:

```
baseline = fieldHeight * 0.3   (approximate for 18pt field)
textX = 2                      (left padding)
```

The pushbutton caption centering uses an estimated character width
(`strlen * fontSize * 0.5`), which is only approximate. Using
`getStringWidth` would give exact results but requires the font metrics
to be loaded.
