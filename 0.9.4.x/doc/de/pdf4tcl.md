# pdf4tcl

## NAME

pdf4tcl - PDF-Dokumentenerstellung

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

Dieses Paket stellt eine Container-Klasse zur Erstellung von *PDF*-Dokumenten bereit.

## COORDINATES

Alle Koordinaten und Abstände können mit oder ohne Einheit angegeben werden. Siehe **UNITS** für gültige Einheiten. Wenn die Seite mit **-orient** auf false konfiguriert ist, liegt der Ursprung in der unteren linken Ecke. Mit **-orient** true (Standard) liegt der Ursprung in der oberen linken Ecke. Der Ursprung wird verschoben, um Ränder zu berücksichtigen, d.h. wenn die Ränder 100 sind, entspricht die Benutzerkoordinate (0,0) der Position (100,100) auf dem Papier. Die Seitenoption **-orient** kann auch den Ankerpunkt für Dinge wie Bilder beeinflussen.

## UNITS

Alle Koordinaten und Abstände können mit oder ohne explizite Einheit angegeben werden. Wenn keine Einheit angegeben wird, wird die Standardeinheit des Dokuments verwendet. Eine Einheit kann **mm** (Millimeter), **m** (Millimeter), **cm** (Zentimeter), **c** (Zentimeter), **p** (Punkte) oder **i** (Zoll) sein. Befehle, die Koordinaten oder Abstände zurückgeben, geben immer einen Double-Wert in der Standardeinheit des Dokuments zurück.

## PUBLIC API

### PACKAGE COMMANDS

**::pdf4tcl::new objectName ?option value...?**
: Dieser Befehl erstellt ein neues pdf4tcl-Objekt mit einem zugehörigen Tcl-Befehl, dessen Name *objectName* ist. Dieser *object*-Befehl wird in den Abschnitten **OBJECT COMMAND** und **OBJECT METHODS** ausführlich erklärt. Der Objektbefehl wird im aktuellen Namespace erstellt, wenn *objectName* nicht vollständig qualifiziert ist, andernfalls im angegebenen Namespace. Wenn *objectName* %AUTO% ist, wird ein Name generiert. Der Rückgabewert ist der Name des neu erstellten Objekts. Die Optionen und ihre Werte nach dem Namen des Objekts werden verwendet, um die anfängliche Konfiguration des Objekts festzulegen. Siehe **OBJECT CONFIGURATION**.

**::pdf4tcl::getPaperSize paper**
: Dieser Aufruf gibt die Größe eines benannten Papierformats zurück, z.B. "a4". Papiernamen sind unabhängig von Groß-/Kleinschreibung. Das Argument *paper* kann auch eine zweielementige Liste mit Werten sein, wie sie von **::pdf4tcl::getPoints** akzeptiert werden. Der Rückgabewert ist eine Liste mit Breite und Höhe in Punkten.

**::pdf4tcl::getPaperSizeList**
: Dieser Aufruf gibt die Liste der bekannten Papierformate zurück.

**::pdf4tcl::getPoints val**
: Dieser Aufruf übersetzt eine Messung in Punkte (1/72 Zoll). Das Format von *val* ist '*num* ?*unit*?' wobei *num* eine gültige Ganzzahl oder Double ist. Siehe **UNITS** für gültige *unit*s. Wenn keine *unit* angegeben wird, wird der Wert als Punkte interpretiert.

**::pdf4tcl::loadBaseTrueTypeFont basefontname ttf_file_name**
: Dieser Aufruf lädt eine TTF-Schriftart aus einer Datei, die von allen pdf4tcl-Objekten verwendet werden kann. Der *basefontname* wird verwendet, um auf diese Schriftart zu verweisen. Um diese Basis-Schriftart in Dokumenten zu verwenden, muss eine Schriftart mit einer Kodierung daraus erstellt werden, indem **createFont** oder **createFontSpecEnc** verwendet wird.

**::pdf4tcl::createBaseTrueTypeFont basefontname ttf_data**
: Dieser Aufruf erstellt eine Basis-Schriftart aus TTF-Binärdaten.

**::pdf4tcl::loadBaseType1Font basefontname AFM_file_name PFB_file_name**
: Dieser Aufruf lädt eine Type1-Schriftart aus zwei Dateien (.afm und .pfb), die von allen pdf4tcl-Objekten verwendet werden kann. Der *basefontname* wird verwendet, um auf diese Schriftart zu verweisen. Um diese Basis-Schriftart in Dokumenten zu verwenden, muss eine Schriftart mit einer Kodierung daraus erstellt werden, indem **createFont** oder **createFontSpecEnc** verwendet wird.

**::pdf4tcl::createBaseType1Font basefontname AFM_data PFB_data**
: Dieser Aufruf erstellt eine Basis-Schriftart aus AFM-Text- und PFB-Binärdaten.

