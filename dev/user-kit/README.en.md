# mpc-frame User Kit

[中文说明](README.md)

This is the generated, user-facing subset of the `mpc-frame` maintainer
repository. It contains FrameTop, the design template, required build tools,
and bilingual user documentation.

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
