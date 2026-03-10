#!/usr/bin/env tclsh -encoding cp1251
# example of using same fonts in many pdf4tcl objects.

#lappend auto_path [pwd]/../..
set auto_path [linsert $auto_path 0 [file normalize [file join [file dirname [info script]] ..]]]
#This file must be sourced in cp1251 encoding.
package require pdf4tcl

proc multipdf {args} {
    global G_pdfobjs
    foreach obj $G_pdfobjs {
        $obj {*}$args
    }
}

proc testmulti {} {
    global G_pdfobjs
    pdf4tcl::loadBaseTrueTypeFont BaseArial "FreeSans.ttf"
    pdf4tcl::createFont BaseArial MyArial cp1251 
    pdf4tcl::loadBaseType1Font BaseType1 "a010013l.afm" "a010013l.pfb"
    pdf4tcl::createFont BaseType1 MyType1 cp1251 
    set G_pdfobjs [list one two three]

    foreach obj $G_pdfobjs {
        pdf4tcl::new $obj -paper a4 -compress 1
    }

    multipdf startPage
    multipdf setFont 20 MyArial
    multipdf text "éöóêåíãøùçõúôûâàïðîëäæýÿ÷ñìèòüáþ" -x 50 -y 50 -bg #CACACA
    multipdf text "ÉÖÓÊÅÍÃØÙÇÕÚÔÛÂÀÏÐÎËÄÆÝß×ÑÌÈÒÜÁÞ" -x 50 -y 100 -bg #CACACA

    multipdf setFont 20 MyType1
    multipdf text "éöóêåíãøùçõúôûâàïðîëäæýÿ÷ñìèòüáþ" -x 50 -y 150 -bg #CACACA
    multipdf text "ÉÖÓÊÅÍÃØÙÇÕÚÔÛÂÀÏÐÎËÄÆÝß×ÑÌÈÒÜÁÞ" -x 50 -y 200 -bg #CACACA

    multipdf setFillColor #6A6A6A
    multipdf setFont 16 Courier
    multipdf text "This is text for testing purposes." -bg #8A8A8A -x 100 -y 370

    multipdf setFont 20 MyType1
    multipdf setFillColor #20FA20
    multipdf text "Skewed. Òåêñò ïîä óãëîì äëÿ ïðîâåðêè." -bg #000000 -x 200 -y 420 -xangle 10 -yangle 15 -angle 25

    foreach obj $G_pdfobjs {
        $obj write -file $obj.pdf 
        $obj destroy
    }
}

testmulti
