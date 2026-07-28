# IP 状态

[English](ip-readiness.en.md)

| 模块 | 状态 | 验证 |
| --- | --- | --- |
| NPC core 0 | 启用 | 从外部 SPI Flash XIP 启动 |
| UART0 | 启用 | 串口输入和输出通过 |
| GPIO0/GPIO1 | 启用 | 两组输出翻转和外部输入读取通过 |
| SPI Flash | 启用 | `FrameTop` 启动镜像通过 |
| QSPI PSRAM | 启用 | byte/halfword/word 和边界读写通过 |
| RCU/CLINT/PLIC | 启用 | 作为 NPC 基础运行支持保留 |

其余原参考工程 IP 已从源码树和 filelist 删除。
