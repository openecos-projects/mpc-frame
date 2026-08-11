#!/usr/bin/env python3
"""Assemble locale-first docs and the VitePress theme into a generated site."""

from __future__ import annotations

import argparse
import json
import os
import shutil
from pathlib import Path


def published_target(output: Path, locale: str, page: str) -> Path:
    if locale == "cn":
        return output / page
    return output / locale / page


def copy_published_docs(root: Path, output: Path) -> None:
    manifest = root / "dev" / "site-docs.json"
    config = json.loads(manifest.read_text(encoding="utf-8"))
    pages = config.get("pages")
    if not isinstance(pages, list) or not pages:
        raise ValueError(f"{manifest}: pages must be a non-empty array")

    for locale in ("cn", "en"):
        for page in pages:
            if not isinstance(page, str) or not page.endswith(".md"):
                raise ValueError(f"{manifest}: invalid page entry: {page!r}")
            source = root / "docs" / locale / page
            if not source.is_file():
                raise FileNotFoundError(f"published document does not exist: {source}")
            target = published_target(output, locale, page)
            target.parent.mkdir(parents=True, exist_ok=True)

            content = source.read_text(encoding="utf-8")
            counterpart_locale = "en" if locale == "cn" else "cn"
            counterpart_source = root / "docs" / counterpart_locale / page
            source_link = Path(os.path.relpath(counterpart_source, source.parent)).as_posix()
            counterpart_target = published_target(output, counterpart_locale, page)
            target_link = Path(os.path.relpath(counterpart_target, target.parent)).as_posix()
            content = content.replace(f"({source_link})", f"({target_link})", 1)
            target.write_text(content, encoding="utf-8")


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--root", type=Path, required=True)
    parser.add_argument("--output", type=Path, required=True)
    args = parser.parse_args()

    root = args.root.resolve()
    output = args.output.resolve()
    site = root / "dev" / "site"

    if output == root or root not in output.parents:
        parser.error("output must be a generated directory below the repository root")

    shutil.rmtree(output, ignore_errors=True)
    output.mkdir(parents=True)

    # docs/ is the only authored Markdown source; the manifest is the public boundary.
    copy_published_docs(root, output)
    shutil.copytree(site / ".vitepress", output / ".vitepress")
    shutil.copytree(site / "public", output / "public")

    dependencies = site / "node_modules"
    if not dependencies.is_dir():
        parser.error("site dependencies are missing; run 'make -f Makefile.dev docs-site-install'")
    (output / "node_modules").symlink_to(dependencies, target_is_directory=True)

    print(f"Prepared documentation site at {output}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
