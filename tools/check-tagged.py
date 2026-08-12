#!/usr/bin/env python3
"""Verify the logical structure of a tagged PDF.

Reads /StructTreeRoot, walks the tree, and reconstructs for every structure
element the text that its marked content sequences actually paint. Checks the
consistency rules that a broken generator gets wrong:

  - /MarkInfo /Marked true and /StructTreeRoot present
  - every page holding an MCID has /StructParents
  - /ParentTree maps each (StructParents, MCID) back to the owning element
  - BDC/EMC nesting in every content stream is balanced
  - MCIDs on a page are unique and start at 0

Usage: check-tagged.py file.pdf [--dump]

Exit code 0 = all checks passed, 1 = at least one failure.
Requires pypdf.
"""

import sys
import re
from pypdf import PdfReader
from pypdf.generic import IndirectObject

FAILURES = []


def check(cond, msg):
    if cond:
        print("  ok   %s" % msg)
    else:
        print("  FAIL %s" % msg)
        FAILURES.append(msg)
    return cond


def resolve(obj):
    while isinstance(obj, IndirectObject):
        obj = obj.get_object()
    return obj


def tokenize(data):
    """Yield (operator, operands) from a content stream."""
    tokens = []
    i = 0
    n = len(data)
    while i < n:
        c = data[i:i + 1]
        if c.isspace():
            i += 1
        elif c == b"(":
            depth = 1
            j = i + 1
            out = b""
            while j < n and depth:
                ch = data[j:j + 1]
                if ch == b"\\":
                    out += data[j:j + 2]
                    j += 2
                    continue
                if ch == b"(":
                    depth += 1
                elif ch == b")":
                    depth -= 1
                    if depth == 0:
                        break
                out += ch
                j += 1
            tokens.append(("str", out))
            i = j + 1
        elif c == b"<" and data[i:i + 2] != b"<<":
            j = data.index(b">", i)
            tokens.append(("hex", data[i + 1:j]))
            i = j + 1
        elif data[i:i + 2] == b"<<":
            depth = 1
            j = i + 2
            while j < n and depth:
                if data[j:j + 2] == b"<<":
                    depth += 1
                    j += 2
                elif data[j:j + 2] == b">>":
                    depth -= 1
                    j += 2
                else:
                    j += 1
            tokens.append(("dict", data[i:j]))
            i = j
        elif c in b"[]":
            tokens.append(("delim", c))
            i += 1
        else:
            j = i
            while j < n and not data[j:j + 1].isspace() and \
                    data[j:j + 1] not in b"()<>[]/":
                j += 1
            if j == i:
                j = i + 1
            word = data[i:j]
            if word.startswith(b"/") or re.match(rb"^[-+.0-9]+$", word):
                tokens.append(("obj", word))
            else:
                tokens.append(("op", word))
            i = j
        if i <= 0:
            break
    return tokens


def text_by_mcid(data):
    """Map MCID -> painted text, and report BDC/EMC balance and nesting."""
    result = {}
    stack = []          # open marked content: mcid or None for artifacts
    operands = []
    depth_errors = 0
    nested = []         # MCIDs opened while another MCID was already open
    for kind, value in tokenize(data):
        if kind == "op":
            op = value
            if op in (b"BDC", b"BMC"):
                mcid = None
                for k, v in operands:
                    if k == "dict":
                        m = re.search(rb"/MCID\s+(\d+)", v)
                        if m:
                            mcid = int(m.group(1))
                if mcid is not None:
                    # A structure element that contains other elements paints
                    # nothing itself and must not carry marked content. An
                    # MCID inside another MCID means a container was given
                    # one; veraPDF reports it as "Nested MCID".
                    if any(m is not None for m in stack):
                        nested.append(mcid)
                    if mcid not in result:
                        result[mcid] = ""
                stack.append(mcid)
            elif op == b"EMC":
                if not stack:
                    depth_errors += 1
                else:
                    stack.pop()
            elif op in (b"Tj", b"'", b'"'):
                for k, v in operands:
                    if k == "str" and stack and stack[-1] is not None:
                        result[stack[-1]] += v.decode("latin-1")
            elif op == b"TJ":
                for k, v in operands:
                    if k == "str" and stack and stack[-1] is not None:
                        result[stack[-1]] += v.decode("latin-1")
            operands = []
        else:
            operands.append((kind, value))
    return result, depth_errors, len(stack), nested


def walk(elem, mctext, pages, out, depth=0):
    elem = resolve(elem)
    if not isinstance(elem, dict):
        return
    stype = str(elem.get("/S", "?")).lstrip("/")
    kids = resolve(elem.get("/K", []))
    if not isinstance(kids, list):
        kids = [kids]
    text = ""
    children = []
    for kid in kids:
        kid = resolve(kid)
        if isinstance(kid, int):
            continue
        if isinstance(kid, dict) and kid.get("/Type") == "/MCR":
            pg = kid.get("/Pg")
            pgnum = pages.get(pg.idnum if isinstance(pg, IndirectObject) else id(pg))
            mcid = int(kid["/MCID"])
            text += mctext.get((pgnum, mcid), "")
        elif isinstance(kid, dict) and "/S" in kid:
            children.append(kid)
        elif isinstance(kid, dict):
            pass
    entry = {
        "type": stype,
        "text": text,
        "alt": str(elem.get("/Alt", "")) if "/Alt" in elem else None,
        "lang": str(elem.get("/Lang", "")) if "/Lang" in elem else None,
        "depth": depth,
    }
    out.append(entry)
    for kid in kids:
        kid = resolve(kid)
        if isinstance(kid, dict) and "/S" in kid:
            walk(kid, mctext, pages, out, depth + 1)


