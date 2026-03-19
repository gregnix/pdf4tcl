# pdf4tcl AES-256: Dependencies for SHA-384/512

## Background

AES-256 encryption (V=5/R=6, PDF 2.0) requires SHA-384 and SHA-512 for
Algorithm 2.B (ISO 32000-2 §7.6.4.3.3). Tcllib provides only SHA-256,
not SHA-384/512. pdf4tcl therefore relies on an external SHA backend.

## Backend Selection

pdf4tcl automatically selects a SHA backend on the first AES-256 call:

1. **tcl-sha** (https://sourceforge.net/projects/tcl-sha/) -- Tcl 8.6 and Tcl 9
2. **openssl** in PATH -- cross-platform fallback

Note: **twapi was removed** as a backend. twapi::sha384 returns 20 bytes
(SHA-1) instead of 48 bytes (SHA-384) -- it does not implement SHA-384/512.

## Platform Support

| Platform | Tcl | SHA available              | AES-256                     |
|----------|-----|----------------------------|-----------------------------|
| Linux    | 8.6 | tcl-sha or openssl         | ok                          |
| Linux    | 9.0 | tcl-sha (built for Tcl 9) or openssl | ok             |
| Windows  | 8.6 | tcl-sha (windows64/sha.dll) or openssl | ok           |
| Windows  | 9.0 | openssl (if installed)     | only with openssl            |
| macOS    | 8.6 | tcl-sha or openssl         | ok                          |
| macOS    | 9.0 | openssl (if installed)     | only with openssl            |

## Installing tcl-sha

### Linux (Tcl 8.6)

Download binary package from
https://sourceforge.net/projects/tcl-sha/files/sha-2.1.1.zip

Install `linux64/sha.so` and `pkgIndex.tcl` into a directory on `auto_path`.

### Linux (Tcl 9)

Build from source with the Tcl-9 patch included in `tools/tclsha-tcl9.patch`.
See `doc/en/tcl-sha-tcl9-linux-build-anleitung.md` for the full build guide.

```bash
cd sha-src-2.1.1
patch -p1 < /path/to/pdf4tcl/tools/tclsha-tcl9.patch
mkdir build9 && cd build9
cmake .. \
    -DTCL_TCLSH=/usr/bin/tclsh9.0 \
    -DTCL_INCLUDE_PATH=/usr/include/tcl9.0 \
    -DTCL_LIBRARY=/usr/lib/x86_64-linux-gnu/libtcl9.0.so \
    -DTCL_STUB_LIBRARY=/usr/lib/x86_64-linux-gnu/libtclstub9.0.a
make
```

### Windows (Tcl 8.6)

Use the pre-built `windows64/sha.dll` from
https://sourceforge.net/projects/tcl-sha/files/sha-2.1.1.zip

Copy `windows64/sha.dll` and `pkgIndex.tcl` to a directory on `auto_path`.

### Windows (Tcl 9)

Not yet available as a pre-built binary. Options:

- Build from source using Visual Studio Build Tools + cmake
  (see `doc/en/tcl-sha-tcl9-windows-build-anleitung.md`)
- Use openssl instead (see below)

## Installing openssl

### Linux / macOS

Usually pre-installed. Verify with:

```bash
openssl dgst -sha384 /dev/null
```

### Windows

Download from https://slproweb.com/products/Win32OpenSSL.html
(Win64 OpenSSL Light is sufficient). Add `openssl.exe` to PATH.

Verify:
```cmd
openssl dgst -sha384 NUL
```

## Error Message

If no backend is available:

```
pdf4tcl AES-256: SHA-384/512 not available (Tcl 9.0.3, Windows NT).
Please install one of the following:
  - tcl-sha (https://sourceforge.net/projects/tcl-sha/)
  - openssl in PATH (Windows: https://slproweb.com/products/Win32OpenSSL.html)
```

## AES-128 Not Affected

AES-128 (V=4/R=4) requires only MD5 and SHA-256, both included in
Tcllib. No external dependencies.

## Fallback to AES-128

If AES-256 is not available on your platform:

```tcl
set p [pdf4tcl::new %AUTO% -paper a4 \
    -userpassword "secret" \
    -encversion 4]
```

## Status

AES-256 (V=5/R=6) is functional and tested with qpdf and Adobe Reader
under Tcl 8.6 and Tcl 9. However, it should be considered **experimental**:

- Performance: Tcllib AES (pure Tcl) is ~200x slower than native C AES.
  Expect ~20-25 seconds per PDF on typical hardware.
- Edge cases with unusual PDF viewers or unusual password encodings
  may not be fully covered.
- For production use, AES-128 (-encversion 4) is the more mature option.
