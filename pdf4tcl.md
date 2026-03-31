# pdf4tcl

## NAME

pdf4tcl - Pdf document generation

## SYNOPSIS

package require **Tcl 8****.6**

package require **pdf4tcl ?0****.9****.4****.25?**

**::pdf4tcl::new** *objectName* ?*option value*...?

**::pdf4tcl::getPaperSize** *paper*

**::pdf4tcl::getPaperSizeList**

**::pdf4tcl::getPoints** *val*

**::pdf4tcl::loadBaseTrueTypeFont** *basefontname* *ttf_file_name*

**::pdf4tcl::createBaseTrueTypeFont** *basefontname* *ttf_data*

**::pdf4tcl::loadBaseType1Font** *basefontname* *AFM_file_name* *PFB_file_name*

**::pdf4tcl::createBaseType1Font** *basefontname* *AFM_data* *PFB_data*

**::pdf4tcl::createFont** *basefontname* *fontname* *encoding_name*

**::pdf4tcl::createFontSpecEnc** *basefontname* *fontname* *subset*

**::pdf4tcl::createFontSpecCID** *basefontname* *fontname*

**::pdf4tcl::getFonts**

**::pdf4tcl::rgb2Cmyk** *rgb*

**::pdf4tcl::cmyk2Rgb** *cmyk*

**::pdf4tcl::catPdf** *infile* ?*infile **.**.**.*? *outfile*

**::pdf4tcl::getForms** *infile*

**::pdf4tcl::exportForms** *infile* *outfile* ?*options*?

**objectName** **method** ?*arg arg **.**.**.*?

*objectName* **configure**

*objectName* **configure** *option*

*objectName* **configure** **-option** *value*...

*objectName* **cget** **-option**

*objectName* **destroy**

*objectName* **startPage** ?*option value*...?

*objectName* **endPage**

*objectName* **startXObject** ?*option value*...?

*objectName* **endXObject**

*objectName* **finish**

*objectName* **get**

*objectName* **write** ?*-file filename*? ?*-chan channel*? ?*-dryrun bool*?

*objectName* **addForm** *type* *x* *y* *width* *height* ?*option value*...?

*objectName* **getDrawableArea**

*objectName* **canvas** *path* ?*option value*...?

*objectName* **metadata** ?*option value*...?

*objectName* **bookmarkAdd** ?*option value*...?

*objectName* **embedFile** *filename* ?*option value*...?

*objectName* **attachFile** *x* *y* *width* *height* *fid* *description* ?*option value*...?

*objectName* **addEmbeddedFile** *filename* ?*option value*...?

*objectName* **hyperlinkAdd** *x* *y* *width* *height* *url* ?*option value*...?

*objectName* **addAnnotNote** *x* *y* *width* *height* ?*option value*...?

*objectName* **addAnnotFreeText** *x* *y* *width* *height* *text* ?*option value*...?

*objectName* **addAnnotHighlight** *x* *y* *width* *height* ?*option value*...?

*objectName* **addAnnotUnderline** *x* *y* *width* *height* ?*option value*...?

*objectName* **addAnnotStrikeOut** *x* *y* *width* *height* ?*option value*...?

*objectName* **addAnnotStamp** *x* *y* *width* *height* ?*option value*...?

*objectName* **addAnnotLine** *x1* *y1* *x2* *y2* ?*option value*...?

*objectName* **viewerPreferences** ?*option value*...?

*objectName* **pageLabel** *pageIndex* ?*option value*...?

*objectName* **setFont** *size* ?*fontname*?

*objectName* **getStringWidth** *str* ?*options*?

*objectName* **getCharWidth** *char*

*objectName* **inPage**

*objectName* **currentPage**

*objectName* **pageCount**

*objectName* **setTextPosition** *x* *y*

*objectName* **moveTextPosition** *dx* *dy*

*objectName* **getTextPosition**

*objectName* **newLine** ?*spacing*?

*objectName* **setLineSpacing** *spacing*

*objectName* **getLineSpacing**

*objectName* **getLineHeight**

*objectName* **text** *str* ?*option value*...?

*objectName* **drawTextBox** *x* *y* *width* *height* *str* ?*option value*...?

*objectName* **getFontMetric** *metric*

*objectName* **putImage** *id* *x* *y* ?*option value*...?

*objectName* **putRawImage** *data* *x* *y* ?*option value*...?

*objectName* **addImage** *filename* ?*option value*...?

*objectName* **addRawImage** *data* ?*option value*...?

*objectName* **getImageHeight** *id*

*objectName* **getImageSize** *id*

*objectName* **getImageWidth** *id*

*objectName* **setBgColor** *red* *green* *blue*

*objectName* **setBgColor** *c* *m* *y* *k*

*objectName* **setFillColor** *red* *green* *blue*

*objectName* **setFillColor** *c* *m* *y* *k*

*objectName* **setStrokeColor** *red* *green* *blue*

*objectName* **setStrokeColor** *c* *m* *y* *k*

*objectName* **setAlpha** *value*

*objectName* **setAlpha** *value* **-fill**

*objectName* **setAlpha** *value* **-stroke**

*objectName* **setAlpha** *fillValue* *strokeValue*

*objectName* **getAlpha**

*objectName* **setBlendMode** *mode*

*objectName* **getBlendMode**

*objectName* **linearGradient** *x1* *y1* *x2* *y2* *color1* *color2* ?*options*?

*objectName* **radialGradient** *cx1* *cy1* *r1* *cx2* *cy2* *r2* *color1* *color2* ?*options*?

*objectName* **setLineWidth** *width*

*objectName* **setLineDash** ?*on off*...? ?*offset*?

*objectName* **setLineStyle** *width* *args*

*objectName* **line** *x1* *y1* *x2* *y2*

*objectName* **curve** *x1* *y1* *x2* *y2* *x3* *y3* ?*x4 y4*?

*objectName* **polygon** ?*x y*...? ?*option value*...?

*objectName* **circle** *x* *y* *radius* ?*option value*...?

*objectName* **oval** *x* *y* *radiusx* *radiusy* ?*option value*...?

*objectName* **arc** *x* *y* *radiusx* *radiusy* *phi* *extend* ?*option value*...?

*objectName* **arrow** *x1* *y1* *x2* *y2* *size* ?*angle*?

*objectName* **rectangle** *x* *y* *width* *height* ?*option value*...?

*objectName* **roundedRect** *x* *y* *width* *height* ?*option value*...?

*objectName* **clip** *x* *y* *width* *height*

*objectName* **gsave**

*objectName* **grestore**

*objectName* **transform** *a* *b* *c* *d* *e* *f*

*objectName* **translate** *tx* *ty*

*objectName* **rotate** *degrees*

*objectName* **scale** *sx* *sy*

*objectName* **getPageSize**

*objectName* **addEmbeddedFile** *filename* ?*options*?

*objectName* **addLayer** *name* ?**-visible bool**?

*objectName* **beginLayer** *layerId*

*objectName* **endLayer**

*objectName* **_WriteXrefTable** *idHash* *encdict_oid* *metadata_oid*

*objectName* **_WriteXrefStream** *idHash* *encdict_oid* *metadata_oid*

## DESCRIPTION

This package provides a container class for generating *pdf* documents.

## COORDINATES

All coordinates and distances can be expressed with or without a unit. See **UNITS** for valid units. When the page is configured with **-orient** set to false, origin is in the bottom left corner. With **-orient** true (the default), origin is in the top left corner. Origin is displaced to account for margins, i.e. if margins are 100, the user coordinate (0,0) corresponds to (100,100) on the paper. Page option **-orient** can also affect the anchor point for things like images.

## UNITS

Any coordinates and distances can be expressed with or without an explicit unit. If no unit is given, the default unit for the document is used. A unit may be one of **mm** (millimeter), **m** (millimeter), **cm** (centimeter), **c** (centimeter), **p** (points) or **i** (inches). Commands returning coordinates or distances always return a double value in the document's default unit.

## PUBLIC API

### PACKAGE COMMANDS

- Color bitmap fonts with CBDT/CBLC tables (e.g. "*NotoColorEmoji**.ttf*")
- Apple bitmap fonts with sbix table (macOS system emoji)
- Layered color vector fonts with COLR/CPAL tables (e.g. Segoe UI Emoji on Windows)
- OpenType fonts with PostScript outlines (OTTO magic, CFF-based)

**::pdf4tcl::new objectName ?option value...?**
: This command creates a new pdf4tcl object with an associated Tcl command whose name is *objectName*. This *object* command is explained in full detail in the sections **OBJECT COMMAND** and **OBJECT METHODS**. The object command will be created under the current namespace if the *objectName* is not fully qualified, and in the specified namespace otherwise. If *objectName* is %AUTO% a name will generated. The return value is the newly created object's name. The options and their values coming after the name of the object are used to set the initial configuration of the object. See **OBJECT CONFIGURATION**.

**::pdf4tcl::getPaperSize paper**
: This call returns the size of a named paper type, e.g. "a4". Paper names are case insensitive. The argument *paper* may also be a two element list with values as accepted by **::pdf4tcl::getPoints**. The return value is a list with width and height in points.

**::pdf4tcl::getPaperSizeList**
: This call returns the list of known paper types.

**::pdf4tcl::getPoints val**
: This call translates a measurement to points (1/72 inch). The format of *val* is '*num* ?*unit*?' where *num* is a valid integer or double. See **UNITS** for valid *unit*s. If no *unit* is given, the value is interpreted as points.

