# mpc-frame

`mpc-frame` 是一个用于拼片的顶层空壳模板工程，并附带一个独立的 SoC 参考设计。

`FrameTop` 是芯片总顶层，默认包含设计 0 参考设计，并预留设计 1 到设计 127 的用户设计槽位。拼片用户通过统一的 `io_in/io_out/io_oe` 接口接入自己的设计。

当前参考 SoC 作为设计 0 的 adapter 接入。参考 SoC 固定维护在 [`reference/sim/`](reference/sim/) 中，作为当前工程的一部分提交和构建，不使用 submodule。

当前保留的顶层接口：

- `clock`：输入时钟。
- `reset`：输入复位。
- `user_io[72:0]`：73 个用户自定义双向 pad。

相关文件：

- `FrameTop.sv`：正式芯片总顶层，也是综合和仿真的统一入口。
- `rtl/DesignIoMux.sv`：128 个设计的 IO 选择和三态控制。
- `rtl/ReferenceDesign0.sv`：参考设计 adapter 边界。
- `rtl/UserDesignSlot.sv`：用户设计槽位默认实现。
- `examples/user_design/`：用户设计示例和 manifest。
- `docs/io-map.md`：用户自定义 pad 编号说明。
- `reference/sim/`：从当前 `sim` 工程导入并裁剪后的 SoC 参考设计。

## 当前状态

本工程的默认 top 是 `FrameTop`。设计选择信号来自 `user_io[6:0]`，在复位期间锁存；`user_io[72:7]` 是当前设计使用的 66 根 payload IO。当前阶段提供 lint 验证，综合、形式验证和流片约束后续接入。

参考设计 design 0 固定使用 `user_io[7:8]` 连接 UART0、`user_io[9:12]` 连接 SPI Flash、`user_io[13:18]` 连接 QSPI PSRAM，并将剩余 `user_io[19:72]` 分配为 32 位和 22 位两组 GPIO。完整 pin map 见 `docs/reference-design.md`。

`user_io` 默认没有任何预定义协议或固定功能。用户需要自行决定每个 pad 的用途、方向、复用方式、电气约束和内部连接关系。

## 快速检查

```sh
make lint
make lint-user
```