**::pdf4tcl::createFont basefontname fontname encoding_name**
: Dieser Aufruf erstellt eine Schriftart, die in Dokumenten verwendet werden kann, aus einer Basis-Schriftart. Die angegebene Kodierung definiert die (bis zu) 256 Unicode-Zeichen, die gezeichnet werden können, wenn *fontname* ausgewählt ist. Um mehr Zeichen zu verwenden, müssen mehrere Schriftarten erstellt und basierend auf dem, was geschrieben werden soll, ausgewählt werden.

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
: Dieser Aufruf erstellt eine Schriftart, die in Dokumenten verwendet werden kann, aus einer Basis-Schriftart. Das *subset* muss eine Liste von (bis zu 256) Unicode-Werten sein, die die Zeichen sind, die gezeichnet werden können, wenn *fontname* ausgewählt ist.

```tcl
pdf4tcl::loadBaseTrueTypeFont BaseArial "arial.ttf"
# Subset ist eine Liste von Unicodes:
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
: Feldtyp.

**value**
: Formularwert.

**flags**
: Wert des Formular-Flags-Felds.

**default**
: Standardwert, falls vorhanden.

**::pdf4tcl::getFonts**
: Dieser Aufruf gibt die Liste der bekannten Schriftartnamen zurück, d.h. diejenigen, die in einem Aufruf von **setFont** akzeptiert werden. Dies umfasst die Standard-Schriftarten und Schriftarten, die z.B. von **::pdf4tcl::createFont** erstellt wurden.

**::pdf4tcl::rgb2Cmyk rgb**
: Dieser Aufruf übersetzt einen RGB-Farbwert in einen CMYK-Farbwert. Er wird intern verwendet, wenn **-cmyk** bei der Objekterstellung gesetzt wurde, um Farben zu übersetzen. Sie können diese Prozedur neu definieren, um Ihre eigene Übersetzung bereitzustellen.

**::pdf4tcl::cmyk2Rgb cmyk**
: Dieser Aufruf übersetzt einen CMYK-Farbwert in einen RGB-Farbwert. Er wird intern verwendet, um Farben zu übersetzen. Sie können diese Prozedur neu definieren, um Ihre eigene Übersetzung bereitzustellen.

**::pdf4tcl::catPdf infile ?infile ...? outfile**
: Dieser Aufruf verkettet PDF-Dateien zu einer. Derzeit schränkt die Implementierung die PDFs stark ein, da noch nicht alle Details berücksichtigt werden. Einfache wie die mit pdf4tcl oder ps2pdf erstellten sollten größtenteils funktionieren.

**::pdf4tcl::getForms infile**
: Dieser Aufruf extrahiert Formulardaten aus einer PDF-Datei. Der Rückgabewert ist ein Dictionary mit id/info-Paaren. Die id ist diejenige, die mit *-id* für **addForm** gesetzt wurde, wenn das PDF mit pdf4tcl generiert wurde. Die info ist ein Dictionary mit den folgenden Feldern:

### OBJECT COMMAND

Alle Befehle, die von **::pdf4tcl::new** erstellt werden, haben die folgende allgemeine Form und können verwendet werden, um verschiedene Operationen auf ihrem PDF-Objekt aufzurufen.

**objectName method ?arg arg ...?**
: Die Methode **method** und ihre *arg*umente bestimmen das genaue Verhalten des Befehls. Siehe Abschnitt **OBJECT METHODS** für die detaillierten Spezifikationen.

### OBJECT METHODS

**-noimage bool**
: Wenn dies gesetzt ist, wird das XObject nicht zum Bildressourcen-Satz hinzugefügt und kann nicht mit putImage verwendet werden, nur in Formularen. Das XObject erhält auch Zugriff auf Ressourcen, was benötigt wird, um z.B. Schriftarten innerhalb des XObject zu verwenden. Dieses Verhalten hat sich als PDF-Reader-abhängig erwiesen, und es ist derzeit nicht bekannt, ob dies besser funktionieren kann.

**-id string**
: Eindeutige Feld-ID (alphanumerisch). Wenn weggelassen, wird automatisch eine generiert: *${type}form${n}* für die meisten Typen, *${group}_${value}* für Radiobuttons, *Signature${n}* für Signaturen.

**-init value**
: Anfangswert. Für *text*/*password* ein String, für *checkbutton* ein Boolean, für *combobox*/*listbox* ein Element aus *-options*, für *radiobutton* ein Boolean, das diesen Button auswählt.

**-readonly boolean**
: Wenn true, ist das Feld schreibgeschützt (PDF Ff Bit 1). Standard **0**.

**-required boolean**
: Wenn true, wird das Feld als erforderlich markiert (PDF Ff Bit 2). Standard **0**. Nicht gültig für *pushbutton* oder *signature*.

**-multiline boolean**
: Mehrzeilige Bearbeitung aktivieren (nur Text). Standard **0**.

**-on xobjectId**
: Benutzerdefiniertes Erscheinungsbild-XObject für den aktivierten Zustand. Erstellt mit **startXObject**.

**-off xobjectId**
: Benutzerdefiniertes Erscheinungsbild-XObject für den deaktivierten Zustand.

**-options list**
: Liste der auswählbaren Elemente. Erforderlich für *combobox* und *listbox*.

**-editable boolean**
: Eingabe benutzerdefinierter Werte erlauben (nur combobox). Standard **0**.

**-sort boolean**
: Die Optionsliste sortieren. Standard **0**.

**-multiselect boolean**
: Mehrfachauswahl erlauben (nur listbox). Standard **0**.

**-group string**
: Gruppenname (erforderlich, alphanumerisch). Alle Buttons, die denselben Gruppennamen teilen, bilden eine sich gegenseitig ausschließende Menge.

**-value string**
: Wert für diesen Button (erforderlich, alphanumerisch). Wird als PDF-Erscheinungsbild-Statusname verwendet.

**-action type**
: Aktionstyp: **reset** (alle Felder löschen), **url** (URL öffnen) oder **submit** (Formulardaten an URL senden).

**-url string**
: Ziel-URL. Erforderlich, wenn *-action* **url** oder **submit** ist.

**-caption string**
: Button-Beschriftungstext. Entweder *-action* oder *-caption* (oder beide) müssen angegeben werden.

**-label string**
: Platzhaltertext, der auf der Signaturzeile angezeigt wird. Standard **Signature**. Nur gültig für *signature*-Felder.

**Common options**

**Text / Password options**

**Checkbutton options**

**Combobox / Listbox options**

**Radiobutton options**

**Pushbutton options**

**Signature options**

**objectName configure**
: Die Methode gibt eine Liste aller bekannten Optionen und ihrer aktuellen Werte zurück, wenn sie ohne Argumente aufgerufen wird.

**objectName configure option**
: Die Methode verhält sich wie die Methode **cget**, wenn sie mit einem einzelnen Argument aufgerufen wird, und gibt den Wert der durch dieses Argument angegebenen Option zurück.

**objectName configure -option value...**
: Die Methode rekonfiguriert die angegebenen **option**en des Objekts und setzt sie auf die zugehörigen *value*s, wenn sie mit einer geraden Anzahl von Argumenten, mindestens zwei, aufgerufen wird. Die gültigen Optionen sind im Abschnitt **OBJECT CONFIGURATION** beschrieben.

**objectName cget -option**
: Diese Methode erwartet eine gültige Konfigurationsoption als Argument und gibt den aktuellen Wert dieser Option für das Objekt zurück, für das die Methode aufgerufen wurde. Die gültigen Konfigurationsoptionen sind im Abschnitt **OBJECT CONFIGURATION** beschrieben.

**objectName destroy**
: Diese Methode zerstört das Objekt, für das sie aufgerufen wird. Wenn die Option **-file** bei der Objekterstellung angegeben wurde, wird die Ausgabedatei abgeschlossen und geschlossen.

**objectName startPage ?option value...?**
: Diese Methode startet eine neue Seite im Dokument. Die Seite hat die Standard-Seiteneinstellungen für das Dokument, es sei denn, sie werden durch *option* überschrieben. Siehe **PAGE CONFIGURATION** für Seiteneinstellungen. Dies beendet jede laufende Seite.

**objectName endPage**
: Diese Methode beendet eine Seite im Dokument. Sie ist normalerweise nicht erforderlich, da sie z.B. von **startPage** und **finish** impliziert wird. Wenn das Dokument jedoch z.B. in einer ereignisgesteuerten Umgebung Seite für Seite erstellt wird, kann es gut sein, **endPage** explizit aufzurufen, um alle Arbeiten der Seite abzuschließen, bevor die Ereignisschleife erneut betreten wird.

**objectName startXObject ?option value...?**
: Diese Methode startet ein neues XObject im Dokument. Ein XObject ist ein wiederverwendbares Zeichnungsobjekt und verhält sich genau wie eine Seite, auf der Sie beliebige Grafiken zeichnen können. Ein XObject muss zwischen Seiten erstellt werden, und diese Methode beendet jede laufende Seite. Der Rückgabewert ist eine ID, die mit **putImage** verwendet werden kann, um es auf der aktuellen Seite zu zeichnen oder mit einigen Formularen. Alle Seiteneinstellungen (**PAGE CONFIGURATION**) sind gültig, wenn ein XObject erstellt wird. Standardoptionen sind **-paper** = {100p 100p}, **-landscape** = 0, **-orient** = Dokumentstandard, **-margin**= 0.

**objectName endXObject**
: Diese Methode beendet eine XObject-Definition. Sie funktioniert genau wie **endPage**.

**objectName finish**
: Diese Methode beendet das Dokument. Dies führt **endPage** durch, falls erforderlich. Wenn die Option **-file** bei der Objekterstellung angegeben wurde, wird die Ausgabedatei abgeschlossen und geschlossen.

**objectName get**
: Diese Methode gibt das generierte PDF zurück. Dies führt **endPage** und **finish** durch, falls erforderlich. Wenn die Option **-file** bei der Objekterstellung angegeben wurde, wird nichts zurückgegeben.

**objectName write ?-file filename?**
: Diese Methode schreibt das generierte PDF in die angegebene *filename*. Wenn keine *filename* angegeben wird, wird es nach stdout geschrieben. Dies führt **endPage** und **finish** durch, falls erforderlich. Wenn die Option **-file** bei der Objekterstellung angegeben wurde, wird eine leere Datei erstellt.

**objectName addForm type x y width height ?option value...?**
: Fügt ein interaktives Formularfeld an der angegebenen Position und Größe hinzu. Koordinaten sind in der aktuellen Einheit des Dokuments. Unterstützte Typen sind *text*, *password*, *checkbutton* (Alias *checkbox*), *combobox*, *listbox*, *radiobutton*, *pushbutton* und *signature*.

- Alle Felder generieren ihre eigenen Erscheinungsbild-Streams; das Flag **NeedAppearances** wird niemals gesetzt, was die Kompatibilität mit digitalen Signatur-Workflows gewährleistet. Radiobutton-Gruppen werden zum Zeitpunkt des Dokumentenschreibens als übergeordnetes Feld mit **/Kids**-Einträgen finalisiert.

### OBJECT METHODS, PAGE

**-title text**
: Text des Lesezeichens setzen.

**-level level**
: Ebene des Lesezeichens setzen. Standard ist 0.

**-closed boolean**
: Auswählen, ob das Lesezeichen standardmäßig geschlossen ist. Standard ist false, d.h. nicht geschlossen.

**-id id**
: Explizit eine ID für die Datei auswählen. Die *id* muss innerhalb des Dokuments eindeutig sein.

**-contents data**
: Stellt den Dateiinhalt bereit, anstatt die tatsächliche Datei zu lesen.

**-icon icon**
: Steuert das Erscheinungsbild des Anhangs. Gültige Werte sind Paperclip, Tag, Graph oder PushPin. Standardwert ist Paperclip.

**objectName getDrawableArea**
: Diese Methode gibt die Größe des verfügbaren Bereichs auf der Seite zurück, nachdem Ränder entfernt wurden. Der Rückgabewert ist eine Liste von Breite und Höhe in der Standardeinheit des Dokuments.

**objectName canvas path ?option value...?**
: Zeichnet den Inhalt des Canvas-Widgets *path* auf der aktuellen Seite. Der Rückgabewert ist die Bounding Box in PDF-Seitenkoordinaten des abgedeckten Bereichs. Option *-bbox* gibt den Bereich des Canvas an, der gezeichnet werden soll. Standard ist der gesamte Inhalt, d.h. das Ergebnis von $path bbox all. Optionen *-x*, *-y*, *-width* und *-height* definieren einen Bereich auf der Seite, in dem der Inhalt platziert werden soll. Der Standardbereich beginnt am Ursprung und erstreckt sich über den zeichnbaren Bereich der Seite. Option *-sticky* definiert, wie der Inhalt innerhalb des Bereichs platziert wird. Der Bereich wird immer in eine Richtung gefüllt, wobei das Seitenverhältnis erhalten bleibt, es sei denn, *-sticky* definiert, dass auch die andere Richtung gefüllt werden soll. Standard *-sticky* ist *nw*. Wenn Option *-bg* true ist, wird ein Hintergrund in der Hintergrundfarbe des Canvas gezeichnet. Andernfalls werden nur Objekte gezeichnet. Standard ist false. Option *-fontmap* gibt ein Dictionary mit Zuordnungen von Tk-Schriftartnamen zu PDF-Schriftartnamen. Option *-textscale* überschreibt die automatische Verkleinerung für tk::canvas-Textelemente, die als zu groß erachtet werden. Wenn *-textscale* größer als 1 ist, werden alle Textelemente um diesen Faktor verkleinert. Schriftarten: Wenn keine Schriftartzuordnung angegeben wird, sind Schriftarten für Textelemente auf PDFs eingebaute beschränkt, d.h. Helvetica, Times und Courier. Es wird eine Vermutung angestellt, welche verwendet werden soll, um eine vernünftige Anzeige auf der Seite zu erhalten. Ein Element in einer Schriftartzuordnung muss genau mit der -font-Option im Textelement übereinstimmen. Der entsprechende Zuordnungswert ist eine PDF-Schriftartfamilie, z.B. eine, die von **pdf4tcl::createFont** erstellt wurde, möglicherweise gefolgt von einer Größe. Es wird empfohlen, benannte Schriftarten in Tk zu verwenden, um die Schriftartzuordnung im Detail zu steuern. Einschränkungen: Option -splinesteps für Linien/Polygone wird ignoriert. Stipple-Offset ist begrenzt. Die Form x,y sollte funktionieren. Fensterelemente erfordern Img und müssen sichtbar auf dem Bildschirm sein, wenn der Canvas gezeichnet wird.

**objectName metadata ?option value...?**
: Diese Methode setzt Metadatenfelder für dieses Dokument. Unterstützte Feldoptionen sind *-author*, *-creator*, *-keywords*, *-producer*, *-subject*, *-title*, *-creationdate* und *-format*.

**objectName bookmarkAdd ?option value...?**
: Fügt ein Lesezeichen auf der aktuellen Seite hinzu.

**objectName embedFile filename ?option value...?**
: Diese Methode bettet eine Datei in den PDF-Stream ein. Dateidaten werden als binär betrachtet. Gibt eine ID zurück, die in nachfolgenden Aufrufen von **attachFile** verwendet werden kann.

**objectName attachFile x y width height fid description ?option value...?**
: Diese Methode fügt eine Dateianmerkung zur aktuellen Seite hinzu. Die Position der Dateianmerkung wird durch die Koordinaten *x*, *y*, *width*, *height* angegeben. Die Anmerkung wird standardmäßig als Büroklammer-Symbol gerendert, was die Extraktion der angehängten Datei ermöglicht. Eine *fid* von einem vorherigen Aufruf von **embedFile** muss gesetzt werden sowie eine *description*, die vom PDF-Viewer beim Aktivieren der Anmerkung angezeigt wird.

```tcl
set fid [$pdfobject embedFile "data.txt" -contents "This should be stored in the file."]
$pdfobject attachFile 0 0 100 100 $fid "This is the description"
```

### OBJECT METHODS, TEXT

**-align left|right|center   (default left)**

**-angle degrees   (default 0) - String im angegebenen Winkel ausrichten.**

**-xangle degrees   (default 0)**

**-yangle degrees   (default 0) - x- oder y-Scherung auf den Text anwenden.**

**-x x   (default 0)**

**-y y   (default 0) - Ermöglicht die Positionierung des Textes ohne setTextPosition.**

**-bg bool   (default 0)**

**-background bool   (default 0)**

**-fill bool   (default 0)**
: Jede von **-bg**, **-background** oder **-fill** bewirkt, dass der Text auf einem Hintergrund gezeichnet wird, dessen Farbe durch setBgColor gesetzt wird.

**-align left|right|center|justify**
: Gibt die Ausrichtung an. Wenn nicht angegeben, ist der Text linksbündig.

**-linesvar var**
: Gibt den Namen einer Variablen an, die auf die Anzahl der geschriebenen Zeilen gesetzt wird.

**-dryrun bool**
: Wenn true, werden keine Änderungen am PDF-Dokument vorgenommen. Der Rückgabewert und **-linesvar** geben Informationen darüber, was mit dem angegebenen Text passieren würde.

**ascend**
: Oberseite des typischen Glyphs, Verschiebung vom Ankerpunkt. Typischerweise eine positive Zahl, da sie über dem Ankerpunkt liegt.

**descend**
: Unterseite des typischen Glyphs, Verschiebung vom Ankerpunkt. Typischerweise eine negative Zahl, da sie unter dem Ankerpunkt liegt.

**fixed**
: Boolean, der true ist, wenn dies eine Festbreitenschriftart ist.

**bboxb**
: Unterseite der Bounding Box, Verschiebung vom Ankerpunkt. Typischerweise eine negative Zahl, da sie unter dem Ankerpunkt liegt.

**bboxt**
: Oberseite der Bounding Box, Verschiebung vom Ankerpunkt. Typischerweise eine positive Zahl, da sie über dem Ankerpunkt liegt.

**height**
: Höhe der Bounding Box der Schriftart.

**objectName setFont size ?fontname?**
: Diese Methode setzt die Schriftart, die von Textzeichnungsroutinen verwendet wird. Wenn *fontname* nicht angegeben wird, wird die zuvor gesetzte *fontname* beibehalten.

**objectName getStringWidth str**
: Diese Methode gibt die Breite einer Zeichenkette unter der aktuellen Schriftart zurück.

**objectName getCharWidth char**
: Diese Methode gibt die Breite eines Zeichens unter der aktuellen Schriftart zurück.

**objectName setTextPosition x y**
: Koordinate für den nächsten Textbefehl setzen.

**objectName moveTextPosition dx dy**
: Position um *dx*, *dy* für den nächsten Textbefehl erhöhen.

**objectName getTextPosition**
: Diese Methode gibt die aktuelle Textkoordinate zurück.

**objectName newLine ?spacing?**
: Bewegt die Textkoordinate nach unten und setzt x auf die Position zurück, an der die letzte **setTextPosition** war. Die Anzahl der Zeilen, um die nach unten bewegt werden soll, kann durch *spacing* gesetzt werden. Dies kann eine beliebige reelle Zahl sein, einschließlich negativer, und standardmäßig der Wert, der durch **setLineSpacing** gesetzt wurde.

**objectName setLineSpacing spacing**
: Setzt den Standard-Zeilenabstand, der z.B. von **newLine** verwendet wird. Anfangs ist der Abstand 1.

**objectName getLineSpacing**
: Gibt den aktuellen Standard-Zeilenabstand zurück.

**objectName text str ?option value...?**
: Zeichnet Text an der Position, die durch setTextPosition definiert ist, unter Verwendung der Schriftart, die durch setFont definiert ist.

**objectName drawTextBox x y width height str ?option value...?**
: Zeichnet die Textzeichenkette *str* mit Umbrüchen bei Leerzeichen und Tabs, sodass sie in die durch *x*, *y*, *width* und *height* definierte Box passt. Ein eingebetteter Zeilenumbruch in *str* verursacht eine neue Zeile in der Ausgabe. Wenn *str* zu lang ist, um in die angegebene Box zu passen, wird sie abgeschnitten und der ungenutzte Rest wird zurückgegeben.

**objectName getFontMetric metric**
: Gibt Informationen über die aktuelle Schriftart zurück. Die verfügbaren *metric*s sind **ascend**, **descend**, **fixed**, **bboxb**, **bboxt** und **height**.

### OBJECT METHODS, IMAGES

Eine begrenzte Anzahl von Bildformaten wird direkt von pdf4tcl verstanden, derzeit einige JPEG-, einige PNG- und einige TIFF-Formate. Um nicht unterstützte Formate zu verwenden, verwenden Sie Tk und das Img-Paket, um Bilder zu laden und in Rohformat zu speichern, das an **putRawImage** und **addRawImage** übergeben werden kann.

**-angle degrees**
: Bild um *degrees* gegen den Uhrzeigersinn um den Ankerpunkt drehen. Standard ist 0.

**-anchor anchor**
: Ankerpunkt (nw, n, ne usw.) des Bildes setzen. Koordinaten *x* und *y* platzieren den Ankerpunkt, und jede Rotation erfolgt um den Ankerpunkt. Standard ist nw, wenn **-orient** true ist, andernfalls se.

**-height height**
: Höhe des Bildes setzen. Standardhöhe ist ein Punkt pro Pixel. Wenn *width* gesetzt ist, aber nicht *height*, wird die Höhe so gewählt, dass das Seitenverhältnis des Bildes erhalten bleibt.

**-width width**
: Breite des Bildes setzen. Standardbreite ist ein Punkt pro Pixel. Wenn *height* gesetzt ist, aber nicht *width*, wird die Breite so gewählt, dass das Seitenverhältnis des Bildes erhalten bleibt.

**-compress boolean**
: Rohe Daten werden zlib-komprimiert, wenn diese Option auf true gesetzt ist. Standardwert ist die **-compress**-Einstellung des Dokuments.

**objectName putImage id x y ?option value...?**
: Platziert ein Bild auf der aktuellen Seite. Das Bild muss zuvor durch **addImage** oder **addRawImage** hinzugefügt worden sein. Die *id* ist diejenige, die vom add-Befehl zurückgegeben wurde.

**objectName putRawImage data x y ?option value...?**
: Platziert ein Bild auf der aktuellen Seite. Funktioniert wie **putImage**, außer dass die rohen Bilddaten direkt angegeben werden.

```tcl
image create photo img1 -file image.gif
  set imgdata [img1 data]
  mypdf putRawImage $imgdata 60 20 -height 40
