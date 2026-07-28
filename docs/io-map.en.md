# IO Mapping

[中文说明](io-map.md)

`FrameTop` exposes 73 bidirectional pads:

```systemverilog
inout wire [72:0] user_io
```

## Fixed partition

| FrameTop pad | Purpose | User design port |
| --- | --- | --- |
| `user_io[6:0]` | 7-bit design ID, sampled only during reset | Not visible |
| `user_io[72:7]` | 66-bit payload for the selected design | `io_in/io_out/io_oe[65:0]` |

The fixed conversion is `io_*[n]` in a user design to
`FrameTop.user_io[n + 7]`. For example, `io_out[0]` drives `user_io[7]`, and
`io_in[65]` reads `user_io[72]`.

## Direction contract

Each payload bit uses three signals:

- `io_in[n]` always reads the resolved pad level;
- with `io_oe[n] = 1`, the design drives the pad from `io_out[n]`;
- with `io_oe[n] = 0`, the design releases the pad for an external driver.

The design must assign known values to every `io_out` and `io_oe` bit. An
external source must not drive an opposing level while `io_oe[n] = 1`, because
that is electrical contention.

## Design selection

The environment drives `user_io[6:0]` while `reset = 1` and keeps it stable for
at least two rising `clock` edges. The ID is locked after reset release; changing
the pads at runtime does not switch designs. Reassert reset to select again.
Design 0 is the fixed reference, and user slots range from 1 through 127.

An unregistered design ID starts no user clock and leaves all payload pads at
high impedance.
