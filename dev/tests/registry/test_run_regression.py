import json
import sys
import tempfile
import unittest
from pathlib import Path


REPOSITORY_ROOT = Path(__file__).resolve().parents[3]
sys.path.insert(0, str(REPOSITORY_ROOT / "scripts"))

import run_regression  # noqa: E402


class ReferenceManifestTest(unittest.TestCase):
    def test_loads_reference_test(self):
        with tempfile.TemporaryDirectory() as temp_dir:
            root = Path(temp_dir)
            manifest = root / "tests.json"
            manifest.write_text(
                json.dumps(
                    {
                        "tests": [
                            {
                                "name": "boot",
                                "image": "boot.bin",
                                "max_cycles": 10,
                                "uart_stop_text": "done",
                            }
                        ]
                    }
                ),
                encoding="utf-8",
            )
            tests = run_regression.load_reference_tests(manifest, root)
            self.assertEqual(tests[0].name, "boot")
            self.assertIn("MAX_CYCLES=10", tests[0].variables)

    def test_rejects_image_outside_reference_root(self):
        with tempfile.TemporaryDirectory() as temp_dir:
            root = Path(temp_dir)
            reference_root = root / "reference"
            reference_root.mkdir()
            manifest = reference_root / "tests.json"
            manifest.write_text(
                json.dumps({"tests": [{"name": "bad", "image": "../bad.bin"}]}),
                encoding="utf-8",
            )
            with self.assertRaises(ValueError) as context:
                run_regression.load_reference_tests(manifest, reference_root)
            self.assertIn("path escapes", str(context.exception))


class ReferenceRunnerTest(unittest.TestCase):
    def test_skips_simulation_after_software_build_failure(self):
        class FailingSoftwareRunner(run_regression.RegressionRunner):
            def __init__(self, root):
                super().__init__(root, trace=False)
                self.run_names = []

            def make(self, name, target, log_path, **variables):
                return True

            def run(self, name, command, log_path):
                self.run_names.append(name)
                return not name.endswith("/software")

        with tempfile.TemporaryDirectory() as temp_dir:
            root = Path(temp_dir)
            reference_root = root / "dev" / "reference" / "sim"
            reference_root.mkdir(parents=True)
            (reference_root / "tests.json").write_text(
                json.dumps(
                    {
                        "tests": [
                            {
                                "name": "gpio",
                                "image": "build/gpio.bin",
                                "build": {
                                    "app": "gpio",
                                    "drivers": ["sys_uart", "gpio"],
                                    "link_target": "xip",
                                },
                            }
                        ]
                    }
                ),
                encoding="utf-8",
            )

            runner = FailingSoftwareRunner(root)
            runner.reference()

            self.assertEqual(runner.run_names, ["reference/gpio/software"])


if __name__ == "__main__":
    unittest.main()
