# pdf4tcl Interactive Forms – User Manual

## Introduction

pdf4tcl 0.9.4.1 extends the original `addForm` method with a complete set of
interactive form field types suitable for building professional PDF forms.
This manual covers all eight field types, their options, and practical usage
patterns.

### Supported Field Types

| Type | PDF Field Type | Purpose |
|------|---------------|---------|
| `text` | `/FT /Tx` | Single-line or multi-line text input |
| `password` | `/FT /Tx` | Masked text input (bullets) |
| `checkbox` | `/FT /Btn` | Toggle on/off (alias for `checkbutton`) |
| `combobox` | `/FT /Ch` | Dropdown selection, optionally editable |
| `listbox` | `/FT /Ch` | Scrollable list, optional multi-select |
| `radiobutton` | `/FT /Btn` | Mutually exclusive choice within a group |
| `pushbutton` | `/FT /Btn` | Clickable button with action |
| `signature` | `/FT /Sig` | Digital signature placeholder |

### Basic Syntax

```tcl
$pdf addForm type x y width height ?options...?
```

All coordinates follow the current coordinate system. When using `-orient 1`
(recommended), `x=0 y=0` is the top-left corner and y increases downward.

---

## Field Types in Detail

### 1. Text Field

A standard text input field. Supports single-line and multi-line modes.

```tcl
# Basic text field
$pdf addForm text 100 200 200 20 -id username

# Pre-filled text field
$pdf addForm text 100 230 200 20 -id city -init "Berlin"

# Multi-line text area
$pdf addForm text 100 260 300 80 -id comments -multiline 1

# Read-only pre-filled field (not editable by user)
$pdf addForm text 100 350 200 20 -id order_nr -init "ORD-2026-0042" -readonly 1
```

**Options:**

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `-id` | string | auto | Unique field identifier |
| `-init` | string | "" | Initial/default value |
| `-multiline` | boolean | 0 | Enable multi-line mode |
| `-readonly` | boolean | 0 | Prevent user editing |

**Notes:**
- The current font (set via `setFont`) determines the field's text appearance.
- For multi-line fields, height should be large enough to hold multiple lines.
- When `-init` is set, an appearance stream is generated showing the text.

---

### 2. Password Field

Identical to a text field but displays bullet characters (•) instead of the
actual text. Useful for login forms or sensitive data entry.

```tcl
$pdf addForm password 100 200 150 20 -id pw -init "secret"
```

**Options:** Same as `text` except `-multiline` is not meaningful.

**Notes:**
- The appearance stream shows bullet characters for the initial value.
- In the PDF viewer, typed characters are also masked.
- The actual value is stored unmasked in the PDF's form data.

---

### 3. Checkbox

A toggle field that can be checked or unchecked. The name `checkbox` is an
alias for `checkbutton` — both are fully interchangeable.

```tcl
# Unchecked checkbox
$pdf addForm checkbox 100 200 14 14 -id accept_terms

# Pre-checked checkbox
$pdf addForm checkbox 100 220 14 14 -id newsletter -init 1

# Read-only (locked) checkbox
$pdf addForm checkbox 100 240 14 14 -id verified -init 1 -readonly 1
```

**Options:**

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `-id` | string | auto | Unique field identifier |
| `-init` | boolean | 0 | Initial state (0=off, 1=on) |
| `-readonly` | boolean | 0 | Prevent toggling |
| `-on` | xobject-id | — | Custom appearance for "on" state |
| `-off` | xobject-id | — | Custom appearance for "off" state |

**Notes:**
- Default appearance uses a ZapfDingbats checkmark (✔) for the "on" state.
- Custom appearances must be created via `xobject` beforehand.
- Width and height should typically be equal (square).

---

### 4. Combobox

A dropdown selection field. The user clicks to reveal a list of options and
selects one. Optionally, the field can be editable, allowing free-text entry.

```tcl
# Basic dropdown
$pdf addForm combobox 100 200 180 20 -id country \
    -options {"Germany" "Netherlands" "Belgium" "France"}

# Pre-selected value
$pdf addForm combobox 100 230 180 20 -id status \
    -options {"Open" "In Progress" "Closed"} -init "Open"

# Editable combobox (user can type custom values)
$pdf addForm combobox 100 260 180 20 -id category \
    -options {"Hardware" "Software" "Service"} -editable 1

# Sorted options
$pdf addForm combobox 100 290 180 20 -id city \
    -options {"Berlin" "Amsterdam" "Paris" "Zurich"} -sort 1

# Read-only (displays fixed value)
$pdf addForm combobox 100 320 180 20 -id locked \
    -options {"Fixed Value"} -init "Fixed Value" -readonly 1
```

