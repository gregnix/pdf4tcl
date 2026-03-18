# pdf4tcl Verschlüsselung: AES-128 und AES-256

Dieses Dokument beschreibt die PDF-Verschlüsselungsunterstützung
in pdf4tcl ab Version 0.9.4.16 (Fork gregnix/pdf4tcl).

## Überblick

pdf4tcl unterstützt zwei Verschlüsselungsstufen:

| Option | Standard | Algorithmus | PDF-Version | Abhängigkeiten |
|--------|----------|-------------|-------------|----------------|
| `-encversion 4` | ja | AES-128 (V=4/R=4) | 1.5+ | nur Tcllib |
| `-encversion 5` | nein | AES-256 (V=5/R=6) | 2.0 | Tcllib + openssl |

## AES-128 (Standard)

AES-128 ist der Standard und benötigt keine externen Programme.
Es verwendet ausschließlich Tcllib (md5, aes).

```tcl
package require pdf4tcl

set p [pdf4tcl::new %AUTO% -paper a4 -orient true \
    -userpassword  "geheim" \
    -ownerpassword "admin"]

$p startPage
$p setFont 12 Helvetica
$p text "Verschlüsselter Inhalt" -x 72 -y 72
$p endPage
$p write -file output.pdf
$p destroy
```

qpdf-Verifikation:

```bash
qpdf --password=geheim --check output.pdf
```

## AES-256

AES-256 aktiviert man mit `-encversion 5`. Es erzeugt PDF-2.0-konforme
Dateien nach ISO 32000-2 und ist von Adobe Reader, qpdf und pikepdf
lesbar.

```tcl
set p [pdf4tcl::new %AUTO% -paper a4 -orient true \
    -userpassword  "geheim" \
    -ownerpassword "admin" \
    -encversion    5]
```

### Laufzeit

AES-256 benötigt SHA-384 und SHA-512 für den Schlüsselableitungsalgorithmus
(ISO 32000-2 §7.6.4.3.3, Alg. 2.B). Tcllib implementiert nur SHA-256,
daher startet pdf4tcl für jedes AES-256-PDF ca. 60-80 `openssl`-Prozesse.

Richtwerte auf normaler Hardware:

- AES-128: unter 100 ms
- AES-256: 2-4 Sekunden

Voraussetzung: `openssl` muss im PATH vorhanden sein.

```bash
which openssl   # muss einen Pfad ausgeben
```

## Optionen

| Option | Typ | Standard | Beschreibung |
|--------|-----|----------|--------------|
| `-userpassword` | String | `""` | Öffnet das PDF (leer = kein Passwort) |
| `-ownerpassword` | String | `""` | Vollzugriff; bei leer = userpassword |
| `-encversion` | 4 oder 5 | `4` | Verschlüsselungsstufe |

Wenn nur `-ownerpassword` gesetzt ist ohne `-userpassword`, wird das
owner-Passwort auch als user-Passwort verwendet.

## Technische Details

### AES-128 (V=4/R=4)

- Schlüsselableitung: MD5 mit 50 Iterationen (ISO 32000-1 §7.6.3)
- Per-Objekt-Schlüssel aus Objekt-Nummer und Generierungs-Nummer
- Padding-Konstante: `28BF...697A` (qpdf-kompatibel)
- Nur Tcllib: md5, aes

### AES-256 (V=5/R=6)

- Schlüsselableitung: Alg. 2.B mit SHA-256/384/512
- Ein einziger File-Encryption-Key (FEK, 32 Bytes) für alle Objekte
- Pro Objekt: zufälliger 16-Byte-IV wird jedem verschlüsselten Stream und
  String vorangestellt (AES-128-CBC-Padding-Schema, identisch mit AES-128)
- Felder: U, UE, O, OE (je 32–48 Bytes), Perms (16 Bytes)
- Implementierung **kompatibel mit qpdf (de-facto Referenzimplementierung)**,
  nicht dem wortgetreuen ISO-Text:
  - Sequenz-Reihenfolge: `password || K || userkey`
  - Hash-Selektor: `sum(E[0:16]) % 3`
  - K bleibt 48/64 Bytes nach SHA-384/512 in der Schleife
- Validiert gegen qpdf: `qpdf --check` mit korrektem Passwort muss
  `User password = <pw>` ausgeben
- Tcllib für SHA-256 und AES-CBC; openssl für SHA-384/512

**Laufzeit und Portabilität:**
AES-256 startet pro PDF ca. 60–80 openssl-Prozesse für SHA-384/512-Hashes.
Das ist ausreichend für gelegentliche Nutzung (2–4 s/PDF), aber nicht
skalierbar. openssl muss im PATH vorhanden sein.

```
# TODO: SHA-384/512 in reinem Tcl implementieren (z.B. über critcl oder
# native Tcl-Erweiterung), um openssl-Abhängigkeit zu eliminieren.
```

## Einschränkungen

- AES-256 ist eine reine Schreib-Implementierung. pdf4tcl kann
  verschlüsselte PDFs nicht lesen oder entschlüsseln.
- Der `-encversion`-Parameter ist `readonly` und kann nach der
  Objekterstellung nicht mehr geändert werden.
- Permissions (`/P`) sind fest auf `-196` gesetzt (alle Rechte erlaubt).

## Diagnosewerkzeuge

### verify_enc3.py

Verifiziert AES-256-PDFs unabhängig von pdf4tcl:

```bash
python3 verify_enc3.py output.pdf geheim
```

Zeigt: U/O-Hash-Vergleich, Iterationsanzahl von Alg. 2.B, FEK,
Perms-Validierung.

### qpdf

```bash
# Passwort prüfen
qpdf --password=geheim --check output.pdf

# Entschlüsseln
qpdf --password=geheim --decrypt output.pdf plain.pdf

# Encryption-Dict anzeigen
qpdf --show-encryption --password=geheim output.pdf
```

## Verschlüsselte Strings und Formulare (§7.6.5)

pdf4tcl verschlüsselt alle PDF-Literal-Strings `(...)` in Dictionaries
gemäß ISO 32000 §7.6.5. Das betrifft AcroForm-Felder (`/T`, `/DA`, `/V`,
`/TU`, `/CA`), Metadaten (`/Author`, `/Title`) und Bookmarks (`/Title`).

**Wechselwirkungen Formulare + Verschlüsselung — bekannte Punkte:**

- Feldnamen `/T` werden verschlüsselt → jedes Feld hat intern einen
  eigenen Namen, kein Überlapp
- Appearance Streams (AP-Dictionaries) sind Streams → werden durch
  `EncryptStreamBody` verschlüsselt
- Default Values `/V` werden als Literal-String verschlüsselt
- Pushbutton-Captions `/CA` werden verschlüsselt

**Validierung:** Getestet mit Evince, Firefox (PDF.js) und
`qpdf --check --password=...`. Chrome zeigt AcroForm generell nicht an
(viewer-seitige Einschränkung, unabhängig von Verschlüsselung).
