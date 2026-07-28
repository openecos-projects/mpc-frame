# User Design Registration

面向首次接入用户的操作步骤见 [用户设计接入指南](user-guide.md)。本文档保留
manifest、生成器和 registry 的详细技术契约。

Stage 5 separates fast, self-contained user verification from final `FrameTop`
integration. A user design package must be testable without compiling the
reference SoC or any other user slot.

## Repository layout

```text
designs/
├── registry.json
└── 1/
    ├── design.json
    ├── rtl/
    ├── tests/
    ├── include/     # optional
    └── README.md    # optional
```

Each `designs/<id>/design.json` is the source of truth for one design package.
The root `designs/registry.json` contains only package paths selected for final
integration. A package does not need to appear in the root registry to run its
standalone lint and tests.

## Design manifest

`design.json` records the design ID, name, top module, sources, include paths,
defines, parameters, optional port mapping, and user tests. All paths are
relative to the package directory and must remain inside it.

The preferred zero-configuration top-level ports are `clock`, `reset`, `io_in`,
`io_out`, and `io_oe`. Designs with different port names declare their mapping
in `design.json`.

The implementation uses Python 3 and the standard-library `json` parser. It
does not require PyYAML or another package installation. Unknown fields are
rejected so spelling errors do not silently change a build.

The supported fields are:

| Field | Required | Meaning |
| --- | --- | --- |
| `id` | yes | Integer user slot from 1 through 127; slot 0 is reserved |
| `name` | yes | Unique package name within the root registry |
| `module` | yes | Actual user top module name |
| `sources` | yes | Ordered `.v`/`.sv` paths inside the package |
| `include_dirs` | no | Include directories inside the package |
| `defines` | no | Compile defines; `null` means a value-less define |
| `parameters` | no | Parameters passed to the actual user top |
| `ports` | no | Semantic-to-actual port name mapping |
| `tests` | registration requires it | Named `unit` or `frame` test declarations |

For example, the standard port names require no `ports` entry. A design using
`clk_i` can declare `"ports": {"clock": "clk_i"}` while the generated wrapper
continues to expose `clock`.

## Standalone flow

```sh
make design-lint DESIGN=designs/1
make design-test DESIGN=designs/1
make design-test DESIGN=designs/1 TEST=io
```

The generator creates a temporary `UserDesignDut.sv` under
`build/designs/1/` with the stable frame interface. Standalone commands compile
only the selected package, generated wrapper, and requested user testbench.
They do not compile the reference SoC, other user packages, or the complete
128-slot frame.

## Frame integration flow

```sh
make registry-check
make registry-generate
make design-frame-test DESIGN=designs/1
```

`design-frame-test` requires the selected package to be present in the root
registry and reports that condition before invoking Verilator.

Every registered package must declare at least one `unit` test and one `frame`
test. An unregistered package may omit tests while its interface is being
developed, but it can only run the commands supported by its current manifest.

The generator reads `registry.json` and emits:

- `rtl/generated/FrameDesignRegistry.sv`, committed to Git;
- `build/generated/user-designs.f`, not committed;
- a 128-bit `design_present` mask used by the frame control logic.

The generated registry contains the port adapters and instances for registered
designs. Unregistered slots have no module instance, return zero data and zero
output enable, remain in reset, and cannot enable a gated clock. `FrameTop`
instantiates one fixed `FrameDesignRegistry` rather than knowing user module
names.

## Implemented behavior

- `design-build` validates one package and generates an isolated wrapper and
  filelist.
- `registry-filelist` validates all registered packages and prepares the
  temporary root filelist.
- `generate-registry` emits wrappers, instances, tie-offs, and the
  `design_present` mask in deterministic ID order.
- `check-registry` compares regenerated content with the committed RTL without
  modifying it.
- Manifest validation aggregates all discovered errors and exits nonzero.
- Root regression discovers every declared test from the registry; adding a
  package does not require editing the root Makefile.

The generator provides a check-only mode that compares regenerated content with
the committed registry without modifying source files. CI uses this mode to
reject stale generated RTL.

## Validation

Validation reports all discovered errors before exiting with a nonzero status.
It checks JSON structure, ID range and uniqueness, reserved design 0, package
containment, source/include/test paths, module names, port mappings, parameters,
defines, generated outputs, and deterministic regeneration.

## Acceptance

Stage 5 acceptance requires:

- a package can run standalone lint and tests without root registration;
- design 1 is generated into the registry and runs through `FrameTop`;
- input, output, reset, clock gating, and runtime selector locking are tested;
- an unregistered slot remains stopped, reset, and high impedance;
- invalid manifests fail with actionable diagnostics;
- clean regeneration is deterministic;
- the design 0 reference regression remains passing.