**Options:**

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `-id` | string | auto | Unique field identifier |
| `-options` | list | — | **Required.** List of selectable values |
| `-init` | string | "" | Pre-selected value |
| `-editable` | boolean | 0 | Allow free-text entry |
| `-sort` | boolean | 0 | Sort options alphabetically |
| `-readonly` | boolean | 0 | Prevent selection changes |

**Notes:**
- The appearance stream includes a dropdown arrow indicator.
- A combobox generates its own appearance stream, so no `NeedAppearances`
  flag is required in the document's AcroForm dictionary. This is important
  because `NeedAppearances` would interfere with signature fields.

---

### 5. Listbox

A scrollable list showing multiple options simultaneously. Supports both
single-select and multi-select modes.

```tcl
# Single-select listbox
$pdf addForm listbox 100 200 180 60 -id department \
    -options {"Engineering" "Sales" "Marketing" "Support" "HR"}

# Multi-select listbox
$pdf addForm listbox 100 270 180 60 -id skills \
    -options {"Tcl" "Python" "C++" "Java" "Rust" "Go"} -multiselect 1

# Pre-selected value
$pdf addForm listbox 100 340 180 60 -id priority \
    -options {"Low" "Normal" "High" "Critical"} -init "Normal"

# Read-only
$pdf addForm listbox 100 410 180 60 -id fixed \
    -options {"Locked"} -init "Locked" -readonly 1
```

**Options:**

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `-id` | string | auto | Unique field identifier |
| `-options` | list | — | **Required.** List of selectable values |
| `-init` | string | "" | Pre-selected value |
| `-multiselect` | boolean | 0 | Allow selecting multiple items |
| `-sort` | boolean | 0 | Sort options alphabetically |
| `-readonly` | boolean | 0 | Prevent selection changes |

**Notes:**
- Height determines how many items are visible without scrolling.
- Like combobox, listbox generates its own appearance stream.

---

### 6. Radiobutton

Mutually exclusive selection within a named group. Only one button per group
can be selected at a time.

```tcl
# A group of three radio buttons
$pdf addForm radiobutton 100 200 12 12 -group priority -value Low
$pdf addForm radiobutton 100 220 12 12 -group priority -value Normal -init 1
$pdf addForm radiobutton 100 240 12 12 -group priority -value High

# A separate group
$pdf addForm radiobutton 100 280 12 12 -group color -value Red -init 1
$pdf addForm radiobutton 100 300 12 12 -group color -value Blue

# Read-only group (set -readonly on any button in the group)
$pdf addForm radiobutton 100 340 12 12 -group locked -value Yes -init 1 -readonly 1
$pdf addForm radiobutton 100 360 12 12 -group locked -value No -readonly 1
```

**Options:**

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `-group` | string | — | **Required.** Group name |
| `-value` | string | — | **Required.** Value when selected |
| `-init` | boolean | 0 | Set to 1 for the initially selected button |
| `-readonly` | boolean | 0 | Locks the entire group |
| `-id` | string | auto | Override auto-generated ID |

**Notes:**
- The `-group` name becomes the field name in the PDF.
- If `-id` is not given, it defaults to `groupName_value`.
- Setting `-readonly 1` on *any* button in a group locks the *entire* group.
- The appearance uses a filled circle (ZapfDingbats bullet) for the selected
  state and an empty circle for unselected.
- Radio groups are finalized at document write time. A parent field object
  is created with `/Ff` flags including NoToggleToOff and Radio bits.

---

### 7. Pushbutton

A clickable button that triggers an action. Three action types are supported:
URL navigation, form reset, and form submission.

