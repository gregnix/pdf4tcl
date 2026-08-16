#!/usr/bin/env tclsh
# demo-aes256.tcl \u2014 AES-256 Verschl\u00FCsselung Demo
# Ablageort: pdf4tcl0.9.4.16src/pdf4tcl/
# Aufruf: tclsh demo-aes256.tcl

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
set scriptDir [file dirname [file normalize [info script]]]
# Das Paket liegt zwei Ebenen hoeher, im Repository-Wurzelverzeichnis.
# Nur den Demo-Ordner einzutragen funktionierte lediglich dann, wenn pdf4tcl
# systemweit installiert war.
set auto_path  [linsert $auto_path 0 [pdf4tclRepoRoot $scriptDir]]
package require pdf4tcl 0.9.4.16

# Ausgabe standardmaessig nach demo/out, optional ein Verzeichnis oder eine
# Datei als erstes Argument.
set demoOutDir [file join $scriptDir out]
if {$argc > 0} { set demoOutDir [lindex $argv 0] }
file mkdir [expr {[file isdirectory $demoOutDir] || ![file exists $demoOutDir]
                  ? $demoOutDir : [file dirname $demoOutDir]}]
if {[file isdirectory $demoOutDir]} {
    set outfile [file join $demoOutDir demo-aes256.pdf]
} else {
    set outfile $demoOutDir
}
set user    "geheim"
set owner   "admin"

set p [pdf4tcl::new %AUTO% -paper a4 -orient true \
    -userpassword  $user \
    -ownerpassword $owner \
    -encversion    5]

$p startPage
$p setFont 18 Helvetica-Bold
$p text "pdf4tcl 0.9.4.16 \u2014 AES-256 Demo" -x 72 -y 72

$p setFont 12 Helvetica
$p text "Dieses PDF ist mit AES-256 (V=5/R=6) verschluesselt." -x 72 -y 112
$p text "User-Passwort:  $user"  -x 72 -y 137
$p text "Owner-Passwort: $owner" -x 72 -y 162

$p setFont 10 Helvetica
$p text "Verifizierung:" -x 72 -y 202
$p text "  qpdf --password=$user --check demo-aes256.pdf" -x 72 -y 222
$p text "  python3 verify_enc3.py demo-aes256.pdf $user"  -x 72 -y 242

$p endPage
$p write -file $outfile
$p destroy

puts "Geschrieben: $outfile ([file size $outfile] Bytes)"
puts "Pruefen mit: qpdf --password=$user --check $outfile"
