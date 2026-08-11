#!/usr/bin/env python3
"""Run FrameTop design and reference regressions with consistent logs."""

from __future__ import annotations

import argparse
import json
import shlex
import subprocess
import sys
from dataclasses import dataclass
from pathlib import Path
from typing import Any

from design_registry import Design, ManifestError, load_design, load_registry


@dataclass(frozen=True)
class ReferenceTest:
    name: str
    image: Path
    variables: tuple[str, ...]
    build_variables: tuple[str, ...]


class RegressionRunner:
    def __init__(self, root: Path, trace: bool):
        self.root = root.resolve()
        self.trace = trace
        self.log_root = self.root / "build" / "logs"
        self.wave_root = self.root / "build" / "waves"
        self.failures: list[str] = []
        self.passes = 0

    def run(self, name: str, command: list[str], log_path: Path) -> bool:
        log_path.parent.mkdir(parents=True, exist_ok=True)
        command_text = shlex.join(command)
        print(f"\n=== RUN {name} ===", flush=True)
        print(f"$ {command_text}", flush=True)
        with log_path.open("w", encoding="utf-8") as log:
            log.write(f"$ {command_text}\n")
            process = subprocess.Popen(
                command,
                cwd=self.root,
                stdout=subprocess.PIPE,
                stderr=subprocess.STDOUT,
                text=True,
                bufsize=1,
            )
            assert process.stdout is not None
            for line in process.stdout:
                sys.stdout.write(line)
                log.write(line)
            return_code = process.wait()
        if return_code == 0:
            self.passes += 1
            print(f"=== PASS {name} ===", flush=True)
            return True
        self.failures.append(name)
        print(f"=== FAIL {name} (exit {return_code}) ===", flush=True)
        return False

    def make(self, name: str, target: str, log_path: Path, **variables: str) -> bool:
        command = ["make", "-f", "Makefile.dev", target]
        command.extend(f"{key}={value}" for key, value in variables.items())
        return self.run(name, command, log_path)

    def design_lint(self, design: Design) -> None:
        self.make(
            f"design-{design.design_id}/lint",
            "design-lint",
            self.log_root / "designs" / str(design.design_id) / "lint.log",
            DESIGN=str(design.manifest.parent),
        )

    def design_test(self, design: Design, kind: str, test_name: str) -> None:
        target = "design-test" if kind == "unit" else "design-frame-test"
        variables = {
            "DESIGN": str(design.manifest.parent),
            "TEST": test_name,
        }
        if kind == "frame":
            variables["TRACE"] = "1" if self.trace else "0"
        self.make(
            f"design-{design.design_id}/{kind}/{test_name}",
            target,
            self.log_root
            / "designs"
            / str(design.design_id)
            / f"{kind}-{test_name}.log",
            **variables,
        )

    def reference(self, selected: str | None = None) -> None:
        manifest = self.root / "dev" / "reference" / "sim" / "tests.json"
        tests = load_reference_tests(manifest, self.root / "dev" / "reference" / "sim")
        if selected is not None:
            tests = [test for test in tests if test.name == selected]
            if not tests:
                raise ValueError(f"unknown reference test: {selected}")

        if not self.make(
            "reference/preflight",
            "registry-filelist",
            self.log_root / "reference" / "preflight.log",
        ):
            return
        if not self.make(
            "reference/registry-check",
            "registry-check",
            self.log_root / "reference" / "registry-check.log",
        ):
            return

        reference_root = self.root / "dev" / "reference" / "sim"
        built_apps: set[tuple[str, ...]] = set()
        for test in tests:
            if test.build_variables and test.build_variables not in built_apps:
                build_command = ["make", "-C", str(reference_root / "sw")]
                build_command.extend(test.build_variables)
                if not self.run(
                    f"reference/{test.name}/software",
                    build_command,
                    self.log_root / "reference" / f"{test.name}-software.log",
                ):
                    continue
                built_apps.add(test.build_variables)

            wave_file = self.wave_root / "reference" / f"{test.name}.fst"
            wave_file.parent.mkdir(parents=True, exist_ok=True)
            sim_log = self.root / "build" / "reference-logs" / f"{test.name}.log"
            sim_log.parent.mkdir(parents=True, exist_ok=True)
            command = [
                "make",
                "-C",
                str(reference_root / "dv" / "verilator"),
                "sim",
                "TOP=FrameTop",
                f"RTL_FILELIST={self.root / 'dev/reference/sim/hw/filelist/frame.f'}",
                f"TRACE={1 if self.trace else 0}",
                f"BOOTROM_IMAGE={test.image}",
                f"WAVE_FILE={wave_file}",
                f"SIM_LOG={sim_log}",
                *test.variables,
            ]
            self.run(
                f"reference/{test.name}",
                command,
                self.log_root / "reference" / f"{test.name}.log",
            )

    def summary(self) -> int:
        if self.failures:
            print(
                f"\nREGRESSION FAIL: {len(self.failures)} failed, {self.passes} passed"
            )
            for name in self.failures:
                print(f"  - {name}")
            return 1
        print(f"\nREGRESSION PASS: {self.passes} steps passed")
        return 0


def _expect_string(raw: dict[str, Any], field: str, context: str) -> str:
    value = raw.get(field)
    if not isinstance(value, str) or not value:
        raise ValueError(f"{context}.{field}: expected a non-empty string")
    return value