```tcl
# Reset button – clears all form fields
$pdf addForm pushbutton 100 200 90 24 -id btnReset \
    -caption "Reset" -action reset

# URL button – opens a web page or runs JavaScript
$pdf addForm pushbutton 200 200 90 24 -id btnWeb \
    -caption "Website" -action url -url "https://example.com"

# Submit button – posts form data to a server
$pdf addForm pushbutton 300 200 100 24 -id btnSubmit \
    -caption "Submit" -action submit -url "https://example.com/api"

# Print button (via JavaScript)
$pdf addForm pushbutton 410 200 90 24 -id btnPrint \
    -caption "Print" -action url -url "javascript:this.print()"

# Read-only (grayed out, non-interactive)
$pdf addForm pushbutton 100 240 90 24 -id btnDisabled \
    -caption "Disabled" -action reset -readonly 1
```

**Options:**

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `-id` | string | auto | Unique field identifier |
| `-caption` | string | "" | Button label text |
| `-action` | string | — | Action type: `reset`, `url`, or `submit` |
| `-url` | string | — | URL for `url` and `submit` actions |
| `-readonly` | boolean | 0 | Disable the button |

**Notes:**
- Either `-action` or `-caption` (or both) is required.
- The `-url` option is required when `-action` is `url` or `submit`.
- The appearance shows a gray button with centered caption text.

---

### 8. Signature

A digital signature placeholder field. When opened in a PDF viewer that
supports digital signatures (Adobe Acrobat, Foxit Reader), the user can click
the field and apply a cryptographic signature using a certificate.

```tcl
# Basic signature field
$pdf addForm signature 100 200 200 60 -id sig_customer

# With custom label text
$pdf addForm signature 100 270 200 60 -id sig_approver \
    -label "Approved by"

# Read-only signature placeholder
$pdf addForm signature 100 340 200 60 -id sig_locked \
    -label "Signed" -readonly 1
```

**Options:**

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `-id` | string | auto | Unique field identifier |
| `-label` | string | "Signature" | Placeholder text above the signature line |
| `-readonly` | boolean | 0 | Lock the signature field |

**Notes:**
- The appearance shows a light gray box with a dashed signature line at 25%
  height and the label text above it.
- If no `-id` is given, one is auto-generated as `Signature<oid>`.
- Signature fields use `/FT /Sig` and do **not** require `NeedAppearances`.
  This was a critical design decision — see the section on NeedAppearances below.
- Not all PDF viewers support signature fields. Evince, for example, may not
  render the placeholder. Adobe Acrobat and Foxit Reader work well.

---

## The -readonly Option

The `-readonly` option is available on all eight field types. It sets bit 1
of the PDF field flags (`/Ff`), preventing the user from modifying the field
in a PDF viewer.

### Common Patterns

**Pre-filled order data that the user should not change:**

```tcl
$pdf addForm text 100 50 200 18 -id order_nr \
    -init "ORD-2026-4711" -readonly 1
$pdf addForm text 100 75 200 18 -id date \
    -init "2026-02-15" -readonly 1
```

**Mixed editable and locked fields on the same form:**

```tcl
# System-generated fields (locked)
$pdf addForm text 100 50 200 18 -id account \
    -init "ACC-001" -readonly 1

# User-editable fields
$pdf addForm text 100 80 200 18 -id name
$pdf addForm text 100 110 200 18 -id email
```

**Completed checklist items alongside open ones:**

```tcl
# Already verified (locked)
$pdf addForm checkbox 100 50 12 12 -id step1 -init 1 -readonly 1
$pdf text "Installation complete" -x 116 -y 53

# Still open (editable)
$pdf addForm checkbox 100 70 12 12 -id step2
$pdf text "Documentation reviewed" -x 116 -y 73
```

### Ff Flag Values with ReadOnly

| Field Type | Normal Ff | ReadOnly Ff |
|-----------|----------|------------|
| text | 0 | 1 |
| text -multiline | 4096 | 4097 |
| password | 8192 | 8193 |
| combobox | 131072 | 131073 |
| combobox -editable | 196608 | 196609 |
| listbox | 0 | 1 |
| listbox -multiselect | 2097152 | 2097153 |
| checkbutton/checkbox | 0 | 1 |
| radiobutton (group) | 49152 | 49153 |
| pushbutton | 65536 | 65537 |
| signature | 0 | 1 |

---

## Coordinate Systems

pdf4tcl supports two coordinate orientations:

**`-orient 0` (default):** Origin at bottom-left, y increases upward
(standard PDF coordinates). This matches the original pdf4tcl behavior.

**`-orient 1` (recommended for forms):** Origin at top-left, y increases
downward. This is more intuitive for building forms top-to-bottom.

