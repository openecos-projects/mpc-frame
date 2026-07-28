# FrameTop Simulation and Regression

[中文说明](simulation-regression.md)

The root runner supports different harnesses: user packages keep their
SystemVerilog testbenches, while the reference design uses its C++ harness with
Flash, PSRAM, UART, and GPIO models.

## Individual FrameTop tests

Run a registered user design:

```sh
make frame-test DESIGN=designs/<id> TEST=frame
```

Run reference tests:

```sh
make frame-test DESIGN=0 TEST=boot
make frame-test DESIGN=0 TEST=uart
make frame-test DESIGN=0 TEST=gpio
make frame-test DESIGN=0 TEST=psram
```

User test names come from each `design.json`; reference tests and parameters
come from `reference/sim/tests.json`.

## Regression levels

During development run:

```sh
make regression-fast
```

It runs root RTL lint, negative manifest tests, control and IO contention tests,
then every registered design's lint, unit tests, and Frame tests.

Before submission run:

```sh
make regression
```

The full regression also tests reference Flash boot, UART, GPIO, and PSRAM.

## Logs and waveforms

Logs are written under:

```text
build/logs/root/
build/logs/designs/<id>/
build/logs/reference/
```

FST tracing is disabled by default. Enable it with `TRACE=1`:

```sh
make frame-test DESIGN=designs/<id> TEST=frame TRACE=1
make frame-test DESIGN=0 TEST=boot TRACE=1
make regression-fast TRACE=1
```

Waveforms are stored at:

```text
build/waves/<design-id>/<test>.fst
build/waves/reference/<test>.fst
```

User testbenches need no `$dumpfile`; the build generates a temporary trace hook.
Trace hooks and waveforms remain under `build/` and are not committed.

## Failure behavior

Each step has a separate log, and the final summary lists all failures. Invalid
manifest or reference test JSON fails before Verilator starts. Every registered
user design needs at least one unit and one Frame test.

FrameTop does not arbitrate electrical contention outside the chip. The external
environment may drive only payload bits where the selected design has
`io_oe=0`. `make io-contention-test` verifies that the monitor distinguishes
legal input drive from conflicting output drive.
