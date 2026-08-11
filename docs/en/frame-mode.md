# Frame Mode Overview

[中文说明](../cn/frame-mode.md)

Frame mode lets independent RTL designs share one chip top and one physical IO
bank. It is a hardware structure implemented by `FrameTop`, covering design
selection, clock and reset isolation, and bidirectional IO multiplexing.

<FrameArchitecture />

## Three boundaries

| Boundary | Purpose | User editable |
| --- | --- | --- |
| `FrameTop` | Chip top that selects a design and connects physical IO | No |
| `UserDesign*` | Uniform wrapper interface for user RTL | Module body only |
| `designs/<name>/` | Sources, manifest, and tests for one design | Yes |

Every design receives `clock`, `reset`, `io_in[65:0]`, `io_out[65:0]`, and
`io_oe[65:0]`. Setting `io_oe[n]` to one drives payload pad `n`; clearing it
releases the pad so it can be read as an input.

## IO groups

```text
user_io[6:0]   -> 7-bit design ID for 128 possible slots
user_io[72:7]  -> 66-bit payload for the selected design

design io_*[n] <-> external user_io[n + 7]
```

The ID pins select a slot and are not part of the user payload. See
[IO Mapping](io-map.md) for the complete mapping.

## Selection sequence

<SelectionTimeline />

Hold reset active, place the design ID on `user_io[6:0]`, wait for selection to
settle, and then release reset. Changing the pins while running does not switch
designs immediately. Enter reset again to select a different slot. See
[Design Selection, Clock, and Reset Control](design-control.md).

## Isolation

Only the selected design receives a running clock, released reset, and access
to the payload IO mux. Every other slot remains clock-gated, held in reset, and
high impedance. An ID absent from the registry leaves all user slots isolated.
Design 0 is the fixed reference SoC; slots 1 through 127 are user designs.

## IDs during user development

A design ID identifies a final chip slot, not a user's package. A user normally
has one unregistered package and only needs:

```sh
make check
```

The FrameTop test creates a temporary registry below `build/` and assigns a test
slot automatically. A maintainer assigns the permanent ID during integration.
See [Getting and Using the User Kit](user-kit.md) and the
[user design guide](user-guide.md).

## Finding a design in waveforms

After generating an FST with `TRACE=1`, inspect `selection_valid`, the relevant
bit of `design_selected`, and `payload_in/payload_out/payload_oe`. Then descend
into `u_design_registry.u_design_<id>` for the wrapper's IO and internal state.

A bidirectional pad reads back the resolved line value, so `io_in` can contain
both external inputs and values currently driven by the selected design. This is
normal. See [Simulation and Regression](simulation-regression.md) for waveform
commands and contention checks.