```tcl
# Recommended setup for form creation
pdf4tcl::new pdf -paper a4 -orient 1 -compress 0
pdf startPage

set y 40   ;# Start near the top
# ... add fields, incrementing y downward ...
```

Form fields honor the current coordinate system. The `addForm` method
internally transforms coordinates via `Trans`/`TransR` and normalizes
height to be positive regardless of orientation.

---

## Working with Fonts

Form fields use the current font set via `setFont`. This affects:

- Text rendering in appearance streams (initial values, captions)
- The `/DA` (Default Appearance) string in the annotation dictionary

```tcl
$pdf setFont 10 Helvetica
$pdf addForm text 100 200 200 20 -id name

$pdf setFont 8 Courier
$pdf addForm text 100 230 200 20 -id code -init "ABC-123"
```

**Supported fonts** for form fields are the 14 standard PDF fonts:
Helvetica, Helvetica-Bold, Helvetica-Oblique, Helvetica-BoldOblique,
Times-Roman, Times-Bold, Times-Italic, Times-BoldItalic,
Courier, Courier-Bold, Courier-Oblique, Courier-BoldOblique,
Symbol, and ZapfDingbats.

---

## Practical Examples

### 1. Simple Contact Form

```tcl
pdf4tcl::new pdf -paper a4 -orient 1 -compress 0
pdf startPage
pdf setFont 12 Helvetica-Bold
pdf text "Contact Form" -x 50 -y 40

pdf setFont 10 Helvetica
set y 70
foreach {label id} {
    "Name:"    name
    "Email:"   email
    "Phone:"   phone
    "Company:" company
} {
    pdf text $label -x 50 -y [expr {$y + 4}]
    pdf addForm text 150 $y 250 18 -id $id
    set y [expr {$y + 26}]
}

pdf text "Message:" -x 50 -y [expr {$y + 4}]
pdf addForm text 150 $y 250 60 -id message -multiline 1
set y [expr {$y + 70}]

pdf addForm pushbutton 150 $y 80 22 -id send \
    -caption "Send" -action submit -url "https://example.com/contact"
pdf addForm pushbutton 240 $y 80 22 -id clear \
    -caption "Clear" -action reset

pdf write -file contact.pdf
pdf destroy
```

### 2. Pre-Filled Delivery Note with Confirmation

```tcl
pdf4tcl::new pdf -paper a4 -orient 1 -compress 0
pdf startPage
pdf setFont 14 Helvetica-Bold
pdf text "Delivery Note" -x 50 -y 40

pdf setFont 9 Helvetica
set y 70

# Pre-filled, read-only fields (from database)
foreach {label id value} {
    "Order No.:"  order_nr  "LS-2026-01234"
    "Date:"       date      "2026-02-15"
    "Customer:"   customer  "Acme Corp"
} {
    pdf text $label -x 50 -y [expr {$y + 4}]
    pdf addForm text 150 $y 200 18 -id $id -init $value -readonly 1
    set y [expr {$y + 24}]
}

# Editable driver fields
set y [expr {$y + 10}]
pdf setFont 10 Helvetica-Bold
pdf text "Driver (please fill in)" -x 50 -y $y
set y [expr {$y + 20}]
pdf setFont 9 Helvetica

pdf text "Name:" -x 50 -y [expr {$y + 4}]
pdf addForm text 150 $y 200 18 -id driver_name
set y [expr {$y + 24}]

pdf text "License Plate:" -x 50 -y [expr {$y + 4}]
pdf addForm text 150 $y 120 18 -id license_plate
set y [expr {$y + 30}]

# Confirmation checkboxes
pdf addForm checkbox 50 $y 12 12 -id complete
pdf text "Delivery complete" -x 66 -y [expr {$y + 3}]
set y [expr {$y + 20}]

pdf addForm checkbox 50 $y 12 12 -id undamaged
pdf text "Goods undamaged" -x 66 -y [expr {$y + 3}]
set y [expr {$y + 30}]

# Signature for confirmation
pdf text "Received by:" -x 50 -y $y
pdf addForm signature 50 [expr {$y + 14}] 200 50 \
    -id sig_received -label "Signature"

pdf write -file delivery_note.pdf
pdf destroy
```

### 3. Survey with Radio Groups

