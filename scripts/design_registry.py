#!/usr/bin/env python3
"""Validate user-design manifests and generate simulation integration RTL."""

from __future__ import annotations

import argparse
import difflib
import json
import re
import sys
from dataclasses import dataclass, replace
from pathlib import Path
from typing import Any


SEMANTIC_PORTS = ("clock", "reset", "io_in", "io_out", "io_oe")
IDENTIFIER_RE = re.compile(r"^[A-Za-z_][A-Za-z0-9_$]*$")
PACKAGE_NAME_RE = re.compile(r"^[a-z0-9][a-z0-9._-]*$")
SOURCE_SUFFIXES = {".v", ".sv"}
TEMPLATE_FILES = {
    "design.json.in": "design.json",
    "rtl/UserDesign.sv.in": "rtl/{module}.sv",
    "tests/UserDesignTb.sv.in": "tests/{module}Tb.sv",
    "tests/FrameUserDesignTb.sv.in": "tests/Frame{module}Tb.sv",
    "README.md.in": "README.md",
    "README.en.md.in": "README.en.md",
}


class ManifestError(Exception):
    def __init__(self, errors: list[str]):
        super().__init__("\n".join(errors))
        self.errors = errors


@dataclass(frozen=True)
class TestSpec:
    name: str
    kind: str
    top: str
    sources: tuple[Path, ...]


@dataclass(frozen=True)
class Design:
    manifest: Path
    design_id: int | None
    name: str
    module: str
    sources: tuple[Path, ...]
    include_dirs: tuple[Path, ...]
    defines: dict[str, Any]
    parameters: dict[str, Any]
    ports: dict[str, str]
    tests: tuple[TestSpec, ...]


@dataclass(frozen=True)
class Registry:
    manifest: Path
    designs: tuple[Design, ...]


def _load_json(path: Path) -> Any:
    try:
        return json.loads(path.read_text(encoding="utf-8"))
    except FileNotFoundError:
        raise ManifestError([f"{path}: file does not exist"])
    except json.JSONDecodeError as exc:
        raise ManifestError([f"{path}:{exc.lineno}:{exc.colno}: {exc.msg}"])


def _is_identifier(value: Any) -> bool:
    return isinstance(value, str) and bool(IDENTIFIER_RE.fullmatch(value))


def _resolve_package_path(
    root: Path,
    value: Any,
    field: str,
    errors: list[str],
    *,
    directory: bool = False,
) -> Path | None:
    if not isinstance(value, str) or not value:
        errors.append(f"{field}: expected a non-empty relative path")
        return None
    candidate = (root / value).resolve()
    try:
        candidate.relative_to(root)
    except ValueError:
        errors.append(f"{field}: path escapes the design package: {value}")
        return None
    if directory:
        if not candidate.is_dir():
            errors.append(f"{field}: directory does not exist: {value}")
            return None
    elif not candidate.is_file():
        errors.append(f"{field}: file does not exist: {value}")
        return None
    return candidate


def _validate_mapping(
    data: Any,
    field: str,
    errors: list[str],
    *,
    allow_null: bool,
) -> dict[str, Any]:
    if data is None:
        return {}
    if not isinstance(data, dict):
        errors.append(f"{field}: expected an object")
        return {}
    result: dict[str, Any] = {}
    for key, value in data.items():
        if not _is_identifier(key):
            errors.append(f"{field}: invalid SystemVerilog identifier: {key!r}")
            continue
        if value is None and allow_null:
            result[key] = value
        elif isinstance(value, (str, int, bool)) and not isinstance(value, float):
            if isinstance(value, str) and ("\n" in value or ";" in value):
                errors.append(f"{field}.{key}: string values cannot contain newlines or ';'")
            else:
                result[key] = value
        else:
            errors.append(f"{field}.{key}: expected a string, integer, or boolean")
    return result


