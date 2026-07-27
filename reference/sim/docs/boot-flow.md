# 启动流程

Verilator 流程从 `build/sw/<board>/<app>/` 读取软件原始二进制镜像，并通过 `+bootrom=<path>` 传给仿真 harness。

## 模板流程

1. 复位后进入 SoC 启动地址，取指路径走 SPI flash。
2. 仿真 harness 通过 `+bootrom=<path>` 传入原始 flash 镜像路径。
3. RTL 发起 SPI flash 读访问时，flash DPI 模型从该镜像读取字节。
4. `sw/ecos/start.S` 中的启动代码初始化栈、清零 `.bss`，然后调用 `main`。
5. 平台驱动使用 `sw/ecos/` 下的 board-package 头文件。

Verilator 仿真应使用 `.bin` 镜像。传入 ELF 文件时，仿真会把 ELF 容器字节当作 flash 内容加载。
