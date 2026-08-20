#!/usr/bin/env tclsh
# Minimal Factur-X container sketch (XML is illustrative, not EN 16931 complete)
source [file join [file dirname [info script]] ../_bootstrap.tcl]
pdf4tcl::doc::init [info script]
set font [pdf4tcl::doc::needFont freesans]
pdf4tcl::loadBaseTrueTypeFont BaseFreeSans $font
pdf4tcl::createFont BaseFreeSans InvoiceFont iso8859-1
set pdf [::pdf4tcl::new %AUTO% -paper a4 -orient 1 -pdfa 3b]
$pdf metadata -title "Invoice INV-demo" -author "Example GmbH"
$pdf startPage
$pdf setFont 12 InvoiceFont
$pdf text "Human-readable invoice (demo)." -x 50 -y 50
$pdf endPage
set xml {<?xml version="1.0" encoding="UTF-8"?>
<rsm:CrossIndustryInvoice xmlns:rsm="urn:un:unece:uncefact:data:standard:CrossIndustryInvoice:100">
  <rsm:ExchangedDocument><ram:ID xmlns:ram="urn:un:unece:uncefact:data:standard:ReusableAggregateBusinessInformationEntity:100">INV-demo</ram:ID></rsm:ExchangedDocument>
</rsm:CrossIndustryInvoice>
}
$pdf facturx -contents $xml -filename "factur-x.xml" \
        -conformance "EN 16931" -documenttype "INVOICE" -version "1.0"
set out [pdf4tcl::doc::outfile howto-facturx.pdf]
$pdf write -file $out
$pdf destroy

# ---------------------------------------------------------------------------
# The same for an order: Order-X (0.9.4.50)
# ---------------------------------------------------------------------------

# Order-X is the ordering counterpart. Same mechanism, same PDF/A-3
# requirement -- what differs is the namespace, the file name and the
# document types. Everything is delegated to facturx, so the two cannot
# drift apart.
set orderXml {<?xml version="1.0" encoding="UTF-8"?>
<rsm:SCRDMCCBDACIOMessageStructure
    xmlns:rsm="urn:un:unece:uncefact:data:SCRDMCCBDACIOMessageStructure:100">
  <rsm:ExchangedDocument><ram:ID>ORD-2026-0001</ram:ID></rsm:ExchangedDocument>
</rsm:SCRDMCCBDACIOMessageStructure>}

set op [::pdf4tcl::new %AUTO% -paper a4 -margin 50 -pdfa 3b -orient 1]
set ofont [pdf4tcl::doc::needFont freesans]
pdf4tcl::loadBaseTrueTypeFont OrderBase $ofont
pdf4tcl::createFontSpecCID OrderBase OrderBody
$op startPage
$op setFont 14 OrderBody
$op text "Purchase order ORD-2026-0001" -x 0 -y 40
$op setFont 10 OrderBody
$op text "The machine-readable order travels inside this file." -x 0 -y 70

# Profiles are basic, comfort, extended -- NOT the invoice levels. An
# invoice profile such as "EN 16931" is refused here, and "comfort" is
# refused by facturx.
$op orderx -contents $orderXml -documenttype ORDER -conformance comfort

set oout [pdf4tcl::doc::outfile howto-orderx.pdf]
$op write -file $oout
$op destroy
puts "order written: [file tail $oout]"

pdf4tcl::doc::done $out
