# pdf4tcl Text und Fonts

Dieses Dokument behandelt die Text-API, die 14 Standard-PDF-Fonts und
das Encoding in pdf4tcl. Nach der Lektuere koennen Texte sicher
positioniert, ausgerichtet und formatiert werden.

## Text schreiben

### Einfache Textausgabe

```tcl
$pdf setFont 12 Helvetica
$pdf text "Hello World" -x 50 -y 100
```

Der Font bleibt aktiv bis zum naechsten `setFont`-Aufruf. Die Y-Position
bezeichnet die Baseline des Textes, nicht die Oberkante.

### Die Baseline

Die Y-Position bei `$pdf text` ist immer die Baseline (Grundlinie).
Buchstaben wie "g", "y" oder "p" ragen nach unten ueber die Baseline
hinaus (Descender). Buchstaben wie "A" oder "h" ragen nach oben
(Ascender).

```
     "Hello World"
Y=100 ----------------  <-- Baseline (wo Y zeigt)
          g  y           <-- Descender unter Baseline
```

Konsequenz: Die Y-Position muss mindestens so gross sein wie die
Schriftgroesse, damit der Text vollstaendig sichtbar ist.

```tcl
# FALSCH - Text wird abgeschnitten
$pdf setFont 18 Helvetica
$pdf text "Test" -x 50 -y 0

# RICHTIG - mindestens Font-Groesse als Y-Wert
$pdf setFont 18 Helvetica
$pdf text "Test" -x 50 -y 20
```

### Text ausrichten

```tcl
# Links (Standard)
$pdf text "Links" -x 50 -y 100

# Zentriert
$pdf text "Zentriert" -x 297 -y 100 -align center

# Rechts
$pdf text "Rechts" -x 545 -y 100 -align right
```

Bei `-align center` ist die X-Position die Mitte des Textes.
Bei `-align right` ist die X-Position das rechte Ende.

### Textbreite berechnen

```tcl
$pdf setFont 12 Helvetica
set breite [$pdf getStringWidth "Beispieltext"]
# --> Breite in Points
```

Die Textbreite ist abhaengig vom aktuell gesetzten Font und der
Schriftgroesse. Sie wird benoetigt fuer manuelle Zentrierung, Tabellen
und Layoutberechnungen.

### Zeilenhoehe und Abstaende

```tcl
set fontSize 12
set lineHeight [expr {$fontSize * 1.4}]  ;# 140% der Font-Groesse

# Mehrere Zeilen
for {set i 0} {$i < 10} {incr i} {
    set y [expr {50 + $i * $lineHeight}]
    $pdf text "Zeile $i" -x 50 -y $y
}
```

Die Faustregel fuer die Zeilenhoehe ist 120% bis 150% der Schriftgroesse.
Fuer 12pt Text ergibt das etwa 14 bis 18pt Zeilenabstand.

## Die 14 Standard-Fonts

PDF definiert 14 Standard-Fonts, die in jedem PDF-Viewer vorhanden sind.
Diese Fonts werden nicht ins PDF eingebettet und garantieren damit
kleine Dateien und universelle Verfuegbarkeit.

### Helvetica (Sans-Serif)

| Font-Name             | Verwendung            |
|-----------------------|-----------------------|
| Helvetica             | Fliesstext, Formulare |
| Helvetica-Bold        | Ueberschriften        |
| Helvetica-Oblique     | Hervorhebung          |
| Helvetica-BoldOblique | Starke Hervorhebung   |

Wichtig: Bei Helvetica heisst es `-Oblique`, nicht `-Italic`.

```tcl
$pdf setFont 12 Helvetica
$pdf setFont 12 Helvetica-Bold
$pdf setFont 12 Helvetica-Oblique
$pdf setFont 12 Helvetica-BoldOblique
```

### Times (Serif)

| Font-Name          | Verwendung             |
|--------------------|------------------------|
| Times-Roman        | Formelle Dokumente     |
| Times-Bold         | Ueberschriften         |
| Times-Italic       | Hervorhebung           |
| Times-BoldItalic   | Starke Hervorhebung    |

Wichtig: Bei Times heisst es `-Italic`, nicht `-Oblique`.

```tcl
$pdf setFont 12 Times-Roman
$pdf setFont 12 Times-Bold
$pdf setFont 12 Times-Italic
$pdf setFont 12 Times-BoldItalic
```

### Courier (Monospace)

| Font-Name            | Verwendung           |
|----------------------|----------------------|
| Courier              | Code, Tabellen       |
| Courier-Bold         | Hervorgehobener Code |
| Courier-Oblique      | Code kursiv          |
| Courier-BoldOblique  | Code fett kursiv     |

```tcl
$pdf setFont 10 Courier
$pdf setFont 10 Courier-Bold
$pdf setFont 10 Courier-Oblique
$pdf setFont 10 Courier-BoldOblique
```

### Spezialfonts

| Font-Name    | Verwendung          |
|--------------|---------------------|
| Symbol       | Griechische Zeichen |
| ZapfDingbats | Sonderzeichen       |

### Haeufige Fehler bei Font-Namen

