# TODO: Complete EN 16931 invoice profile

Status of the `examples/facturx.tcl` demo and what is still needed to turn its
embedded XML into a fully compliant EN 16931 (and XRechnung) invoice.

## Scope

pdf4tcl produces the **PDF/A-3 container** and embeds the invoice XML plus the
Factur-X XMP extension. That side is **done and validated** (veraPDF PDF/A-3B:
`isCompliant=true`, 0 failed checks).

This TODO is about the **embedded CII XML content** (`factur-x.xml`), which is an
application-level concern, not a pdf4tcl feature. The demo's `buildCII` currently
emits a **minimal, illustrative skeleton** that would NOT pass EN 16931 Schematron
validation yet.

Two layers of validation exist and are independent:

- **veraPDF** -> checks the PDF/A-3 + Factur-X *container*. Already green.
- **Schematron (KoSIT)** -> checks the *invoice content* against the EN 16931
  business rules (BR-*). Not addressed yet. This is the harder layer.

## Target level

Decide the target before filling in fields, because it sets the mandatory scope:

- **Pure EN 16931** (guideline `urn:cen.eu:en16931:2017`, what the demo uses now)
  -- the European core model. Fewest mandatory fields.
- **XRechnung** (German CIUS) -- EN 16931 plus ~50 extra `de-BR-*` rules
  (mandatory Leitweg-ID, payment means, delivery date, electronic addresses).
  Required for German B2G and increasingly B2B.
- **Factur-X EN 16931 / ZUGFeRD COMFORT** -- the profile the XMP already
  declares; aligned with EN 16931 core.

The demo's XMP `ConformanceLevel` (currently `EN 16931`) and the XML content must
match the chosen level.

## Already present in the demo XML

Document: BT-1 (number), BT-2 (issue date), BT-3 (type 380), BT-24 (spec id),
BT-5 (currency), BT-10 (BuyerReference / Leitweg-ID).
Seller (BG-4/5): BT-27 (name), BT-31 (VAT id), BT-40 (country) + address.
Buyer (BG-7/8): BT-44 (name), BT-55 (country) + address.
Line (BG-25): BT-126, BT-129+BT-130, BT-131, BT-146, BT-153, BT-151.
VAT breakdown (BG-23): BT-116, BT-117, BT-118, BT-119.
Totals (BG-22): BT-106, BT-109, BT-110, BT-112, BT-115.

## A. Required for pure EN 16931 (fatal Schematron failures today)

- [ ] **BR-CO-25** -- Amount due (BT-115) is positive, so the invoice MUST carry
      **Payment due date (BT-9)** OR **Payment terms (BT-20)**. Neither is present.
      CII: `…/ram:ApplicableHeaderTradeSettlement/ram:SpecifiedTradePaymentTerms/ram:DueDateDateTime/udt:DateTimeString` (BT-9, format 102)
      or `…/ram:SpecifiedTradePaymentTerms/ram:Description` (BT-20).
- [ ] **Calculation rules must balance exactly** (no rounding tolerance):
      BR-CO-10 (sum of line nets = BT-106), BR-CO-13 (BT-109 derivation),
      BR-CO-15 (BT-112 = BT-109 + BT-110), BR-S-08/09 (per-category VAT).
      All monetary amounts: max 2 decimals.
- [ ] **Code-list correctness**: unit code BT-130 from UN/ECE Rec 20/21
      (`C62` = piece, ok), VAT category BT-118/BT-151 from UNCL5305 (`S` = standard),
      currency BT-5 ISO 4217.
- [ ] **Exemption reason** BT-120 (code) / BT-121 (text) -- required when the VAT
      category is not `S` (e.g. `Z` zero, `E` exempt, `AE` reverse charge, `K`
      intra-community, `G` export). Not needed for the current `S` demo, but the
      generator must handle it.

## B. Additional for XRechnung (German CIUS)

- [ ] **Payment means (BG-16)** -- BT-81 payment means type code (e.g. `58` SEPA
      credit transfer) + BT-84 IBAN.
      CII: `…/ram:SpecifiedTradeSettlementPaymentMeans/ram:TypeCode` and
      `…/ram:PayeePartyCreditorFinancialAccount/ram:IBANID`.
- [ ] **Delivery / tax point date (BT-72)** -- actual delivery date, OR a billing
      period (BG-14). XRechnung requires one of them.
      CII: `…/ram:ApplicableHeaderTradeDelivery/ram:ActualDeliverySupplyChainEvent/ram:OccurrenceDateTime/udt:DateTimeString` (currently empty).
- [ ] **Seller electronic address (BT-34)** with `schemeID` (e.g. EM for email).
      CII: `…/ram:SellerTradeParty/ram:URIUniversalCommunication/ram:URIID schemeID="…"`.
- [ ] **Buyer electronic address (BT-49)** with `schemeID`.
      CII: `…/ram:BuyerTradeParty/ram:URIUniversalCommunication/ram:URIID schemeID="…"`.
- [ ] **Business process (BT-23)** -- e.g. `urn:fdc:peppol.eu:2017:poacc:billing:01:1.0`.
      CII: `rsm:ExchangedDocumentContext/ram:BusinessProcessSpecifiedDocumentContextParameter/ram:ID`.
- [ ] **Seller contact (BG-6)** -- name, phone, email (`ram:DefinedTradeContact`).
- [ ] **Seller legal registration (BT-30)** -- register/HRB number if applicable
      (`ram:SpecifiedLegalOrganization/ram:ID`).
- [ ] **Buyer reference (BT-10)** -- already present (Leitweg-ID).

## C. CII implementation notes

- **Element order is fixed** in CII (UN/CEFACT sequence). Adding a field in the
  wrong position fails XSD validation even if the value is correct. Follow the
  ZUGFeRD/Factur-X reference XML ordering.
- Keep the **PDF and the XML in sync**: every value shown in the human-readable
  PDF must equal the corresponding XML value (the demo already builds both from
  the same Tcl vars -- preserve that discipline).
- Always XML-escape free-text values (`xmlEsc` already does this).
- Amounts as strings with exactly 2 decimals; dates in CII format `102`
  (`YYYYMMDD`) unless a different `format` attribute is specified.

## D. Validation tooling

- [ ] **KoSIT validator** (Java) with the official scenario configuration:
      EN 16931 + (optionally) XRechnung Schematron. This is the authoritative
      Schematron check. Run the standalone `factur-x.xml` through it.
- [ ] **Mustang / ZUGFeRD validator** -- alternative that validates both the
      embedded XML and the PDF/A-3 container in one pass; good cross-check.
- [x] **veraPDF** PDF/A-3B -- already green for the container.

Practical loop: `examples/facturx.tcl` already writes the standalone
`factur-x.xml` next to the PDF, so it can be fed directly to KoSIT/Mustang.

## E. Suggested order of work

1. Pick the target level (pure EN 16931 vs XRechnung).
2. Extend `buildCII`: add BR-CO-25 (payment terms/due date) -> get pure EN 16931
   green in KoSIT.
3. Add payment means, delivery date, electronic addresses, business process
   -> XRechnung green.
4. Add exemption-reason handling and multi-line / multi-rate support so the
   generator is reusable beyond the single-line demo.
5. Wire the generator into the application (lieferschein/faktura) instead of the
   hard-coded demo data.

## Notes

- This is deliberately deferred; the container (pdf4tcl side) is complete.
- E-Rechnung mandate / ZUGFeRD version specifics change over time -- re-check the
  current KoSIT scenario package and ZUGFeRD/Factur-X version before a production
  rollout.
