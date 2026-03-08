Ticket #14 -- createFontSpecEnc: check for maximum 256 codepoints

File: src/fonts.tcl
Change: Add length check at start of createFontSpecEnc proc.
        Raises "createFontSpecEnc: subset must not exceed 256 codepoints" error
        if more than 256 codepoints are passed.

Apply patch:
    patch -p1 < fix14-fonts.patch
    cat src/prologue.tcl src/fonts.tcl src/helpers.tcl src/options.tcl \
        src/main.tcl src/cat.tcl > pdf4tcl.tcl
