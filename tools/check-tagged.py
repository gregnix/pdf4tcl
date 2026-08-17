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
            elif op in (b"Tj", b"'", b'"', b"TJ"):
                for k, v in operands:
                    if stack and stack[-1] is not None:
                        if k == "str":
                            result[stack[-1]] += v.decode("latin-1")
                        elif k == "hex":
                            # A CID font writes glyph indices as a hex string.
                            # Turning those back into characters needs the
                            # font's CMap, which is more than this tool does.
                            # The marker keeps the element from looking empty,
                            # which would read as a defect in the document
                            # rather than a limit of the checker.
                            result[stack[-1]] += "<CID>"
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
            mcid = int(kid["/MCID"])
            stm = kid.get("/Stm")
            if stm is not None:
                # Inside a form XObject the text is keyed by the stream.
                # Without this the dump showed such elements empty, which
                # was the only sign that the checker never looked inside.
                num = stm.idnum if isinstance(stm, IndirectObject) else None
                text += mctext.get(("stm", num, mcid), "")
                continue
            pg = kid.get("/Pg")
            pgnum = pages.get(pg.idnum if isinstance(pg, IndirectObject) else id(pg))
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

    # Form XObjects carry their own marked content (ISO 32000-1 clause
    # 14.7.4.4): MCIDs are scoped to the stream, the XObject dictionary has
    # its own /StructParents, and every /MCR pointing into it names the
    # stream in /Stm.
    #
    # This section did not exist until 0.9.4.46. Without it the checker
    # printed "PASSED: all checks" for a document whose XObject content it
    # had never opened -- the P element in the dump showed up with no text
    # at all, which was the only visible hint.
    xobj_streams = {}          # object number -> {mcid: text}
    for pageno, page in enumerate(reader.pages):
        res = resolve(page.get("/Resources", {})) or {}
        xobjs = resolve(res.get("/XObject", {})) or {}
        for name, ref in xobjs.items():
            num = ref.idnum if isinstance(ref, IndirectObject) else None
            xo = resolve(ref)
            if not isinstance(xo, dict):
                continue
            if str(xo.get("/Subtype")) != "/Form":
                continue
            if num in xobj_streams:
                continue
            try:
                data = xo.get_data()
            except Exception:
                continue
            texts, unbalanced, left_open, nested = text_by_mcid(data)
            if not texts:
                continue
            print("== XObject %d ==" % num)
            check(unbalanced == 0, "XObject %d: no EMC without BDC" % num)
            check(left_open == 0,
                  "XObject %d: no BDC left open at end of stream" % num)
            check(not nested,
                  "XObject %d: no MCID nested inside another MCID" % num)
            ids = sorted(texts)
            check(ids == list(range(len(ids))),
                  "XObject %d: MCIDs are 0..%d without gaps" % (num, len(ids) - 1))
            check("/StructParents" in xo,
                  "XObject %d: /StructParents present" % num)
            xobj_streams[num] = texts
            for mcid, txt in texts.items():
                mctext[("stm", num, mcid)] = txt

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

    print("== annotations ==")
    # Every annotation reachable from a page must be claimed by exactly one
    # structure element through an /OBJR, and its /StructParent must resolve
    # back to that same element. A link that is only in /Annots but not in the
    # tree is invisible to a screen reader even though it works on click.
    annots_by_obj = {}
    for pageno, page in enumerate(reader.pages):
        for a in resolve(page.get("/Annots", [])) or []:
            num = a.idnum if isinstance(a, IndirectObject) else None
            annots_by_obj[num] = (pageno, resolve(a))
    rootkids = resolve(st.get("/K", []))
    if not isinstance(rootkids, list):
        rootkids = [rootkids]

    # Every MCID inside an XObject must be claimed by an /MCR that names the
    # stream in /Stm. Without /Stm the reference means "MCID n of the page",
    # where that number belongs to different content or does not exist --
    # the file stays valid PDF and the reading order is quietly wrong.
    if xobj_streams:
        stm_refs = {}          # stream object number -> set of MCIDs claimed
        def collect_stm(elem):
            elem = resolve(elem)
            if not isinstance(elem, dict):
                return
            kids = resolve(elem.get("/K", []))
            if not isinstance(kids, list):
                kids = [kids]
            for k in kids:
                k = resolve(k)
                if isinstance(k, dict) and str(k.get("/Type")) == "/MCR":
                    stm = k.get("/Stm")
                    if stm is not None:
                        num = stm.idnum if isinstance(stm, IndirectObject) else None
                        stm_refs.setdefault(num, set()).add(int(k.get("/MCID")))
                elif isinstance(k, dict):
                    collect_stm(k)
        for kid in rootkids:
            collect_stm(kid)
        for num, texts in xobj_streams.items():
            claimed = stm_refs.get(num, set())
            missing = sorted(set(texts) - claimed)
            check(not missing,
                  "XObject %d: every MCID is claimed by an /MCR with /Stm%s"
                  % (num, "" if not missing else " (missing: %s)" % missing))

    objr = {}
    def collect_objr(elem, oid_of):
        elem = resolve(elem)
        if not isinstance(elem, dict):
            return
        kids = resolve(elem.get("/K", []))
        if not isinstance(kids, list):
            kids = [kids]
        for kid in kids:
            k = resolve(kid)
            if isinstance(k, dict) and k.get("/Type") == "/OBJR":
                ref = k.get("/Obj")
                if isinstance(ref, IndirectObject):
                    objr.setdefault(ref.idnum, []).append(elem)
            elif isinstance(k, dict) and "/S" in k:
                collect_objr(k, oid_of)
    for kid in rootkids:
        collect_objr(kid, None)

    if not annots_by_obj and not objr:
        print("  info no annotations in this document")
    else:
        for num, elems in objr.items():
            check(len(elems) == 1,
                  "annotation %s is claimed by exactly one element" % num)
            check(num in annots_by_obj,
                  "annotation %s referenced by /OBJR is in a page /Annots"
                  % num)
        for num, (pageno, a) in annots_by_obj.items():
            claimed = num in objr
            check(claimed,
                  "annotation %s on page %d is claimed by an /OBJR"
                  % (num, pageno))
            sp = a.get("/StructParent")
            check(sp is not None,
                  "annotation %s carries /StructParent" % num)
            if sp is not None and claimed:
                target = resolve(mapping.get(int(sp), [None])
                                 if not isinstance(mapping.get(int(sp)), list)
                                 else mapping.get(int(sp))[0])
                entry = mapping.get(int(sp))
                # For an annotation the parent tree entry is a single element,
                # not an array; pypdf hands back the resolved object either way
                if isinstance(entry, list) and len(entry) == 1:
                    entry = entry[0]
                same = resolve(entry) is not None and \
                    resolve(entry).get("/S") == objr[num][0].get("/S")
                check(same,
                      "annotation %s /StructParent resolves to its element"
                      % num)
            if a.get("/Subtype") == "/Link":
                check("/Contents" in a,
                      "link annotation %s carries /Contents" % num)
        # ISO 14289-1 clause 7.18.3
        for pageno, page in enumerate(reader.pages):
            if resolve(page.get("/Annots", [])):
                check(str(page.get("/Tabs")) == "/S",
                      "page %d with annotations uses /Tabs /S" % pageno)

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
                stm = kid.get("/Stm")
                if stm is not None:
                    # Content inside a form XObject is keyed by the stream,
                    # not by the page -- the same key text_by_mcid used for
                    # the XObject section above.
                    num = stm.idnum if isinstance(stm, IndirectObject) else None
                    claimed.add(("stm", num, int(kid["/MCID"])))
                    continue
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

    # Heading order. ISO 14289-1 clause 7.4.2: headings run in ascending
    # order without skipping a level, in the order of the structure tree --
    # which is the reading order, not the order things appear on the page.
    #
    # This check did not exist until the XObject demo failed veraPDF with
    # PDF/UA while every check here said "ok". Its tree started with an H2
    # from an XObject built at the top of the script, and the page's H1
    # followed. Nothing in the file was malformed; the reading order was.
    levels = []
    for entry in out:
        t = entry["type"]
        if len(t) == 2 and t[0] == "H" and t[1].isdigit():
            levels.append(int(t[1]))
    if levels:
        problems = []
        if levels[0] != 1:
            problems.append("starts with H%d" % levels[0])
        prev = levels[0]
        for lv in levels[1:]:
            if lv > prev + 1:
                problems.append("H%d follows H%d" % (lv, prev))
            prev = lv
        check(not problems,
              "headings are in ascending order without gaps%s"
              % ("" if not problems else " (%s)" % ", ".join(problems)))

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
