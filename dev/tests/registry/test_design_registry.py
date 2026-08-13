import json
import sys
import tempfile
import unittest
from pathlib import Path


REPOSITORY_ROOT = Path(__file__).resolve().parents[3]
sys.path.insert(0, str(REPOSITORY_ROOT / "scripts"))

import design_registry  # noqa: E402


class DesignRegistryTest(unittest.TestCase):
    def make_design(
        self,
        root: Path,
        directory: str,
        name: str,
        legacy_id: int | None = None,
        module: str = "Dut",
    ) -> Path:
        package = root / directory
        (package / "rtl").mkdir(parents=True)
        (package / "rtl" / "Dut.sv").write_text(
            f"""module {module}(
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
            "name": name,
            "module": module,
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
        if legacy_id is not None:
            manifest["id"] = legacy_id
        path = package / "design.json"
        path.write_text(json.dumps(manifest), encoding="utf-8")
        return path

    def test_default_port_mapping_and_deterministic_rendering(self):
        with tempfile.TemporaryDirectory() as temp_dir:
            root = Path(temp_dir)
            design_path = self.make_design(root, "one", "one")
            design = design_registry.load_design(design_path)
            self.assertEqual(design.ports["clock"], "clock")
            self.assertIsNone(design.design_id)

            registry_path = root / "registry.json"
            registry_path.write_text(
                json.dumps(
                    {"designs": [{"id": 1, "manifest": "one/design.json"}]}
                ),
                encoding="utf-8",
            )
            registry = design_registry.load_registry(registry_path)
            first = design_registry.render_registry(registry)
            second = design_registry.render_registry(registry)
            self.assertEqual(first, second)
            self.assertIn("FrameDesignSlot1", first)
            self.assertIn("128'h00000000000000000000000000000003", first)

    def test_full_128_slot_registry_generation(self):
        with tempfile.TemporaryDirectory() as temp_dir:
            root = Path(temp_dir)
            designs_root = root / "designs"
            designs_root.mkdir()
            entries = []
            for design_id in range(1, 128):
                name = f"design-{design_id:03d}"
                module = f"Design{design_id:03d}"
                manifest = self.make_design(
                    designs_root,
                    name,
                    name,
                    module=module,
                )
                entries.append(
                    {"id": design_id, "manifest": f"{name}/design.json"}
                )
            registry_path = designs_root / "registry.json"
            registry_path.write_text(json.dumps({"designs": entries}), encoding="utf-8")

            registry = design_registry.load_registry(registry_path)
            rendered = design_registry.render_registry(registry)
            filelist = design_registry.render_registry_filelist(
                registry, relative_to=root
            )

            self.assertEqual(len(registry.designs), 127)
            self.assertIn(
                "128'hffffffffffffffffffffffffffffffff",
                rendered,
            )
            self.assertEqual(filelist.splitlines()[0], "designs/design-001/rtl/Dut.sv")
            self.assertEqual(filelist.splitlines()[-1], "designs/design-127/rtl/Dut.sv")
            self.assertEqual(len(filelist.splitlines()), 127)
            self.assertEqual(rendered.count("FrameDesignSlot"), 254)

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
            self.make_design(root, "first", "first", module="FirstDut")
            self.make_design(root, "second", "second", module="SecondDut")
            registry_path = root / "registry.json"
            registry_path.write_text(
                json.dumps(
                    {
                        "designs": [
                            {"id": 4, "manifest": "first/design.json"},
                            {"id": 4, "manifest": "second/design.json"},
                        ]
                    }
                ),
                encoding="utf-8",
            )
            with self.assertRaises(design_registry.ManifestError) as context:
                design_registry.load_registry(registry_path)
            self.assertIn("duplicate design id 4", "\n".join(context.exception.errors))

    def test_legacy_manifest_id_and_string_registry_remain_supported(self):
        with tempfile.TemporaryDirectory() as temp_dir:
            root = Path(temp_dir)
            self.make_design(root, "legacy", "legacy", legacy_id=9)
            registry_path = root / "registry.json"
            registry_path.write_text(
                json.dumps({"designs": ["legacy/design.json"]}), encoding="utf-8"
            )

            registry = design_registry.load_registry(registry_path)

            self.assertEqual(registry.designs[0].design_id, 9)

    def test_registry_rejects_paths_outside_designs_root(self):
        with tempfile.TemporaryDirectory() as temp_dir:
            root = Path(temp_dir)
            outside = root / "outside"
            registry_root = root / "designs"
            registry_root.mkdir()
            self.make_design(root, "outside", "outside")
            self.assertTrue(outside.exists())
            registry_path = registry_root / "registry.json"
            registry_path.write_text(
                json.dumps(
                    {
                        "designs": [
                            {"id": 5, "manifest": "../outside/design.json"}
                        ]
                    }
                ),
                encoding="utf-8",
            )
            with self.assertRaises(design_registry.ManifestError) as context:
                design_registry.load_registry(registry_path)
            self.assertIn("path escapes", "\n".join(context.exception.errors))

    def test_registered_design_requires_unit_and_frame_tests(self):
        with tempfile.TemporaryDirectory() as temp_dir:
            root = Path(temp_dir)
            design_path = self.make_design(root, "one", "one")
            manifest = json.loads(design_path.read_text(encoding="utf-8"))
            manifest["tests"] = [manifest["tests"][0]]
            design_path.write_text(json.dumps(manifest), encoding="utf-8")
            registry_path = root / "registry.json"
            registry_path.write_text(
                json.dumps(
                    {"designs": [{"id": 1, "manifest": "one/design.json"}]}
                ),
                encoding="utf-8",
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
                "my-design",
                "MyDesign",
            )
            design = design_registry.load_design(manifest)
            self.assertIsNone(design.design_id)
            self.assertEqual(design.module, "MyDesign")
            self.assertEqual({test.kind for test in design.tests}, {"unit", "frame"})
            self.assertTrue((output / "rtl" / "MyDesign.sv").is_file())
            self.assertTrue((output / "README.md").is_file())
            self.assertTrue((output / "README.en.md").is_file())
            for generated in output.rglob("*"):
                if generated.is_file():
                    self.assertNotIn("@MODULE@", generated.read_text(encoding="utf-8"))

    def test_create_refuses_existing_output_and_registered_name(self):
        with tempfile.TemporaryDirectory() as temp_dir:
            root = Path(temp_dir)
            self.make_design(root, "registered", "new-design", module="NewDesign")
            registry = root / "registry.json"
            registry.write_text(
                json.dumps(
                    {
                        "designs": [
                            {"id": 17, "manifest": "registered/design.json"}
                        ]
                    }
                ),
                encoding="utf-8",
            )
            output = root / "existing"
            output.mkdir()
            with self.assertRaises(design_registry.ManifestError) as context:
                design_registry.create_design_package(
                    REPOSITORY_ROOT / "designs" / "template",
                    output,
                    "new-design",
                    "NewDesign",
                    registry,
                )
            errors = "\n".join(context.exception.errors)
            self.assertIn("refusing to overwrite", errors)
            self.assertIn("name: 'new-design' is already registered", errors)

    def test_finds_the_single_unregistered_design(self):
        with tempfile.TemporaryDirectory() as temp_dir:
            root = Path(temp_dir)
            designs = root / "designs"
            designs.mkdir()
            registered = self.make_design(
                designs, "registered", "registered", module="RegisteredDut"
            )
            candidate = self.make_design(
                designs, "candidate", "candidate", module="CandidateDut"
            )
            registry_path = designs / "registry.json"
            registry_path.write_text(
                json.dumps(
                    {
                        "designs": [
                            {"id": 7, "manifest": "registered/design.json"}
                        ]
                    }
                ),
                encoding="utf-8",
            )
            self.assertTrue(registered.is_file())
            selected = design_registry.find_user_design(designs, registry_path)
            self.assertEqual(selected, candidate.resolve())

    def test_frame_registry_assigns_first_free_temporary_id(self):
        with tempfile.TemporaryDirectory() as temp_dir:
            root = Path(temp_dir)
            self.make_design(root, "registered", "registered", module="RegisteredDut")
            candidate_path = self.make_design(
                root, "candidate", "candidate", module="CandidateDut"
            )
            registry_path = root / "registry.json"
            registry_path.write_text(
                json.dumps(
                    {
                        "designs": [
                            {"id": 1, "manifest": "registered/design.json"}
                        ]
                    }
                ),
                encoding="utf-8",
            )
            registry = design_registry.load_registry(registry_path)
            candidate = design_registry.load_design(candidate_path)
            temporary, selected_id = design_registry.prepare_frame_registry(
                registry, candidate
            )
            self.assertEqual(selected_id, 2)
            self.assertEqual([design.design_id for design in temporary.designs], [1, 2])

    def test_frame_build_injects_strict_contention_monitor(self):
        with tempfile.TemporaryDirectory() as temp_dir:
            root = Path(temp_dir)
            design_path = self.make_design(root, "candidate", "candidate")
            design = design_registry.load_design(design_path)
            output = root / "build"

            design_registry.write_design_build(
                design,
                output,
                "frame",
                "frame",
                None,
                frame_design_id=3,
            )

            hook = output / "FrameIoContentionHook.sv"
            content = hook.read_text(encoding="utf-8")
            sources = (output / "sources.f").read_text(encoding="utf-8")
            self.assertIn(str(hook.resolve()), sources)
            self.assertIn("bind DutFrameTb FrameIoContentionMonitor", content)
            self.assertIn(
                "test_io_oe[IO_WIDTH-1:DESIGN_ID_WIDTH] & design_io_oe",
                content,
            )
            self.assertNotIn("test_io_out", content)

    def test_integrate_design_writes_id_to_registry_only(self):
        with tempfile.TemporaryDirectory() as temp_dir:
            designs = Path(temp_dir) / "designs"
            designs.mkdir()
            candidate = self.make_design(
                designs, "counter32", "counter32", module="Counter32"
            )
            registry_path = designs / "registry.json"
            registry_path.write_text('{"designs": []}\n', encoding="utf-8")

            design_registry.integrate_design(registry_path, candidate, 12)

            manifest = json.loads(candidate.read_text(encoding="utf-8"))
            registry = json.loads(registry_path.read_text(encoding="utf-8"))
            self.assertNotIn("id", manifest)
            self.assertEqual(
                registry["designs"],
                [{"id": 12, "manifest": "counter32/design.json"}],
            )


if __name__ == "__main__":
    unittest.main()