**::pdf4tcl::loadBaseTrueTypeFont basefontname ttf_file_name**
: This call loads a TTF font from file to be used by any pdf4tcl objects. The *basefontname* is used to reference this font. To use this base font in documents, a font with some encoding must be created from it using **createFont**, **createFontSpecEnc**, or **createFontSpecCID**. Only TrueType outline fonts (TTF) are supported. The following font types are detected and rejected with a descriptive error: For emoji and symbol coverage, use a vector outline font such as or "*Symbola**.ttf*" (*https://dn-works**.com/ufas/*).

**::pdf4tcl::createBaseTrueTypeFont basefontname ttf_data**
: This call creates a base font from TTF binary data.

**::pdf4tcl::loadBaseType1Font basefontname AFM_file_name PFB_file_name**
: This call loads a Type1 font from two files (.afm and .pfb) to be used by any pdf4tcl objects. The *basefontname* is used to reference this font. To use this base font in documents, a font with some encoding must be created from it using **createFont** or **createFontSpecEnc**.

**::pdf4tcl::createBaseType1Font basefontname AFM_data PFB_data**
: This call creates a base font from AFM text and PFB binary data.

**::pdf4tcl::createFont basefontname fontname encoding_name**
: This call creates a font that can be used in documents from a base font. The given encoding defines the (up to) 256 unicode characters that can be drawn when *fontname* is selected. To use more characters, multiple fonts need to be created and selected based on what needs to be written.

```tcl
pdf4tcl::loadBaseTrueTypeFont BaseArial "arial.ttf"
pdf4tcl::createFont BaseArial MyArial cp1251
pdf4tcl::loadBaseType1Font BaseType1 "a010013l.afm" "a010013l.pfb"
pdf4tcl::createFont BaseType1 MyType1 cp1251
pdf4tcl::new mypdf -paper a4 -compress 0
mypdf startPage
mypdf setFont 10 MyArial
set txt "\u042D\u0442\u043E \u0442\u0435\u043A\u0441\u0442 \u043D\u0430 \u0440\u0443\u0441\u0441\u043A\u043E\u043C\
         \u044F\u0437\u044B\u043A\u0435. This is text in Russian."
mypdf text $txt -bg #CACACA -x 50 -y 100
mypdf setFont 10 MyType1
mypdf text $txt -x 50 -y 200
mypdf write -file fonts.pdf
mypdf destroy
```

**::pdf4tcl::createFontSpecEnc basefontname fontname subset**
: This call creates a font that can be used in documents from a base font. The *subset* must be a list of (up to 256) unicode values which are the characters that can be drawn when *fontname* is selected.

```tcl
pdf4tcl::loadBaseTrueTypeFont BaseArial "arial.ttf"
# Subset is a list of unicodes:
for {set f 0} {$f < 128} {incr f} {lappend subset $f}
lappend subset [expr 0xB2] [expr 0x3B2]
pdf4tcl::createFontSpecEnc BaseArial MyArial $subset
pdf4tcl::new mypdf -paper a4
mypdf startPage
mypdf setFont 16 MyArial
set txt "sin\u00B2\u03B2 + cos\u00B2\u03B2 = 1"
mypdf text $txt -x 50 -y 100
mypdf write -file specenc.pdf
mypdf destroy
```

**::pdf4tcl::createFontSpecCID basefontname fontname**
: This call creates a Unicode-capable CID font (CIDFontType2 with Identity-H encoding) from a previously loaded TrueType base font. Unlike **createFont** and **createFontSpecEnc**, which are limited to 256 characters per font instance, a CID font supports any Unicode character covered by the underlying TTF file. This includes Latin Extended, Greek, Cyrillic, CJK ideographs, and other scripts. The full TTF binary is embedded in the PDF. Characters in the Supplementary Multilingual Plane (SMP, U+10000 and above) are supported. They are encoded as UTF-16BE surrogate pairs in the ToUnicode CMap, as required by the PDF specification (ISO 32000, §9.10.3). This enables correct text extraction and copy-paste from PDF viewers for characters such as mathematical alphanumerics (U+1D400), musical symbols (U+1D100), or emoji from vector outline fonts (U+1F300 and above).

```tcl
pdf4tcl::loadBaseTrueTypeFont DejaVuSans "/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf"
pdf4tcl::createFontSpecCID DejaVuSans myCIDFont
pdf4tcl::new mypdf -paper a4
mypdf startPage
mypdf setFont 14 myCIDFont
mypdf text "Latin: Hello World" -x 50 -y 750
mypdf text "Extended: \u00e4\u00f6\u00fc\u00df" -x 50 -y 720
mypdf text "Greek: \u0391\u03b2\u03b3\u03b4" -x 50 -y 690
mypdf text "Cyrillic: \u041f\u0440\u0438\u0432\u0435\u0442" -x 50 -y 660
mypdf endPage
mypdf write -file unicode.pdf
mypdf destroy
```

**type**
: Field type.

**value**
: Form value.

**flags**
: Value of form flags field.

**default**
: Default value, if any.

**-format fdf|xfdf**
: Output format. **fdf** (default): Forms Data Format (ISO 32000 SS12.7.7), a compact text format supported by most PDF viewers. **xfdf**: XML Forms Data Format (ISO 32000 SS12.7.8), human-readable XML.

**-password string**
: Password for encrypted PDFs.

**::pdf4tcl::getFonts**
: This call returns the list of known font names, i.e. those accepted in a call to **setFont**. This includes the default fonts and fonts created by e.g. **::pdf4tcl::createFont**.

**::pdf4tcl::rgb2Cmyk rgb**
: This call translates an RGB color value to a CMYK color value. It is used internally if **-cmyk** was set at object creation to translate colors. You can redefine this procedure to provide your own translation.

**::pdf4tcl::cmyk2Rgb cmyk**
: This call translates a CMYK color value to an RGB color value. It is used internally to translate colors. You can redefine this procedure to provide your own translation.

**::pdf4tcl::catPdf infile ?infile ...? outfile**
: This call concatenates PDF files into one. Currently the implementation limits the PDFs a lot since not all details are taken care of yet. Straightforward ones like those created with pdf4tcl or ps2pdf should work mostly ok.

**::pdf4tcl::getForms infile**
: This call extracts form data from a PDF file. The return value is a dictionary with id/info pairs. The id is the one set with *-id* to **addForm**, if the PDF was generated with pdf4tcl. The info is a dictionary with the following fields:

**::pdf4tcl::exportForms infile outfile ?options?**
: Export form field data from a filled PDF as FDF or XFDF (0.9.4.23+). Returns the number of exported fields.

```tcl
# Export as FDF
pdf4tcl::exportForms filled.pdf data.fdf
# Export as XFDF
pdf4tcl::exportForms filled.pdf data.xfdf -format xfdf
```

### OBJECT COMMAND

All commands created by **::pdf4tcl::new** have the following general form and may be used to invoke various operations on their pdf object.

**objectName method ?arg arg ...?**
: The method **method** and its *arg*'uments determine the exact behavior of the command. See section **OBJECT METHODS** for the detailed specifications.

### OBJECT METHODS

**-noimage bool**
: If this is set the XObject is not added to the image resource set and cannot be used with putImage, only in forms. The XObject also gets access to resources which is needed to use e.g. fonts within the XObject. This behaviour has shown to be PDF reader dependent, and it is currently not known if this can be made to work better.

**-file filename**
: Write PDF to the given file.

**-chan channel**
: Write PDF to the given open channel (e.g. from **open**, a socket or a memory channel). The channel must be opened for writing; it is not closed by this method. Added in version 0.9.4.25 (ported from the AndroWish fork, contributed by Christian Werner).

**-dryrun bool**
: If true, return the PDF data as a string without writing to a file and without modifying the document state. Useful for previewing or testing the output. Default is false.

**-id string**
: Unique field ID (alphanumeric). If omitted, one is generated automatically: *${type}form${n}* for most types, *${group}_${value}* for radiobuttons, *Signature${n}* for signatures.

**-init value**
: Initial value. For *text*/*password* a string, for *checkbutton* a boolean, for *combobox*/*listbox* an item from *-options*, for *radiobutton* a boolean selecting this button.

**-readonly boolean**
: If true, the field is read-only (PDF Ff bit 1). Default **0**.

**-required boolean**
: If true, the field is marked as required (PDF Ff bit 2). Default **0**. Not valid for *pushbutton* or *signature*.

**-multiline boolean**
: Enable multi-line editing (text only). Default **0**.

**-on xobjectId**
: Custom appearance XObject for the checked state. Created with **startXObject**.

**-off xobjectId**
: Custom appearance XObject for the unchecked state.

**-options list**
: List of selectable items. Required for *combobox* and *listbox*.

**-editable boolean**
: Allow typing custom values (combobox only). Default **0**.

**-sort boolean**
: Sort the option list. Default **0**.

**-multiselect boolean**
: Allow selecting multiple items (listbox only). Default **0**.

**-group string**
: Group name (required, alphanumeric). All buttons sharing the same group name form a mutually exclusive set.

**-value string**
: Value for this button (required, alphanumeric). Used as the PDF appearance state name.

**-action type**
: Action type: **reset** (clear all fields), **url** (open URL), or **submit** (submit form data to URL).

**-url string**
: Target URL. Required when *-action* is **url** or **submit**.

**-caption string**
: Button label text. Either *-action* or *-caption* (or both) must be given.

**-label string**
: Placeholder text displayed on the signature line. Default **Signature**. Only valid for *signature* fields.

**-tooltip string**
: Tooltip text written as PDF **/TU** (Tooltip User) entry. Displayed by PDF readers on hover and read aloud by screen readers (PDF/UA). Valid for all field types.

**-tabindex integer**
: Tab order index written as PDF **/TI** entry. Must be a non-negative integer. Used to define the logical keyboard tab order within the AcroForm. Valid for all field types.

**Common options**

**Text / Password options**

**Checkbutton options**

**Combobox / Listbox options**

**Radiobutton options**

**Pushbutton options**

**Signature options**

**Accessibility and tab order options**

**objectName configure**
: The method returns a list of all known options and their current values when called without any arguments.

**objectName configure option**
: The method behaves like the method **cget** when called with a single argument and returns the value of the option specified by said argument.

**objectName configure -option value...**
: The method reconfigures the specified **option**s of the object, setting them to the associated *value*s, when called with an even number of arguments, at least two. The legal options are described in the section **OBJECT CONFIGURATION**.

**objectName cget -option**
: This method expects a legal configuration option as argument and will return the current value of that option for the object the method was invoked for. The legal configuration options are described in section **OBJECT CONFIGURATION**.

**objectName destroy**
: This method destroys the object it is invoked for. If the **-file** option was given at object creation, the output file will be finished and closed.

**objectName startPage ?option value...?**
: This method starts a new page in the document. The page will have the default page settings for the document unless overridden by *option*. See **PAGE CONFIGURATION** for page settings. This will end any ongoing page.

**objectName endPage**
: This method ends a page in the document. It is normally not needed since it is implied by e.g. **startPage** and **finish**. However, if the document is built page by page in e.g. an event driven environment it can be good to call **endPage** explicitly to have all the page's work finished before reentering the event loop.

**objectName startXObject ?option value...?**
: This method starts a new XObject in the document. An XObject is a reusable drawing object and behaves just like a page where you can draw any graphics. An XObject must be created between pages and this method will end any ongoing page. The return value is an id that can be used with **putImage** to draw it on the current page or with some forms. All page settings (**PAGE CONFIGURATION**) are valid when creating an XObject. Default options are **-paper** = {100p 100p}, **-landscape** = 0, **-orient** = document default, **-margin**= 0.

**objectName endXObject**
: This method ends an XObject definition. It works just like **endPage**.

**objectName finish**
: This method ends the document. This will do **endPage** if needed. If the **-file** option was given at object creation, the output file will be finished and closed.

**objectName get**
: This method returns the generated pdf. This will do **endPage** and **finish** if needed. If the **-file** option was given at object creation, nothing is returned.

**objectName write ?-file filename? ?-chan channel? ?-dryrun bool?**
: This method writes the generated pdf to the given *filename* or *channel*. If neither **-file** nor **-chan** is given, output is written to stdout. This will do **endPage** and **finish** if needed. If the **-file** option was given at object creation, an empty file is created.

**objectName addForm type x y width height ?option value...?**
: Add an interactive form field at the given position and size. Coordinates are in the document's current unit. Supported types are *text*, *password*, *checkbutton* (alias *checkbox*), *combobox*, *listbox*, *radiobutton*, *pushbutton*, and *signature*.

- All fields generate their own appearance streams; the **NeedAppearances** flag is never set, ensuring compatibility with digital signature workflows. Radiobutton groups are finalized at document write time as a parent field with **/Kids** entries.

### OBJECT METHODS, PAGE

**-title text**
: Set the text of the bookmark.

**-level level**
: Set the level of the bookmark. Default is 0.

**-closed boolean**
: Select if the bookmark is closed by default. Default is false, i.e. not closed.

**-id id**
: Explicitly select an id for the file. The *id* must be unique within the document.

**-contents data**
: Provides the file contents instead of reading the actual file.

**-icon icon**
: Controls the appearance of the attachment. Valid values are Paperclip, Tag, Graph, or PushPin. Default value is Paperclip.

**objectName getDrawableArea**
: This method returns the size of the available area on the page, after removing margins. The return value is a list of width and height, in the document's default unit.

**objectName canvas path ?option value...?**
: Draws the contents of the canvas widget *path* on the current page. The return value is the bounding box in pdf page coordinates of the area covered. Option *-bbox* gives the area of the canvas to be drawn. Default is the entire contents, i.e. the result of $path bbox all. Options *-x*, *-y*, *-width* and *-height* defines an area on the page where to place the contents. Default area starts at origin, stretching over the drawable area of the page. Option *-sticky* defines how to place the contents within the area. The area is always filled in one direction, preserving aspect ratio, unless *-sticky* defines that the other direction should be filled too. Default *-sticky* is *nw*. If option *-bg* is true, a background is drawn in the canvas' background color. Otherwise only objects are drawn. Default is false. Option *-fontmap* gives a dictionary mapping from Tk font names to PDF font names. Option *-textscale* overrides the automatic downsizing made for tk::canvas text items that are deemed too large. If *-textscale* is larger than 1, all text items are reduced in size by that factor. Fonts: If no font mapping is given, fonts for text items are limited to PDF's builtins, i.e. Helvetica, Times and Courier. A guess is made to chose which one to use to get a reasonable display on the page. An element in a font mapping must exactly match the -font option in the text item. The corresponding mapping value is a PDF font family, e.g. one created by **pdf4tcl::createFont**, possibly followed by a size. It is recommended to use named fonts in Tk to control the font mapping in detail. Limitations: Option **-splinesteps** for lines/polygons is not applicable: PDF uses exact cubic Bezier curves (**CanvasBezier**), which are mathematically equivalent to any number of spline steps. The visual result is equal to or better than Tk's screen rendering. *Stipple:* Both offset forms are supported: **x,y** (absolute pixel offset) and **#x,y** (bitmap-relative -- aligns bitmap pixel (x,y) with canvas origin). Empty offset (no adjustment) is handled correctly. Minor visual differences from on-screen rendering may remain due to pattern scaling. *Widget classes supported:* **tk::canvas** (class **Canvas**) -- all standard item types: rectangle, oval, line, polygon, arc, text, image, bitmap, window. **tkpath** (**::tkp::canvas**, class **PathCanvas**) -- tkpath item types: pimage, ptext, pline, polyline, ppolygon, prect, circle, ellipse, path, group. Handled via **itempdf** delegation (C-level). **tko::path** (class **tko::path**) -- tko::path item types: image, text, line, polyline, polygon, rect, circle, ellipse, path, group, window. Handled via **itempdf** delegation. *Window items (tk::canvas):* The embedded widget must be visible on-screen when the canvas is exported. Package **Img** with **-format window** support is required to capture the widget as a raster image. If **Img** is not available or the widget is unmapped, a solid black rectangle is drawn in its place. *Window items (tko::path):* The item is silently skipped -- no crash, no error message (fix in 0.9.4.24, BUG-C1). All other items on the same **tko::path** are exported correctly. Raster capture of embedded widgets is not supported for **tko::path**.

**objectName metadata ?option value...?**
: This method sets metadata fields for this document. Supported field options are *-author*, *-creator*, *-keywords*, *-producer*, *-subject*, *-title*, *-creationdate* and *-moddate*. Multiple keywords should be passed as a comma-separated string, e.g. *-keywords "tcl,pdf,document"*. For *-creationdate* and *-moddate* a **clock seconds** value is expected. A value of **0** uses the current date and time. Unknown option names cause an error.

**objectName bookmarkAdd ?option value...?**
: Add a bookmark on the current page.

**objectName embedFile filename ?option value...?**
: This method embeds a file into the PDF stream. File data is considered binary. Returns an id that can be used in subsequent calls to **attachFile**.

**objectName attachFile x y width height fid description ?option value...?**
: This method adds a file annotation to the current page. The location of the file annotation is given by the coordinates *x*, *y*, *width*, *height*. The annotation is rendered by default as a paperclip icon, which allows the extraction of the attached file. An *fid* from a previous call to **embedFile** must be set as well as a *description*, which is shown by the PDF viewer upon activating the annotation.

```tcl
set fid [$pdfobject embedFile "data.txt" -contents "This should be stored in the file."]
$pdfobject attachFile 0 0 100 100 $fid "This is the description"
```

**-contents data**
: Raw binary content of the file. If omitted, the file is read from disk using *filename* as path.

**-mimetype type**
: MIME type string, e.g. **application/xml**. Written as **/Subtype** in the EmbeddedFile stream dictionary.

**-description text**
: Human-readable description stored as **/Desc** in the FileSpec dictionary.

**-afrelationship rel**
: PDF/A-3 **/AFRelationship** entry. Valid values are **Alternative**, **Data**, **Source**, **Supplement**, and **Unspecified**.

**objectName addEmbeddedFile filename ?option value...?**
: This method embeds a file silently into the PDF document via the Catalog **/Names** / **/EmbeddedFiles** NameTree (ISO 32000 SS7.11.4). No visible annotation is created on any page. This is the correct mechanism for electronic invoice attachments (ZUGFeRD, Factur-X) and other document-level file attachments. *filename* is used as the display name stored in the PDF (**/F** and **/UF** entries of the FileSpec dictionary). When **-contents** is not given, the file is read from disk using *filename* as path; in that case the basename is used as the PDF name. *PDF/A-1 restriction:* embedded files are forbidden by ISO 19005-1 SS6.1.7. Calling this method when **-pdfa** is set to **1b** raises an error. PDF/A-2b and PDF/A-3b allow embedded files.

```tcl
# ZUGFeRD / Factur-X pattern
set xmlData [read [open "factur-x.xml" rb]]
$pdfobject addEmbeddedFile "factur-x.xml"  -contents $xmlData  -mimetype "application/xml"  -description "Factur-X invoice"  -afrelationship Alternative
```

**-borderwidth n**
: Width of the annotation border in points. Use **0** for an invisible border (default: **0**).

**-bordercolor color**
: Color of the annotation border. Accepts any color format supported by pdf4tcl (default: **{0 0 1}**, blue).

**-borderradius n**
: Corner radius of the annotation border in points (default: **0**).

**-borderdash on off**
: Dash pattern of the border as a list of two numbers *on* and *off* in points. An empty list produces a solid border (default: ).

**-highlight mode**
: Visual effect when the user clicks the annotation. Valid values are **N** (None), **I** (Invert, default), **O** (Outline), and **P** (Push).

**objectName hyperlinkAdd x y width height url ?option value...?**
: This method adds a URI hyperlink annotation to the current page. The clickable area is defined by *x*, *y*, *width* and *height*. The *url* argument must be a valid URI string (e.g. **https://www****.example****.com**). By default the annotation has no visible border.

```tcl
# Invisible link
$pdfobject hyperlinkAdd 50 100 200 20 "https://sourceforge.net/p/pdf4tcl"
# Link with visible blue border
$pdfobject hyperlinkAdd 50 130 200 20 "https://github.com/gregnix/pdf4tcl"  -borderwidth 1 -bordercolor {0 0 1}
# Dashed border, rounded corners
$pdfobject hyperlinkAdd 50 160 200 20 "https://www.tcl.tk"  -borderwidth 1 -bordercolor {0 0.6 0} -borderdash {5 3} -borderradius 4
```

**-content string**
: Note text shown in the popup.

**-author string**
: Author name shown in the popup header.

**-subject string**
: Subject line.

**-icon name**
: Icon type: **Note** (default), **Comment**, **Key**, **Help**, **NewParagraph**, **Paragraph**, **Insert**.

**-color color**
: Background color (default: **1 1 0** = yellow).

**-open bool**
: Show popup open by default (default: **0**).

**-fontsize n**
: Font size in points (default: **10**).

**-color color**
: Text color (default: **0 0 0**).

**-bgcolor color**
: Background fill color (default: **1 1 0****.8**).

**-borderwidth n**
: Border width in points (default: **1**).

**-align n**
: Text alignment: **0**=left (default), **1**=center, **2**=right.

**-color color**
: Markup color. Defaults: yellow for Highlight, black for Underline, red for StrikeOut.

**-content string**
: Optional comment text.

**-author string**
: Author name.

**-name name**
: Predefined stamp name (default: **Draft**). Valid names: **Approved**, **Confidential**, **Draft**, **Experimental**, **Expired**, **Final**, **ForPublicRelease**, **NotApproved**, **NotForPublicRelease**, **Sold**, **TopSecret**.

**-color color**
: Stamp color (default: **1 0 0**).

**-content string**
: Optional popup content.

**-color color**
: Line color (default: **0 0 0**).

**-width n**
: Line width in points (default: **1**).

**-startend list**
: Two-element list of arrowhead styles for start and end of the line (default: **None None**). Valid styles: **None**, **OpenArrow**, **ClosedArrow**, **Square**, **Circle**, **Diamond**, **Butt**, **Slash**.

**-content string**
: Optional popup content.

**-pagelayout layout**
: Set the page layout on open. Valid values: **SinglePage**, **OneColumn**, **TwoColumnLeft**, **TwoColumnRight**, **TwoPageLeft**, **TwoPageRight**.

**-pagemode mode**
: Set the page mode on open. Valid values: **UseNone**, **UseOutlines**, **UseThumbs**, **FullScreen**, **UseOC**, **UseAttachments**.

**-hidetoolbar bool**
: Hide the viewer toolbar when the document is open (default false).

**-hidemenubar bool**
: Hide the viewer menu bar (default false).

**-hidewindowui bool**
: Hide viewer interface elements (default false).

**-fitwindow bool**
: Resize the document window to fit the first page (default false).

**-centerwindow bool**
: Center the document window on the screen (default false).

**-displaydoctitle bool**
: Display the document title from metadata instead of the file name (default false).

**-nonfullscreenpagemode mode**
: Page mode when leaving full-screen mode. Valid values: **UseNone**, **UseOutlines**, **UseThumbs**, **UseOC**.

**-direction dir**
: Reading order. Valid values: **L2R** (default) or **R2L** (right-to-left).

**-printscaling scale**
: Default print scaling. Valid values: **AppDefault** or **None**.

**-duplex mode**
: Paper handling when printing. Valid values: **None**, **Simplex**, **DuplexFlipShortEdge**, **DuplexFlipLongEdge**.

**objectName addAnnotNote x y width height ?option value...?**
: Add a **/Text** sticky note annotation (0.9.4.23+). The annotation appears as a small icon; clicking it opens a popup window. *Note:* Popup behaviour varies between PDF viewers -- some keep the popup open, others do not show a close button. For consistent cross-viewer display use **addAnnotFreeText** instead.

**objectName addAnnotFreeText x y width height text ?option value...?**
: Add a **/FreeText** annotation -- a visible text box directly on the page (0.9.4.23+). No click required; always visible in all viewers.

**objectName**
: **addAnnotHighlight** *x* *y* *width* *height* ?*option value*...?

**objectName**
: **addAnnotUnderline** *x* *y* *width* *height* ?*option value*...?

**objectName addAnnotStrikeOut x y width height ?option value...?**
: Text markup annotations (0.9.4.23+). The rectangle defines the text area to mark.

**objectName addAnnotStamp x y width height ?option value...?**
: Add a **/Stamp** annotation -- a rubber stamp visible on the page (0.9.4.23+).

**objectName addAnnotLine x1 y1 x2 y2 ?option value...?**
: Add a **/Line** annotation with optional arrowheads (0.9.4.23+).

**objectName viewerPreferences ?option value...?**
: Set viewer preference flags in the PDF catalog. These control how a PDF viewer displays the document when it is opened. Options can be combined freely.

```tcl
$pdfobject viewerPreferences -pagemode FullScreen -hidetoolbar 1
$pdfobject viewerPreferences -pagelayout TwoColumnLeft -direction L2R
```

**-style style**
: Numbering style. Valid values: **D** (decimal: 1 2 3), **r** (roman lowercase: i ii iii), **R** (roman uppercase: I II III), **a** (alpha lowercase: a b c), **A** (alpha uppercase: A B C), or empty string (prefix only, no number).

**-prefix string**
: Label prefix prepended to each page number (e.g. **App-** produces App-1, App-2...).

**-start integer**
: Start value for the numbering in this range. Must be a positive integer. Default is 1.

**objectName pageLabel pageIndex ?option value...?**
: Define a page label range starting at the given zero-based *pageIndex*. PDF page labels allow viewers to display custom page numbers (e.g. roman numerals for a preface, decimal numbers for the main body). Multiple ranges can be defined.

```tcl
# Preface pages: i, ii, iii...
$pdfobject pageLabel 0 -style r
# Main body pages: 1, 2, 3...
$pdfobject pageLabel 4 -style D -start 1
# Appendix with prefix
$pdfobject pageLabel 20 -style A -prefix "App-"
```

### OBJECT METHODS, TEXT

**-font fontName**
: Use *fontName* instead of the current font.

**-size fontSize**
: Use *fontSize* instead of the current font size.

**-internal bool**
: Return width in points instead of current unit.

**objectName setFont size ?fontname?**
: This method sets the font used by text drawing routines. If *fontname* is not provided, the previously set *fontname* is kept.

**objectName getStringWidth str ?options?**
: This method returns the width of *str* in the current unit. Options (0.9.4.23+):

- Without options the method behaves as before. If no font has been set and **-font** is not given, an error is raised.
**-align**
: *left|right|center* (default left)

**-angle**
: *degrees* (default 0) - Orient string at the specified angle.

**-xangle**
: *degrees* (default 0)

**-yangle**
: *degrees* (default 0) - Apply x or y shear to the text.

**-x**
: *x* (default 0)

**-y**
: *y* (default 0) - Allow the text to be positioned without setTextPosition.

**-bg**
: *bool|color* (default 0)

**-background**
: *bool|color*

**-fill bool|color**
: Any of **-bg**, **-background** or **-fill** cause the text to be drawn on a filled background. If a boolean true is given, the background color is taken from **setBgColor**. Alternatively, a color value in any format accepted by pdf4tcl can be given directly (e.g. **{1 0 0}** for red). All three options are aliases.

**-align left|right|center|justify**
: Specifies the justification. If not given, the text is left justified.

**-linesvar var**
: Gives the name of a variable which will be set to the number of lines written.

**-newyvar var**
: Gives the name of a variable which will be set to the Y position after the last rendered line, in the current unit (0.9.4.23+). Allows the caller to continue drawing below the text box:

```tcl
$pdf drawTextBox $x $y $w $h $text -newyvar nextY
$pdf line $x $nextY [expr {$x+$w}] $nextY
```

**-dryrun bool**
: If true, no changes will be made to the PDF document. The return value and **-linesvar** gives information of what would happen with the given text.

**ascend**
: Top of typical glyph, displacement from anchor point. Typically a positive number since it is above the anchor point.

**descend**
: Bottom of typical glyph, displacement from anchor point. Typically a negative number since it is below the anchor point.

**fixed**
: Boolean which is true if this is a fixed width font.

**bboxb**
: Bottom of Bounding Box, displacement from anchor point. Typically a negative number since it is below the anchor point.

**bboxt**
: Top of Bounding Box, displacement from anchor point. Typically a positive number since it is above the anchor point.

**height**
: Height of font's Bounding Box.

**objectName getCharWidth char**
: This method returns the width of a character under the current font.

**objectName inPage**
: Returns **1** if a page is currently open, **0** otherwise. Useful for library code managing page state without accessing internals.

**objectName currentPage**
: Returns the current page number (1-based). Returns **0** before the first **startPage** call.

**objectName pageCount**
: Returns the number of completed pages (**endPage** called). A currently open page is not counted until **endPage**.

**objectName setTextPosition x y**
: Set coordinate for next text command.

**objectName moveTextPosition dx dy**
: Increment position by *dx*, *dy* for the next text command.

**objectName getTextPosition**
: This method returns the current text coordinate.

**objectName newLine ?spacing?**
: Moves text coordinate down and resets x to where the latest **setTextPosition** was. The number of lines to move down can be set by *spacing*. This may be any real number, including negative, and defaults to the value set by **setLineSpacing**.

**objectName setLineSpacing spacing**
: Set the default line spacing used be e.g. **newLine**. Initially the spacing is 1.

**objectName getLineSpacing**
: Get the current default line spacing factor (a dimensionless multiplier).

**objectName getLineHeight**
: Get the actual vertical distance advanced by **newLine** in the document's current unit. This is *font_size* times the line spacing factor. Use this to calculate bounding boxes around multi-line text blocks. Requires a font to be set.

**objectName text str ?option value...?**
: Draw text at the position defined by setTextPosition using the font defined by setFont.

**objectName drawTextBox x y width height str ?option value...?**
: Draw the text string *str* wrapping at blanks and tabs so that it fits within the box defined by *x*, *y*, *width* and *height*. An embedded newline in *str* causes a new line in the output. If *str* is too long to fit in the specified box, it is truncated and the unused remainder is returned.

**objectName getFontMetric metric**
: Get information about current font. The available *metric*s are **ascend**, **descend**, **fixed**, **bboxb**, **bboxt** and **height**.

### OBJECT METHODS, IMAGES

A limited set of image formats are directly understood by pdf4tcl, currently some JPEG, some PNG, and some TIFF formats. To use unsupported formats, use Tk and the Img package to load and dump images to raw format which can be fed to **putRawImage** and **addRawImage**.

**-angle degrees**
: Rotate image *degrees* counterclockwise around the anchor point. Default is 0.

**-anchor anchor**
: Set the anchor point (nw, n, ne etc.) of the image. Coordinates *x* and *y* places the anchor point, and any rotation is around the anchor point. Default is nw if **-orient** is true, otherwise se.

**-height height**
: Set the height of the image. Default height is one point per pixel. If *width* is set but not *height*, the height is selected to preserve the aspect ratio of the image.

**-width width**
: Set the width of the image. Default width is one point per pixel. If *height* is set but not *width*, the width is selected to preserve the aspect ratio of the image.

**-compress boolean**
: Raw data will be zlib compressed if this option is set to true. Default value is the document's **-compress** setting.

**objectName putImage id x y ?option value...?**
: Put an image on the current page. The image must have been added previously by **addImage** or **addRawImage**. The *id* is the one returned from the add command.

**objectName putRawImage data x y ?option value...?**
: Put an image on the current page. Works like **putImage** except that the raw image data is given directly.

```tcl
image create photo img1 -file image.gif
  set imgdata [img1 data]
  mypdf putRawImage $imgdata 60 20 -height 40
```

**-id id**
: Explicitly select an id for the image. The *id* must be unique within the document.

**-type name**
: Override automatic type detection based on file extension. Valid values are **png**, **jpg** (or **jpeg**), **tif** (or **tiff**). Set the image type. This can usually be deduced from the file name, this option helps when that is not possible. This can be either "png", "jpeg", or "tiff".

**-compress boolean**
: Raw data will be zlib compressed if this option is set to true. Default value is the document's **-compress** setting.

**objectName addImage filename ?option value...?**
: Add an image to the document. Returns an id that can be used in subsequent calls to **putImage**. Supported formats are PNG, JPEG and TIFF.

**objectName addRawImage data ?option value...?**
: Add an image to the document. Works like **addImage** except that the raw image data is given directly.

```tcl
image create photo img1 -file image.gif
  set imgdata [img1 data]
  set id [mypdf addRawImage $imgdata]
  mypdf putImage $id 20 60 -width 100
```

**objectName getImageHeight id**
: This method returns the height of the image identified by *id*.

**objectName getImageSize id**
: This method returns the size of the image identified by *id*. The return value is a list of width and height.

**objectName getImageWidth id**
: This method returns the width of the image identified by *id*.

### OBJECT METHODS, COLORS

Colors can be expressed in various formats. First, as a three element list of values in the range 0.0 to 1.0. Second, in the format #XXXXXX where the Xes are two hexadecimal digits per color value. Third, if Tk is available, any color accepted by winfo rgb is accepted.

**-extend {bool bool}**
: Whether to extend the gradient beyond the start (*bool1*) and end (*bool2*) coordinates. Default: **1 1**.

**objectName setBgColor red green blue**
: Sets the background color for text operations where -bg is true.

**objectName setBgColor c m y k**
: Alternative calling form, to set color in CMYK color space.

**objectName setFillColor red green blue**
: Sets the fill color for graphics operations, and the foreground color for text operations.

**objectName setFillColor c m y k**
: Alternative calling form, to set color in CMYK color space.

**objectName setStrokeColor red green blue**
: Sets the stroke color for graphics operations.

**objectName setStrokeColor c m y k**
: Alternative calling form, to set color in CMYK color space.

**objectName setAlpha value**
: Sets the opacity for both fill and stroke operations. *value* must be a number between 0.0 (fully transparent) and 1.0 (fully opaque). Values outside this range are clamped. The default is 1.0. Internally this creates a PDF ExtGState object with **/ca** (fill alpha) and **/CA** (stroke alpha). Identical alpha values are cached and reuse the same ExtGState object. The alpha state is saved and restored by **gsave** / **grestore**.

**objectName setAlpha value -fill**
: Sets fill opacity only, leaving stroke opacity unchanged.

**objectName setAlpha value -stroke**
: Sets stroke opacity only, leaving fill opacity unchanged.

**objectName setAlpha fillValue strokeValue**
: Sets fill and stroke opacity independently in a single call.

**objectName getAlpha**
: Returns the current opacity values as a two-element list *fillAlpha strokeAlpha*.

**objectName setBlendMode mode**
: Sets the PDF blend mode for subsequent graphics and text operations. *mode* must be one of: **Normal**, **Multiply**, **Screen**, **Overlay**, **Darken**, **Lighten**, **ColorDodge**, **ColorBurn**, **HardLight**, **SoftLight**, **Difference**, **Exclusion**, **Hue**, **Saturation**, **Color**, **Luminosity**. Use **Normal** to reset to the default. Internally this creates a PDF ExtGState object combining **/BM** with the current alpha values; objects are cached per mode and alpha combination. The PDF version is raised to 1.4 automatically.

**objectName getBlendMode**
: Returns the currently active blend mode string (default: **Normal**).

**objectName linearGradient x1 y1 x2 y2 color1 color2 ?options?**
: Paints a linear (axial) gradient from (*x1*,*y1*) to (*x2*,*y2*). *color1* is the colour at the start point, *color2* at the end point. Both colours can be specified as an RGB triple *{r g b}* (values 0.0–1.0), a named colour (**red**, **green**, **blue**, **white**, **black**, **yellow**, **cyan**, **magenta**) or a CSS hex string *#rrggbb*. Options: The gradient is painted using PDF ShadingType 2 + FunctionType 2 and registered in the page **/Shading** resource dictionary. Clip the drawing area first (e.g. **clip** or **gsave**/**grestore**) to constrain the fill.

**objectName radialGradient cx1 cy1 r1 cx2 cy2 r2 color1 color2 ?options?**
: Paints a radial gradient between two circles. The first circle is centred at (*cx1*,*cy1*) with radius *r1*; the second at (*cx2*,*cy2*) with radius *r2*. *color1* applies to the first circle, *color2* to the second. Colour formats are the same as for **linearGradient**. Options: same **-extend** option as **linearGradient**. Uses PDF ShadingType 3 + FunctionType 2.

### OBJECT METHODS, GRAPHICS

**-filled bool   (default 0)**
: Fill the polygon.

**-stroke bool   (default 1)**
: Draw an outline of the polygon.

**-closed bool   (default 1)**
: Close polygon.

**-filled bool   (default 0)**
: Fill the circle.

**-stroke bool   (default 1)**
: Draw an outline of the circle.

**-filled bool   (default 0)**
: Fill the oval.

**-stroke bool   (default 1)**
: Draw an outline of the oval.

**-filled bool   (default 0)**
: Fill the arc.

**-stroke bool   (default 1)**
: Draw an outline of the arc.

**-style arc|pieslice|chord   (default arc)**
: Defines the style of the arc. An *arc* draws the perimeter of the arc and is never filled. A *pieslice* closes the arc with lines to the center of the oval. A *chord* closes the arc directly.

**-filled bool   (default 0)**
: Fill the rectangle.

**-stroke bool   (default 1)**
: Draw an outline of the rectangle.

**-radius value   (default 5)**
: Corner radius in the document's current unit. Automatically clamped to half the shorter side.

**-filled bool   (default 0)**
: Fill the rectangle.

**-stroke bool   (default 1)**
: Draw an outline of the rectangle.

**objectName setLineWidth width**
: Sets the width for subsequent line drawing. Line width must be a non-negative number.

**objectName setLineDash ?on off...? ?offset?**
: Sets the dash pattern for subsequent line drawing. Offset and any elements in the dash pattern must be non-negative numbers. *on off* is a series of pairs of numbers which define a dash pattern. The 1st, 3rd ... numbers give units to paint, the 2nd, 4th ... numbers specify unpainted gaps. When all numbers have been used, the pattern is re-started from the beginning. An optional last argument sets the dash offset, which defaults to 0. Calling **setLineDash** with no arguments resets the dash pattern to a solid line.

**objectName setLineStyle width args**
: Sets the width and dash pattern for subsequent line drawing. Line width and any elements in the dash pattern must be non-negative numbers. *args* is a series of numbers (not a tcl list) which define a dash pattern. The 1st, 3rd ... numbers give units to paint, the 2nd, 4th ... numbers specify unpainted gaps. When all numbers have been used, the pattern is re-started from the beginning. This method do not support offsetting the pattern, see **setLineDash** for a more complete method.

**objectName line x1 y1 x2 y2**
: Draws a line from *x1,* *y1* to *x2,* *y2*

**objectName curve x1 y1 x2 y2 x3 y3 ?x4 y4?**
: If *x4,* *y4* are present, draws a cubic bezier from *x1,* *y1* to *x4,* *y4* with control points *x2,* *y2* and *x3,* *y3*. Otherwise draws a quadratic bezier from *x1,* *y1* to *x3,* *y3*, with control point *x2,* *y2*

**objectName polygon ?x y...? ?option value...?**
: Draw a polygon. There must be at least 3 points. The polygon is closed back to the first coordinate unless *-closed* is false in which case a poly-line is drawn.

**objectName circle x y radius ?option value...?**
: Draw a circle at the given center coordinates.

**objectName oval x y radiusx radiusy ?option value...?**
: Draw an oval at the given center coordinates.

**objectName arc x y radiusx radiusy phi extend ?option value...?**
: Draw an arc, following the given oval. The arc starts at angle *phi*, given in degrees starting in the "east" direction, counting counter clockwise. The arc extends *extend* degrees.

**objectName arrow x1 y1 x2 y2 size ?angle?**
: Draw an arrow. Default *angle* is 20 degrees.

**objectName rectangle x y width height ?option value...?**
: Draw a rectangle.

**objectName roundedRect x y width height ?option value...?**
: Draw a rectangle with rounded corners (Bezier approximation).

**objectName clip x y width height**
: Create a clip region. To cancel a clip region you must restore a graphic context that was saved before.

**objectName gsave**
: Save graphic/text context. (I.e. insert a raw PDF "q" command). This saves the settings of at least these calls: **clip**, **setBgColor**, **setFillColor**, **setStrokeColor**, **setAlpha**, **setLineStyle**, **setLineWidth**, **setLineDash**, **setFont**, and **setLineSpacing**. Each call to **gsave** should be followed by a later call to **grestore** in the same page.

**objectName grestore**
: Restore graphic/text context. (I.e. insert a raw PDF "Q" command). Restores all saved state including the raw-coordinate mode set by **translate**, **rotate**, **scale**, or **transform**. After **grestore**, drawing commands return to user-coordinate mode (orient + margin active).

**objectName transform a b c d e f**
: Apply a PDF transformation matrix (**cm** operator) to the current graphics state. Use with **gsave**/**grestore**. After this call, drawing commands (**line**, **rectangle** etc.) work in raw-coordinate mode: y points upward, no margin, no orient flip. Text commands (**text**) use absolute **Tm** positioning and are *not* affected by transformation matrices.

**objectName translate tx ty**
: Shift the coordinate origin by *tx*/*ty* in the current unit, respecting orient and margins. Equivalent to **transform** **1 0 0 1 tx ty** (after coordinate conversion). *Raw-coordinate note:* after **translate**, drawing commands work in raw PDF space (y upward). A **rectangle** **0 0 w h** draws *h* points *upward* from the new origin. To place the bottom edge of a rectangle at user-y *y*, pass **[expr {$y + $h}]** as the *ty* argument:

```tcl
$pdf gsave
$pdf translate $x [expr {$y + $h}]  ;# bottom edge at user-y
$pdf rectangle 0 0 $w $h
$pdf grestore
```

**objectName rotate degrees**
: Rotate the coordinate system clockwise by *degrees*. Typical use: **translate** to the pivot point, then **rotate**. Like **translate**, switches to raw-coordinate mode.

**objectName scale sx sy**
: Scale the coordinate system (**1****.0** = unchanged). Like **translate**, switches to raw-coordinate mode.

**objectName getPageSize**
: Return the full page dimensions as **{width height}** in the current unit (set via **-unit** at creation time). For A4 with **-unit mm**: approximately **210****.0 297****.0**. For A4 with **-unit p**: approximately **595****.0 842****.0** (pdf4tcl rounds MediaBox to integer points). Complements **getDrawableArea** which excludes margins.

**objectName addEmbeddedFile filename ?options?**
: Embed a file in the PDF. When **-pdfa 3b** is active the FileSpec OID is automatically added to the document-level **/AF** array in the Catalog (ISO 19005-3 SS6.2.11.4). Options: **-contents**, **-mimetype**, **-description**, **-afrelationship** (Alternative|Data|Source|Supplement|Unspecified). *Note:* Embedded files are forbidden in PDF/A-1 (ISO 19005-1 SS6.1.7).

**objectName addLayer name ?-visible bool?**
: Add an Optional Content Group (OCG / layer) to the document. Returns a layer ID for use with **beginLayer**. *name* is the visible label shown in the viewer's layer panel. **-visible** controls default visibility (1 = shown, 0 = hidden, default: 1). Use cases: debug grids (**-visible 0**), letterhead variants, watermarks (**-visible 0**). *Note:* **addLayer** must be called before **finish**. All layers are shared across all pages of the document.

**objectName beginLayer layerId**
: Open an Optional Content Group block. All drawing commands until **endLayer** belong to this layer. *layerId* is the OID returned by **addLayer**. Inserts a **BDC** operator into the content stream.

**objectName endLayer**
: Close the current Optional Content Group block. Inserts an **EMC** operator into the content stream.

```tcl
set lGrid [$pdf addLayer "Debug-Raster" -visible 0]
set lKopf [$pdf addLayer "Briefkopf"   -visible 1]
$pdf beginLayer $lGrid
  $pdf setStrokeColor 0.9 0.9 0.9
  for {set x 0} {$x <= 595} {incr x 50} { $pdf line $x 0 $x 842 }
$pdf endLayer
$pdf beginLayer $lKopf
  $pdf text "Musterfirma GmbH" -x 40 -y 28
$pdf endLayer
```

**objectName**
: **_WriteXrefTable** *idHash* *encdict_oid* *metadata_oid*

**objectName _WriteXrefStream idHash encdict_oid metadata_oid**
: Internal methods for writing the cross-reference section. **_WriteXrefTable** writes the classic text-based xref table and trailer dict. **_WriteXrefStream** writes a binary XRef stream object (PDF 1.5+, required for PDF/A-2b+). The XRef stream object contains all trailer entries (**/Root**, **/Info**, **/ID**) eliminating the need for a separate trailer dictionary. Selection is automatic: **-pdfa 2b** uses **_WriteXrefStream**, all other modes use **_WriteXrefTable**.

### OBJECT CONFIGURATION

All pdf4tcl objects understand the options from **PAGE CONFIGURATION**, which defines default page settings when used with a pdf4tcl object. The objects also understand the following configuration options:

- An XMP metadata stream with the pdfaid identification schema (*pdfaid:part* and *pdfaid:conformance*).
- An OutputIntent dictionary with an sRGB ICC profile (**/GTS_PDFA1**).
- Suppresses **/Group /S /Transparency** on all pages (required for PDF/A-1).

**-cmyk boolean**
: If true, pdf4tcl will try to generate the document in CMYK color space. See **::pdf4tcl::rgb2Cmyk** for a way to control color translation. Default value is false. This option can only be set at object creation.

**-compress boolean**
: Pages will be zlib compressed if this option is set to true. Default value is true. This option can only be set at object creation.

**-file filename**
: Continuously write pdf to *filename* instead of storing it in memory. This option can only be set at object creation.

**-unit defaultunit**
: Defines default unit for coordinates and distances. Any value given without a unit is interpreted using this unit. See **UNITS** for valid units. Default value is "p" as in points. This option can only be set at object creation.

**-pdfa level**
: Enables PDF/A conformance for the document. Valid values are (none, default), **1b** (PDF/A-1b, ISO\u00a019005-1) and **2b** (PDF/A-2b, ISO\u00a019005-2). When set to **1b** or **2b**, pdf4tcl automatically embeds: Note: Standard Type\u00a01 fonts (Helvetica, Times, Courier) are not embedded. For full PDF/A conformance, use CID fonts created with **::pdf4tcl::createFontSpecCID**. Default value is . This option can only be set at object creation.

**-pdfa-icc path**
: Explicit path to the sRGB ICC profile file used for the OutputIntent when **-pdfa** is **1b** or **2b**. If not specified, pdf4tcl searches for the profile in standard system locations (e.g. "*/usr/share/color/icc/ghostscript/srgb**.icc*"). This option can only be set at object creation.

**-userpassword string**
: Set a user (open) password for the document. When set, the document cannot be opened without this password. The encryption level is controlled by **-encversion**: AES-128 (default, V=4/R=4) or AES-256 (V=5/R=6). Note: **-userpassword** and **-pdfa** cannot be combined -- PDF/A forbids encryption (ISO 19005). This option can only be set at object creation.

**-ownerpassword string**
: Set an owner password for the document. The owner password grants full access regardless of user-password restrictions. When only **-ownerpassword** is set (no **-userpassword**), the document opens without a password but is protected from modification. This option can only be set at object creation.

**-encversion integer**
: Set the encryption version. Must be **4** (AES-128, default) or **5** (AES-256). **4**: AES-128, V=4/R=4, PDF 1.5+. Pure Tcl, no external programs. **5**: AES-256, V=5/R=6, PDF 2.0. SHA-384/SHA-512 is selected automatically from three backends in priority order: **tcl-sha** (C extension, fastest, optional), **openssl** (if in PATH), or a pure-Tcl fallback (always available, approx. 24 seconds per document). No external program is required. This option can only be set at object creation.

**-permissions value**
: Set the access rights for users of an encrypted document. Only meaningful in combination with **-userpassword**. Accepted values: **all** (default, /P=-196), **none**, **readonly** (print only), a list of flags (**print**, **hq-print**, **modify**, **copy**, **annotate**, **fill-forms**, **accessibility**, **assemble**), or a direct integer /P value. Note: permissions are enforced by conforming viewers only. The owner password always grants full access. This option can only be set at object creation.

### PAGE CONFIGURATION

**-paper name**
: The argument of this option defines the paper size. The paper size may be a string like "a4", where valid values are available through **::pdf4tcl::getPaperSizeList**. Supported series include ISO A (a0-a10), ISO B (b0-b10), ISO C (c0-c10), and the oversize formats **4a0** and **2a0**. North American sizes (**letter**, **legal**, **executive**) are also supported. Paper size may also be a two element list specifying width and height. The default value of this option is "a4".

**-landscape boolean**
: If true, paper width and height are switched. The default value of this option is false.

**-orient boolean**
: This sets the orientation of the y axis of the coordinate system. With **-orient** false, origin is in the bottom left corner. With **-orient** true, origin is in the top left corner. The default value of this option is true.

**-margin values**
: The margin is a one, two or four element list of margins. For one element, it specifies all margins. Two elements specify left/right and top/bottom. Four elements specify left, right, top and bottom. The default value of this option is zero.

**-rotate angle**
: This value defines a rotation angle for the display of the page. Allowed values are multiples of 90. The default value of this option is zero.

## EXAMPLES

```tcl
pdf4tcl::new mypdf -paper a3
  mypdf startPage
  mypdf setFont 12 Courier
  mypdf text "Hejsan" -x 50 -y 50
  mypdf write -file mypdf.pdf
  mypdf destroy
```

### UNIT CONVERSION PROCS

The following procs convert common units to PDF points (1 pt = 1/72 inch). They can be used directly in any coordinate or distance argument.

**pdf4tcl::mm value**
: Convert millimetres to points.

**pdf4tcl::cm value**
: Convert centimetres to points.

**pdf4tcl::in value**
: Convert inches to points.

**pdf4tcl::pt value**
: Identity conversion (returns the value as a floating-point number). Example:

```tcl
$pdf text "Hello" -x [pdf4tcl::mm 20] -y [pdf4tcl::mm 267]
$pdf roundedRect [pdf4tcl::mm 20] [pdf4tcl::mm 50]                  [pdf4tcl::mm 80] [pdf4tcl::mm 30]                  -radius [pdf4tcl::mm 5] -filled 1
```

## PACKAGE VARIABLES

**::pdf4tcl::warnings** A list of non-fatal compliance warnings accumulated during PDF generation. Currently populated by **setAlpha** when called with a value less than 1.0 under **-pdfa 1b** (transparency forbidden by ISO 19005-1 SS6.1.3).

```tcl
set ::pdf4tcl::warnings {}
set pdf [pdf4tcl::new %AUTO% -pdfa 1b]
$pdf startPage
$pdf setAlpha 0.5      ;# appends warning -- no exception raised
$pdf endPage
$pdf destroy
foreach w $::pdf4tcl::warnings { puts "WARNING: $w" }
```

Reset before each document with **set ::pdf4tcl::warnings {}**. The PDF is generated regardless of any warnings in this list. **::pdf4tcl::_md5Backend** Set by **_InitMD5Backend** on first use. Values: **tcllib**, **openssl**, **pure-tcl**. Read-only; for diagnostics only.

## CHANGES

### VERSION 0.9.4.25

- (c0-c10), and oversize formats **4a0** and **2a0**. Dimensions rounded to the nearest integer point (ISO 216 / ISO 269). Ported from the AndroWish fork.
- writes PDF output to an already-open Tcl channel (file, socket, memory channel). The channel is not closed by **write**. Ported from the AndroWish fork, contributed by Christian Werner.
- (channel output) and paper-1.1..1.8 (B/C-series dimensions, backward compatibility of a4).
- paper series (4 pages).
- **-chan** use cases (file channel, memory channel, stdout).

### VERSION 0.9.4.24

- **$path coords $id** returns an empty list. This happened for **window** items, **group** items, and items with **-matrix** set. Added length guard: if coords has fewer than 2 elements, the item is silently skipped. Symptom was *can't read "x1": no such variable*.
- canvas), canvas-4.2 (tko::path window item), canvas-4.3 (version check).

### VERSION 0.9.4.23

- keyword arguments **-font** and **-size** (0.9.4.23+). Text width can now be measured without a prior **setFont** call. CIDFont metrics are supported. Legacy positional call unchanged.
- page is currently open, **0** otherwise.
- page number (1-based, **0** before first **startPage**). **pageCount** added -- returns the number of completed pages.
- option. The named variable receives the Y position after the last rendered line in the current unit. Allows flowing text without manual recalculation.
- **addAnnotNote**, **addAnnotFreeText**, **addAnnotHighlight**, **addAnnotUnderline**, **addAnnotStrikeOut**, **addAnnotStamp**, **addAnnotLine**.
- Exports form field data from a filled PDF as FDF (ISO 32000 SS12.7.7) or XFDF (SS12.7.8). Returns the number of exported fields.
- PDF/A-3b allows embedded files with associated file relationships.
- for the document-level **/AF** array when **-pdfa 3b** is active. The **/AF** array in the Catalog associates embedded files with the document as a whole (ISO 19005-3 SS6.2.11.4).
- **/AS** array added to the OCG **/D** dictionary when **-pdfa 2b** or **-pdfa 3b** is active (ISO 19005-2 SS6.2.10). Defines layer state for Print and View events. Standard PDFs and PDF/A-1b are not affected.
- annotation methods (**addAnnotNote**, **addAnnotFreeText**, **addAnnotHighlight**, **addAnnotUnderline**, **addAnnotStrikeOut**, **addAnnotStamp**, **addAnnotLine**).
- **-pdfa 3b** validation (3), **/AF** array (4), **/AS** array (5), **getStringWidth** with **-font**/**-size** (3), **inPage** / **currentPage** / **pageCount** (5), **drawTextBox** **-newyvar** (2), **::pdf4tcl::exportForms** (5).

### VERSION 0.9.4.22

- (**_WriteXrefStream**) instead of a classic xref table. Required by ISO 19005-2 SS6.1.4. PDF/A-1b continues to use the classic table (XRef streams forbidden by ISO 19005-1 SS6.1.3). Classic xref table extracted into **_WriteXrefTable**.
- (ISO 19005-2 SS4.1 requires PDF 1.7 as base format). PDF/A-1b and standard PDFs remain at PDF 1.4.
- under **-pdfa 1b** appends a warning to **::pdf4tcl::warnings** (transparency forbidden by ISO 19005-1 SS6.1.3). No exception is raised -- the PDF is generated regardless.
- Accumulates non-fatal compliance warnings. Check after document creation; reset with **set ::pdf4tcl::warnings {}**.
- **_MD5**, **_MD5Init**, **_MD5Update**, **_MD5Final**, **_MD5PureTcl**). Priority: Tcllib md5 -> openssl -> pure-Tcl implementation (RFC 1321). AES-128 encryption now works on FIPS systems without Tcllib.
- XRef-Stream (7), PDF version (3), setAlpha warning (2), MD5 pure-Tcl (5).
- structure, PDF/A-2b implementation, and 0.9.4.22 fixes. PDF version on page 1 now dynamically reflects actual document version.
- **-pdfa 1b** + **setAlpha** warning mechanism.

### VERSION 0.9.4.21

- **FlateDecode** when **-compress** is active. Previously written as raw uncompressed stream. Saves approximately 2 KB per PDF/A document.
- **beginLayer**, **endLayer** implement Optional Content Groups (OCG / Layers, ISO 32000 SS8.11). Supports debug grids, letterhead variants, watermarks. Layer visibility controlled by **-visible** (default: 1).
- as part of **make test** via a tcltest wrapper.
- ICC compression (5) and OCG/Layer (8).
- 

### VERSION 0.9.4.20

- **rotate**, **scale**, **translate** apply PDF coordinate transformations. Drawing commands work correctly in the transformed system via the new **rawcoords** graphics state flag (saved/restored by **gsave**/**grestore**). **transform**, **rotate**, **scale**, **translate** call **EndTextObj** before emitting the **cm** operator.
- full page dimensions as **{width height}** in the current unit. Complements **getDrawableArea** (which excludes margins).
- the access rights (**/P** value) for encrypted PDFs.
- 
- **translate**, **rotate**, **scale**, **getPageSize**. Added to "*tests/examples**.test*" as **examples-1****.7**.
- **getPageSize**, **transform**, **rotate**, **scale**, **translate**, and **rawcoords** state management.