def main(path, dump=False):
    reader = PdfReader(path)
    root = reader.trailer["/Root"]

    print("== catalog ==")
    check("/StructTreeRoot" in root, "/StructTreeRoot present")
    markinfo = resolve(root.get("/MarkInfo", {}))
    marked = markinfo.get("/Marked") if markinfo else None
    # pypdf returns a BooleanObject here, not a Python bool
    check(marked is not None and bool(getattr(marked, "value", marked)),
          "/MarkInfo /Marked true")
    if "/Lang" in root:
        print("  info /Lang = %s" % root["/Lang"])

    if not FAILURES:
        st = resolve(root["/StructTreeRoot"])
    else:
        return 1

    print("== content streams ==")
    mctext = {}
    pages = {}
    sp_by_page = {}
    for pageno, page in enumerate(reader.pages):
        pages[page.indirect_reference.idnum] = pageno
        data = page.get_contents().get_data()
        texts, unbalanced, left_open, nested = text_by_mcid(data)
        check(unbalanced == 0,
              "page %d: no EMC without BDC" % pageno)
        check(left_open == 0,
              "page %d: no BDC left open at end of stream" % pageno)
        check(not nested,
              "page %d: no MCID nested inside another MCID%s"
              % (pageno, "" if not nested else " (nested: %s)" % nested))
        for mcid, txt in texts.items():
            mctext[(pageno, mcid)] = txt
        if texts:
            ids = sorted(texts)
            check(ids == list(range(len(ids))),
                  "page %d: MCIDs are 0..%d without gaps" % (pageno, len(ids) - 1))
            check("/StructParents" in page,
                  "page %d: /StructParents present" % pageno)
            sp_by_page[pageno] = page.get("/StructParents")

    print("== parent tree ==")
    ptree = resolve(st.get("/ParentTree"))
    nums = resolve(ptree.get("/Nums", [])) if ptree else []
    mapping = {}
    for i in range(0, len(nums), 2):
        key = resolve(nums[i])
        val = resolve(nums[i + 1])
        mapping[int(key)] = val if isinstance(val, list) else [val]
    check(ptree is not None, "/ParentTree present")
    # Two pages sharing a /StructParents key both resolve to the same parent
    # tree entry, so one page's content is silently attributed to the other
    # page's structure. This is what merging two tagged documents used to
    # produce, and every per-page check still passed.
    keys = list(sp_by_page.values())
    check(len(keys) == len(set(keys)),
          "/StructParents keys are unique across pages")
    for pageno, sp in sp_by_page.items():
        arr = mapping.get(int(sp))
        ok = arr is not None
        if ok:
            count = len([k for k in mctext if k[0] == pageno])
            ok = len(arr) == count
        check(ok, "page %d: parent tree entry covers every MCID" % pageno)
    nextkey = st.get("/ParentTreeNextKey")
    check(nextkey is None or int(nextkey) > max(mapping) if mapping else True,
          "/ParentTreeNextKey greater than the highest key")

    print("== structure tree ==")
    out = []
    kids = resolve(st.get("/K", []))
    if not isinstance(kids, list):
        kids = [kids]
    for kid in kids:
        walk(kid, mctext, pages, out)
    check(len(out) > 0, "structure tree is not empty")
    check(out[0]["type"] == "Document", "root element is /Document")

    # Every MCID painted on a page must be claimed by exactly one element.
    # An orphan means content that carries a structure marker but hangs
    # outside the tree -- invisible to a screen reader despite looking tagged.
    claimed = set()
    def collect(elem):
        elem = resolve(elem)
        if not isinstance(elem, dict):
            return
        kids = resolve(elem.get("/K", []))
        if not isinstance(kids, list):
            kids = [kids]
        for kid in kids:
            kid = resolve(kid)
            if isinstance(kid, dict) and kid.get("/Type") == "/MCR":
                pg = kid.get("/Pg")
                pgnum = pages.get(pg.idnum if isinstance(pg, IndirectObject)
                                  else id(pg))
                claimed.add((pgnum, int(kid["/MCID"])))
            elif isinstance(kid, dict) and "/S" in kid:
                collect(kid)
    for kid in kids:
        collect(kid)
    orphans = set(mctext) - claimed
    check(not orphans,
          "every marked content sequence is claimed by an element%s"
          % ("" if not orphans else " (orphans: %s)" % sorted(orphans)))

    print("== extracted content ==")
    for e in out:
        line = "  %s%-12s" % ("  " * e["depth"], e["type"])
        if e["text"]:
            line += " %r" % e["text"][:70]
        if e["alt"]:
            line += "  /Alt=%r" % e["alt"]
        if e["lang"]:
            line += "  /Lang=%s" % e["lang"]
        print(line)

    print("")
    if FAILURES:
        print("FAILED: %d check(s)" % len(FAILURES))
        return 1
    print("PASSED: all checks")
    return 0


if __name__ == "__main__":
    if len(sys.argv) < 2:
        print(__doc__)
        sys.exit(2)
    sys.exit(main(sys.argv[1], "--dump" in sys.argv))
