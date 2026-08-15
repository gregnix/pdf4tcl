#!/usr/bin/env python3
"""Check PDFs against the conformance they claim, with veraPDF.

Reads each file's XMP packet, works out which profiles it claims -- pdfaid
gives the PDF/A part and level, pdfuaid gives PDF/UA -- and runs veraPDF
against exactly those. A document that claims nothing is reported as such
rather than validated against a profile it never promised.

That is the point of the tool: it finds the gap between what a document says
about itself and what it is. Running everything against a fixed profile list
mostly produces failures that were never in question -- an untagged invoice
is not PDF/UA, and saying so is not information.

Usage:
    check-conformance.py file.pdf [file.pdf ...]
    check-conformance.py out/                  # every *.pdf below a directory
    check-conformance.py -p 3a -p ua1 file.pdf # force profiles instead
    check-conformance.py --rules out/          # list failing rules, not just
                                               # the verdict

Exit code 0 = every claim held, 1 = at least one did not, 2 = veraPDF or a
file was missing.
Requires veraPDF on PATH. pypdf is used when present; without it the XMP is
read with a regular expression, which is enough for the identification
schemas.
"""

import argparse
import os
import re
import subprocess
import sys
import xml.etree.ElementTree as ET

# veraPDF profile flags, in the order they should be reported
PDFA_FLAG = {("1", "A"): "1a", ("1", "B"): "1b",
             ("2", "A"): "2a", ("2", "B"): "2b", ("2", "U"): "2u",
             ("3", "A"): "3a", ("3", "B"): "3b", ("3", "U"): "3u",
             ("4", ""): "4"}


def read_xmp(path):
    """Return the XMP packet of a PDF as text, or "" when there is none."""
    try:
        from pypdf import PdfReader
        root = PdfReader(path).trailer["/Root"]
        md = root.get("/Metadata")
        if md is None:
            return ""
        return md.get_object().get_data().decode("utf-8", "replace")
    except Exception:
        pass
    # Without pypdf, or for an encrypted file: the identification schemas sit
    # in an uncompressed metadata stream in every file pdf4tcl writes, so a
    # plain search over the bytes finds them.
    try:
        with open(path, "rb") as fh:
            data = fh.read()
    except OSError:
        return ""
    m = re.search(rb"<x:xmpmeta.*?</x:xmpmeta>", data, re.S)
    return m.group(0).decode("utf-8", "replace") if m else ""


def claims(path):
    """Which profiles does this document claim? Returns a list of flags."""
    xmp = read_xmp(path)
    out = []
    part = re.search(r"<pdfaid:part>\s*(\d)\s*</pdfaid:part>", xmp)
    conf = re.search(r"<pdfaid:conformance>\s*(\w)\s*</pdfaid:conformance>", xmp)
    if part:
        key = (part.group(1), conf.group(1).upper() if conf else "")
        if key in PDFA_FLAG:
            out.append(PDFA_FLAG[key])
        else:
            out.append("?pdfa-%s%s" % key)
    if re.search(r"<pdfuaid:part>\s*[12]\s*</pdfuaid:part>", xmp):
        out.append("ua1")
    return out


def run_verapdf(path, flag):
    """Run veraPDF once. Returns (compliant, rules) with rules as a list of
    (clause, testNumber, failedChecks, description)."""
    try:
        proc = subprocess.run(["verapdf", "-f", flag, path],
                              capture_output=True, text=True, timeout=300)
    except FileNotFoundError:
        print("verapdf not found on PATH", file=sys.stderr)
        sys.exit(2)
    except subprocess.TimeoutExpired:
        return None, [("timeout", "", "", "veraPDF did not finish")]
    # veraPDF writes warnings to stdout before the XML, so start at the
    # declaration rather than parsing the whole stream.
    start = proc.stdout.find("<?xml")
    if start < 0:
        return None, [("no-report", "", "", proc.stdout.strip()[:120])]
    try:
        root = ET.fromstring(proc.stdout[start:])
    except ET.ParseError as exc:
        return None, [("bad-xml", "", "", str(exc)[:120])]

    rep = root.find(".//validationReport")
    if rep is None:
        return None, [("no-report", "", "", "no validationReport element")]
    compliant = rep.get("isCompliant") == "true"
    rules = []
    for rule in rep.findall(".//rule[@status='failed']"):
        rules.append((rule.get("clause", "?"),
                      rule.get("testNumber", "?"),
                      rule.get("failedChecks", "?"),
                      (rule.findtext("description") or "").strip()))
    return compliant, rules


def collect(paths):
    files = []
    for p in paths:
        if os.path.isdir(p):
            for dirpath, _, names in os.walk(p):
                for n in sorted(names):
                    if n.lower().endswith(".pdf"):
                        files.append(os.path.join(dirpath, n))
        elif os.path.isfile(p):
            files.append(p)
        else:
            print("no such file or directory: %s" % p, file=sys.stderr)
            sys.exit(2)
    return files


def main():
    ap = argparse.ArgumentParser(
        description="Check PDFs against the conformance they claim.")
    ap.add_argument("paths", nargs="+", metavar="PDF|DIR")
    ap.add_argument("-p", "--profile", action="append", dest="profiles",
                    metavar="FLAG",
                    help="check this profile instead of the claimed ones; "
                         "repeatable (3a, 3b, ua1, ...)")
    ap.add_argument("--rules", action="store_true",
                    help="print the failing rules, not just the verdict")
    ap.add_argument("-q", "--quiet", action="store_true",
                    help="print only files that fail")
    args = ap.parse_args()

    files = collect(args.paths)
    if not files:
        print("no PDF files found")
        return 0

    width = min(max(len(os.path.basename(f)) for f in files), 42)
    failed = 0
    unclaimed = 0

    for path in files:
        name = os.path.basename(path)
        profiles = args.profiles or claims(path)

        if not profiles:
            unclaimed += 1
            if not args.quiet:
                print("%-*s  %s" % (width, name[:width], "claims nothing"))
            continue

        for flag in profiles:
            if flag.startswith("?"):
                print("%-*s  %-4s %s" % (width, name[:width], "", 
                                         "unknown claim " + flag[1:]))
                failed += 1
                continue
            compliant, rules = run_verapdf(path, flag)
            if compliant:
                if not args.quiet:
                    print("%-*s  %-4s ok" % (width, name[:width], flag))
                continue
            failed += 1
            print("%-*s  %-4s FAILED%s" % (
                width, name[:width], flag,
                "" if compliant is not None else " (no verdict)"))
            if args.rules or compliant is None:
                for clause, test, count, desc in rules:
                    print("%-*s       %s-%s  %s check(s)  %s" % (
                        width, "", clause, test, count, desc[:70]))

    print("-" * (width + 20))
    print("%d file(s), %d check(s) failed, %d claiming nothing"
          % (len(files), failed, unclaimed))
    return 1 if failed else 0


if __name__ == "__main__":
    sys.exit(main())
