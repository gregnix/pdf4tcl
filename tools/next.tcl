# Zielversion und Beschreibung fuer den naechsten "tclsh tools/bump.tcl".
#
# VON HAND PFLEGEN. bump.tcl liest diese Datei und laesst sie stehen --
# welche Nummer als naechste kommt, entscheidet der Autor. Nach einem
# Bump steht hier weiterhin die eben vergebene Version und ihre
# Beschreibung; beides bleibt so lange stehen, bis es geaendert wird.
#
# Ein Aufruf in diesem Zustand ist ein REPARATURLAUF: er zieht nach, was
# noch auf einer alten Nummer steht, und meldet den Rest als
# unveraendert. Nuetzlich, wenn "make doc" ausgeblieben ist und
# pdf4tcl.html noch die alte Version traegt -- "bump.tcl --verify" zeigt
# so etwas an.
set NEXT_VERSION 0.9.4.49
set NEXT_MSG "missing glyphs are reported"
