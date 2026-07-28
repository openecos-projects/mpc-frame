# 用户设计接入指南

[English](user-guide.en.md)

这份指南面向只开发一个设计的普通用户。用户只需要给设计起名、编写 RTL 和测试，
不需要选择 design ID，也不需要修改 `designs/registry.json`。最终 ID 由维护者合并
代码时分配。

完整示例：

- [三路非门](examples/three-inverter.md)：组合逻辑和双向 IO；
- [32 位计数器](examples/counter-32bit.md)：时序逻辑、时钟和同步复位。

## 1. 检查工具

需要 Python 3、GNU Make、C++ 编译器和 Verilator。推荐 Verilator 5.050，工程也
验证过 5.032；低于 5.032 的版本未验证。

```sh
make verilator-version
```

## 2. 创建设计

选择一个能表达功能的名称，例如 `counter32`：

```sh
make create-design DESIGN_NAME=counter32
```

命令会创建：

```text
designs/counter32/
├── README.md
├── README.en.md
├── design.json
├── rtl/Counter32.sv
└── tests/
    ├── Counter32Tb.sv
    └── FrameCounter32Tb.sv
```

默认模块名由设计名称生成。确实需要自定义时使用：

```sh
make create-design DESIGN_NAME=counter32 DESIGN_MODULE=MyCounter
```

创建命令不会覆盖已有目录。名称只能使用小写字母、数字、点、下划线和连字符。

## 3. 编写电路

打开 `rtl/Counter32.sv`，替换模板逻辑。下面五个端口是 FrameTop 与用户设计之间
的固定接口，初次使用时不要改名或删除：

```systemverilog
input  logic        clock;
input  logic        reset;
input  logic [65:0] io_in;
output logic [65:0] io_out;
output logic [65:0] io_oe;
```

- `clock`：时钟；纯组合电路可以不使用，但端口必须保留。
- `reset`：复位；无状态电路可以不使用，但端口必须保留。
- `io_in[n]`：读取第 n 位用户 IO 的当前电平。
- `io_out[n]`：设计准备输出的值。
- `io_oe[n] = 1`：设计驱动该引脚；为 0 时释放该引脚。

请为全部 `io_out` 和 `io_oe` 位提供确定值。常见写法是先清零，再打开实际输出：

```systemverilog
always_comb begin
  io_out = '0;
  io_oe  = '0;
  // 实际逻辑
end
```

## 4. 修改测试

两个 TB 文件已经标出“通常保留”和“按设计修改”的区域：

- `tests/Counter32Tb.sv` 只测试用户电路；
- `tests/FrameCounter32Tb.sv` 测试信号经过外部 `user_io` 和 FrameTop 的完整路径。

Frame TB 中的 `DESIGN_ID` 由构建工具通过 `FRAME_TEST_DESIGN_ID` 自动注入。不要
把它改成固定数字。

## 5. 运行用户检查

仓库中只有一个未注册设计时，不需要传入目录：

```sh
make user-lint
make user-test
make user-frame-test
```

也可以一次运行全部检查：

```sh
make user-check
```

这些命令分别完成：

1. `user-lint`：检查用户 RTL 语法、组合环路和常见结构问题；
2. `user-test`：运行独立单元测试；
3. `user-frame-test`：自动选择空闲临时 ID，生成隔离 registry，再运行 Frame TB。

如果工作区中有多个未注册设计，工具会要求显式选择：

```sh
make user-check DESIGN=designs/counter32
```

原有维护者命令仍可使用，例如
`make design-test DESIGN=designs/counter32 TEST=io`。

## 6. IO 映射

FrameTop 的 73 根双向引脚中，低 7 位供框架选择设计，其余 66 位连接用户电路：

```text
设计 io_*[n] <-> 外部 user_io[n + 7]
```

例如 `io_in[0]` 对应 `user_io[7]`。测试环境只能驱动设计释放的输入引脚；如果
测试环境和设计同时驱动同一位，波形会出现 `x`。

## 7. 查看波形

```sh
make user-frame-test TRACE=1
gtkwave build/waves/counter32/frame.fst
```

本次 Frame 测试实际使用的临时或正式 ID 写在：

```text
build/designs/counter32/frame/selected-id.txt
```

假设其中是 `1`，在 GTKWave 的 SST 窗口中展开：

```text
FrameCounter32Tb
└── dut
    └── u_design_registry
        └── u_design_1
            └── u_design
```

重点观察 TB 的 `test_io_out/test_io_oe/user_io`、FrameTop 的
`selection_valid/payload_*`，以及最后一级 `u_design` 内部的状态信号。

`io_in` 会回读设计正在驱动的输出引脚，这是双向 IO 的正常行为。判断方向时以
`io_oe` 为准。

## 8. 提交代码

提交前运行：

```sh
make user-check
make docs-check
git diff --check
git status --short
```

普通用户提交 `designs/<name>/` 即可，不要修改或提交以下内容：

- `designs/registry.json`；
- `rtl/generated/FrameDesignRegistry.sv`；
- `build/` 和 FST 波形。

维护者合并时执行：

```sh
make integrate-design DESIGN=designs/counter32 DESIGN_ID=12
```

该命令分配最终槽位、更新正式 registry、重新生成 registry RTL，并使用最终 ID
再次运行 Frame 测试。

## 常见错误

- `no unregistered user design found`：当前没有待测试设计，先运行创建命令。
- `multiple unregistered user designs found`：使用 `DESIGN=designs/<name>` 指定。
- 输出为 `z`：对应 `io_oe` 没有置 1，或设计尚未成功选中。
- 输出为 `x`：信号没有确定赋值，或 TB 与设计同时驱动同一引脚。
- `$fatal`：TB 检查失败，错误文字会说明具体位置。
- `generated file is stale`：这是维护者正式集成阶段的问题，运行
  `make registry-generate`。
