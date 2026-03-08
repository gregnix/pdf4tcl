pdf4tcl patch: Add hyperlinkAdd -- URI link annotations [SF ticket #15]
Version: 0.9.4.3
Date:    2026-03-08
Author:  Gregor (gregnix@github)

New method: hyperlinkAdd x y width height url ?options?

  Creates a PDF Link annotation (/Subtype /Link) with a URI action.
  The clickable area is defined by x y width height in current units.

Options
-------
  -borderwidth  n        border width in points, 0 = no border (default: 0)
  -bordercolor  color    border color, any pdf4tcl color        (default: {0 0 1})
  -borderradius n        corner radius in points                (default: 0)
  -borderdash   {on off} dash pattern, {} = solid               (default: {})
  -highlight    N|I|O|P  click effect: None/Invert/Outline/Push (default: I)

Example
-------
  $pdf startPage
  $pdf setFont 12 Helvetica
  $pdf text 50 100 "Click here"
  $pdf hyperlinkAdd 50 95 60 15 "https://example.com" \
      -borderwidth 1 -bordercolor {0 0 1}

Files
-----
  fix15-main.patch   -- hyperlinkAdd in src/main.tcl
  fix15-page.patch   -- 11 new tests in tests/page.test

Apply
-----
  patch -p1 < fix15-main.patch
  patch -p1 < fix15-page.patch
  make

Fork
----
  https://github.com/gregnix/pdf4tcl
