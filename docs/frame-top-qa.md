# FrameTop 工程定义 QA

这份文档用于明确 `mpc-frame` 的工程定位、顶层边界、参考设计接入方式和验证流程。已经确认的内容记录为“已确认”，待回答的问题保留在“待确认”部分。

## 已确认

### Q1. 当前工程的用途是什么？

**A：** `mpc-frame` 是面向用户交付的空芯片模板。用户基于固定的芯片顶层接口实现自己的设计，并使用统一的验证、综合和流片流程。

### Q2. `reference` 目录的用途是什么？

**A：** `reference` 是参考设计，用于验证芯片模板和流片流程的正确性。参考设计不是与模板完全无关的示例，而是应该能够被顶层直接实例化，并作为默认的可运行实现。

### Q3. 芯片顶层叫什么？

**A：** 当前顶层从 `GenerateTop` 更名为 `FrameTop`。后续文档、文件名、仿真入口和构建脚本统一使用 `FrameTop`。

### Q4. 芯片顶层的固定接口是什么？

**A：** 当前固定接口为：

```verilog
module FrameTop(
  input clock,
  input reset,
  inout [N-1:0] user_io
);
```

其中 `user_io` 的数量仍可能调整，当前暂定为 73 根。flash、PSRAM、UART、GPIO 等功能不作为顶层固定端口单独暴露，而应通过 `user_io` 或内部适配层连接。

### Q5. 需要支持哪些验证目标？

**A：** 以下目标都需要支持：

1. 空模板可以通过基础 lint 和综合检查。
2. `FrameTop` 实例化参考设计后可以完成 SoC 级仿真。
3. 用户替换内部设计后，可以继续复用同一套仿真入口和验证流程。

## 已确认（续）

### Q6. `FrameTop` 默认实例化哪一种实现？

**A：** 默认实例化参考设计，同时保留用户设计接入接口。参考设计是设计 0，用户设计从设计 1 开始编号。

```text
design 0 -> reference design
design 1 -> user design 1
design 2 -> user design 2
design 3 -> user design 3
...
```

### Q7. 用户设计如何替换参考设计？

**A：** 用户不替换参考设计。参考设计和用户设计同时接入 `FrameTop`，由顶层 mux 选择实际启动的设计。

```text
FrameTop
├── Design0: ReferenceSoC
├── Design1: UserDesign1
├── Design2: UserDesign2
└── DesignSelect / mux
```

### Q8. 是否需要定义 `FrameTop` 与内部设计之间的抽象接口？

建议不要让 `FrameTop` 直接暴露参考 SoC 的 AXI/APB/外设细节，而是定义稳定的内部适配接口，例如：

```text
FrameTop
└── FrameImpl
    ├── clock/reset
    └── frame_io
        └── user_io adapter
```

**A：** 暂时不定义独立的 `frame_io` 抽象接口。用户设计直接连接普通的 `user_io`。同时提供用户设计的 example 包裹层。

### Q9. `user_io` 的默认功能映射是什么？

请确认以下策略：

- [ ] `user_io` 默认全部保持用户自定义，不规定 UART/GPIO 等功能。
- [ ] 参考设计提供一份默认 IO map，但用户可以重新分配。
- [ ] frame 规定固定的 IO map，所有用户设计必须遵守。
- [ ] 其他：

**A：** `user_io` 只是普通 IO 接口，不规定 UART、GPIO 等默认功能。每个用户设计可以自行定义 IO 的用途、方向和协议。

### Q10. 参考设计的源码和 FrameTop 的关系是什么？

- [ ] `reference/sim` 作为独立源码快照，由 `FrameTop` 的 reference backend 调用。
- [ ] 将参考设计的关键 RTL 移入根工程，`reference` 只保留验证资源。
- [ ] 使用 git submodule、subtree 或其他方式保持参考设计与上游同步。
- [ ] 其他：

