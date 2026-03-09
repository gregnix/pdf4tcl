# pdf4tcl Grundlagen

Dieses Dokument behandelt Installation, Koordinatensystem, Einheiten und
die ersten Schritte mit pdf4tcl. Es richtet sich an Einsteiger, die mit
Tcl/Tk bereits vertraut sind und nun PDF-Dokumente erzeugen moechten.

## Installation

### Voraussetzungen

pdf4tcl benoetigt Tcl/Tk ab Version 8.6. Die empfohlene Version von
pdf4tcl ist 0.9.4. Optional koennen folgende Tools installiert werden:

- poppler-utils: `pdfinfo` und `pdftotext` fuer PDF-Validierung
- mupdf: Leichtgewichtiger PDF-Viewer
- ghostscript: Fuer PDF/A-Konvertierung

### Installation ueber Paketmanager

```bash
# Debian/Ubuntu
sudo apt-get install tcllib

# Fedora
sudo dnf install tcllib

# macOS
brew install tcllib
```

### Lokale Installation (projektspezifisch)

```tcl
#!/usr/bin/env tclsh

# Lokale Version laden
lappend auto_path [file join [file dirname [info script]] pdf4tcl094]
package require pdf4tcl 0.9
```

### Systemweite Installation

```bash
mkdir -p ~/.local/lib/tcl8.6/pdf4tcl0.9

cp pdf4tcl.tcl ~/.local/lib/tcl8.6/pdf4tcl0.9/
echo "package ifneeded pdf4tcl 0.9 [list source [file join \$dir pdf4tcl.tcl]]" \
    > ~/.local/lib/tcl8.6/pdf4tcl0.9/pkgIndex.tcl
```

### Installation pruefen

```tcl
#!/usr/bin/env tclsh

if {[catch {package require pdf4tcl 0.9} err]} {
    puts "ERROR: pdf4tcl nicht gefunden - $err"
    exit 1
}

puts "pdf4tcl Version: [package require pdf4tcl]"

set pdf [::pdf4tcl::new %AUTO% -paper a4 -orient true]
$pdf startPage
$pdf setFont 18 Helvetica-Bold
$pdf text "Installation successful!" -x 50 -y 50
$pdf endPage

set outfile "test-installation.pdf"
$pdf write -file $outfile
$pdf destroy

puts "Test-PDF erstellt: $outfile"
```

## Koordinatensystem

Das Koordinatensystem ist die haeufigste Fehlerquelle bei Anfaengern.
pdf4tcl unterstuetzt zwei Modi, die ueber `-orient` gesteuert werden.

### Mode 1: orient true (empfohlen)

Der Ursprung (0,0) liegt oben links. Y waechst nach unten, X nach rechts.
Dies entspricht dem Verhalten von Tk Canvas und HTML.

```
(0,0) ---------------------> X
  |
  |    Dokument
  |
  v
  Y
```

```tcl
set pdf [pdf4tcl::pdf4tcl create %AUTO% -paper a4 -orient true]
$pdf startPage

# Text oben
$pdf text "Oben" -x 50 -y 50      ;# Y=50 --> nahe dem oberen Rand

# Text unten
$pdf text "Unten" -x 50 -y 800    ;# Y=800 --> nahe dem unteren Rand

$pdf endPage
```

### Mode 2: orient false (mathematisch)

Der Ursprung (0,0) liegt unten links. Y waechst nach oben.
Dies entspricht dem kartesischen Koordinatensystem.

```
  Y
  ^
  |
  |    Dokument
  |
(0,0) ---------------------> X
```

```tcl
set pdf [pdf4tcl::pdf4tcl create %AUTO% -paper a4 -orient false]
$pdf startPage

# Text unten
$pdf text "Unten" -x 50 -y 50     ;# Y=50 --> nahe dem unteren Rand

# Text oben
$pdf text "Oben" -x 50 -y 800     ;# Y=800 --> nahe dem oberen Rand

$pdf endPage
```

### Empfehlung

