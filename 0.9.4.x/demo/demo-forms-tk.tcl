#!/usr/bin/env wish
# demo-forms-tk.tcl
#
# Interactive Tk demo for pdf4tcl addForm
# - Margin, Area, coordinate system configurable
# - Font and size selectable via comboboxes
# - Debug: coordinates, field IDs, AcroForm dump, margin lines
# - All 8 field types testable individually or together
#
# Requirement: pdf4tcl 0.9.4.1
# Usage:  wish demo-forms-tk.tcl

package require Tk

set demodir  [file dirname [file normalize [info script]]]
set reporoot [file normalize [file join $demodir ../..]]
set auto_path [linsert $auto_path 0 $reporoot]

namespace eval ::demo {
    variable paper       "a4"
    variable orient      1
    variable compress    0
    variable marginLeft  15
    variable marginRight 15
    variable marginTop   15
    variable marginBottom 15
    variable formFont    "Helvetica"
    variable formSize    10
    variable labelFont   "Helvetica"
    variable labelSize   10
    variable titleFont   "Helvetica-Bold"
    variable titleSize   14
    variable showGrid      0
    variable showCoords    0
    variable showFieldIds  0
    variable dumpAcroForm  0
    variable outputFile    "demo-forms-output.pdf"
    variable openAfter     1
    variable fieldTypes {text password checkbox combobox listbox radiobutton pushbutton signature}
    # Field size variables (width/height per type)
    variable fieldWidth    200
    variable fieldHeight   20
    variable checkboxSize  14
    variable radiobuttonSize 12
    variable listboxHeight 48
    variable signatureWidth 120
    variable signatureHeight 40
    # Field position variables
    variable fieldX        0
    variable fieldY        0
    # Templates
    variable templates {
        default "Default (all fields)"
        minimal "Minimal (text, checkbox, pushbutton)"
        form "Form (text, combobox, radiobutton)"
        signature_only "Signature only"
    }
    variable currentTemplate "default"
    variable templateDesc "Default (all fields)"
    variable selectedTypes {}
    variable fontList {
        Helvetica Helvetica-Bold Helvetica-Oblique Helvetica-BoldOblique
        Times-Roman Times-Bold Times-Italic Times-BoldItalic
        Courier Courier-Bold Courier-Oblique Courier-BoldOblique
    }
    variable sizeList {6 7 8 9 10 11 12 14 16 18 20 24}
    variable paperList {a4 a5 letter legal}
}

proc ::demo::mm2pt {mm} { expr {$mm * 2.8346456693} }

proc ::demo::log {msg {tag ""}} {
    variable W
    if {![info exists W(log)]} return
    $W(log) configure -state normal
    if {$tag ne ""} {
        $W(log) insert end "$msg\n" $tag
    } else {
        $W(log) insert end "$msg\n"
    }
    $W(log) see end
    $W(log) configure -state disabled
}

proc ::demo::clearLog {} {
    variable W
    $W(log) configure -state normal
    $W(log) delete 1.0 end
    $W(log) configure -state disabled
}

proc ::demo::openPDF {path} {
    if {$path eq "" || ![file exists $path]} return
    log "Opening: $path"
    set os $::tcl_platform(os)
    catch {
        if {$os eq "Windows NT"} {
            exec {*}[auto_execok start] "" $path &
        } elseif {$os eq "Darwin"} {
            exec open $path &
        } else {
            exec xdg-open $path &
        }
    }
}

# \u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550
# Generate PDF
# \u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550

