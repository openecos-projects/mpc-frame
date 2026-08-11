# User Design Registration

[中文说明](../cn/user-design-registration.md)

See the [User Design Integration Guide](user-guide.md) for contributor steps.
This document defines the package, temporary Frame test, and permanent registry
contracts.

## Identity separation

The project separates three kinds of identity:

| Information | Source | Committed? |
| --- | --- | --- |
| Package name, module, sources, tests | `designs/<name>/design.json` | Yes |
| Temporary Frame test ID | Chosen by the build under `build/` | No |
| Permanent hardware design ID | Assigned in `designs/registry.json` | Yes |

New user manifests therefore contain no `id`, and contributors do not edit the
root registry.

## Package manifest

`design.json` supports:

| Field | Required | Meaning |
| --- | --- | --- |
| `name` | yes | Package name, unique in the permanent registry |
| `module` | yes | User top module |
| `sources` | yes | Ordered `.v`/`.sv` sources inside the package |
| `include_dirs` | no | Include directories inside the package |
| `defines` | no | Compile defines; `null` means no value |
| `parameters` | no | Parameters passed to the user top |
| `ports` | no | Semantic-to-actual port mapping |
| `tests` | needed for testing | Named `unit` and `frame` tests |
| `id` | legacy only | Omit in new packages; the registry owns the final ID |

All paths are package-relative and cannot escape the package. Unknown fields are
rejected. The standard ports are `clock/reset/io_in/io_out/io_oe`.

## Contributor verification

```sh
make user-lint
make user-test
make user-frame-test
make check
```

`find-user-design` excludes registered packages and selects the only remaining
`designs/*/design.json`. Multiple candidates require `DESIGN=<path>`.

For an unregistered Frame test, the generator chooses the first free ID and
writes an isolated `FrameDesignRegistry.sv`, `user-designs.f`, `frame.f`, and
`selected-id.txt` under `build/designs/<name>/frame/`. It injects that ID into
the TB as `FRAME_TEST_DESIGN_ID`. No permanent source file changes.

## Permanent registry

Permanent entries own both the ID and package path:

```json
{
  "designs": [
    {
      "id": 12,
      "manifest": "counter32/design.json"
    }
  ]
}
```

The maintainer assigns `DESIGN_ID` and performs permanent integration in the
development repository.

The command checks ID, name, module, and path conflicts; updates and regenerates
the permanent registry; and reruns the Frame test with the final ID. Commit the
updated `designs/registry.json` and generated registry RTL with the package.

Legacy string entries and manifest-level IDs remain readable during migration.
A legacy manifest ID that disagrees with its registry ID is rejected.

## Generation and regression

- `design-build` validates a package and creates wrappers, test filelists, and
  an isolated Frame registry;
- `find-user-design` discovers one unregistered package;
- `integrate-design` assigns the permanent ID;
- `registry-filelist` and `generate-registry` build permanent integration files;
- `check-registry` rejects stale generated RTL;
- `regression-fast` runs all tests declared by the permanent registry.

Permanent designs require both unit and Frame tests. ID 0 is reserved for the
reference design; user IDs range from 1 through 127. IDs, names, modules, and
manifest paths must be unique.
