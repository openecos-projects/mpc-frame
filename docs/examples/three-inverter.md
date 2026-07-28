# 三路非门用户设计接入示例

[English](three-inverter.en.md)

本文以一个简单的三路一位非门为例，完整演示如何创建用户设计、编写 RTL、编写
两层测试、注册到 FrameTop，以及查看波形。完成后的电路关系是：

```text
io_in[3] -> 非门 -> io_out[0]
io_in[4] -> 非门 -> io_out[1]
io_in[5] -> 非门 -> io_out[2]
```

设计内部 IO 与芯片外部引脚的关系为：

| 用途 | 用户设计内部 | FrameTop 外部 |
| --- | --- | --- |
| 三个输入 | `io_in[5:3]` | `user_io[12:10]` |
| 三个输出 | `io_out[2:0]` | `user_io[9:7]` |
| design 编号 | 用户设计不可见 | `user_io[6:0]` |

本示例使用 design ID 1。如果 1 已被占用，请换成其他未注册编号，并同步替换命令、
文件名和文中的 design ID。

## 1. 创建 design 1

在仓库根目录运行：

```sh
make create-design DESIGN_ID=1
```

命令会生成：

```text
designs/1/
├── README.md
├── README.en.md
├── design.json
├── rtl/UserDesign1.sv
└── tests/
    ├── UserDesign1Tb.sv
    └── FrameUserDesign1Tb.sv
```

`UserDesign1Tb.sv` 只测试非门本身；`FrameUserDesign1Tb.sv` 测试信号经过
`user_io` 和 FrameTop 后是否仍然正确。

## 2. 编写三路非门

用以下内容替换 `designs/1/rtl/UserDesign1.sv`：

```systemverilog
module UserDesign1 #(
  parameter int IO_WIDTH = 66
) (
  input  logic                clock,
  input  logic                reset,
  input  logic [IO_WIDTH-1:0] io_in,
  output logic [IO_WIDTH-1:0] io_out,
  output logic [IO_WIDTH-1:0] io_oe
);

  always_comb begin
    // 默认释放所有 IO，并给全部输出确定值。
    io_out = '0;
    io_oe  = '0;

    // 三路逐位取反。
    io_out[2:0] = ~io_in[5:3];

    // 只有 io_out[2:0] 驱动外部；io_in[5:3] 对应位保持释放。
    io_oe[2:0] = 3'b111;
  end

endmodule
```

`clock` 和 `reset` 在纯组合电路中没有使用，但它们属于固定接口，必须保留。
`io_oe` 是输出使能，不是输入使能：某位为 1 时设计驱动对应引脚，为 0 时设计
释放引脚，外部才能向该位输入。

## 3. 编写单元测试

打开 `designs/1/tests/UserDesign1Tb.sv`，保留模块声明、信号和
`UserDesignDut` 实例，用下面内容替换原来的 `initial begin ... end`：

```systemverilog
initial begin
  reset = 1'b0;
  io_in = '0;
  #1ns;

  // 只允许三个输出位驱动引脚。
  if (io_oe[2:0] !== 3'b111)
    $fatal(1, "output enable incorrect: actual=%03b expected=111", io_oe[2:0]);

  if (io_oe[IO_WIDTH-1:3] !== '0)
    $fatal(1, "unused IO pins are unexpectedly enabled");

  // 三个输入共有 2^3=8 种组合，全部检查。
  for (int pattern = 0; pattern < 8; pattern++) begin
    io_in = '0;
    io_in[5:3] = pattern[2:0];
    #1ns;

    if (io_out[2:0] !== ~io_in[5:3])
      $fatal(
        1,
        "NOT result incorrect: input=%03b output=%03b expected=%03b",
        io_in[5:3], io_out[2:0], ~io_in[5:3]
      );

    if (io_out[IO_WIDTH-1:3] !== '0)
      $fatal(1, "unused output bits are not zero");
  end

  $display("USER DESIGN 1 UNIT TEST PASS");
  $finish;
end
```

先执行 lint。这个步骤必须保留，因为它会检查用户 RTL 中真实的组合环路和其他
结构问题：

```sh
make design-lint DESIGN=designs/1
```

lint 通过后再运行单元测试：

```sh
make design-test DESIGN=designs/1 TEST=io
```

成功时会看到：

```text
USER DESIGN 1 UNIT TEST PASS
```

## 4. 注册到 FrameTop

独立测试通过后，打开根目录的 `designs/registry.json`，加入 design 1：

```json
{
  "designs": [
    "1/design.json"
  ]
}
```

如果清单中已有其他正式设计，只追加新的一行，不要删除原有条目。然后运行：

```sh
make registry-generate
make registry-check
```

