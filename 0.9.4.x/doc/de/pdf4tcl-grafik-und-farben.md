# pdf4tcl Grafik und Farben

Dieses Dokument behandelt die Grafik-API von pdf4tcl: Linien, Rechtecke,
Kreise, Farben, Transparenz und Transformationen. Es zeigt, wie
geometrische Formen gezeichnet und gestaltet werden.

## Farben

### RGB-Farbmodell

pdf4tcl verwendet RGB-Farben mit Werten von 0.0 bis 1.0, nicht 0 bis 255.

```tcl
# Schwarz
$pdf setFillColor 0.0 0.0 0.0

# Weiss
$pdf setFillColor 1.0 1.0 1.0

# Rot
$pdf setFillColor 1.0 0.0 0.0

# 50% Grau
$pdf setFillColor 0.5 0.5 0.5
```

### Fuell- und Strichfarbe

Es gibt zwei Farbkanaele: Fuellfarbe (fuer Text und gefuellte Formen) und
Strichfarbe (fuer Linien und Umrisse).

```tcl
# Fuellfarbe (Text, gefuellte Formen)
$pdf setFillColor R G B

# Strichfarbe (Linien, Umrisse)
$pdf setStrokeColor R G B
```

Wichtig: Beide Farben bleiben aktiv bis sie erneut gesetzt werden.
Nach farbigem Text oder Formen muessen die Farben zurueckgesetzt werden.

```tcl
# Farbigen Text schreiben
$pdf setFillColor 0.8 0.0 0.0
$pdf text "Roter Text" -x 50 -y 100

# Farbe zuruecksetzen
$pdf setFillColor 0.0 0.0 0.0
$pdf text "Schwarzer Text" -x 50 -y 120
```

### Umrechnung von Hex und 0-255

```tcl
proc rgb255_to_pdf {r g b} {
    return [list \
        [expr {$r / 255.0}] \
        [expr {$g / 255.0}] \
        [expr {$b / 255.0}]]
}

proc hex_to_rgb {hex} {
    set hex [string trimleft $hex "#"]
    scan $hex "%2x%2x%2x" r g b
    return [list \
        [expr {$r / 255.0}] \
        [expr {$g / 255.0}] \
        [expr {$b / 255.0}]]
}

# Verwendung
lassign [hex_to_rgb "#FF6347"] r g b
$pdf setFillColor $r $g $b
```

### Nuetzliche Farbtabelle

| Farbe       | R    | G    | B    | Verwendung            |
|-------------|------|------|------|-----------------------|
| Schwarz     | 0.0  | 0.0  | 0.0  | Text, Linien          |
| Weiss       | 1.0  | 1.0  | 1.0  | Hintergrund           |
| Hellgrau    | 0.9  | 0.9  | 0.9  | Tabellen-Header       |
| Mittelgrau  | 0.6  | 0.6  | 0.6  | Hilfslinien           |
| Dunkelgrau  | 0.3  | 0.3  | 0.3  | Sekundaerer Text      |
| Rot         | 0.8  | 0.0  | 0.0  | Fehler, Warnungen     |
| Dunkelblau  | 0.0  | 0.0  | 0.6  | Links, Ueberschriften |
| Dunkelgruen | 0.0  | 0.4  | 0.0  | Erfolg, positiv       |

## Linien

### Einfache Linie

```tcl
$pdf setStrokeColor 0 0 0
$pdf setLineWidth 1
$pdf line 50 100 300 100
```

Parameter: X1, Y1 (Startpunkt), X2, Y2 (Endpunkt).

### Linienbreite

```tcl
$pdf setLineWidth 0.5    ;# Fein (Grids, Hilfslinien)
$pdf setLineWidth 1      ;# Standard
$pdf setLineWidth 2      ;# Dick (Rahmen)
$pdf setLineWidth 5      ;# Sehr dick (Diagramme)
```

### Gestrichelte Linien

