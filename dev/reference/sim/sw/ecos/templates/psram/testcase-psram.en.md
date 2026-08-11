# Test Case 02: PSRAM Access

[中文说明](testcase-psram.md)

## Purpose and scope

Verify software reads and writes the memory-mapped PSRAM window beginning at
`0xc0000000`, with correct data returned by the Verilator model. Bandwidth,
timing margin, refresh behavior, and multicore coherence are outside scope.

## Reserved address map

| Region | Base | Size | Expected chip select |
| --- | ---: | ---: | --- |
| PSRAM chip 0 | `0xc0000000` | `0x00800000` | `psram_nss_o[0]` |
| PSRAM chip 1 | `0xc0800000` | `0x00800000` | `psram_nss_o[1]` |
| PSRAM chip 2 | `0xc1000000` | `0x00800000` | `psram_nss_o[2]` |

The complete reserved window is `0xc0000000..0xc17fffff`. The current FRAME
reference instantiates and tests one 8 MiB chip only.

## Preconditions

- `config/memory.yml`, `hw/include/soc_pkg.sv`, and `sw/ecos/board.h` agree on
  the PSRAM base and size.
- The Verilator top connects external PSRAM pins to `ESP_PSRAM64H`.
- The active reference model corresponds to `psram_nss_o[0]`.

## Program behavior

1. Initialize UART and print `psram test start`.
2. Write fixed patterns to representative addresses.
3. Read the same addresses and compare values.
4. Print `psram ok` on success, or `psram fail` and stop on mismatch.

Required chip 0 samples include:

| Address | Value | Purpose |
| ---: | ---: | --- |
| `0xc0000000` | `0x11223344` | First word |
| `0xc0000004` | `0x55667788` | Adjacent word |
| `0xc0400100` | `0x0c040100` | Midpoint sample |
| `0xc07ffffc` | `0xa5a5a5a5` | Final word |

Addresses in chip 1 and chip 2 remain historical reserved-window cases and are
not accessed by the current one-chip regression.

## Pass criteria

UART must print `psram test start` followed by `psram ok`. `psram fail`, timeout,
or a missing chip select is a failure.

## Current implementation

Verilator `FrameTop` connects one `ESP_PSRAM64H` model under
`FRAME_SIM_MODELS`. The `psram` regression checks boundaries, a representative
midpoint, and byte/halfword/word accesses.