proc ::demo::generatePDF {} {
    variable paper;      variable orient;     variable compress
    variable marginLeft; variable marginRight
    variable marginTop;  variable marginBottom
    variable formFont;   variable formSize
    variable labelFont;  variable labelSize
    variable titleFont;  variable titleSize
    variable showGrid;   variable showCoords
    variable showFieldIds; variable dumpAcroForm
    variable selectedTypes; variable openAfter; variable outputFile
    variable fieldX; variable fieldY
    variable fieldWidth; variable fieldHeight
    variable checkboxSize; variable radiobuttonSize
    variable listboxHeight
    variable signatureWidth; variable signatureHeight

    if {[llength $selectedTypes] == 0} {
        tk_messageBox -icon warning -title "No Field Types" \
            -message "Please select at least one field type."
        return
    }
    clearLog
    log "=== PDF Generation ===" heading

    if {[catch {package require pdf4tcl} err]} {
        log "ERROR: pdf4tcl not found: $err" error
        return
    }
    log "pdf4tcl [package present pdf4tcl] loaded"

    # Paper sizes
    array set PS {a4 {595.28 841.89} a5 {419.53 595.28} letter {612 792} legal {612 1008}}
    if {![info exists PS($paper)]} { log "Format?: $paper" error; return }
    lassign $PS($paper) pageW pageH

    set mL [mm2pt $marginLeft];  set mR [mm2pt $marginRight]
    set mT [mm2pt $marginTop];   set mB [mm2pt $marginBottom]
    set areaX $mL
    set areaW [expr {$pageW - $mL - $mR}]
    set areaY $mT
    set areaH [expr {$pageH - $mT - $mB}]

    log [format "Paper: %s (%.0fx%.0f pt)  Orient: %d" $paper $pageW $pageH $orient]
    log [format "Margins: L=%.0f R=%.0f T=%.0f B=%.0f pt" $mL $mR $mT $mB]
    log [format "Area: x=%.0f y=%.0f w=%.0f h=%.0f (%.0fx%.0f mm)" \
         $areaX $areaY $areaW $areaH [expr {$areaW/2.835}] [expr {$areaH/2.835}]]
    log [format "Fonts: T=%s/%s L=%s/%s F=%s/%s" \
         $titleFont $titleSize $labelFont $labelSize $formFont $formSize]
    log ""

    set pdf [pdf4tcl::new %AUTO% -paper $paper -orient $orient -compress $compress]
    $pdf startPage

    # Debug: margin lines
    if {$showGrid} {
        log "Debug: margin lines" debug
        $pdf setStrokeColor 0.8 0.0 0.0
        $pdf setLineWidth 0.3
        $pdf setLineDash 3 2
        if {$orient} {
            $pdf line $mL $mT [expr {$pageW-$mR}] $mT
            $pdf line $mL [expr {$pageH-$mB}] [expr {$pageW-$mR}] [expr {$pageH-$mB}]
            $pdf line $mL $mT $mL [expr {$pageH-$mB}]
            $pdf line [expr {$pageW-$mR}] $mT [expr {$pageW-$mR}] [expr {$pageH-$mB}]
        } else {
            $pdf line $mL $mB [expr {$pageW-$mR}] $mB
            $pdf line $mL [expr {$pageH-$mT}] [expr {$pageW-$mR}] [expr {$pageH-$mT}]
            $pdf line $mL $mB $mL [expr {$pageH-$mT}]
            $pdf line [expr {$pageW-$mR}] $mB [expr {$pageW-$mR}] [expr {$pageH-$mT}]
        }
        $pdf setFillColor 0.8 0 0
        $pdf setFont 6 Helvetica
        if {$orient} {
            $pdf text [format "(%.0f,%.0f)" $mL $mT] -x [expr {$mL+2}] -y [expr {$mT+8}]
            $pdf text [format "(%.0f,%.0f)" [expr {$pageW-$mR}] [expr {$pageH-$mB}]] \
                -x [expr {$pageW-$mR-55}] -y [expr {$pageH-$mB-3}]
        }
        $pdf setFillColor 0 0 0; $pdf setStrokeColor 0 0 0
        $pdf setLineWidth 0.5; $pdf setLineDash 0 0
    }

    # Layout variables
    set x [expr {$areaX + $fieldX}]; set y [expr {$areaY + $fieldY}]
    set fH $fieldHeight; set fG 5; set sG 12
    set fW $fieldWidth
    set lX $x; set fX [expr {$x + 70}]
    set fc 0
    # Maximum Y position (bottom of printable area)
    set maxY [expr {$orient ? ($pageH - $mB) : ($mB)}]
    
    # Helper to check if we need a new page before adding a field
    proc _checkPageBreak {fy fh} {
        upvar maxY maxY orient orient pdf pdf pageW pageW pageH pageH
        upvar mL mL mR mR mT mT mB mB areaX areaX areaW areaW
        upvar x x y y fieldX fieldX fieldY fieldY
        if {$orient} {
            # Top-left origin: y increases downward
            if {[expr {$fy + $fh}] > $maxY} {
                # Need new page
                $pdf endPage
                $pdf startPage
                # Redraw margin lines if needed
                upvar showGrid showGrid
                if {$showGrid} {
                    $pdf setStrokeColor 0.8 0.0 0.0
                    $pdf setLineWidth 0.3
                    $pdf setLineDash 3 2
                    $pdf line $mL $mT [expr {$pageW-$mR}] $mT
                    $pdf line $mL [expr {$pageH-$mB}] [expr {$pageW-$mR}] [expr {$pageH-$mB}]
                    $pdf line $mL $mT $mL [expr {$pageH-$mB}]
                    $pdf line [expr {$pageW-$mR}] $mT [expr {$pageW-$mR}] [expr {$pageH-$mB}]
                    $pdf setFillColor 0 0 0; $pdf setStrokeColor 0 0 0
                    $pdf setLineWidth 0.5; $pdf setLineDash 0 0
                }
                # Reset y to top of new page
                set y [expr {$mT + $fieldY}]
                return 1
            }
        } else {
            # Bottom-left origin: y increases upward
            if {[expr {$fy - $fh}] < $maxY} {
                # Need new page
                $pdf endPage
                $pdf startPage
                # Reset y to bottom of new page
                set y [expr {$pageH - $mT - $fieldY}]
                return 1
            }
        }
        return 0
    }

    # Title
    $pdf setFont $titleSize $titleFont
    $pdf text "pdf4tcl Forms Demo" -x $x -y $y
    set y [expr {$y + $titleSize + 3}]
    $pdf setFont 7 Helvetica
    $pdf setFillColor 0.4 0.4 0.4
    $pdf text [format "Font:%s/%s Label:%s/%s Margin:%s/%s/%s/%smm" \
        $formFont $formSize $labelFont $labelSize \
        $marginLeft $marginRight $marginTop $marginBottom] -x $x -y $y
    $pdf setFillColor 0 0 0
    set y [expr {$y + 10}]
    $pdf setStrokeColor 0.3 0.3 0.3; $pdf setLineWidth 1.0
    $pdf line $x $y [expr {$x + $areaW}] $y
    $pdf setStrokeColor 0 0 0; $pdf setLineWidth 0.5
    set y [expr {$y + $sG}]

    # Helper procs for field creation
    proc _lbl {pdf lx ly text lf ls sc} {
        $pdf setFont $ls $lf
        $pdf text $text -x $lx -y [expr {$ly + 4}]
        if {$sc} {
            $pdf setFont 5 Courier; $pdf setFillColor 0.6 0 0
            $pdf text [format "(%d,%d)" [expr {int($lx)}] [expr {int($ly)}]] \
                -x $lx -y [expr {$ly - 4}]
            $pdf setFillColor 0 0 0
        }
    }
    proc _ido {pdf fx fy fw fh id sf} {
        if {$sf} {
            $pdf setFont 5 Courier; $pdf setFillColor 0 0 0.8
            $pdf text "id=$id" -x [expr {$fx+$fw+3}] -y [expr {$fy+4}]
            $pdf setFillColor 0 0 0
        }
    }
    proc _sec {pdf x y text aw ls} {
        $pdf setFont [expr {$ls+1}] Helvetica-Bold
        $pdf setFillColor 0.15 0.30 0.50
        $pdf text $text -x $x -y $y
        $pdf setFillColor 0 0 0
        set uy [expr {$y + $ls + 3}]
        $pdf setStrokeColor 0.15 0.30 0.50; $pdf setLineWidth 0.4
        $pdf line $x $uy [expr {$x + $aw}] $uy
        $pdf setStrokeColor 0 0 0; $pdf setLineWidth 0.5
        return [expr {$uy + 5}]
    }
    proc _fl {id fx fy fw fh {ex ""}} {
        ::demo::log [format "  %-16s @(%d,%d) %dx%d %s" \
            $id [expr {int($fx)}] [expr {int($fy)}] [expr {int($fw)}] [expr {int($fh)}] $ex]
    }

    # \u2550\u2550 TEXT \u2550\u2550
    if {"text" in $selectedTypes} {
        log "--- Text ---"
        set y [_sec $pdf $x $y "Text Fields" $areaW $labelSize]
        $pdf setFont $formSize $formFont

        _lbl $pdf $lX $y "Simple:" $labelFont $labelSize $showCoords
        $pdf addForm text $fX $y $fW $fH -id txt_simple
        _ido $pdf $fX $y $fW $fH txt_simple $showFieldIds
        _fl txt_simple $fX $y $fW $fH; incr fc
        set y [expr {$y + $fH + $fG}]

        _lbl $pdf $lX $y "Init Value:" $labelFont $labelSize $showCoords
        _checkPageBreak $y $fH
        $pdf addForm text $fX $y $fW $fH -id txt_init -init "Pre-filled"
        _ido $pdf $fX $y $fW $fH txt_init $showFieldIds
        _fl txt_init $fX $y $fW $fH "init='Pre-filled'"; incr fc
        set y [expr {$y + $fH + $fG}]

        set mlH [expr {$fieldHeight * 2.0}]
        _lbl $pdf $lX $y "Multiline:" $labelFont $labelSize $showCoords
        _checkPageBreak $y $mlH
        $pdf addForm text $fX $y $fW $mlH -id txt_multi -multiline 1
        _ido $pdf $fX $y $fW $mlH txt_multi $showFieldIds
        _fl txt_multi $fX $y $fW $mlH "multiline"; incr fc
        set y [expr {$y + $mlH + $fG}]

        _lbl $pdf $lX $y "Readonly:" $labelFont $labelSize $showCoords
        _checkPageBreak $y $fH
        $pdf addForm text $fX $y $fW $fH -id txt_ro -init "Not editable" -readonly 1
        _ido $pdf $fX $y $fW $fH txt_ro $showFieldIds
        _fl txt_ro $fX $y $fW $fH "readonly"; incr fc
        set y [expr {$y + $fH + $sG}]
    }

    # \u2550\u2550 PASSWORD \u2550\u2550
    if {"password" in $selectedTypes} {
        log "--- Password ---"
        set y [_sec $pdf $x $y "Password Fields" $areaW $labelSize]
        $pdf setFont $formSize $formFont

        _lbl $pdf $lX $y "Password:" $labelFont $labelSize $showCoords
        _checkPageBreak $y $fH
        $pdf addForm password $fX $y $fW $fH -id pw_empty
        _fl pw_empty $fX $y $fW $fH; incr fc
        set y [expr {$y + $fH + $fG}]

        _lbl $pdf $lX $y "With Init:" $labelFont $labelSize $showCoords
        _checkPageBreak $y $fH
        $pdf addForm password $fX $y $fW $fH -id pw_init -init "secret"
        _fl pw_init $fX $y $fW $fH "init=****"; incr fc
        set y [expr {$y + $fH + $sG}]
    }

    # \u2550\u2550 CHECKBOX \u2550\u2550
    if {"checkbox" in $selectedTypes} {
        log "--- Checkbox ---"
        set y [_sec $pdf $x $y "Checkbox Fields" $areaW $labelSize]
        $pdf setFont $formSize $formFont
        set cbS $checkboxSize; set cx $fX
        foreach {id lbl ini ro} {cb_off Unchecked 0 0 cb_on Checked 1 0 cb_ro Readonly 1 1} {
            set opts [list -id $id -init $ini]
            if {$ro} { lappend opts -readonly 1 }
            $pdf addForm checkbox $cx $y $cbS $cbS {*}$opts
            $pdf setFont $formSize $formFont
            $pdf text $lbl -x [expr {$cx+$cbS+4}] -y [expr {$y+3}]
            _ido $pdf $cx $y $cbS $cbS $id $showFieldIds
            _fl $id $cx $y $cbS $cbS "init=$ini"; incr fc
            set cx [expr {$cx + 100}]
        }
        set y [expr {$y + $cbS + $sG}]
    }

    # \u2550\u2550 COMBOBOX + LISTBOX (side by side) \u2550\u2550
    if {"combobox" in $selectedTypes || "listbox" in $selectedTypes} {
        set bothTypes [expr {"combobox" in $selectedTypes && "listbox" in $selectedTypes}]
        if {$bothTypes} {
            set secTitle "Combobox / Listbox Fields"
        } elseif {"combobox" in $selectedTypes} {
            set secTitle "Combobox Fields"
        } else {
            set secTitle "Listbox Fields"
        }
        log "--- $secTitle ---"
        set y [_sec $pdf $x $y $secTitle $areaW $labelSize]
        $pdf setFont $formSize $formFont

        # Column geometry: left = combobox, right = listbox
        set colGap 20
        set halfW  [expr {($areaW - $colGap) / 2.0}]
        set rX     [expr {$x + $halfW + $colGap}]
        set cW     [expr {$halfW - 70}]
        set lW     [expr {$halfW - 50}]
        set lH     $listboxHeight
        set yL     $y
        set yR     $y

        # \u2500\u2500 Left column: Combobox \u2500\u2500
        if {"combobox" in $selectedTypes} {
            _lbl $pdf $lX $yL "Standard:" $labelFont $labelSize $showCoords
            $pdf addForm combobox $fX $yL $cW $fH -id cmb_std \
                -options {"Red" "Green" "Blue" "Yellow" "White"} -init "Red"
            _fl cmb_std $fX $yL $cW $fH "5 opts, init=Red"; incr fc
            set yL [expr {$yL + $fH + $fG}]

            _lbl $pdf $lX $yL "Editable:" $labelFont $labelSize $showCoords
            $pdf addForm combobox $fX $yL $cW $fH -id cmb_edit \
                -options {"Option A" "Option B" "Option C"} -editable 1
            _fl cmb_edit $fX $yL $cW $fH "editable"; incr fc
            set yL [expr {$yL + $fH + $fG}]

            _lbl $pdf $lX $yL "Sorted:" $labelFont $labelSize $showCoords
            $pdf addForm combobox $fX $yL $cW $fH -id cmb_sort \
                -options {"Cherry" "Apple" "Banana" "Date"} -sort 1
            _fl cmb_sort $fX $yL $cW $fH "sort=1"; incr fc
            set yL [expr {$yL + $fH + $fG}]

            _lbl $pdf $lX $yL "Readonly:" $labelFont $labelSize $showCoords
            $pdf addForm combobox $fX $yL $cW $fH -id cmb_ro \
                -options {"Fixed" "Locked"} -init "Fixed" -readonly 1
            _fl cmb_ro $fX $yL $cW $fH "readonly"; incr fc
            set yL [expr {$yL + $fH}]
        }

        # \u2500\u2500 Right column: Listbox \u2500\u2500
        if {"listbox" in $selectedTypes} {
            set rlX $rX
            set rlFX [expr {$rX + 50}]
            _lbl $pdf $rlX $yR "Single:" $labelFont $labelSize $showCoords
            $pdf addForm listbox $rlFX $yR $lW $lH -id lb_single \
                -options {"Apple" "Pear" "Cherry" "Plum" "Grape"}
            _fl lb_single $rlFX $yR $lW $lH "5 opts"; incr fc
            set yR [expr {$yR + $lH + $fG}]

            _lbl $pdf $rlX $yR "Multi:" $labelFont $labelSize $showCoords
            $pdf addForm listbox $rlFX $yR $lW $lH -id lb_multi \
                -options {"Alpha" "Beta" "Gamma" "Delta" "Epsilon"} -multiselect 1
            _fl lb_multi $rlFX $yR $lW $lH "multiselect"; incr fc
            set yR [expr {$yR + $lH}]
        }

        # Continue from whichever column is lower
        set y [expr {max($yL, $yR) + $sG}]
    }

    # \u2550\u2550 RADIOBUTTON \u2550\u2550
    if {"radiobutton" in $selectedTypes} {
        log "--- Radiobutton ---"
        set y [_sec $pdf $x $y "Radiobutton Fields" $areaW $labelSize]
        $pdf setFont $formSize $formFont
        set rS $radiobuttonSize

        _lbl $pdf $lX $y "Size:" $labelFont $labelSize $showCoords
        set rx $fX
        foreach {val lbl ini} {Small Small 0 Medium Medium 1 Large Large 0} {
            $pdf addForm radiobutton $rx $y $rS $rS -group rb_size -value $val -init $ini
            $pdf setFont $formSize $formFont
            $pdf text $lbl -x [expr {$rx+$rS+3}] -y [expr {$y+3}]
            incr fc; set rx [expr {$rx+80}]
        }
        _fl rb_size $fX $y 240 $rS "3 values, init=Medium"
        set y [expr {$y + $rS + $fG}]

        _lbl $pdf $lX $y "Shipping:" $labelFont $labelSize $showCoords
        set rx $fX
        foreach {val lbl} {Normal Normal Express Express Pickup Pickup} {
            $pdf addForm radiobutton $rx $y $rS $rS -group rb_ship -value $val
            $pdf setFont $formSize $formFont
            $pdf text $lbl -x [expr {$rx+$rS+3}] -y [expr {$y+3}]
            incr fc; set rx [expr {$rx+90}]
        }
        _fl rb_ship $fX $y 270 $rS "3 values"
        set y [expr {$y + $rS + $sG}]
    }

    # \u2550\u2550 PUSHBUTTON \u2550\u2550
    if {"pushbutton" in $selectedTypes} {
        log "--- Pushbutton ---"
        set y [_sec $pdf $x $y "Pushbutton Fields" $areaW $labelSize]
        $pdf setFont $formSize $formFont
        set bW 100; set bH 24

        $pdf addForm pushbutton $fX $y $bW $bH -id btn_reset -caption "Clear" -action reset
        _fl btn_reset $fX $y $bW $bH "reset"; incr fc
        set bx2 [expr {$fX+$bW+10}]
        $pdf addForm pushbutton $bx2 $y $bW $bH -id btn_url -caption "Website" \
            -action url -url "https://example.com"
        _fl btn_url $bx2 $y $bW $bH "url"; incr fc
        set bx3 [expr {$bx2+$bW+10}]
        $pdf addForm pushbutton $bx3 $y $bW $bH -id btn_submit -caption "Submit" \
            -action submit -url "https://example.com/submit"
        _fl btn_submit $bx3 $y $bW $bH "submit"; incr fc
        set y [expr {$y + $bH + $sG}]
    }

    # \u2550\u2550 SIGNATURE \u2550\u2550
    if {"signature" in $selectedTypes} {
        log "--- Signature ---"
        set y [_sec $pdf $x $y "Signature Field" $areaW $labelSize]
        $pdf setFont $formSize $formFont
        set sW $signatureWidth; set sH $signatureHeight
        _lbl $pdf $lX $y "Signature:" $labelFont $labelSize $showCoords
        _checkPageBreak $y $sH
        $pdf addForm signature $fX $y $sW $sH -id sig_main -label "Sign here"
        _ido $pdf $fX $y $sW $sH sig_main $showFieldIds
        _fl sig_main $fX $y $sW $sH "label"; incr fc
        set y [expr {$y + $sH + $sG}]
    }

    # Footer
    $pdf setFont 7 Helvetica; $pdf setFillColor 0.5 0.5 0.5
    set footY [expr {$orient ? ($pageH-$mB+6) : ($mB-12)}]
    $pdf text [format "Created: %s | Fields: %d | pdf4tcl %s" \
        [clock format [clock seconds] -format "%Y-%m-%d %H:%M"] \
        $fc [package present pdf4tcl]] -x $x -y $footY
    $pdf setFillColor 0 0 0

    # Save
    set outputPath [file join [pwd] $outputFile]
    if {[catch {$pdf write -file $outputPath} err]} {
        log "ERROR: $err" error; $pdf destroy; return
    }
    $pdf destroy

    log ""
    log [format "=== Saved: %s ===" $outputPath] heading
    log [format "    %d fields, types: %s" $fc [join $selectedTypes ", "]]
    if {[file exists $outputPath]} {
        log [format "    Size: %d bytes (%.1f KB)" \
            [file size $outputPath] [expr {[file size $outputPath]/1024.0}]]
    }

    if {$dumpAcroForm} {
        log "\n--- AcroForm Dump ---" debug
        catch {
            set forms [pdf4tcl::getForms $outputPath]
            dict for {fid fi} $forms {
                log [format "  %-16s type=%-12s flags=%-6s val='%s'" \
                    $fid [dict get $fi type] [dict get $fi flags] [dict get $fi value]]
            }
        }
    }
    if {$openAfter} { openPDF $outputPath }
}

