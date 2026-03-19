#!/bin/sh
# tcl9env.sh -- Tcl 9 Umgebung fuer pdf4tcl
#
# Aufruf:
#   . ./tcl9env.sh          (in aktuelle Shell einlesen)
#   source ./tcl9env.sh
#
# Danach normal arbeiten:
#   make test
#   make example
#   tclsh tests/test-aes256.tcl
#   usw.

HOME_DIR="${HOME:-$(getent passwd "$USER" | cut -d: -f6)}"

# tclsh9.0 als Standard
export TCLSH=tclsh9.0

# tcl9.0-Pfad vorne (tcl-sha 9.0 wird gefunden)
export TCLLIBPATH="$HOME_DIR/lib/share/tcl9.0 $HOME_DIR/lib/share/tcltk ${TCLLIBPATH:-}"

echo "=== Tcl 9 Umgebung aktiv ==="
echo "TCLSH=$TCLSH"
echo "TCLLIBPATH=$TCLLIBPATH"
echo "Tcl version: $(tclsh9.0 <<< 'puts [info patchlevel]')"
echo ""
