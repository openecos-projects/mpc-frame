# PLIC

[English](README.en.md)

## 特性

- 兼容 RISC-V PLIC 1.0.0
- 支持一个 hart target
- 最多 31 路外部中断和 16 个优先级
- 支持上升沿和高电平触发
- 可编程 pending 计数器用于排队边沿中断
- 每个中断源具有独立 enable 和 pending 位
- 静态同步设计，完全可综合

完整寄存器说明见[中文数据手册](doc/datasheet.md)。
