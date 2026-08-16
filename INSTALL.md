# INSTALL -- building, testing and packaging pdf4tcl

This is the working tree of the gregnix fork. If you only want to *use*
pdf4tcl, take the release tarball (see [Releases](#make-release)) or copy
the files listed under [What a user needs](#what-a-user-needs) -- nothing
here is required at run time.

Requirements: Tcl 8.6 or 9.x with TclOO. Tk only for the canvas features
and a few demos. `make check` additionally needs
[nagelfar](https://wiki.tcl-lang.org/page/Nagelfar), `make checkdoc` needs
eskil; both are optional.

---

## The tree

| | |
|---|---|
| `src/` | the sources -- **this is what you edit** |
| `pdf4tcl.tcl` | assembled from `src/` by `make`; never edit it |
| `pkg/` | the package layout, a **symlink directory** -- see below |
| `tests/` | tcltest suite, `tests/all.tcl` is the runner |
| `examples/` | the upstream example scripts, run by `make example` |
| `demo/` | the fork's demos, run by `demo/run-all-demos.tcl` |
| `doc/en/` | howtos and tutorials, each one runnable |
| `tools/` | version bump, the pkg symlinks, checks, metric extraction |
| `afm/`, `bitmaps/` | font metrics and Tk bitmaps, used at run time |

`pdf4tcl.tcl`, `pdf4tcl.html` and `pdf4tcl.n` are generated **and**
committed -- the upstream project ships them, and this fork keeps that.
`make checkbuild` fails if they are older than `src/`.

---

## pkg/ is a symlink directory

`pkg/` holds exactly what goes into a release: the assembled library, the
package index, the metrics, the manual, the bitmaps and the licence. It is
not a second copy of them -- every entry is a symlink into the root:

```
pkg/pdf4tcl.tcl    -> ../pdf4tcl.tcl
pkg/pdf4tcl.html   -> ../pdf4tcl.html
pkg/pdf4tcl.man    -> ../pdf4tcl.man
pkg/pkgIndex.tcl   -> ../pkgIndex.tcl
pkg/stdmetrics.tcl -> ../stdmetrics.tcl
pkg/glyph2uni.tcl  -> ../glyph2uni.tcl
pkg/licence.terms  -> ../licence.terms
```

**Why it matters.** `make release` tars `pkg/` with `-h`, so the symlinks
are resolved and the archive holds real files. As long as they are links,
the release cannot ship a stale file. When they were plain copies, exactly
that happened: `pkg/pdf4tcl.man` sat two days behind `pdf4tcl.man` and a
release would have shipped the previous version's manual with the current
code. `make checkbuild` would not have noticed -- it only compares
`pdf4tcl.tcl`.

### Restoring the links

```bash
tclsh tools/restore-pkg-symlinks.tcl            # do it
tclsh tools/restore-pkg-symlinks.tcl --dry-run  # show first
```

Run it once after cloning, and again after `make distclean` -- that target
deletes `pkg/pdf4tcl.tcl` along with the file it points at, and the next
`make` recreates it as a plain file.

`make` writes *through* the symlink (`cp pdf4tcl.tcl pkg/pdf4tcl.tcl` ends
up copying the file onto itself), so an ordinary build leaves the links
intact.

> On Windows, symlinks need developer mode or an elevated shell. Without
> them, `pkg/` falls back to being copies, and the staleness above can
> return -- check `pkg/pdf4tcl.man` before a release.

---

## make targets

Measured on this tree, Tcl 9.0.4.

### `make`

Assembles `pdf4tcl.tcl` from `src/` (the file list lives in `CATFILES`, in
the Makefile, and nowhere else), copies it to `pkg/`, and regenerates
`pdf4tcl.html` and `pdf4tcl.n` from `pdf4tcl.man`.

```bash
make
make checkbuild     # fails if the generated files are older than src/
```

Run `checkbuild` after every change. It is the only thing that catches a
`pdf4tcl.tcl` built from an incomplete file list.

> **Timestamps from an archive can lie.** Files unpacked from a zip may
> carry a date in the future, and `make` then considers `pdf4tcl.tcl`
> current. If a change does not seem to arrive:
> ```bash
> rm -f pdf4tcl.tcl pkg/pdf4tcl.tcl && touch src/*.tcl && make
> ```

### `make example`

Runs the upstream example scripts in `examples/` and writes their PDFs
beside them. They are reference output: after a change to the PDF
structure, regenerate them and look at the diff.

The version number is part of every file (`/Creator`), so a version bump
changes all of them.

### `make test`

Runs `tests/all.tcl` -- **with `tclsh8.6`**, because the Makefile sets
`TCLSH ?= tclsh8.6`. Measured on this tree:

```
tclsh8.6   Total 1035  Passed 1005  Skipped 30  Failed 0
tclsh9.0   Total 1035  Passed 1007  Skipped 28  Failed 0
```

Two tests skip under 8.6 and run under 9.0. To run the suite under another
interpreter:

```bash
make test TCLSH=tclsh9.0
tclsh9.0 tests/all.tcl        # the same, directly
```

Both generations matter: `encoding convertto` substitutes silently under
8.6 and throws under 9.0, and `getSubstCount` only counts under 9. A change
tested on one generation is tested by half.

The skips are constraints, not failures: root-only file permission tests,
Tk tests without a display, slow AES-256 cases, missing optional fonts.
On a headless machine, start a display first if you want the Tk tests to
run rather than skip:

```bash
Xvfb :99 -screen 0 1280x1024x24 & export DISPLAY=:99
```

Single file:

```bash
tclsh tests/all.tcl -file form.test
```

### `make clean` / `make distclean`

`clean` removes what the other targets produce: coverage artefacts, the
nagelfar syntax databases, the output directories of the demos, docs and
tests, and `release/`. It leaves `pdf4tcl.tcl` alone, because that one is
committed.

**It does not touch `examples/*.pdf`.** Those are reference output, they
are in the repository, and `tests/examples.test` diffs freshly generated
PDFs against them. A first version of this target removed them, and
`make clean && make test` then reported 8 failures, reproducibly. Regenerate
them with `make example` when the PDF structure changes -- not by deleting
them.

`distclean` additionally removes `pdf4tcl.tcl`, `pkg/pdf4tcl.tcl`,
`pdf4tcl.html` and `pdf4tcl.n`. After it you need `make` before anything
runs -- and `tools/restore-pkg-symlinks.tcl` to get `pkg/` back to links.

### `make release`

Builds `release/pdf4tclXXXXX.tar.gz` (and `make zip` the matching `.zip`)
by symlinking `pdf4tclXXXXX -> pkg` and taring it with `-h`. 19 files, no
sources, no tests.

```bash
make release
make zip
tar tzf release/pdf4tcl09444.tar.gz
```

**GitHub does not use `release/`.** A tag or release on GitHub gets the
archives GitHub builds itself from the *tracked* files -- the whole working
tree, 374 files. `release/` is in `.gitignore` and is not part of any tag.
To ship the package archive, attach it to the release explicitly:

```bash
gh release create v0.9.4.44 \
    release/pdf4tcl09444.tar.gz release/pdf4tcl09444.zip \
    --title "pdf4tcl 0.9.4.44"
```

### The other targets

| | |
|---|---|
| `make check` | nagelfar over `pdf4tcl.tcl`; it should print nothing at all |
| `make check90` | the same against the Tcl 9 syntax database |
| `make checkdoc` | compares the methods in the manual against the source (needs eskil) |
| `make instrument` / `make icheck` | code coverage |
| `make bump TO=0.9.4.X MSG="..."` | version bump, see below and `bumprev.txt` |
| `make verify` | version consistency across six files, no changes |

---

## Versions

The version lives in `src/prologue.tcl` and is copied into eight other
places by `tools/bump.tcl` -- `pkgIndex.tcl`, `pkg/pkgIndex.tcl`,
`tests/init.tcl`, `README.md`, the Makefile (`VERSION`, without dots) and
`pdf4tcl.man` (twice). `make verify` checks all of them and changes
nothing.

```bash
tclsh tools/bump.tcl --to 0.9.4.45 --msg "short description"
tclsh tools/bump.tcl --show          # what it would do
tclsh tools/bump.tcl --verify        # consistency only
```

### tools/next.tcl

Two lines, and the reason `tools/bump.tcl` can be called without
arguments:

```tcl
set NEXT_VERSION 0.9.4.45
set NEXT_MSG ""
```

It names the **next** version to be handed out -- not the one currently in
the tree. `bump.tcl` reads it, and after a successful bump writes it
forward to the following number with an empty message, so the description
has to be given deliberately next time rather than repeating the last one.

Two things this protects against, both of which happened:

* Without the forward write, the file kept the version just released, and
  a call without `--to` reported `Bump: 0.9.4.44 --> 0.9.4.43` -- backwards,
  with the message of the version before last.
* `bump.tcl` now refuses a target that is not higher than the current
  version, so that case ends with an error instead of a downgraded tree.

**The file belongs in the repository.** It used to be in `.gitignore`,
while `bump.tcl` reads it -- in a fresh clone the tool died with
`couldn't read file "tools/next.tcl"` before doing anything.

---

## What a user needs

Nothing in this tree except the package layout:

```tcl
package require pdf4tcl
```

with `pkg/` (or the unpacked release) on `auto_path`. `pdf4tcl.tcl`,
`pkgIndex.tcl`, `stdmetrics.tcl` and `glyph2uni.tcl` are the whole library;
`bitmaps/` is needed only for the Tk bitmap features, `afm/` only if you
use the AFM metrics of the 14 standard fonts.

---

## Notes on this fork

`web/`, `contrib/` and `exp.tcl` were removed in 0.9.4.44:

* `web/` was the upstream project page, uploaded by `make webt` via rsync
  to `pspjuth@web.sourceforge.net` -- an account this fork cannot publish
  to. `mkweb.tcl` went with it, and `all`/`doc` no longer depend on it.
* `contrib/` held a third-party table helper referenced by nothing in the
  Makefile, the tests or the demos.
* `exp.tcl` was a scratch file using snit, which the project dropped in
  0.9.