```

**-id id**
: Explizit eine ID für das Bild auswählen. Die *id* muss innerhalb des Dokuments eindeutig sein.

**-type name**
: Bildtyp setzen. Dies kann normalerweise aus dem Dateinamen abgeleitet werden, diese Option hilft, wenn das nicht möglich ist. Dies kann entweder "png", "jpeg" oder "tiff" sein.

**-compress boolean**
: Rohe Daten werden zlib-komprimiert, wenn diese Option auf true gesetzt ist. Standardwert ist die **-compress**-Einstellung des Dokuments.

**objectName addImage filename ?option value...?**
: Fügt ein Bild zum Dokument hinzu. Gibt eine ID zurück, die in nachfolgenden Aufrufen von **putImage** verwendet werden kann. Unterstützte Formate sind PNG, JPEG und TIFF.

**objectName addRawImage data ?option value...?**
: Fügt ein Bild zum Dokument hinzu. Funktioniert wie **addImage**, außer dass die rohen Bilddaten direkt angegeben werden.

```tcl
image create photo img1 -file image.gif
  set imgdata [img1 data]
  set id [mypdf addRawImage $imgdata]
  mypdf putImage $id 20 60 -width 100
```

**objectName getImageHeight id**
: Diese Methode gibt die Höhe des durch *id* identifizierten Bildes zurück.

**objectName getImageSize id**
: Diese Methode gibt die Größe des durch *id* identifizierten Bildes zurück. Der Rückgabewert ist eine Liste von Breite und Höhe.

**objectName getImageWidth id**
: Diese Methode gibt die Breite des durch *id* identifizierten Bildes zurück.

### OBJECT METHODS, COLORS

Farben können in verschiedenen Formaten ausgedrückt werden. Erstens als dreielementige Liste von Werten im Bereich 0.0 bis 1.0. Zweitens im Format #XXXXXX, wobei die Xe zwei hexadezimale Ziffern pro Farbwert sind. Drittens, wenn Tk verfügbar ist, wird jede Farbe akzeptiert, die von winfo rgb akzeptiert wird.

**objectName setBgColor red green blue**
: Setzt die Hintergrundfarbe für Textoperationen, bei denen -bg true ist.

**objectName setBgColor c m y k**
: Alternative Aufrufform, um Farbe im CMYK-Farbraum zu setzen.

**objectName setFillColor red green blue**
: Setzt die Füllfarbe für Grafikoperationen und die Vordergrundfarbe für Textoperationen.

**objectName setFillColor c m y k**
: Alternative Aufrufform, um Farbe im CMYK-Farbraum zu setzen.

**objectName setStrokeColor red green blue**
: Setzt die Strichfarbe für Grafikoperationen.

**objectName setStrokeColor c m y k**
: Alternative Aufrufform, um Farbe im CMYK-Farbraum zu setzen.

### OBJECT METHODS, GRAPHICS

**-filled bool   (default 0)**
: Polygon füllen.

**-stroke bool   (default 1)**
: Umriss des Polygons zeichnen.

**-closed bool   (default 1)**
: Polygon schließen.

**-filled bool   (default 0)**
: Kreis füllen.

**-stroke bool   (default 1)**
: Umriss des Kreises zeichnen.

**-filled bool   (default 0)**
: Oval füllen.

**-stroke bool   (default 1)**
: Umriss des Ovals zeichnen.

**-filled bool   (default 0)**
: Bogen füllen.

**-stroke bool   (default 1)**
: Umriss des Bogens zeichnen.

**-style arc|pieslice|chord   (default arc)**
: Definiert den Stil des Bogens. Ein *arc* zeichnet den Umfang des Bogens und wird niemals gefüllt. Ein *pieslice* schließt den Bogen mit Linien zum Mittelpunkt des Ovals. Ein *chord* schließt den Bogen direkt.

**-filled bool   (default 0)**
: Rechteck füllen.

**-stroke bool   (default 1)**
: Umriss des Rechtecks zeichnen.

**objectName setLineWidth width**
: Setzt die Breite für nachfolgende Linienzeichnungen. Die Linienbreite muss eine nicht-negative Zahl sein.

**objectName setLineDash ?on off...? ?offset?**
: Setzt das Strichmuster für nachfolgende Linienzeichnungen. Offset und alle Elemente im Strichmuster müssen nicht-negative Zahlen sein. *on off* ist eine Reihe von Zahlenpaaren, die ein Strichmuster definieren. Die 1., 3. ... Zahlen geben Einheiten zum Malen an, die 2., 4. ... Zahlen geben unpaintierte Lücken an. Wenn alle Zahlen verwendet wurden, wird das Muster von Anfang an neu gestartet. Ein optionales letztes Argument setzt den Strich-Offset, der standardmäßig 0 ist. Das Aufrufen von **setLineDash** ohne Argumente setzt das Strichmuster auf eine durchgezogene Linie zurück.

**objectName setLineStyle width args**
: Setzt die Breite und das Strichmuster für nachfolgende Linienzeichnungen. Die Linienbreite und alle Elemente im Strichmuster müssen nicht-negative Zahlen sein. *args* ist eine Reihe von Zahlen (keine tcl-Liste), die ein Strichmuster definieren. Die 1., 3. ... Zahlen geben Einheiten zum Malen an, die 2., 4. ... Zahlen geben unpaintierte Lücken an. Wenn alle Zahlen verwendet wurden, wird das Muster von Anfang an neu gestartet. Diese Methode unterstützt keine Verschiebung des Musters, siehe **setLineDash** für eine vollständigere Methode.

**objectName line x1 y1 x2 y2**
: Zeichnet eine Linie von *x1,* *y1* nach *x2,* *y2*

**objectName curve x1 y1 x2 y2 x3 y3 ?x4 y4?**
: Wenn *x4,* *y4* vorhanden sind, zeichnet es eine kubische Bezier-Kurve von *x1,* *y1* nach *x4,* *y4* mit Kontrollpunkten *x2,* *y2* und *x3,* *y3*. Andernfalls zeichnet es eine quadratische Bezier-Kurve von *x1,* *y1* nach *x3,* *y3* mit Kontrollpunkt *x2,* *y2*

**objectName polygon ?x y...? ?option value...?**
: Zeichnet ein Polygon. Es müssen mindestens 3 Punkte vorhanden sein. Das Polygon wird zur ersten Koordinate zurückgeschlossen, es sei denn, *-closed* ist false, in diesem Fall wird eine Polylinie gezeichnet.

**objectName circle x y radius ?option value...?**
: Zeichnet einen Kreis an den angegebenen Mittelpunktskoordinaten.

**objectName oval x y radiusx radiusy ?option value...?**
: Zeichnet ein Oval an den angegebenen Mittelpunktskoordinaten.

**objectName arc x y radiusx radiusy phi extend ?option value...?**
: Zeichnet einen Bogen, der dem angegebenen Oval folgt. Der Bogen beginnt bei Winkel *phi*, angegeben in Grad, beginnend in "Ost"-Richtung, gegen den Uhrzeigersinn zählend. Der Bogen erstreckt sich über *extend* Grad.

**objectName arrow x1 y1 x2 y2 size ?angle?**
: Zeichnet einen Pfeil. Standard *angle* ist 20 Grad.

**objectName rectangle x y width height ?option value...?**
: Zeichnet ein Rechteck.

**objectName clip x y width height**
: Erstellt einen Clip-Bereich. Um einen Clip-Bereich aufzuheben, müssen Sie einen Grafikkontext wiederherstellen, der zuvor gespeichert wurde.

**objectName gsave**
: Grafik-/Textkontext speichern. (D.h. einen rohen PDF-"q"-Befehl einfügen). Dies speichert die Einstellungen von mindestens diesen Aufrufen: **clip**, **setBgColor**, **setFillColor**, **setStrokeColor**, **setLineStyle**, **setLineWidth**, **setLineDash**, **setFont** und **setLineSpacing**. Jeder Aufruf von **gsave** sollte von einem späteren Aufruf von **grestore** auf derselben Seite gefolgt werden.

**objectName grestore**
: Grafik-/Textkontext wiederherstellen. (D.h. einen rohen PDF-"Q"-Befehl einfügen).

### OBJECT CONFIGURATION

Alle pdf4tcl-Objekte verstehen die Optionen aus **PAGE CONFIGURATION**, die Standard-Seiteneinstellungen definiert, wenn sie mit einem pdf4tcl-Objekt verwendet werden. Die Objekte verstehen auch die folgenden Konfigurationsoptionen:

**-cmyk boolean**
: Wenn true, versucht pdf4tcl, das Dokument im CMYK-Farbraum zu generieren. Siehe **::pdf4tcl::rgb2Cmyk** für eine Möglichkeit, die Farbübersetzung zu steuern. Standardwert ist false. Diese Option kann nur bei der Objekterstellung gesetzt werden.

**-compress boolean**
: Seiten werden zlib-komprimiert, wenn diese Option auf true gesetzt ist. Standardwert ist true. Diese Option kann nur bei der Objekterstellung gesetzt werden.

**-file filename**
: Kontinuierlich PDF in *filename* schreiben, anstatt es im Speicher zu speichern. Diese Option kann nur bei der Objekterstellung gesetzt werden.

**-unit defaultunit**
: Definiert die Standardeinheit für Koordinaten und Abstände. Jeder Wert, der ohne Einheit angegeben wird, wird mit dieser Einheit interpretiert. Siehe **UNITS** für gültige Einheiten. Standardwert ist "p" wie in Punkten. Diese Option kann nur bei der Objekterstellung gesetzt werden.

### PAGE CONFIGURATION

**-paper name**
: Das Argument dieser Option definiert die Papiergröße. Die Papiergröße kann eine Zeichenkette wie "a4" sein, wobei gültige Werte über **::pdf4tcl::getPaperSizeList** verfügbar sind. Die Papiergröße kann auch eine zweielementige Liste sein, die Breite und Höhe angibt. Der Standardwert dieser Option ist "a4".

**-landscape boolean**
: Wenn true, werden Papierbreite und -höhe vertauscht. Der Standardwert dieser Option ist false.

**-orient boolean**
: Dies setzt die Ausrichtung der y-Achse des Koordinatensystems. Mit **-orient** false liegt der Ursprung in der unteren linken Ecke. Mit **-orient** true liegt der Ursprung in der oberen linken Ecke. Der Standardwert dieser Option ist true.

**-margin values**
: Der Rand ist eine ein-, zwei- oder vierteilige Liste von Rändern. Bei einem Element gibt es alle Ränder an. Zwei Elemente geben links/rechts und oben/unten an. Vier Elemente geben links, rechts, oben und unten an. Der Standardwert dieser Option ist null.

**-rotate angle**
: Dieser Wert definiert einen Rotationswinkel für die Anzeige der Seite. Erlaubte Werte sind Vielfache von 90. Der Standardwert dieser Option ist null.

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
