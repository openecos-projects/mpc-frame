# 架构说明

## 源码组织

- `hw/soc/top/` 存放 SoC 集成顶层。
- `hw/soc/bus/`、`hw/soc/reset/` 和 `hw/soc/clock/` 预留给 SoC 级总线、复位和时钟集成逻辑。
- `hw/ip/` 存放可复用 IP，每个 IP 可以包含自己的 `rtl/`、`tb/` 或 `dv/`、`driver/` 和 `doc/` 目录。
- `hw/common/` 存放迁移 IP Makefile 复用的 RTL 公共工具。
- `hw/ip/` 同时保留 SoC 仍在使用的兼容实现，例如 `hw/ip/spi/legacy_apb/`。

## 配置来源

- `config/soc.yml` 描述模板 SoC 顶层和选用的 IP 路径。
- `config/memory.yml` 是生成 RTL package 和 C 头文件的内存映射来源。
- `config/boards/sim.yml` 描述仿真板级默认配置。

## 集成流程

1. SoC 集成顶层保持在 `hw/soc/top/` 下；新增或重命名模块时同步更新 `hw/filelist/verilator.f`。
2. 顶层总线、时钟、复位和中断连线放在 `hw/soc/` 下。
3. 同步更新 `hw/filelist/soc.f` 和 `hw/filelist/verilator.f`。
4. 内存映射变化时，从 `config/memory.yml` 重新生成 `hw/include/soc_pkg.sv`，并同步 `sw/ecos/board.h`。

CPU 替换或 bring-up 工作请遵循 `docs/custom-core.md` 中描述的 core slot 和 AXI 接口约定。
