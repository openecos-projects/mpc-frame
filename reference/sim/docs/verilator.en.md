# Verilator

[中文说明](verilator.md)

The only simulation top is the repository-root `FrameTop`. The reference
filelist is `hw/filelist/frame.f`, and the harness is
`dv/verilator/csrc/sim_main.cpp`.

```sh
make reference-verilate
make reference-test
```

`reference-test` covers Flash XIP, UART input/output, both GPIO groups, and one
PSRAM.
