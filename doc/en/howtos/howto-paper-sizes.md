# How-to: Paper sizes and units

## Runnable script

```bash
tclsh 0.9.4.x/doc/en/howtos/howto-paper-sizes.tcl
# PDF -> 0.9.4.x/doc/en/out/
```

Companion: [`howto-paper-sizes.tcl`](howto-paper-sizes.tcl).

Demo: `0.9.4.x/demo/demo-paper-sizes.tcl`

## Problem

Pick A/B/C series paper or set a custom size and work in millimetres.

## Recipe

```tcl
# Named papers (ISO B/C since 0.9.4.25)
set pdf [::pdf4tcl::new %AUTO% -paper a4 -orient 1]
# also: a3, a5, letter, legal, b5, c4, 4a0, ...

# Custom size in points, or with -unit
set pdf2 [::pdf4tcl::new %AUTO% -paper {210m 297m} -unit m -orient 1]
lassign [$pdf2 getPageSize] w h
```

`-unit` (e.g. `p`, `m`, `c`, `i`) is fixed at creation. Margins accept the
same unit style as other length options.

Landscape: `-landscape 1` (or rotate via page options -- see basics guide).