def load_design(manifest: Path) -> Design:
    manifest = manifest.resolve()
    raw = _load_json(manifest)
    if not isinstance(raw, dict):
        raise ManifestError([f"{manifest}: top-level value must be an object"])

    errors: list[str] = []
    root = manifest.parent.resolve()

    design_id = raw.get("id")
    if design_id is not None and (
        not isinstance(design_id, int) or isinstance(design_id, bool)
    ):
        errors.append("id: expected an integer in the range 1..127 when present")
        design_id = None
    elif design_id is not None and not 1 <= design_id <= 127:
        errors.append("id: design 0 is reserved; user design IDs must be in the range 1..127")

    name = raw.get("name")
    if not isinstance(name, str) or not name.strip():
        errors.append("name: expected a non-empty string")
        name = "invalid-design"

    module = raw.get("module")
    if not _is_identifier(module):
        errors.append("module: expected a valid SystemVerilog identifier")
        module = "InvalidDesign"

    source_values = raw.get("sources")
    sources: list[Path] = []
    if not isinstance(source_values, list) or not source_values:
        errors.append("sources: expected a non-empty array")
    else:
        for index, value in enumerate(source_values):
            source = _resolve_package_path(root, value, f"sources[{index}]", errors)
            if source is not None:
                if source.suffix.lower() not in SOURCE_SUFFIXES:
                    errors.append(f"sources[{index}]: expected a .v or .sv file")
                sources.append(source)

    include_values = raw.get("include_dirs", [])
    include_dirs: list[Path] = []
    if not isinstance(include_values, list):
        errors.append("include_dirs: expected an array")
    else:
        for index, value in enumerate(include_values):
            include_dir = _resolve_package_path(
                root, value, f"include_dirs[{index}]", errors, directory=True
            )
            if include_dir is not None:
                include_dirs.append(include_dir)

    defines = _validate_mapping(raw.get("defines"), "defines", errors, allow_null=True)
    parameters = _validate_mapping(
        raw.get("parameters"), "parameters", errors, allow_null=False
    )

    port_values = raw.get("ports", {})
    ports = {semantic: semantic for semantic in SEMANTIC_PORTS}
    if not isinstance(port_values, dict):
        errors.append("ports: expected an object")
    else:
        unknown_ports = sorted(set(port_values) - set(SEMANTIC_PORTS))
        for key in unknown_ports:
            errors.append(f"ports: unknown semantic port: {key}")
        for semantic in SEMANTIC_PORTS:
            if semantic in port_values:
                actual = port_values[semantic]
                if not _is_identifier(actual):
                    errors.append(f"ports.{semantic}: expected a SystemVerilog identifier")
                else:
                    ports[semantic] = actual

    tests: list[TestSpec] = []
    test_values = raw.get("tests", [])
    seen_tests: set[tuple[str, str]] = set()
    if not isinstance(test_values, list):
        errors.append("tests: expected an array")
    else:
        for index, value in enumerate(test_values):
            prefix = f"tests[{index}]"
            if not isinstance(value, dict):
                errors.append(f"{prefix}: expected an object")
                continue
            test_name = value.get("name")
            if not isinstance(test_name, str) or not test_name:
                errors.append(f"{prefix}.name: expected a non-empty string")
                test_name = f"invalid-{index}"
            kind = value.get("kind", "unit")
            if kind not in ("unit", "frame"):
                errors.append(f"{prefix}.kind: expected 'unit' or 'frame'")
                kind = "unit"
            top = value.get("top")
            if not _is_identifier(top):
                errors.append(f"{prefix}.top: expected a SystemVerilog identifier")
                top = "InvalidTestTop"
            key = (kind, test_name)
            if key in seen_tests:
                errors.append(f"{prefix}: duplicate {kind} test name: {test_name}")
            seen_tests.add(key)
            test_sources: list[Path] = []
            values = value.get("sources")
            if not isinstance(values, list) or not values:
                errors.append(f"{prefix}.sources: expected a non-empty array")
            else:
                for source_index, source_value in enumerate(values):
                    source = _resolve_package_path(
                        root,
                        source_value,
                        f"{prefix}.sources[{source_index}]",
                        errors,
                    )
                    if source is not None:
                        if source.suffix.lower() not in SOURCE_SUFFIXES:
                            errors.append(
                                f"{prefix}.sources[{source_index}]: expected a .v or .sv file"
                            )
                        test_sources.append(source)
            tests.append(TestSpec(test_name, kind, top, tuple(test_sources)))

    if sources and _is_identifier(module):
        source_text = "\n".join(
            source.read_text(encoding="utf-8", errors="replace") for source in sources
        )
        source_text = re.sub(r"/\*.*?\*/", "", source_text, flags=re.DOTALL)
        source_text = re.sub(r"//.*", "", source_text)
        module_match = re.search(
            rf"\bmodule\s+{re.escape(module)}\b(?P<body>.*?)\bendmodule\b",
            source_text,
            flags=re.DOTALL,
        )
        if module_match is None:
            errors.append(f"module: {module} was not found in sources")
        else:
            body = module_match.group("body")
            for semantic, actual in ports.items():
                if not re.search(rf"\b{re.escape(actual)}\b", body):
                    errors.append(
                        f"ports.{semantic}: mapped port {actual} was not found in module {module}"
                    )

    known_fields = {
        "id",
        "name",
        "module",
        "sources",
        "include_dirs",
        "defines",
        "parameters",
        "ports",
        "tests",
    }
    for field in sorted(set(raw) - known_fields):
        errors.append(f"unknown field: {field}")

    if errors:
        raise ManifestError([f"{manifest}: {error}" for error in errors])

    return Design(
        manifest=manifest,
        design_id=design_id,
        name=name,
        module=module,
        sources=tuple(sources),
        include_dirs=tuple(include_dirs),
        defines=defines,
        parameters=parameters,
        ports=ports,
        tests=tuple(tests),
    )


