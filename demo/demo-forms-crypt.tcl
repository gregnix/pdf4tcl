#!/usr/bin/env tclsh
# demo-forms-crypt.tcl -- verschluesselte Formulare lesen, fuellen, exportieren
# Aufruf:    tclsh demo-forms-crypt.tcl ?ausgabeverzeichnis?
#
# Seit 0.9.4.71 nehmen getForms, fillForms und exportForms -password.
# Ohne die Option wird das leere Kennwort versucht, wie in jedem
# Betrachter: ein Formular mit nur einem Eigentuemerkennwort geht damit
# ohne Nachfrage auf. Bis 0.9.4.70 kam bei verschluesselter Eingabe still
# nichts heraus -- ein leeres dict, "no such field", eine leere Ausgabe.
#
# Ausgabe (demo/out):
#   demo-forms-crypt.pdf            AES-128, Benutzer geheim / Eigentuemer admin
#   demo-forms-crypt-gefuellt.pdf   gefuellt, gleich verschluesselt
#   demo-forms-crypt.xfdf           Export der gefuellten Werte
#   demo-forms-crypt-owner.pdf      nur Eigentuemerkennwort
#
# Viewer: Firefox / Evince / Acrobat, Kennwort geheim

proc pdf4tclRepoRoot {start} {
    set dir [file normalize $start]
    for {set i 0} {$i < 8} {incr i} {
        if {[file exists [file join $dir pkgIndex.tcl]]
                && [file isdirectory [file join $dir src]]} { return $dir }
        set parent [file dirname $dir]
        if {$parent eq $dir} break
        set dir $parent
    }
    return -code error "pdf4tcl-Wurzel nicht gefunden ueber $start"
}
set scriptDir [file dirname [file normalize [info script]]]
set auto_path [linsert $auto_path 0 [pdf4tclRepoRoot $scriptDir]]
package require pdf4tcl

set outDir [file join $scriptDir out]
if {$argc > 0} { set outDir [lindex $argv 0] }
file mkdir $outDir

set user  geheim
set owner admin

# ---------------------------------------------------------------------------
# Ein Formular schreiben -- Text, Ankreuzfeld, Auswahl
# ---------------------------------------------------------------------------
proc formular {file opts} {
    set p [pdf4tcl::new %AUTO% -paper a4 -orient true {*}$opts]
    $p startPage
    $p setFont 16 Helvetica-Bold
    $p text "Antrag" -x 72 -y 60
    $p setFont 10 Helvetica
    $p text "Name:"  -x 72 -y 100
    $p text "Ort:"   -x 72 -y 130
    $p text "Farbe:" -x 72 -y 160
    $p text "Einverstanden:" -x 72 -y 190
    $p setFont 11 Helvetica
    $p addForm text 160 88 220 16 -id name -init "Meier"
    $p addForm text 160 118 220 16 -id ort
    $p addForm combobox 160 148 120 16 -id farbe \
            -options {Rot Gruen Blau} -init Rot
    $p addForm checkbutton 160 178 14 14 -id ok -init 0
    $p endPage
    $p write -file $file
    $p destroy
}

proc zeige {titel felder} {
    puts "  $titel"
    foreach id [lsort [dict keys $felder]] {
        puts [format "    %-6s = %s" $id [dict get $felder $id value]]
    }
}

set pdf   [file join $outDir demo-forms-crypt.pdf]
set voll  [file join $outDir demo-forms-crypt-gefuellt.pdf]
set xfdf  [file join $outDir demo-forms-crypt.xfdf]
set nurEig [file join $outDir demo-forms-crypt-owner.pdf]

formular $pdf [list -userpassword $user -ownerpassword $owner -encversion 4]
puts "Geschrieben: $pdf (AES-128, Kennwort $user)"

# ---------------------------------------------------------------------------
# 1. Ohne Kennwort: ein Fehler, kein leeres Ergebnis
# ---------------------------------------------------------------------------
puts "\n1. getForms ohne -password"
if {[catch {pdf4tcl::getForms $pdf} msg opts]} {
    puts "  [dict get $opts -errorcode]: $msg"
} else {
    puts "  UNERWARTET: $msg"
    exit 1
}

# ---------------------------------------------------------------------------
# 2. Mit Benutzer- oder Eigentuemerkennwort
# ---------------------------------------------------------------------------
puts "\n2. getForms mit Kennwort"
zeige "-password $user"  [pdf4tcl::getForms $pdf -password $user]
zeige "-password $owner" [pdf4tcl::getForms $pdf -password $owner]

puts "\n   falsches Kennwort:"
catch {pdf4tcl::getForms $pdf -password falsch} msg opts
puts "  [dict get $opts -errorcode]: $msg"

# ---------------------------------------------------------------------------
# 3. Fuellen. Die Ausgabe ist gleich verschluesselt.
# ---------------------------------------------------------------------------
puts "\n3. fillForms"
set n [pdf4tcl::fillForms $pdf $voll \
        [dict create name "M\u00fcller" ort "K\u00f6ln" farbe Blau ok /Yes] \
        -password $user]
puts "  $n Felder gefuellt -> $voll"
zeige "wieder gelesen" [pdf4tcl::getForms $voll -password $user]
if {![catch {pdf4tcl::getForms $voll}]} {
    puts "  UNERWARTET: Ausgabe ohne Kennwort lesbar"
    exit 1
}
puts "  ohne Kennwort weiterhin verschlossen"

# ---------------------------------------------------------------------------
# 4. Exportieren -- -password gab es schon, jetzt wirkt es
# ---------------------------------------------------------------------------
puts "\n4. exportForms"
set n [pdf4tcl::exportForms $voll $xfdf -format xfdf -password $user]
puts "  $n Felder -> $xfdf"

# ---------------------------------------------------------------------------
# 5. Nur Eigentuemerkennwort: geht ohne -password auf
# ---------------------------------------------------------------------------
puts "\n5. Nur Eigentuemerkennwort"
formular $nurEig [list -ownerpassword $owner -encversion 4]
zeige "getForms ohne -password" [pdf4tcl::getForms $nurEig]

puts "\nFertig."