```tcl
pdf4tcl::new pdf -paper a4 -orient 1 -compress 0
pdf startPage
pdf setFont 14 Helvetica-Bold
pdf text "Customer Survey" -x 50 -y 40

pdf setFont 9 Helvetica
set y 70

proc addRating {pdf y groupName questionText} {
    $pdf text $questionText -x 50 -y [expr {$y + 3}]
    set rx 300
    foreach {val label} {1 Poor 2 Fair 3 Good 4 Excellent} {
        $pdf addForm radiobutton $rx $y 10 10 \
            -group $groupName -value $val
        $pdf text $label -x [expr {$rx + 14}] -y [expr {$y + 3}]
        set rx [expr {$rx + 70}]
    }
}

addRating pdf $y q1 "Product quality:"
set y [expr {$y + 24}]
addRating pdf $y q2 "Customer service:"
set y [expr {$y + 24}]
addRating pdf $y q3 "Value for money:"
set y [expr {$y + 34}]

pdf text "Additional comments:" -x 50 -y [expr {$y + 4}]
pdf addForm text 50 [expr {$y + 18}] 450 60 -id comments -multiline 1

set y [expr {$y + 90}]
pdf addForm pushbutton 50 $y 100 24 -id submit \
    -caption "Submit" -action submit -url "https://example.com/survey"

pdf write -file survey.pdf
pdf destroy
```

---

## Important Notes

### NeedAppearances

Previous versions of the addForm extension set the `/NeedAppearances true`
flag in the AcroForm dictionary when combobox or listbox fields were present.
This instructed the PDF viewer to regenerate all appearance streams at open
time.

**Problem:** NeedAppearances overrides custom appearance streams, including
those for signature fields. This caused signature placeholders to appear
blank.

**Solution (current version):** Combobox and listbox fields now generate
their own appearance streams. The NeedAppearances flag is never set. All
field types coexist correctly in the same document.

### PDF Viewer Compatibility

| Viewer | text | checkbox | combobox | listbox | radio | pushbutton | signature |
|--------|------|----------|----------|---------|-------|------------|-----------|
| Adobe Acrobat | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ |
| Foxit Reader | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ |
| Chrome/Edge | ✓ | ✓ | ✓ | ✓ | ✓ | partial | — |
| Evince | ✓ | ✓ | ✓ | ✓ | ✓ | partial | — |
| Okular | ✓ | ✓ | ✓ | ✓ | ✓ | partial | — |

**Notes:**
- Pushbutton actions (especially JavaScript) may not work in all viewers.
- Signature fields require a viewer with digital signature support.
- The `reset` action works in most viewers; `submit` requires network access.

### Reading Form Data Back

pdf4tcl provides `pdf4tcl::getForms` to extract form data from existing PDFs:

```tcl
set forms [pdf4tcl::getForms "filled_form.pdf"]
dict for {fieldId fieldInfo} $forms {
    puts "$fieldId: type=[dict get $fieldInfo type] value=[dict get $fieldInfo value]"
}
```

This returns a dictionary with field IDs as keys. Each value is a dictionary
containing `type`, `value`, `flags`, and optionally `default`.

---

## Quick Reference

```
$pdf addForm text      x y w h  ?-id ID? ?-init VALUE? ?-multiline BOOL? ?-readonly BOOL?
$pdf addForm password  x y w h  ?-id ID? ?-init VALUE? ?-readonly BOOL?
$pdf addForm checkbox  x y w h  ?-id ID? ?-init BOOL? ?-readonly BOOL? ?-on XOBJ? ?-off XOBJ?
$pdf addForm combobox  x y w h  -options LIST ?-id ID? ?-init VALUE? ?-editable BOOL? ?-sort BOOL? ?-readonly BOOL?
$pdf addForm listbox   x y w h  -options LIST ?-id ID? ?-init VALUE? ?-multiselect BOOL? ?-sort BOOL? ?-readonly BOOL?
$pdf addForm radiobutton x y w h -group NAME -value VAL ?-init BOOL? ?-readonly BOOL? ?-id ID?
$pdf addForm pushbutton  x y w h ?-id ID? -caption TEXT ?-action TYPE? ?-url URL? ?-readonly BOOL?
$pdf addForm signature   x y w h ?-id ID? ?-label TEXT? ?-readonly BOOL?
```

---

## Interactive Demo