def load_registry(manifest: Path) -> Registry:
    manifest = manifest.resolve()
    raw = _load_json(manifest)
    if not isinstance(raw, dict):
        raise ManifestError([f"{manifest}: top-level value must be an object"])

    errors: list[str] = []
    entries = raw.get("designs")
    if not isinstance(entries, list):
        raise ManifestError([f"{manifest}: designs: expected an array"])
    for field in sorted(set(raw) - {"designs"}):
        errors.append(f"{manifest}: unknown field: {field}")

    root = manifest.parent.resolve()
    designs: list[Design] = []
    seen_paths: set[Path] = set()
    for index, value in enumerate(entries):
        entry_id: int | None = None
        entry_path: Any = value
        if isinstance(value, dict):
            unknown = sorted(set(value) - {"id", "manifest"})
            for field in unknown:
                errors.append(f"{manifest}: designs[{index}]: unknown field: {field}")
            entry_id = value.get("id")
            entry_path = value.get("manifest")
            if not isinstance(entry_id, int) or isinstance(entry_id, bool):
                errors.append(
                    f"{manifest}: designs[{index}].id: expected an integer in the range 1..127"
                )
                entry_id = None
            elif not 1 <= entry_id <= 127:
                errors.append(
                    f"{manifest}: designs[{index}].id: design 0 is reserved; "
                    "expected 1..127"
                )
                entry_id = None
        design_manifest = _resolve_package_path(
            root, entry_path, f"{manifest}: designs[{index}].manifest", errors
        )
        if design_manifest is None:
            continue
        if design_manifest in seen_paths:
            errors.append(
                f"{manifest}: designs[{index}]: duplicate manifest: {entry_path}"
            )
            continue
        seen_paths.add(design_manifest)
        try:
            design = load_design(design_manifest)
        except ManifestError as exc:
            errors.extend(exc.errors)
            continue

        if entry_id is None:
            if isinstance(value, str) and design.design_id is not None:
                entry_id = design.design_id
            else:
                errors.append(
                    f"{manifest}: designs[{index}]: registry entry must assign an id"
                )
                continue
        if design.design_id is not None and design.design_id != entry_id:
            errors.append(
                f"{design.manifest}: legacy manifest id {design.design_id} does not "
                f"match registry id {entry_id}"
            )
            continue
        designs.append(replace(design, design_id=entry_id))

    seen_ids: dict[int, Path] = {}
    seen_names: dict[str, Path] = {}
    seen_modules: dict[str, Path] = {}
    for design in designs:
        test_kinds = {test.kind for test in design.tests}
        for required_kind in ("unit", "frame"):
            if required_kind not in test_kinds:
                errors.append(
                    f"{design.manifest}: registered designs require at least one "
                    f"{required_kind} test"
                )
        assert design.design_id is not None
        if design.design_id in seen_ids:
            errors.append(
                f"{manifest}: duplicate design id {design.design_id}: "
                f"{seen_ids[design.design_id]} and {design.manifest}"
            )
        else:
            seen_ids[design.design_id] = design.manifest
        if design.name in seen_names:
            errors.append(
                f"{manifest}: duplicate design name {design.name!r}: "
                f"{seen_names[design.name]} and {design.manifest}"
            )
        else:
            seen_names[design.name] = design.manifest
        if design.module in seen_modules:
            errors.append(
                f"{manifest}: duplicate design top module {design.module}: "
                f"{seen_modules[design.module]} and {design.manifest}"
            )
        else:
            seen_modules[design.module] = design.manifest

    if errors:
        raise ManifestError(errors)
    return Registry(manifest, tuple(sorted(designs, key=lambda design: design.design_id)))


