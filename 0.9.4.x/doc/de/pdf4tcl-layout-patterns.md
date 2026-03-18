# pdf4tcl Layout-Patterns

Dieses Dokument behandelt wiederverwendbare Layout-Muster, die
Helper-Library und professionelle Seitengestaltung. Es zeigt, wie
pdf4tcl-Code strukturiert und wartbar bleibt.

## Das Problem

pdf4tcl ist absichtlich low-level gehalten. Wiederkehrende Aufgaben
wie Margin-Berechnung, Seitenzentrierung und Seitenzahlen erfordern
immer wieder denselben Code:

```tcl
# Immer wieder: mm nach pt umrechnen
set x_pt [expr {20.0 / 25.4 * 72.0}]

# Immer wieder: Margins berechnen
set margin_pt [expr {20.0 / 25.4 * 72.0}]
set sx $margin_pt
set ex [expr {595.276 - $margin_pt}]
```

Die Loesung sind Helper-Funktionen und das Page-Context-Pattern.

## Page Context Pattern

### Zentrales Layout-Dictionary

Das wichtigste Pattern: ein Dictionary mit allen Layout-Informationen.

```tcl
proc create_page_context {paper margin_mm orient} {
    array set sizes {
        a4     {595.276 841.890}
        letter {612 792}
        a3     {842 1191}
        a5     {420 595}
    }
    
    lassign $sizes($paper) pw ph
    
    set margin_pt [expr {$margin_mm * 72.0 / 25.4}]
    
    set sx $margin_pt
    set sy $margin_pt
    set sw [expr {$pw - 2 * $margin_pt}]
    set sh [expr {$ph - 2 * $margin_pt}]
    
    return [dict create \
        PW $pw \
        PH $ph \
        margin_pt $margin_pt \
        SX $sx \
        SY $sy \
        SW $sw \
        SH $sh \
        orient $orient]
}
```

### Verwendung

```tcl
set ctx [create_page_context a4 20 true]

set sx [dict get $ctx SX]    ;# Safe X (linker Rand)
set sy [dict get $ctx SY]    ;# Safe Y (oberer Rand)
set sw [dict get $ctx SW]    ;# Safe Width (nutzbare Breite)
set sh [dict get $ctx SH]    ;# Safe Height (nutzbare Hoehe)

# Text im sicheren Bereich
$pdf text "Im Safe Area" -x $sx -y $sy
```

Vorteil: Keine Magic Numbers im Code. Alle Abmessungen an einer Stelle
definiert.

## Helper-Funktionen

### Einheiten-Konvertierung

```tcl
proc mm {mm} {
    return [expr {$mm / 25.4 * 72.0}]
}

proc cm {cm} {
    return [expr {$cm / 2.54 * 72.0}]
}
```

### Zentrierter Text

```tcl
proc center_text {pdf ctx text y} {
    set centerX [expr {[dict get $ctx PW] / 2.0}]
    $pdf text $text -x $centerX -y $y -align center
}
```

### Seitenzahl

```tcl
proc add_page_number {pdf ctx pagenum {total ""}} {
    set centerX [expr {[dict get $ctx PW] / 2.0}]
    set bottomY [expr {[dict get $ctx PH] - 25}]
    $pdf setFont 9 Helvetica
    if {$total ne ""} {
        $pdf text "Seite $pagenum von $total" \
            -x $centerX -y $bottomY -align center
    } else {
        $pdf text "Seite $pagenum" \
            -x $centerX -y $bottomY -align center
    }
}
```

### Horizontale Trennlinie

```tcl
proc draw_hr {pdf ctx y {color {0.6 0.6 0.6}}} {
    lassign $color r g b
    set sx [dict get $ctx SX]
    set sw [dict get $ctx SW]
    $pdf setStrokeColor $r $g $b
    $pdf setLineWidth 0.5
    $pdf line $sx $y [expr {$sx + $sw}] $y
    $pdf setStrokeColor 0 0 0
}
```

### Debug-Raster

