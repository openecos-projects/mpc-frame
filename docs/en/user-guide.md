# User Design Integration Guide

[中文说明](../cn/user-guide.md)

This guide is for a contributor developing one design. Give the design a name,
write its RTL and tests, and submit it. Do not choose a design ID or edit
`designs/registry.json`; a maintainer assigns the permanent ID during merge.

If you do not have the distribution yet, start with
[Getting and Using the User Kit](user-kit.md).

Complete examples:

- [Three inverters](examples/three-inverter.md) for combinational logic and
  bidirectional IO;
- [32-bit counter](examples/counter-32bit.md) for sequential logic, clocking,
  and synchronous reset.

## 1. Check the tools

Python 3, GNU Make, a C++ compiler, and Verilator 5.050 are required.

```sh
make doctor
```

## 2. Create a design

Choose a descriptive name:

```sh
make create NAME=counter32
```

This creates:

```text
designs/counter32/
├── README.md
├── README.en.md
├── design.json
├── rtl/Counter32.sv
└── tests/
    ├── Counter32Tb.sv
    └── FrameCounter32Tb.sv
```

The top module name is derived from the design name. Override it with
`TOP_NAME` only when needed:

```sh
make create NAME=counter32 TOP_NAME=MyCounter
```

Creation never overwrites an existing directory. Names may contain lowercase
letters, digits, dots, underscores, and hyphens.

## 3. Implement the circuit

Replace the template logic in `rtl/Counter32.sv`. Keep the five fixed FrameTop
interface ports:

```systemverilog
input  logic        clock;
input  logic        reset;
input  logic [65:0] io_in;
output logic [65:0] io_out;
output logic [65:0] io_oe;
```

`io_in[n]` reads a pin, `io_out[n]` supplies an output value, and
`io_oe[n] = 1` drives that pin. Give all output and enable bits known values.

## 4. Update the tests

The generated TB files mark setup code and design-specific checks:

- `tests/Counter32Tb.sv` tests the circuit directly;
- `tests/FrameCounter32Tb.sv` tests the full path through `user_io` and FrameTop.

The build injects Frame TB's `DESIGN_ID` through `FRAME_TEST_DESIGN_ID`. Never
replace it with a fixed number.

## 5. Run user checks

With one unregistered design in the repository, no path is needed:

```sh
make user-lint
make user-test
make user-frame-test
make check
```

`user-frame-test` selects a free temporary ID and generates an isolated registry
under `build/`. If several unregistered packages exist, select one explicitly:

```sh
make check DESIGN=designs/counter32
```

The maintainer-oriented commands remain available, such as
`make design-test DESIGN=designs/counter32 TEST=io`.

## 6. IO mapping

The low seven FrameTop pins select a hardware slot. The remaining 66 pins map
to the user design:

```text
design io_*[n] <-> external user_io[n + 7]
```

The testbench must drive only pins released by the design. A generated
contention monitor fails the Frame simulation whenever the external and design
output enables overlap, even if both sides drive the same value. Keep the
template infrastructure names `reset`, `test_io_oe`, and `dut`; the monitor
uses them for its standard connections.

## 7. Inspect a waveform

```sh
make trace
make wave
```

`trace` generates the FST and `wave` locates and opens it in GTKWave. When using
a non-default Frame test, pass the same `TEST=<name>` to both targets.

The selected temporary or permanent ID is recorded in
`build/designs/counter32/frame/selected-id.txt`. If it contains `1`, expand
`dut/u_design_registry/u_design_1/u_design` in GTKWave.

## 8. Submit the design

```sh
make check
git diff --check
git status --short
```

Contributors submit `designs/<name>/`. Do not modify or submit the root registry,
generated registry RTL, `build/`, or FST files.

During merge, a maintainer assigns the permanent slot, regenerates the registry,
and reruns the Frame test using the final ID.

## Common errors

- `no unregistered user design found`: create a design first.
- `multiple unregistered user designs found`: pass `DESIGN=designs/<name>`.
- Output is `z`: the matching `io_oe` bit is not enabled.
- `payload IO contention`: `test_io_oe` drives a payload bit already enabled by
  the design; use the printed mask to release the matching external driver.
- `$fatal`: a testbench assertion failed; read its accompanying message.