```tcl
# Gestrichelt: 5pt Strich, 3pt Luecke
$pdf setLineDash 5 3
$pdf line 50 100 300 100

# Gepunktet: 1pt Strich, 3pt Luecke
$pdf setLineDash 1 3
$pdf line 50 120 300 120

# Zurueck auf durchgezogen
$pdf setLineDash 0 0
```

## Rechtecke

### Rahmen

```tcl
$pdf setStrokeColor 0 0 0
$pdf setLineWidth 1
$pdf rectangle 50 100 200 80
```

Parameter: X, Y, Breite, Hoehe.

### Gefuellt

```tcl
$pdf setFillColor 0.9 0.9 0.9
$pdf rectangle 50 100 200 80 -filled 1
```

### Gefuellt mit Rahmen

```tcl
$pdf setFillColor 0.9 0.9 0.9
$pdf setStrokeColor 0 0 0
$pdf setLineWidth 0.5
$pdf rectangle 50 100 200 80 -filled 1 -stroke 1
```

### Tabellenzelle mit Hintergrund

```tcl
proc drawCell {pdf x y w h text {bg ""}} {
    if {$bg ne ""} {
        lassign $bg r g b
        $pdf setFillColor $r $g $b
        $pdf rectangle $x $y $w $h -filled 1
    }
    $pdf setStrokeColor 0.6 0.6 0.6
    $pdf setLineWidth 0.5
    $pdf rectangle $x $y $w $h
    $pdf setFillColor 0 0 0
    $pdf setFont 10 Helvetica
    set textY [expr {$y + int(($h - 10) / 0.45)}]
    $pdf text $text -x [expr {$x + 4}] -y $textY
}
```

## Kreise und Ellipsen

### Kreis

```tcl
$pdf circle 200 300 50
```

Parameter: Mittelpunkt X, Mittelpunkt Y, Radius.

### Gefuellter Kreis

```tcl
$pdf setFillColor 0.2 0.4 0.8
$pdf circle 200 300 50 -filled 1
```

### Ellipse

```tcl
$pdf oval 200 300 80 40
```

Parameter: Mittelpunkt X, Mittelpunkt Y, Radius-X, Radius-Y.

## Pfade und Bezier-Kurven

### Polygon

```tcl
# Dreieck
$pdf polygon 100 200 200 100 300 200
```

Die Koordinaten sind Paare von X,Y-Werten fuer jeden Eckpunkt.

### Bezier-Kurve

```tcl
# Kubische Bezier-Kurve
$pdf curve 50 300 100 200 200 200 250 300
```

Parameter: Startpunkt, Kontrollpunkt 1, Kontrollpunkt 2, Endpunkt.

## Transformationen

### Grundkonzept

In pdf4tcl werden nicht einzelne Objekte transformiert, sondern das
gesamte Koordinatensystem. Alle nachfolgenden Zeichenbefehle sind
betroffen. Daher ist `gsave`/`grestore` essenziell.

### gsave und grestore

```tcl
# Koordinatensystem sichern
$pdf gsave

# Transformation anwenden
$pdf rotate 45
$pdf text "Rotiert" -x 0 -y 0

# Koordinatensystem zuruecksetzen
$pdf grestore

# Jetzt wieder normal
$pdf text "Normal" -x 100 -y 100
```

Ohne `gsave`/`grestore` wuerden alle weiteren Zeichenoperationen
ebenfalls rotiert sein.

### Rotation

```tcl
$pdf gsave
$pdf translate 200 400    ;# Zum Rotationspunkt verschieben
$pdf rotate 45            ;# Um 45 Grad drehen
$pdf text "45 Grad" -x 0 -y 0
$pdf grestore
```

Die Rotation erfolgt immer um den aktuellen Ursprung. Daher muss zuerst
zum gewuenschten Drehpunkt verschoben werden.

### Skalierung

```tcl
$pdf gsave
$pdf scale 2.0 2.0        ;# 200% vergroessern
$pdf text "Gross" -x 50 -y 50
$pdf grestore
```

