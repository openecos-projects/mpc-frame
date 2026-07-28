# Software SDK Flow (ECOS-SDK)

[中文说明](ecos-sdk.md)

`sw/ecos/` is the in-repository `mpc-soc` BSP package. To integrate it with
ECOS-SDK, copy or merge its contents into
`$(ECOS_SDK_HOME)/board/mpc-soc/`.

## Commands

```sh
make -C sw info
make -C sw list
make -C sw BOARD=mpc-soc APP=hello ECOS_SDK=/path/to/ecos-sdk CROSS_COMPILE=riscv64-unknown-elf-
```

Override `ARCH_FLAGS` when a toolchain needs an explicit ISA string, for example
`-march=rv32im_zicsr -mabi=ilp32`.

## Package contents

- `ecos-board.yml`: BSP discovery manifest
- `Makefile`: SDK board-package entry
- `build_conf.mk`: selected drivers and build options
- `board.kconfig` and `driver.kconfig`: board and driver configuration
- `board.h`: register map and declarations
- `start.S` and `sections.lds`: startup and linker script
- `driver/`: peripheral drivers
- `loader/`: optional bootloader wrapper

## Local repository wrapper

- `sw/Makefile`: local build entry
- `sw/ecos.mk`: local SDK/toolchain adapter
- `build/sw/mpc-soc/<app>/`: generated ELF, binary, dump, and map files
