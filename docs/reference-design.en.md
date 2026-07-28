# Reference Design

[中文说明](reference-design.md)

`reference/sim/` contains the SoC reference design shipped with `mpc-frame`.

## Project boundary

- `FrameTop.sv` is the chip top.
- Design 0 connects the reference SoC through `rtl/ReferenceDesign0.sv`.
- `reference/sim/` remains a distinct source boundary but is committed directly,
  not as a Git submodule.
- It retains `config/`, `hw/`, `dv/`, `sw/`, `scripts/`, and `docs/` layers.
- Trimming, replacement, and feature verification should remain within that tree.
- The active design contains NPC core 0, UART0, two GPIO groups, one SPI Flash,
  and one QSPI PSRAM.
- UART pins are independent of GPIO:

  | IO | Function |
  | --- | --- |
  | `user_io[6:0]` | Design ID |
  | `user_io[7]` | UART0 RX |
  | `user_io[8]` | UART0 TX |
  | `user_io[9]` | SPI Flash SCK |
  | `user_io[10]` | SPI Flash CS_n |
  | `user_io[11]` | SPI Flash MOSI |
  | `user_io[12]` | SPI Flash MISO |
  | `user_io[13]` | QSPI PSRAM SCK |
  | `user_io[14]` | QSPI PSRAM CS_n |
  | `user_io[18:15]` | QSPI PSRAM DQ[3:0] |
  | `user_io[50:19]` | GPIO0[31:0] |
  | `user_io[72:51]` | GPIO1[21:0] |

The generic frame interface remains `clock`, `reset`, and `user_io`; this table
is the fixed design 0 mapping.

## Reference entry points

```sh
make lint
make frame-test DESIGN=0 TEST=boot
make reference-test
make regression
```

`FrameTop` is the official simulation top. `FrameReferenceSoC` is its fixed
design 0 implementation; the reference tree has no separate simulation top.
`reference/sim/tests.json` lists the reference regressions. Peripheral models
and the C++ harness remain under `reference/sim/dv/verilator`; the root runner
only selects tests and manages logs and waveforms.

## Import policy

The reference is imported as a source snapshot without Git metadata or build
output. Updates must be committed completely in this repository with a matching
version note to avoid path and dependency drift.
