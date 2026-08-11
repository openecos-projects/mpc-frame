# Architecture

[中文说明](arch.md)

## Source layout

- `hw/soc/top/` contains the SoC integration top.
- `hw/soc/bus/`, `hw/soc/reset/`, and `hw/soc/clock/` hold SoC-level integration.
- `hw/ip/` contains reusable IP with optional `rtl/`, `tb/` or `dv/`, `driver/`,
  and `doc/` directories.
- `hw/common/` contains shared RTL utilities.
- Compatibility implementations still used by the SoC remain under `hw/ip/`,
  such as `hw/ip/spi/legacy_apb/`.

## Configuration sources

- `config/soc.yml` describes the template SoC top and selected IP paths.
- `config/memory.yml` is the source for generated RTL packages and C headers.
- `config/boards/sim.yml` describes simulation-board defaults.

## Integration flow

1. Keep the SoC top under `hw/soc/top/`; update `hw/filelist/verilator.f` when
   modules are added or renamed.
2. Put top-level bus, clock, reset, and interrupt wiring under `hw/soc/`.
3. Update `hw/filelist/soc.f` and `hw/filelist/verilator.f` together.
4. After memory-map changes, regenerate `hw/include/soc_pkg.sv` from
   `config/memory.yml` and update `sw/ecos/board.h`.

CPU replacement and bring-up must follow the core-slot and AXI contracts.
