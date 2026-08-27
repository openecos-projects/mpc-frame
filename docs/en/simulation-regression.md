# User Design Simulation and Waveforms

[中文说明](../cn/simulation-regression.md)

Each user design declares its own RTL, unit test, and FrameTop test. All build
output stays under `build/`, and the permanent registry is not modified.

## Complete check

```sh
make check DESIGN=designs/counter32
```

This runs RTL lint, the standalone unit test, and the integration test through
`FrameTop`. `DESIGN` may be omitted when exactly one unregistered design exists.

The compatibility targets remain useful when isolating one failing stage:

```sh
make user-lint DESIGN=designs/counter32
make user-test DESIGN=designs/counter32
make user-frame-test DESIGN=designs/counter32
```

Test names come from the design's `design.json`. A Frame test selects a free
temporary ID and records it in
`build/designs/<name>/frame/selected-id.txt`.

## FST waveforms

```sh
make trace DESIGN=designs/counter32
make wave DESIGN=designs/counter32
```

The testbench needs no `$dumpfile`. The build creates a temporary trace hook for
the Frame test, and both hooks and FST files stay under `build/`. `wave` checks
for GTKWave and the waveform, and tells the user to run the corresponding
`trace` command if the file is missing. Pass the same `TEST=<name>` to both
targets when selecting a test.

## Failure behavior

Verilator compile errors, invalid manifest fields, and testbench `$fatal` calls
all return a nonzero status. The external test environment may drive only
payload bits released with `io_oe[n] = 0`. Every Frame test automatically binds
an IO contention monitor. If `test_io_oe[n + 7]` and the design's `io_oe[n]`
are both 1, the simulation exits through `$fatal` and prints the overlap mask,
even when both sides drive the same value.

This check does not rely on `user_io` becoming `x` in a waveform because
Verilator is primarily a two-state simulator. Keep the template infrastructure
names `reset`, `test_io_oe`, and `dut` in a Frame testbench; the generated
monitor uses those standard connections to locate both output enables.