def create_design_package(
    template_dir: Path,
    output_dir: Path,
    name: str,
    module: str,
    registry_path: Path | None = None,
) -> Path:
    errors: list[str] = []
    if not PACKAGE_NAME_RE.fullmatch(name):
        errors.append(
            "name: use lowercase letters, digits, '.', '_' or '-', starting with a letter or digit"
        )
    if not _is_identifier(module):
        errors.append("module: expected a valid SystemVerilog identifier")

    output_dir = output_dir.resolve()
    if output_dir.exists():
        errors.append(f"output: path already exists; refusing to overwrite: {output_dir}")

    if registry_path is not None:
        try:
            registry = load_registry(registry_path)
        except ManifestError as exc:
            errors.extend(exc.errors)
        else:
            for design in registry.designs:
                if design.name == name:
                    errors.append(
                        f"name: {name!r} is already registered by {design.manifest}"
                    )
                if design.module == module:
                    errors.append(
                        f"module: {module} is already registered by {design.manifest}"
                    )

    template_dir = template_dir.resolve()
    templates: list[tuple[str, str]] = []
    for source_name, destination_pattern in TEMPLATE_FILES.items():
        source = template_dir / source_name
        try:
            templates.append((destination_pattern, source.read_text(encoding="utf-8")))
        except FileNotFoundError:
            errors.append(f"template: required file does not exist: {source}")

    if errors:
        raise ManifestError(errors)

    replacements = {
        "@PACKAGE_NAME@": name,
        "@MODULE@": module,
        "@UNIT_TOP@": f"{module}Tb",
        "@FRAME_TOP@": f"Frame{module}Tb",
    }
    rendered_files: list[tuple[str, str]] = []
    for destination_pattern, content in templates:
        for token, value in replacements.items():
            content = content.replace(token, value)
        unresolved = sorted(set(re.findall(r"@[A-Z_]+@", content)))
        if unresolved:
            errors.append(
                f"template: unresolved tokens in {destination_pattern}: "
                f"{', '.join(unresolved)}"
            )
        rendered_files.append((destination_pattern, content))

    if errors:
        raise ManifestError(errors)

    for destination_pattern, content in rendered_files:
        destination = output_dir / destination_pattern.format(module=module)
        destination.parent.mkdir(parents=True, exist_ok=True)
        destination.write_text(content, encoding="utf-8")

    manifest = output_dir / "design.json"
    load_design(manifest)
    return manifest


