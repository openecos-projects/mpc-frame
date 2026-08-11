# 维护者发布流程

[English](../en/maintainer-release.md)

本文只面向 `mpc-frame` 维护者，不属于用户站点或 User Kit 发行内容。

## 仓库设置

在 GitHub `Settings > Actions > General` 中为 workflow 启用读写权限。Pages 的
Source 设置为 GitHub Actions。`release/user-kit` 必须允许 User Kit workflow
进行强制更新，不需要提前手工创建该分支。

## 合并前验证

```sh
make -f Makefile.dev docs-check
make -f Makefile.dev stage9-test
make -f Makefile.dev regression-fast
make -f Makefile.dev reference-test
make -f Makefile.dev docs-site-check
make -f Makefile.dev export-user-kit
```

还应在 `build/user-kit` 中运行一次 `doctor/create/check/trace/wave`，并确认生成的
FST 非空，以验证导出包没有依赖开发仓库内容，波形链路也可以独立工作。测试后
必须重新导出干净 User Kit，再检查其中没有 `build/` 和 smoke design。

## 发布调用链

合并并 push 到 `main` 后：

```text
CI                     -> 源码、Frame 和 reference 回归
Documentation Pages    -> 仅构建 dev/site-docs.json 允许的用户页面
User Kit               -> 导出、验证并覆盖 release/user-kit
```

User Kit workflow 同时上传保留 14 天的 `mpc-frame-user-kit` artifact。

## 发布边界

- `dev/site-docs.json` 是公共站点页面白名单。
- `dev/user-kit.json` 是 User Kit 文件白名单；公共文档直接复用
  `dev/site-docs.json`，避免新增维护者文档时意外进入发行包。
- `docs/cn` 与 `docs/en` 保存全部双语源码，包括不发布的维护者资料。
- `dev/site` 只保存主题、配置和静态资源，不保存第二份 Markdown。

修改白名单后必须运行 `docs-site-check` 和导出包 smoke test。

## 接收用户设计

用户交付单个 `designs/<name>/` package。维护者检查后执行：

```sh
make -f Makefile.dev integrate-design \
  DESIGN=designs/<name> DESIGN_ID=<1..127>
make -f Makefile.dev regression-fast
make -f Makefile.dev reference-test
```

不要要求用户在 User Kit 中修改正式 registry 或选择最终 ID。

## 已知限制

`release/user-kit` 当前是自动覆盖的 orphan 分支，适合发行下载，但不支持用户从
该分支直接向 `main` 创建普通 PR。若以后以 PR 为主要贡献入口，应改用独立模板
仓库和自动导入流程，或重新设计带共享历史的发行方式。
