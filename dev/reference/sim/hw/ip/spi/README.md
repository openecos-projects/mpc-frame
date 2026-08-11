# SPI 控制器

[English](README.en.md)

## 特性

- 兼容 Motorola SPI，支持主机半双工传输
- 支持标准、Dual 和 Quad SPI
- 最多四个片选
- 最大 2^16 的可编程分频
- 支持 MSB/LSB 优先、软硬件 NSS 和全部 CPOL/CPHA 模式
- 支持 8、16、24 或 32 位数据宽度
- 硬件 NSS 下支持 1～65536 次传输
- 可编程 dummy 和 delay 周期
- 独立收发 FIFO，深度 16～64
- 可屏蔽收发中断和可编程阈值
- 静态同步设计，完全可综合

当前实现细节以 RTL 和 driver 源码为准。
