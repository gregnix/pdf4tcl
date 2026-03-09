Ticket #17 -- -align right incorrect when string contains unmappable chars

Problem:
  When a string contains characters outside the WinAnsi encoding (e.g.
  CJK ideographs), CleanText substitutes them with "?". However,
  getStringWidth (called before CleanText) returned width 0.0 for each
  unmappable char because GetCharWidth fell through to 0.0 on a failed
  dict lookup. The -align right/center offset was therefore calculated
  from a wrong (too small) width.

Fix (src/fonts.tcl -- GetCharWidth):
  When a codepoint is not found in charWidths, fall back to the width of
  "?" (codepoint 63) instead of 0.0. This matches what CleanText actually
  renders, so getStringWidth and -align right/center are consistent.

Files changed:
  src/fonts.tcl     -- GetCharWidth: fallback to width of "?" (0x3F)
  tests/util.test   -- util-6.1..6.3: new tests for the fallback

Patch files:
  fix17-fonts.patch  -- src/fonts.tcl
  fix17-util.patch   -- tests/util.test
