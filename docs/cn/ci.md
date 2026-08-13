# 持续集成

[English](../en/ci.md)

根工程使用 `.github/workflows/ci.yml` 执行固定的 Ubuntu 24.04 单平台 CI，
不使用构建缓存和多平台矩阵。Verilator 固定为 5.050，并从官方 tag 构建；
reference 固件使用发行版提供的 `riscv64-unknown-elf` 工具链。

CI 和本地用户流程都固定使用 5.050，以获得一致且可重复的结果。根 Makefile
仍会对非关键警告参数先做能力检测。

文档站使用独立的 `.github/workflows/pages.yml`。它以 Node.js 24 构建 VitePress
静态文件，不会把开发服务器部署到公网。

## 自动门禁

提交到 `main` 或向 `main` 提交 pull request 时运行三个独立检查：

- `source-check`：检查 Python、manifest 负向测试、registry/filelist，以及已提交
  生成文件是否最新；同时禁止提交 `build/` 和 QA 记录。
- `frame-regression`：运行 `make -f Makefile.dev regression-fast`，覆盖根 lint、控制面、IO
  争用以及全部注册用户设计的独立和 FrameTop 测试。
- `reference-regression`：运行 `make -f Makefile.dev reference-test`，覆盖 Flash 启动、UART
  收发、两组 GPIO 和 PSRAM 读写；默认等待测试完成。

建议在 GitHub 的 `main` branch protection 中将上述三个 job 设为 required
status checks，并要求分支在合并前保持最新。PR 工作流只有源码读取权限，不使用
仓库 secret。

回归失败时会保留七天日志 artifact。并发提交到同一分支时，旧工作流会被取消。

## 手动波形

在 GitHub Actions 中手动运行 `CI`，填写 `design` 和 `test`。该入口执行：

```sh
make -f Makefile.dev frame-test DESIGN=<design> TEST=<test> TRACE=1
```

日志和 `build/waves/` 下的 FST 作为 artifact 保留七天。reference 设计使用
`design=0`，测试名可选 `boot`、`uart`、`gpio` 或 `psram`。

## 文档站部署

文档、主题或站点构建脚本发生变化时，`Documentation Pages` 工作流会先运行：

```sh
make -f Makefile.dev docs-site-check
```

pull request 只构建并验证站点。合并到 `main` 后，工作流把
`build/docs-site/.vitepress/dist` 上传为 Pages artifact，再部署到
`https://openecos-projects.github.io/mpc-frame/`。仓库第一次启用时，需要在 GitHub
的 `Settings > Pages > Build and deployment` 中把 Source 设为 `GitHub Actions`。