def default_module_name(package_name: str) -> str:
    parts = [part for part in re.split(r"[^A-Za-z0-9]+", package_name) if part]
    module = "".join(part[0].upper() + part[1:] for part in parts)
    if not module:
        return "UserDesign"
    if module[0].isdigit():
        module = "UserDesign" + module
    return module


def find_user_design(
    designs_root: Path, registry_path: Path, selected: Path | None = None
) -> Path:
    if selected is not None:
        candidate = selected.resolve()
        if candidate.is_dir():
            candidate /= "design.json"
        load_design(candidate)
        return candidate

    designs_root = designs_root.resolve()
    registry = load_registry(registry_path)
    registered = {design.manifest for design in registry.designs}
    candidates = sorted(
        manifest.resolve()
        for manifest in designs_root.glob("*/design.json")
        if manifest.resolve() not in registered
    )
    if len(candidates) == 1:
        load_design(candidates[0])
        return candidates[0]
    if not candidates:
        raise ManifestError(
            [
                f"{designs_root}: no unregistered user design found; "
                "run 'make create-design DESIGN_NAME=<name>'"
            ]
        )
    names = ", ".join(str(path.parent) for path in candidates)
    raise ManifestError(
        [
            f"{designs_root}: multiple unregistered user designs found: {names}; "
            "select one with DESIGN=<path>"
        ]
    )


def integrate_design(registry_path: Path, design_path: Path, design_id: int) -> None:
    if not 1 <= design_id <= 127:
        raise ManifestError(
            ["id: design 0 is reserved; expected an integer in the range 1..127"]
        )

    registry_path = registry_path.resolve()
    registry = load_registry(registry_path)
    design = load_design(design_path)
    root = registry_path.parent
    try:
        relative_manifest = design.manifest.relative_to(root)
    except ValueError:
        raise ManifestError(
            [f"{design.manifest}: design package must be inside {root}"]
        )

    errors: list[str] = []
    for registered in registry.designs:
        if registered.manifest == design.manifest:
            errors.append(
                f"{design.manifest}: design is already registered as id {registered.design_id}"
            )
        if registered.design_id == design_id:
            errors.append(
                f"id: design {design_id} is already registered by {registered.manifest}"
            )
        if registered.name == design.name and registered.manifest != design.manifest:
            errors.append(
                f"name: {design.name!r} is already registered by {registered.manifest}"
            )
        if registered.module == design.module and registered.manifest != design.manifest:
            errors.append(
                f"module: {design.module} is already registered by {registered.manifest}"
            )
    if design.design_id is not None and design.design_id != design_id:
        errors.append(
            f"{design.manifest}: legacy manifest id {design.design_id} does not "
            f"match requested id {design_id}"
        )
    if errors:
        raise ManifestError(errors)

    entries = [
        {
            "id": registered.design_id,
            "manifest": registered.manifest.relative_to(root).as_posix(),
        }
        for registered in registry.designs
    ]
    entries.append({"id": design_id, "manifest": relative_manifest.as_posix()})
    entries.sort(key=lambda entry: int(entry["id"]))
    _write(registry_path, json.dumps({"designs": entries}, indent=2) + "\n")


def prepare_frame_registry(registry: Registry, design: Design) -> tuple[Registry, int]:
    for registered in registry.designs:
        if registered.manifest == design.manifest:
            assert registered.design_id is not None
            return registry, registered.design_id

    errors: list[str] = []
    for registered in registry.designs:
        if registered.name == design.name:
            errors.append(
                f"name: {design.name!r} is already registered by {registered.manifest}"
            )
        if registered.module == design.module:
            errors.append(
                f"module: {design.module} is already registered by {registered.manifest}"
            )
    if errors:
        raise ManifestError(errors)

    used_ids = {registered.design_id for registered in registry.designs}
    temporary_id = next(
        (candidate for candidate in range(1, 128) if candidate not in used_ids), None
    )
    if temporary_id is None:
        raise ManifestError(["registry has no free design ID for a temporary Frame test"])
    temporary = replace(design, design_id=temporary_id)
    designs = tuple(
        sorted((*registry.designs, temporary), key=lambda item: item.design_id or 0)
    )
    return Registry(registry.manifest, designs), temporary_id