```tcl
proc draw_grid {pdf ctx {step 50}} {
    set pw [dict get $ctx PW]
    set ph [dict get $ctx PH]
    
    $pdf setStrokeColor 0.9 0.9 0.9
    $pdf setLineWidth 0.25
    
    # Vertikale Linien
    for {set x 0} {$x <= $pw} {incr x $step} {
        $pdf line $x 0 $x $ph
    }
    
    # Horizontale Linien
    for {set y 0} {$y <= $ph} {incr y $step} {
        $pdf line 0 $y $pw $y
    }
    
    # Beschriftung
    $pdf setFont 6 Helvetica
    $pdf setFillColor 0.7 0.7 0.7
    for {set x 0} {$x <= $pw} {incr x $step} {
        $pdf text $x -x $x -y 8
    }
    for {set y $step} {$y <= $ph} {incr y $step} {
        $pdf text $y -x 2 -y $y
    }
    
    $pdf setFillColor 0 0 0
    $pdf setStrokeColor 0 0 0
}
```

## Spalten-Layouts

### Zwei Spalten

```tcl
proc two_columns {pdf ctx leftText rightText y {gap 20}} {
    set sx [dict get $ctx SX]
    set sw [dict get $ctx SW]
    set colW [expr {($sw - $gap) / 2.0}]
    
    set leftX $sx
    set rightX [expr {$sx + $colW + $gap}]
    
    $pdf drawTextBox $leftX $y $colW 500 $leftText -align left
    $pdf drawTextBox $rightX $y $colW 500 $rightText -align left
}
```

### Drei Spalten

```tcl
proc three_columns {pdf ctx texts y {gap 15}} {
    set sx [dict get $ctx SX]
    set sw [dict get $ctx SW]
    set colW [expr {($sw - 2 * $gap) / 3.0}]
    
    for {set i 0} {$i < 3} {incr i} {
        set x [expr {$sx + $i * ($colW + $gap)}]
        $pdf drawTextBox $x $y $colW 500 [lindex $texts $i] -align left
    }
}
```

## Kopf- und Fusszeilen

### Header-Funktion

```tcl
proc draw_header {pdf ctx title {subtitle ""}} {
    set sx [dict get $ctx SX]
    set sy [dict get $ctx SY]
    set sw [dict get $ctx SW]
    
    $pdf setFont 14 Helvetica-Bold
    $pdf text $title -x $sx -y $sy
    
    if {$subtitle ne ""} {
        $pdf setFont 10 Helvetica
        $pdf setFillColor 0.4 0.4 0.4
        $pdf text $subtitle -x $sx -y [expr {$sy + 18}]
        $pdf setFillColor 0 0 0
    }
    
    # Trennlinie
    set lineY [expr {$sy + 25}]
    draw_hr $pdf $ctx $lineY
    
    return [expr {$lineY + 15}]
}
```

### Footer-Funktion

```tcl
proc draw_footer {pdf ctx pagenum {text ""}} {
    set sx [dict get $ctx SX]
    set sw [dict get $ctx SW]
    set ph [dict get $ctx PH]
    
    set footerY [expr {$ph - 35}]
    
    # Trennlinie
    draw_hr $pdf $ctx $footerY
    
    $pdf setFont 8 Helvetica
    set textY [expr {$footerY + 10}]
    
    if {$text ne ""} {
        $pdf text $text -x $sx -y $textY
    }
    
    # Seitenzahl rechts
    $pdf text "Seite $pagenum" \
        -x [expr {$sx + $sw}] -y $textY -align right
}
```

## Seitenumbruch-Management

### Manueller Seitenumbruch

```tcl
proc check_page_break {pdf ctx y_var lineHeight pagenum_var} {
    upvar $y_var y
    upvar $pagenum_var pagenum
    
    set maxY [expr {[dict get $ctx PH] - [dict get $ctx margin_pt] - 40}]
    
    if {($y + $lineHeight) > $maxY} {
        draw_footer $pdf $ctx $pagenum
        $pdf endPage
        
        incr pagenum
        $pdf startPage
        
        set startY [draw_header $pdf $ctx "Fortsetzung"]
        set y $startY
    }
}
```

### Verwendung

```tcl
set ctx [create_page_context a4 20 true]
set pdf [::pdf4tcl::new %AUTO% -paper a4 -orient true -compress 1]

$pdf startPage
set pagenum 1
set y [draw_header $pdf $ctx "Mein Dokument"]

$pdf setFont 12 Times-Roman
set lineHeight 16

foreach zeile $daten {
    check_page_break $pdf $ctx y $lineHeight pagenum
    $pdf text $zeile -x [dict get $ctx SX] -y $y
    incr y $lineHeight
}

draw_footer $pdf $ctx $pagenum
$pdf endPage
$pdf write -file dokument.pdf
$pdf destroy
```

