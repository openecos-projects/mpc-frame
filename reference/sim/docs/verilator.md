# Verilator

[English](verilator.en.md)

唯一仿真顶层为仓库根目录的 `FrameTop`。参考设计 filelist 为
`hw/filelist/frame.f`，仿真 harness 为 `dv/verilator/csrc/sim_main.cpp`。

```sh
make reference-verilate
make reference-test
```

`reference-test` 覆盖 Flash XIP、UART 输入输出、两组 GPIO 和单颗 PSRAM。