**A：** `reference` 作为当前工程的固定源码目录直接维护和提交，不使用 git submodule。参考设计保留自身的 `config/`、`hw/`、`dv/`、`sw/`、`scripts/` 和 `docs/` 结构，但其版本随 `mpc-frame` 一起管理。
### Q11. 仿真顶层应该是哪一个？

- [ ] Verilator 直接以 `FrameTop` 为 RTL top，并由 testbench 驱动 `clock/reset/user_io`。
- [ ] 继续以 `SimTop` 为仿真 top，由 `SimTop` 包装 `FrameTop`。
- [ ] ASIC/综合 top 是 `FrameTop`，仿真 top 可以额外使用 `SimTop`。
- [ ] 其他：

**A：** Verilator 直接以 `FrameTop` 为 RTL top，由 testbench 驱动 `clock`、`reset` 和 `user_io`。

### Q12. 空模板需要验证到什么程度？

- [ ] 只做 Verilog/SystemVerilog lint。
- [ ] 做综合 elaboration 和基本时钟/复位检查。
- [ ] 做形式验证或结构约束检查。
- [ ] 做 IO 三态、方向和 pad 连接检查。
**A：** 当前阶段先做 lint 检查，综合、形式验证、IO 三态检查和其他流片检查后续再接入。

### Q13. 用户替换设计后，哪些内容必须保持不变？

请列出不可修改的契约，例如：

- 顶层模块名：`FrameTop`
- 顶层端口名和方向
- `user_io` 数量
- clock/reset 电气和时序约束
- 构建命令
- 仿真 testbench 接口

**A：** 暂时未确定。

### Q14. 流片流程需要哪些固定输入？

请确认是否需要纳入仓库：

- [ ] IO/pad 约束
- [ ] 时钟约束
- [ ] 复位约束
- [ ] 工艺库或标准单元 wrapper
- [ ] 顶层综合网表检查脚本
- [ ] DRC/LVS/STA 的接口脚本
- [ ] 其他：

**A：** 当前暂不接入 IO 约束、时钟约束、工艺库 wrapper、综合网表检查、DRC/LVS/STA 等流片脚本。

## 下一组需要确认的问题

### Q15. 设计选择信号从哪里来？

- [ ] 由 `user_io` 中的若干位在上电时采样。
- [ ] 由仿真 plusarg、综合宏或构建变量选择。
- [ ] 由参考设计中的寄存器或 boot 配置选择。

**A：** 设计选择信号从 `user_io` 中提取。当前目标是支持 128 个小设计接入，因此至少需要 7 位选择编码：

```text
design_id = user_io[6:0]
```

具体选择位范围和是否需要上电采样仍待确定。

### Q16. 设计 1、设计 2 等用户设计是否同时综合？

- [ ] 所有设计都实例化并综合，运行时由 mux 选择。
- [ ] 每次只编译一个用户设计，设计编号只用于构建配置。
- [ ] 仿真时全部实例化，流片时只保留选中的设计。
**A：** 所有用户设计都需要参与流片，因此综合时全部设计都要实例化并参与综合，运行时由顶层 mux 选择当前设计。

### Q17. 多个设计如何处理 `user_io` 驱动冲突？

**A：** 每个设计的输入和输出都经过统一 mux。用户设计不能直接把多个 `inout` 端口互相连接后交给顶层，而应通过统一的输入、输出和输出使能信号接入 mux。
- [ ] 只有当前设计可以驱动 `user_io`，其他设计强制高阻。
- [ ] 用户设计自行保证未选中时不驱动 IO。
- [ ] 其他：

### Q18. 用户 example 包裹层的交付形式是什么？

- [ ] `examples/user_design/` 下提供可编译的 RTL 示例。
- [ ] 提供一个 `UserDesign` 模块模板和对应 filelist。
- [x] 每个用户设计独立一个目录，并通过 manifest 注册。
- [ ] 其他：

## 当前架构结论

```text
FrameTop
├── user_io
│   ├── design select bits
│   └── design payload IO
├── Design0: ReferenceSoC
├── Design1 ... Design127: user designs
├── DesignMux
└── UserDesignManifest
```

