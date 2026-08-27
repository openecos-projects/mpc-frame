# mpc-frame User Kit

[中文说明](README.md)

This is the generated, user-facing subset of the `mpc-frame` maintainer
repository. It contains FrameTop, the design template, required build tools,
and bilingual user documentation.
The root-level `FRAME_VERSION` records the frame format and source commit.
The 128-design capacity belongs to maintainer integration; a user normally
develops and submits one design package.

The distribution root contains only `.gitignore`, `FRAME_VERSION`,
`FrameTop.sv`, `Makefile`, the bilingual READMEs, and the `designs/`, `docs/`,
`mk/`, `rtl/`, and `scripts/` directories. `build/` is not distribution
content; it is generated locally only after checks or simulation and is ignored
by `.gitignore`.

```sh
make doctor
make create NAME=counter32
make check DESIGN=designs/counter32
make trace DESIGN=designs/counter32
make wave DESIGN=designs/counter32
```

Start with [Getting and Using the User Kit](docs/en/user-kit.md), then follow
the [English user guide](docs/en/user-guide.md) and the
[IO mapping](docs/en/io-map.md). Do not edit
`rtl/generated/FrameDesignRegistry.sv` or `designs/registry.json`; maintainers
assign permanent design IDs.
