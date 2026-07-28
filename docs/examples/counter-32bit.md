# 32 位计数器用户设计接入示例

[English](counter-32bit.en.md)

本文用一个每个时钟加一的 32 位计数器，演示时序逻辑如何接入 FrameTop。计数值
直接输出到 32 根用户 IO：

```text
clock 上升沿 -> counter + 1 -> io_out[31:0]
reset = 1     -> counter = 0
```

内部 IO 与外部引脚的关系为：

| 用途 | 用户设计内部 | FrameTop 外部 |
| --- | --- | --- |
| 32 位计数值 | `io_out[31:0]` | `user_io[38:7]` |
| design 编号 | 用户设计不可见 | `user_io[6:0]` |

本例没有外部输入，全部 32 根计数值引脚都由设计驱动。本示例使用 design ID 2；
如果编号 2 已被占用，请换成其他未注册编号，并同步替换命令、文件名和 design ID。

## 1. 创建设计

在仓库根目录运行：

```sh
make create-design DESIGN_ID=2
```

命令会创建：

```text
designs/2/
├── README.md
├── README.en.md
├── design.json
├── rtl/UserDesign2.sv
└── tests/
    ├── UserDesign2Tb.sv
    └── FrameUserDesign2Tb.sv
```

`UserDesign2Tb.sv` 直接测试计数器；`FrameUserDesign2Tb.sv` 测试计数值经过
FrameTop 后能否从外部引脚正确读出。

## 2. 编写 32 位计数器

用以下内容替换 `designs/2/rtl/UserDesign2.sv`：

```systemverilog
module UserDesign2 #(
  parameter int IO_WIDTH = 66
) (
  input  logic                clock,
  input  logic                reset,
  input  logic [IO_WIDTH-1:0] io_in,
  output logic [IO_WIDTH-1:0] io_out,
  output logic [IO_WIDTH-1:0] io_oe
);

  logic [31:0] counter;

  // reset 是同步高电平复位，只在 clock 上升沿生效。
  always_ff @(posedge clock) begin
    if (reset)
      counter <= 32'b0;
    else
      counter <= counter + 32'd1;
  end

  always_comb begin
    io_out = '0;
    io_oe  = '0;

    io_out[31:0] = counter;
    io_oe[31:0]  = 32'hffff_ffff;
  end

endmodule
```

`always_ff` 表示这个代码块描述触发器，只在指定的时钟边沿更新状态。这里使用
非阻塞赋值 `<=`，使 `counter` 表现为真正的寄存器。

`io_in` 在本例中没有使用，但它属于固定接口，不能删除。`io_oe[31:0]` 全部为 1，
表示设计持续驱动这 32 根输出引脚；其余 IO 保持释放。

## 3. 编写单元测试

打开 `designs/2/tests/UserDesign2Tb.sv`，保留模块声明、时钟、信号和
`UserDesignDut` 实例，用下面内容替换原来的 `initial begin ... end`：

```systemverilog
initial begin
  logic [31:0] expected;

  io_in = '0;

  // reset 初始为 1。保持两个时钟，计数器应一直为 0。
  repeat (2) @(posedge clock);
  #1ns;
  if (io_out[31:0] !== 32'b0)
    $fatal(1, "counter did not reset: actual=%08h", io_out[31:0]);

  if (io_oe[31:0] !== 32'hffff_ffff)
    $fatal(1, "counter outputs are not enabled");

  if (io_oe[IO_WIDTH-1:32] !== '0)
    $fatal(1, "unused IO pins are unexpectedly enabled");

  // 在下降沿释放复位，避免与上升沿采样发生竞争。
  @(negedge clock);
  reset = 1'b0;
  expected = 32'b0;

  // 连续检查 10 个时钟，每个时钟必须严格加一。
  repeat (10) begin
    @(posedge clock);
    expected = expected + 32'd1;
    #1ns;
    if (io_out[31:0] !== expected)
      $fatal(
        1,
        "counter incorrect: actual=%08h expected=%08h",
        io_out[31:0], expected
      );
  end

  // 再次拉高 reset，确认计数器能够回到 0。
  @(negedge clock);
  reset = 1'b1;
  @(posedge clock);
  #1ns;
  if (io_out[31:0] !== 32'b0)
    $fatal(1, "counter did not reset a second time");

  $display("USER DESIGN 2 COUNTER UNIT TEST PASS");
  $finish;
end
```

先运行独立 lint，再运行测试：

```sh
make design-lint DESIGN=designs/2
make design-test DESIGN=designs/2 TEST=io
```

成功时会看到：

```text
USER DESIGN 2 COUNTER UNIT TEST PASS
```

测试在时钟上升沿之后等待 `#1ns` 再读取结果，是为了让非阻塞赋值完成更新。

## 4. 注册到 FrameTop

