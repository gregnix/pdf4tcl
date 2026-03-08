Ticket #23 -- pageLabel: custom page numbering
==============================================

Fix in: src/main.tcl
Tests:  tests/page.test (page-11.x)

Problem:
  No way to set custom page labels (e.g. i ii iii for front matter,
  1 2 3 for body, A-1 A-2 for appendix).

Fix:
  New method pageLabel:
    $pdf pageLabel pageIndex ?-style D|r|R|a|A? ?-start N? ?-prefix str?

  Writes /PageLabels into the PDF catalog.

Note: fix19-23-main.patch also contains ticket #19 (viewerPreferences).

Files:
  fix19-23-main.patch -- patch for src/main.tcl (tickets 19+23 combined)

Apply:
  patch -p0 < fix19-23-main.patch
  patch -p0 < ../ticket18/fix18-19-23-page.patch

Source: https://github.com/gregnix/pdf4tcl
