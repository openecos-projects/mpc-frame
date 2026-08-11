# Test Case 02: PSRAM Access

[中文说明](testcase-psram.md)

## Purpose

Verify that software accesses the external PSRAM window through the SoC memory
path and that the Verilator PSRAM model returns written data.

## Scope

This test covers memory-mapped PSRAM at `0xc0000000`. It does not verify
bandwidth, timing margin, refresh behavior, or multicore coherence.

## Address map

| Region | Base | Size | Expected chip select |
| --- | ---: | ---: | --- |
| PSRAM chip 0 | `0xc0000000` | `0x00800000` | `psram_nss_o[0]` |

The current reference uses chip 0 only, with the window
`0xc0000000..0xc07fffff`.

## Preconditions

- `config/memory.yml` defines PSRAM base `0xc0000000`, size `0x00800000`.
- `hw/include/soc_pkg.sv` exports `SOC_PSRAM_BASE` and `SOC_PSRAM_SIZE`.
- `sw/ecos/board.h` exports `MPC_SOC_PSRAM_BASE` and `MPC_SOC_PSRAM_SIZE`.
- The Verilator top connects PSRAM pins to an `ESP_PSRAM64H` model.
- The FRAME top instantiates the model matching `psram_nss_o[0]`.

## Test behavior

1. Initialize UART.
2. Print `psram test start`.
3. Write fixed 32-bit patterns to representative PSRAM addresses.
4. Read the same addresses.
5. Print `psram ok` when every value matches.
6. Print `psram fail` and stop on a mismatch.

## Required accesses

| Address | Value | Purpose |
| ---: | ---: | --- |
| `0xc0000000` | `0x11223344` | First word of chip 0 |
| `0xc0000004` | `0x55667788` | Adjacent word and byte-lane check |
| `0xc07ffffc` | `0xa5a5a5a5` | Last word of chip 0 |

Older three-chip designs also tested addresses at and above `0xc0800000`; the
current single-chip reference no longer accesses them.

## Pass criteria

UART must contain:

```text
psram test start
psram ok
```

The test fails if UART prints `psram fail`, simulation times out before
`psram ok`, or the controller does not assert the expected chip select.

## Suggested regression entry

Archive the image as:

```text
sw/bootrom/psram_access/
  main-asm.bin
  test.yml
```

Example `test.yml`:

```yaml
name: psram_access
image: main-asm.bin
max_cycles: 2000000
trace: false
uart:
  stop_text: "psram ok"
```

## Current implementation

FRAME regression uses `TOP=FrameTop` and connects the external PSRAM interface
to one simulation model under `FRAME_SIM_MODELS`. Tapeout builds do not define
that macro; PSRAM DQ inputs come directly from `FrameTop.user_io`.
