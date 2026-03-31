#!/usr/bin/env tclsh
# Erzeugt 3 Cheat-Sheet PDFs fuer pdf4tcl 0.9.4.25
# Layout: 2 Spalten pro Seite

set scriptDir [file dirname [file normalize [info script]]]
lappend auto_path $scriptDir
package require pdf4tcl

set outDir [file join $scriptDir out]
file mkdir $outDir

# ============================================================
# Spalten-Konfiguration
# ============================================================
set COL1_X   8      ;# linke Spalte: x-Start
set COL2_X   302    ;# rechte Spalte: x-Start
set COL_W    284    ;# Breite einer Spalte
set VAL_OFF  85     ;# Value-Offset relativ zu Spalte
set Y_START  50     ;# y nach Header
set Y_MAX    650    ;# Seitenumbruch-Schwelle

# ============================================================
# Hilfsprocs
# ============================================================
proc cs_header {pdf title sub} {
    $pdf setFillColor 0.1 0.2 0.5
    $pdf rectangle 0 0 595 40 -filled 1
    $pdf setFillColor 1 1 1
    $pdf setFont 14 Helvetica-Bold
    $pdf text $title -x 12 -y 10
    $pdf setFont 9 Helvetica
    $pdf text $sub -x 12 -y 26
    $pdf setFillColor 0 0 0
}

# Spalte wechseln oder neue Seite
proc cs_col {pdf y cx title sub} {
    global COL1_X COL2_X Y_START Y_MAX
    upvar 1 $cx col
    if {$y > $Y_MAX} {
        if {$col == $COL1_X} {
            # Wechsel zur rechten Spalte
            set col $COL2_X
            return $Y_START
        } else {
            # Neue Seite, zurück zur linken Spalte
            $pdf endPage
            $pdf startPage
            cs_header $pdf $title $sub
            set col $COL1_X
            return $Y_START
        }
    }
    return $y
}

proc cs_section {pdf title y col} {
    global COL_W
    set y [expr {$y + 4}]
    $pdf setFillColor 0.88 0.92 0.98
    $pdf rectangle $col $y $COL_W 15 -filled 1
    $pdf setFillColor 0.1 0.2 0.5
    $pdf setFont 9 Helvetica-Bold
    $pdf text $title -x [expr {$col+4}] -y [expr {$y+10}]
    $pdf setFillColor 0 0 0
    return [expr {$y + 20}]
}

proc cs_row {pdf label value y col {mono 0}} {
    global COL_W VAL_OFF
    $pdf setFillColor 0.35 0.35 0.35
    $pdf setFont 8 Helvetica-Bold
    $pdf text $label -x [expr {$col+4}] -y [expr {$y+8}]
    if {$mono} {
        $pdf setFont 8 Courier
    } else {
        $pdf setFont 8 Helvetica
    }
    $pdf setFillColor 0 0 0
    set nlines 0
    set vx [expr {$col + $VAL_OFF}]
    set vw [expr {$COL_W - $VAL_OFF - 4}]
    $pdf drawTextBox $vx [expr {$y+1}] $vw 200 $value \
        -align left -linesvar nlines
    set h [expr {max(12, $nlines * 10 + 3)}]
    return [expr {$y + $h}]
}

proc cs_code {pdf line y col} {
    global COL_W
    $pdf setFont 7 Courier
    $pdf setFillColor 0.15 0.15 0.15
    $pdf text $line -x [expr {$col+4}] -y $y
    $pdf setFillColor 0 0 0
    return [expr {$y + 10}]
}

proc cs_sep {pdf y col} {
    global COL_W
    incr y 2
    $pdf setStrokeColor 0.8 0.8 0.8
    $pdf line $col $y [expr {$col+$COL_W}] $y
    $pdf setStrokeColor 0 0 0
    return [expr {$y + 5}]
}

# Vertikale Spaltentrenner
proc cs_divider {pdf} {
    $pdf setStrokeColor 0.75 0.75 0.75
    $pdf line 297 45 297 820
    $pdf setStrokeColor 0 0 0
}

# ============================================================
# 1. pdf4tcl-cheat-sheet.pdf
# ============================================================
set T1 "pdf4tcl 0.9.4.25 -- Cheat Sheet"
set S1 "github.com/gregnix/pdf4tcl"
set pdf [::pdf4tcl::new %AUTO% -paper a4 -orient true]
$pdf startPage
cs_header $pdf $T1 $S1
cs_divider $pdf
set y $Y_START
set col $COL1_X

