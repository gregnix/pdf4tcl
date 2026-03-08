pdf4tcl patch: Fix tickets #20 and #21 -- metadata documentation
Version: 0.9.4.2
Date:    2026-03-08
Author:  Gregor (gregnix@github)

Ticket #20 -- Doc bug: -format
-----------------------------------------------
The documentation listed -format as a supported metadata option.
This option does not exist in the code and is not a standard PDF
Info Dictionary field. Removed from pdf4tcl.man.

Ticket #21 -- Doc issue: -keywords
-----------------------------------------------
The documentation did not explain that multiple keywords must be
passed as a comma-separated string. Added a note:
  e.g. -keywords "tcl,pdf,document"

Files
-----
  fix20+21-man.patch   -- fix in pdf4tcl.man

Apply
-----
  patch -p1 < fix20+21-man.patch
