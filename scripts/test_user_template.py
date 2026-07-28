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
    package = stage_root / "designs" / "127"
    registry = stage_root / "designs" / "registry.json"
    registry_rtl = stage_root / "FrameDesignRegistry.sv"
    registry_filelist = stage_root / "user-designs.f"
    frame_filelist = stage_root / "frame.f"
    design_build = root / "build" / "designs" / "127"

    shutil.rmtree(stage_root, ignore_errors=True)
    shutil.rmtree(design_build, ignore_errors=True)
    run(
        [
            sys.executable,
            "scripts/design_registry.py",
            "create-design",
            "--id",
            "127",
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
    registry.write_text(json.dumps({"designs": ["127/design.json"]}), encoding="utf-8")
    run(
        [
            sys.executable,
            "scripts/design_registry.py",
            "generate-registry",
            "--registry",
            str(registry),
            "--output",
            str(registry_rtl),
            "--filelist",
            str(registry_filelist),
        ],
        root,
    )

    frame_filelist.write_text(
        "\n".join(
            [
                str(root / "rtl/FrameClockGate.sv"),
                str(root / "rtl/FrameDesignControl.sv"),
                str(root / "rtl/DesignIoMux.sv"),
                str(root / "rtl/ReferenceDesign0.sv"),
                f"-f {registry_filelist}",
                str(registry_rtl),
                str(root / "FrameTop.sv"),
            ]
        )
        + "\n",
        encoding="utf-8",
    )

    common = [f"DESIGN={package}"]
    run(["make", "design-lint", *common], root)
    run(["make", "design-test", "TEST=io", *common], root)
    run(
        [
            "make",
            "design-frame-test",
            "TEST=frame",
            *common,
            f"REGISTRY_MANIFEST={registry}",
            f"REGISTRY_RTL={registry_rtl}",
            f"REGISTRY_FILELIST={registry_filelist}",
            f"RTL_FILELIST={frame_filelist}",
        ],
        root,
    )
    print("STAGE 9 USER TEMPLATE TEST PASS")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
