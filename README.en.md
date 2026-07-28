# mpc-frame

[中文说明](README.md)

`mpc-frame` is a chip-frame project for integrating multiple user designs. It
also contains a standalone reference SoC as design 0.

Rendered documentation: [mpc-frame GitHub Pages](https://openecos-projects.github.io/mpc-frame/).

`FrameTop` is the chip top. Design 0 is fixed. User designs use IDs 1 through
127 and are listed in `designs/registry.json`. Every user design connects
through the same five signals: `clock`, `reset`, `io_in`, `io_out`, and `io_oe`.

## Main files

- `FrameTop.sv`: chip top used for both simulation and synthesis.
- `designs/registry.json`: list of user designs connected to FrameTop.
- `designs/template/`: source files used by `make create-design`.
- `designs/<name>/`: a user's design directory; internal test designs are not
  stored here.
- `rtl/generated/FrameDesignRegistry.sv`: generated connection code; do not
  edit it manually.
- `docs/user-guide.en.md`: step-by-step user workflow.
- `docs/io-map.md`: external pin mapping.
- `reference/sim/`: reference SoC sources and tests.

## IO layout

`FrameTop` has 73 bidirectional `user_io` pins. `user_io[6:0]` selects a design
during reset. `user_io[72:7]` carries the 66 user-design IO bits. Therefore:

```text
design io_*[n] <-> FrameTop user_io[n + 7]
```

Only design 0 and designs listed in `designs/registry.json` can run. An
unregistered design stays in reset with its clock stopped and its pins released.

## Start a user design

```sh
make create-design DESIGN_NAME=counter32
```

Then follow the [English user guide](docs/user-guide.en.md). The corresponding
[Chinese guide](docs/user-guide.md) is the primary version.

Common checks are:

```sh
make user-lint
make user-test
make user-frame-test
make user-check
```

Users do not choose a design ID or edit the root registry. `user-frame-test`
assigns a temporary slot under `build/`. During merge, a maintainer runs
`make integrate-design DESIGN=designs/<name> DESIGN_ID=<id>` to assign the
permanent hardware slot and regenerate the registry.

Verilator 5.050 is recommended, and 5.032 is also tested. Versions older than
5.032 are not tested. The Makefile probes nonessential warning options and skips
unsupported ones, including `-Wno-PROCASSINIT` on Verilator 5.032.

## Regression

`make regression-fast` runs root lint, manifest tests, frame control tests, IO
contention tests, and every registered user design's lint, unit tests, and Frame
tests. `make regression` also runs the complete reference SoC tests.

Set `TRACE=1` to create FST waveforms under `build/waves/` for Frame tests.

## Local documentation site

Install the dependencies once and start the local site:

```sh
make docs-site-install
make docs-site-dev
```

Open `http://localhost:5173/mpc-frame/`. Before submitting documentation, run
`make docs-site-check` to validate bilingual pairs, internal links, and the
static build.
