import json
import sys
import tempfile
import unittest
from pathlib import Path


REPOSITORY_ROOT = Path(__file__).resolve().parents[3]
sys.path.insert(0, str(REPOSITORY_ROOT / "scripts"))

import export_user_kit  # noqa: E402


class ExportUserKitTest(unittest.TestCase):
    def manifest_config(self):
        return {
            "files": [],
            "trees": [],
            "public_docs": {"manifest": "dev/site-docs.json", "exclude": ["index.md"]},
            "generated": {
                "registry": "designs/registry.json",
                "rtl": "rtl/generated/FrameDesignRegistry.sv",
                "filelist": "rtl/generated/user-designs.f",
                "metadata": "FRAME_VERSION",
            },
            "overrides": [],
        }

    def test_exports_only_allowlisted_public_docs(self):
        with tempfile.TemporaryDirectory() as temp_dir:
            root = Path(temp_dir)
            (root / "dev").mkdir()
            for locale in ("cn", "en"):
                docs = root / "docs" / locale
                docs.mkdir(parents=True)
                (docs / "index.md").write_text("site index\n", encoding="utf-8")
                (docs / "guide.md").write_text("public guide\n", encoding="utf-8")
                (docs / "maintainer.md").write_text(
                    "private notes\n", encoding="utf-8"
                )
            (root / "dev" / "site-docs.json").write_text(
                json.dumps({"pages": ["index.md", "guide.md"]}), encoding="utf-8"
            )
            manifest = root / "dev" / "user-kit.json"
            manifest.write_text(
                json.dumps(
                    self.manifest_config()
                ),
                encoding="utf-8",
            )
            output = root / "build" / "user-kit"

            export_user_kit.export_user_kit(root, output, manifest)

            self.assertTrue((output / "docs" / "cn" / "guide.md").is_file())
            self.assertTrue((output / "docs" / "en" / "guide.md").is_file())
            self.assertFalse((output / "docs" / "cn" / "index.md").exists())
            self.assertFalse((output / "docs" / "cn" / "maintainer.md").exists())

    def test_registered_designs_are_removed_from_exported_frame(self):
        with tempfile.TemporaryDirectory() as temp_dir:
            root = Path(temp_dir)
            (root / "dev").mkdir()
            (root / "docs" / "cn").mkdir(parents=True)
            (root / "docs" / "en").mkdir(parents=True)
            for locale in ("cn", "en"):
                (root / "docs" / locale / "guide.md").write_text("guide\n", encoding="utf-8")
            (root / "dev" / "site-docs.json").write_text(json.dumps({"pages": ["guide.md"]}), encoding="utf-8")
            (root / "designs").mkdir()
            (root / "designs" / "registry.json").write_text(
                json.dumps({"designs": [{"id": 7, "manifest": "secret/design.json"}]}),
                encoding="utf-8",
            )
            (root / "rtl" / "generated").mkdir(parents=True)
            (root / "rtl" / "generated" / "FrameDesignRegistry.sv").write_text("secret\n", encoding="utf-8")
            (root / "rtl" / "generated" / "user-designs.f").write_text("secret/rtl/Secret.sv\n", encoding="utf-8")
            manifest = root / "dev" / "user-kit.json"
            config = self.manifest_config()
            config["public_docs"]["exclude"] = []
            manifest.write_text(json.dumps(config), encoding="utf-8")
            output = root / "build" / "user-kit"

            export_user_kit.export_user_kit(root, output, manifest)

            self.assertEqual(json.loads((output / "designs" / "registry.json").read_text()), {"designs": []})
            self.assertNotIn("secret", (output / "rtl" / "generated" / "FrameDesignRegistry.sv").read_text())
            self.assertEqual((output / "rtl" / "generated" / "user-designs.f").read_text(), "")
            self.assertIn("FRAME_FORMAT_VERSION=1", (output / "FRAME_VERSION").read_text())

    def test_real_user_kit_has_only_public_root_entries(self):
        build_root = REPOSITORY_ROOT / "build"
        build_root.mkdir(exist_ok=True)
        with tempfile.TemporaryDirectory(dir=build_root) as temp_dir:
            output = Path(temp_dir) / "user-kit"

            export_user_kit.export_user_kit(
                REPOSITORY_ROOT,
                output,
                REPOSITORY_ROOT / "dev" / "user-kit.json",
            )

            self.assertEqual(
                {path.name for path in output.iterdir()},
                {
                    ".gitignore",
                    "FRAME_VERSION",
                    "FrameTop.sv",
                    "Makefile",
                    "README.en.md",
                    "README.md",
                    "designs",
                    "docs",
                    "mk",
                    "rtl",
                    "scripts",
                },
            )
            self.assertFalse((output / "build").exists())
            self.assertFalse((output / "dev").exists())
            self.assertFalse((output / "Makefile.dev").exists())


if __name__ == "__main__":
    unittest.main()