def write_frame_filelist(registry: Registry, output_dir: Path, root: Path) -> None:
    registry_rtl = output_dir / "FrameDesignRegistry.sv"
    registry_filelist = output_dir / "user-designs.f"
    frame_filelist = output_dir / "frame.f"
    _write(registry_rtl, render_registry(registry))
    _write(registry_filelist, render_registry_filelist(registry))
    lines = [
        root / "rtl/FrameClockGate.sv",
        root / "rtl/FrameDesignControl.sv",
        root / "rtl/DesignIoMux.sv",
        root / "rtl/ReferenceDesign0.sv",
    ]
    content = "\n".join(str(path.resolve()) for path in lines)
    content += f"\n-f {registry_filelist.resolve()}\n"
    content += f"{registry_rtl.resolve()}\n{(root / 'FrameTop.sv').resolve()}\n"
    _write(frame_filelist, content)


def _sv_value(value: Any) -> str:
    if isinstance(value, bool):
        return "1'b1" if value else "1'b0"
    return str(value)


def _parameter_connections(design: Design, indent: str) -> str:
    if not design.parameters:
        return ""
    connections = []
    for key in sorted(design.parameters):
        value = "IO_WIDTH" if key == "IO_WIDTH" else _sv_value(design.parameters[key])
        connections.append(f"{indent}.{key}({value})")
    return " #(\n" + ",\n".join(connections) + "\n    )"


def render_wrapper(design: Design, wrapper_module: str) -> str:
    params = _parameter_connections(design, "        ")
    ports = ",\n".join(
        f"        .{design.ports[semantic]}({semantic})" for semantic in SEMANTIC_PORTS
    )
    return f"""module {wrapper_module} #(
    parameter int IO_WIDTH = 66
) (
    input  wire                  clock,
    input  wire                  reset,
    input  wire [IO_WIDTH-1:0]   io_in,
    output wire [IO_WIDTH-1:0]   io_out,
    output wire [IO_WIDTH-1:0]   io_oe
);
    {design.module}{params} u_design (
{ports}
    );
endmodule
"""


def render_registry(registry: Registry) -> str:
    if any(design.design_id is None for design in registry.designs):
        raise ManifestError(["registry rendering requires an ID for every design"])
    wrappers = "\n".join(
        render_wrapper(design, f"FrameDesignSlot{design.design_id}").rstrip()
        for design in registry.designs
    )
    if wrappers:
        wrappers += "\n\n"

    mask = 1
    for design in registry.designs:
        mask |= 1 << design.design_id

    instances = []
    for design in registry.designs:
        design_id = design.design_id
        instances.append(
            f"""    FrameDesignSlot{design_id} #(
        .IO_WIDTH(IO_WIDTH)
    ) u_design_{design_id} (
        .clock  (design_clock[{design_id}]),
        .reset  (design_reset[{design_id}]),
        .io_in  (io_in),
        .io_out (designs_io_out[{design_id}]),
        .io_oe  (designs_io_oe[{design_id}])
    );"""
        )
    instance_text = "\n\n".join(instances)
    if instance_text:
        instance_text += "\n\n"

    return f"""// Generated by scripts/design_registry.py. Do not edit manually.
{wrappers}module FrameDesignRegistry #(
    parameter int IO_WIDTH = 66,
    parameter int DESIGN_COUNT = 128
) (
    input  wire [DESIGN_COUNT-1:0]                 design_clock,
    input  wire [DESIGN_COUNT-1:0]                 design_reset,
    input  wire [IO_WIDTH-1:0]                     io_in,
    output wire [DESIGN_COUNT-1:0][IO_WIDTH-1:0]   designs_io_out,
    output wire [DESIGN_COUNT-1:0][IO_WIDTH-1:0]   designs_io_oe,
    output wire [DESIGN_COUNT-1:0]                 design_present
);
    localparam logic [127:0] DESIGN_PRESENT = 128'h{mask:032x};

    assign design_present = DESIGN_PRESENT;

    ReferenceDesign0 #(
        .IO_WIDTH(IO_WIDTH)
    ) u_reference_design_0 (
        .clock  (design_clock[0]),
        .reset  (design_reset[0]),
        .io_in  (io_in),
        .io_out (designs_io_out[0]),
        .io_oe  (designs_io_oe[0])
    );

{instance_text}    for (genvar design_index = 1; design_index < DESIGN_COUNT; design_index++) begin : gen_absent_design
        if (!DESIGN_PRESENT[design_index]) begin : gen_tie_off
            assign designs_io_out[design_index] = '0;
            assign designs_io_oe[design_index] = '0;
        end
    end
endmodule
"""


