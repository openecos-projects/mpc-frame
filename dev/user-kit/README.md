# mpc-frame 用户模板

[English](README.en.md)

这是从 `mpc-frame` 开发仓库自动生成的精简用户环境，只包含 FrameTop、设计模板、
必要的构建脚本和双语用户文档。

```sh
make doctor
make create NAME=counter32
make check DESIGN=designs/counter32
make trace DESIGN=designs/counter32
make wave DESIGN=designs/counter32
```

从获取、建分支到交付设计的流程见 [User Kit 指南](docs/cn/user-kit.md)，
电路开发步骤见[中文用户指南](docs/cn/user-guide.md)，外部引脚定义见
[IO 映射](docs/cn/io-map.md)。不要直接修改 `rtl/generated/FrameDesignRegistry.sv`
或 `designs/registry.json`；正式设计编号由框架维护者分配。
