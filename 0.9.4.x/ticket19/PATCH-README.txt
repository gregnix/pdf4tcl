Ticket #19 -- viewerPreferences + metadata -moddate
====================================================

Fix in: src/main.tcl
Tests:  tests/page.test (page-9.x, page-10.x)

Changes:
  1. New method viewerPreferences with options:
       -pagelayout -pagemode -hidetoolbar -hidemenubar -hidewindowui
       -fitwindow -centerwindow -displaydoctitle -nonfullscreenpagemode
       -direction -printscaling -duplex
  2. metadata: new -moddate option (0 = current time, or clock seconds value)
  3. metadata: unknown options now throw "PDF4TCL" error

Note: fix19-23-main.patch also contains ticket #23 (pageLabel).

Files:
  fix19-23-main.patch    -- patch for src/main.tcl (tickets 19+23 combined)
  fix18-19-23-page.patch -- combined patch for tests/page.test (in ticket18/)

Apply:
  patch -p0 < fix19-23-main.patch
  patch -p0 < ../ticket18/fix18-19-23-page.patch

Source: https://github.com/gregnix/pdf4tcl
