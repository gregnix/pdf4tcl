pdf4tcl patch: Fix ticket #22 -- metadata/bookmarkAdd without setFont
Version: 0.9.4.2
Date:    2026-03-08
Author:  Gregor (gregnix@github)

Problem
-------
When metadata or bookmarkAdd is called before any setFont, pdf4tcl
crashes with:
  Can't read "FontsAttrs(,specialencoding)": no such element in array

The root cause is that CleanText requires a font to be set
($pdf(current_font)), but metadata strings and bookmark titles do not
need font encoding -- they are plain PDF Info Dictionary strings.

Fix
---
Replace CleanText with QuoteString for:
  src/main.tcl line 712: metadata dictionary values
  src/main.tcl line 892: bookmarkAdd -title

QuoteString escapes PDF special characters (parentheses, backslash)
without requiring any font state.

Files
-----
  fix22-main.patch   -- 2-line fix in src/main.tcl
  fix22-page.patch   -- 5 new tests in tests/page.test

Apply
-----
  patch -p1 < fix22-main.patch
  patch -p1 < fix22-page.patch
  # Then rebuild pdf4tcl.tcl:
  cat src/prologue.tcl src/fonts.tcl src/helpers.tcl \
      src/options.tcl src/main.tcl src/cat.tcl > pdf4tcl.tcl

Fork
----
  https://github.com/gregnix/pdf4tcl
