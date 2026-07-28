# 用户设计接入指南

本流程不需要修改 `FrameTop.sv`、`rtl/` 或 reference 代码。用户只维护自己的
design package，并在准备集成时更新 `designs/registry.json`。

## 1. 创建 package

先选择尚未注册的 ID：

```sh
make create-design DESIGN_ID=3
```

默认生成 `designs/3/`，顶层名为 `UserDesign3`。也可以指定名称和模块名：

```sh
make create-design DESIGN_ID=3 DESIGN_NAME=uart-demo DESIGN_MODULE=UartDemo
```

命令会拒绝 design 0、超出 1..127 的编号、已注册编号、非法模块名以及已有输出
目录，不会覆盖用户文件。

## 2. 实现和独立测试

生成目录包含：

```text
designs/3/
├── design.json
├── README.md
├── rtl/UserDesign3.sv
└── tests/
    ├── UserDesign3Tb.sv
    └── FrameUserDesign3Tb.sv
```

替换 RTL 中的示例逻辑并同步修改 unit test。设计顶层的标准接口是：

```systemverilog
input  logic              clock;
input  logic              reset;
input  logic [65:0]       io_in;
output logic [65:0]       io_out;
output logic [65:0]       io_oe;
```

独立验证不需要注册，也不会编译其他用户设计或 reference SoC：

```sh
make design-lint DESIGN=designs/3
make design-test DESIGN=designs/3 TEST=io
```

## 3. 注册到 FrameTop

将 package manifest 加入 `designs/registry.json`：

```json
{
  "designs": [
    "1/design.json",
    "2/design.json",
    "3/design.json"
  ]
}
```

重新生成并验证集成文件：

```sh
make registry-generate
make registry-check
make design-frame-test DESIGN=designs/3 TEST=frame
```

`rtl/generated/FrameDesignRegistry.sv` 是确定性生成文件，必须与
`designs/registry.json` 和 package 一起提交，不要手工修改。

## 4. 提交前验收

```sh
make regression-fast
```

该命令遍历 registry 中全部 package，执行根 lint、控制面、IO 争用、每个设计的
lint、unit test 和 FrameTop test。调试波形可通过以下命令生成：

```sh
make frame-test DESIGN=designs/3 TEST=frame TRACE=1
```

FST 位于 `build/waves/3/frame.fst`。IO 编号和选择时序见 [IO 映射](io-map.md)，
manifest 全部字段见 [用户设计注册](user-design-registration.md)。

## 常见错误

- `design is not listed`：package 尚未加入 `designs/registry.json`。
- `generated file is stale`：执行 `make registry-generate` 并提交生成结果。
- `duplicate design id`：两个注册 package 使用了相同 ID。
- `mapped port ... was not found`：`module` 或 `ports` 与 RTL 顶层不一致。
- `path escapes the design package`：manifest 源码路径越过了当前 package 边界。
- pad 显示 `z`：检查对应 `io_oe` 是否置 1，以及当前 design ID 是否已注册并选中。
