#!/usr/bin/env python3
"""Assemble the repository Markdown and the VitePress theme into one site."""

from __future__ import annotations

import argparse
import shutil
from pathlib import Path


def copy_markdown_tree(source: Path, destination: Path) -> None:
    """Copy published documents while preserving their repository paths."""
    for path in source.rglob("*.md"):
        relative = path.relative_to(source)
        target = destination / relative
        target.parent.mkdir(parents=True, exist_ok=True)
        shutil.copy2(path, target)


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--root", type=Path, required=True)
    parser.add_argument("--output", type=Path, required=True)
    args = parser.parse_args()

    root = args.root.resolve()
    output = args.output.resolve()
    site = root / "site"

    if output == root or root not in output.parents:
        parser.error("output must be a generated directory below the repository root")

    shutil.rmtree(output, ignore_errors=True)
    output.mkdir(parents=True)

    for name in ("README.md", "README.en.md"):
        shutil.copy2(root / name, output / name)

    copy_markdown_tree(root / "docs", output / "docs")
    copy_markdown_tree(root / "reference", output / "reference")
    shutil.copytree(site / ".vitepress", output / ".vitepress")
    shutil.copytree(site / "public", output / "public")
    shutil.copy2(site / "index.md", output / "index.md")
    shutil.copy2(site / "index.en.md", output / "index.en.md")

    # QA notes are intentionally local and must not appear in the public site.
    for path in (output / "docs").rglob("*-qa.md"):
        path.unlink()

    dependencies = site / "node_modules"
    if not dependencies.is_dir():
        parser.error("site dependencies are missing; run 'make docs-site-install'")
    (output / "node_modules").symlink_to(dependencies, target_is_directory=True)

    print(f"Prepared documentation site at {output}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
