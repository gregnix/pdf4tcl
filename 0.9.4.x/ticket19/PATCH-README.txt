Ticket #19 -- Support for moddate and viewer instructions

Changes:
  metadata: new -moddate option (clock seconds value, 0 = current time)
  metadata: unknown options now throw an error
  viewerPreferences: new method, sets /ViewerPreferences in PDF catalog
                     Options: -pagelayout, -pagemode, -hidetoolbar, -hidemenubar,
                     -hidewindowui, -fitwindow, -centerwindow, -displaydoctitle,
                     -nonfullscreenpagemode, -direction, -printscaling, -duplex

File: src/main.tcl
Apply patch:
    patch -p1 < fix19-main.patch
    make