def load_reference_tests(manifest: Path, reference_root: Path) -> list[ReferenceTest]:
    try:
        raw = json.loads(manifest.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as exc:
        raise ValueError(f"cannot read {manifest}: {exc}") from exc
    if not isinstance(raw, dict) or set(raw) != {"tests"}:
        raise ValueError(f"{manifest}: expected an object containing only 'tests'")
    entries = raw["tests"]
    if not isinstance(entries, list) or not entries:
        raise ValueError(f"{manifest}: tests must be a non-empty array")

    known_fields = {
        "name",
        "image",
        "build",
        "max_cycles",
        "uart_input",
        "uart_start_cycle",
        "uart_stop_text",
        "uart_fail_text",
        "gpio_in",
        "gpio_drive",
        "gpio_expect",
        "gpio_expect_mask",
    }
    variable_names = {
        "max_cycles": "MAX_CYCLES",
        "uart_input": "UART_INPUT",
        "uart_start_cycle": "UART_START_CYCLE",
        "uart_stop_text": "UART_STOP_TEXT",
        "uart_fail_text": "UART_FAIL_TEXT",
        "gpio_in": "GPIO_IN",
        "gpio_drive": "GPIO_DRIVE",
        "gpio_expect": "GPIO_EXPECT",
        "gpio_expect_mask": "GPIO_EXPECT_MASK",
    }
    tests: list[ReferenceTest] = []
    seen_names: set[str] = set()
    for index, entry in enumerate(entries):
        context = f"{manifest}: tests[{index}]"
        if not isinstance(entry, dict):
            raise ValueError(f"{context}: expected an object")
        unknown = set(entry) - known_fields
        if unknown:
            raise ValueError(f"{context}: unknown fields: {', '.join(sorted(unknown))}")
        name = _expect_string(entry, "name", context)
        if name in seen_names:
            raise ValueError(f"{context}: duplicate name: {name}")
        seen_names.add(name)
        image_value = _expect_string(entry, "image", context)
        image = (reference_root / image_value).resolve()
        try:
            image.relative_to(reference_root.resolve())
        except ValueError as exc:
            raise ValueError(f"{context}.image: path escapes the reference root") from exc

        variables = []
        for field, make_name in variable_names.items():
            if field in entry:
                value = entry[field]
                if not isinstance(value, (str, int)) or isinstance(value, bool):
                    raise ValueError(f"{context}.{field}: expected a string or integer")
                variables.append(f"{make_name}={value}")

        build_variables: list[str] = []
        build = entry.get("build")
        if build is not None:
            if not isinstance(build, dict) or set(build) != {
                "app",
                "drivers",
                "link_target",
            }:
                raise ValueError(
                    f"{context}.build: expected app, drivers, and link_target"
                )
            app = _expect_string(build, "app", f"{context}.build")
            link_target = _expect_string(build, "link_target", f"{context}.build")
            drivers = build["drivers"]
            if not isinstance(drivers, list) or not drivers or not all(
                isinstance(driver, str) and driver for driver in drivers
            ):
                raise ValueError(f"{context}.build.drivers: expected non-empty strings")
            build_variables = [
                f"APP={app}",
                f"DRIVERS={' '.join(drivers)}",
                f"LINK_TARGET={link_target}",
            ]
        tests.append(
            ReferenceTest(name, image, tuple(variables), tuple(build_variables))
        )
    return tests


def _parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--root", type=Path, default=Path.cwd())
    parser.add_argument("--trace", choices=("0", "1"), default="0")
    subparsers = parser.add_subparsers(dest="command", required=True)

    frame = subparsers.add_parser("frame")
    frame.add_argument("--design", required=True)
    frame.add_argument("--test")

    reference = subparsers.add_parser("reference")
    reference.add_argument("--test")

    regression = subparsers.add_parser("regression")
    regression.add_argument("--mode", choices=("fast", "full"), required=True)
    return parser


def main() -> int:
    args = _parser().parse_args()
    root = args.root.resolve()
    runner = RegressionRunner(root, args.trace == "1")
    try:
        if args.command == "reference":
            runner.reference(args.test)
        elif args.command == "frame":
            if args.design == "0":
                runner.reference(args.test or "boot")
            else:
                design_path = Path(args.design)
                if not design_path.is_absolute():
                    design_path = root / design_path
                if design_path.is_dir():
                    design_path /= "design.json"
                design = load_design(design_path)
                tests = [test for test in design.tests if test.kind == "frame"]
                if args.test:
                    tests = [test for test in tests if test.name == args.test]
                if not tests:
                    raise ValueError("selected design has no matching frame test")
                runner.design_test(design, "frame", tests[0].name)
        else:
            registry = load_registry(root / "designs" / "registry.json")
            runner.make("root/lint", "lint", runner.log_root / "root" / "lint.log")
            runner.make(
                "root/manifest",
                "manifest-test",
                runner.log_root / "root" / "manifest.log",
            )
            runner.make(
                "root/control",
                "control-test",
                runner.log_root / "root" / "control.log",
            )
            runner.make(
                "root/io-contention",
                "io-contention-test",
                runner.log_root / "root" / "io-contention.log",
            )
            for design in registry.designs:
                runner.design_lint(design)
                for test in design.tests:
                    runner.design_test(design, test.kind, test.name)
            if args.mode == "full":
                runner.reference()
    except (ManifestError, OSError, ValueError) as exc:
        print(f"error: {exc}", file=sys.stderr)
        return 2
    return runner.summary()


if __name__ == "__main__":
    raise SystemExit(main())
