# Makefile for pdf4tcl

VERSION = 09459

# TOOL paths
TCLSH    ?= tclsh8.6
NAGELFAR = nagelfar -encoding iso8859-1 -s syntaxdb86.tcl
NAGELFAR90 = nagelfar -encoding iso8859-1 -s syntaxdb90.tcl
ESKIL    = eskil

all: pdf4tcl.tcl pkg/pdf4tcl.tcl doc

# Build from source
CATFILES = src/prologue.tcl src/fonts.tcl src/helpers.tcl src/options.tcl src/main.tcl src/color.tcl src/encrypt.tcl src/tagged.tcl src/cat.tcl

pdf4tcl.tcl: $(CATFILES)
	cat $(CATFILES) > pdf4tcl.tcl

# pkg/pdf4tcl.tcl haelt den Paketstand. Eigenes Ziel, damit es neu entsteht,
# sobald pdf4tcl.tcl sich aendert oder fehlt.
#
# Ist pkg/ als Symlink-Verzeichnis eingerichtet (nogit/scripts/restore-pkg-
# symlinks.tcl), schreibt dieses cp durch den Symlink auf dieselbe Datei --
# der Symlink bleibt erhalten, und pkg/ kann nicht mehr veralten. Siehe
# INSTALL.md.
pkg/pdf4tcl.tcl: pdf4tcl.tcl
	cp pdf4tcl.tcl pkg/pdf4tcl.tcl

# CI guard: fail if the generated files are stale -- src/ changed but
# pdf4tcl.tcl not rebuilt, or pkg/pdf4tcl.tcl drifted from pdf4tcl.tcl.
# Read-only. ('check' is already the Nagelfar target.)
.PHONY: checkbuild clean distclean
checkbuild:
	@cat $(CATFILES) > pdf4tcl.tcl.chk
	@if cmp -s pdf4tcl.tcl.chk pdf4tcl.tcl; then \
	  echo "OK: pdf4tcl.tcl matches src/"; \
	else \
	  echo "STALE: pdf4tcl.tcl != cat(src/) -- run 'make pdf4tcl.tcl'"; \
	  rm -f pdf4tcl.tcl.chk; exit 1; \
	fi
	@rm -f pdf4tcl.tcl.chk
	@if cmp -s pkg/pdf4tcl.tcl pdf4tcl.tcl; then \
	  echo "OK: pkg/pdf4tcl.tcl matches pdf4tcl.tcl"; \
	else \
	  echo "STALE: pkg/pdf4tcl.tcl != pdf4tcl.tcl -- run 'make pkg/pdf4tcl.tcl'"; \
	  exit 1; \
	fi

# Documentation
doc : pdf4tcl.html pdf4tcl.n

pdf4tcl.html pdf4tcl.n : pdf4tcl.man mkdoc.tcl
	./mkdoc.tcl

# Generate pdf4tcl.md from pdf4tcl.n via nroff2md.tcl
md : pdf4tcl.n
	nroff2md.tcl pdf4tcl.n pdf4tcl.md

checkdoc: pdf4tcl.tcl
	@egrep 'method [a-z]' pdf4tcl.man | grep '\[call' | egrep -v 'method configure' | sed 's/[]["]/ /g' | sed 's/ arg / /g' | sed 's/  */ /g' | sed 's/call objectName/ /g' | sort > _docmeth
	@egrep 'method [a-z]' pdf4tcl.tcl | sed 's/[{}]/ /g' | sed 's/  */ /g' | sort > _srcmeth
	@$(ESKIL) -block _srcmeth _docmeth
	@rm _srcmeth _docmeth

# Die Ziele web/webt sind mit dem Verzeichnis web/ entfallen. Sie luden per
# rsync nach pspjuth@web.sourceforge.net -- das Konto des Originalprojekts,
# nicht das des Forks. Die Seite war fuer diesen Baum nicht
# veroeffentlichbar. mkweb.tcl ist damit ebenfalls weg.

# Die Demos. "example" erzeugt nur examples/, so dass demo/out/ von der
# Abnahme nie angefasst wurde -- gemessen: demo-forms-enc.pdf lag zwei Tage
# alt herum und meldete einen Fehler, der laengst behoben war.
# Bricht nicht ab: einzelne Demos brauchen Werkzeuge, die nicht ueberall
# da sind (demo-pdfa-gs.tcl will Ghostscript). Ein fehlendes Werkzeug ist
# kein Fehler im Baum. Was wirklich schiefging, steht in der Ausgabe.
demos:
	@cd demo && $(TCLSH) run-all-demos.tcl || true

# Wo landet der Text? qpdf prueft die Unversehrtheit, veraPDF den Anspruch,
# pdfcheck-native die Strukturen -- keines davon sieht, ob zwei Textbloecke
# uebereinanderliegen oder ein Wort im Rand steht.
#
# Zwei der ausgelieferten Beispiele melden etwas und sind trotzdem richtig;
# die Begruendung steht im Kopf von tools/layout-check.tcl. Deshalb bricht
# das Ziel nicht ab, sondern berichtet.
layoutcheck:
	@$(TCLSH) tools/layout-check.tcl doc/en/out/ || true

example:
	@cd examples && $(TCLSH) test0.tcl
	@cd examples && $(TCLSH) test1.tcl
	@cd examples && $(TCLSH) test2.tcl
	@cd examples && $(TCLSH) test3.tcl
	@cd examples && $(TCLSH) test4.tcl
	@cd examples && $(TCLSH) test5.tcl
	@cd examples && $(TCLSH) test6.tcl
	@cd examples && $(TCLSH) specenc.tcl
	@cd examples && $(TCLSH) multiout.tcl
	@cd examples && $(TCLSH) test7.tcl
	@cd examples && $(TCLSH) test-transform.tcl