### VERSION 0.9.4.19

- (**encoding convertto utf-8** before **Pdfout**). Fixes EILSEQ when **metadata** **-title** contains codepoints above U+00FF under Tcl 9. Resolves knownbug cidfont-9.2.
- cidfont-9.2.
- **write**, **_ValidatePdfDate**, **CleanText**, metadata Unicode handling, and **::pdf4tcl::sha2pure** NIST vectors.

### VERSION 0.9.4.18

- Tcl 9 compatibility: pdf4tcl runs under both Tcl 8.6 and Tcl 9.0.
- SHA library path under Tcl 9. SHA output uses hex encoding and **binary decode hex** for binary-safe results on all platforms.
- **_AesEcb** wrap all **aes::aes** calls with **binary format a*** to guarantee bytearrays under Tcl 8.6 and Tcl 9.
- characters one by one using **catch** -- Tcl 9 throws instead of substituting.
- in addition to **-translation binary** to prevent EILSEQ errors under Tcl 9.
- range (below 10^12) -- Tcl 9 accepts arbitrarily large integers in **string is integer**.
- Makefile: **TCLSH ?=** allows override via environment.
- **-encoding binary** (removed in Tcl 9).
- the Tcl version changes ("*.tclver*" fingerprint file).
- 
- **make test** and **make example**.

