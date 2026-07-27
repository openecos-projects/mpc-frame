# 测试用例 02：PSRAM 访问

## 目的

验证软件可以通过 SoC 内存路径访问外部 PSRAM 窗口，并且 Verilator PSRAM 模型可以正确返回已写入的数据。

## 范围

本测试覆盖 `0xc0000000` 处的 memory-mapped PSRAM 读写。

本测试不验证 PSRAM 带宽、时序裕量、刷新行为或多核一致性。

## 地址映射

| 区域 | 基地址 | 大小 | 期望片选 |
| --- | ---: | ---: | --- |
| PSRAM 片 0 | `0xc0000000` | `0x00800000` | `psram_nss_o[0]` |
<!-- FRAME 参考设计只使用片 0。 -->

PSRAM 窗口为 `0xc0000000..0xc07fffff`。

## 前置条件

- `config/memory.yml` 将 PSRAM 定义为基地址 `0xc0000000`、大小 `0x00800000`。
- `hw/include/soc_pkg.sv` 导出 `SOC_PSRAM_BASE` 和 `SOC_PSRAM_SIZE`。
- `sw/ecos/board.h` 导出 `MPC_SOC_PSRAM_BASE` 和 `MPC_SOC_PSRAM_SIZE`。
- Verilator 必须使用会把 PSRAM 引脚连接到 `ESP_PSRAM64H` 模型的仿真顶层。
- FRAME 仿真顶层例化 `psram_nss_o[0]` 对应的一颗 PSRAM 模型。

## 测试程序行为

启动镜像应执行：

1. 初始化 UART。
2. 打印 `psram test start`。
3. 向代表性 PSRAM 地址写入固定 32-bit pattern。
4. 从同一批地址读回数据。
5. 如果所有值匹配，打印 `psram ok`。
6. 如果任意值不匹配，打印 `psram fail` 并停机。

## 必需访问

最低必需地址：

| 地址 | 写入值 | 目的 |
| ---: | ---: | --- |
| `0xc0000000` | `0x11223344` | 片 0 的首个字 |
| `0xc0000004` | `0x55667788` | 相邻字，用于基本字节通道检查 |
| `0xc07ffffc` | `0xa5a5a5a5` | 片 0 的最后一个字 |

旧版三颗 PSRAM 设计曾扩展测试以下地址，当前单颗 PSRAM 参考设计不再访问：

| 地址 | 写入值 | 目的 |
| ---: | ---: | --- |
| `0xc0800000` | `0x12345678` | 片 1 的首个字 |
| `0xc0fffffc` | `0x87654321` | 片 1 的最后一个字 |
| `0xc1000000` | `0xdeadbeef` | 片 2 的首个字 |
| `0xc17ffffc` | `0xcafebabe` | 片 2 的最后一个字 |

## 通过标准

当 UART 输出包含以下内容时，测试通过：

```text
psram test start
psram ok
```

以下情况判定失败：

- UART 输出包含 `psram fail`。
- 仿真在输出 `psram ok` 前超时。
- PSRAM 控制器没有对被访问地址拉起期望的片选。

## 建议回归入口

将启动镜像归档到：

```text
sw/bootrom/psram_access/
  main-asm.bin
  test.yml
```

建议的 `test.yml`：

```yaml
name: psram_access
image: main-asm.bin
max_cycles: 2000000
trace: false
uart:
  stop_text: "psram ok"
```

## 当前实现说明

FRAME 回归使用 `TOP=FrameTop`，并通过 `FRAME_SIM_MODELS` 将外部 PSRAM 接口连接到单颗仿真模型。

流片构建不定义 `FRAME_SIM_MODELS`，PSRAM DQ 输入直接来自 `FrameTop.user_io`。