# Helpers

#metrics:
#	tclsh tools/extract-metrics.tcl metrics.tcl

# Tests
test: cleancc pdf4tcl.tcl
	$(TCLSH) tests/all.tcl $(TESTFLAGS)

pdf4tcl_h.syntax : pdf4tcl.tcl pdf4tcl.syntax
	$(NAGELFAR) -header pdf4tcl_h.syntax pdf4tcl.tcl -filter '*Unknown variable*' -filter '*Unknown subcommand*'

check: pdf4tcl_h.syntax
	$(NAGELFAR) pdf4tcl_h.syntax pdf4tcl.tcl

check90: pdf4tcl_h90.syntax
	$(NAGELFAR90) pdf4tcl_h90.syntax pdf4tcl.tcl

pdf4tcl_h90.syntax: pdf4tcl.tcl
	$(NAGELFAR90) -header pdf4tcl_h90.syntax pdf4tcl.tcl -filter '*Unknown variable*' -filter '*Unknown subcommand*'

# Code coverage tests
SRCFILES = pdf4tcl.tcl
IFILES   = $(SRCFILES:.tcl=.tcl_i)
LOGFILES = $(SRCFILES:.tcl=.tcl_log)
MFILES   = $(SRCFILES:.tcl=.tcl_m)

%.tcl_i: %.tcl pdf4tcl_h.syntax
	@$(NAGELFAR) -instrument pdf4tcl_h.syntax $<

instrument: $(IFILES)
	@rm -f $(LOGFILES)

$(LOGFILES): $(IFILES)
	@$(TCLSH) tests/all.tcl

%.tcl_m: %.tcl_log 
	@$(NAGELFAR) -markup $*.tcl

icheck: $(MFILES)
	@for i in $(SRCFILES) ; do $(ESKIL) -noparse $$i $${i}_m & done

cleancc:
	@rm -f $(LOGFILES) $(IFILES) $(MFILES)

# Alles Erzeugte weg. Was hier steht, entsteht mit "make" oder einem der
# anderen Ziele neu -- Quelldateien fasst es nicht an.
#
# pdf4tcl.tcl und pkg/pdf4tcl.tcl SIND erzeugt (aus src/), stehen aber im
# Repo, weil das Original sie mitliefert. Deshalb loescht clean sie NICHT;
# dafuer gibt es distclean.
clean: cleancc
	@rm -f pdf4tcl_h.syntax pdf4tcl_h90.syntax
	@rm -f tests/*.pdf tests/*.ps
	@rm -rf demo/out doc/en/out tests/out
	@rm -rf release
	@echo "clean: erzeugte Dateien entfernt (pdf4tcl.tcl bleibt -- siehe distclean)"

# examples/*.pdf wird BEWUSST nicht geloescht: die Dateien sind
# Referenzausgabe und im Repo versioniert -- tests/examples.test
# vergleicht die frisch erzeugten gegen sie. Eine erste Fassung dieses
# Ziels raeumte sie mit weg, und "make clean && make test" meldete
# reproduzierbar 8 Fehler. Neu erzeugt werden sie mit "make example".

# Zusaetzlich die assemblierten Dateien. Danach ist "make" noetig, bevor
# irgendetwas laeuft.
distclean: clean
	@rm -f pdf4tcl.tcl pkg/pdf4tcl.tcl pdf4tcl.html pdf4tcl.n
	@echo "distclean: auch die assemblierten Dateien entfernt -- jetzt 'make'"

# Version management
verify:
	@$(TCLSH) tools/bump.tcl --verify

bump:
	@$(TCLSH) tools/bump.tcl \
	    $(if $(TO),--to $(TO),) \
	    $(if $(MSG),--msg "$(MSG)",)

bump-git:
	@$(TCLSH) tools/bump.tcl \
	    $(if $(TO),--to $(TO),) \
	    $(if $(MSG),--msg "$(MSG)",) \
	    --git
#----------------------------------------------------------------
# Packaging/Releasing
#----------------------------------------------------------------

release: pdf4tcl.tcl doc
	@mkdir -p release
	@rm -f release/pdf4tcl.tar.gz release/pdf4tcl$(VERSION).tar.gz
	@ln -s pkg pdf4tcl$(VERSION)
	@tar -zcvhf release/pdf4tcl.tar.gz --exclude=.svn pdf4tcl$(VERSION)
	@rm -f pdf4tcl$(VERSION)
	@cp release/pdf4tcl.tar.gz release/pdf4tcl`date +%Y%m%d`.tar.gz
	@mv release/pdf4tcl.tar.gz release/pdf4tcl$(VERSION).tar.gz
	@ls -lh release/pdf4tcl$(VERSION).tar.gz

zip: pdf4tcl.tcl doc
	@mkdir -p release
	@rm -f release/pdf4tcl$(VERSION).zip
	@ln -s pkg pdf4tcl$(VERSION)
	@zip -r release/pdf4tcl$(VERSION).zip pdf4tcl$(VERSION) --exclude "*.svn*"
	@rm -f pdf4tcl$(VERSION)
	@ls -lh release/pdf4tcl$(VERSION).zip

upload:
	rsync -e ssh README release/pdf4tcl$(VERSION).tar.gz pspjuth@frs.sourceforge.net:/home/frs/project/pdf4tcl/
