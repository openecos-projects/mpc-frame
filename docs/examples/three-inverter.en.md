# Three-Inverter User Design Integration Example

[中文说明](three-inverter.md)

This example walks through creating a user design, writing RTL, adding unit and
Frame tests, registering the design, and reading its waveform. The circuit has
three one-bit inverters:

```text
io_in[3] -> inverter -> io_out[0]
io_in[4] -> inverter -> io_out[1]
io_in[5] -> inverter -> io_out[2]
```

The internal and external pin mapping is:

| Purpose | User design | FrameTop pin |
| --- | --- | --- |
| Three inputs | `io_in[5:3]` | `user_io[12:10]` |
| Three outputs | `io_out[2:0]` | `user_io[9:7]` |
| Design ID | Not visible to the user design | `user_io[6:0]` |

The package name is `three-inverter`. Contributors do not choose a design ID;
the Frame test assigns a temporary ID and a maintainer assigns the final ID.

## 1. Create the design

Run from the repository root:

```sh
make create-design DESIGN_NAME=three-inverter
```

The command creates:

```text
designs/three-inverter/
├── README.md
├── README.en.md
├── design.json
├── rtl/ThreeInverter.sv
└── tests/
    ├── ThreeInverterTb.sv
    └── FrameThreeInverterTb.sv
```

`ThreeInverterTb.sv` tests the inverters directly. `FrameThreeInverterTb.sv` tests
the complete path through `user_io` and FrameTop.

## 2. Implement the inverters

Replace `designs/three-inverter/rtl/ThreeInverter.sv` with:

```systemverilog
module ThreeInverter #(
  parameter int IO_WIDTH = 66
) (
  input  logic                clock,
  input  logic                reset,
  input  logic [IO_WIDTH-1:0] io_in,
  output logic [IO_WIDTH-1:0] io_out,
  output logic [IO_WIDTH-1:0] io_oe
);

  always_comb begin
    // Release every IO and give every output a known value by default.
    io_out = '0;
    io_oe  = '0;

    // Three bitwise inversions.
    io_out[2:0] = ~io_in[5:3];

    // Only io_out[2:0] drives pins. The io_in[5:3] pins remain released.
    io_oe[2:0] = 3'b111;
  end

endmodule
```

The combinational circuit does not use `clock` or `reset`, but these fixed
interface ports must remain. `io_oe` is output enable, not input enable: 1 means
the design drives a pin; 0 means the design releases it for an external input.

## 3. Write the unit test

Open `designs/three-inverter/tests/ThreeInverterTb.sv`. Keep the module declaration, signals,
and `UserDesignDut` instance, and replace its `initial begin ... end` block with:

```systemverilog
initial begin
  reset = 1'b0;
  io_in = '0;
  #1ns;

  if (io_oe[2:0] !== 3'b111)
    $fatal(1, "output enable incorrect: actual=%03b expected=111", io_oe[2:0]);

  if (io_oe[IO_WIDTH-1:3] !== '0)
    $fatal(1, "unused IO pins are unexpectedly enabled");

  // Check all 2^3=8 input combinations.
  for (int pattern = 0; pattern < 8; pattern++) begin
    io_in = '0;
    io_in[5:3] = pattern[2:0];
    #1ns;

    if (io_out[2:0] !== ~io_in[5:3])
      $fatal(
        1,
        "NOT result incorrect: input=%03b output=%03b expected=%03b",
        io_in[5:3], io_out[2:0], ~io_in[5:3]
      );

    if (io_out[IO_WIDTH-1:3] !== '0)
      $fatal(1, "unused output bits are not zero");
  end

  $display("THREE INVERTER UNIT TEST PASS");
  $finish;
end
```

Run lint first. This step is required because it detects real combinational
loops and other structural problems in user RTL:

```sh
make user-lint
```

After lint passes, run the unit test:

```sh
make user-test
```

A successful run prints:

```text
THREE INVERTER UNIT TEST PASS
```

## 4. Connect temporarily to FrameTop

Do not edit the root registry. The Frame test chooses a free temporary ID and
generates an isolated registry under `build/designs/three-inverter/frame/`.

## 5. Write the Frame integration test

