# mpc-frame

[English](README.en.md)

`mpc-frame` 用统一的 66 位双向 payload 接口，将多个独立 RTL 设计接入
`FrameTop`。当前工具基线是 Verilator 5.050。

## 用户流程

```sh
make doctor
make create NAME=counter32
make check DESIGN=designs/counter32
make trace DESIGN=designs/counter32
make wave DESIGN=designs/counter32
```

用户只需要修改生成的 `designs/<name>/rtl/` 和 `designs/<name>/tests/`。
完整步骤见[用户设计接入指南](docs/cn/user-guide.md)，引脚契约见
[IO 映射](docs/cn/io-map.md)。

## 仓库边界

- `FrameTop.sv`、`rtl/`：Frame 核心 RTL、生成的设计 registry，以及已提交的
  `rtl/generated/user-designs.f` 源码 filelist。
- `designs/template/`：用户设计模板。
- `docs/cn/`、`docs/en/`：路径一一对应的双语文档源。
- `mk/`、`Makefile`：稳定的用户构建入口。
- `Makefile.dev`：registry、全量回归、reference 和文档站点等维护入口。
- `dev/tests/`：框架自身测试，不属于用户设计测试。
- `dev/reference/`：系统级参考 SoC 和独立验收环境。
- `dev/site/`：VitePress 主题和站点资源。

完整部署步骤见[维护者发布流程](docs/cn/maintainer-release.md)。

维护者命令通过独立入口执行：

```sh
make -f Makefile.dev dev-help
make -f Makefile.dev stage9-test
make -f Makefile.dev regression-fast
make -f Makefile.dev docs-site-check
make -f Makefile.dev export-user-kit
```

用户发行内容由 `dev/user-kit.json` 白名单生成。`release/user-kit` 分支应由
CI 更新，不应手工维护。
