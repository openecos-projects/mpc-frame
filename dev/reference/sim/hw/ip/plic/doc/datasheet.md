# PLIC 数据手册

[English](datasheet.en.md)

## 概述

PLIC 是参数化平台级中断控制器软 IP，兼容 RISC-V PLIC 1.0.0，提供 APB4 从
接口，支持一个 hart target 和最多 31 路外部中断。

## 接口

| 端口 | 类型 | 说明 |
| --- | --- | --- |
| `apb4` | interface | APB4 从接口 |
| `plic.irq_i` | input | 外部中断源输入 |
| `plic.irq_o` | output | 发往 hart 的中断输出 |

## 寄存器

| 名称 | 偏移 | 长度 | 说明 |
| --- | ---: | ---: | --- |
| `CTRL` | `0x00` | 4 | 控制和 gateway 最大触发数 |
| `TM` | `0x04` | 4 | 32 路触发模式 |
| `PRIO1` | `0x08` | 4 | IRQ 0～7 优先级 |
| `PRIO2` | `0x0c` | 4 | IRQ 8～15 优先级 |
| `PRIO3` | `0x10` | 4 | IRQ 16～23 优先级 |
| `PRIO4` | `0x14` | 4 | IRQ 24～31 优先级 |
| `IP` | `0x18` | 4 | pending 状态 |
| `IE` | `0x1c` | 4 | 中断使能 |
| `THOLD` | `0x20` | 4 | target 0 优先级阈值 |
| `CLAIMCOMP` | `0x24` | 4 | claim/complete |

寄存器复位值均为 `0x0000_0000`。

### CTRL

- `CTRL.EN`：0 禁用 PLIC，1 启用。
- `CTRL.TNM`：gateway 最大触发数。

### TM 和优先级

- `TM[i] = 0`：IRQ i 为电平触发；`TM[i] = 1`：边沿触发。
- 每路优先级占 4 位，分布在 `PRIO1`～`PRIO4`。

### Pending、使能和阈值

- `IP[i]`：IRQ i 的只读 pending 状态。
- `IE[i]`：IRQ i 的使能位。
- `THOLD`：只有优先级高于阈值的中断才能到达 target。

### Claim/Complete

读取 `CLAIMCOMP` 返回当前可处理的 IRQ ID；处理完成后将同一 ID 写回，清除该
中断的 in-service 状态。

## 编程示例

```c
plic.CTRL.TNM = TNM;
plic.TM       = TRIGGER_MODES;
plic.PRIO1    = PRIORITY_0_7;
plic.PRIO2    = PRIORITY_8_15;
plic.PRIO3    = PRIORITY_16_23;
plic.PRIO4    = PRIORITY_24_31;
plic.THOLD    = THRESHOLD;
plic.IE       = ENABLE_MASK;
plic.CTRL.EN  = 1;

void plic_handle(void) {
    uint32_t id = plic.CLAIMCOMP;
    handle_external_irq(id);
    plic.CLAIMCOMP = id;
}
```