The file demo-forms-tk.tcl provides a Tk GUI for interactively testing
all eight field types. Features include configurable page margins,
font/size selection via comboboxes, and several debug overlays.

### Running the Demo

    wish demo-forms-tk.tcl

### Tabs

Page and Margins: Paper format, orientation, compression, margin
spinboxes (mm), computed printable area display.

Fonts and Sizes: Three combobox pairs for title, label, and form field
fonts. The form field font determines the /DA string in the PDF which
controls how text appears in interactive fields.

Field Types: Checkbuttons for each of the eight types. Fields can be
toggled individually or all at once.

Debug: Five checkbutton options plus four info buttons.

### Debug Options

Margin lines: Red dashed lines showing the printable area boundary
with corner coordinates in points.

Coordinates: Small (x,y) text next to each label, showing the
exact position in the current coordinate system.

Field IDs: Shows id=xxx next to each field. Useful when correlating
with getForms output.

AcroForm dump: After PDF creation, calls pdf4tcl::getForms and logs
each field with type, flags, and value.

### Info Buttons

| Button | Funktion |
|---|---|
| pdf4tcl Info | Version, Package-Pfad, verfuegbare Kommandos |
| Font-Liste | Alle 14 Standard-Fonts mit Oblique/Italic-Hinweis |
| Koordinaten-Rechner | Y-Werte fuer beide Orient-Modi, Umrechnung mm/pt/in |
| Ff-Flag Rechner | Alle Bit-Konstanten mit Hex-Werten und Kombinationen |

### See Also

The demo generates demo-forms-output.pdf in the current directory.
For implementation details, see pdf4tcl-forms-technical.md.

## Tooltip and Tab Order (0.9.4.13)

Two new options improve PDF/UA accessibility and keyboard navigation:

### -tooltip

Sets the `/TU` (tooltip) field in the PDF annotation dictionary.
PDF viewers display this string as a tooltip when hovering over the field.
Screen readers use it as the accessible label.

```tcl
$pdf setFont 10 Helvetica
$pdf addForm text 140 105 240 16 \
    -id "f_name" \
    -tooltip "Enter the customer's full name"

$pdf addForm combobox 140 130 200 16 \
    -id "f_country" \
    -options {Germany Austria Switzerland} \
    -tooltip "Select the country of delivery"
```

### -tabindex

Sets the `/TI` (tab index) field. Controls the keyboard tab order between
fields. Fields are visited in ascending order of their tab index.

```tcl
$pdf setFont 10 Helvetica
$pdf addForm text 140 105 240 16 -id "f_name"    -tabindex 1
$pdf addForm text 140 130 240 16 -id "f_email"   -tabindex 2
$pdf addForm text 140 155 240 16 -id "f_phone"   -tabindex 3
$pdf addForm pushbutton 140 180 80 20 \
    -id "submit" -caption "Submit" \
    -action reset -tabindex 4
```

Note: pdf4tcl also writes `/Tabs /R` in the page dictionary when form
fields are present, enabling row-based tab order in compliant viewers.

## Encryption and Forms (0.9.4.16)

When encryption is active, pdf4tcl encrypts all PDF string objects in
field dictionaries (ISO 32000 §7.6.5), including `/T` (field name), `/DA`
(default appearance), `/V` (initial value), `/TU` (tooltip), and `/CA`
(button caption). Appearance streams (AP entries) are encrypted as PDF
streams. Each encrypted value gets its own random 16-byte IV.

Without string encryption, PDF viewers decrypt `/T` field names and receive
corrupted text. Since all corrupted names collide, any text typed in one
field appears in all fields.

No API change is required. String encryption is applied automatically
whenever the document is encrypted. **Validated against qpdf, Evince, and
Firefox (PDF.js).**

**Note on Chrome:** Chrome's built-in PDF renderer does not display AcroForm
fields at all — this is a viewer limitation unrelated to encryption.

```tcl
# AES-128: forms work correctly with encryption
set p [pdf4tcl::new %AUTO% -paper a4 -userpassword "secret"]
$p startPage
$p setFont 10 Helvetica
$p addForm text 140 105 240 16 -id "f_name" -init ""
$p addForm text 140 130 240 16 -id "f_email" -init ""
$p endPage
$p write -file form-enc.pdf
$p destroy

# AES-256
set p [pdf4tcl::new %AUTO% -paper a4 \
    -userpassword "secret" -encversion 5]
```
