# mpc-frame

[中文说明](README.md)

`mpc-frame` connects independent RTL designs to `FrameTop` through a uniform
66-bit bidirectional payload interface. The supported tool baseline is
Verilator 5.050.

## User workflow

```sh
make doctor
make create NAME=counter32
make check DESIGN=designs/counter32
make trace DESIGN=designs/counter32
make wave DESIGN=designs/counter32
```

Users only edit the generated `designs/<name>/rtl/` and
`designs/<name>/tests/` directories. Follow the
[user design integration guide](docs/en/user-guide.md) and the
[IO mapping](docs/en/io-map.md).

## Repository boundaries

- `FrameTop.sv` and `rtl/`: frame RTL and the generated design registry.
- `designs/template/`: user design template.
- `docs/cn/` and `docs/en/`: path-matched bilingual documentation sources.
- `mk/` and `Makefile`: stable user build interface.
- `Makefile.dev`: registry, regression, reference, and documentation maintenance.
- `dev/tests/`: framework tests, separate from per-design tests.
- `dev/reference/`: system-level reference SoC and acceptance environment.
- `dev/site/`: VitePress theme and site assets.

See the [maintainer release process](docs/en/maintainer-release.md) for the
complete deployment workflow.

Maintainer commands use the separate entry point:

```sh
make -f Makefile.dev dev-help
make -f Makefile.dev stage9-test
make -f Makefile.dev regression-fast
make -f Makefile.dev docs-site-check
make -f Makefile.dev export-user-kit
```

The user distribution is generated from the `dev/user-kit.json` allowlist.
CI, rather than manual edits, should update the `release/user-kit` branch.
