# pdf4tcl

## NAME

pdf4tcl - Pdf document generation

## SYNOPSIS

package require **Tcl 8****.6**

package require **pdf4tcl ?0****.9****.4****.1?**

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

**::pdf4tcl::getFonts**

**::pdf4tcl::rgb2Cmyk** *rgb*

**::pdf4tcl::cmyk2Rgb** *cmyk*

**::pdf4tcl::catPdf** *infile* ?*infile **.**.**.*? *outfile*

**::pdf4tcl::getForms** *infile*

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

*objectName* **write** ?*-file filename*?

*objectName* **addForm** *type* *x* *y* *width* *height* ?*option value*...?

*objectName* **getDrawableArea**

*objectName* **canvas** *path* ?*option value*...?

*objectName* **metadata** ?*option value*...?

*objectName* **bookmarkAdd** ?*option value*...?

*objectName* **embedFile** *filename* ?*option value*...?

*objectName* **attachFile** *x* *y* *width* *height* *fid* *description* ?*option value*...?

*objectName* **setFont** *size* ?*fontname*?

*objectName* **getStringWidth** *str*

*objectName* **getCharWidth** *char*

*objectName* **setTextPosition** *x* *y*

*objectName* **moveTextPosition** *dx* *dy*

*objectName* **getTextPosition**

*objectName* **newLine** ?*spacing*?

*objectName* **setLineSpacing** *spacing*

*objectName* **getLineSpacing**

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

*objectName* **clip** *x* *y* *width* *height*

*objectName* **gsave**

*objectName* **grestore**

## DESCRIPTION

This package provides a container class for generating *pdf* documents.

## COORDINATES

All coordinates and distances can be expressed with or without a unit. See **UNITS** for valid units. When the page is configured with **-orient** set to false, origin is in the bottom left corner. With **-orient** true (the default), origin is in the top left corner. Origin is displaced to account for margins, i.e. if margins are 100, the user coordinate (0,0) corresponds to (100,100) on the paper. Page option **-orient** can also affect the anchor point for things like images.

## UNITS

Any coordinates and distances can be expressed with or without an explicit unit. If no unit is given, the default unit for the document is used. A unit may be one of **mm** (millimeter), **m** (millimeter), **cm** (centimeter), **c** (centimeter), **p** (points) or **i** (inches). Commands returning coordinates or distances always return a double value in the document's default unit.

## PUBLIC API

### PACKAGE COMMANDS

**::pdf4tcl::new objectName ?option value...?**
: This command creates a new pdf4tcl object with an associated Tcl command whose name is *objectName*. This *object* command is explained in full detail in the sections **OBJECT COMMAND** and **OBJECT METHODS**. The object command will be created under the current namespace if the *objectName* is not fully qualified, and in the specified namespace otherwise. If *objectName* is %AUTO% a name will generated. The return value is the newly created object's name. The options and their values coming after the name of the object are used to set the initial configuration of the object. See **OBJECT CONFIGURATION**.

**::pdf4tcl::getPaperSize paper**
: This call returns the size of a named paper type, e.g. "a4". Paper names are case insensitive. The argument *paper* may also be a two element list with values as accepted by **::pdf4tcl::getPoints**. The return value is a list with width and height in points.

**::pdf4tcl::getPaperSizeList**
: This call returns the list of known paper types.

**::pdf4tcl::getPoints val**
: This call translates a measurement to points (1/72 inch). The format of *val* is '*num* ?*unit*?' where *num* is a valid integer or double. See **UNITS** for valid *unit*s. If no *unit* is given, the value is interpreted as points.

**::pdf4tcl::loadBaseTrueTypeFont basefontname ttf_file_name**
: This call loads a TTF font from file to be used by any pdf4tcl objects. The *basefontname* is used to reference this font. To use this base font in documents, a font with some encoding must be created from it using **createFont** or **createFontSpecEnc**.

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

**type**
: Field type.

**value**
: Form value.

**flags**
: Value of form flags field.

**default**
: Default value, if any.

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

### OBJECT COMMAND

All commands created by **::pdf4tcl::new** have the following general form and may be used to invoke various operations on their pdf object.

**objectName method ?arg arg ...?**
: The method **method** and its *arg*'uments determine the exact behavior of the command. See section **OBJECT METHODS** for the detailed specifications.

### OBJECT METHODS

**-noimage bool**
: If this is set the XObject is not added to the image resource set and cannot be used with putImage, only in forms. The XObject also gets access to resources which is needed to use e.g. fonts within the XObject. This behaviour has shown to be PDF reader dependent, and it is currently not known if this can be made to work better.

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

**Common options**

**Text / Password options**

**Checkbutton options**

**Combobox / Listbox options**

**Radiobutton options**

**Pushbutton options**

**Signature options**

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

