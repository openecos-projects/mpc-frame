#!/usr/bin/env python3
"""Elaborate a full 128-slot FrameTop registry with Verilator."""

from __future__ import annotations

import argparse
import json
import subprocess
import tempfile
from pathlib import Path

from design_registry import load_registry, render_registry, render_registry_filelist


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--root", type=Path, required=True)
    parser.add_argument("--verilator", default="verilator")
    args = parser.parse_args()
    root = args.root.resolve()

    with tempfile.TemporaryDirectory(prefix="mpc-frame-full-registry-") as temp:
        stage = Path(temp)
        designs = stage / "designs"
        entries = []
        for design_id in range(1, 128):
            name = f"full-{design_id:03d}"
            module = f"FullDesign{design_id:03d}"
            package = designs / name
            (package / "rtl").mkdir(parents=True)
            (package / "rtl" / f"{module}.sv").write_text(
                f"""module {module} #(parameter int IO_WIDTH = 66) (
  input wire clock, input wire reset, input wire [IO_WIDTH-1:0] io_in,
  output wire [IO_WIDTH-1:0] io_out, output wire [IO_WIDTH-1:0] io_oe
);
assign io_out = io_in;
assign io_oe = '0;
endmodule
""",
                encoding="utf-8",
            )
            (package / "design.json").write_text(
                json.dumps(
                    {
                        "name": name,
                        "module": module,
                        "sources": [f"rtl/{module}.sv"],
                        "parameters": {"IO_WIDTH": 66},
                        "tests": [
                            {"name": "unit", "kind": "unit", "top": module, "sources": [f"rtl/{module}.sv"]},
                            {"name": "frame", "kind": "frame", "top": module, "sources": [f"rtl/{module}.sv"]},
                        ],
                    }
                ),
                encoding="utf-8",
            )
            entries.append({"id": design_id, "manifest": f"{name}/design.json"})

        registry_path = designs / "registry.json"
        registry_path.write_text(json.dumps({"designs": entries}), encoding="utf-8")
        registry = load_registry(registry_path)
        generated = stage / "FrameDesignRegistry.sv"
        generated.write_text(render_registry(registry), encoding="utf-8")
        user_filelist = stage / "user-designs.f"
        user_filelist.write_text(render_registry_filelist(registry), encoding="utf-8")
        frame_filelist = stage / "frame.f"
        frame_filelist.write_text(
            "\n".join(
                [
                    str(root / "rtl/FrameClockGate.sv"),
                    str(root / "rtl/FrameDesignControl.sv"),
                    str(root / "rtl/DesignIoMux.sv"),
                    str(root / "rtl/ReferenceDesign0.sv"),
                    f"-f {user_filelist}",
                    str(generated),
                    str(root / "FrameTop.sv"),
                ]
            )
            + "\n",
            encoding="utf-8",
        )
        subprocess.run(
            [
                args.verilator,
                "--lint-only",
                "--timing",
                "--top-module",
                "FrameTop",
                "-Wno-UNUSEDSIGNAL",
                "-Wno-UNUSEDPARAM",
                "-Wno-DECLFILENAME",
                "-Wno-UNOPTFLAT",
                "-f",
                str(frame_filelist),
            ],
            cwd=root,
            check=True,
        )
    print("FULL 128-SLOT STRUCTURAL TEST PASS")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
