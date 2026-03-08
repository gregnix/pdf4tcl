pdf4tcl Forms Extension v2.1 -- Patch
======================================

Applies against: pdf4tcl 0.9.4 (official git checkout from SourceForge)

  git clone https://git.code.sf.net/p/pdf4tcl/code pdf4tcl-code
  cd pdf4tcl-code


Apply
-----

  patch -p1 < addforms-v21.patch

Manpage update (separate patch, recommended):

  patch -p1 < addforms-manpage.patch

Reassemble:

  cat src/prologue.tcl src/fonts.tcl src/helpers.tcl \
      src/options.tcl src/main.tcl src/cat.tcl > pdf4tcl.tcl


Test
----

  tclsh tests/all.tcl -file form.test      # 14 tests (existing, unchanged)
  tclsh tests/all.tcl -file form-ext.test  # 67 tests (new field types)

To verify the correct version is loaded:

  cd tests && tclsh diagnose.tcl


Revert
------

  patch -p1 -R < addforms-v21.patch
  patch -p1 -R < addforms-manpage.patch


Changed files (3)
-----------------

  src/helpers.tcl    +14 lines
      AcroForm field flag constants (Ff_READONLY, Ff_REQUIRED, Ff_MULTILINE,
      Ff_PASSWORD, Ff_NOTOGGLEOFF, Ff_RADIO, Ff_PUSHBUTTON, Ff_COMBO,
      Ff_EDIT, Ff_SORT, Ff_MULTISELECT) as namespace variables.

  src/main.tcl       +451 lines
      - addForm: 8 field types instead of 2 (text, password, checkbutton,
        combobox, listbox, radiobutton, pushbutton, signature)
      - New options: -readonly, -required, -options, -editable, -sort,
        -multiselect, -group, -value, -action, -url, -caption, -label
      - Private appearance stream builders: _FormXObjHeader, _BuildCheckboxAP,
        _BuildTextAP, _BuildChoiceAP, _BuildRadioAP, _BuildSignatureAP
      - Radio group finalization in finish() via pdf(radiogroups) dict
      - NeedAppearances is never set (preserves digital signature support)

  tests/init.tcl     +5 lines
      Bug fix in mytest: after whitespace collapse, the glob pattern " * "
      (space-wildcard-space) fails when PDF tokens are directly adjacent.
      Fix: regsub -all { \* } $pattern {*} pattern


New files (3)
-------------

  tests/form-ext.test
      67 tests covering all new field types:
      combobox (form-5.x), listbox (form-6.x), password (form-7.x),
      radiobutton (form-8.x), pushbutton (form-9.x), signature (form-10.x),
      -readonly flag (form-11.x), -required flag (form-12.x)

  tests/diagnose.tcl
      Diagnostic tool: verifies which pdf4tcl version is loaded and runs
      5 feature checks for v2.1-specific behaviour.
      Run from tests/: tclsh diagnose.tcl

  examples/test7.tcl
      Demo script generating a 3-page PDF with all 8 field types,
      including readonly fields and a registration form with signature.