**objectName write ?-file filename?**
: This method writes the generated pdf to the given *filename*. If no *filename* is given, it is written to stdout. This will do **endPage** and **finish** if needed. If the **-file** option was given at object creation, an empty file is created.

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
: Draws the contents of the canvas widget *path* on the current page. The return value is the bounding box in pdf page coordinates of the area covered. Option *-bbox* gives the area of the canvas to be drawn. Default is the entire contents, i.e. the result of $path bbox all. Options *-x*, *-y*, *-width* and *-height* defines an area on the page where to place the contents. Default area starts at origin, stretching over the drawable area of the page. Option *-sticky* defines how to place the contents within the area. The area is always filled in one direction, preserving aspect ratio, unless *-sticky* defines that the other direction should be filled too. Default *-sticky* is *nw*. If option *-bg* is true, a background is drawn in the canvas' background color. Otherwise only objects are drawn. Default is false. Option *-fontmap* gives a dictionary mapping from Tk font names to PDF font names. Option *-textscale* overrides the automatic downsizing made for tk::canvas text items that are deemed too large. If *-textscale* is larger than 1, all text items are reduced in size by that factor. Fonts: If no font mapping is given, fonts for text items are limited to PDF's builtins, i.e. Helvetica, Times and Courier. A guess is made to chose which one to use to get a reasonable display on the page. An element in a font mapping must exactly match the -font option in the text item. The corresponding mapping value is a PDF font family, e.g. one created by **pdf4tcl::createFont**, possibly followed by a size. It is recommended to use named fonts in Tk to control the font mapping in detail. Limitations: Option -splinesteps for lines/polygons is ignored. Stipple offset is limited. The form x,y should work. Window items require Img to be present and must be visible on-screen when the canvas is drawn.

**objectName metadata ?option value...?**
: This method sets metadata fields for this document. Supported field options are *-author*, *-creator*, *-keywords*, *-producer*, *-subject*, *-title*, *-creationdate* and *-format*.

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

### OBJECT METHODS, TEXT

**-align left|right|center   (default left)**

**-angle degrees   (default 0) - Orient string at the specified angle.**

**-xangle degrees   (default 0)**

**-yangle degrees   (default 0) - Apply x or y shear to the text.**

**-x x   (default 0)**

**-y y   (default 0) - Allow the text to be positioned without setTextPosition.**

**-bg bool   (default 0)**

**-background bool   (default 0)**

**-fill bool   (default 0)**
: Any of **-bg**, **-background** or **-fill** cause the text to be drawn on a background whose color is set by setBgColor.

**-align left|right|center|justify**
: Specifies the justification. If not given, the text is left justified.

**-linesvar var**
: Gives the name of a variable which will be set to the number of lines written.

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

**objectName setFont size ?fontname?**
: This method sets the font used by text drawing routines. If *fontname* is not provided, the previously set *fontname* is kept.

**objectName getStringWidth str**
: This method returns the width of a string under the current font.

**objectName getCharWidth char**
: This method returns the width of a character under the current font.

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
: Get the current default line spacing.

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
: Set the image type. This can usually be deduced from the file name, this option helps when that is not possible. This can be either "png", "jpeg", or "tiff".

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

**objectName clip x y width height**
: Create a clip region. To cancel a clip region you must restore a graphic context that was saved before.

**objectName gsave**
: Save graphic/text context. (I.e. insert a raw PDF "q" command). This saves the settings of at least these calls: **clip**, **setBgColor**, **setFillColor**, **setStrokeColor**, **setLineStyle**, **setLineWidth**, **setLineDash**, **setFont**, and **setLineSpacing**. Each call to **gsave** should be followed by a later call to **grestore** in the same page.

**objectName grestore**
: Restore graphic/text context. (I.e. insert a raw PDF "Q" command).

### OBJECT CONFIGURATION

All pdf4tcl objects understand the options from **PAGE CONFIGURATION**, which defines default page settings when used with a pdf4tcl object. The objects also understand the following configuration options:

**-cmyk boolean**
: If true, pdf4tcl will try to generate the document in CMYK color space. See **::pdf4tcl::rgb2Cmyk** for a way to control color translation. Default value is false. This option can only be set at object creation.

**-compress boolean**
: Pages will be zlib compressed if this option is set to true. Default value is true. This option can only be set at object creation.

**-file filename**
: Continuously write pdf to *filename* instead of storing it in memory. This option can only be set at object creation.

**-unit defaultunit**
: Defines default unit for coordinates and distances. Any value given without a unit is interpreted using this unit. See **UNITS** for valid units. Default value is "p" as in points. This option can only be set at object creation.

### PAGE CONFIGURATION

**-paper name**
: The argument of this option defines the paper size. The paper size may be a string like "a4", where valid values are available through **::pdf4tcl::getPaperSizeList**. Paper size may also be a two element list specifying width and height. The default value of this option is "a4".

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

## SEE ALSO

doctools

## KEYWORDS

document, pdf

## COPYRIGHT

```tcl
Copyright (c) 2007-2016 Peter Spjuth
Copyright (c) 2009 Yaroslav Schekin
```

