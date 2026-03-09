Ticket #24 -- A CMap has too many code maps
============================================

Reported by: holgerjakobs (SourceForge)
Fixed in:    pdf4tcl fork 0.9.4.6

Problem
-------
Ghostscript 10.04.0 (and PDF validators) emit the warning
"A CMap has too many code maps" when processing PDFs generated
by pdf4tcl. The PDF spec (section 9.10.3) requires that each
beginbfchar block contains at most 100 entries. pdf4tcl's
MakeToUnicodeCMap wrote a single block for the entire encoding
(up to 256 entries for a full WinAnsi font), violating this limit.

This error appears when embedding PDF invoices as ZUGFERD attachments
via Ghostscript, because Ghostscript repairs the file but logs the
violation.

Fix
---
In src/fonts.tcl, proc MakeToUnicodeCMap: replace the single
beginbfchar block with a loop that writes chunks of at most 100
entries each.

Files changed
-------------
src/fonts.tcl    MakeToUnicodeCMap: chunked beginbfchar blocks

Tests
-----
tests/util.test: util-7.1, util-7.2, util-7.3

Apply to upstream pdf4tcl 0.9.4:
---------------------------------
  patch -p1 < fix24-fonts.patch
  cat src/prologue.tcl src/fonts.tcl src/helpers.tcl \
      src/options.tcl src/main.tcl src/cat.tcl > pdf4tcl.tcl