# \u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550
# Debug Tools
# \u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550

proc ::demo::calcArea {} {
    variable W; variable paper
    variable marginLeft; variable marginRight
    variable marginTop;  variable marginBottom
    array set PS {a4 {595.28 841.89} a5 {419.53 595.28} letter {612 792} legal {612 1008}}
    if {![info exists PS($paper)]} { $W(areaInfo) configure -text "?"; return }
    lassign $PS($paper) pw ph
    set mL [mm2pt $marginLeft]; set mR [mm2pt $marginRight]
    set mT [mm2pt $marginTop];  set mB [mm2pt $marginBottom]
    set aw [expr {$pw-$mL-$mR}]; set ah [expr {$ph-$mT-$mB}]
    $W(areaInfo) configure -text [format \
        "Page: %.0fx%.0f pt | Area: %.0fx%.0f pt (%.0fx%.0f mm) | Start: (%.0f,%.0f)" \
        $pw $ph $aw $ah [expr {$aw/2.835}] [expr {$ah/2.835}] $mL $mT]
}

proc ::demo::showPdf4tclInfo {} {
    clearLog; log "=== pdf4tcl Info ===" heading
    if {[catch {package require pdf4tcl} err]} { log "Not loaded: $err" error; return }
    log "Version: [package present pdf4tcl]"
    log "auto_path:"
    foreach p $::auto_path {
        if {[glob -nocomplain [file join $p pdf4tcl*]] ne ""} { log "  $p" debug }
    }
    log "\nCommands:"
    foreach cmd [lsort [info commands ::pdf4tcl::*]] { log "  [namespace tail $cmd]" }
}

