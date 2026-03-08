Ticket #14 -- createFontSpecEnc: enforce 256-codepoint limit
=============================================================

Fix in: src/fonts.tcl
Tests:  tests/font.test (font-7.x)

Problem:
  createFontSpecEnc accepted subsets larger than 256 codepoints
  which silently produced invalid PDFs.

Fix:
  Added a guard at the start of createFontSpecEnc:
    throw "PDF4TCL" "createFontSpecEnc: subset must not exceed 256 codepoints (got N)"

Files:
  fix14-fonts.patch  -- patch for src/fonts.tcl
  fix14-font.patch   -- patch for tests/font.test

Apply:
  patch -p0 < fix14-fonts.patch
  patch -p0 < fix14-font.patch

Source: https://github.com/gregnix/pdf4tcl
