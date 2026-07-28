#!/usr/bin/env python3
"""Generate and verify a fresh user package without changing the root registry."""

from __future__ import annotations

import json
import shutil
import subprocess
import sys
from pathlib import Path


def run(command: list[str], root: Path) -> None:
    print(f"$ {' '.join(command)}", flush=True)
    subprocess.run(command, cwd=root, check=True)


def main() -> int:
    root = Path(__file__).resolve().parents[1]
    stage_root = root / "build" / "stage9"
    package = stage_root / "designs" / "stage9-smoke"
    registry = stage_root / "designs" / "registry.json"
    registry_rtl = stage_root / "FrameDesignRegistry.sv"
    registry_filelist = stage_root / "user-designs.f"
    design_build = root / "build" / "designs" / "stage9-smoke"

    shutil.rmtree(stage_root, ignore_errors=True)
    shutil.rmtree(design_build, ignore_errors=True)
    run(
        [
            sys.executable,
            "scripts/design_registry.py",
            "create-design",
            "--name",
            "stage9-smoke",
            "--module",
            "Stage9Smoke",
            "--template",
            "designs/template",
            "--output",
            str(package),
        ],
        root,
    )

    registry.parent.mkdir(parents=True, exist_ok=True)
    registry.write_text(json.dumps({"designs": []}), encoding="utf-8")

    common = [f"DESIGN={package}", f"REGISTRY_MANIFEST={registry}"]
    run(["make", "design-lint", *common], root)
    run(["make", "design-test", "TEST=io", *common], root)
    run(["make", "design-frame-test", "TEST=frame", *common], root)

    run(
        [
            "make",
            "integrate-design",
            f"DESIGN={package}",
            "DESIGN_ID=127",
            f"REGISTRY_MANIFEST={registry}",
            f"REGISTRY_RTL={registry_rtl}",
            f"REGISTRY_FILELIST={registry_filelist}",
        ],
        root,
    )

    registered = json.loads(registry.read_text(encoding="utf-8"))["designs"]
    if registered != [{"id": 127, "manifest": "stage9-smoke/design.json"}]:
        raise RuntimeError(f"unexpected integrated registry: {registered}")
    print("STAGE 9 USER TEMPLATE TEST PASS")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
