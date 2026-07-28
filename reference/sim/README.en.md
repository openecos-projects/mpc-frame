# FRAME Reference SoC

[中文说明](README.md)

This directory contains the fixed reference sources used by design 0 in
`FrameTop`.

Retained blocks:

- NPC core 0
- UART16550 UART0
- two GPIO groups: 32 bits and 22 bits
- SPI Flash XIP controller and simulation model
- one 8 MiB QSPI PSRAM controller and simulation model
- RCU, CLINT, and PLIC required by the CPU

The official simulation entry is the repository-root `FrameTop`:

```sh
make reference-verilate
make reference-test
```

Flash and PSRAM models are enabled only with `FRAME_SIM_MODELS`. Tapeout RTL
exposes physical memory pins through `FrameTop.user_io` and contains no
behavioral memory model.