### VERSION 0.9.4.17

- (**EncryptStringsInBody**, **_PdfLiteralToBytes**) wired into four call sites in "*src/main**.tcl*": FlushObjects, radio group parent, info dictionary, and bookmarks. Fixes AcroForm field corruption in encrypted documents.
- (**::pdf4tcl::sha2pure**, NIST FIPS 180-4 compliant). AES-256 no longer requires any external program.
- SHA backend priority: **tcl-sha** (C extension) > **openssl** (if in PATH) > pure-Tcl fallback (always available).
- Combobox and listbox generate their own appearance streams. **NeedAppearances** is never set; all field types coexist correctly with signature fields.
- New options **-required** and **-label** in **addForm**.

### VERSION 0.9.4.16

- AES-256 encryption (V=5, R=6, PDF 2.0, ISO 32000-2 §7.6.4). New option **-encversion**: **4** (AES-128, default) or **5** (AES-256). SHA-384/512 via openssl subprocess (superseded by pure-Tcl fallback in 0.9.4.17). Algorithm 2.B implemented after pypdf/qpdf reference ("*libqpdf/QPDF_encryption**.cc*").
- Fixed "*src/main**.tcl*": Makefile dependency correct build order.
- Extended "*tests/encrypt**.test*" with 12 AES-256 tests (encrypt-9.1 through encrypt-9.12).

