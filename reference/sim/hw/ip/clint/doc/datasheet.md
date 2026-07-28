# CLINT 数据手册

[English](datasheet.en.md)

## 概述

CLINT（core-local interruptor）是参数化软 IP，实现兼容 RISC-V Privileged
Specification v1.1 的本地定时器和软件中断，并提供符合 AMBA APB v2.0 的 APB4
从接口。

## 特性

- 64 位可编程 `mtime` 和 `mtimecmp`
- 软件中断
- 静态同步、完全可综合

## 接口

| 端口 | 类型 | 说明 |
| --- | --- | --- |
| `apb4` | interface | APB4 从接口 |
| `clint.tmr_irq_o` | output | 定时器中断输出 |
| `clint.sfr_irq_o` | output | 软件中断输出 |

## 寄存器

| 名称 | 偏移 | 长度 | 说明 |
| --- | ---: | ---: | --- |
| `MSIP` | `0x0000` | 4 | 机器模式软件中断 |
| `MTIMECMPL` | `0x4000` | 4 | `mtimecmp[31:0]` |
| `MTIMECMPH` | `0x4004` | 4 | `mtimecmp[63:32]` |
| `MTIMEL` | `0xbff8` | 4 | `mtime[31:0]` |
| `MTIMEH` | `0xbffc` | 4 | `mtime[63:32]` |

### MSIP

| 位 | 访问 | 说明 |
| --- | --- | --- |
| `[31:1]` | - | 保留 |
| `[0]` | RW | 写 1 挂起软件中断，写 0 清除 |

复位值：`0x0000_0000`。

### MTIME

`MTIMEL` 和 `MTIMEH` 为只读的 64 位自由运行计数器低、高 32 位，复位值均为
`0x0000_0000`。

### MTIMECMP

`MTIMECMPL` 和 `MTIMECMPH` 为可读写的 64 位比较值低、高 32 位，复位值均为
`0xffff_ffff`。当 `mtime` 达到比较值时产生定时器中断。

## 编程示例

所有寄存器按 4 字节对齐访问：

```c
clint.MTIMECMPL = MTIMECMP_LOW_32;
clint.MTIMECMPH = MTIMECMP_HIGH_32;

// 更新下一次定时器中断
clint.MTIMECMPL = UPDATE_LOW_32;
clint.MTIMECMPH = UPDATE_HIGH_32;

// 软件中断
clint.MSIP = 1; // 触发
clint.MSIP = 0; // 清除
```

完整 driver 和测试代码位于 `../driver/`。
