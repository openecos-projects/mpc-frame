# GPIO 数据手册

[English](datasheet.en.md)

## 概述

GPIO 是 1～32 路参数化软 IP，提供 APB4 从接口、方向控制、两路备选功能复用和
多种输入中断触发方式。

## 接口

| 端口 | 类型 | 说明 |
| --- | --- | --- |
| `apb4` | interface | APB4 从接口 |
| `gpio.gpio_in_i` | input | GPIO 输入 |
| `gpio.gpio_out_o` | output | GPIO 输出 |
| `gpio.gpio_dir_o` | output | GPIO 方向 |
| `gpio.gpio_alt_in_o` | output | 送往复用功能的输入 |
| `gpio.gpio_alt_0_out_i` | input | 备选功能 0 输出值 |
| `gpio.gpio_alt_0_dir_i` | input | 备选功能 0 方向 |
| `gpio.gpio_alt_1_out_i` | input | 备选功能 1 输出值 |
| `gpio.gpio_alt_1_dir_i` | input | 备选功能 1 方向 |
| `gpio.irq_o` | output | GPIO 中断 |

## 寄存器

| 名称 | 偏移 | 长度 | 说明 |
| --- | ---: | ---: | --- |
| `PADDIR` | `0x00` | 4 | 引脚方向 |
| `PADIN` | `0x04` | 4 | 引脚输入数据 |
| `PADOUT` | `0x08` | 4 | 引脚输出数据 |
| `INTEN` | `0x0c` | 4 | 中断使能 |
| `INTTYPE0` | `0x10` | 4 | 中断类型位 0 |
| `INTTYPE1` | `0x14` | 4 | 中断类型位 1 |
| `INTSTAT` | `0x18` | 4 | 中断状态 |
| `IOCFG` | `0x1c` | 4 | IO 控制模式 |
| `PINMUX` | `0x20` | 4 | 备选功能选择 |

有效位范围均为 `[GPIO_NUM-1:0]`，高位保留，复位值为 `0x0000_0000`。

### 方向和数据

- `PADDIR[i] = 0`：第 i 路输入；`PADDIR[i] = 1`：第 i 路输出。
- `PADIN[i]`：只读的引脚实际输入值。
- `PADOUT[i]`：软件控制模式下的输出值。

### 中断

- `INTEN[i] = 1`：启用第 i 路输入中断。
- `INTTYPE1[i: i]` 与 `INTTYPE0[i: i]` 组合定义触发方式：

  | `INTTYPE1` | `INTTYPE0` | 触发方式 |
  | ---: | ---: | --- |
  | 0 | 0 | 高电平 |
  | 0 | 1 | 低电平 |
  | 1 | 0 | 上升沿 |
  | 1 | 1 | 下降沿 |

- `INTSTAT` 返回中断状态。

### IO 复用

- `IOCFG[i] = 0`：软件 GPIO 控制；`IOCFG[i] = 1`：备选功能控制。
- 备选模式下，`PINMUX[i] = 0` 选择通道 0，`PINMUX[i] = 1` 选择通道 1。

## 编程示例

```c
// 软件输出
gpio.IOCFG[i]  = 0;
gpio.PADDIR[i] = 1;
gpio.PADOUT[i] = DATA_1_BIT;

// 备选功能
gpio.IOCFG[i]  = 1;
gpio.PINMUX[i] = ALT_CHANNEL;

// 输入中断
gpio.PADDIR[i]  = 0;
gpio.INTEN[i]   = 1;
gpio.INTTYPE0[i] = 0;
gpio.INTTYPE1[i] = 1; // 上升沿
```

当前裁剪后的参考工程只保留 RTL 接口示例，不包含独立的 GPIO 软件驱动。
