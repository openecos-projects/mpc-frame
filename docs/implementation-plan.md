# mpc-frame 工程实施计划

本文档描述从当前 RTL 骨架到可供用户使用的芯片模板所需完成的阶段、交付物和验收条件。已经冻结的设计选择、时钟和复位契约记录在 [Design Control](design-control.md) 中。

## 当前状态

已完成第一版结构骨架：

- `FrameTop.sv` 已作为根目录正式顶层。
- 已支持设计 0 到设计 127 的槽位结构。
- `user_io[6:0]` 已用于设计选择，`user_io[72:7]` 作为 payload IO。
- 已加入 `io_in/io_out/io_oe` 和统一 IO mux。
- 已完成两级设计选择同步、无毛刺时钟门控和内部复位延迟释放。
- design 0 已接入单 NPC 核参考 SoC，并暴露 UART0、SPI Flash、QSPI PSRAM 和两组 GPIO。
- 已建立以 `FrameTop` 为顶层的 Verilator 构建与参考设计功能回归。
- 已完成 JSON 用户设计注册、独立 wrapper、design 1 独立测试和 FrameTop 集成测试。
- `make regression-fast` 和 `make regression` 已统一根检查、所有注册设计和 reference 验收入口。

当前 design 0 参考链路、两个用户设计和统一回归均已可运行；后续主要工作是 CI、用户交付模板、工艺 pad wrapper 和约束。

## 阶段计划

| 阶段 | 目标 | 主要工作 | 交付物 | 验收条件 |
| --- | --- | --- | --- | --- |
| 0. 契约冻结 | 固定 FrameTop 外部和内部契约 | 确认顶层端口、IO 数量、设计编号、复位采样时序、payload IO 宽度、用户设计 wrapper | README、design control 和 IO map 定稿 | 任何实现都能依据正式设计文档接入，不再依赖口头约定 |
| 1. 工程边界整理 | 建立稳定的源码和参考工程边界 | 将 `reference/sim` 作为当前仓库固定源码提交；清理 Git 元数据和构建输出；区分参考源码与当前工程构建输出 | 固定的 `reference/sim/` 源码、参考设计版本说明、根目录 Makefile | 新环境直接克隆 `mpc-frame` 即可获得参考设计 |
| 2. FrameTop 基础结构 | 完成芯片总顶层和 128 槽位 | 保留设计 0～127；实现设计编号锁存；实现选中设计控制；统一 `io_in/io_out/io_oe` | `FrameTop.sv`、`rtl/DesignIoMux.sv`、槽位 wrapper | FrameTop 可独立 lint；非法连接和多重 IO 驱动检查通过 |
| 3. 设计选择和时钟控制 | 已完成：保证运行时选择稳定且无毛刺 | 两级同步并锁存 design ID；通用无毛刺 clock gate；未选设计停钟并保持复位；选中设计延迟释放内部复位 | `rtl/FrameDesignControl.sv`、`rtl/FrameClockGate.sv`、`docs/design-control.md` | `make control-test` 已覆盖运行期锁定、重新选择、one-hot、复位、IO 隔离和门控脉冲 |
| 4. 参考 SoC 接入 | 让设计 0 真正运行精简参考 SoC | 接入单 NPC core、UART0、SPI Flash、单颗 QSPI PSRAM 和 32+22 GPIO | `ReferenceDesign0` 实现、reference IO map、精简 filelist | 已完成：design 0 可从外部 Flash 接口取指并运行 |
| 5. 用户设计注册 | 已完成：让设计 1～127 可独立测试并按清单集成 | 每个 `designs/<id>/design.json` 自包含源码和测试；根 `registry.json` 只选择最终集成包；生成 standalone wrapper、slot wrapper、registry、filelist 和 `design_present` | `designs/`、注册生成器、`rtl/generated/FrameDesignRegistry.sv`、[用户设计注册](user-design-registration.md) | `make stage5-test` 覆盖独立测试、注册集成和未注册槽位隔离 |
| 6. FrameTop 仿真 | 已完成：建立统一顶层仿真入口 | 统一调度 SV package testbench 和 reference C++ harness；规范日志、FST 波形和 reference JSON 清单 | `scripts/run_regression.py`、`reference/sim/tests.json`、[仿真与回归](simulation-regression.md) | `make frame-test` 可运行 design 0 或任意注册用户设计；`TRACE=1` 产生非空 FST |
| 7. 设计级回归 | 已完成：验证选择、mux 和多设计 IO 行为 | registry 驱动全部设计测试；覆盖 design 0、design 1、design 2、未注册槽位、复位、停钟、输入回读、高阻和外部 IO 争用检测 | design 2、IO contention monitor、分层日志、快速和完整回归入口 | `make regression-fast` 自动覆盖根契约和所有注册用户设计；`make regression` 增加完整 reference 验收 |
| 8. 根工程质量门禁 | 防止用户接入破坏公共契约 | 增加 lint、filelist 检查、manifest 检查、模块接口检查和 CI | `.github/workflows/ci.yml`、检查脚本 | 每次提交自动完成根工程 lint 和最小仿真 |
| 9. 用户交付模板 | 形成可复制的用户工程入口 | 完善用户 README、设计目录模板、构建变量、错误提示和 IO map | `designs/template/`、用户指南 | 用户可以复制模板、注册设计并复用同一仿真命令 |
| 10. 流片准备 | 后续接入真实流片流程 | 加入 pad/IO 约束、时钟复位约束、工艺 wrapper、综合和顶层检查脚本 | `constraints/`、综合脚本、流片接口文档 | FrameTop 可进入目标工艺的综合和后续 signoff 流程 |

