# Software

[中文说明](README.md)

`sw/ecos/` is the in-repository `mpc-soc` BSP package. The local wrapper writes
Verilator-ready binaries under `build/sw/<board>/<app>/`.

```text
sw/
└── ecos/
    ├── ecos-board.yml
    ├── driver/
    └── templates/
```

## Local build

Reference firmware uses the in-repository BSP and a
`riscv64-unknown-elf` toolchain; no external eCos SDK is required.

```sh
make -C sw info
make -C sw list BOARD=mpc-soc
make -C sw BOARD=mpc-soc APP=hello
```

## Verilator input image

The default image is `build/sw/mpc-soc/hello/hello.bin`, generated with:

```sh
make -C sw BOARD=mpc-soc APP=hello
```

Pass another raw binary with `BOOTROM_IMAGE=<path>.bin`.
