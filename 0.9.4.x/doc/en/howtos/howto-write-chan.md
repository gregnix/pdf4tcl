# How-to: Write to a channel (`write -chan`)

Demo: `0.9.4.x/demo/demo-write-chan.tcl`

## Problem

Send PDF bytes to an open channel (socket, pipe, memory channel) instead of
only `-file`.

## Recipe

```tcl
set pdf [::pdf4tcl::new %AUTO% -paper a4 -orient 1]
$pdf startPage
$pdf setFont 12 Helvetica
$pdf text "streamed" -x 50 -y 50
$pdf endPage

set ch [open out.pdf wb]
$pdf write -chan $ch
close $ch
$pdf destroy
```

The channel must already be open for writing; pdf4tcl does **not** close it.

Also available: `write -file path`, and `get` for the PDF as a Tcl byte
string (see the demo for comparisons).
