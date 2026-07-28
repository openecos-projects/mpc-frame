# 用户设计接入指南

[English](user-guide.en.md)

这份指南从一个空目录开始，带你完成创建电路、测试电路、接入 FrameTop 和提交前
检查。第一次使用时按顺序执行即可，不需要修改 `FrameTop.sv` 或根目录的 RTL。

## 0. 检查工具

需要 Python 3、GNU Make、C++ 编译器和 Verilator。推荐 Verilator 5.050，工程也
验证过 5.032；低于 5.032 的版本没有经过验证。

```sh
make verilator-version
```

Makefile 会自动检测 Verilator 是否支持非关键警告参数。旧版本不认识
`-Wno-PROCASSINIT` 时会跳过它，不会因此停止构建。

## 1. 创建自己的目录

从 1 到 127 中选择一个未使用的编号。例如创建 design 3：

```sh
make create-design DESIGN_ID=3
```

命令会创建：

```text
designs/3/
├── README.md                  中文说明
├── README.en.md               English guide
├── design.json                源码和测试清单
├── rtl/
│   └── UserDesign3.sv         你的电路
└── tests/
    ├── UserDesign3Tb.sv       只测试你的电路
    └── FrameUserDesign3Tb.sv  测试接入 FrameTop 后的完整连接
```

默认顶层名是 `UserDesign3`。确实需要自定义时可以在创建时指定：

```sh
make create-design DESIGN_ID=3 DESIGN_NAME=uart-demo DESIGN_MODULE=UartDemo
```

创建命令不会覆盖已有目录，也会拒绝 design 0、超出范围的编号和已经注册的编号。

## 2. 编写电路

打开 `rtl/UserDesign3.sv`，替换示例逻辑。最外层五个端口是 FrameTop 与用户电路
之间的固定连接，初次接入时不要改名或删除：

```systemverilog
input  logic        clock;
input  logic        reset;
input  logic [65:0] io_in;
output logic [65:0] io_out;
output logic [65:0] io_oe;
```

- `clock` 是时钟。纯组合电路可以不使用，但端口仍需保留。
- `reset` 是复位。没有状态的电路可以不使用，但端口仍需保留。
- `io_in[n]` 读取第 n 位用户 IO 的当前电平。
- `io_out[n]` 是电路准备输出的值。
- `io_oe[n] = 1` 才会把 `io_out[n]` 驱动到外部；为 0 时释放该引脚。

请给所有 `io_out` 和 `io_oe` 位确定值。常见写法是先设置默认值，再单独打开
需要的输出：

```systemverilog
always_comb begin
  io_out = '0;
  io_oe  = '0;
  // 在这里实现你的逻辑
end
```

## 3. 修改并运行单元测试

`tests/UserDesign3Tb.sv` 只连接你的电路，适合先判断功能是否正确。文件内已用
“通常保留 / Usually keep”和“按设计修改 / Edit for your design”标出边界。

修改 RTL 后，必须同步替换 TB 中针对模板 heartbeat 的输入和判断。运行：

```sh
make design-lint DESIGN=designs/3
make design-test DESIGN=designs/3 TEST=io
```

`design-lint` 检查语法和常见 RTL 问题；`design-test` 会编译并真正运行 TB。
只有看见 TB 输出的 `PASS` 且 make 正常结束，才算通过。`Verilog $finish` 表示
测试按计划结束，不是错误。

此时 design 还没有接入正式 FrameTop，这是正常的。

## 4. 注册 design

独立测试通过后，打开根目录的 `designs/registry.json`。例如注册 design 3：

```json
{
  "designs": [
    "3/design.json"
  ]
}
```

如果已有其他正式设计，在数组中追加一行，不要删除它们。然后生成 FrameTop 使用
的连接代码：

```sh
make registry-generate
make registry-check
```

`rtl/generated/FrameDesignRegistry.sv` 是工具生成的文件，不要手工编辑。

## 5. 修改并运行 Frame 测试

`tests/FrameUserDesign3Tb.sv` 检查完整路径：

```text
测试环境 -> user_io -> FrameTop -> UserDesign3 -> FrameTop -> user_io
```

`user_io[6:0]` 用于选择 design。其余 66 位连接用户电路，换算规则是：

```text
设计内部 io_*[n] <-> FrameTop 外部 user_io[n + 7]
```

例如，设计的 `io_in[0]` 对应 `user_io[7]`，`io_out[5]` 对应
`user_io[12]`。

修改 TB 中标为“按设计修改”的功能检查。测试环境只能驱动输入引脚，不能同时
驱动设计已经通过 `io_oe=1` 驱动的输出引脚，否则会产生 IO 冲突。

运行：

```sh
make design-frame-test DESIGN=designs/3 TEST=frame
```

只有看见 Frame TB 输出的 `PASS` 且 make 正常结束，才算完整接入成功。

## 6. 提交前检查

```sh
make regression-fast
git diff --check
```

需要调试 Frame 测试时可以生成波形：

```sh
make frame-test DESIGN=designs/3 TEST=frame TRACE=1
```

波形位于 `build/waves/3/frame.fst`，构建产物和波形不要提交。

## 常见错误

- `DESIGN is required`：命令中缺少 `DESIGN=designs/3`。
- `design is not listed`：还没有把 design 加入 `designs/registry.json`。
- `generated file is stale`：执行 `make registry-generate`。
- `Unknown warning ... PROCASSINIT`：使用了未做兼容处理的旧 Makefile；更新后
  根 Makefile 会自动跳过该选项。
- 输出显示 `z`：对应的 `io_oe` 没有置 1，或 design 尚未成功选中。
- 输出显示 `x`：信号没有确定赋值，或者测试环境与设计同时驱动同一引脚。
- `$fatal`：TB 的某一项检查失败；错误文字会说明实际失败的位置。