### VERSION 0.9.4.13

- New method **setBlendMode**: sets the PDF blend mode for subsequent graphics operations via ExtGState **/BM**. Supported modes: **Normal**, **Multiply**, **Screen**, **Overlay**, **Darken**, **Lighten**, **ColorDodge**, **ColorBurn**, **HardLight**, **SoftLight**, **Difference**, **Exclusion**, **Hue**, **Saturation**, **Color**, **Luminosity**. Requires PDF 1.4 (version is raised automatically). ExtGState objects are cached per mode + alpha combination.
- New method **getBlendMode**: returns the currently active blend mode (default **Normal**).
- New method **linearGradient**: paints a linear (axial) gradient between two points using PDF ShadingType 2 + FunctionType 2. Options: **-extend** *bool bool* (default **1 1**).
- New method **radialGradient**: paints a radial gradient between two circles using PDF ShadingType 3 + FunctionType 2. Options: **-extend** *bool bool* (default **1 1**).
- New internal helper **_colorToRGB**: accepts an RGB triple *{r g b}*, a named color (**red**, **green**, **blue**, **white**, **black**, **yellow**, **cyan**, **magenta**) or a CSS hex string *#rrggbb*.
- New options **-tooltip** and **-tabindex** in **addForm**: **-tooltip** writes **/TU** (PDF/UA accessible tooltip); **-tabindex** writes **/TI** (tab order index within AcroForm, non-negative integer).
- **endPage** now writes **/Tabs /R** into the page dictionary when annotations are present, enabling correct tab order for screen readers.