生成器会更新 `rtl/generated/FrameDesignRegistry.sv`。不要手工修改这个生成文件。

## 5. 编写 Frame 集成测试

打开 `designs/1/tests/FrameUserDesign1Tb.sv`，保留模块声明、时钟、三态引脚连接和
`FrameTop dut` 实例，用下面内容替换原来的 `initial begin ... end`：

```systemverilog
initial begin
  // reset 期间通过 user_io[6:0] 选择 design 1。
  test_io_oe[DESIGN_ID_WIDTH-1:0] = '1;
  test_io_out[DESIGN_ID_WIDTH-1:0] = DESIGN_ID;

  repeat (20) @(posedge clock);
  @(negedge clock);
  reset = 1'b0;
  repeat (4) @(posedge clock);
  #1ns;

  if (!dut.selection_valid || !dut.design_selected[DESIGN_ID])
    $fatal(1, "design 1 was not selected through FrameTop");

  // 测试平台驱动 user_io[12:10]，对应设计的 io_in[5:3]。
  test_io_oe[DESIGN_ID_WIDTH + 5 : DESIGN_ID_WIDTH + 3] = 3'b111;

  // 测试平台释放 user_io[9:7]，让设计驱动 io_out[2:0]。
  test_io_oe[DESIGN_ID_WIDTH + 2 : DESIGN_ID_WIDTH] = 3'b000;

  for (int pattern = 0; pattern < 8; pattern++) begin
    test_io_out[
      DESIGN_ID_WIDTH + 5 : DESIGN_ID_WIDTH + 3
    ] = pattern[2:0];
    #1ns;

    if (
      user_io[DESIGN_ID_WIDTH + 2 : DESIGN_ID_WIDTH]
      !== ~pattern[2:0]
    ) begin
      $fatal(
        1,
        "Frame NOT result incorrect: input=%03b output=%03b expected=%03b",
        pattern[2:0],
        user_io[DESIGN_ID_WIDTH + 2 : DESIGN_ID_WIDTH],
        ~pattern[2:0]
      );
    end
  end

  $display("USER DESIGN 1 FRAME TEST PASS");
  $finish;
end
```

测试平台只驱动输入 `user_io[12:10]`，不能驱动输出 `user_io[9:7]`。如果测试
平台和用户设计同时驱动同一引脚，会产生 `x` 或 IO contention。

按顺序运行：

```sh
make design-lint DESIGN=designs/1
make design-frame-test DESIGN=designs/1 TEST=frame
```

成功时会看到：

```text
USER DESIGN 1 FRAME TEST PASS
```

Frame 测试会对双向 IO 产生的框架级 `UNOPTFLAT` 误报做兼容处理，但独立 lint
仍然必须执行，用来发现用户设计内部真实的组合反馈环路。

## 6. 生成并查看波形

```sh
make frame-test DESIGN=designs/1 TEST=frame TRACE=1
gtkwave build/waves/1/frame.fst
```

在 GTKWave 的 SST 窗口中展开：

```text
FrameUserDesign1Tb
└── dut
    └── u_design_registry
        └── u_design_1
            └── u_design
```

重点观察：

- TB 中的 `test_io_out`、`test_io_oe` 和 `user_io`；
- FrameTop 中的 `design_id`、`selection_valid` 和 `payload_*`；
- 用户设计中的 `io_in`、`io_out` 和 `io_oe`。

例如输入为 `3'b101` 时：

```text
io_in[5:3]  = 101
io_out[2:0] = 010
io_oe[2:0]  = 111
```

由于 `io_in` 会读取所有物理引脚，输出引脚也会被回读，所以此时：

```text
io_in[5:0] = 101_010 = 6'h2a
```

这不是接线错误。`io_in[2:0]` 是设计输出 `io_out[2:0]` 在物理引脚上的回读值。

## 7. 提交前检查

```sh
make regression-fast
git diff --check
git status --short
```

需要提交的内容包括 `designs/1/`、`designs/registry.json` 和重新生成的
`rtl/generated/FrameDesignRegistry.sv`。不要提交 `build/` 或 FST 波形。

## 常见错误

- 只有 `io_out[0]` 有输出：误写了 `io_oe[0] = 1'b111`；应写
  `io_oe[2:0] = 3'b111`。
- 输出是 `z`：对应 `io_oe` 没有置 1，或者 design 1 没有成功注册和选中。
- 输出是 `x`：测试平台驱动了设计的输出引脚，造成两个驱动源冲突。
- Frame 测试提示未注册：检查 `designs/registry.json`，再执行
  `make registry-generate`。
- 波形中的 `io_in` 包含输出数据：这是双向 IO 的正常输出回读。
