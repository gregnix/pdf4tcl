# tools/ -- Entwicklungswerkzeuge fuer pdf4tcl

## Qualitätsprüfung

### check-ascii.tcl
Prüft alle Dateien in `src/` und `tests/` auf nicht-ASCII-Bytes.
Nicht-ASCII in Tcl-Quellcode führt unter Windows Tcl 8.6 (ohne UTF-8-BOM)
zu Syntaxfehlern (`missing close-brace`).

```bash
tclsh tools/check-ascii.tcl             # prüfen
tclsh tools/check-ascii.tcl --verbose   # alle Dateien anzeigen
tclsh tools/check-ascii.tcl --fix       # bekannte Symbole automatisch ersetzen
                                        # (── -> --, — -> --, ä -> ae usw.)
```

Whitelist (absichtliche Unicode-Testdaten, werden übersprungen):
`tests/regression.test`, `tests/tounicode.test`, `tests/nist-tests.tcl`

Exit-Code 0 = sauber, 1 = Probleme gefunden.
Kann in `make-release.tcl` als Schritt 0 eingebunden werden.

---

## Versionsverwaltung

### bump.tcl
Aktualisiert alle Versionsnummern in einem Schritt.
Liest Zielversion und Beschreibung aus `next.tcl`.

```bash
tclsh tools/bump.tcl          # ausfuehren
tclsh tools/bump.tcl --show   # nur anzeigen, nichts schreiben
```

Aktualisierte Dateien: `src/prologue.tcl`, `tests/init.tcl`,
`pkgIndex.tcl`, `pkg/pkgIndex.tcl`, `Makefile`, `pdf4tcl.man`,
`README.md`, `web/index.html`, `web/changes.html`, `ChangeLog`,
`sync-pdf4tcl.tcl`, `pdf4tcl.tcl`, `pkg/pdf4tcl.tcl`.

### next.tcl
Konfigurationsdatei fuer bump.tcl.
Hier Zielversion und Beschreibung eintragen, dann `tclsh tools/bump.tcl`.

```tcl
set NEXT_VERSION "0.9.4.18"
set NEXT_MSG     "Kurzbeschreibung der Aenderungen"
```

---

## Tcl-9-Umgebung

### tcl9env.sh
Setzt die Umgebungsvariablen fuer Tests und Beispiele unter Tcl 9.
Muss mit `. tools/tcl9env.sh` (source) eingelesen werden, nicht ausgefuehrt.

```bash
. tools/tcl9env.sh    # Tcl-9-Umgebung aktivieren
make test             # laeuft jetzt mit tclsh9.0
make example

unset TCLSH TCLLIBPATH   # zurueck zu Tcl 8.6
```

Setzt: `TCLSH=tclsh9.0`, `TCLLIBPATH` mit tcl9.0-Pfad vorne.

---

## Build-Werkzeuge (Upstream)

### extract-glyphnames.tcl
Extrahiert die Glyph-zu-Unicode-Tabelle aus `glyphlist.txt`.
Wird benoetigt wenn die Adobe Glyph List aktualisiert wird.

```bash
tclsh tools/extract-glyphnames.tcl > src/glyphnames.tcl
```

### extract-metrics.tcl
Extrahiert Zeichenbreiten aus AFM-Dateien (Adobe Font Metrics).
Wird benoetigt wenn Standard-Font-Metriken aktualisiert werden.

```bash
tclsh tools/extract-metrics.tcl font.afm >> src/stdmetrics.tcl
```

### glyphlist.txt
Adobe Glyph List 2.0 -- Datendatei fuer `extract-glyphnames.tcl`.
Nicht direkt ausfuehren.

---

## Hilfsprogramme

### txt2pdf.tcl
Konvertiert Textdateien in PDF.
Einfaches Kommandozeilen-Tool, unabhaengig von pdf4tcl-Entwicklung.

```bash
tclsh tools/txt2pdf.tcl datei.txt datei.pdf
```