### VERSION 0.9.4.12

- New method **roundedRect**: draws a rectangle with rounded corners using Bezier approximation. Options **-radius** (default 5), **-filled**, **-stroke**. Radius is automatically clamped to half the shorter side.
- New namespace procs **pdf4tcl::mm**, **pdf4tcl::cm**, **pdf4tcl::in**, **pdf4tcl::pt**: convert common units to PDF points (1 pt = 1/72 inch). Use directly in coordinate arguments.
- Date validation in **metadata**: new method **_ValidatePdfDate** validates and normalises PDF date strings for **-creationdate** and **-moddate**. Throws **PDF4TCL BADDATE** on invalid format.
- Extended "*0**.9**.4**.x/demo/demo-alpha**.tcl*" with sections demonstrating **roundedRect** and unit conversion procs.
- New test file "*tests/new-0**.9**.4**.12**.test*": 17 tests.

### VERSION 0.9.4.11

- New module "*src/encrypt**.tcl*": AES-128 encryption (V=4, R=4) per PDF 1.6 specification. New options **-userpassword** and **-ownerpassword**. The Encrypt dictionary uses **/CFM** **/AESV2**, **/StmF** **/StdCF**, **/StrF** **/StdCF**. Padding constant corrected to 0x7A (qpdf-compatible).
- Extended **_FindSRGBProfile** with TeX Live path variants for the sRGB ICC profile (glob search for year-variable path components).
- New test file "*tests/encrypt**.test*": 25 tests covering AES-128 encryption, O/U-entry calculation, and Encrypt dictionary structure.