proc ::demo::showFontList {} {
    clearLog; log "=== Standard PDF Fonts ===" heading
    log "\nSans-Serif (Helvetica):" debug
    foreach f {Helvetica Helvetica-Bold Helvetica-Oblique Helvetica-BoldOblique} { log "  $f" }
    log "\nSerif (Times):" debug
    foreach f {Times-Roman Times-Bold Times-Italic Times-BoldItalic} { log "  $f" }
    log "\nMonospace (Courier):" debug
    foreach f {Courier Courier-Bold Courier-Oblique Courier-BoldOblique} { log "  $f" }
    log "\nSpecial:" debug
    log "  Symbol (Greek characters)"
    log "  ZapfDingbats (Special characters)"
    log "\nNote: Helvetica=-Oblique, Times=-Italic, case sensitive!" debug
}

proc ::demo::coordCalc {} {
    clearLog; variable paper; variable orient; variable marginTop; variable marginLeft
    log "=== Coordinate Calculator ===" heading
    array set PS {a4 {595.28 841.89} a5 {419.53 595.28} letter {612 792} legal {612 1008}}
    if {![info exists PS($paper)]} return
    lassign $PS($paper) pw ph
    set mL [mm2pt $marginLeft]; set mT [mm2pt $marginTop]
    log ""
    if {$orient} {
        log "Orient=1 (top-left, y downward):" debug
        log "  First line:     y = [format %.1f $mT]"
        log "  at 50mm:        y = [format %.1f [mm2pt 50]]"
        log "  at 100mm:       y = [format %.1f [mm2pt 100]]"
        log "  Page center:    y = [format %.1f [expr {$ph/2.0}]]"
    } else {
        log "Orient=0 (bottom-left, y upward):" debug
        log "  First line:     y = [format %.1f [expr {$ph-$mT}]]"
        log "  at 50mm:        y = [format %.1f [expr {$ph-[mm2pt 50]}]]"
        log "  at 100mm:       y = [format %.1f [expr {$ph-[mm2pt 100]}]]"
        log "  Page center:    y = [format %.1f [expr {$ph/2.0}]]"
    }
    log "\nConversion:" debug
    log "  1mm=2.835pt  1cm=28.35pt  1in=72pt"
    log "  A4=210x297mm=595x842pt"
}

