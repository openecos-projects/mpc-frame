# Design Selection, Clock, and Reset Control

[中文说明](design-control.md)

This document defines the synthesizable stage 3 control contract for `FrameTop`.

## External contract

- `reset` is active high and must be asserted and released synchronously to `clock`.
- Each reset assertion starts a new design selection cycle.
- `reset` must remain asserted for at least 20 rising clock edges.
- `user_io[6:0]` must remain stable for at least two rising clock edges before reset is released.
- Changes to `user_io[6:0]` after reset release do not affect the running design.

## Selection sequence

While reset is asserted, the two-stage synchronizer continuously samples
`user_io[6:0]`. All design clocks are disabled, every design reset is asserted,
and payload output enables are forced low.

After external reset is released:

1. The synchronized design ID is decoded to a one-hot selection.
2. The selected clock gate is enabled only while the source clock is low.
3. The selected design receives at least two complete clock edges while its
   internal reset remains asserted.
4. `selection_valid` becomes active, the selected reset is released, and its IO
   output enables may reach the payload pads.

Unselected designs keep their clocks disabled and resets asserted. Reasserting
external reset returns all payload pads to high impedance and permits a new
design ID to be sampled.

## Clock gate mapping

`rtl/FrameClockGate.sv` is the technology-independent behavior used by lint and
simulation. It latches the enable only during the source clock low phase, so an
enable transition cannot create a shortened high pulse. The latch must be
mapped to a target-process integrated clock-gating cell during stage 10.

## Verification

Run the dedicated control regression with:

```sh
make control-test
```

The regression covers designs 0, 1, and 127, runtime selector isolation,
reselection after reset, one-hot selection, reset containment, IO isolation,
unselected clock shutdown, and gated-clock pulse width.