### VERSION 0.9.4.10

- Added **setAlpha**: sets fill and/or stroke opacity (0.0 transparent, 1.0 opaque) via PDF ExtGState (/ca, /CA). Supports single value, **-fill**, **-stroke**, and two-value form for independent fill/stroke control.
- Added **getAlpha**: returns current fill and stroke opacity as a list.
- Alpha state is saved and restored by **gsave** / **grestore**.
- ExtGState objects are cached: identical alpha values reuse one PDF object.
- Added **demo-alpha****.tcl**: demonstrates transparency with overlapping shapes, alpha steps, independent fill/stroke alpha, transparent text, and gsave/grestore.

### VERSION 0.9.4.9

- Added **demo-pdfa****.tcl**: Demonstration of PDF/A-1b and PDF/A-2b features using embedded CIDFont (DejaVuSans). Requires no Ghostscript.
- Added **demo-pdfa-gs****.tcl**: PDF/A conversion workflow via Ghostscript. Produces PDF/A-1b and PDF/A-2b from a pdf4tcl source document.
- Extended **demo-all****.tcl** with page 6 (section 12): PDF/A feature overview, usage example, 1b vs. 2b comparison table, and font embedding requirement.
- Added **SafeQuoteString** tests ("*tests/util**.test*" util-9.1..9.5): covers ASCII passthrough, Latin-1 retention, SMP replacement, PDF special character escaping, and mixed input.