def _filelist_lines(design: Design) -> list[str]:
    lines = []
    for key in sorted(design.defines):
        value = design.defines[key]
        lines.append(f"+define+{key}" if value is None else f"+define+{key}={_sv_value(value)}")
    lines.extend(f"+incdir+{path}" for path in design.include_dirs)
    lines.extend(str(path) for path in design.sources)
    return lines


def render_registry_filelist(registry: Registry) -> str:
    lines: list[str] = []
    for design in registry.designs:
        lines.extend(_filelist_lines(design))
    return "\n".join(lines) + ("\n" if lines else "")


def _select_test(design: Design, kind: str, name: str | None) -> TestSpec:
    candidates = [test for test in design.tests if test.kind == kind]
    if name:
        candidates = [test for test in candidates if test.name == name]
    if not candidates:
        suffix = f" named {name!r}" if name else ""
        raise ManifestError(
            [f"{design.manifest}: no {kind} test{suffix} is declared in design.json"]
        )
    return candidates[0]


def write_design_build(
    design: Design,
    output_dir: Path,
    kind: str | None,
    test_name: str | None,
    trace_file: Path | None,
    frame_design_id: int | None = None,
) -> None:
    output_dir.mkdir(parents=True, exist_ok=True)
    lines: list[str] = []
    if kind != "frame":
        wrapper = output_dir / "UserDesignDut.sv"
        wrapper.write_text(render_wrapper(design, "UserDesignDut"), encoding="utf-8")
        lines.extend(_filelist_lines(design))
        lines.append(str(wrapper.resolve()))
    top = "UserDesignDut"
    if kind is not None:
        test = _select_test(design, kind, test_name)
        if kind == "frame":
            if frame_design_id is None:
                raise ManifestError(["frame build requires a selected design ID"])
            lines.append(f"+define+FRAME_TEST_DESIGN_ID={frame_design_id}")
        lines.extend(str(path) for path in test.sources)
        top = test.top
        if kind == "frame" and trace_file is not None:
            trace_hook = output_dir / "FrameTraceHook.sv"
            trace_path = str(trace_file.resolve()).replace("\\", "\\\\").replace('"', '\\"')
            trace_hook.write_text(
                f"""module FrameTraceHook;
    initial begin
        $dumpfile(\"{trace_path}\");
        $dumpvars(0);
    end
endmodule

bind {top} FrameTraceHook u_frame_trace_hook();
""",
                encoding="utf-8",
            )
            lines.append(str(trace_hook.resolve()))
    (output_dir / "sources.f").write_text("\n".join(lines) + "\n", encoding="utf-8")
    (output_dir / "top.txt").write_text(top + "\n", encoding="utf-8")


def _write(path: Path, content: str) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(content, encoding="utf-8")


