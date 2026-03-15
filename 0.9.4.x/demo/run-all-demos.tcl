#!/usr/bin/env tclsh
# run-all-demos.tcl -- alle pdf4tcl Demos ausfuehren
#
# Fuehrt alle Demo-Skripte aus und sammelt Ergebnisse.
# Demos die Tk benoetigen werden uebersprungen wenn kein DISPLAY gesetzt ist.
#
# Usage:
#   tclsh run-all-demos.tcl              -- Ausgabe nach demo/out/
#   tclsh run-all-demos.tcl --outdir /tmp/pdfout

set demodir  [file dirname [file normalize [info script]]]
set reporoot [file normalize [file join $demodir ../..]]

# ---------------------------------------------------------------------------
# Argumente
# ---------------------------------------------------------------------------

set outdir [file join $demodir out]
set idx [lsearch $argv --outdir]
if {$idx >= 0} {
    set outdir [lindex $argv [expr {$idx + 1}]]
}
file mkdir $outdir

# ---------------------------------------------------------------------------
# Tk verfuegbar?
# ---------------------------------------------------------------------------

set hasTk [expr {[info exists env(DISPLAY)] && $env(DISPLAY) ne ""}]

# ---------------------------------------------------------------------------
# Demo-Liste
# Eintraege: {skriptname tk_erforderlich beschreibung}
# ---------------------------------------------------------------------------

# Demo-Liste
# Eintraege: {skriptname tk_erforderlich argschema beschreibung}
# argschema:
#   none      -- kein Argument (schreibt in demodir)
#   dir       -- outdir als positionales Argument
#   file NAME -- outdir/NAME als positionales Argument
#   --out     -- --out outdir
#   --out+    -- --out outdir (plus weitere feste Argumente moeglich)

set DEMOS {
    {minimalPdf.tcl              0  none       "Minimales PDF (Hello World)"}
    {FarbenundFormen.tcl         0  none       "Farben und Formen"}
    {demo-all.tcl                0  none       "Alle Features (Comprehensive)"}
    {demo-alpha.tcl              0  {file demo-alpha.pdf}  "Transparenz (setAlpha/getAlpha)"}
    {demo-api-vergleich.tcl      0  none       "API-Vergleich (Font-Demo)"}
    {demo-cidfont.tcl            0  none       "CIDFont Unicode-Support"}
    {demo-embedfile.tcl          0  --out      "Eingebettete Dateien (addEmbeddedFile)"}
    {demo-encryption.tcl         0  dir        "AES-128 Verschluesselung"}
    {demo-pdfa.tcl               0  --out      "PDF/A direkt"}
    {demo-pdfa-gs.tcl            0  --out      "PDF/A via Ghostscript"}
    {demo-stdfonts-tabelle.tcl   0  none       "Standard-Fonts Tabelle"}
    {demo-stdfonts-tounicode.tcl 0  none       "Standard-Fonts ToUnicode"}
    {demo-symbole.tcl            0  none       "Symbole"}
    {demo-unicode-tabelle.tcl    0  none       "Unicode-Tabelle"}
    {fonts.tcl                   0  none       "Font-Demo"}
    {demo-forms-tk.tcl           1  none       "Formulare (Tk-GUI)"}
}

# ---------------------------------------------------------------------------
# Hilfsprozeduren
# ---------------------------------------------------------------------------

proc ok   {msg} { puts "  OK     $msg" }
proc skip {msg} { puts "  SKIP   $msg" }
proc fail {msg} { puts "  FEHLER $msg" }

# ---------------------------------------------------------------------------
# Demos ausfuehren
# ---------------------------------------------------------------------------

set n_ok   0
set n_skip 0
set n_fail 0
set failed {}

puts "Ausgabe: $outdir"
puts "Tk verfuegbar: [expr {$hasTk ? {ja} : {nein (DISPLAY nicht gesetzt)}}]"
puts "\n[string repeat - 60]"

foreach demo $DEMOS {
    lassign $demo script needsTk argschema desc

    set scriptpath [file join $demodir $script]

    # Datei vorhanden?
    if {![file exists $scriptpath]} {
        skip "$script -- Datei nicht gefunden"
        incr n_skip
        continue
    }

    # Tk-Check
    if {$needsTk && !$hasTk} {
        skip "$script -- benoetigt Tk (kein DISPLAY)"
        incr n_skip
        continue
    }

    # Argumente aufbauen
    set extraargs {}
    switch -glob $argschema {
        none      { }
        dir       { set extraargs [list $outdir] }
        {file *}  { set fname [lindex $argschema 1]
                    set extraargs [list [file join $outdir $fname]] }
        --out     { set extraargs [list --out $outdir] }
    }

    # Ausfuehren
    puts -nonewline "  RUN    $script ... "
    flush stdout

    set cmd [list tclsh $scriptpath {*}$extraargs]
    if {[catch {exec {*}$cmd 2>@stdout} result]} {
        puts "FEHLER"
        if {$result ne ""} { puts "         $result" }
        lappend failed $script
        incr n_fail
    } else {
        puts "OK"
        incr n_ok
    }
}

# ---------------------------------------------------------------------------
# Zusammenfassung
# ---------------------------------------------------------------------------

puts "\n[string repeat - 60]"
puts "Ergebnis: $n_ok OK  /  $n_skip uebersprungen  /  $n_fail Fehler"

if {[llength $failed] > 0} {
    puts "\nFehlgeschlagen:"
    foreach s $failed { puts "  - $s" }
    exit 1
}

puts "\nAlle Demos erfolgreich. PDFs in: $outdir"