## Vollstaendiges Beispiel: Bericht-Template

```tcl
#!/usr/bin/env tclsh
package require pdf4tcl 0.9

# Helper-Funktionen (oben definiert) laden
# source helpers/pdf4tcl_helpers.tcl

set ctx [create_page_context a4 20 true]
set pdf [::pdf4tcl::new %AUTO% -paper a4 -orient true -compress 1]

# Titelseite
$pdf startPage
$pdf setFont 28 Helvetica-Bold
center_text $pdf $ctx "Jahresbericht 2025" 200
$pdf setFont 16 Helvetica
$pdf setFillColor 0.4 0.4 0.4
center_text $pdf $ctx "Abteilung Entwicklung" 240
$pdf setFillColor 0 0 0
$pdf setFont 12 Helvetica
center_text $pdf $ctx "Stand: Oktober 2025" 280
$pdf endPage

# Inhaltsseiten
set pagenum 1
$pdf startPage
set y [draw_header $pdf $ctx "Zusammenfassung"]

$pdf setFont 12 Times-Roman
set lineHeight 16
set sx [dict get $ctx SX]
set sw [dict get $ctx SW]

set absaetze {
    "Der folgende Bericht fasst die wichtigsten Ergebnisse zusammen."
    "Im ersten Quartal wurden drei neue Projekte gestartet."
    "Die Kundenzufriedenheit stieg um 15 Prozent gegenueber dem Vorjahr."
}

foreach absatz $absaetze {
    check_page_break $pdf $ctx y $lineHeight pagenum
    $pdf drawTextBox $sx $y $sw 100 $absatz -align justify \
        -linesvar numLines
    incr y [expr {int($numLines * $lineHeight + 10)}]
}

draw_footer $pdf $ctx $pagenum
$pdf endPage
$pdf write -file bericht-2025.pdf
$pdf destroy
```

## Architektur-Hinweis

pdf4tcl ist bewusst als PDF-Primitiv-Layer konzipiert. Es bietet keine
eingebauten Tabellen, automatischen Seitenumbrueche oder Layout-Engines.
Diese Funktionalitaet gehoert in Helper-Libraries und Abstraktionsschichten
wie pdfdoclib, pdfgrid oder pdftextboxlib.

| Schicht           | Verantwortung                          |
|-------------------|----------------------------------------|
| pdf4tcl (Core)    | PDF-Primitive: Text, Linien, Bilder    |
| Helper-Library    | Konvertierungen, Page Context, Utility |
| pdfdoclib         | Dokument-Abstraktion, Styles, Layouts  |
| pdfgrid           | Tabellen mit Summen, Formatierung      |
| pdftextboxlib     | Erweiterte TextBox mit Optionen        |

## Eingebettete Dateien (0.9.4.14)

`addEmbeddedFile` bettet eine Datei unsichtbar in das PDF ein — ohne
sichtbare Seitenannotation. Die Datei ist ueber den PDF-Katalog unter
`/Names /EmbeddedFiles` erreichbar.

Hauptanwendungsfall: ZUGFeRD/Factur-X-Rechnungen, bei denen eine
XML-Datei zusammen mit dem PDF ausgeliefert werden muss.

```tcl
# Einfaches Einbetten
$pdf addEmbeddedFile "rechnung.xml" \
    [file join $scriptDir rechnung.xml]

# Mit Metadaten
$pdf addEmbeddedFile "ZUGFeRD-invoice.xml" \
    [file join $scriptDir zugferd.xml] \
    -mimetype    "application/xml" \
    -description "ZUGFeRD 2.1 Rechnung" \
    -afrelationship "Alternative"
```

Optionen:

| Option | Standard | Beschreibung |
|--------|----------|-------------|
| `-contents` | Dateiinhalt | Alternativer Dateiinhalt als String |
| `-mimetype` | `application/octet-stream` | MIME-Typ |
| `-description` | `""` | Beschreibung der Datei |
| `-afrelationship` | `Unspecified` | `Alternative Data Source Supplement Unspecified` |

Einschraenkung: Bei `-pdfa 1b` ist `addEmbeddedFile` nicht erlaubt
(ISO 19005-1 §6.1.7). Bei PDF/A-3 (`-pdfa 3b`) ist es ausdruecklich
vorgesehen.
