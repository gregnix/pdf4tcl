Ticket #18 -- Make line spacing distance observable via getLineHeight

New method: getLineHeight
Returns the actual vertical distance advanced by newLine in the document's
current unit: font_size_in_points * lineSpacingFactor / unit_factor

File: src/main.tcl
Apply patch:
    patch -p1 < fix18-main.patch
    make