## 当前最缺失的内容

### 1. 根工程 CI 尚未接入

本地已经具备 lint、manifest 负向测试、控制测试、design 独立测试和 FrameTop 回归入口，但还没有在每次提交时自动执行的 CI 工作流。

### 2. `reference` 需要完成固定源码治理

当前工作区中的 `reference/` 已经是普通源码目录，但还需要完成提交治理：确认哪些文件属于源码、排除构建输出，并记录参考设计版本和来源变更。

### 3. 流片 pad wrapper 和约束尚未完成

Flash、PSRAM、UART 和 GPIO 已从 `FrameTop.user_io` 暴露，但还需要目标工艺的 pad cell、引脚位置、电气属性和时序约束。

### 4. 用户交付模板仍需产品化

`designs/1` 已证明完整流程，但阶段 9 仍需提供可复制的空模板、面向用户的中文接入指南和更清晰的常见错误说明。

### 5. 工艺 ICG 映射留待流片阶段

通用无毛刺 `FrameClockGate` 已完成并通过行为回归；目标工艺确定后，仍需在阶段 10 将其映射为具体 ICG 标准单元。

### 6. IO 契约还需要更明确

当前默认是 73 根 IO，其中 7 根用于 design ID，剩余 66 根作为 payload。需要在 IO map 中明确：

- 设计选择位在 reset 期间的电平和采样窗口；
- payload IO 的输入、输出和高阻行为；
- 未注册设计的默认行为；
- 参考 SoC 具体 pad 到 payload bit 的映射。

当前参考设计映射固定为：UART0 使用 `user_io[8:7]`，SPI Flash 使用 `user_io[12:9]`，QSPI PSRAM 使用 `user_io[18:13]`，GPIO0/GPIO1 使用 `user_io[50:19]` 和 `user_io[72:51]`。

## 推荐执行顺序

建议按以下顺序推进，不要先扩展 127 个用户设计：

1. 冻结 IO 和设计选择契约。
2. 固定 `reference/sim` 源码边界和版本说明。
3. 完成 design 0 的真实接入。
4. 建立 FrameTop 级最小仿真，先跑 design 0。
5. 接入 design 1 并跑同一仿真入口。
6. 实现 manifest 到设计槽位的自动注册。
7. 扩展 CI、回归、用户模板和流片约束。

## 阶段完成标准

在进入下一阶段前，至少满足：

- 当前阶段的 RTL、脚本和文档已经落盘；
- 有一个可重复执行的命令作为验收入口；
- 失败时能明确定位是顶层、设计槽位、参考 SoC 还是 testbench 问题；
- 不改变已经冻结的 `FrameTop` 外部接口。
