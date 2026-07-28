# mpc-frame

[English](README.en.md)

`mpc-frame` 是一个用于拼片的顶层空壳模板工程，并附带一个独立的 SoC 参考设计。

`FrameTop` 是芯片总顶层，设计 0 固定为参考设计，设计 1 到设计 127 通过 JSON registry 注册。拼片用户通过统一的 `clock/reset/io_in/io_out/io_oe` 语义接口接入自己的设计。

当前参考 SoC 作为设计 0 的 adapter 接入。参考 SoC 固定维护在 [`reference/sim/`](reference/sim/) 中，作为当前工程的一部分提交和构建，不使用 submodule。

当前保留的顶层接口：

- `clock`：输入时钟。
- `reset`：输入复位。
- `user_io[72:0]`：73 个用户自定义双向 pad。

相关文件：

- `FrameTop.sv`：正式芯片总顶层，也是综合和仿真的统一入口。
- `rtl/DesignIoMux.sv`：128 个设计的 IO 选择和三态控制。
- `rtl/FrameDesignControl.sv`：设计编号同步、锁存和复位释放控制。
- `rtl/FrameClockGate.sv`：可映射到工艺 ICG 的通用无毛刺时钟门控。
- `rtl/ReferenceDesign0.sv`：参考设计 adapter 边界。
- `designs/registry.json`：参与 FrameTop 集成的用户设计清单。
- `designs/template/`：通过 `make create-design` 使用的用户 package 模板。
- `designs/<name>/`：用户通过 `make create-design` 创建的个人设计目录；仓库不
  预放内部测试设计。
- `scripts/design_registry.py`：manifest 校验与 wrapper/registry 生成器。
- `rtl/generated/FrameDesignRegistry.sv`：已提交的确定性生成结果。
- `docs/io-map.md`：用户自定义 pad 编号说明。
- `reference/sim/`：从当前 `sim` 工程导入并裁剪后的 SoC 参考设计。

## 当前状态

本工程的默认 top 是 `FrameTop`。设计选择信号来自 `user_io[6:0]`，在复位期间锁存；`user_io[72:7]` 是当前设计使用的 66 根 payload IO。只有设计 0 和 `designs/registry.json` 中注册的设计能够被选择，未注册设计保持停钟、复位和高阻。

参考设计 design 0 固定使用 `user_io[7:8]` 连接 UART0、`user_io[9:12]` 连接 SPI Flash、`user_io[13:18]` 连接 QSPI PSRAM，并将剩余 `user_io[19:72]` 分配为 32 位和 22 位两组 GPIO。完整 pin map 见 `docs/reference-design.md`。

`user_io` 默认没有任何预定义协议或固定功能。用户需要自行决定每个 pad 的用途、方向、复用方式、电气约束和内部连接关系。

## 快速检查

创建一个新的用户设计 package：

```sh
make create-design DESIGN_NAME=counter32
```

完整流程见 [用户设计接入指南](docs/user-guide.md)。已有设计的检查入口如下：

```sh
make user-lint
make user-test
make user-frame-test
make user-check
make lint
make control-test
make frame-test DESIGN=0 TEST=boot
make registry-check
make stage9-test
make regression-fast
make regression
```

推荐使用 Verilator 5.050；工程也验证过 5.032。低于 5.032 的版本未验证。
Makefile 会先检测非关键警告参数是否受支持，不会因为旧版本不认识
`-Wno-PROCASSINIT` 而中止。

用户不需要选择 design ID 或修改根 registry。`user-frame-test` 会在 `build/` 中
自动分配临时槽位。维护者合并时使用
`make integrate-design DESIGN=designs/<name> DESIGN_ID=<id>` 分配最终 ID、更新
registry 并重新验证。完整格式和流程见
[用户设计注册](docs/user-design-registration.md)。

`make regression-fast` 运行根检查及所有已注册用户设计的 lint、unit 和 FrameTop 测试；`make regression` 在此基础上增加 reference Flash 启动、UART、GPIO 和 PSRAM 回归。传入 `TRACE=1` 后，FrameTop 测试的 FST 波形写入 `build/waves/`。完整回归契约见 [仿真与回归](docs/simulation-regression.md)。

GitHub CI 在 push 和 pull request 上分别执行源码一致性、FrameTop 快速回归和
reference 完整回归，也支持手动生成 FST artifact。配置和门禁说明见
[持续集成](docs/ci.md)。
