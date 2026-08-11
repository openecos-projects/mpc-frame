# mpc-frame 工程实施计划

[English](../en/implementation-plan.md)

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
- 已完成 JSON 用户设计注册、独立 wrapper、临时用户设计测试和 FrameTop 集成测试。
- `make -f Makefile.dev regression-fast` 和 `make -f Makefile.dev regression` 已统一根检查、所有注册设计和 reference 验收入口。
- 已接入单平台 CI，自动执行源码一致性、FrameTop 快速回归和 reference 完整验收。
- 已提供可生成的用户 package 模板、中文接入指南和端到端模板验收。

当前 design 0 参考链路、用户设计创建和注册、统一回归及 CI 门禁均已可运行；后续工作进入流片 pad wrapper、约束和工艺映射。

## 阶段计划

| 阶段 | 目标 | 主要工作 | 交付物 | 验收条件 |
| --- | --- | --- | --- | --- |
| 0. 契约冻结 | 固定 FrameTop 外部和内部契约 | 确认顶层端口、IO 数量、设计编号、复位采样时序、payload IO 宽度、用户设计 wrapper | README、design control 和 IO map 定稿 | 任何实现都能依据正式设计文档接入，不再依赖口头约定 |
| 1. 工程边界整理 | 建立稳定的源码和参考工程边界 | 将 `dev/reference/sim` 作为当前仓库固定源码提交；清理 Git 元数据和构建输出；区分参考源码与当前工程构建输出 | 固定的 `dev/reference/sim/` 源码、参考设计版本说明、根目录 Makefile | 新环境直接克隆 `mpc-frame` 即可获得参考设计 |
| 2. FrameTop 基础结构 | 完成芯片总顶层和 128 槽位 | 保留设计 0～127；实现设计编号锁存；实现选中设计控制；统一 `io_in/io_out/io_oe` | `FrameTop.sv`、`rtl/DesignIoMux.sv`、槽位 wrapper | FrameTop 可独立 lint；非法连接和多重 IO 驱动检查通过 |
| 3. 设计选择和时钟控制 | 已完成：保证运行时选择稳定且无毛刺 | 两级同步并锁存 design ID；通用无毛刺 clock gate；未选设计停钟并保持复位；选中设计延迟释放内部复位 | `rtl/FrameDesignControl.sv`、`rtl/FrameClockGate.sv`、`docs/cn/design-control.md` | `make -f Makefile.dev control-test` 已覆盖运行期锁定、重新选择、one-hot、复位、IO 隔离和门控脉冲 |
| 4. 参考 SoC 接入 | 让设计 0 真正运行精简参考 SoC | 接入单 NPC core、UART0、SPI Flash、单颗 QSPI PSRAM 和 32+22 GPIO | `ReferenceDesign0` 实现、reference IO map、精简 filelist | 已完成：design 0 可从外部 Flash 接口取指并运行 |
| 5. 用户设计注册 | 已完成：用户按名称开发，维护者合并时分配 1～127 的最终槽位 | 每个 `designs/<name>/design.json` 自包含且不要求 ID；Frame 测试自动分配临时 ID；根 registry 保存最终 ID 与 package 路径 | `designs/`、注册生成器、`rtl/generated/FrameDesignRegistry.sv`、[用户设计注册](user-design-registration.md) | `make -f Makefile.dev stage5-test` 覆盖独立测试、临时 Frame 集成和正式注册 |
| 6. FrameTop 仿真 | 已完成：建立统一顶层仿真入口 | 统一调度 SV package testbench 和 reference C++ harness；规范日志、FST 波形和 reference JSON 清单 | `scripts/run_regression.py`、`dev/reference/sim/tests.json`、[仿真与回归](simulation-regression.md) | `make -f Makefile.dev frame-test` 可运行 design 0 或任意注册用户设计；`TRACE=1` 产生非空 FST |
| 7. 设计级回归 | 已完成：验证选择、mux 和多设计 IO 行为 | registry 驱动全部正式设计测试；每个 Frame 测试自动 bind 严格 OE 重叠 monitor；根测试覆盖未注册槽位、复位、停钟、高阻和同值外部 IO 争用 | 临时测试 package、生成式 IO contention monitor、分层日志、快速和完整回归入口 | `make -f Makefile.dev regression-fast` 自动覆盖根契约和所有注册用户设计；`make -f Makefile.dev regression` 增加完整 reference 验收 |
| 8. 根工程质量门禁 | 已完成：防止用户接入破坏公共契约 | 固定工具版本；检查源码、manifest、filelist 和生成文件；分别执行 FrameTop 与 reference 回归；支持手动 FST | `.github/workflows/ci.yml`、`scripts/ci/install_verilator.sh`、[持续集成](ci.md) | push 和 PR 自动运行三项门禁，失败日志可下载，手动测试可下载波形 |
| 9. 用户交付模板 | 已完成：形成可生成、可独立验证的用户工程入口 | 一键生成 package；提供 RTL、unit/FrameTop test、中文指南、冲突诊断和明确 IO map；CI 执行端到端模板 smoke test | `designs/template/`、`make create`、`make -f Makefile.dev stage9-test`、[用户设计接入指南](user-guide.md) | 全新 package 可独立 lint 和 unit test，并通过临时 registry 接入 FrameTop，不修改正式 registry 或根 RTL |
| 10. 流片准备 | 后续接入真实流片流程 | 加入 pad/IO 约束、时钟复位约束、工艺 wrapper、综合和顶层检查脚本 | `constraints/`、综合脚本、流片接口文档 | FrameTop 可进入目标工艺的综合和后续 signoff 流程 |

## 当前最缺失的内容

### 1. 流片 pad wrapper 和约束尚未完成

Flash、PSRAM、UART 和 GPIO 已从 `FrameTop.user_io` 暴露，但还需要目标工艺的 pad cell、引脚位置、电气属性和时序约束。

### 2. 工艺 ICG 映射留待流片阶段

通用无毛刺 `FrameClockGate` 已完成并通过行为回归；目标工艺确定后，仍需在阶段 10 将其映射为具体 ICG 标准单元。


## 推荐执行顺序

建议按以下顺序推进，不要先扩展 127 个用户设计：

1. 冻结 IO 和设计选择契约。
2. 固定 `dev/reference/sim` 源码边界和版本说明。
3. 完成 design 0 的真实接入。
4. 建立 FrameTop 级最小仿真，先跑 design 0。
5. 创建临时 design package 并通过同一仿真入口接入验证。
6. 实现 manifest 到设计槽位的自动注册。
7. 扩展 CI、回归、用户模板和流片约束。

## 阶段完成标准

在进入下一阶段前，至少满足：

- 当前阶段的 RTL、脚本和文档已经落盘；
- 有一个可重复执行的命令作为验收入口；
- 失败时能明确定位是顶层、设计槽位、参考 SoC 还是 testbench 问题；
- 不改变已经冻结的 `FrameTop` 外部接口。
