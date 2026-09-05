#!/usr/bin/env tclsh
# demo-forms.tcl \u2014 Bestellformular ohne Verschluesselung
# Ablageort: pdf4tcl0.9.4.16src/pdf4tcl/demo/
# Aufruf:    tclsh demo-forms.tcl

# ---------------------------------------------------------------------------
# Wurzel suchen, nicht zaehlen. Markierung ist pkgIndex.tcl neben src/.
#
# Vorher stand hier [file join $scriptDir .. .. ..] -- drei Ebenen nach
# oben, also AUSSERHALB des Baums. Wer dort eine aeltere pdf4tcl liegen
# hat, bekam die, und eine Korrektur im Baum wirkte beim Demolauf nicht.
# Gemessen: eine behobene Stelle in getForms schlug weiter fehl.
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
lappend auto_path [pdf4tclRepoRoot $scriptDir] \
                  [file join $scriptDir ../../..]
package require pdf4tcl

# Ausgabe standardmaessig nach demo/out, optional ein Verzeichnis oder eine
# Datei als erstes Argument.
set demoOutDir [file join $scriptDir out]
if {$argc > 0} { set demoOutDir [lindex $argv 0] }
file mkdir [expr {[file isdirectory $demoOutDir] || ![file exists $demoOutDir]
                  ? $demoOutDir : [file dirname $demoOutDir]}]
if {[file isdirectory $demoOutDir]} {
    set outfile [file join $demoOutDir demo-forms.pdf]
} else {
    set outfile $demoOutDir
}

set p [pdf4tcl::new %AUTO% -paper a4 -orient true]

$p startPage

# --- Titel ---
$p setFont 16 Helvetica-Bold
$p text "Bestellformular" -x 72 -y 60

$p setLineWidth 0.5
$p setStrokeColor 0.5 0.5 0.5
$p line 72 75 520 75
$p setStrokeColor 0 0 0

# --- Textfelder ---
foreach {label id y} {
    "Name:"   f_name  105
    "Firma:"  f_firma 130
    "E-Mail:" f_email 155
} {
    $p setFont 10 Helvetica
    $p text $label -x 72 -y $y
    $p setFont 10 Helvetica
    $p addForm text 160 [expr {$y - 10}] 300 16 -id $id -init ""
}

# --- Combobox ---
$p setFont 10 Helvetica
$p text "Artikel:" -x 72 -y 180
$p setFont 10 Helvetica
$p addForm combobox 160 170 200 16 -id "f_artikel" \
    -options {"Artikel A" "Artikel B" "Artikel C" "Sonderbestellung"}

# --- Menge ---
$p setFont 10 Helvetica
$p text "Menge:" -x 72 -y 205
$p setFont 10 Helvetica
$p addForm text 160 195 60 16 -id "f_menge" -init "1"

# --- Radiobuttons ---
$p setFont 10 Helvetica
$p text "Prioritaet:" -x 72 -y 240
foreach {rid rval rx rlabel} {
    prio_n  normal    160 "Normal"
    prio_e  express   240 "Express"
    prio_o  overnight 320 "Overnight"
} {
    $p setFont 10 Helvetica
    $p addForm radiobutton $rx 230 12 12 -id $rid -group "prio" -value $rval
    $p setFont 10 Helvetica
    $p text $rlabel -x [expr {$rx + 16}] -y 240
}

# --- Checkbox ---
$p setFont 10 Helvetica
$p addForm checkbutton 72 263 12 12 -id "f_agb"
$p setFont 10 Helvetica
$p text "Ich akzeptiere die AGB." -x 90 -y 273

# --- Bemerkung ---
$p setFont 10 Helvetica
$p text "Bemerkung:" -x 72 -y 300
$p setFont 10 Helvetica
$p addForm text 160 285 300 55 -id "f_bemerkung" -multiline 1

# --- Buttons ---
$p setFont 10 Helvetica
$p addForm pushbutton 72 360 90 20 \
    -id "f_submit" -caption "Absenden" -action submit \
    -url "mailto:bestellung@example.com"

$p setFont 10 Helvetica
$p addForm pushbutton 175 360 90 20 \
    -id "f_reset" -caption "Zuruecksetzen" -action reset

# --- Kaestchen je Zeichen und ein Datumsfeld (0.9.4.63) ---
#
# Der Fall, um den es geht: ein Vordruck hat fuer das Kennzeichen ein
# Kaestchen je Zeichen. Ohne -comb schreibt das Feld eine Zeichenkette
# quer darueber; mit -comb sitzt jedes Zeichen in seinem Fach.
#
# Die Kaestchen hier sind gezeichnet, damit man es sieht -- auf einem
# echten Vordruck stehen sie schon auf dem Papier.
$p setFont 10 Helvetica
$p text "Kennzeichen:" -x 72 -y 405
set kx 160 ; set ky 393 ; set kw 160 ; set kh 18 ; set kn 8
for {set i 0} {$i <= $kn} {incr i} {
    $p line [expr {$kx + $i * double($kw)/$kn}] $ky \
            [expr {$kx + $i * double($kw)/$kn}] [expr {$ky + $kh}]
}
$p line $kx $ky [expr {$kx + $kw}] $ky
$p line $kx [expr {$ky + $kh}] [expr {$kx + $kw}] [expr {$ky + $kh}]
$p setFont 11 Helvetica
$p addForm text $kx $ky $kw $kh -id "f_kennzeichen" \
        -maxlen $kn -comb 1 -init "BORXY123"

