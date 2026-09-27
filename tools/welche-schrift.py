#!/usr/bin/env python3
"""welche-schrift.py -- welcher Text steht in welcher Schrift?

Beantwortet die eine Frage, an der die Adobe-Diagnose haengt: der Titel
zeichnet, der Rumpf nicht -- WELCHE Schrift ist das jeweils?

qpdf und poppler sagen "keine Beanstandung", und das stimmt: die Datei ist
syntaktisch gesund. Sie sagen nur nicht, welche der drei eingebetteten
Schriften den unsichtbaren Text traegt. Das macht dieses Skript: es geht
durch die Textobjekte, merkt sich das zuletzt gesetzte /Fxx, loest es ueber
die /Resources der Seite zum Schriftnamen auf und zeigt je Schrift, was
damit gezeichnet wird.

Aufruf:   python3 welche-schrift.py datei.pdf
Braucht:  qpdf im PATH. Sonst nichts.

Lesart:
  * Steht der fehlende Text unter genau EINER Schrift -- das ist die
    Schuldige. Dann deren Objekte mit einer zeichnenden vergleichen.
  * Verteilt er sich ueber alle -- dann liegt es nicht an der Schrift,
    sondern am Inhaltsstrom oder an der Seite.
  * Fehlt der Text ganz -- dann steht er gar nicht in der Datei, und der
    Fehler liegt vor dem PDF.
"""
import re
import subprocess
import sys
import tempfile
import os


def qdf(pfad):
    """Die Datei lesbar machen: Stroeme unkomprimiert, keine Objektstroeme."""
    ziel = tempfile.mktemp(suffix=".qdf")
    try:
        subprocess.run(
            ["qpdf", "--qdf", "--object-streams=disable", pfad, ziel],
            check=True, capture_output=True)
    except FileNotFoundError:
        sys.exit("qpdf nicht gefunden. apt install qpdf")
    except subprocess.CalledProcessError as e:
        # qpdf warnt gern und schreibt trotzdem
        if not os.path.exists(ziel):
            sys.exit("qpdf konnte die Datei nicht lesen:\n" + e.stderr.decode(errors="replace"))
    with open(ziel, "rb") as f:
        return f.read().decode("latin1"), ziel


def objekte(text):
    return {int(m.group(1)): m.group(2)
            for m in re.finditer(r'(\d+) 0 obj\n(.*?)\nendobj', text, re.S)}


def schriftnamen(objs):
    """Objektnummer -> BaseFont, fuer jedes Font-Objekt."""
    namen = {}
    for n, b in objs.items():
        if '/Type /Font' not in b and '/Type/Font' not in b:
            continue
        m = re.search(r'/BaseFont\s*/(\S+?)[\s/>]', b + " ")
        st = re.search(r'/Subtype\s*/(\w+)', b)
        namen[n] = (m.group(1) if m else "?", st.group(1) if st else "?")
    return namen


def main():
    if len(sys.argv) != 2:
        sys.exit(__doc__)
    text, tmp = qdf(sys.argv[1])
    objs = objekte(text)
    namen = schriftnamen(objs)

    # /Fxx -> Objektnummer, aus allen /Font-Woerterbuechern der Resources
    fzuo = {}
    for n, b in objs.items():
        for fm in re.finditer(r'/Font\s*<<(.*?)>>', b, re.S):
            for em in re.finditer(r'/(\w+)\s+(\d+)\s+0\s+R', fm.group(1)):
                fzuo[em.group(1)] = int(em.group(2))
    # /Font kann auch ein Verweis sein
    for n, b in objs.items():
        m = re.search(r'/Font\s+(\d+)\s+0\s+R', b)
        if m and m.group(1).isdigit():
            ziel = objs.get(int(m.group(1)), "")
            for em in re.finditer(r'/(\w+)\s+(\d+)\s+0\s+R', ziel):
                fzuo[em.group(1)] = int(em.group(2))

    if not fzuo:
        print("Keine Schrift-Zuordnung in den Resources gefunden.")
        return

    # Durch alle Stroeme gehen und Text je Schrift sammeln
    proSchrift = {}
    for m in re.finditer(r'stream\n(.*?)\nendstream', text, re.S):
        strom = m.group(1)
        if 'Tf' not in strom:
            continue
        aktuell = None
        for zeile in strom.split('\n'):
            tf = re.search(r'/(\w+)\s+[\d.]+\s+Tf', zeile)
            if tf:
                aktuell = tf.group(1)
            if 'Tj' in zeile or 'TJ' in zeile:
                stuecke = re.findall(r'<([0-9A-Fa-f]+)>', zeile)
                if not stuecke:
                    stuecke = re.findall(r'\((.*?)\)', zeile)
                if not stuecke:
                    continue
                gids = []
                for s in stuecke:
                    if re.fullmatch(r'[0-9A-Fa-f]+', s) and len(s) % 4 == 0:
                        gids += [int(s[i:i+4], 16) for i in range(0, len(s), 4)]
                proSchrift.setdefault(aktuell, {"zeilen": 0, "glyphen": 0, "probe": []})
                proSchrift[aktuell]["zeilen"] += 1
                proSchrift[aktuell]["glyphen"] += len(gids)
                if len(proSchrift[aktuell]["probe"]) < 3:
                    proSchrift[aktuell]["probe"].append(gids[:12])

    print(f"{len(namen)} Schrift-Objekte, {len(proSchrift)} davon benutzt\n")
    for fname in sorted(proSchrift, key=lambda x: (x is None, x)):
        d = proSchrift[fname]
        oid = fzuo.get(fname)
        name, subtype = namen.get(oid, ("?", "?"))
        print(f"/{fname}  ->  Obj {oid}  {name}  ({subtype})")
        print(f"    {d['zeilen']} Textzeilen, {d['glyphen']} Glyphen")
        for p in d["probe"]:
            print(f"      Glyphennummern: {p}")
        print()

    benutzt = {fzuo.get(f) for f in proSchrift}
    unbenutzt = set(namen) - benutzt
    if unbenutzt:
        print("Eingebettet, aber nirgends benutzt:")
        for o in sorted(unbenutzt):
            print(f"   Obj {o}  {namen[o][0]}")
    print(f"\n(lesbare Fassung: {tmp} -- dort die Objekte vergleichen)")


if __name__ == "__main__":
    main()
