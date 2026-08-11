# 32-Bit Counter User Design Integration Example

[中文说明](../../cn/examples/counter-32bit.md)

This example uses a 32-bit counter to demonstrate sequential logic in
FrameTop. The counter increments on every clock and directly drives 32 user IO
pins:

```text
clock rising edge -> counter + 1 -> io_out[31:0]
reset = 1         -> counter = 0
```

The internal and external pin mapping is:

| Purpose | User design | FrameTop pin |
| --- | --- | --- |
| 32-bit count | `io_out[31:0]` | `user_io[38:7]` |
| Design ID | Not visible to the user design | `user_io[6:0]` |

This design has no external inputs and drives all 32 count pins. Its package
name is `counter32`. Contributors do not choose a design ID; the Frame test
assigns a temporary ID.

## 1. Create the design

Run from the repository root:

```sh
make create NAME=counter32
```

The command creates:

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

`Counter32Tb.sv` tests the counter directly. `FrameCounter32Tb.sv` checks
that the count reaches the external pins through FrameTop.

## 2. Implement the 32-bit counter

Replace `designs/counter32/rtl/Counter32.sv` with:

```systemverilog
module Counter32 #(
  parameter int IO_WIDTH = 66
) (
  input  logic                clock,
  input  logic                reset,
  input  logic [IO_WIDTH-1:0] io_in,
  output logic [IO_WIDTH-1:0] io_out,
  output logic [IO_WIDTH-1:0] io_oe
);

  logic [31:0] counter;

  // reset is synchronous and active high.
  always_ff @(posedge clock) begin
    if (reset)
      counter <= 32'b0;
    else
      counter <= counter + 32'd1;
  end

  always_comb begin
    io_out = '0;
    io_oe  = '0;

    io_out[31:0] = counter;
    io_oe[31:0]  = 32'hffff_ffff;
  end

endmodule
```

`always_ff` describes flip-flops and updates state only on the specified clock
edge. The nonblocking assignment `<=` gives `counter` register behavior.

This example does not use `io_in`, but the fixed interface port must remain.
Setting `io_oe[31:0]` to all ones makes the design drive those 32 pins while
all remaining IO pins stay released.

## 3. Write the unit test

Open `designs/counter32/tests/Counter32Tb.sv`. Keep the module declaration, clock,
signals, and `UserDesignDut` instance. Replace the original
`initial begin ... end` block with:

```systemverilog
initial begin
  logic [31:0] expected;

  io_in = '0;

  // reset starts at 1. Hold it for two clocks and expect a zero count.
  repeat (2) @(posedge clock);
  #1ns;
  if (io_out[31:0] !== 32'b0)
    $fatal(1, "counter did not reset: actual=%08h", io_out[31:0]);

  if (io_oe[31:0] !== 32'hffff_ffff)
    $fatal(1, "counter outputs are not enabled");

  if (io_oe[IO_WIDTH-1:32] !== '0)
    $fatal(1, "unused IO pins are unexpectedly enabled");

  // Release reset on a falling edge to avoid a race at the sampling edge.
  @(negedge clock);
  reset = 1'b0;
  expected = 32'b0;

  // Check ten consecutive increments.
  repeat (10) begin
    @(posedge clock);
    expected = expected + 32'd1;
    #1ns;
    if (io_out[31:0] !== expected)
      $fatal(
        1,
        "counter incorrect: actual=%08h expected=%08h",
        io_out[31:0], expected
      );
  end

  // Assert reset again and confirm that the counter returns to zero.
  @(negedge clock);
  reset = 1'b1;
  @(posedge clock);
  #1ns;
  if (io_out[31:0] !== 32'b0)
    $fatal(1, "counter did not reset a second time");

  $display("COUNTER32 COUNTER UNIT TEST PASS");
  $finish;
end
```

Run standalone lint before the test:

```sh
make user-lint
make user-test
```

A successful run prints:

```text
COUNTER32 COUNTER UNIT TEST PASS
```

The test waits `#1ns` after each rising edge so nonblocking assignments can
finish updating before the result is read.

## 4. Connect temporarily to FrameTop

Do not edit the permanent registry. `user-frame-test` selects a free temporary
ID for `counter32` and generates an isolated registry under `build/`.