`-orient` immer explizit setzen. Der Default-Wert ist `1` (orient true),
aber das ist nicht offensichtlich. Code der den Default annimmt, kann
sich bei Versionswechseln falsch verhalten.

```tcl
# RICHTIG - immer explizit
set pdf [::pdf4tcl::new %AUTO% -paper a4 -orient true]

# FALSCH - abhaengig vom Default
set pdf [::pdf4tcl::new %AUTO% -paper a4]
```

### drawTextBox und orient

Das `y`-Argument von `drawTextBox` haengt vom orient-Modus ab:

- Mit `-orient true`: `y` ist die **Oberkante** der Box (Text fuellt nach unten)
- Mit `-orient false`: `y` ist die **Unterkante** der Box (Text fuellt nach oben)

```tcl
# orient true (empfohlen): y = Oberkante
set pdf [::pdf4tcl::new %AUTO% -paper a4 -orient true]
$pdf startPage
$pdf setFont 11 Helvetica
$pdf text "Ueberschrift" -x 50 -y 100
$pdf drawTextBox 50 120 400 60 "Dieser Text beginnt bei y=120." -align left

# orient false: y = Unterkante -- Box fuellt von y aufwaerts bis y+height
set pdf [::pdf4tcl::new %AUTO% -paper a4 -orient false]
$pdf startPage
$pdf setFont 11 Helvetica
$pdf text "Ueberschrift" -x 50 -y 700
# Oberkante = 680, Unterkante = 620, Hoehe 60
$pdf drawTextBox 50 620 400 60 "Text zwischen 620 und 680." -align left
```

Faustregel: mit `-orient false` und festen y-Werten immer ausreichend
Abstand zwischen Beschriftung und Box-y einplanen.

### setFont und -unit

`setFont size fontname` interpretiert `size` in der konfigurierten
Einheit, nicht immer in Punkten:

```tcl
# -unit mm: setFont 9 = 9mm = ca. 25.5pt -- viel zu gross!
set pdf [::pdf4tcl::new %AUTO% -paper a4 -orient true -unit mm]
$pdf setFont 9 Helvetica     ;# FALSCH: 9mm Schrift

# Korrekt 1: explizit Punkte angeben
$pdf setFont 9p Helvetica    ;# RICHTIG: 9pt

# Korrekt 2: kein -unit, alles in Punkten
set pdf [::pdf4tcl::new %AUTO% -paper a4 -orient true]
$pdf setFont 9 Helvetica     ;# RICHTIG: 9pt
```

## Einheiten

### Points als Grundeinheit

pdf4tcl rechnet intern in Points (pt). Ein Point entspricht 1/72 Inch.
Die Umrechnung:

| Von       | Nach    | Faktor            |
|-----------|---------|-------------------|
| 1 inch    | pt      | 72                |
| 1 mm      | pt      | 2.8346            |
| 1 pt      | mm      | 0.3528            |
| 1 cm      | pt      | 28.346            |

### Konvertierungsfunktionen

```tcl
proc mm_to_pt {mm} {
    return [expr {$mm / 25.4 * 72.0}]
}

proc cm_to_pt {cm} {
    return [expr {$cm / 2.54 * 72.0}]
}

proc pt_to_mm {pt} {
    return [expr {$pt * 25.4 / 72.0}]
}
```

### Typische Werte fuer A4

```tcl
mm_to_pt 210    ;# --> 595.276 pt (A4 Breite)
mm_to_pt 297    ;# --> 841.890 pt (A4 Hoehe)
mm_to_pt 20     ;# --> 56.693 pt (2cm Rand)
mm_to_pt 10     ;# --> 28.346 pt (1cm Rand)
```

### A4-Abmessungen

| Format | mm          | pt              | inch           |
|--------|-------------|-----------------|----------------|
| A4     | 210 x 297   | 595.276 x 841.890 | 8.27 x 11.69 |
| A3     | 297 x 420   | 842 x 1191     | 11.69 x 16.54  |
| A5     | 148 x 210   | 420 x 595      | 5.83 x 8.27    |
| Letter | 216 x 279   | 612 x 792      | 8.5 x 11       |