### Translation (Verschiebung)

```tcl
$pdf gsave
$pdf translate 100 200    ;# Ursprung verschieben
$pdf text "Verschoben" -x 0 -y 0
$pdf grestore
```

### Kombinierte Transformation

Transformationen koennen kombiniert werden. Die Reihenfolge ist wichtig,
da sie aufeinander aufbauen.

```tcl
$pdf gsave
$pdf translate 300 400    ;# 1. Zum Punkt verschieben
$pdf rotate 30            ;# 2. Drehen
$pdf scale 0.5 0.5        ;# 3. Verkleinern
$pdf text "Kombiniert" -x 0 -y 0
$pdf grestore
```

## Zeichenbefehle-Referenz

```tcl
# Linie
$pdf line $x1 $y1 $x2 $y2

# Rechteck (nur Rahmen)
$pdf rectangle $x $y $width $height

# Rechteck (gefuellt)
$pdf rectangle $x $y $width $height -filled 1

# Rechteck (gefuellt + Rahmen)
$pdf rectangle $x $y $width $height -filled 1 -stroke 1

# Kreis
$pdf circle $cx $cy $radius
$pdf circle $cx $cy $radius -filled 1

# Linienbreite
$pdf setLineWidth 0.5

# Farben (RGB, 0.0 bis 1.0)
$pdf setStrokeColor $r $g $b
$pdf setFillColor $r $g $b

# Strichlinie
$pdf setLineDash $dash $gap

# Transparenz
$pdf setAlpha 0.5           ;# Fill und Stroke auf 50%
$pdf setAlpha 0.3 -fill     ;# Nur Fill
$pdf setAlpha 1.0 -stroke   ;# Nur Stroke

# Transformation
$pdf gsave
$pdf translate $dx $dy
$pdf rotate $degrees
$pdf scale $sx $sy
$pdf grestore
```

## Transparenz (setAlpha / getAlpha)

Ab Version 0.9.4.10 unterstuetzt pdf4tcl Transparenz ueber `setAlpha`
und `getAlpha`. Der Alpha-Wert liegt zwischen 0.0 (unsichtbar) und
1.0 (undurchsichtig, Standard).

```tcl
# Fill und Stroke gemeinsam setzen
$pdf setAlpha 0.5

# Nur Fill-Alpha (fuer Flaechen/Text)
$pdf setFillColor 1 0 0
$pdf setAlpha 0.4 -fill
$pdf rectangle 50 500 200 100 -filled 1

# Nur Stroke-Alpha (fuer Konturlinien)
$pdf setAlpha 1.0 -stroke
$pdf setLineStyle 2
$pdf rectangle 50 500 200 100

# Aktuellen Alpha-Wert abfragen
set a [$pdf getAlpha -fill]
```

`gsave`/`grestore` speichern und stellen den Alpha-Wert zurueck:

```tcl
$pdf setAlpha 0.3
$pdf gsave
$pdf rectangle 60 400 100 50 -filled 1   ;# alpha 0.3
$pdf grestore
$pdf rectangle 180 400 100 50 -filled 1  ;# wieder alpha 1.0
```

**Hinweis:** Bei PDF/A-1 (`-pdfa 1b`) ist Transparenz nicht erlaubt.
pdf4tcl unterdrueckt `/Group /S /Transparency` automatisch, aber
`setAlpha`-Werte kleiner 1.0 koennen veraPDF-Fehler erzeugen.


## Praktisches Beispiel: Horizontale Trennlinie

```tcl
proc drawSeparator {pdf x y width {color "0.6 0.6 0.6"}} {
    lassign $color r g b
    $pdf setStrokeColor $r $g $b
    $pdf setLineWidth 0.5
    $pdf line $x $y [expr {$x + $width}] $y
    $pdf setStrokeColor 0 0 0
}
```

Wichtig: Nie `string repeat "-"` als Separator verwenden.
Immer `$pdf line` fuer pixelgenaue Positionierung nutzen.
