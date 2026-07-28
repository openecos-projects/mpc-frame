# mpc-frame

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
- `designs/1/`：可独立 lint 和仿真的用户设计包示例。
- `scripts/design_registry.py`：manifest 校验与 wrapper/registry 生成器。
- `rtl/generated/FrameDesignRegistry.sv`：已提交的确定性生成结果。
- `docs/io-map.md`：用户自定义 pad 编号说明。
- `reference/sim/`：从当前 `sim` 工程导入并裁剪后的 SoC 参考设计。

## 当前状态

本工程的默认 top 是 `FrameTop`。设计选择信号来自 `user_io[6:0]`，在复位期间锁存；`user_io[72:7]` 是当前设计使用的 66 根 payload IO。只有设计 0 和 `designs/registry.json` 中注册的设计能够被选择，未注册设计保持停钟、复位和高阻。

参考设计 design 0 固定使用 `user_io[7:8]` 连接 UART0、`user_io[9:12]` 连接 SPI Flash、`user_io[13:18]` 连接 QSPI PSRAM，并将剩余 `user_io[19:72]` 分配为 32 位和 22 位两组 GPIO。完整 pin map 见 `docs/reference-design.md`。

`user_io` 默认没有任何预定义协议或固定功能。用户需要自行决定每个 pad 的用途、方向、复用方式、电气约束和内部连接关系。

## 快速检查

```sh
make lint
make control-test
make design-lint DESIGN=designs/1
make design-test DESIGN=designs/1
make design-frame-test DESIGN=designs/1
make registry-check
```

用户包的独立 lint 和测试不要求写入根 registry。需要集成到 `FrameTop` 时，将其 `design.json` 路径加入 `designs/registry.json`，执行 `make registry-generate`，并提交更新后的生成 RTL。完整格式和流程见 [用户设计注册](docs/user-design-registration.md)。