```tcl
# FALSCH - Name existiert nicht
$pdf setFont 12 Helvetica-Italic     ;# Heisst Oblique!
$pdf setFont 12 Times-Oblique        ;# Heisst Italic!
$pdf setFont 12 helvetica            ;# Gross/Klein beachten!
$pdf setFont 12 "Helvetica Bold"     ;# Kein Leerzeichen!

# RICHTIG
$pdf setFont 12 Helvetica-Oblique
$pdf setFont 12 Times-Italic
$pdf setFont 12 Helvetica
$pdf setFont 12 Helvetica-Bold
```

## Encoding

### WinAnsi / CP1252

Die Standard-Fonts unterstuetzen WinAnsi/CP1252. Damit sind
westeuropaeische Zeichen abgedeckt, darunter deutsche Umlaute
(ae, oe, ue, ss), franzoesische Akzente und skandinavische Zeichen.

Ab Version 0.9.4.9 enthalten Standard-Fonts automatisch einen
ToUnicode-CMap-Stream. Damit ist korrekte Text-Extraktion und
Copy-Paste aus PDF-Viewern moeglich (vorher: nur Fragezeichen beim
Kopieren von Sonderzeichen).

```tcl
# Funktioniert (WinAnsi)
$pdf text "Gruesse aus Muenchen" -x 50 -y 100
$pdf text "Cafe, Noel, Resume" -x 50 -y 120

# Funktioniert NICHT (ausserhalb WinAnsi)
$pdf text "Chinesische Zeichen" -x 50 -y 140    ;# Nur Fragezeichen
```

### Unicode-Probleme vermeiden

Zeichen ausserhalb von WinAnsi/CP1252 werden nicht korrekt dargestellt.
Fuer volle Unicode-Unterstuetzung muessen TrueType-Fonts eingebettet
werden, was pdf4tcl in der Basisversion nicht unterstuetzt.

Typische problematische Zeichen und ihre Ersetzungen:

| Zeichen      | Beschreibung     | Ersetzung  |
|--------------|------------------|------------|
| Box-Drawing  | Tabellenrahmen   | `+ - \|`   |
| Haekchen     | Checkboxen       | `[x] [ ]`  |
| Aufzaehlungspunkt | Bullet      | `*`        |
| Auslassung   | Ellipse          | `...`      |

```tcl
# Sanitization-Funktion fuer Standard-Fonts
proc sanitize_for_pdf {text} {
    set map {
        "\u2502" "|"   "\u2500" "-"   "\u253C" "+"
        "\u2611" "[x]" "\u2610" "[ ]"
        "\u2022" "*"   "\u2026" "..."
    }
    return [string map $map $text]
}
```

## TextBox (Textblock mit Umbruch)

### drawTextBox

Fuer laengere Texte mit automatischem Zeilenumbruch:

```tcl
$pdf setFont 12 Helvetica
$pdf drawTextBox 50 100 200 300 "Dies ist ein laengerer Text, \
    der automatisch umbrochen wird, wenn er die Breite \
    der TextBox ueberschreitet." -align left
```

Parameter: X-Position, Y-Position, Breite, Hoehe, Text.

### Ausrichtungsoptionen

```tcl
# Linksbuendig (Standard)
$pdf drawTextBox 50 100 200 300 $text -align left

# Zentriert
$pdf drawTextBox 50 100 200 300 $text -align center

# Rechtsbuendig
$pdf drawTextBox 50 100 200 300 $text -align right

# Blocksatz
$pdf drawTextBox 50 100 200 300 $text -align justify
```

### Zeilenanzahl ermitteln

```tcl
$pdf drawTextBox 50 100 200 300 $text -linesvar numLines
puts "Anzahl Zeilen: $numLines"
```

### Trockenlauf (Dryrun)

```tcl
# Nur berechnen, nicht zeichnen
$pdf drawTextBox 50 100 200 300 $text \
    -linesvar numLines -dryrun 1

# Benoetigte Hoehe berechnen
set benoetigteHoehe [expr {$numLines * $lineHeight}]
```

## Praktische Tipps

### Ueberschriften-Hierarchie

```tcl
proc setHeadingFont {pdf level} {
    set sizes {24 20 16 14 12 11}
    set size [lindex $sizes [expr {$level - 1}]]
    $pdf setFont $size Helvetica-Bold
}

proc setBodyFont {pdf} {
    $pdf setFont 11 Times-Roman
}
```

### Seitenzahl zeichnen

```tcl
proc drawPageNumber {pdf pagenum ctx} {
    set centerX [expr {[dict get $ctx PW] / 2.0}]
    set bottomY [expr {[dict get $ctx PH] - 30}]
    $pdf setFont 10 Helvetica
    $pdf text "Seite $pagenum" -x $centerX -y $bottomY -align center
}
```

### Text in Tabellenzellen positionieren

Die Baseline-Positionierung erfordert besondere Aufmerksamkeit in
Tabellenzellen. Naive Zentrierung setzt den Text zu hoch.

```tcl
# FALSCH - Text ragt ueber Zellenrahmen
set textY [expr {$y0 + int(($cellH - $fontSize) / 2.0)}]

# RICHTIG - Baseline tief genug setzen
set textY [expr {$y0 + int(($cellH - $fontSize) / 0.45)}]
```

Der Ascent (Hoehe ueber Baseline) betraegt bei Helvetica ca. 70-80%
der fontSize. Bei Division durch 2.0 liegt die Baseline zu nah an
der Oberkante der Zelle.
