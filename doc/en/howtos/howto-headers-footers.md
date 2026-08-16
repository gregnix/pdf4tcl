# How-to: Headers and footers on every page

## Runnable script

```bash
tclsh doc/en/howtos/howto-headers-footers.tcl
# PDF -> doc/en/out/
```

Companion: [`howto-headers-footers.tcl`](howto-headers-footers.tcl).

## Problem

Repeat a title line and a page number without duplicating layout logic.

## Recipe

Call small helpers after every `startPage`. With `-orient 1`, keep the header
near **small y** and the footer near **bottom of the drawable area**.

```tcl
set pdf [::pdf4tcl::new %AUTO% -paper a4 -orient 1 -margin 50]
set pageNo 0

proc pageChrome {pdf title} {
    upvar 1 pageNo pageNo
    incr pageNo
    lassign [$pdf getDrawableArea] W H

    $pdf setFont 9 Helvetica
    $pdf setFillColor 0.4 0.4 0.4
    $pdf text $title -x 0 -y 10
    $pdf setStrokeColor 0.75 0.75 0.75
    $pdf setLineWidth 0.4
    $pdf line 0 14 $W 14

    $pdf text "Page $pageNo" -x [expr {$W - 40}] -y [expr {$H - 8}]
    $pdf setFillColor 0 0 0
}

$pdf startPage
pageChrome $pdf "My document"
$pdf setFont 12 Helvetica
$pdf text "Body starts below the header." -x 0 -y 40
$pdf endPage
```

## Tagged documents

Running heads and page numbers are **not** part of the reading order. Mark
them as artifacts:

```tcl
$pdf tagArtifact -type Pagination -subtype Header
# ... draw header ...
$pdf tagArtifactEnd

$pdf tagArtifact -type Pagination -subtype Footer
# ... draw footer ...
$pdf tagArtifactEnd
```

See `../tutorials/tutorial-03-accessible-pdf.md` and `../reference/TAGGED.md`.

## Limits

pdf4tcl does not flow text around chrome or reserve space automatically. Leave
a vertical margin under the header and above the footer yourself, or use a
layout library (pdf4tcllib) that tracks a content cursor.
