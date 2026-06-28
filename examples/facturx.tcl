#!/usr/bin/env tclsh
#
# facturx.tcl -- Factur-X / ZUGFeRD demo for pdf4tcl
#
# Produces a hybrid electronic invoice: a human-readable PDF/A-3b document with
# the machine-readable EN 16931 invoice XML embedded as the associated file
# "factur-x.xml", plus the Factur-X XMP extension schema. The result is the
# container a ZUGFeRD/Factur-X invoice needs.
#
# IMPORTANT: the CII XML built below is a minimal, illustrative skeleton meant
# to show how the pieces fit together. A production invoice must generate a
# COMPLETE EN 16931 Cross Industry Invoice and validate it (KoSIT/Schematron
# for the XML, veraPDF for the PDF/A-3 + Factur-X profile). pdf4tcl provides
# the PDF container only; generating and validating the XML is the
# application's responsibility.

set auto_path [linsert $auto_path 0 [file normalize [file join [file dirname [info script]] ..]]]
package require pdf4tcl

# PDF/A requires every font to be embedded -- the base-14 fonts (Helvetica ...)
# have no embeddable program, so load and embed a real TrueType font instead.
set fontFile [file join [file dirname [info script]] FreeSans.ttf]
pdf4tcl::loadBaseTrueTypeFont BaseFreeSans $fontFile
pdf4tcl::createFont BaseFreeSans InvoiceFont iso8859-1

# ---------------------------------------------------------------------------
# Invoice data (one place to edit)
# ---------------------------------------------------------------------------
set inv(no)        "INV-2026-0001"
set inv(date)      "20260115"                 ;# CII format 102: YYYYMMDD
set inv(dateHuman) "15.01.2026"
set inv(currency)  "EUR"
set inv(buyerRef)  "04011000-1234512345-06"   ;# Leitweg-ID (B2G)

set seller(name)   "Muster GmbH"
set seller(street) "Musterstrasse 1"
set seller(zip)    "48691"
set seller(city)   "Vreden"
set seller(country) "DE"
set seller(vatid)  "DE123456789"

set buyer(name)    "Beispiel AG"
set buyer(street)  "Beispielweg 2"
set buyer(zip)     "10115"
set buyer(city)    "Berlin"
set buyer(country) "DE"

# one line item; amounts kept consistent across line and header totals
set item(name)     "Beratungsleistung"
set item(qty)      "2"
set item(unit)     "C62"      ;# UN/ECE Rec 20: C62 = "one/piece"
set item(price)    "50.00"
set item(net)      "100.00"
set vat(rate)      "19.00"
set vat(amount)    "19.00"
set total(net)     "100.00"
set total(gross)   "119.00"

