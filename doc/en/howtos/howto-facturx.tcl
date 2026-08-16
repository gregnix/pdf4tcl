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
pdf4tcl::doc::done $out
