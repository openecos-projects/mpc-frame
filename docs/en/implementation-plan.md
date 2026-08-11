# mpc-frame Implementation Plan

[中文说明](../cn/implementation-plan.md)

This document describes the stages, deliverables, and acceptance criteria from
the RTL skeleton to a usable chip frame. The frozen selection, clock, and reset
contract is documented in [Design Control](design-control.md).

## Current status

The first complete project structure is operational:

- `FrameTop.sv` is the official root top.
- Slots 0 through 127 and the shared `io_in/io_out/io_oe` mux are implemented.
- `user_io[6:0]` selects a design; `user_io[72:7]` is the payload.
- Selection synchronization, glitch-free clock gating, and delayed reset release
  are implemented.
- Design 0 runs the single-NPC reference SoC with UART0, SPI Flash, QSPI PSRAM,
  and two GPIO groups.
- Verilator builds and functional reference regressions use `FrameTop`.
- JSON user registration, isolated wrappers, temporary design tests, and Frame
  integration are implemented.
- Fast/full regression and single-platform CI gates are available.
- A generated user package, Chinese-first guide, English translation, and
  end-to-end template acceptance test are provided.

The remaining major work is the tapeout pad wrapper, constraints, and process
mapping.

## Stage plan

| Stage | Goal | Main work | Deliverables | Acceptance |
| --- | --- | --- | --- | --- |
| 0. Freeze contracts | Fix external/internal FrameTop contracts | Ports, IO count, IDs, reset sampling, payload width, wrapper | README, design control, IO map | Integration no longer depends on oral conventions |
| 1. Project boundaries | Stabilize source and reference boundaries | Commit `dev/reference/sim`; remove nested Git/build output | Fixed reference source and root Makefile | A clone contains the complete reference |
| 2. FrameTop skeleton | Implement chip top and 128 slots | ID latch, selection, common IO mux | `FrameTop.sv`, `DesignIoMux.sv`, wrappers | FrameTop lints and connection checks pass |
| 3. Selection and clocks | Stable, glitch-free runtime control | Synchronizer, clock gate, stopped/reset unselected designs | control RTL and [design control](design-control.md) | `make -f Makefile.dev control-test` covers locking, reselection, reset, isolation, and pulse width |
| 4. Reference SoC | Run the trimmed SoC as design 0 | NPC, UART0, Flash, one PSRAM, 32+22 GPIO | adapter, IO map, trimmed filelist | External Flash boot passes |
| 5. User registration | Name-based contributor flow and maintainer-assigned slots | ID-free package manifests, temporary Frame IDs, permanent registry ID/path entries | generator, generated registry, [registration contract](user-design-registration.md) | `make -f Makefile.dev stage5-test` covers standalone, temporary Frame, and permanent registration paths |
| 6. Frame simulation | One root simulation entry | SV package tests plus reference C++ harness, logs and FST | runner, tests JSON, [regression guide](simulation-regression.md) | design 0 and user designs run through `make -f Makefile.dev frame-test` |
| 7. Design regression | Verify mux and multi-design behavior | temporary smoke design, a strict OE-overlap monitor bound into every Frame test, and same-value root contention coverage | generated contention hook, layered logs, and fast/full runners | fast regression covers root and registered designs |
| 8. Quality gates | Prevent contract regressions | pinned CI tools, source/manifest/generated checks | CI workflow and installer | push/PR gates and downloadable failures/waves |
| 9. User template | Deliver a runnable package workflow | generator, RTL/TB templates, bilingual guides | `designs/template`, `make create`, and the maintainer stage 9 smoke test | a fresh package passes lint, unit, and temporary Frame integration |
| 10. Tapeout preparation | Connect the target process | pads, timing/electrical constraints, ICG mapping, synthesis | constraints and process wrappers | target-process synthesis and signoff entry pass |

## Main remaining items

### Pad wrapper and constraints

Flash, PSRAM, UART, and GPIO reach `FrameTop.user_io`, but the target process
still needs pad cells, placement, electrical attributes, and timing constraints.

### ICG mapping

The generic `FrameClockGate` passes behavioral regression. Stage 10 must map it
to the selected process ICG standard cell.

## Recommended order

1. Keep IO and selection contracts frozen.
2. Maintain the `dev/reference/sim` source boundary and version information.
3. Keep design 0 operational.
4. Validate every FrameTop change with the minimum design 0 simulation.
5. Validate user integration with a temporary generated package.
6. Keep manifest-to-slot registration automatic.
7. Extend CI, regression, templates, and tapeout constraints together.

## Stage completion rule

Before advancing, the stage must have committed RTL/scripts/docs, a repeatable
acceptance command, actionable failure localization, and no change to the frozen
`FrameTop` external interface.