# ---------------------------------------------------------------------------
# Build the EN 16931 (COMFORT) Cross Industry Invoice XML
# ---------------------------------------------------------------------------
proc xmlEsc {s} {
    return [string map {& &amp; < &lt; > &gt; \" &quot;} $s]
}

proc buildCII {} {
    global inv seller buyer item vat total
    set ns1 "urn:un:unece:uncefact:data:standard:CrossIndustryInvoice:100"
    set ns2 "urn:un:unece:uncefact:data:standard:ReusableAggregateBusinessInformationEntity:100"
    set ns3 "urn:un:unece:uncefact:data:standard:UnqualifiedDataType:100"
    set x "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n"
    append x "<rsm:CrossIndustryInvoice xmlns:rsm=\"$ns1\" xmlns:ram=\"$ns2\" xmlns:udt=\"$ns3\">\n"
    append x "  <rsm:ExchangedDocumentContext>\n"
    append x "    <ram:GuidelineSpecifiedDocumentContextParameter>\n"
    append x "      <ram:ID>urn:cen.eu:en16931:2017</ram:ID>\n"
    append x "    </ram:GuidelineSpecifiedDocumentContextParameter>\n"
    append x "  </rsm:ExchangedDocumentContext>\n"
    append x "  <rsm:ExchangedDocument>\n"
    append x "    <ram:ID>[xmlEsc $inv(no)]</ram:ID>\n"
    append x "    <ram:TypeCode>380</ram:TypeCode>\n"
    append x "    <ram:IssueDateTime>\n"
    append x "      <udt:DateTimeString format=\"102\">$inv(date)</udt:DateTimeString>\n"
    append x "    </ram:IssueDateTime>\n"
    append x "  </rsm:ExchangedDocument>\n"
    append x "  <rsm:SupplyChainTradeTransaction>\n"
    append x "    <ram:IncludedSupplyChainTradeLineItem>\n"
    append x "      <ram:AssociatedDocumentLineDocument><ram:LineID>1</ram:LineID></ram:AssociatedDocumentLineDocument>\n"
    append x "      <ram:SpecifiedTradeProduct><ram:Name>[xmlEsc $item(name)]</ram:Name></ram:SpecifiedTradeProduct>\n"
    append x "      <ram:SpecifiedLineTradeAgreement>\n"
    append x "        <ram:NetPriceProductTradePrice><ram:ChargeAmount>$item(price)</ram:ChargeAmount></ram:NetPriceProductTradePrice>\n"
    append x "      </ram:SpecifiedLineTradeAgreement>\n"
    append x "      <ram:SpecifiedLineTradeDelivery><ram:BilledQuantity unitCode=\"$item(unit)\">$item(qty)</ram:BilledQuantity></ram:SpecifiedLineTradeDelivery>\n"
    append x "      <ram:SpecifiedLineTradeSettlement>\n"
    append x "        <ram:ApplicableTradeTax><ram:TypeCode>VAT</ram:TypeCode><ram:CategoryCode>S</ram:CategoryCode><ram:RateApplicablePercent>$vat(rate)</ram:RateApplicablePercent></ram:ApplicableTradeTax>\n"
    append x "        <ram:SpecifiedTradeSettlementLineMonetarySummation><ram:LineTotalAmount>$item(net)</ram:LineTotalAmount></ram:SpecifiedTradeSettlementLineMonetarySummation>\n"
    append x "      </ram:SpecifiedLineTradeSettlement>\n"
    append x "    </ram:IncludedSupplyChainTradeLineItem>\n"
    append x "    <ram:ApplicableHeaderTradeAgreement>\n"
    append x "      <ram:BuyerReference>[xmlEsc $inv(buyerRef)]</ram:BuyerReference>\n"
    append x "      <ram:SellerTradeParty>\n"
    append x "        <ram:Name>[xmlEsc $seller(name)]</ram:Name>\n"
    append x "        <ram:PostalTradeAddress><ram:PostcodeCode>$seller(zip)</ram:PostcodeCode><ram:LineOne>[xmlEsc $seller(street)]</ram:LineOne><ram:CityName>[xmlEsc $seller(city)]</ram:CityName><ram:CountryID>$seller(country)</ram:CountryID></ram:PostalTradeAddress>\n"
    append x "        <ram:SpecifiedTaxRegistration><ram:ID schemeID=\"VA\">$seller(vatid)</ram:ID></ram:SpecifiedTaxRegistration>\n"
    append x "      </ram:SellerTradeParty>\n"
    append x "      <ram:BuyerTradeParty>\n"
    append x "        <ram:Name>[xmlEsc $buyer(name)]</ram:Name>\n"
    append x "        <ram:PostalTradeAddress><ram:PostcodeCode>$buyer(zip)</ram:PostcodeCode><ram:LineOne>[xmlEsc $buyer(street)]</ram:LineOne><ram:CityName>[xmlEsc $buyer(city)]</ram:CityName><ram:CountryID>$buyer(country)</ram:CountryID></ram:PostalTradeAddress>\n"
    append x "      </ram:BuyerTradeParty>\n"
    append x "    </ram:ApplicableHeaderTradeAgreement>\n"
    append x "    <ram:ApplicableHeaderTradeDelivery/>\n"
    append x "    <ram:ApplicableHeaderTradeSettlement>\n"
    append x "      <ram:InvoiceCurrencyCode>$inv(currency)</ram:InvoiceCurrencyCode>\n"
    append x "      <ram:ApplicableTradeTax><ram:CalculatedAmount>$vat(amount)</ram:CalculatedAmount><ram:TypeCode>VAT</ram:TypeCode><ram:BasisAmount>$total(net)</ram:BasisAmount><ram:CategoryCode>S</ram:CategoryCode><ram:RateApplicablePercent>$vat(rate)</ram:RateApplicablePercent></ram:ApplicableTradeTax>\n"
    append x "      <ram:SpecifiedTradeSettlementHeaderMonetarySummation>\n"
    append x "        <ram:LineTotalAmount>$total(net)</ram:LineTotalAmount>\n"
    append x "        <ram:TaxBasisTotalAmount>$total(net)</ram:TaxBasisTotalAmount>\n"
    append x "        <ram:TaxTotalAmount currencyID=\"$inv(currency)\">$vat(amount)</ram:TaxTotalAmount>\n"
    append x "        <ram:GrandTotalAmount>$total(gross)</ram:GrandTotalAmount>\n"
    append x "        <ram:DuePayableAmount>$total(gross)</ram:DuePayableAmount>\n"
    append x "      </ram:SpecifiedTradeSettlementHeaderMonetarySummation>\n"
    append x "    </ram:ApplicableHeaderTradeSettlement>\n"
    append x "  </rsm:SupplyChainTradeTransaction>\n"
    append x "</rsm:CrossIndustryInvoice>\n"
    return $x
}

# ---------------------------------------------------------------------------
# Human-readable PDF/A-3b document
# ---------------------------------------------------------------------------
# -orient 0: y grows upward from the bottom-left (the coordinates below are
# written that way). pdf4tcl defaults to -orient 1 (y from the top), which
# would render this layout upside-down.
pdf4tcl::new p1 -paper a4 -pdfa 3b -compress 1 -orient 0

p1 metadata \
    -title        "Rechnung $inv(no)" \
    -author       $seller(name) \
    -subject      "Factur-X / ZUGFeRD invoice" \
    -creator      "pdf4tcl facturx demo" \
    -creationdate "D:20260115100000" \
    -moddate      "D:20260115100000"

p1 startPage

proc L {y size str {align left}} {
    p1 setFont $size InvoiceFont
    p1 text $str -x 60 -y $y -align $align
}
proc R {y size str} {
    p1 setFont $size InvoiceFont
    p1 text $str -x 535 -y $y -align right
}

# Title
L 790 20 "RECHNUNG"
R 790 9  "Factur-X / ZUGFeRD (EN 16931)"

# Seller / Buyer
L 750 11 $seller(name)
L 736 9  "$seller(street)"
L 724 9  "$seller(zip) $seller(city)"
L 712 9  "USt-IdNr: $seller(vatid)"

L 680 9  "Rechnung an:"
L 666 11 $buyer(name)
L 652 9  "$buyer(street)"
L 640 9  "$buyer(zip) $buyer(city)"

# Invoice meta
L 600 9  "Rechnungsnummer:"
R 600 9  $inv(no)
L 586 9  "Rechnungsdatum:"
R 586 9  $inv(dateHuman)
L 572 9  "Leitweg-ID:"
R 572 9  $inv(buyerRef)

# Table
p1 setLineWidth 0.5
p1 line 60 545 535 545
L 532 9  "Pos / Beschreibung"
R 532 9  "Menge        Einzelpreis        Betrag"
p1 line 60 525 535 525
L 510 10 "1   $item(name)"
R 510 10 "$item(qty)            $item(price) $inv(currency)        $item(net) $inv(currency)"
p1 line 60 495 535 495

# Totals
L 478 9  "Nettobetrag:"
R 478 9  "$total(net) $inv(currency)"
L 464 9  "USt $vat(rate) %:"
R 464 9  "$vat(amount) $inv(currency)"
p1 setFont 12 InvoiceFont
p1 text "Gesamtbetrag:" -x 60 -y 446
p1 text "$total(gross) $inv(currency)" -x 535 -y 446 -align right

# Footer note
L 110 8  "Diese Rechnung enthaelt eine eingebettete XML-Datei (factur-x.xml) nach EN 16931."
L 98  8  "Hybrid-Dokument: PDF/A-3 fuer Menschen, XML fuer die maschinelle Verarbeitung."

p1 endPage

# ---------------------------------------------------------------------------
# Embed the invoice XML + write the Factur-X XMP extension
# ---------------------------------------------------------------------------
set ::pdf4tcl::warnings {}
set xml [buildCII]

p1 facturx -contents $xml \
    -filename     "factur-x.xml" \
    -conformance  "EN 16931" \
    -documenttype "INVOICE" \
    -version      "1.0"

p1 write -file facturx-invoice.pdf
p1 destroy

# Also drop the standalone XML next to the PDF (handy for inspection/validation)
set fh [open "factur-x.xml" w]
fconfigure $fh -encoding utf-8
puts -nonewline $fh $xml
close $fh

puts "Wrote facturx-invoice.pdf (+ factur-x.xml) -- conformance EN 16931."
if {[llength $::pdf4tcl::warnings] > 0} {
    puts "Warnings:"
    foreach w $::pdf4tcl::warnings { puts "  - $w" }
} else {
    puts "No warnings (PDF/A-3b active)."
}
puts "Validate the XML against EN 16931 (KoSIT) and the PDF with veraPDF for production use."
