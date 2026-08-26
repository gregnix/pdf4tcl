# findfont.tcl -- eine TrueType-Schrift finden, auf jeder Plattform.
#
# Demos und Tests brauchen eine Schrift mit Zeichen ausserhalb Latin-1. Bis
# 0.9.4.59 stand in jeder Datei eine eigene Liste mit /usr/share/fonts-Pfaden
# -- 117 Stellen in 23 Dateien, und unter Windows fand keine davon etwas:
#
#     keine Unicode-Schrift gefunden -- Seite 2 uebersprungen
#
# Die Demo lief durch und schrieb eine halbe Datei. Das ist die schlechteste
# Art zu scheitern: kein Fehler, kein Hinweis, nur ein fehlendes Ergebnis.
#
# Verwendung:
#
#     source [file join $here .. tools findfont.tcl]
#     set f [::pdf4tcl::findFont unicode]     ;# "" wenn nichts da ist
#     set f [::pdf4tcl::findFont unicode -required]   ;# oder Fehler
#
# Die Sorten:
#
#     unicode   irgendeine Schrift mit Griechisch und Kyrillisch
#     mono      eine dicktengleiche
#     otf       eine OpenType/CFF-Schrift
#     emoji     eine Farbschrift

package require Tcl 8.6-

namespace eval ::pdf4tcl {}

# Wo eine Plattform ihre Schriften ablegt.
proc ::pdf4tcl::FontDirs {} {
    set dirs {}
    switch -- $::tcl_platform(platform) {
        windows {
            foreach v {WINDIR SystemRoot} {
                if {[info exists ::env($v)]} {
                    lappend dirs [file join $::env($v) Fonts]
                }
            }
            if {[info exists ::env(LOCALAPPDATA)]} {
                lappend dirs [file join $::env(LOCALAPPDATA) \
                        Microsoft Windows Fonts]
            }
        }
        default {
            if {$::tcl_platform(os) eq "Darwin"} {
                lappend dirs /System/Library/Fonts /Library/Fonts \
                        [file join $::env(HOME) Library Fonts]
            } else {
                lappend dirs /usr/share/fonts /usr/local/share/fonts
                if {[info exists ::env(HOME)]} {
                    lappend dirs [file join $::env(HOME) .fonts] \
                            [file join $::env(HOME) .local share fonts]
                }
            }
        }
    }
    set out {}
    foreach d $dirs {
        if {[file isdirectory $d]} { lappend out $d }
    }
    return $out
}

# Dateinamen, die je Sorte in Frage kommen, in der Reihenfolge der Vorliebe.
#
# Nach NAMEN gesucht, nicht nach Inhalt: eine Schrift zu oeffnen und ihre
# cmap zu lesen waere genauer, kostet aber bei jedem Testlauf Zeit, und die
# Namen sind auf allen drei Plattformen stabil genug.
proc ::pdf4tcl::FontNames {sorte} {
    switch -- $sorte {
        unicode {
            # Griechisch und Kyrillisch muessen drin sein. Arial und Tahoma
            # haben beides, DejaVu und FreeSans auch.
            return {DejaVuSans.ttf FreeSans.ttf NotoSans-Regular.ttf
                    LiberationSans-Regular.ttf arial.ttf tahoma.ttf
                    Arial.ttf Tahoma.ttf segoeui.ttf Helvetica.ttc}
        }
        mono {
            return {DejaVuSansMono.ttf FreeMono.ttf LiberationMono-Regular.ttf
                    consola.ttf cour.ttf Courier.ttc Menlo.ttc}
        }
        otf {
            return {Loma.otf Loma-Bold.otf GFSPorson.otf GFSBaskerville.otf
                    SourceSansPro-Regular.otf}
        }
        emoji {
            return {NotoColorEmoji.ttf seguiemj.ttf "Apple Color Emoji.ttc"}
        }
        default {
            return -code error "unknown font kind \"$sorte\""
        }
    }
}

# Die erste Schrift der Sorte, die wirklich da ist.
#
# Gibt "" zurueck, wenn nichts gefunden wurde -- ausser bei -required, dann
# ist es ein Fehler mit der Liste der durchsuchten Verzeichnisse. Wer eine
# Demo schreibt, nimmt "" und ueberspringt; wer einen Test schreibt, setzt
# einen Guard darauf.
proc ::pdf4tcl::findFont {sorte args} {
    set required [expr {"-required" in $args}]
    set dirs [FontDirs]
    set namen [FontNames $sorte]

    foreach dir $dirs {
        foreach n $namen {
            # Direkt darunter, dann eine Ebene tiefer (Linux sortiert nach
            # Hersteller: /usr/share/fonts/truetype/dejavu/...).
            set p [file join $dir $n]
            if {[file readable $p]} { return $p }
            foreach treffer [glob -nocomplain -directory $dir */$n */*/$n] {
                if {[file readable $treffer]} { return $treffer }
            }
        }
    }
    if {$required} {
        return -code error "no $sorte font found. Looked for\
                [join $namen {, }] under [join $dirs {, }]"
    }
    return ""
}
