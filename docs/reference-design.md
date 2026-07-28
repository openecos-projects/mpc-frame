# Reference Design

`reference/sim/` 是 `mpc-frame` 当前附带的 SoC 参考设计，来源为同级 `sim` 工程的当前版本。

## Boundary

- `FrameTop.sv` 是 mpc-frame 的默认芯片总顶层。
- 设计 0 通过 `rtl/ReferenceDesign0.sv` 接入参考 SoC。
- `reference/sim/` 保持独立的参考 SoC 工程边界，但作为当前仓库的固定源码目录直接维护，不使用 git submodule。
- 参考设计保留完整的 `config/`、`hw/`、`dv/`、`sw/`、`scripts/` 和 `docs/` 分层。
- 后续裁剪、替换和功能验证优先在 `reference/sim/` 内进行。
- 参考设计只启用 core 0（NPC）、一组 UART0、两组 GPIO、一颗 SPI Flash 和一颗 QSPI PSRAM。
- 参考设计使用独立 UART IO，不与 GPIO 复用：

  | IO | Function |
  | --- | --- |
  | `user_io[6:0]` | Design ID |
  | `user_io[7]` | UART0 RX |
  | `user_io[8]` | UART0 TX |
  | `user_io[9]` | SPI Flash SCK |
  | `user_io[10]` | SPI Flash CS_n |
  | `user_io[11]` | SPI Flash MOSI |
  | `user_io[12]` | SPI Flash MISO |
  | `user_io[13]` | QSPI PSRAM SCK |
  | `user_io[14]` | QSPI PSRAM CS_n |
  | `user_io[18:15]` | QSPI PSRAM DQ[3:0] |
  | `user_io[50:19]` | GPIO0[31:0] |
  | `user_io[72:51]` | GPIO1[21:0] |

- frame 的通用顶层接口仍为 `clock`、`reset` 和 `user_io`；上述映射是 design 0 参考设计的固定 IO 约定。

## Reference Entry Points

frame 工程的基础入口为：

```sh
make lint
make frame-test DESIGN=0 TEST=boot
make reference-test
make regression
```

`FrameTop` 是工程的正式仿真 top；`FrameReferenceSoC` 是其中 design 0 使用的固定参考实现。reference 内部不再保留独立仿真顶层。

reference 的回归项目由 `reference/sim/tests.json` 描述，外设模型和 C++ harness 继续归 `reference/sim/dv/verilator` 管理。根回归调度器只负责测试选择、日志和波形路径。

## Import Policy

参考设计按 `sim` 工程快照导入，不带入其 Git 元数据和构建输出。参考设计更新时应在当前仓库内提交完整变更，并同步更新版本说明，避免手工复制产生路径或依赖漂移。
