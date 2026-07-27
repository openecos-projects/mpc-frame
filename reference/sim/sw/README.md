# 软件

`sw/ecos/` 是仓库内的 `mpc-soc` BSP package 根目录。本仓库的本地软件包装会把 Verilator 可用的二进制产物写到 `build/sw/<board>/<app>/`。

```text
sw/
└── ecos/
    ├── ecos-board.yml
    ├── driver/
    └── templates/
```

## 本地 SDK 构建

```sh
make -C sw info
make -C sw list BOARD=mpc-soc
make -C sw BOARD=mpc-soc APP=hello
```

## 输入镜像（Verilator）

默认 Verilator 输入是 `build/sw/mpc-soc/hello/hello.bin`。使用以下命令生成：

```sh
make -C sw BOARD=mpc-soc APP=hello
```

也可以通过 `BOOTROM_IMAGE=<path>.bin` 传入其他原始二进制镜像。
