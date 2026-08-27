# 用户设计仿真与波形

[English](../en/simulation-regression.md)

每个用户设计都声明独立的 RTL、单元测试和 FrameTop 测试。构建输出全部写入
`build/`，不会修改正式 registry。

## 完整检查

```sh
make check DESIGN=designs/counter32
```

该命令依次执行 RTL lint、独立单元测试和经过 `FrameTop` 的集成测试。只有一个
未注册设计时可以省略 `DESIGN`。

需要单独定位失败阶段时，兼容入口仍可使用：

```sh
make user-lint DESIGN=designs/counter32
make user-test DESIGN=designs/counter32
make user-frame-test DESIGN=designs/counter32
```

测试名称来自设计自己的 `design.json`。Frame 测试会选择空闲临时 ID，并在
`build/designs/<name>/frame/selected-id.txt` 中记录实际编号。

## FST 波形

```sh
make trace DESIGN=designs/counter32
make wave DESIGN=designs/counter32
```

测试平台不需要手工添加 `$dumpfile`。构建工具会为 Frame 测试生成临时 trace
hook，所有 hook 和 FST 都位于 `build/`。`wave` 会检查 GTKWave 和波形文件，
并在文件不存在时提示先运行对应的 `trace` 命令。指定测试时，对两个目标使用相同的
`TEST=<name>`。

## 失败行为

Verilator 编译错误、manifest 字段错误和 testbench 的 `$fatal` 都会使命令返回
非零状态。外部测试环境只能驱动设计释放的位，即 `io_oe[n] = 0` 的 payload；
每次 Frame 测试都会自动注入 IO contention monitor。只要测试环境的
`test_io_oe[n + 7]` 与设计的 `io_oe[n]` 同时为 1，无论双方驱动值是否相同，
仿真都会通过 `$fatal` 返回非零状态并打印重叠位 mask。

该检查不依赖 `user_io` 在波形中变成 `x`，因为 Verilator 主要采用二值仿真。
Frame testbench 应保留模板中的 `reset`、`test_io_oe` 和 `dut` 名称，构建时生成的
monitor 使用这些标准连接定位双方的输出使能。
