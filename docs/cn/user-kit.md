# User Kit 获取与使用

[English](../en/user-kit.md)

User Kit 是 `mpc-frame` 面向普通设计用户的精简发行版本。它只包含 FrameTop、
用户设计模板、必要构建工具和用户文档，不包含 reference SoC、框架内部测试、
文档站点源码或维护者回归入口。发行包中的 registry 和生成 filelist 会重置为空
的用户开发框架，维护者主仓库中已经注册的设计不会被复制到 User Kit。
每次导出还会包含 `FRAME_VERSION`，记录框架格式版本和生成该发行包的源码提交。
`128` 个设计是单个 `FrameTop` 在维护者集成阶段的容量上限。普通 User Kit
项目只需开发并交付一个 `designs/<name>/` package，用户不需要创建 128 个设计，
也不需要在本地填充 registry。

## 发行包边界

干净的 User Kit 根目录只包含：

```text
.gitignore
FRAME_VERSION
FrameTop.sv
Makefile
README.md
README.en.md
designs/
docs/
mk/
rtl/
scripts/
```

`build/` 不属于发行包。它只会在用户运行检查、仿真或波形命令后在本地生成，
并由 User Kit 根目录的 `.gitignore` 排除。发行分支中也不包含 `dev/`、
`Makefile.dev`、reference SoC、框架内部测试或站点维护源码。

## 获取 User Kit

用户不需要 clone `main`。在维护者完成首次发布后，直接获取只读发行分支：

```sh
git clone --branch release/user-kit --single-branch \
  https://github.com/openecos-projects/mpc-frame.git my-frame-design
cd my-frame-design
```

GitHub Actions 页面也会提供名为 `mpc-frame-user-kit` 的临时 artifact。正常开发
优先使用 `release/user-kit`，因为 artifact 只保留有限时间。

## 建立自己的开发分支

上游 `release/user-kit` 由自动化流程覆盖更新，不要直接在该分支长期开发：

```sh
git switch -c user/counter32
```

需要推送到自己的仓库时：

```sh
git remote rename origin upstream
git remote add origin https://github.com/<user>/<project>.git
git push -u origin user/counter32
```

## 检查工具

User Kit 要求 Python 3、GNU Make、C++ 编译器和 Verilator 5.050：

```sh
make doctor
```

如果 5.050 没有位于默认 `PATH`：

```sh
make doctor VERILATOR=/path/to/verilator
```

## 开发一个设计

```sh
make create NAME=counter32
make check DESIGN=designs/counter32
make trace DESIGN=designs/counter32
make wave DESIGN=designs/counter32
```

创建命令生成 RTL、`design.json`、独立单元测试和 FrameTop 集成测试。具体接口、
测试修改方式和 IO 规则见[用户设计接入指南](user-guide.md)与
[IO 映射](io-map.md)。

只有一个未注册设计时可以简写为：

```sh
make check
make trace
make wave
```

存在多个未注册设计时必须明确传入 `DESIGN=designs/<name>`。

## 更新 User Kit

`release/user-kit` 是自动生成并强制更新的发行分支，目前没有自动升级命令。
升级时建议重新获取一份干净版本，再复制自己的设计 package：

```sh
git clone --branch release/user-kit --single-branch \
  https://github.com/openecos-projects/mpc-frame.git mpc-frame-new
cp -a my-frame-design/designs/counter32 mpc-frame-new/designs/
cd mpc-frame-new
make check DESIGN=designs/counter32
```

不要直接把上游发行分支强制合并到已有设计仓库。

## 交付设计

用户只需要交付：

```text
designs/<name>/
```

不要修改 `designs/registry.json`、`rtl/generated/FrameDesignRegistry.sv`、
`FrameTop.sv` 或框架 RTL。正式 design ID 由维护者集成时分配。

当前发行分支与开发主线没有共享提交历史，因此不能直接从 User Kit 分支向
`main` 创建普通 PR。请提交完整的 `designs/<name>/` 目录，或按项目约定提供
对应压缩包和补丁。

## 清理

```sh
make clean
```

该命令只删除 `build/` 中的生成文件，不会删除用户设计源码。