Open `designs/three-inverter/tests/FrameThreeInverterTb.sv`. Keep the module declaration,
clock, tri-state pin connections, and `FrameTop dut` instance. Replace its
`initial begin ... end` block with:

```systemverilog
initial begin
  // The build injects DESIGN_ID; select it while reset is asserted.
  test_io_oe[DESIGN_ID_WIDTH-1:0] = '1;
  test_io_out[DESIGN_ID_WIDTH-1:0] = DESIGN_ID;

  repeat (20) @(posedge clock);
  @(negedge clock);
  reset = 1'b0;
  repeat (4) @(posedge clock);
  #1ns;

  if (!dut.selection_valid || !dut.design_selected[DESIGN_ID])
    $fatal(1, "three-inverter was not selected through FrameTop");

  // Drive user_io[12:10], which maps to the design's io_in[5:3].
  test_io_oe[DESIGN_ID_WIDTH + 5 : DESIGN_ID_WIDTH + 3] = 3'b111;

  // Release user_io[9:7] so the design can drive io_out[2:0].
  test_io_oe[DESIGN_ID_WIDTH + 2 : DESIGN_ID_WIDTH] = 3'b000;

  for (int pattern = 0; pattern < 8; pattern++) begin
    test_io_out[
      DESIGN_ID_WIDTH + 5 : DESIGN_ID_WIDTH + 3
    ] = pattern[2:0];
    #1ns;

    if (
      user_io[DESIGN_ID_WIDTH + 2 : DESIGN_ID_WIDTH]
      !== ~pattern[2:0]
    ) begin
      $fatal(
        1,
        "Frame NOT result incorrect: input=%03b output=%03b expected=%03b",
        pattern[2:0],
        user_io[DESIGN_ID_WIDTH + 2 : DESIGN_ID_WIDTH],
        ~pattern[2:0]
      );
    end
  end

  $display("THREE INVERTER FRAME TEST PASS");
  $finish;
end
```

The test drives only the input pins at `user_io[12:10]`. It must not drive the
output pins at `user_io[9:7]`, or the test and design will create contention.

Run in this order:

```sh
make user-lint
make user-frame-test
```

A successful run prints:

```text
THREE INVERTER FRAME TEST PASS
```

The Frame test suppresses a framework-level `UNOPTFLAT` false positive caused
by bidirectional IO. Standalone lint is still required to find real feedback
loops inside user RTL.

## 6. Generate and inspect a waveform

```sh
make user-frame-test TRACE=1
gtkwave build/waves/three-inverter/frame.fst
```

Read `build/designs/three-inverter/frame/selected-id.txt` first. If it contains
`1`, expand:

Expand this hierarchy in GTKWave's SST pane:

```text
FrameThreeInverterTb
└── dut
    └── u_design_registry
        └── u_design_1
            └── u_design
```

Inspect:

- `test_io_out`, `test_io_oe`, and `user_io` in the TB;
- `design_id`, `selection_valid`, and `payload_*` in FrameTop;
- `io_in`, `io_out`, and `io_oe` in the user design.

For an input of `3'b101`, expect:

```text
io_in[5:3]  = 101
io_out[2:0] = 010
io_oe[2:0]  = 111
```

Because `io_in` reads every physical pin, it also reads back the output pins:

```text
io_in[5:0] = 101_010 = 6'h2a
```

This is not a wiring error. `io_in[2:0]` is the physical readback of
`io_out[2:0]`.

## 7. Checks before submission

```sh
make user-check
make docs-check
git diff --check
git status --short
```

Contributors commit only `designs/three-inverter/`. Do not edit the permanent
registry or commit `build/` and FST waves.

## Common errors

- Only `io_out[0]` works: `io_oe[0] = 1'b111` was used instead of
  `io_oe[2:0] = 3'b111`.
- Output is `z`: the matching `io_oe` bit is not 1, or design 1 is not registered
  and selected.
- Output is `x`: the test drives an output pin and conflicts with the design.
- No user design is found: check `designs/three-inverter/design.json`; when
  several unregistered designs exist, pass `DESIGN=designs/three-inverter`.
- `io_in` contains output data in the waveform: this is normal output readback
  on bidirectional IO.
