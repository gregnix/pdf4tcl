#!/usr/bin/env tclsh
# ---------------------------------------------------------------------------
# Wurzel suchen, nicht zaehlen.
#
# Zwei Ebenen hoch stimmte, solange die Demos unter 0.9.4.x/demo lagen.
# Nach dem Flachlegen des fork-Verzeichnisses zeigte es aus dem Repo
# hinaus. Sichtbar wurde das nur in den Demos, die daraus einen Dateipfad
# bauen (demo-tagged brach ab); die uebrigen legten still ein falsches
# Verzeichnis in auto_path und pruefen dann das pdf4tcl, das auf dem
# Rechner zufaellig installiert ist -- gruen, und ueber die falsche
# Fassung.
#
# Markierung ist pkgIndex.tcl neben src/; beides gibt es nur in der Wurzel.
# ---------------------------------------------------------------------------
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
set demodir  [file dirname [file normalize [info script]]]
set reporoot [pdf4tclRepoRoot $demodir]
set auto_path [linsert $auto_path 0 $reporoot]

package require pdf4tcl

set pdf [::pdf4tcl::new %AUTO% -paper a4 -orient true]
$pdf startPage
$pdf setFont 18 Helvetica-Bold
$pdf text "Hello World!" -x 50 -y 100
$pdf endPage
set demoOutDir [file join [file dirname [file normalize [info script]]] out]
if {$argc > 0} { set demoOutDir [lindex $argv 0] }
file mkdir $demoOutDir
$pdf write -file [file join $demoOutDir hello.pdf]
$pdf destroy




