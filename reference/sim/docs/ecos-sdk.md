# 软件 SDK 流程（ECOS-SDK）

`sw/ecos/` 是仓库内的 `mpc-soc` BSP package 根目录。合入 ECOS-SDK 时，将 `sw/ecos/` 的内容复制或合并到 `$(ECOS_SDK_HOME)/board/mpc-soc/`。

## 命令

```sh
make -C sw info
make -C sw list
make -C sw BOARD=mpc-soc APP=hello ECOS_SDK=/path/to/ecos-sdk CROSS_COMPILE=riscv64-unknown-elf-
```

如果 SDK 工具链需要更具体的 ISA 字符串，可以覆盖 `ARCH_FLAGS`，例如 `-march=rv32im_zicsr -mabi=ilp32`。

## 可合入 SDK 的包内容

- `sw/ecos/ecos-board.yml`：SDK 板卡发现使用的 BSP package manifest。
- `sw/ecos/Makefile`：SDK board-package 构建入口。
- `sw/ecos/build_conf.mk`：由配置驱动的驱动选择和构建选项。
- `sw/ecos/board.kconfig`：板卡、内存、时钟和链接模式 Kconfig。
- `sw/ecos/driver.kconfig`：外设驱动 Kconfig。
- `sw/ecos/board.h`：板级寄存器映射和声明。
- `sw/ecos/start.S`：固件启动代码。
- `sw/ecos/sections.lds`：固件链接脚本。
- `sw/ecos/driver/`：板级外设驱动。
- `sw/ecos/loader/`：可选 bootloader wrapper。

## 本仓库本地包装

- `sw/Makefile`：本仓库使用的本地构建入口。
- `sw/ecos.mk`：本地 SDK 和工具链路径适配层。
- `build/sw/mpc-soc/<app>/`：本地生成的 ELF、binary、dump 和 map 输出。

合入 ECOS-SDK 时，创建 `$(ECOS_SDK_HOME)/board/mpc-soc/`，并将 `sw/ecos/` 的内容复制或合并到该目录。
