# User Design Integration Guide

[中文说明](user-guide.md)

This guide starts from an empty design directory and walks through creating a
circuit, testing it, connecting it to FrameTop, and running the final checks.
You do not need to edit `FrameTop.sv` or the root RTL files.

## 0. Check the tools

You need Python 3, GNU Make, a C++ compiler, and Verilator. Verilator 5.050 is
recommended, and 5.032 is also tested. Versions older than 5.032 are not tested.

```sh
make verilator-version
```

The Makefile checks optional Verilator warning flags before using them. If an
older version does not recognize `-Wno-PROCASSINIT`, the flag is skipped rather
than stopping the build.

## 1. Create your directory

Choose an unused ID from 1 through 127. For example, create design 3:

```sh
make create-design DESIGN_ID=3
```

The command creates:

```text
designs/3/
├── README.md                  Chinese guide
├── README.en.md               English guide
├── design.json                Source and test list
├── rtl/
│   └── UserDesign3.sv         Your circuit
└── tests/
    ├── UserDesign3Tb.sv       Tests only your circuit
    └── FrameUserDesign3Tb.sv  Tests the complete FrameTop connection
```

The default top module is `UserDesign3`. To choose custom names at creation:

```sh
make create-design DESIGN_ID=3 DESIGN_NAME=uart-demo DESIGN_MODULE=UartDemo
```

The command never overwrites an existing directory. It also rejects design 0,
out-of-range IDs, and IDs that are already registered.

## 2. Implement the circuit

Open `rtl/UserDesign3.sv` and replace the example logic. Keep the five top-level
ports; they are the fixed connection between FrameTop and your circuit:

```systemverilog
input  logic        clock;
input  logic        reset;
input  logic [65:0] io_in;
output logic [65:0] io_out;
output logic [65:0] io_oe;
```

- `clock` is the clock. A combinational circuit may ignore it, but keep it.
- `reset` is reset. A stateless circuit may ignore it, but keep it.
- `io_in[n]` reads the current level of user IO bit n.
- `io_out[n]` is the value your circuit wants to output.
- `io_oe[n] = 1` drives `io_out[n]`; `io_oe[n] = 0` releases that pin.

Give every `io_out` and `io_oe` bit a known value. A common pattern is:

```systemverilog
always_comb begin
  io_out = '0;
  io_oe  = '0;
  // Implement your logic here.
end
```

## 3. Update and run the unit test

`tests/UserDesign3Tb.sv` connects directly to your circuit. It is the fastest
way to check the circuit behavior. The file marks setup code with
“Usually keep” and functional checks with “Edit for your design.”

After changing the RTL, replace the TB checks for the template heartbeat with
checks for your real design. Run:

```sh
make design-lint DESIGN=designs/3
make design-test DESIGN=designs/3 TEST=io
```

`design-lint` checks syntax and common RTL issues. `design-test` compiles and
runs the TB. The test passes only when the TB prints `PASS` and make exits
normally. `Verilog $finish` means the test ended as planned; it is not an error.

The design is not connected to the official FrameTop yet, which is expected.

## 4. Register the design

After the standalone test passes, open the root `designs/registry.json`. To
register design 3:

```json
{
  "designs": [
    "3/design.json"
  ]
}
```

If other official designs are already present, append an entry without deleting
them. Generate and check the FrameTop connection code:

```sh
make registry-generate
make registry-check
```

`rtl/generated/FrameDesignRegistry.sv` is generated. Do not edit it manually.

## 5. Update and run the Frame test

`tests/FrameUserDesign3Tb.sv` checks the full path:

```text
test -> user_io -> FrameTop -> UserDesign3 -> FrameTop -> user_io
```

`user_io[6:0]` selects the design. The other 66 bits connect to your circuit:

```text
design io_*[n] <-> FrameTop user_io[n + 7]
```

For example, `io_in[0]` maps to `user_io[7]`, and `io_out[5]` maps to
`user_io[12]`.

Replace the functional checks marked “Edit for your design.” The test may drive
input pins only. It must not drive a pin that the design already drives with
`io_oe=1`, because that creates IO contention.

Run:

```sh
make design-frame-test DESIGN=designs/3 TEST=frame
```

Integration passes only when the Frame TB prints `PASS` and make exits normally.

## 6. Checks before submission

```sh
make regression-fast
git diff --check
```

To generate a waveform while debugging a Frame test:

```sh
make frame-test DESIGN=designs/3 TEST=frame TRACE=1
```

The waveform is `build/waves/3/frame.fst`. Do not commit build output or waves.

## Common errors

- `DESIGN is required`: add `DESIGN=designs/3` to the command.
- `design is not listed`: add the design to `designs/registry.json`.
- `generated file is stale`: run `make registry-generate`.
- `Unknown warning ... PROCASSINIT`: an old, incompatible Makefile is in use;
  the updated root Makefile detects and skips this flag.
- Output is `z`: `io_oe` is not 1, or the design was not selected.
- Output is `x`: a signal has no known value, or two sources drive one pin.
- `$fatal`: a TB check failed; the message identifies the failed check.