# Die Beschriftung steht UEBER dem Vergleichsfeld, nicht daneben: der
# Satz ist laenger als der Platz links davon und lag sonst quer im Feld.
$p setFont 10 Helvetica
$p text "Zum Vergleich, dasselbe ohne -comb:" -x 72 -y 432
$p setFont 11 Helvetica
$p addForm text $kx 440 $kw $kh -id "f_ohne_comb" -init "BORXY123"

$p setFont 10 Helvetica
$p text "Datum:" -x 72 -y 485
$p setFont 10 Helvetica
$p addForm text 160 473 110 16 -id "f_datum" -format date -init "04.09.2026"
$p setFont 8 Helvetica
$p text "-format date, Muster dd.mm.yyyy" -x 285 -y 485

$p setFont 10 Helvetica
$p text "Lieferdatum (ISO):" -x 72 -y 512
$p setFont 10 Helvetica
$p addForm text 160 500 110 16 -id "f_liefer" -format {date format iso}
$p setFont 8 Helvetica
$p text "-format {date format iso}" -x 285 -y 512

$p endPage
$p write -file $outfile
$p destroy

# --------------------------------------------------------------------------
# Auslesen und Fuellen (0.9.4.50)
# --------------------------------------------------------------------------

puts ""
puts "Auslesen und Fuellen:"
set felder [pdf4tcl::getForms $outfile]
puts "  Felder: [join [lsort [dict keys $felder]] {, }]"

# Das erste Textfeld nehmen und fuellen.
set textfeld ""
dict for {id info} $felder {
    if {[dict exists $info type] && [dict get $info type] eq "/Tx"} {
        set textfeld $id
        break
    }
}
if {$textfeld ne ""} {
    set gefuellt [file rootname $outfile]-gefuellt.pdf
    set n [pdf4tcl::fillForms $outfile $gefuellt \
            [dict create $textfeld "Meier & Co (GmbH)"]]
    puts "  $n Feld gefuellt: $textfeld"
    set danach [pdf4tcl::getForms $gefuellt]
    puts "  Wert danach: [dict get $danach $textfeld value]"
    puts "  Geschrieben: $gefuellt"
    puts ""
    puts "  Der Wert steht in der Datei, GEZEICHNET wird er nicht."
    puts "  /NeedAppearances weist den Leser an, ihn darzustellen --"
    puts "  Acrobat und die gaengigen Browser tun das."

    # ----------------------------------------------------------------------
    # Der Rundlauf: auslesen, aendern, zurueckschreiben (0.9.4.55)
    # ----------------------------------------------------------------------
    puts ""
    puts "  Rundlauf ueber drei Durchgaenge:"
    set quelle $gefuellt
    for {set i 1} {$i <= 3} {incr i} {
        set alt [pdf4tcl::getForms $quelle]
        set neu {}
        dict for {k v} $alt {
            if {[string index [dict get $v value] 0] ne "/"} {
                dict set neu $k [dict get $v value]
            }
        }
        set ziel [file rootname $outfile]-rund$i.pdf
        pdf4tcl::fillForms $quelle $ziel $neu
        set jetzt [dict get [pdf4tcl::getForms $ziel] $textfeld value]
        puts "    $i. Durchgang: $jetzt"
        set quelle $ziel
    }
    puts ""
    puts "  getForms gibt AUSGEPACKT zurueck -- genau die Form, die"
    puts "  fillForms nimmt. Vorher verdoppelte sich die Maskierung"
    puts "  jedes Feldes, das man nicht angefasst hat, bei jedem"
    puts "  Durchgang."
}

# Was getForms von den neuen Angaben zurueckliest (0.9.4.63).
puts ""
puts "Kaestchen und Formate, zurueckgelesen:"
dict for {id f} [pdf4tcl::getForms $outfile] {
    if {[dict get $f maxlen] eq "" && ![dict get $f comb]} continue
    puts [format "  %-16s maxlen=%-4s comb=%s" $id \
            [dict get $f maxlen] [dict get $f comb]]
}
puts "  Was addForm schreiben kann, liest getForms auch zurueck --"
puts "  sonst verliert ein Nachbau die Kaestchen und merkt es erst"
puts "  am fertigen Formular."

# Ein Feld, das es nicht gibt, wird gemeldet statt uebergangen.
if {[catch {pdf4tcl::fillForms $outfile /tmp/verworfen.pdf {gibtsnicht x}} e]} {
    puts "  Unbekanntes Feld: [string range $e 0 60]..."
}

puts ""
puts "Geschrieben: $outfile ([file size $outfile] Bytes)"
puts "Oeffnen:     firefox $outfile"
