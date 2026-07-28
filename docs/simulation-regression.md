# FrameTop 仿真与回归

[English](simulation-regression.en.md)

根工程统一测试入口负责调度，不要求所有设计使用同一种 harness。用户设计继续使用包内 SystemVerilog testbench，reference design 继续使用包含 Flash、PSRAM、UART 和 GPIO 模型的 C++ harness。

## 单项 FrameTop 测试

运行当前未注册用户设计：

```sh
make user-frame-test
```

运行 reference 测试：

```sh
make frame-test DESIGN=0 TEST=boot
make frame-test DESIGN=0 TEST=uart
make frame-test DESIGN=0 TEST=gpio
make frame-test DESIGN=0 TEST=psram
```

用户测试名称来自各包的 `design.json`。reference 测试名称和仿真参数来自 `reference/sim/tests.json`。

## 回归层次

开发阶段使用快速回归：

```sh
make regression-fast
```

它执行根 RTL lint、manifest 负向测试、控制面和 IO 争用测试，并遍历 `designs/registry.json` 中的全部设计，运行每个设计的 lint、全部 unit test 和全部 frame test。

提交前使用完整回归：

```sh
make regression
```

完整回归包含快速回归，并增加 reference Flash 启动、UART 收发、GPIO 和 PSRAM 测试。

## 日志与波形

所有统一入口日志写入：

```text
build/logs/root/
build/logs/designs/<name>/
build/logs/reference/
```

默认不生成波形。传入 `TRACE=1` 后生成 FST：

```sh
make user-frame-test TRACE=1
make frame-test DESIGN=0 TEST=boot TRACE=1
make regression-fast TRACE=1
```

波形路径为：

```text
build/waves/<design-id>/<test>.fst
build/waves/reference/<test>.fst
```

用户 testbench 不需要添加 `$dumpfile`。构建工具会为 frame test 生成临时 trace hook；该文件和所有波形均位于 `build/`，不提交到仓库。

## 失败行为

调度器为每个步骤保留独立日志，并在结束时列出所有失败步骤。manifest 或 reference 测试清单格式错误会在启动 Verilator 前失败。注册用户设计必须至少声明一个 unit test 和一个 frame test。

FrameTop 不仲裁芯片外部的电气争用。外部环境只能驱动当前设计 `io_oe=0` 的 payload 位；同时驱动不同电平属于接口违规。`make io-contention-test` 验证回归 monitor 能区分合法输入驱动和冲突输出驱动。