当前共 128 个设计，编号为设计 0 到设计 127。其中设计 0 是参考设计，设计 1 到设计 127 是用户设计。所有设计参与综合；运行时只有被选择的设计可以通过 IO mux 连接到顶层 `user_io`。

虽然当前不对用户额外公开 `frame_io` 抽象接口，但顶层内部仍需要统一的设计适配形式：

```text
UserDesignN
├── io_in[N-1:0]
├── io_out[N-1:0]
└── io_oe[N-1:0]
        │
        ▼
    DesignMux
        │
        ▼
  user_io[N-1:0]
```

## 下一组需要确认的问题

### Q19. 128 个设计的编号范围是什么？

**A：** 设计 0 到设计 127，共 128 个；设计 0 是参考设计，设计 1 到设计 127 是用户设计。
- [ ] 设计 1 到设计 128，共 128 个；设计 0 保留给其他用途。
- [ ] 其他：

### Q20. `design_id` 是否需要上电锁存？

**A：** 复位期间从 `user_io[6:0]` 采样一次，复位释放后锁存 `design_id`，运行期间不再改变。
- [ ] 上电后采样一次，并提供固定的稳定时间。
- [ ] 其他：

### Q21. `user_io` 中哪些位用于设计选择？

**A：** 固定使用 `user_io[6:0]` 作为设计选择信号，`user_io[72:7]` 提供给当前被选中的设计使用。因此当前 73 根 IO 中有 66 根是设计 payload IO。
- [ ] 选择位和普通 IO 通过时序复用。
- [ ] 选择位由单独的配置机制提供，但仍从 `user_io` 进入。
- [ ] 其他：

### Q22. 未被选择的设计是否继续运行？

**A：** 只有被选中的设计接收有效时钟，其他设计暂停。设计选择锁存完成后，才能生成各设计的有效时钟，避免设计选择信号在运行期间变化。
- [ ] 其他：

### Q23. 用户设计的统一接入接口是什么？

建议使用内部 wrapper 统一成以下形式，用户无需直接实现顶层 `inout`：

```verilog
module UserDesignWrapper #(
  parameter int IO_WIDTH = 73
) (
  input  logic                 clock,
  input  logic                 reset,
  input  logic [IO_WIDTH-1:0] io_in,
  output logic [IO_WIDTH-1:0] io_out,
  output logic [IO_WIDTH-1:0] io_oe
);
```

**A：** 采用 `io_in/io_out/io_oe` 形式。用户设计不直接使用顶层 `inout`，由 `FrameTop` 或用户 example wrapper 完成转换。
- [ ] 用户设计直接使用 `inout`，由 wrapper 负责转换。
- [ ] 其他：

## 最终架构摘要

```text
                     reset 期间采样
user_io[6:0] ─────────────────────────┐
                                      ▼
                              DesignIdLatch
                                      │ design_id[6:0]
                                      ▼
clock ───────────────────────────► DesignClockEnable
                                      │
        ┌─────────────────────────────┼─────────────────────────────┐
        │                             │                             │
        ▼                             ▼                             ▼
 Design0                         Design1                       Design127
 ReferenceSoC                    UserDesign1                   UserDesign127
        │                             │                             │
 io_in/io_out/io_oe             io_in/io_out/io_oe             io_in/io_out/io_oe
        └─────────────────────────────┼─────────────────────────────┘
                                      ▼
                              UserIoMux / TriState
                                      │
                              user_io[72:7]
```

工程上需要区分两个概念：

- `FrameTop` 的外部接口仍然是 `clock`、`reset` 和 `user_io`。
- `io_in/io_out/io_oe` 是顶层内部的统一连接形式，不作为用户芯片的额外外部端口。

由于设计选择在复位期间锁存，设计选择位在运行期间不能作为普通 payload IO 使用。当前 payload IO 数量为 66 根。

设计选择对应的时钟控制应优先实现为无毛刺的 clock-enable 或工艺相关 clock-gating cell。不能直接使用可能在有效时钟边沿附近变化的组合 mux 生成时钟。
