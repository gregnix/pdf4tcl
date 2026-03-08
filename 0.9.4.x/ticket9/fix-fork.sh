#!/bin/bash
# fix-fork.sh -- Alle offenen Punkte in einem Schritt beheben
# Ausfuehren aus dem Wurzelverzeichnis des Forks:
#   cd ~/...pdf4tcl/
#   bash fix-fork.sh

set -e
echo "=== pdf4tcl fork -- offene Punkte beheben ==="
echo ""

# Sicherstellen dass wir im richtigen Verzeichnis sind
if [[ ! -f "src/prologue.tcl" || ! -d "0.9.4.x/ticket9" ]]; then
    echo "FEHLER: bitte aus dem pdf4tcl-Wurzelverzeichnis ausfuehren"
    echo "  Erwartet: src/prologue.tcl und 0.9.4.x/ticket9/"
    exit 1
fi

# 1. tests/init.tcl: package require 0.9.4 -> 0.9.4.1
echo "[1] tests/init.tcl: package require 0.9.4.1"
sed -i 's/package require pdf4tcl 0\.9\.4$/package require pdf4tcl 0.9.4.1/' tests/init.tcl
grep "package require pdf4tcl" tests/init.tcl

# 2. Makefile VERSION
echo "[2] Makefile: VERSION = 0941"
sed -i 's/^VERSION = 094$/VERSION = 0941/' Makefile
# test7.tcl im example-Ziel ergaenzen
sed -i 's/\t@cd examples && $(TCLSH) multiout\.tcl/\t@cd examples \&\& $(TCLSH) multiout.tcl\n\t@cd examples \&\& $(TCLSH) test7.tcl/' Makefile
grep "VERSION\|test7" Makefile

