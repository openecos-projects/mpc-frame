# Boot Flow

[中文说明](boot-flow.md)

Verilator reads a raw software binary from `build/sw/<board>/<app>/` and passes
its path to the harness as `+bootrom=<path>`.

## Flow

1. After reset, the CPU fetches from the SoC boot address through SPI Flash.
2. The harness receives the raw Flash image path through `+bootrom=<path>`.
3. The Flash DPI model returns bytes when RTL performs SPI reads.
4. `sw/ecos/start.S` initializes the stack, clears `.bss`, and calls `main`.
5. Platform drivers use the board-package headers under `sw/ecos/`.

Use a `.bin` image. Passing an ELF makes the model treat ELF container bytes as
raw Flash contents.
