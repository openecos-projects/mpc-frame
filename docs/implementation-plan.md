# mpc-frame 工程实施计划

本文档根据 [FrameTop 工程定义 QA](frame-top-qa.md) 制定，描述从当前 RTL 骨架到可供用户使用的芯片模板所需完成的阶段、交付物和验收条件。

## 当前状态

已完成第一版结构骨架：

- `FrameTop.sv` 已作为根目录正式顶层。
- 已支持设计 0 到设计 127 的槽位结构。
- `user_io[6:0]` 已用于设计选择，`user_io[72:7]` 作为 payload IO。
- 已加入 `io_in/io_out/io_oe` 和统一 IO mux。
- design 0 已接入单 NPC 核参考 SoC，并暴露 UART0、SPI Flash、QSPI PSRAM 和两组 GPIO。
- 已建立以 `FrameTop` 为顶层的 Verilator 构建与参考设计功能回归。
- `make lint`、`make lint-user`、`make reference-verilate` 和 `make reference-test` 已通过。

当前 design 0 的参考设计链路已经可运行；后续主要工作是用户槽位自动注册、无毛刺时钟门控、工艺 pad wrapper、约束和 CI。

## 阶段计划

| 阶段 | 目标 | 主要工作 | 交付物 | 验收条件 |
| --- | --- | --- | --- | --- |
| 0. 契约冻结 | 固定 FrameTop 外部和内部契约 | 确认顶层端口、IO 数量、设计编号、复位采样时序、payload IO 宽度、用户设计 wrapper | `docs/frame-top-qa.md` 定稿、IO map 定稿 | 任何实现都能依据文档接入，不再依赖口头约定 |
| 1. 工程边界整理 | 建立稳定的源码和参考工程边界 | 将 `reference/sim` 作为当前仓库固定源码提交；清理 Git 元数据和构建输出；区分参考源码与当前工程构建输出 | 固定的 `reference/sim/` 源码、参考设计版本说明、根目录 Makefile | 新环境直接克隆 `mpc-frame` 即可获得参考设计 |
| 2. FrameTop 基础结构 | 完成芯片总顶层和 128 槽位 | 保留设计 0～127；实现设计编号锁存；实现选中设计控制；统一 `io_in/io_out/io_oe` | `FrameTop.sv`、`rtl/DesignIoMux.sv`、槽位 wrapper | FrameTop 可独立 lint；非法连接和多重 IO 驱动检查通过 |
| 3. 设计选择和时钟控制 | 保证运行时选择稳定且无毛刺 | 明确复位期间采样窗口；实现 design ID latch；确定 clock-enable 或工艺 clock-gating cell；处理未选设计 reset/clock 行为 | 设计选择 RTL、时钟控制模块、时序说明 | 选择位在运行期间变化不影响当前设计；无组合时钟毛刺 |
| 4. 参考 SoC 接入 | 让设计 0 真正运行精简参考 SoC | 接入单 NPC core、UART0、SPI Flash、单颗 QSPI PSRAM 和 32+22 GPIO | `ReferenceDesign0` 实现、reference IO map、精简 filelist | 已完成：design 0 可从外部 Flash 接口取指并运行 |
| 5. 用户设计注册 | 让设计 1～127 可由用户独立接入 | 定义每个设计目录格式；实现 manifest 解析或生成 filelist；提供 wrapper 模板；明确空槽位行为 | `examples/`、manifest、设计注册脚本、用户接入文档 | 新增一个用户设计只需新增目录和 manifest，不修改 FrameTop 核心 RTL |
| 6. FrameTop 仿真 | 建立真正的顶层仿真入口 | 驱动 clock/reset、design ID 和外部 IO；为 Flash/PSRAM 接入条件仿真模型 | Verilator harness、仿真 Makefile | design 0 已完成；design 1 仍待接入回归 |
| 7. 设计级回归 | 验证选择、mux 和 IO 行为 | 覆盖 design 0、design 1、未注册槽位、复位采样、设计切换禁止、输入回读、输出使能和高阻行为 | testbench、scoreboard、回归配置 | 所有核心场景自动 PASS；未选设计不会影响外部 IO |
| 8. 根工程质量门禁 | 防止用户接入破坏公共契约 | 增加 lint、filelist 检查、manifest 检查、模块接口检查和 CI | `.github/workflows/ci.yml`、检查脚本 | 每次提交自动完成根工程 lint 和最小仿真 |
| 9. 用户交付模板 | 形成可复制的用户工程入口 | 完善 example、用户 README、设计目录模板、构建变量、错误提示和 IO map | `examples/user_design/template/`、用户指南 | 用户可以复制模板、注册设计并复用同一仿真命令 |
| 10. 流片准备 | 后续接入真实流片流程 | 加入 pad/IO 约束、时钟复位约束、工艺 wrapper、综合和顶层检查脚本 | `constraints/`、综合脚本、流片接口文档 | FrameTop 可进入目标工艺的综合和后续 signoff 流程 |

## 当前最缺失的内容

### 1. design 1 和用户槽位尚未进入仿真回归

design 0 已完成参考 SoC 接入和功能回归；下一项功能缺口是让 manifest 实际驱动 design 1～127 的构建和实例化。

### 2. `reference` 需要完成固定源码治理

当前工作区中的 `reference/` 已经是普通源码目录，但还需要完成提交治理：确认哪些文件属于源码、排除构建输出，并记录参考设计版本和来源变更。

### 3. 流片 pad wrapper 和约束尚未完成

Flash、PSRAM、UART 和 GPIO 已从 `FrameTop.user_io` 暴露，但还需要目标工艺的 pad cell、引脚位置、电气属性和时序约束。

### 4. 用户 manifest 还没有驱动构建

目前 `examples/user_design/manifest.yml` 只是描述文件，`FrameTop` 仍然实例化默认 `UserDesignSlot`。还需要生成器或固定 wrapper，使 manifest 中的设计真正进入对应编号槽位。

### 5. 时钟门控还需要工程化处理

当前骨架使用 `clock & design_selected` 表达“只有选中设计运行”。这只适合说明结构，不能直接作为最终流片实现。后续需要替换为无毛刺 clock-enable 或工艺相关 clock-gating cell。

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
5. 接入 design 1 example 并跑同一仿真入口。
6. 再实现 manifest 到设计槽位的自动注册。
7. 最后扩展 CI、回归和流片约束。

## 阶段完成标准

在进入下一阶段前，至少满足：

- 当前阶段的 RTL、脚本和文档已经落盘；
- 有一个可重复执行的命令作为验收入口；
- 失败时能明确定位是顶层、设计槽位、参考 SoC 还是 testbench 问题；
- 不改变已经冻结的 `FrameTop` 外部接口。
