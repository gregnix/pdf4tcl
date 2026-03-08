pdf4tcl Forms Extension v2.1 — Patch
=====================================

Applies against: pdf4tcl 0.9.4 (official fossil checkout)

Apply:
  cd pdf4tcl-code
  patch -p1 < addforms-v21.patch

Manpage update (optional, separate patch):
  patch -p1 < addforms-manpage.patch

Reassemble:
  cat src/prologue.tcl src/fonts.tcl src/helpers.tcl \
      src/options.tcl src/main.tcl src/cat.tcl > pdf4tcl.tcl

Test:
  cd tests
  tclsh form-ext.test    # 67 tests (new)
  tclsh form.test        # 14 tests (existing, unchanged)

Revert:
  patch -p1 -R < addforms-v21.patch

Changed files (3):
  src/helpers.tcl     +14 lines (Ff constants)
  src/main.tcl        +451 lines (addForm extension + helpers)
  tests/init.tcl      +5 lines  (glob pattern fix)

New files (3):
  tests/form-ext.test         67 tests
  tests/diagnose.tcl          version diagnostic tool
  examples/test7.tcl           all 8 field types demo

