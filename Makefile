# Makefile for pdf4tcl

VERSION = 09424

# TOOL paths
TCLSH    ?= tclsh8.6
NAGELFAR = nagelfar -encoding iso8859-1 -s syntaxdb86.tcl
NAGELFAR90 = nagelfar -encoding iso8859-1 -s syntaxdb90.tcl
ESKIL    = eskil

all: doc web pdf4tcl.tcl

# Build from source
CATFILES = src/prologue.tcl src/fonts.tcl src/helpers.tcl src/options.tcl src/main.tcl src/encrypt.tcl src/cat.tcl

pdf4tcl.tcl: $(CATFILES)
	cat $(CATFILES) > pdf4tcl.tcl

# Documentation
doc : pdf4tcl.html pdf4tcl.n web/mypdf.pdf

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

web/mypdf.pdf: pdf4tcl.tcl mkweb.tcl web/index.html
	./mkweb.tcl

web/pdf4tcl.html: pdf4tcl.html
	/bin/cp pdf4tcl.html web/pdf4tcl.html

web : web/mypdf.pdf web/pdf4tcl.html

webt: web
	rsync -e ssh -rv web/* pspjuth@web.sourceforge.net:/home/project-web/pdf4tcl/htdocs

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

# Version management
verify:
	@$(TCLSH) tools/bump.tcl --verify

bump:
	@$(TCLSH) tools/bump.tcl \
	    $(if $(TO),--to $(TO),) \
	    $(if $(MSG),--msg "$(MSG)",) \
	    --no-test

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