set y [cs_section $pdf "Setup" $y $col]
set y [cs_code $pdf {lappend auto_path /pfad/zu/pdf4tcl} $y $col]
set y [cs_code $pdf {package require pdf4tcl 0.9.4.25} $y $col]
set y [cs_code $pdf {set pdf [pdf4tcl::new %AUTO% -paper a4 -orient true]} $y $col]
set y [cs_code $pdf {$pdf startPage} $y $col]
set y [cs_code $pdf {# ... zeichnen ...} $y $col]
set y [cs_code $pdf {$pdf endPage} $y $col]
set y [cs_code $pdf {$pdf write -file out.pdf  ;# oder: -chan $ch} $y $col]
set y [cs_code $pdf {$pdf destroy} $y $col]
set y [cs_sep $pdf $y $col]

set y [cs_col $pdf $y col $T1 $S1]
set y [cs_section $pdf "Text" $y $col]
set y [cs_row $pdf "setFont"        {$pdf setFont 12 Helvetica} $y $col 1]
set y [cs_row $pdf "text"           {$pdf text "Hallo" -x 50 -y 100} $y $col 1]
set y [cs_row $pdf "drawTextBox"    {$pdf drawTextBox x y w h txt -align left} $y $col 1]
set y [cs_row $pdf "getStringWidth" {getStringWidth str -font Helvetica -size 12} $y $col 1]
set y [cs_row $pdf "Fonts"          {Helvetica Times-Roman Courier (+ Bold/Oblique)} $y $col 0]
set y [cs_sep $pdf $y $col]

set y [cs_col $pdf $y col $T1 $S1]
set y [cs_section $pdf "Farben" $y $col]
set y [cs_row $pdf "setFillColor"   {$pdf setFillColor r g b  ;# 0.0-1.0} $y $col 1]
set y [cs_row $pdf "setStrokeColor" {$pdf setStrokeColor r g b} $y $col 1]
set y [cs_row $pdf "setAlpha"       {$pdf setAlpha 0.5} $y $col 1]
set y [cs_sep $pdf $y $col]

set y [cs_col $pdf $y col $T1 $S1]
set y [cs_section $pdf "Formen" $y $col]
set y [cs_row $pdf "line"        {$pdf line x1 y1 x2 y2} $y $col 1]
set y [cs_row $pdf "rectangle"   {$pdf rectangle x y w h -filled 1} $y $col 1]
set y [cs_row $pdf "roundedRect" {$pdf roundedRect x y w h -radius 8 -filled 1} $y $col 1]
set y [cs_row $pdf "oval"        {$pdf oval x y w h} $y $col 1]
set y [cs_row $pdf "circle"      {$pdf circle x y r} $y $col 1]
set y [cs_row $pdf "polygon"     {$pdf polygon x1 y1 x2 y2 ...} $y $col 1]
set y [cs_row $pdf "arc"         {$pdf arc x y w h start extent} $y $col 1]
set y [cs_sep $pdf $y $col]

set y [cs_col $pdf $y col $T1 $S1]
set y [cs_section $pdf "Linien-Stil" $y $col]
set y [cs_row $pdf "setLineWidth" {$pdf setLineWidth 2} $y $col 1]
set y [cs_row $pdf "setLineDash"  {$pdf setLineDash 6 3  ;# on off} $y $col 1]
set y [cs_row $pdf "setLineStyle" {$pdf setLineStyle solid|dash|dot|dashdot} $y $col 1]
set y [cs_sep $pdf $y $col]

set y [cs_col $pdf $y col $T1 $S1]
set y [cs_section $pdf "Seiten + Koordinaten" $y $col]
set y [cs_row $pdf "startPage"       {startPage ?-paper a3? ?-landscape 1?} $y $col 1]
set y [cs_row $pdf "getDrawableArea" {lassign [$pdf getDrawableArea] w h} $y $col 1]
set y [cs_row $pdf "getPageSize"     {lassign [$pdf getPageSize] w h} $y $col 1]
set y [cs_row $pdf "inPage"          {$pdf inPage  ;# 1/0} $y $col 1]
set y [cs_row $pdf "currentPage"     {$pdf currentPage  ;# 1-basiert} $y $col 1]
set y [cs_row $pdf "orient"          {-orient true: y=0 oben, nach unten} $y $col 0]
set y [cs_sep $pdf $y $col]

set y [cs_col $pdf $y col $T1 $S1]
set y [cs_section $pdf "Papierformate (0.9.4.25)" $y $col]
set y [cs_row $pdf "A-Serie"  {a0..a10, 2a0, 4a0} $y $col 0]
set y [cs_row $pdf "B-Serie"  {b0..b10} $y $col 0]
set y [cs_row $pdf "C-Serie"  {c0..c10  (Umschlaege)} $y $col 0]
set y [cs_row $pdf "US"       {letter legal ledger 11x17} $y $col 0]
set y [cs_row $pdf "Abfragen" {pdf4tcl::getPaperSize a4} $y $col 1]
set y [cs_sep $pdf $y $col]

set y [cs_col $pdf $y col $T1 $S1]
set y [cs_section $pdf "Bilder" $y $col]
set y [cs_row $pdf "addImage" {set id [$pdf addImage file.jpg]} $y $col 1]
set y [cs_row $pdf "putImage" {$pdf putImage $id x y -width 100} $y $col 1]
set y [cs_sep $pdf $y $col]

set y [cs_col $pdf $y col $T1 $S1]
set y [cs_section $pdf "Transformation" $y $col]
set y [cs_row $pdf "gsave"     {$pdf gsave} $y $col 1]
set y [cs_row $pdf "grestore"  {$pdf grestore} $y $col 1]
set y [cs_row $pdf "rotate"    {$pdf rotate 90 -x cx -y cy} $y $col 1]
set y [cs_row $pdf "translate" {$pdf translate dx dy} $y $col 1]
set y [cs_row $pdf "scale"     {$pdf scale sx sy} $y $col 1]
set y [cs_row $pdf "transform" {$pdf transform a b c d e f} $y $col 1]
set y [cs_row $pdf "Hinweis"   {gsave/grestore um Zustand zu sichern} $y $col 0]
set y [cs_sep $pdf $y $col]

set y [cs_col $pdf $y col $T1 $S1]
set y [cs_section $pdf "Font Metrics" $y $col]
set y [cs_row $pdf "getStringWidth"  {getStringWidth str -font H. -size 12} $y $col 1]
set y [cs_row $pdf "getFontMetric"   {$pdf getFontMetric ascender} $y $col 1]
set y [cs_row $pdf "getLineHeight"   {$pdf getLineHeight} $y $col 1]
set y [cs_row $pdf "Metriken"        {ascender descender bboxb bboxt} $y $col 0]
set y [cs_sep $pdf $y $col]

set y [cs_col $pdf $y col $T1 $S1]
set y [cs_section $pdf "Ausgabe (write)" $y $col]
set y [cs_row $pdf "-file"  {$pdf write -file output.pdf} $y $col 1]
set y [cs_row $pdf "-chan"  {$pdf write -chan \$ch  ;# NEU 0.9.4.25} $y $col 1]
set y [cs_row $pdf "stdout" {$pdf write  ;# nach stdout} $y $col 1]
set y [cs_row $pdf "get"    {set d [\$pdf get]  ;# als String} $y $col 1]

set y [cs_col $pdf $y col $T1 $S1]
set y [cs_section $pdf "Gradienten" $y $col]
set y [cs_row $pdf "linearGradient" {$pdf linearGradient x1 y1 x2 y2 stops} $y $col 1]
set y [cs_row $pdf "radialGradient" {$pdf radialGradient cx cy r stops} $y $col 1]
set y [cs_row $pdf "stops"          {{{0 "1 0 0"} {1 "0 0 1"}}  ;# r g b} $y $col 1]
set y [cs_row $pdf "setBlendMode"   {$pdf setBlendMode Normal|Multiply|...} $y $col 1]
set y [cs_sep $pdf $y $col]

set y [cs_col $pdf $y col $T1 $S1]
set y [cs_section $pdf "Text-Optionen" $y $col]
set y [cs_row $pdf "newLine"        {$pdf newLine  ;# y += lineSpacing} $y $col 1]
set y [cs_row $pdf "moveTextPos"    {$pdf moveTextPosition dx dy} $y $col 1]
set y [cs_row $pdf "setTextPos"     {$pdf setTextPosition x y} $y $col 1]
set y [cs_row $pdf "getTextPos"     {$pdf getTextPosition  -> x y} $y $col 1]
set y [cs_row $pdf "setLineSpacing" {$pdf setLineSpacing 1.2} $y $col 1]
set y [cs_row $pdf "drawTextBox"    {-align left|right|center|justify} $y $col 0]
set y [cs_row $pdf ""               {-linesvar N  -newyvar yvar} $y $col 0]
set y [cs_sep $pdf $y $col]

set y [cs_col $pdf $y col $T1 $S1]
set y [cs_section $pdf "Lesezeichen + Links" $y $col]
set y [cs_row $pdf "bookmarkAdd"   {$pdf bookmarkAdd -title "Kapitel" -level 1} $y $col 1]
set y [cs_row $pdf "hyperlinkAdd"  {$pdf hyperlinkAdd x y w h url} $y $col 1]
set y [cs_row $pdf "pageLabel"     {$pdf pageLabel -prefix "A-" -start 1} $y $col 1]
set y [cs_sep $pdf $y $col]

set y [cs_col $pdf $y col $T1 $S1]
set y [cs_section $pdf "Layer (OCG)" $y $col]
set y [cs_row $pdf "addLayer"     {set id [$pdf addLayer "Ebene 1"]} $y $col 1]
set y [cs_row $pdf "beginLayer"   {$pdf beginLayer $id} $y $col 1]
set y [cs_row $pdf "endLayer"     {$pdf endLayer} $y $col 1]
set y [cs_row $pdf "Hinweis"      {-pdfa 2b+ erlaubt Layer} $y $col 0]
set y [cs_sep $pdf $y $col]

set y [cs_col $pdf $y col $T1 $S1]
set y [cs_section $pdf "Encryption" $y $col]
set y [cs_row $pdf "-encryption" {pdf4tcl::new ... -encryption aes256} $y $col 1]
set y [cs_row $pdf "-password"   {-userpwd "user" -ownerpwd "owner"} $y $col 1]
set y [cs_row $pdf "AES-128"     {V=4/R=4 -- ab 0.9.4.11} $y $col 0]
set y [cs_row $pdf "AES-256"     {V=5/R=6 -- ab 0.9.4.16} $y $col 0]
set y [cs_row $pdf "Kein PDF/A"  {Encryption + PDF/A schliessen sich aus} $y $col 0]
set y [cs_sep $pdf $y $col]

set y [cs_col $pdf $y col $T1 $S1]
set y [cs_section $pdf "Metadata + PDF/A" $y $col]
set y [cs_row $pdf "metadata"    {$pdf metadata -author "Name" -title "..."} $y $col 1]
set y [cs_row $pdf "-pdfa"       {pdf4tcl::new ... -pdfa 1b|2b|3b} $y $col 1]
set y [cs_row $pdf "addEmbedded" {$pdf addEmbeddedFile file.xml "factur-x.xml"} $y $col 1]
set y [cs_row $pdf "viewerPref"  {$pdf viewerPreferences -fitwindow 1} $y $col 1]

$pdf endPage
$pdf write -file [file join $outDir pdf4tcl-cheat-sheet.pdf]
$pdf destroy
puts "pdf4tcl-cheat-sheet.pdf"

# ============================================================
# 2. pdf-cheat-sheet.pdf
# ============================================================
set T2 "PDF Grundlagen -- Cheat Sheet"
set S2 "Koordinaten, Einheiten, Papierformate, PDF-Struktur"
set pdf [::pdf4tcl::new %AUTO% -paper a4 -orient true]
$pdf startPage
cs_header $pdf $T2 $S2
cs_divider $pdf
set y $Y_START
set col $COL1_X

set y [cs_section $pdf "Einheiten" $y $col]
set y [cs_row $pdf "1 pt (Point)" {= 1/72 Inch = 0.353 mm} $y $col 0]
set y [cs_row $pdf "1 mm"         {= 2.835 pt} $y $col 0]
set y [cs_row $pdf "1 cm"         {= 28.35 pt} $y $col 0]
set y [cs_row $pdf "1 Inch"       {= 72 pt} $y $col 0]
set y [cs_row $pdf "Umrechnung"   {mm -> pt:  val * 72.0 / 25.4} $y $col 1]
set y [cs_sep $pdf $y $col]

set y [cs_col $pdf $y col $T2 $S2]
set y [cs_section $pdf "Papiergroessen (in pt)" $y $col]
# Zwei Eintraege nebeneinander
set sizes2 {
    a4 "595 x 842"   a3  "842 x 1191"
    a5 "420 x 595"   a6  "298 x 420"
    b4 "709 x 1001"  b5  "499 x 709"
    c4 "649 x 918"   c5  "459 x 649"
    letter "612 x 792"  legal "612 x 1008"
}
set sc 0
foreach {name dim} $sizes2 {
    if {$sc == 0} {
        $pdf setFont 8 Helvetica-Bold
        $pdf setFillColor 0.35 0.35 0.35
        $pdf text $name -x [expr {$col+4}] -y $y
        $pdf setFont 8 Helvetica
        $pdf setFillColor 0 0 0
        $pdf text $dim -x [expr {$col+45}] -y $y
        set sc 1
    } else {
        $pdf setFont 8 Helvetica-Bold
        $pdf setFillColor 0.35 0.35 0.35
        $pdf text $name -x [expr {$col+145}] -y $y
        $pdf setFont 8 Helvetica
        $pdf setFillColor 0 0 0
        $pdf text $dim -x [expr {$col+185}] -y $y
        set y [expr {$y + 11}]
        set sc 0
    }
}
set y [cs_sep $pdf $y $col]

set y [cs_col $pdf $y col $T2 $S2]
set y [cs_section $pdf "Koordinatensystem" $y $col]
set y [cs_row $pdf "orient true"  {(0,0) oben-links, y nach unten (Tk)} $y $col 0]
set y [cs_row $pdf "orient false" {(0,0) unten-links, y nach oben (PDF)} $y $col 0]
set y [cs_row $pdf "Empfehlung"   {-orient true immer explizit setzen} $y $col 0]
set y [cs_row $pdf "Baseline"     {text -y = Baseline, nicht Oberkante} $y $col 0]
set y [cs_row $pdf ""             {Ascender ~ 0.75 * fontSize} $y $col 0]
set y [cs_sep $pdf $y $col]

set y [cs_col $pdf $y col $T2 $S2]
set y [cs_section $pdf "PDF-Operatoren" $y $col]
set y [cs_row $pdf "m / l / c" {moveto lineto curveto} $y $col 1]
set y [cs_row $pdf "S / s"     {stroke offen / geschlossen} $y $col 1]
set y [cs_row $pdf "f / B"     {fill / fill+stroke} $y $col 1]
set y [cs_row $pdf "q / Q"     {gsave / grestore} $y $col 1]
set y [cs_row $pdf "cm"        {concat matrix (Transform)} $y $col 1]
set y [cs_row $pdf "BT / ET"   {Textblock begin / end} $y $col 1]
set y [cs_row $pdf "Tm"        {Textmatrix setzen} $y $col 1]
set y [cs_row $pdf "Tj / TJ"   {Text ausgeben} $y $col 1]
set y [cs_row $pdf "rg / RG"   {fill / stroke color (RGB)} $y $col 1]
set y [cs_row $pdf "w / d"     {Linienbreite / Dash-Pattern} $y $col 1]
set y [cs_row $pdf "J / j"     {Linienende / Verbindung} $y $col 1]
set y [cs_sep $pdf $y $col]

set y [cs_col $pdf $y col $T2 $S2]
set y [cs_section $pdf "PDF-Struktur" $y $col]
set y [cs_row $pdf "Header"    {%PDF-x.x  (erste Zeile)} $y $col 0]
set y [cs_row $pdf "Objekte"   {N 0 obj ... endobj} $y $col 0]
set y [cs_row $pdf "Streams"   {<< /Length N >> stream...endstream} $y $col 0]
set y [cs_row $pdf "XRef"      {xref-Tabelle oder XRef-Stream} $y $col 0]
set y [cs_row $pdf "Trailer"   {trailer << /Root /Info /Size >>} $y $col 0]
set y [cs_row $pdf "startxref" {Offset der XRef-Tabelle} $y $col 0]
set y [cs_row $pdf "EOF"       {%%EOF (letzte Zeile)} $y $col 0]
set y [cs_sep $pdf $y $col]

set y [cs_col $pdf $y col $T2 $S2]
set y [cs_section $pdf "PDF/A (pdf4tcl)" $y $col]
set y [cs_row $pdf "PDF/A-1b"    {-pdfa 1b: Basis, keine Transparenz} $y $col 0]
set y [cs_row $pdf "PDF/A-2b"    {-pdfa 2b: + Transparenz, Layer} $y $col 0]
set y [cs_row $pdf "PDF/A-3b"    {-pdfa 3b: + Embedded Files (ZUGFeRD)} $y $col 0]
set y [cs_row $pdf "Validierung" {veraPDF: https://verapdf.org} $y $col 0]

set y [cs_col $pdf $y col $T2 $S2]
set y [cs_section $pdf "Farbmodelle" $y $col]
set y [cs_row $pdf "DeviceRGB"   {rg/RG: r g b  (0.0-1.0)} $y $col 1]
set y [cs_row $pdf "DeviceGray"  {g/G: gray (0.0-1.0)} $y $col 1]
set y [cs_row $pdf "DeviceCMYK"  {k/K: c m y k} $y $col 1]
set y [cs_row $pdf "Schwarz"     {0 0 0 rg  oder  0 g} $y $col 1]
set y [cs_row $pdf "Weiss"       {1 1 1 rg  oder  1 g} $y $col 1]
set y [cs_sep $pdf $y $col]

set y [cs_col $pdf $y col $T2 $S2]
set y [cs_section $pdf "PDF Debugging" $y $col]
set y [cs_row $pdf "qpdf --check"     {Struktur pruefen} $y $col 1]
set y [cs_row $pdf "qpdf --json"      {Alle Objekte als JSON} $y $col 1]
set y [cs_row $pdf "pdfinfo"          {Metadaten, Seitenzahl, Version} $y $col 1]
set y [cs_row $pdf "pdftotext"        {Text-Extraktion testen} $y $col 1]
set y [cs_row $pdf "veraPDF"          {PDF/A-Validierung} $y $col 1]
set y [cs_row $pdf "Ghostscript"      {gs -dNOPAUSE -sDEVICE=nullpage} $y $col 1]
set y [cs_sep $pdf $y $col]

set y [cs_col $pdf $y col $T2 $S2]
set y [cs_section $pdf "Haeufige PDF-Fehler" $y $col]
set y [cs_row $pdf "off-by-one"   {/Length falsch -> korrupt} $y $col 0]
set y [cs_row $pdf "fehlendes EOL" {\r\n vor endstream noetig (PDF/A)} $y $col 0]
set y [cs_row $pdf "XRef-Offset"  {startxref falsch -> nicht lesbar} $y $col 0]
set y [cs_row $pdf "Font missing"  {/BaseFont nicht eingebettet} $y $col 0]
set y [cs_row $pdf "Encoding"     {WinAnsi vs UTF-8 Mischung} $y $col 0]
set y [cs_row $pdf "Transparenz"  {setAlpha < 1.0 verboten in PDF/A-1b} $y $col 0]
set y [cs_sep $pdf $y $col]

set y [cs_col $pdf $y col $T2 $S2]
set y [cs_section $pdf "Koordinaten-Formeln" $y $col]
set y [cs_row $pdf "mm -> pt"    {pt = mm * 72.0 / 25.4} $y $col 1]
set y [cs_row $pdf "pt -> mm"    {mm = pt * 25.4 / 72.0} $y $col 1]
set y [cs_row $pdf "Zentrierung" {x = (pageW - textW) / 2.0} $y $col 1]
set y [cs_row $pdf "Texthoehe"   {y += fontSize * lineSpacing} $y $col 1]
set y [cs_row $pdf "Druckrand"   {lassign [\$pdf getDrawableArea] w h} $y $col 1]
set y [cs_row $pdf "Box-Mitte"   {cx = x + w/2.0  cy = y + h/2.0} $y $col 1]
set y [cs_sep $pdf $y $col]

set y [cs_col $pdf $y col $T2 $S2]
set y [cs_section $pdf "Externe Tools (Linux)" $y $col]
set y [cs_row $pdf "pdftocairo"  {pdftocairo -png -r 150 in.pdf out} $y $col 1]
set y [cs_row $pdf "pdftk"       {pdftk in.pdf burst / cat / compress} $y $col 1]
set y [cs_row $pdf "qpdf merge"  {qpdf --empty --pages a.pdf b.pdf -- out.pdf} $y $col 1]
set y [cs_row $pdf "gs pdf/a"    {gs -dPDFA=2 -dBATCH ... in.pdf} $y $col 1]
set y [cs_row $pdf "ocrmypdf"    {ocrmypdf -l deu in.pdf out.pdf} $y $col 1]

$pdf endPage
$pdf write -file [file join $outDir pdf-cheat-sheet.pdf]
$pdf destroy
puts "pdf-cheat-sheet.pdf"

# ============================================================
# 3. canvas-cheat-sheet.pdf
# ============================================================
set T3 "Canvas Export -- Cheat Sheet (pdf4tcl 0.9.4.25)"
set S3 "tk::canvas / tkpath (PathCanvas) / tko::path"
set pdf [::pdf4tcl::new %AUTO% -paper a4 -orient true]
$pdf startPage
cs_header $pdf $T3 $S3
cs_divider $pdf
set y $Y_START
set col $COL1_X

set y [cs_section $pdf "Grundaufruf" $y $col]
set y [cs_code $pdf {update  ;# Canvas muss gerendert sein} $y $col]
set y [cs_code $pdf {set bb [$canvas bbox all]} $y $col]
set y [cs_code $pdf {$pdf canvas $canvas -bbox $bb -x lx -y ly -width w -height h} $y $col]
set y [cs_sep $pdf $y $col]

set y [cs_col $pdf $y col $T3 $S3]
set y [cs_section $pdf "Optionen: canvas" $y $col]
set y [cs_row $pdf "-bbox"         {Bereich (noetig bei tkpath/tko)} $y $col 1]
set y [cs_row $pdf "-x / -y"       {Position auf der PDF-Seite} $y $col 1]
set y [cs_row $pdf "-width/-height" {Groesse auf der Seite} $y $col 1]
set y [cs_row $pdf "-sticky"       {nw (default), ns, ew, nsew} $y $col 1]
set y [cs_row $pdf "-bg"           {Hintergrund malen (default: 0)} $y $col 1]
set y [cs_row $pdf "-fontmap"      {Tk-Fontname -> PDF-Fontname} $y $col 1]
set y [cs_row $pdf "Return"        {bbox in PDF-Koordinaten} $y $col 1]
set y [cs_sep $pdf $y $col]

set y [cs_col $pdf $y col $T3 $S3]
set y [cs_section $pdf "tk::canvas  (class: Canvas)" $y $col]
set y [cs_row $pdf "Items"    {rect oval line polygon arc text image window} $y $col 0]
set y [cs_row $pdf "-matrix"  {nicht unterstuetzt} $y $col 0]
set y [cs_row $pdf "window"   {Img + on-screen; Fallback: schwarzes Rect} $y $col 0]
set y [cs_row $pdf "Dispatch" {CanvasDoItem (cls=1)} $y $col 0]
set y [cs_sep $pdf $y $col]

set y [cs_col $pdf $y col $T3 $S3]
set y [cs_section $pdf "tkpath  (class: PathCanvas)" $y $col]
set y [cs_row $pdf "Items"     {prect circle ellipse pline polyline ppolygon path group pimage ptext} $y $col 0]
set y [cs_row $pdf "-matrix"   {VERSCHACHTELT: \{\{a b\} \{c d\} \{tx ty\}\}} $y $col 1]
set y [cs_row $pdf {-stroke ""} {leer ok (kein Stroke)} $y $col 1]
set y [cs_row $pdf "gradient"  {$w gradient create linear/radial} $y $col 1]
set y [cs_row $pdf "Dispatch"  {CanvasDoTkpathItem (cls=2)} $y $col 0]
set y [cs_sep $pdf $y $col]

set y [cs_col $pdf $y col $T3 $S3]
set y [cs_section $pdf "tko::path  (class: tko::path)" $y $col]
set y [cs_row $pdf "Items"     {rect circle ellipse line polyline polygon path group text image window} $y $col 0]
set y [cs_row $pdf "-matrix"   {FLACH: \{a b c d tx ty\}  (6 Zahlen)} $y $col 1]
set y [cs_row $pdf {-stroke ""} {CRASH! Immer Farbe angeben} $y $col 1]
set y [cs_row $pdf "window"    {still uebersprungen (BUG-C1 Fix 0.9.4.24)} $y $col 0]
set y [cs_row $pdf "Dispatch"  {CanvasDoTkoPathItem (cls=3)} $y $col 0]
set y [cs_sep $pdf $y $col]

set y [cs_col $pdf $y col $T3 $S3]
set y [cs_section $pdf "Vergleich tkpath vs tko::path" $y $col]
set y [cs_row $pdf "Item-Prefix" {tkpath: p-Prefix  |  tko: kein Prefix} $y $col 0]
set y [cs_row $pdf "matrix"      {tkpath: verschachtelt  |  tko: flach} $y $col 0]
set y [cs_row $pdf "stroke leer" {tkpath: ok  |  tko: CRASH} $y $col 0]
set y [cs_row $pdf "Gradient"    {tkpath: ja  |  tko: nicht getestet} $y $col 0]
set y [cs_row $pdf "window"      {tkpath: ---  |  tko: uebersprungen} $y $col 0]
set y [cs_sep $pdf $y $col]

set y [cs_col $pdf $y col $T3 $S3]
set y [cs_section $pdf "Wichtige Regeln" $y $col]
set y [cs_row $pdf "update"      {update/idletasks vor Export} $y $col 0]
set y [cs_row $pdf "-bbox"       {Immer -bbox [\$w bbox all] bei tkpath/tko} $y $col 0]
set y [cs_row $pdf "orient"      {-orient true + page::context synchron} $y $col 0]
set y [cs_row $pdf "text -y"     {= Baseline (nicht Oberkante)} $y $col 0]
set y [cs_row $pdf "splinesteps" {ignoriert -- exakte Bezier-Kurven} $y $col 0]

set y [cs_col $pdf $y col $T3 $S3]
set y [cs_section $pdf "tkpath: Gradienten" $y $col]
set y [cs_code $pdf {set g [$w gradient create linear -stops {{0 red} {1 blue}}]} $y $col]
set y [cs_code $pdf {$w create prect 10 10 200 100 -fill $g} $y $col]
set y [cs_code $pdf {set r [$w gradient create radial -stops {{0 white} {1 "#0055aa"}}]} $y $col]
set y [cs_code $pdf {$w create circle 100 100 -r 50 -fill $r} $y $col]
set y [cs_sep $pdf $y $col]

set y [cs_col $pdf $y col $T3 $S3]
set y [cs_section $pdf "Canvas Text-Optionen" $y $col]
set y [cs_row $pdf "tk::canvas"  {-text -font -anchor -fill -justify} $y $col 0]
set y [cs_row $pdf "tkpath ptext" {-text -fontfamily -fontsize -fontweight} $y $col 0]
set y [cs_row $pdf ""             {-fontslant -textanchor -fill} $y $col 0]
set y [cs_row $pdf "tko::path"   {-text -fontfamily -fontsize -fontweight} $y $col 0]
set y [cs_row $pdf ""             {-fontslant -textanchor -fill} $y $col 0]
set y [cs_row $pdf "textanchor"  {start | middle | end} $y $col 0]
set y [cs_sep $pdf $y $col]

set y [cs_col $pdf $y col $T3 $S3]
set y [cs_section $pdf "Typisches Export-Pattern" $y $col]
set y [cs_code $pdf {wm withdraw .} $y $col]
set y [cs_code $pdf {canvas .c -width 400 -height 300} $y $col]
set y [cs_code $pdf {pack .c} $y $col]
set y [cs_code $pdf {# Items zeichnen...} $y $col]
set y [cs_code $pdf {update idletasks} $y $col]
set y [cs_code $pdf {set pdf [pdf4tcl::new %AUTO% -paper a4]} $y $col]
set y [cs_code $pdf {$pdf startPage} $y $col]
set y [cs_code $pdf {$pdf canvas .c -bbox [.c bbox all] -x 50 -y 50} $y $col]
set y [cs_code $pdf {$pdf endPage} $y $col]
set y [cs_code $pdf {$pdf write -file out.pdf  ;  $pdf destroy} $y $col]
set y [cs_sep $pdf $y $col]

set y [cs_col $pdf $y col $T3 $S3]
set y [cs_section $pdf "Canvas Bild-Export" $y $col]
set y [cs_row $pdf "addImage"   {set img [$pdf addImage [$c image create photo ...]]} $y $col 1]
set y [cs_row $pdf "-image"     {.c create image x y -image $photo} $y $col 1]
set y [cs_row $pdf "pimage"     {.c create pimage x1 y1 x2 y2 -image $photo} $y $col 1]
set y [cs_row $pdf "Tipp"       {update vor bbox: sonst falsche Masse} $y $col 0]
set y [cs_sep $pdf $y $col]

$pdf endPage
$pdf write -file [file join $outDir canvas-cheat-sheet.pdf]
$pdf destroy
puts "canvas-cheat-sheet.pdf"
puts ""
puts "Alle Cheat Sheets in: $outDir"

# ============================================================
# 4. pdf-internals-cheat-sheet.pdf
# ============================================================
set T4 "PDF Internals -- Cheat Sheet"
set S4 "Objektstruktur, Font/CMap, XRef, Streams, Encryption, XMP"
set pdf [::pdf4tcl::new %AUTO% -paper a4 -orient true]
$pdf startPage
cs_header $pdf $T4 $S4
cs_divider $pdf
set y $Y_START
set col $COL1_X

set y [cs_section $pdf "PDF Objektstruktur" $y $col]
set y [cs_code $pdf {%PDF-1.7} $y $col]
set y [cs_code $pdf {1 0 obj  << /Type /Catalog /Pages 2 0 R >>  endobj} $y $col]
set y [cs_code $pdf {2 0 obj  << /Type /Pages /Kids [3 0 R] /Count 1 >>  endobj} $y $col]
set y [cs_code $pdf {3 0 obj  << /Type /Page /Parent 2 0 R ...>>  endobj} $y $col]
set y [cs_code $pdf {4 0 obj  << /Length 44 >>} $y $col]
set y [cs_code $pdf {stream} $y $col]
set y [cs_code $pdf {BT /F1 12 Tf 50 800 Td (Hallo) Tj ET} $y $col]
set y [cs_code $pdf {endstream  endobj} $y $col]
set y [cs_code $pdf {xref  trailer  startxref  %%EOF} $y $col]
set y [cs_sep $pdf $y $col]

set y [cs_col $pdf $y col $T4 $S4]
set y [cs_section $pdf "Stream Filter" $y $col]
set y [cs_row $pdf "FlateDecode"  {zlib/deflate Kompression (Standard)} $y $col 0]
set y [cs_row $pdf "DCTDecode"    {JPEG Bilder} $y $col 0]
set y [cs_row $pdf "CCITTFax"     {Fax/TIFF 1-bit} $y $col 0]
set y [cs_row $pdf "JPXDecode"    {JPEG2000 (PDF/A-2b+)} $y $col 0]
set y [cs_row $pdf "ASCII85"      {ASCII-Kodierung} $y $col 0]
set y [cs_row $pdf "Length"       {immer exakt -- off by one -> kaputt} $y $col 0]
set y [cs_row $pdf "Newline"      {\\r\\n vor endstream (PDF/A-Pflicht)} $y $col 0]
set y [cs_sep $pdf $y $col]

set y [cs_col $pdf $y col $T4 $S4]
set y [cs_section $pdf "Font Struktur" $y $col]
set y [cs_row $pdf "Type1"      {Standard 14: Helvetica Times Courier Symbol} $y $col 0]
set y [cs_row $pdf "TrueType"   {/Type /Font /Subtype /TrueType} $y $col 0]
set y [cs_row $pdf "CIDFont"    {fuer Unicode/CJK -- Type0 Wrapper} $y $col 0]
set y [cs_row $pdf "Encoding"   {WinAnsiEncoding / MacRomanEncoding} $y $col 0]
set y [cs_row $pdf "ToUnicode"  {CMap Stream -- Pflicht fuer Suche/Copy} $y $col 0]
set y [cs_row $pdf "Widths"     {Array der Zeichenbreiten (1/1000 em)} $y $col 0]
set y [cs_sep $pdf $y $col]

set y [cs_col $pdf $y col $T4 $S4]
set y [cs_section $pdf "XRef Tabelle vs XRef Stream" $y $col]
set y [cs_row $pdf "Tabelle"     {xref\\n 0 N\\n 0000000000 65535 f\\n} $y $col 1]
set y [cs_row $pdf "Stream"      {<</Type/XRef /W [1 4 2] /Index ...>>} $y $col 1]
set y [cs_row $pdf "PDF/A-2b+"   {XRef Stream Pflicht (pdf4tcl ab 0.9.4.22)} $y $col 0]
set y [cs_row $pdf "Offset"      {startxref = Byte-Offset XRef vom Dateistart} $y $col 0]
set y [cs_sep $pdf $y $col]

set y [cs_col $pdf $y col $T4 $S4]
set y [cs_section $pdf "Encryption (pdf4tcl)" $y $col]
set y [cs_row $pdf "RC4-128"    {V=3/R=3 -- veraltet} $y $col 0]
set y [cs_row $pdf "AES-128"    {V=4/R=4 -- pdf4tcl 0.9.4.11+} $y $col 0]
set y [cs_row $pdf "AES-256"    {V=5/R=6 -- pdf4tcl 0.9.4.16+} $y $col 0]
set y [cs_row $pdf "Schluessel" {UserPassword / OwnerPassword} $y $col 0]
set y [cs_row $pdf "Strings"    {/T /DA /V in Formularen werden verschl.} $y $col 0]
set y [cs_row $pdf "Kein PDF/A" {Encryption + PDF/A schliessen sich aus} $y $col 0]
set y [cs_sep $pdf $y $col]

set y [cs_col $pdf $y col $T4 $S4]
set y [cs_section $pdf "XMP Metadata (PDF/A Pflicht)" $y $col]
set y [cs_row $pdf "Stream"     {/Type /Metadata /Subtype /XML} $y $col 0]
set y [cs_row $pdf "Namespaces" {dc: xmp: pdf: pdfaid: xmpMM:} $y $col 0]
set y [cs_row $pdf "pdfaid"     {/pdfaid:part '1'|'2'|'3' + conformance 'B'} $y $col 0]
set y [cs_row $pdf "Producer"   {xmp:CreatorTool + pdf:Producer} $y $col 0]
set y [cs_row $pdf "Dates"      {xmp:CreateDate / xmp:ModifyDate (ISO 8601)} $y $col 0]
set y [cs_sep $pdf $y $col]

set y [cs_col $pdf $y col $T4 $S4]
set y [cs_section $pdf "PDF/A Pflichtfelder" $y $col]
set y [cs_row $pdf "OutputIntent"  {sRGB ICC-Profil eingebettet} $y $col 0]
set y [cs_row $pdf "XMP"           {pdfaid:part + pdfaid:conformance} $y $col 0]
set y [cs_row $pdf "ToUnicode"     {fuer alle verwendeten Fonts} $y $col 0]
set y [cs_row $pdf "Kein ExtGS"    {keine Transparenz bei PDF/A-1b} $y $col 0]
set y [cs_row $pdf "Kein JS"       {kein JavaScript} $y $col 0]
set y [cs_row $pdf "Validierung"   {veraPDF: https://verapdf.org} $y $col 0]
set y [cs_sep $pdf $y $col]

set y [cs_col $pdf $y col $T4 $S4]
set y [cs_section $pdf "Annotation Typen (pdf4tcl 0.9.4.23+)" $y $col]
set y [cs_row $pdf "Note"         {addAnnotNote x y w h text} $y $col 1]
set y [cs_row $pdf "FreeText"     {addAnnotFreeText x y w h text} $y $col 1]
set y [cs_row $pdf "Highlight"    {addAnnotHighlight x y w h} $y $col 1]
set y [cs_row $pdf "StrikeOut"    {addAnnotStrikeOut x y w h} $y $col 1]
set y [cs_row $pdf "Underline"    {addAnnotUnderline x y w h} $y $col 1]
set y [cs_row $pdf "Line"         {addAnnotLine x1 y1 x2 y2} $y $col 1]
set y [cs_row $pdf "Stamp"        {addAnnotStamp x y w h text} $y $col 1]
set y [cs_sep $pdf $y $col]

set y [cs_col $pdf $y col $T4 $S4]
set y [cs_section $pdf "AcroForm (Formularfelder)" $y $col]
set y [cs_row $pdf "text"         {addForm text x y w h -name id} $y $col 1]
set y [cs_row $pdf "checkbutton"  {addForm checkbutton x y w h} $y $col 1]
set y [cs_row $pdf "radiobutton"  {addForm radiobutton x y w h -group g} $y $col 1]
set y [cs_row $pdf "combobox"     {addForm combobox x y w h -values {a b c}} $y $col 1]
set y [cs_row $pdf "listbox"      {addForm listbox x y w h -values {a b}} $y $col 1]
set y [cs_row $pdf "pushbutton"   {addForm pushbutton x y w h -label OK} $y $col 1]
set y [cs_row $pdf "Export"       {pdf4tcl::exportForms $pdf FDF out.fdf} $y $col 1]

$pdf endPage
$pdf write -file [file join $outDir pdf-internals-cheat-sheet.pdf]
$pdf destroy
puts "pdf-internals-cheat-sheet.pdf"
