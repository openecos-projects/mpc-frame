# FRAME Reference SoC

[English](README.en.md)

该目录包含 `FrameTop` design 0 使用的固定参考设计源码。

保留模块：

- NPC core 0
- UART16550 UART0
- 两组 GPIO：32 位和 22 位
- SPI Flash XIP 控制器及仿真模型
- 单颗 8 MiB QSPI PSRAM 控制器及仿真模型
- CPU 运行所需的 RCU、CLINT 和 PLIC

正式仿真入口是仓库根目录的 `FrameTop`：

```sh
make reference-verilate
make reference-test
```

Flash 和 PSRAM 模型仅在 `FRAME_SIM_MODELS` 下启用。流片 RTL 通过
`FrameTop.user_io` 暴露真实存储器引脚，不包含行为模型。
