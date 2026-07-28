# 持续集成

根工程使用 `.github/workflows/ci.yml` 执行固定的 Ubuntu 24.04 单平台 CI，
不使用构建缓存和多平台矩阵。Verilator 固定为 5.050，并从官方 tag 构建；
reference 固件使用发行版提供的 `riscv64-unknown-elf` 工具链。

CI 固定 5.050 是为了得到可重复的结果，不代表用户必须安装完全相同的版本。
本地用户流程也验证过 5.032；根 Makefile 会对非关键警告参数先做能力检测。

## 自动门禁

提交到 `main` 或向 `main` 提交 pull request 时运行三个独立检查：

- `source-check`：检查 Python、manifest 负向测试、registry/filelist，以及已提交
  生成文件是否最新；同时禁止提交 `build/` 和 QA 记录。
- `frame-regression`：运行 `make regression-fast`，覆盖根 lint、控制面、IO
  争用以及全部注册用户设计的独立和 FrameTop 测试。
- `reference-regression`：运行 `make reference-test`，覆盖 Flash 启动、UART
  收发、两组 GPIO 和 PSRAM 读写。

建议在 GitHub 的 `main` branch protection 中将上述三个 job 设为 required
status checks，并要求分支在合并前保持最新。PR 工作流只有源码读取权限，不使用
仓库 secret。

回归失败时会保留七天日志 artifact。并发提交到同一分支时，旧工作流会被取消。

## 手动波形

在 GitHub Actions 中手动运行 `CI`，填写 `design` 和 `test`。该入口执行：

```sh
make frame-test DESIGN=<design> TEST=<test> TRACE=1
```

日志和 `build/waves/` 下的 FST 作为 artifact 保留七天。reference 设计使用
`design=0`，测试名可选 `boot`、`uart`、`gpio` 或 `psram`。
