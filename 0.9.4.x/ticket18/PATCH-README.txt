Ticket #18 -- getLineHeight: new method
=======================================

Fix in: src/main.tcl
Tests:  tests/page.test (page-8.x)

Problem:
  No way to query the current line height in document units.
  getLineSpacing returns only the dimensionless multiplier.

Fix:
  New method getLineHeight returns font_size * line_spacing / pdf(unit).
  Requires a font to be set first.

Files:
  fix18-main.patch       -- patch for src/main.tcl
  fix18-19-23-page.patch -- combined patch for tests/page.test (tickets 18/19/23)

Apply:
  patch -p0 < fix18-main.patch
  patch -p0 < fix18-19-23-page.patch

Source: https://github.com/gregnix/pdf4tcl