独立测试通过后，在根目录的 `designs/registry.json` 中加入 design 2：

```json
{
  "designs": [
    "2/design.json"
  ]
}
```

如果已有其他正式设计，只追加条目，不要删除原有内容。然后运行：

```sh
make registry-generate
make registry-check
```

不要手工修改生成的 `rtl/generated/FrameDesignRegistry.sv`。

## 5. 编写 Frame 集成测试

打开 `designs/2/tests/FrameUserDesign2Tb.sv`，保留模块声明、时钟、三态连接和
`FrameTop dut` 实例，用下面内容替换原来的 `initial begin ... end`：

```systemverilog
initial begin
  logic [31:0] count_snapshot;
  logic [31:0] expected;

  // reset 期间通过 user_io[6:0] 选择 design 2。
  test_io_oe[DESIGN_ID_WIDTH-1:0] = '1;
  test_io_out[DESIGN_ID_WIDTH-1:0] = DESIGN_ID;

  repeat (20) @(posedge clock);
  @(negedge clock);
  reset = 1'b0;
  repeat (4) @(posedge clock);
  #1ns;

  if (!dut.selection_valid || !dut.design_selected[DESIGN_ID])
    $fatal(1, "design 2 was not selected through FrameTop");

  // user_io[38:7] 是设计的 io_out[31:0]。测试平台必须保持释放。
  test_io_oe[
    DESIGN_ID_WIDTH + 31 : DESIGN_ID_WIDTH
  ] = 32'b0;

  // FrameTop 内部复位的释放时刻由选择流程决定，因此先读取当前值，
  // 再检查后续每个时钟是否加一，而不假设当前绝对值。
  count_snapshot = user_io[
    DESIGN_ID_WIDTH + 31 : DESIGN_ID_WIDTH
  ];
  if ($isunknown(count_snapshot))
    $fatal(1, "Frame counter output contains x or z");

  expected = count_snapshot;

  repeat (10) begin
    @(posedge clock);
    expected = expected + 32'd1;
    #1ns;
    if (
      user_io[DESIGN_ID_WIDTH + 31 : DESIGN_ID_WIDTH]
      !== expected
    ) begin
      $fatal(
        1,
        "Frame counter incorrect: actual=%08h expected=%08h",
        user_io[DESIGN_ID_WIDTH + 31 : DESIGN_ID_WIDTH],
        expected
      );
    end
  end

  $display("USER DESIGN 2 COUNTER FRAME TEST PASS");
  $finish;
end
```

这里不能让测试平台驱动 `user_io[38:7]`，因为计数器已经通过
`io_oe[31:0]` 驱动这些引脚。双方同时驱动会产生 `x` 或 IO contention。

运行：

```sh
make design-lint DESIGN=designs/2
make design-frame-test DESIGN=designs/2 TEST=frame
```

成功时会看到：

```text
USER DESIGN 2 COUNTER FRAME TEST PASS
```

## 6. 生成并查看波形

```sh
make frame-test DESIGN=designs/2 TEST=frame TRACE=1
gtkwave build/waves/2/frame.fst
```

在 GTKWave 的 SST 窗口中展开：

```text
FrameUserDesign2Tb
└── dut
    └── u_design_registry
        └── u_design_2
            └── u_design
```

建议观察：

- `clock` 和 `reset`；
- FrameTop 中的 `selection_valid` 和 `design_selected[2]`；
- 用户设计中的 `counter`、`io_out[31:0]` 和 `io_oe[31:0]`；
- TB 中的 `user_io[38:7]`。

正常波形应当表现为：

```text
clock 上升沿:    1    2    3    4
counter:         1    2    3    4
io_out[31:0]:    1    2    3    4
user_io[38:7]:   1    2    3    4
```

在 `reset=1` 的有效时钟边沿之后，`counter` 应回到 0。由于这是同步复位，单独
改变 `reset` 而没有时钟上升沿时，计数值不会立即改变。

## 7. 提交前检查

```sh
make regression-fast
make docs-check
git diff --check
git status --short
```

需要提交 `designs/2/`、`designs/registry.json` 和重新生成的 registry RTL。
不要提交 `build/` 或 FST 波形。

## 常见错误

- 计数器一直为 0：`reset` 没有释放，或设计没有被 FrameTop 选中。
- 第一次检查差一：在上升沿读取过早；等待 `#1ns` 后再检查非阻塞赋值结果。
- 输出为 `z`：没有把 `io_oe[31:0]` 置 1。
- 输出为 `x`：测试平台也在驱动 `user_io[38:7]`，与设计发生冲突。
- 使用 `always_comb` 编写计数器：组合逻辑不能保存上一个计数值，应使用
  `always_ff @(posedge clock)`。
- 拉高 reset 后数值没有立即归零：本例使用同步复位，要等下一个时钟上升沿。
