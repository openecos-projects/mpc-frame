# User Design Integration Guide

[中文说明](user-guide.md)

This guide is for a contributor developing one design. Give the design a name,
write its RTL and tests, and submit it. Do not choose a design ID or edit
`designs/registry.json`; a maintainer assigns the permanent ID during merge.

Complete examples:

- [Three inverters](examples/three-inverter.en.md) for combinational logic and
  bidirectional IO;
- [32-bit counter](examples/counter-32bit.en.md) for sequential logic, clocking,
  and synchronous reset.

## 1. Check the tools

Python 3, GNU Make, a C++ compiler, and Verilator are required. Verilator 5.050
is recommended, and 5.032 is tested. Older versions are not tested.

```sh
make verilator-version
```

## 2. Create a design

Choose a descriptive name:

```sh
make create-design DESIGN_NAME=counter32
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

The module name is derived from the design name. Override it only when needed:

```sh
make create-design DESIGN_NAME=counter32 DESIGN_MODULE=MyCounter
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
make user-check
```

`user-frame-test` selects a free temporary ID and generates an isolated registry
under `build/`. If several unregistered packages exist, select one explicitly:

```sh
make user-check DESIGN=designs/counter32
```

The maintainer-oriented commands remain available, such as
`make design-test DESIGN=designs/counter32 TEST=io`.

## 6. IO mapping

The low seven FrameTop pins select a hardware slot. The remaining 66 pins map
to the user design:

```text
design io_*[n] <-> external user_io[n + 7]
```

The testbench must drive only pins released by the design. Driving a pin from
both sides produces `x` values.

## 7. Inspect a waveform

```sh
make user-frame-test TRACE=1
gtkwave build/waves/counter32/frame.fst
```

The selected temporary or permanent ID is recorded in
`build/designs/counter32/frame/selected-id.txt`. If it contains `1`, expand
`dut/u_design_registry/u_design_1/u_design` in GTKWave.

## 8. Submit the design

```sh
make user-check
make docs-check
git diff --check
git status --short
```

Contributors submit `designs/<name>/`. Do not modify or submit the root registry,
generated registry RTL, `build/`, or FST files.

During merge, a maintainer runs:

```sh
make integrate-design DESIGN=designs/counter32 DESIGN_ID=12
```

This assigns the permanent slot, updates and regenerates the registry, and runs
the Frame test again using the final ID.

## Common errors

- `no unregistered user design found`: create a design first.
- `multiple unregistered user designs found`: pass `DESIGN=designs/<name>`.
- Output is `z`: the matching `io_oe` bit is not enabled.
- Output is `x`: the signal is unknown or both sides drive the same pin.
- `$fatal`: a testbench assertion failed; read its accompanying message.