### VERSION 0.9.4.8

- PDF/A-1b and PDF/A-2b support via **-pdfa** option.
- XMP metadata stream with pdfaid identification schema (*pdfaid:part*, *pdfaid:conformance*).
- OutputIntent with sRGB ICC profile (**-pdfa-icc** for explicit path).
- */Group/S/Transparency* suppressed for PDF/A-1 pages.
- Binary comment (4 bytes > 0x7F) in PDF header.
- Fixed */Length* calculation to use UTF-8 byte count.

### VERSION 0.9.4.7

- Assembled "*pdf4tcl**.tcl*", updated examples, manpage and tests.

### VERSION 0.9.4.6

- Added **SafeQuoteString**: strips codepoints > U+00FF before PDF encoding for Tcl 9.0 compatibility (ticket #17).
- Fixed CID *.notdef* width handling.
- Improved **GetCharWidth** fallback for unmappable WinAnsi codepoints.

### VERSION 0.9.4.5

- CIDFont Unicode support: **createFontSpecCID** for full TTF embedding.
- Supports Latin Extended, Greek, Cyrillic, CJK and all BMP/SMP codepoints.
- ToUnicode CMap with UTF-16BE surrogate pairs for SMP characters.

### VERSION 0.9.4.3

- Added **hyperlinkAdd**: URI annotation links with optional border and color (ticket #15).

### VERSION 0.9.4.1

- AcroForm v2.1: extended **addForm** from 2 to 8 field types: *text*, *password*, *checkbutton*, *combobox*, *listbox*, *radiobutton*, *pushbutton*, *signature*. Added **-required**, **-label** and radio group support (ticket #9).

### VERSION 0.9.4.15

- OTF/CFF font support in **pdf4tcl::loadBaseTrueTypeFont**: OpenType fonts with CFF outlines ("*.otf*" files, OTTO magic number **0x4F54544F**) are now accepted without error. Previously these fonts caused *TTF: postscript outlines are not supported*. No CFF parser is required: pdf4tcl embeds the font binary as-is and reads only metadata tables (**name**, **head**, **OS/2**, **post**, **hhea**, **maxp**, **cmap**, **hmtx**). **loca** and **glyf** tables (TTF-only) are skipped for CFF fonts. PDF embedding uses **/CIDFontType0** with **/FontFile3** (**/Subtype /OpenType**) instead of the TTF path (**/CIDFontType2** / **/FontFile2** / **/Length1**). The ToUnicode CMap and all other font objects are identical. A new internal flag **BFA($name,isCFF)** is set to **1** for CFF/OTF fonts and **0** for TrueType fonts.

### VERSION 0.9.4.14

- New method **addEmbeddedFile**: embeds a file silently into the PDF Catalog **/Names** / **/EmbeddedFiles** NameTree (ISO 32000 SS7.11.4). No visible page annotation is created. Options: **-contents** (raw data), **-mimetype**, **-description**, **-afrelationship** (**Alternative** | **Data** | **Source** | **Supplement** | **Unspecified**). Calling this method when **-pdfa** is **1b** raises an error (ISO 19005-1 SS6.1.7). Intended use: ZUGFeRD / Factur-X electronic invoices and other document-level attachments.

## CREDITS

**AndroWish -- write -chan option**
: The **-chan** option for the **write** command was originally developed for *AndroWish* by Christian Werner and was ported to pdf4tcl. AndroWish is licensed under the Tcl/Tk license. See: *https://www**.androwish**.org/*

## SEE ALSO

doctools

## KEYWORDS

document, pdf

## COPYRIGHT

```tcl
Copyright (c) 2007-2016 Peter Spjuth
Copyright (c) 2009 Yaroslav Schekin
Copyright (c) 2024-2026 gregnix (fork 0.9.4.x)
```

