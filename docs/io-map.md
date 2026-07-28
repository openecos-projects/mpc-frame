# IO 映射

`FrameTop` 对外提供 73 根双向 pad：

```systemverilog
inout wire [72:0] user_io
```

## 固定分区

| FrameTop pad | 用途 | 用户设计端口 |
| --- | --- | --- |
| `user_io[6:0]` | 7 位 design ID，仅在复位期间采样 | 不可见 |
| `user_io[72:7]` | 当前选中设计的 66 位 payload | `io_in/io_out/io_oe[65:0]` |

payload 的换算关系固定为：用户设计的 `io_*[n]` 对应
`FrameTop.user_io[n + 7]`。例如 `io_out[0]` 驱动 `user_io[7]`，
`io_in[65]` 读取 `user_io[72]`。

## 方向契约

每一位 payload 都使用三信号语义：

- `io_in[n]` 始终读取 pad 当前解析后的电平；
- `io_oe[n] = 1` 时，设计通过 `io_out[n]` 驱动 pad；
- `io_oe[n] = 0` 时，设计释放 pad 为高阻，可由外部驱动。

设计必须给全部 `io_out` 和 `io_oe` 位确定值。外部环境不得在
`io_oe[n] = 1` 时反向驱动不同电平，否则属于电气争用。

## 设计选择

外部环境应在 `reset = 1` 时驱动 `user_io[6:0]`，并至少跨越两个 `clock`
上升沿保持稳定。复位释放后 design ID 被锁定，运行期间修改 pad 不会切换设计；
重新选择必须再次进入复位。design 0 固定为 reference，用户槽位范围为 1 到 127。

未注册的 design ID 不会启动任何用户时钟，所有 payload pad 保持高阻。
