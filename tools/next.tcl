# Zielversion und Beschreibung fuer den naechsten "tclsh tools/bump.tcl".
#
# VON HAND PFLEGEN. bump.tcl liest diese Datei und laesst sie stehen --
# welche Nummer als naechste kommt, entscheidet der Autor. Nach einem
# Bump steht hier weiterhin die eben vergebene Version und ihre
# Beschreibung; beides bleibt so lange stehen, bis es geaendert wird.
#
# Ein Aufruf in diesem Zustand ist ein REPARATURLAUF: er zieht nach, was
# noch auf einer alten Nummer steht, und meldet den Rest als
# unveraendert.
set NEXT_VERSION 0.9.4.52
set NEXT_MSG "test names handed out twice"
