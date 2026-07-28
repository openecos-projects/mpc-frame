# Continuous Integration

[中文说明](ci.md)

The root project uses `.github/workflows/ci.yml` on Ubuntu 24.04 without a
build cache or platform matrix. CI builds Verilator 5.050 from its official tag
and uses the distribution `riscv64-unknown-elf` toolchain for reference firmware.

Pinning 5.050 makes CI reproducible; local users may use the tested 5.032 release.
The root Makefile probes nonessential warning options before using them.

The documentation site uses the separate `.github/workflows/pages.yml` workflow.
It builds static VitePress files with Node.js 24 and never deploys the development
server.

## Automatic gates

Pushes and pull requests to `main` run three jobs:

- `source-check`: checks Python, negative manifest tests, registry/filelists,
  generated source freshness, and rejects committed build or QA output.
- `frame-regression`: runs `make regression-fast` for root lint, control, IO
  contention, and every registered user design's standalone and Frame tests.
- `reference-regression`: runs `make reference-test` for Flash boot, UART, both
  GPIO groups, and PSRAM.

These jobs should be required by `main` branch protection. Pull request jobs
have read-only repository permissions and use no repository secrets. Failure
logs are retained as artifacts for seven days, and an older run is cancelled
when a newer commit arrives on the same branch.

## Manual waveforms

Run the `CI` workflow manually and provide `design` and `test`. It executes:

```sh
make frame-test DESIGN=<design> TEST=<test> TRACE=1
```

Logs and FST files under `build/waves/` are retained for seven days. For the
reference design use `design=0` and one of `boot`, `uart`, `gpio`, or `psram`.

## Documentation deployment

Changes to documentation, the theme, or site build scripts trigger the
`Documentation Pages` workflow, which first runs:

```sh
make docs-site-check
```

Pull requests only build and validate the site. After a merge to `main`, the
workflow uploads `build/docs-site/.vitepress/dist` as a Pages artifact and
deploys it to `https://openecos-projects.github.io/mpc-frame/`. When enabling the
site for the first time, set `Settings > Pages > Build and deployment > Source`
to `GitHub Actions`.