proc ::demo::fflagCalc {} {
    clearLog; log "=== Ff-Flag Calculator ===" heading
    log ""
    log "Bit constants:" debug
    foreach {name val} {
        READONLY 1 REQUIRED 2 NOEXPORT 4 MULTILINE 4096
        PASSWORD 8192 NOTOGGLEOFF 16384 RADIO 32768
        PUSHBUTTON 65536 COMBO 131072 EDIT 262144 MULTISELECT 2097152
    } {
        log [format "  %-14s = %7d  (0x%06X)" $name $val $val]
    }
    log "\nExamples:" debug
    log "  Combobox:          131072 (COMBO)"
    log "  Combobox+Edit:     393216 (COMBO|EDIT)"
    log "  Combobox+RO:       131073 (COMBO|READONLY)"
    log "  Radio group:       49152 (RADIO|NOTOGGLEOFF)"
    log "  Text+Multiline:      4096 (MULTILINE)"
    log "  Text+ML+RO:          4097 (MULTILINE|READONLY)"
}

# \u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550
# Build GUI
# \u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550

proc ::demo::buildGUI {} {
    variable W; variable fontList; variable sizeList
    variable paperList; variable fieldTypes; variable selectedTypes
    variable templates; variable templateDesc
    set selectedTypes $fieldTypes
    set templateDesc [dict get $templates default]

    wm title . "pdf4tcl Forms Demo"
    wm geometry . 780x720
    wm minsize . 640 500

    ttk::panedwindow .pw -orient vertical
    pack .pw -fill both -expand 1 -padx 4 -pady 4
    set top [ttk::frame .pw.top]; .pw add $top -weight 0
    set bot [ttk::frame .pw.bot]; .pw add $bot -weight 1

    # \u2500\u2500 Notebook \u2500\u2500
    ttk::notebook $top.nb
    pack $top.nb -fill both -expand 1 -padx 2 -pady 2

    # Tab 1: Page & Margins
    set t1 [ttk::frame $top.nb.page]
    $top.nb add $t1 -text " Page & Margins "

    ttk::labelframe $t1.paper -text "Paper" -padding 6
    grid $t1.paper -row 0 -column 0 -sticky nsew -padx 4 -pady 4
    foreach {lbl var vals r} {
        "Format:" paper paperList 0  "Orient:" orient {} 1  "Compress:" compress {} 2
    } {
        ttk::label $t1.paper.l$r -text $lbl
        if {$vals ne ""} {
            ttk::combobox $t1.paper.c$r -textvariable ::demo::$var \
                -values [set ::demo::$vals] -width 10 -state readonly
        } else {
            ttk::combobox $t1.paper.c$r -textvariable ::demo::$var \
                -values {0 1} -width 10 -state readonly
        }
        grid $t1.paper.l$r -row $r -column 0 -sticky w -padx {0 4} -pady 1
        grid $t1.paper.c$r -row $r -column 1 -sticky w
    }

    ttk::labelframe $t1.margin -text "Margins (mm)" -padding 6
    grid $t1.margin -row 0 -column 1 -sticky nsew -padx 4 -pady 4
    set mr 0
    foreach {lbl var} {
        "Left:" marginLeft "Right:" marginRight "Top:" marginTop "Bottom:" marginBottom
    } {
        ttk::label $t1.margin.l$mr -text $lbl
        ttk::spinbox $t1.margin.s$mr -textvariable ::demo::$var \
            -from 5 -to 50 -increment 1 -width 6
        grid $t1.margin.l$mr -row $mr -column 0 -sticky w -padx {0 4}
        grid $t1.margin.s$mr -row $mr -column 1 -sticky w -pady 1
        incr mr
    }

    ttk::labelframe $t1.output -text "Output File" -padding 6
    grid $t1.output -row 1 -column 0 -columnspan 2 -sticky nsew -padx 4 -pady 4
    ttk::label $t1.output.lbl -text "Filename:"
    ttk::entry $t1.output.entry -textvariable ::demo::outputFile -width 30
    grid $t1.output.lbl -row 0 -column 0 -sticky w -padx {0 4} -pady 2
    grid $t1.output.entry -row 0 -column 1 -sticky ew -pady 2
    grid columnconfigure $t1.output 1 -weight 1

    ttk::labelframe $t1.area -text "Calculated Printable Area" -padding 6
    grid $t1.area -row 2 -column 0 -columnspan 2 -sticky nsew -padx 4 -pady 4
    set W(areaInfo) [ttk::label $t1.area.info -text "(Click Calculate)" -foreground gray40]
    pack $W(areaInfo) -anchor w
    ttk::button $t1.area.calc -text "Calculate" -command ::demo::calcArea
    pack $t1.area.calc -anchor w -pady {4 0}
    grid columnconfigure $t1 {0 1} -weight 1

    # Tab 2: Fonts
    set t2 [ttk::frame $top.nb.fonts]
    $top.nb add $t2 -text " Fonts & Sizes "
    foreach {grp vf vs lbl r c cs} {
        title titleFont titleSize  "Title Font"              0 0 ""
        label labelFont labelSize  "Label Font"              0 1 ""
        field formFont  formSize   "Field Font (Form Fields)" 1 0 "-columnspan 2"
    } {
        ttk::labelframe $t2.$grp -text $lbl -padding 6
        grid $t2.$grp -row $r -column $c -sticky nsew -padx 4 -pady 4 {*}$cs
        ttk::label $t2.$grp.lf -text "Font:"
        ttk::combobox $t2.$grp.cf -textvariable ::demo::$vf \
            -values $fontList -width 22 -state readonly
        ttk::label $t2.$grp.ls -text "Size:"
        ttk::combobox $t2.$grp.cs -textvariable ::demo::$vs \
            -values $sizeList -width 6 -state readonly
        grid $t2.$grp.lf -row 0 -column 0 -sticky w -padx {0 4}
        grid $t2.$grp.cf -row 0 -column 1 -sticky w
        grid $t2.$grp.ls -row 0 -column 2 -sticky w -padx {8 4}
        grid $t2.$grp.cs -row 0 -column 3 -sticky w
    }
    ttk::label $t2.field.hint \
        -text "(sets /DA in PDF - determines appearance in AcroForm fields)" \
        -foreground gray50
    grid $t2.field.hint -row 1 -column 0 -columnspan 4 -sticky w -pady {2 0}
    grid columnconfigure $t2 {0 1} -weight 1

    # Tab 3: Field Types
    set t3 [ttk::frame $top.nb.types]
    $top.nb add $t3 -text " Field Types "
    
    # Template selection
    ttk::labelframe $t3.tmpl -text "Template" -padding 6
    pack $t3.tmpl -fill x -padx 4 -pady {4 2}
    ttk::label $t3.tmpl.lbl -text "Preset:"
    ttk::combobox $t3.tmpl.cb -textvariable ::demo::currentTemplate \
        -values [dict keys [set ::demo::templates]] -width 25 -state readonly
    $t3.tmpl.cb set "default"
    bind $t3.tmpl.cb <<ComboboxSelected>> ::demo::applyTemplate
    ttk::label $t3.tmpl.desc -textvariable ::demo::templateDesc -foreground gray50
    grid $t3.tmpl.lbl -row 0 -column 0 -sticky w -padx {0 4} -pady 2
    grid $t3.tmpl.cb -row 0 -column 1 -sticky ew -pady 2
    grid $t3.tmpl.desc -row 1 -column 0 -columnspan 2 -sticky w -padx {0 4} -pady {0 2}
    grid columnconfigure $t3.tmpl 1 -weight 1
    
    ttk::labelframe $t3.sel -text "Fields in PDF" -padding 6
    pack $t3.sel -fill both -expand 1 -padx 4 -pady 4
    set col 0; set row 0
    foreach ft $fieldTypes {
        set ::demo::ft_$ft 1
        ttk::checkbutton $t3.sel.cb_$ft -text $ft \
            -variable ::demo::ft_$ft -command ::demo::updateSelectedTypes
        grid $t3.sel.cb_$ft -row $row -column $col -sticky w -padx 8 -pady 2
        incr col; if {$col >= 4} { set col 0; incr row }
    }
    set bf [ttk::frame $t3.sel.btns]
    grid $bf -row [expr {$row+1}] -column 0 -columnspan 4 -sticky w -padx 4 -pady {6 0}
    ttk::button $bf.all  -text "All On"  -width 10 -command {::demo::setAllTypes 1}
    ttk::button $bf.none -text "All Off" -width 10 -command {::demo::setAllTypes 0}
    pack $bf.all $bf.none -side left -padx 4

    # Tab 4: Field Layout
    set t4 [ttk::frame $top.nb.layout]
    $top.nb add $t4 -text " Field Layout "
    
    ttk::labelframe $t4.pos -text "Field Position (offset from margin)" -padding 6
    pack $t4.pos -fill x -padx 4 -pady {4 2}
    foreach {lbl var r} {
        "X offset (pt):" fieldX 0  "Y offset (pt):" fieldY 1
    } {
        ttk::label $t4.pos.l$r -text $lbl
        ttk::spinbox $t4.pos.s$r -textvariable ::demo::$var \
            -from 0 -to 1000 -increment 5 -width 8
        grid $t4.pos.l$r -row $r -column 0 -sticky w -padx {0 4} -pady 2
        grid $t4.pos.s$r -row $r -column 1 -sticky w -pady 2
    }
    
    ttk::labelframe $t4.size -text "Field Sizes" -padding 6
    pack $t4.size -fill x -padx 4 -pady 4
    foreach {lbl var r} {
        "Text/Password width (pt):" fieldWidth 0
        "Text/Password height (pt):" fieldHeight 1
        "Checkbox size (pt):" checkboxSize 2
        "Radiobutton size (pt):" radiobuttonSize 3
        "Listbox height (pt):" listboxHeight 4
        "Signature width (pt):" signatureWidth 5
        "Signature height (pt):" signatureHeight 6
    } {
        ttk::label $t4.size.l$r -text $lbl
        ttk::spinbox $t4.size.s$r -textvariable ::demo::$var \
            -from 5 -to 500 -increment 5 -width 8
        grid $t4.size.l$r -row $r -column 0 -sticky w -padx {0 4} -pady 2
        grid $t4.size.s$r -row $r -column 1 -sticky w -pady 2
    }

    # Tab 5: Debug
    set t5 [ttk::frame $top.nb.debug]
    $top.nb add $t5 -text " Debug "
    ttk::labelframe $t4.opts -text "Debug Options" -padding 6
    pack $t4.opts -fill both -expand 1 -padx 4 -pady 4
    foreach {var text} {
        showGrid     "Show margin lines (red dashed in PDF)"
        showCoords   "Show coordinates (x,y) at labels"
        showFieldIds "Show field IDs next to fields (id=...)"
        dumpAcroForm "AcroForm dump to log (getForms after generation)"
        openAfter    "Open PDF after generation with system viewer"
    } {
        ttk::checkbutton $t4.opts.$var -text $text -variable ::demo::$var
        pack $t4.opts.$var -anchor w -padx 8 -pady 2
    }
    ttk::separator $t4.opts.sep -orient horizontal
    pack $t4.opts.sep -fill x -padx 8 -pady 6
    set df [ttk::frame $t4.opts.btns]
    pack $df -anchor w -padx 8
    ttk::button $df.info   -text "pdf4tcl Info"        -command ::demo::showPdf4tclInfo
    ttk::button $df.fonts  -text "Font List"          -command ::demo::showFontList
    ttk::button $df.coords -text "Coordinate Calculator" -command ::demo::coordCalc
    ttk::button $df.flags  -text "Ff-Flag Calculator"     -command ::demo::fflagCalc
    pack $df.info $df.fonts $df.coords $df.flags -side left -padx 4

    # \u2500\u2500 Action Bar \u2500\u2500
    set af [ttk::frame $top.actions]
    pack $af -fill x -padx 4 -pady {4 2}
    ttk::button $af.gen   -text "  Generate PDF  " -command ::demo::generatePDF
    ttk::button $af.open  -text "Open Last PDF" \
        -command {::demo::openPDF $::demo::outputFile}
    ttk::button $af.clear -text "Clear Log" -command ::demo::clearLog
    ttk::separator $af.sep -orient vertical
    pack $af.gen -side left -padx {0 8}
    pack $af.sep -side left -fill y -padx 4
    pack $af.open $af.clear -side left -padx 4

    # \u2500\u2500 Log \u2500\u2500
    ttk::label $bot.lbl -text "Log:" -font TkSmallCaptionFont
    set W(log) [text $bot.log -height 12 -width 80 -font {Courier 9} \
        -state disabled -wrap none -relief sunken -bd 1 \
        -bg "#1e1e2e" -fg "#cdd6f4" -insertbackground "#cdd6f4" \
        -selectbackground "#45475a" -selectforeground "#cdd6f4"]
    ttk::scrollbar $bot.sby -orient vertical   -command [list $W(log) yview]
    ttk::scrollbar $bot.sbx -orient horizontal -command [list $W(log) xview]
    $W(log) configure -yscrollcommand [list $bot.sby set] \
                      -xscrollcommand [list $bot.sbx set]
    grid $bot.lbl -row 0 -column 0 -sticky w    -padx 4 -pady {2 0}
    grid $W(log)  -row 1 -column 0 -sticky nsew -padx {4 0} -pady 2
    grid $bot.sby -row 1 -column 1 -sticky ns   -pady 2
    grid $bot.sbx -row 2 -column 0 -sticky ew   -padx {4 0}
    grid columnconfigure $bot 0 -weight 1
    grid rowconfigure    $bot 1 -weight 1

    $W(log) tag configure heading -foreground "#f38ba8" -font {Courier 9 bold}
    $W(log) tag configure error   -foreground "#f38ba8"
    $W(log) tag configure debug   -foreground "#a6e3a1"

    # Initialize template
    applyTemplate
    
    log "pdf4tcl Forms Demo ready." heading
    log "Adjust settings in the tabs, then click 'Generate PDF'."
    log ""
}

