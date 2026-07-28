import json
import sys
import tempfile
import unittest
from pathlib import Path


REPOSITORY_ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(REPOSITORY_ROOT / "scripts"))

import design_registry  # noqa: E402


class DesignRegistryTest(unittest.TestCase):
    def make_design(self, root: Path, directory: str, design_id: int, name: str) -> Path:
        package = root / directory
        (package / "rtl").mkdir(parents=True)
        (package / "rtl" / "Dut.sv").write_text(
            """module Dut(
  input wire clock, input wire reset, input wire [7:0] io_in,
  output wire [7:0] io_out, output wire [7:0] io_oe
);
assign io_out = io_in;
assign io_oe = '0;
endmodule
""",
            encoding="utf-8",
        )
        (package / "tests").mkdir()
        (package / "tests" / "DutTb.sv").write_text(
            "module DutUnitTb; endmodule\nmodule DutFrameTb; endmodule\n",
            encoding="utf-8",
        )
        manifest = {
            "id": design_id,
            "name": name,
            "module": "Dut",
            "sources": ["rtl/Dut.sv"],
            "tests": [
                {
                    "name": "unit",
                    "kind": "unit",
                    "top": "DutUnitTb",
                    "sources": ["tests/DutTb.sv"],
                },
                {
                    "name": "frame",
                    "kind": "frame",
                    "top": "DutFrameTb",
                    "sources": ["tests/DutTb.sv"],
                },
            ],
        }
        path = package / "design.json"
        path.write_text(json.dumps(manifest), encoding="utf-8")
        return path

    def test_default_port_mapping_and_deterministic_rendering(self):
        with tempfile.TemporaryDirectory() as temp_dir:
            root = Path(temp_dir)
            design_path = self.make_design(root, "1", 1, "one")
            design = design_registry.load_design(design_path)
            self.assertEqual(design.ports["clock"], "clock")

            registry_path = root / "registry.json"
            registry_path.write_text(
                json.dumps({"designs": ["1/design.json"]}), encoding="utf-8"
            )
            registry = design_registry.load_registry(registry_path)
            first = design_registry.render_registry(registry)
            second = design_registry.render_registry(registry)
            self.assertEqual(first, second)
            self.assertIn("FrameDesignSlot1", first)
            self.assertIn("128'h00000000000000000000000000000003", first)

    def test_design_reports_multiple_errors(self):
        with tempfile.TemporaryDirectory() as temp_dir:
            root = Path(temp_dir)
            manifest = root / "design.json"
            manifest.write_text(
                json.dumps(
                    {
                        "id": 0,
                        "name": "",
                        "module": "not a module",
                        "sources": ["missing.sv"],
                        "ports": {"unknown": "value"},
                    }
                ),
                encoding="utf-8",
            )
            with self.assertRaises(design_registry.ManifestError) as context:
                design_registry.load_design(manifest)
            self.assertGreaterEqual(len(context.exception.errors), 5)

    def test_registry_rejects_duplicate_ids(self):
        with tempfile.TemporaryDirectory() as temp_dir:
            root = Path(temp_dir)
            self.make_design(root, "first", 4, "first")
            self.make_design(root, "second", 4, "second")
            registry_path = root / "registry.json"
            registry_path.write_text(
                json.dumps(
                    {"designs": ["first/design.json", "second/design.json"]}
                ),
                encoding="utf-8",
            )
            with self.assertRaises(design_registry.ManifestError) as context:
                design_registry.load_registry(registry_path)
            self.assertIn("duplicate design id 4", "\n".join(context.exception.errors))

    def test_registry_rejects_paths_outside_designs_root(self):
        with tempfile.TemporaryDirectory() as temp_dir:
            root = Path(temp_dir)
            outside = root / "outside"
            registry_root = root / "designs"
            registry_root.mkdir()
            self.make_design(root, "outside", 5, "outside")
            self.assertTrue(outside.exists())
            registry_path = registry_root / "registry.json"
            registry_path.write_text(
                json.dumps({"designs": ["../outside/design.json"]}), encoding="utf-8"
            )
            with self.assertRaises(design_registry.ManifestError) as context:
                design_registry.load_registry(registry_path)
            self.assertIn("path escapes", "\n".join(context.exception.errors))

    def test_registered_design_requires_unit_and_frame_tests(self):
        with tempfile.TemporaryDirectory() as temp_dir:
            root = Path(temp_dir)
            design_path = self.make_design(root, "1", 1, "one")
            manifest = json.loads(design_path.read_text(encoding="utf-8"))
            manifest["tests"] = [manifest["tests"][0]]
            design_path.write_text(json.dumps(manifest), encoding="utf-8")
            registry_path = root / "registry.json"
            registry_path.write_text(
                json.dumps({"designs": ["1/design.json"]}), encoding="utf-8"
            )
            with self.assertRaises(design_registry.ManifestError) as context:
                design_registry.load_registry(registry_path)
            self.assertIn(
                "require at least one frame test", "\n".join(context.exception.errors)
            )

    def test_creates_complete_design_from_template(self):
        with tempfile.TemporaryDirectory() as temp_dir:
            output = Path(temp_dir) / "design"
            manifest = design_registry.create_design_package(
                REPOSITORY_ROOT / "designs" / "template",
                output,
                17,
                "my-design",
                "MyDesign",
            )
            design = design_registry.load_design(manifest)
            self.assertEqual(design.design_id, 17)
            self.assertEqual(design.module, "MyDesign")
            self.assertEqual({test.kind for test in design.tests}, {"unit", "frame"})
            self.assertTrue((output / "rtl" / "MyDesign.sv").is_file())
            self.assertTrue((output / "README.md").is_file())
            self.assertTrue((output / "README.en.md").is_file())
            for generated in output.rglob("*"):
                if generated.is_file():
                    self.assertNotIn("@MODULE@", generated.read_text(encoding="utf-8"))

    def test_create_refuses_existing_output_and_registered_id(self):
        with tempfile.TemporaryDirectory() as temp_dir:
            root = Path(temp_dir)
            self.make_design(root, "registered", 17, "registered")
            registry = root / "registry.json"
            registry.write_text(
                json.dumps({"designs": ["registered/design.json"]}), encoding="utf-8"
            )
            output = root / "existing"
            output.mkdir()
            with self.assertRaises(design_registry.ManifestError) as context:
                design_registry.create_design_package(
                    REPOSITORY_ROOT / "designs" / "template",
                    output,
                    17,
                    "new-design",
                    "NewDesign",
                    registry,
                )
            errors = "\n".join(context.exception.errors)
            self.assertIn("refusing to overwrite", errors)
            self.assertIn("design 17 is already registered", errors)


if __name__ == "__main__":
    unittest.main()
