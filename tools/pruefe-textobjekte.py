#!/usr/bin/env python3
"""pruefe-textobjekte.py -- steht jede Textausgabe zwischen BT und ET?

Der Befund vom 27.09.2026: in einem getaggten Spickzettel standen 133 von
146 Textausgaben AUSSERHALB eines Textobjekts:

    BT / Tm / ET / <</MCID 3>> BDC / <...> Tj / EMC
                ^^                    ^^^^^^^^^^
                zu frueh beendet      Tj steht draussen

ISO 32000-1 9.4: eine Textausgabe (Tj, TJ, ', ") gehoert zwischen BT und ET.
Der Adobe Reader zeichnet sie ausserhalb NICHT. poppler, mupdf und Chrome tun
es -- darum sagen qpdf, pdfinfo und pdffonts nichts, und darum sah die Datei
ueberall richtig aus ausser dort, wo sie zaehlte.

Genau die 13 Ausgaben, die drinnen standen, waren im Reader zu sehen: Titel,
Untertitel und elf Ueberschriften. Der Rest der Seite blieb leer.

Aufruf:   python3 pruefe-textobjekte.py datei.pdf [...]
Braucht:  qpdf im PATH.
Ausgang:  0 wenn alles drinnen steht, 1 sonst.
"""
import re
import subprocess
import sys
import tempfile
import os

TEXTOPS = re.compile(r"(?<![A-Za-z0-9])(Tj|TJ)(?![A-Za-z0-9])")

# ' und " sind ebenfalls Textausgaben, aber ein einzelnes Zeichen findet sich
# in jedem Binaerstrom. Gemessen am 27.09.2026 an demo-cat-1b-a.pdf: das
# eingebettete ICC-Profil enthielt vier davon und wurde als Fehler gemeldet.
# Darum nur, wenn die Zeile aussieht wie eine Textausgabe: eine Zeichenkette
# oder Zahl, dann der Operator, dann Zeilenende.
TEXTOPS_KURZ = re.compile(r"""[)\]>\d]\s*['"]\s*$""")

# Ein Inhaltsstrom ist Text. Ein Bild- oder Profilstrom ist es nicht -- auch
# nicht nach dem Auspacken durch qpdf.
def istText(strom):
    if not strom:
        return False
    roh = strom.encode("latin1", "replace")
    schlecht = sum(1 for b in roh if b < 9 or (13 < b < 32) or b > 126)
    return schlecht * 20 < len(roh)


def qdf(pfad):
    ziel = tempfile.mktemp(suffix=".qdf")
    try:
        subprocess.run(["qpdf", "--qdf", "--object-streams=disable", pfad, ziel],
                       check=True, capture_output=True)
    except FileNotFoundError:
        sys.exit("qpdf nicht gefunden. apt install qpdf")
    except subprocess.CalledProcessError as e:
        if not os.path.exists(ziel):
            print(f"   qpdf kann {pfad} nicht lesen: "
                  f"{e.stderr.decode(errors='replace').strip()[:100]}")
            return None
    with open(ziel, "rb") as f:
        daten = f.read().decode("latin1")
    os.unlink(ziel)
    return daten


def pruefe(pfad):
    daten = qdf(pfad)
    if daten is None:
        return None
    drin = draussen = 0
    stellen = []
    for m in re.finditer(r'stream\n(.*?)\nendstream', daten, re.S):
        strom = m.group(1)
        if 'BT' not in strom or not istText(strom):
            continue
        offen = False
        zeilen = strom.split('\n')
        for i, z in enumerate(zeilen):
            s = z.strip()
            # BT und ET stehen bei pdf4tcl allein auf der Zeile; zur Sicherheit
            # auch am Zeilenende erkennen.
            if re.search(r'(?<![A-Za-z0-9])BT(?![A-Za-z0-9])', s):
                offen = True
            if TEXTOPS.search(s) or TEXTOPS_KURZ.search(s):
                if offen:
                    drin += 1
                else:
                    draussen += 1
                    if len(stellen) < 3:
                        anfang = max(0, i - 4)
                        stellen.append(zeilen[anfang:i + 2])
            if re.search(r'(?<![A-Za-z0-9])ET(?![A-Za-z0-9])', s):
                offen = False
    return drin, draussen, stellen


def main():
    if len(sys.argv) < 2:
        sys.exit(__doc__)
    schlecht = 0
    for pfad in sys.argv[1:]:
        e = pruefe(pfad)
        if e is None:
            schlecht += 1
            continue
        drin, draussen, stellen = e
        name = os.path.basename(pfad)
        if draussen:
            schlecht += 1
            anteil = draussen * 100 // (drin + draussen)
            print(f"FEHLER  {name}: {draussen} von {drin + draussen} "
                  f"Textausgaben ausserhalb BT/ET ({anteil} %)")
            for umgebung in stellen:
                print("        ...")
                for z in umgebung:
                    print(f"        {z[:88]}")
        else:
            print(f"ok      {name}: alle {drin} Textausgaben stehen in einem Textobjekt")
    sys.exit(1 if schlecht else 0)


if __name__ == "__main__":
    main()