# 3. ChangeLog -- neuen Eintrag vorne einfuegen
echo "[3] ChangeLog: Eintrag fuer addForm v2.1"
TODAY=$(date +"%Y-%m-%d")
TMPFILE=$(mktemp)
cat > "$TMPFILE" << CLEOF
$TODAY Gregor  <gregnix@github>
	* Bumped revision to 0.9.4.1
	* Extended addForm method to support 8 field types:
	  text, password, checkbutton (alias checkbox), combobox,
	  listbox, radiobutton, pushbutton, signature. [SF #9]
	* New addForm options: -readonly, -required, -options,
	  -editable, -sort, -multiselect, -group, -value,
	  -action, -url, -caption, -label.
	* Added Ff field flag constants to src/helpers.tcl.
	* Radiobutton groups finalized at finish() as parent /Kids hierarchy.
	* NeedAppearances never set (preserves digital signature support).
	* Added 67 tests in tests/form-ext.test (form-5.x to form-12.x).
	* Added tests/diagnose.tcl for version verification.
	* Added examples/test7.tcl demo for all 8 field types.
	* Fixed mytest glob pattern bug in tests/init.tcl.
	* Added patch submission files in 0.9.4.x/ticket9/ for SF ticket #9.
	* Added German documentation in 0.9.4.x/doc/de/.
	* Added demo scripts in 0.9.4.x/demo/.

CLEOF
cat ChangeLog >> "$TMPFILE"
mv "$TMPFILE" ChangeLog
head -3 ChangeLog

# 4. bumprev.txt -- GitHub-Schritt ergaenzen
echo "[4] bumprev.txt: GitHub-Schritt"
cat > bumprev.txt << 'BUMPEOF'
These files need to be changed when bumping revisions:

src/prologue.tcl (package provide)
tests/init.tcl (package require)
pkgIndex.tcl (package ifneeded)
Makefile (VERSION)
pdf4tcl.man (two places) (regenerate doc)

Also update these:
ChangeLog
web/index.html
web/changes.html



To do when updating code:

Is pdf4tcl.man, ChangeLog, web/changes.html updated?
Everything clean?
make
make test
make check
make example

Review and commit:
git diff / git commit
git push origin master



To do when doing a release:

All clean above? Revision bumped?

make release

For the fork (GitHub):
git tag v0.9.4.x
git push origin master
git push origin --tags

For upstream (SourceForge, if patch is accepted):
make upload
make webt
Go to sourceforge and mark uploaded file as latest release for all platforms.
BUMPEOF
echo "  bumprev.txt geschrieben"

# 5. 0.9.4.x/ticket9/: PATCH-README und Manpage aktualisieren
echo "[5] 0.9.4.x/ticket9/: PATCH-README.txt und addForm-manpage.txt"

cat > 0.9.4.x/ticket9/PATCH-README.txt << 'READMEEOF'
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
READMEEOF

cat > 0.9.4.x/ticket9/addForm-manpage.txt << 'MANEOF'
# addForm manpage section -- replaces the existing addForm paragraph in pdf4tcl.man
# (from "[call [arg objectName] [method addForm]..." to the blank line
#  before "[list_end]")
#
# The patch addforms-manpage.patch applies this automatically.
# To apply manually: replace the old 5-line addForm paragraph with this text.

[call [arg objectName] [method addForm] [arg "type"] [arg "x"] [arg "y"] [arg "width"] [arg "height"] [opt [arg "option value"]...]]

Add an interactive form field at the given position and size.
Coordinates are in the document's current unit.

Supported types are [arg text], [arg password], [arg checkbutton]
(alias [arg checkbox]), [arg combobox], [arg listbox],
[arg radiobutton], [arg pushbutton], and [arg signature].

[list_begin definitions]

[def "[emph {Common options}]"]
[list_begin options]
[opt_def -id [arg string]]
Unique field ID (alphanumeric). If omitted, one is generated
automatically: [arg {${type}form${n}}] for most types,
[arg {${group}_${value}}] for radiobuttons,
[arg {Signature${n}}] for signatures.

[opt_def -init [arg value]]
Initial value. For [arg text]/[arg password] a string,
for [arg checkbutton] a boolean, for [arg combobox]/[arg listbox]
an item from [arg -options], for [arg radiobutton] a boolean
selecting this button.

[opt_def -readonly [arg boolean]]
If true, the field is read-only (PDF Ff bit 1). Default [const 0].

[opt_def -required [arg boolean]]
If true, the field is marked as required (PDF Ff bit 2). Default [const 0].
Not valid for [arg pushbutton] or [arg signature].
[list_end]

[def "[emph {Text / Password options}]"]
[list_begin options]
[opt_def -multiline [arg boolean]]
Enable multi-line editing (text only). Default [const 0].
[list_end]

[def "[emph {Checkbutton options}]"]
[list_begin options]
[opt_def -on [arg xobjectId]]
Custom appearance XObject for the checked state.
Created with [method startXObject].

[opt_def -off [arg xobjectId]]
Custom appearance XObject for the unchecked state.
[list_end]

[def "[emph {Combobox / Listbox options}]"]
[list_begin options]
[opt_def -options [arg list]]
List of selectable items. Required for [arg combobox] and [arg listbox].

[opt_def -editable [arg boolean]]
Allow typing custom values (combobox only). Default [const 0].

[opt_def -sort [arg boolean]]
Sort the option list. Default [const 0].

[opt_def -multiselect [arg boolean]]
Allow selecting multiple items (listbox only). Default [const 0].
[list_end]

[def "[emph {Radiobutton options}]"]
[list_begin options]
[opt_def -group [arg string]]
Group name (required, alphanumeric). All buttons sharing the same
group name form a mutually exclusive set.

[opt_def -value [arg string]]
Value for this button (required, alphanumeric). Used as the
PDF appearance state name.
[list_end]

[def "[emph {Pushbutton options}]"]
[list_begin options]
[opt_def -action [arg type]]
Action type: [const reset] (clear all fields), [const url] (open URL),
or [const submit] (submit form data to URL).

[opt_def -url [arg string]]
Target URL. Required when [arg -action] is [const url] or [const submit].

[opt_def -caption [arg string]]
Button label text. Either [arg -action] or [arg -caption] (or both)
must be given.
[list_end]

[def "[emph {Signature options}]"]
[list_begin options]
[opt_def -label [arg string]]
Placeholder text displayed above the signature line.
If omitted, defaults to [const Signature].
Only valid for [arg signature] fields.
[list_end]

[list_end]

All fields generate their own appearance streams; the
[const NeedAppearances] flag is never set, ensuring compatibility
with digital signature workflows.
Radiobutton groups are finalized at document write time as a
parent field with [const /Kids] entries per the PDF specification.
The [method getForms] method returns data for all field types
including the new ones added in this patch.
MANEOF
echo "  0.9.4.x/ticket9/ aktualisiert"

echo ""
echo "=== Alle Aenderungen gemacht. Jetzt pruefen und committen: ==="
echo ""
echo "  git diff"
echo "  git add -A"
echo "  git commit -m \"fix: version 0.9.4.1 cleanup -- ChangeLog, Makefile, bumprev, patch docs\""
echo "  git push"