## Erste Schritte

### Das minimale PDF

```tcl
#!/usr/bin/env tclsh
package require pdf4tcl 0.9

set pdf [::pdf4tcl::new %AUTO% -paper a4 -orient true]
$pdf startPage
$pdf setFont 18 Helvetica-Bold
$pdf text "Hello World!" -x 50 -y 100
$pdf endPage
$pdf write -file hello.pdf
$pdf destroy
```

### Zeile fuer Zeile erklaert

`::pdf4tcl::new` erstellt ein neues PDF-Objekt. `%AUTO%` generiert
automatisch einen Befehlsnamen (z.B. `pdf1`). Mit `-paper a4` wird
das Papierformat A4 (595 x 842 pt) gesetzt. `-orient true` legt den
Koordinatenursprung auf oben links fest.

`startPage` beginnt eine neue Seite. `setFont` setzt Schriftgroesse und
Schriftart. `text` schreibt Text an die angegebene Position. `endPage`
schliesst die Seite ab. `write -file` speichert das PDF. `destroy`
gibt das Objekt frei.

### Text mit verschiedenen Fonts

```tcl
#!/usr/bin/env tclsh
package require pdf4tcl 0.9

set pdf [::pdf4tcl::new %AUTO% -paper a4 -orient true]
$pdf startPage

# Ueberschrift
$pdf setFont 24 Helvetica-Bold
$pdf text "Mein Dokument" -x 50 -y 60

# Fliesstext
$pdf setFont 12 Times-Roman
$pdf text "Dies ist ein Absatz in Times Roman." -x 50 -y 100

# Hervorgehobener Text
$pdf setFont 12 Helvetica-Bold
$pdf text "Wichtig:" -x 50 -y 130
$pdf setFont 12 Helvetica
$pdf text "Normaler Text nach der Hervorhebung." -x 110 -y 130

# Monospace fuer Code
$pdf setFont 10 Courier
$pdf text "puts \"Hello World\"" -x 50 -y 170

$pdf endPage
$pdf write -file fonts-demo.pdf
$pdf destroy
```

### Farben und Formen

```tcl
#!/usr/bin/env tclsh
package require pdf4tcl 0.9

set pdf [::pdf4tcl::new %AUTO% -paper a4 -orient true]
$pdf startPage

# Farbiger Text
$pdf setFont 16 Helvetica-Bold
$pdf setFillColor 0.8 0.0 0.0
$pdf text "Roter Text" -x 50 -y 50

# Linie
$pdf setStrokeColor 0.0 0.0 0.0
$pdf setLineWidth 1
$pdf line 50 70 300 70

# Gefuelltes Rechteck
$pdf setFillColor 0.9 0.9 0.9
$pdf rectangle 50 90 250 80 -filled 1

# Text auf Rechteck
$pdf setFillColor 0.0 0.0 0.0
$pdf setFont 12 Helvetica
$pdf text "Text auf grauem Hintergrund" -x 60 -y 120

$pdf endPage
$pdf write -file farben-demo.pdf
$pdf destroy
```

### Speichern und Ausgabe

```tcl
# In Datei speichern
$pdf write -file output.pdf

# Als String zurueckgeben
set pdfdata [$pdf get]

# Verzeichnis sicherstellen
file mkdir output
$pdf write -file [file join output dokument.pdf]
```

## Projektstruktur

Eine empfohlene Projektstruktur fuer pdf4tcl-Projekte:

```
meinprojekt/
|-- src/
|   |-- generate.tcl        # Haupt-Script
|   |-- helpers.tcl          # Hilfsfunktionen
|-- output/                  # Generierte PDFs
|-- data/                    # Eingabedaten
|-- images/                  # Logos und Bilder
```

## Naechste Schritte

- Text-API und Fonts: siehe pdf4tcl-text-und-fonts.md
- Grafik und Farben: siehe pdf4tcl-grafik-und-farben.md
- Layout-Patterns: siehe pdf4tcl-layout-patterns.md
