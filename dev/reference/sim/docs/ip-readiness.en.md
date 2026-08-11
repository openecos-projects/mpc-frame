# IP Readiness

[中文说明](ip-readiness.md)

| Block | Status | Verification |
| --- | --- | --- |
| NPC core 0 | Enabled | Boots through external SPI Flash XIP |
| UART0 | Enabled | Serial input and output pass |
| GPIO0/GPIO1 | Enabled | Both output groups and external inputs pass |
| SPI Flash | Enabled | `FrameTop` boot image passes |
| QSPI PSRAM | Enabled | Byte/halfword/word and boundary accesses pass |
| RCU/CLINT/PLIC | Enabled | Retained as NPC runtime support |

Other IP from the former reference project has been removed from the source
tree and filelists.