proc ::demo::updateSelectedTypes {} {
    variable fieldTypes; variable selectedTypes
    set selectedTypes {}
    foreach ft $fieldTypes { if {[set ::demo::ft_$ft]} { lappend selectedTypes $ft } }
}

proc ::demo::setAllTypes {val} {
    variable fieldTypes
    foreach ft $fieldTypes { set ::demo::ft_$ft $val }
    updateSelectedTypes
}

proc ::demo::applyTemplate {} {
    variable currentTemplate
    variable templates
    variable fieldTypes
    
    set desc [dict get $templates $currentTemplate]
    set ::demo::templateDesc $desc
    
    # Reset all to off
    foreach ft $fieldTypes { set ::demo::ft_$ft 0 }
    
    # Apply template-specific selections
    switch $currentTemplate {
        "default" {
            foreach ft $fieldTypes { set ::demo::ft_$ft 1 }
        }
        "minimal" {
            set ::demo::ft_text 1
            set ::demo::ft_checkbox 1
            set ::demo::ft_pushbutton 1
        }
        "form" {
            set ::demo::ft_text 1
            set ::demo::ft_combobox 1
            set ::demo::ft_radiobutton 1
        }
        "signature_only" {
            set ::demo::ft_signature 1
        }
    }
    
    updateSelectedTypes
}

::demo::buildGUI
