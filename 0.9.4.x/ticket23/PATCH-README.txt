Ticket #23 -- Support for PDF page labels (/PageLabels)

New method: pageLabel pageIndex ?-style D|r|R|a|A|{}? ?-prefix str? ?-start int?

Defines page label ranges in the PDF catalog. pageIndex is 0-based.
Styles: D=decimal, r=roman lowercase, R=roman uppercase, a=alpha lower, A=alpha upper
Multiple ranges can be defined by calling pageLabel multiple times.

File: src/main.tcl
Apply patch:
    patch -p1 < fix23-main.patch
    make
