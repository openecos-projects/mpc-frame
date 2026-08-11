import json
import sys
import tempfile
import unittest
from pathlib import Path


REPOSITORY_ROOT = Path(__file__).resolve().parents[3]
sys.path.insert(0, str(REPOSITORY_ROOT / "scripts"))

import export_user_kit  # noqa: E402


class ExportUserKitTest(unittest.TestCase):
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
                    {
                        "files": [],
                        "trees": [],
                        "public_docs": {
                            "manifest": "dev/site-docs.json",
                            "exclude": ["index.md"],
                        },
                        "overrides": [],
                    }
                ),
                encoding="utf-8",
            )
            output = root / "build" / "user-kit"

            export_user_kit.export_user_kit(root, output, manifest)

            self.assertTrue((output / "docs" / "cn" / "guide.md").is_file())
            self.assertTrue((output / "docs" / "en" / "guide.md").is_file())
            self.assertFalse((output / "docs" / "cn" / "index.md").exists())
            self.assertFalse((output / "docs" / "cn" / "maintainer.md").exists())


if __name__ == "__main__":
    unittest.main()