## 5. Write the Frame integration test

Open `designs/counter32/tests/FrameCounter32Tb.sv`. Keep the module declaration,
clock, tri-state connections, and `FrameTop dut` instance. Replace the original
`initial begin ... end` block with:

```systemverilog
initial begin
  logic [31:0] count_snapshot;
  logic [31:0] expected;

  // The build injects DESIGN_ID; select it while reset is asserted.
  test_io_oe[DESIGN_ID_WIDTH-1:0] = '1;
  test_io_out[DESIGN_ID_WIDTH-1:0] = DESIGN_ID;

  repeat (20) @(posedge clock);
  @(negedge clock);
  reset = 1'b0;
  repeat (4) @(posedge clock);
  #1ns;

  if (!dut.selection_valid || !dut.design_selected[DESIGN_ID])
    $fatal(1, "counter32 was not selected through FrameTop");

  // user_io[38:7] maps to io_out[31:0]. The test must release these pins.
  test_io_oe[
    DESIGN_ID_WIDTH + 31 : DESIGN_ID_WIDTH
  ] = 32'b0;

  // FrameTop controls the exact internal-reset release time. Sample the current
  // value and check subsequent increments instead of assuming an absolute value.
  count_snapshot = user_io[
    DESIGN_ID_WIDTH + 31 : DESIGN_ID_WIDTH
  ];
  if ($isunknown(count_snapshot))
    $fatal(1, "Frame counter output contains x or z");

  expected = count_snapshot;

  repeat (10) begin
    @(posedge clock);
    expected = expected + 32'd1;
    #1ns;
    if (
      user_io[DESIGN_ID_WIDTH + 31 : DESIGN_ID_WIDTH]
      !== expected
    ) begin
      $fatal(
        1,
        "Frame counter incorrect: actual=%08h expected=%08h",
        user_io[DESIGN_ID_WIDTH + 31 : DESIGN_ID_WIDTH],
        expected
      );
    end
  end

  $display("COUNTER32 COUNTER FRAME TEST PASS");
  $finish;
end
```

The test must not drive `user_io[38:7]` because the counter already drives
those pins through `io_oe[31:0]`. The generated monitor terminates the
simulation with an IO contention error if both output enables overlap.

Run:

```sh
make user-lint
make user-frame-test
```

A successful run prints:

```text
COUNTER32 COUNTER FRAME TEST PASS
```

## 6. Generate and inspect a waveform

```sh
make trace
make wave
```

Read `build/designs/counter32/frame/selected-id.txt` first. If it contains `1`,
expand:

Expand this hierarchy in GTKWave's SST pane:

```text
FrameCounter32Tb
└── dut
    └── u_design_registry
        └── u_design_1
            └── u_design
```

Inspect:

- `clock` and `reset`;
- `selection_valid` and the `design_selected` bit for the temporary ID;
- `counter`, `io_out[31:0]`, and `io_oe[31:0]` in the user design;
- `user_io[38:7]` in the testbench.

The normal waveform is:

```text
clock rising edge:  1    2    3    4
counter:            1    2    3    4
io_out[31:0]:       1    2    3    4
user_io[38:7]:      1    2    3    4
```

After a rising edge with `reset=1`, `counter` returns to zero. Because reset is
synchronous, changing `reset` without a rising edge does not immediately change
the count.

## 7. Checks before submission

```sh
make check
git diff --check
git status --short
```

Contributors commit only `designs/counter32/`. Do not edit the permanent
registry or commit `build/` and FST waveforms.

## Common errors

- The counter stays at zero: reset is still asserted or FrameTop did not select
  the design.
- The first check is off by one: wait `#1ns` after the rising edge before reading
  a nonblocking-assignment result.
- Output is `z`: `io_oe[31:0]` was not set to all ones.
- `payload IO contention`: the testbench also drives `user_io[38:7]`; clear the
  matching `test_io_oe` bit identified by the mask.
- The counter uses `always_comb`: combinational logic cannot retain the previous
  count; use `always_ff @(posedge clock)`.
- The count does not clear immediately when reset goes high: this example uses
  synchronous reset, so it clears on the next rising edge.
