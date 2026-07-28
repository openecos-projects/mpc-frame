# Frame 模式介绍

[English](frame-mode.en.md)

Frame 模式让多个彼此独立的 RTL 设计共用一个芯片顶层和一组物理 IO。它不是一套
软件协议，而是由 `FrameTop` 实现的硬件选择、时钟复位隔离和 IO 复用结构。

<FrameArchitecture />

## 先理解三个边界

| 边界 | 作用 | 用户是否修改 |
| --- | --- | --- |
| `FrameTop` | 芯片总顶层，负责选择设计和连接物理 IO | 否 |
| `UserDesign*` | 用户 RTL 的统一包装接口 | 只修改模块内部 |
| `designs/<name>/` | 一个设计的源码、manifest 和测试 package | 是 |

用户设计看到的接口固定为 `clock`、`reset`、`io_in[65:0]`、`io_out[65:0]` 和
`io_oe[65:0]`。其中 `io_oe[n] = 1` 表示设计主动驱动第 `n` 根 payload pad，
`io_oe[n] = 0` 表示释放这根 pad，可以把它当作输入读取。

## IO 如何分组

`FrameTop` 对外共有 73 根双向 `user_io`：

```text
user_io[6:0]   -> 7-bit design ID，最多表示 128 个槽位
user_io[72:7]  -> 66-bit payload，交给当前选中的设计

设计内部 io_*[n] <-> 芯片外部 user_io[n + 7]
```

design ID 只负责选择槽位，不属于用户设计的 66 位业务 IO。完整逐位关系见
[IO 映射](io-map.md)。

## 设计怎样被选中

<SelectionTimeline />

选择过程发生在复位阶段。外部先保持 `reset = 1`，把 design ID 放到
`user_io[6:0]`，等待选择稳定后再释放复位。运行期间修改 ID 不会把芯片突然切换到
另一个设计；要重新选择，应重新进入复位流程。详细时序见
[设计选择、时钟与复位控制](design-control.md)。

## 未选中设计会发生什么

Frame 模式同时对三个方向做隔离：

- 时钟：只有选中设计获得运行时钟，其余设计停钟。
- 复位：只有选中且有效的设计释放复位，其余设计保持复位。
- IO：只有选中设计的 `io_out/io_oe` 能到达外部，其他设计保持高阻。

如果 ID 没有在 registry 中注册，`selection_valid` 为 0，所有用户设计继续保持隔离。
design 0 固定连接参考 SoC，design 1 到 127 用于注册用户设计。

## 用户阶段为什么不需要 design ID

design ID 是芯片集成槽位，不是用户 package 的身份。用户通常只有一个待提交设计，
因此只需运行：

```sh
make user-check
```

`user-frame-test` 会在 `build/` 中生成临时 registry 并自动分配测试槽位，不会修改正式
registry。维护者合并设计时才使用 `make integrate-design ... DESIGN_ID=<id>` 分配最终
硬件编号。完整流程见[用户设计接入指南](user-guide.md)和
[用户设计注册](user-design-registration.md)。

## 在波形中定位自己的设计

使用 `TRACE=1` 生成 FST 后，先查看 `FrameTop` 下列信号：

1. `selection_valid`：确认编号有效。
2. `design_selected[DESIGN_ID]`：确认目标槽位被选中。
3. `payload_in/payload_out/payload_oe`：查看 Frame 边界上的 66 位总线。
4. `u_design_registry.u_design_<id>`：进入用户 wrapper，查看设计自己的 `io_*` 和内部状态。

双向 pad 读回当前线路解析后的值，所以 `io_in` 中可能同时看到外部输入和本设计正在
驱动的输出，这是正常的电气语义。波形命令与冲突排查见
[FrameTop 仿真与回归](simulation-regression.md)。