def _check(path: Path, expected: str) -> bool:
    try:
        actual = path.read_text(encoding="utf-8")
    except FileNotFoundError:
        print(f"error: generated file is missing: {path}", file=sys.stderr)
        return False
    if actual == expected:
        return True
    print(f"error: generated file is stale: {path}", file=sys.stderr)
    diff = difflib.unified_diff(
        actual.splitlines(), expected.splitlines(), fromfile=str(path), tofile="expected"
    )
    for line in diff:
        print(line, file=sys.stderr)
    return False


def _build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(description=__doc__)
    subparsers = parser.add_subparsers(dest="command", required=True)

    validate_design = subparsers.add_parser("validate-design")
    validate_design.add_argument("--design", required=True, type=Path)

    create_design = subparsers.add_parser("create-design")
    create_design.add_argument("--name", required=True)
    create_design.add_argument("--module")
    create_design.add_argument("--output", required=True, type=Path)
    create_design.add_argument("--template", required=True, type=Path)
    create_design.add_argument("--registry", type=Path)

    design_build = subparsers.add_parser("design-build")
    design_build.add_argument("--design", required=True, type=Path)
    design_build.add_argument("--output-dir", required=True, type=Path)
    design_build.add_argument("--kind", choices=("unit", "frame"))
    design_build.add_argument("--test")
    design_build.add_argument("--registry", type=Path)
    design_build.add_argument("--trace-file", type=Path)

    find_design = subparsers.add_parser("find-user-design")
    find_design.add_argument("--designs-root", required=True, type=Path)
    find_design.add_argument("--registry", required=True, type=Path)
    find_design.add_argument("--design", type=Path)

    integrate = subparsers.add_parser("integrate-design")
    integrate.add_argument("--design", required=True, type=Path)
    integrate.add_argument("--id", required=True, type=int)
    integrate.add_argument("--registry", required=True, type=Path)

    for command in ("validate-registry", "registry-filelist", "generate-registry", "check-registry"):
        subparser = subparsers.add_parser(command)
        subparser.add_argument("--registry", required=True, type=Path)
        if command in ("registry-filelist", "generate-registry"):
            subparser.add_argument("--filelist", required=True, type=Path)
        if command in ("generate-registry", "check-registry"):
            subparser.add_argument("--output", required=True, type=Path)
    return parser


def main() -> int:
    args = _build_parser().parse_args()
    try:
        if args.command == "validate-design":
            load_design(args.design)
        elif args.command == "create-design":
            name = args.name
            module = args.module or default_module_name(name)
            manifest = create_design_package(
                args.template, args.output, name, module, args.registry
            )
            print(f"created {manifest}")
        elif args.command == "find-user-design":
            manifest = find_user_design(
                args.designs_root, args.registry, args.design
            )
            print(manifest.parent)
        elif args.command == "integrate-design":
            integrate_design(args.registry, args.design, args.id)
            print(f"registered {args.design} as design {args.id}")
        elif args.command == "design-build":
            design = load_design(args.design)
            frame_design_id = None
            if args.kind == "frame":
                if args.registry is None:
                    raise ManifestError(["frame tests require --registry"])
                registry = load_registry(args.registry)
                frame_registry, frame_design_id = prepare_frame_registry(registry, design)
                write_frame_filelist(
                    frame_registry,
                    args.output_dir,
                    Path(__file__).resolve().parents[1],
                )
                _write(args.output_dir / "selected-id.txt", f"{frame_design_id}\n")
            write_design_build(
                design,
                args.output_dir,
                args.kind,
                args.test,
                args.trace_file,
                frame_design_id,
            )
        else:
            registry = load_registry(args.registry)
            if args.command == "registry-filelist":
                _write(args.filelist, render_registry_filelist(registry))
            elif args.command == "generate-registry":
                _write(args.output, render_registry(registry))
                _write(args.filelist, render_registry_filelist(registry))
            elif args.command == "check-registry":
                if not _check(args.output, render_registry(registry)):
                    print("run 'make registry-generate' to refresh it", file=sys.stderr)
                    return 1
    except ManifestError as exc:
        for error in exc.errors:
            print(f"error: {error}", file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
