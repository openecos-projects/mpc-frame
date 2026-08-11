#!/usr/bin/env python3
"""Validate locale-first bilingual documentation and counterpart links."""

from __future__ import annotations

import os
import re
import sys
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
DOCS = ROOT / "docs"
LINK_SCAN_LINES = 10
HAN_RE = re.compile(r"[\u3400-\u4dbf\u4e00-\u9fff]")
CHINESE_LINK_RE = re.compile(r"\[中文说明\]\([^)]+\)")


def markdown_files(root: Path) -> dict[Path, Path]:
    return {
        path.relative_to(root): path
        for path in root.rglob("*.md")
        if "qa" not in path.relative_to(root).parts
        and not path.name.endswith("-qa.md")
    }


def relative_link(source: Path, target: Path) -> str:
    return Path(os.path.relpath(target, source.parent)).as_posix()


def top_text(path: Path) -> str:
    return "\n".join(path.read_text(encoding="utf-8").splitlines()[:LINK_SCAN_LINES])


def has_link(text: str, label: str, target: str) -> bool:
    pattern = rf"\[{re.escape(label)}\]\(<?{re.escape(target)}>?\)"
    return re.search(pattern, text) is not None


def main() -> int:
    errors: list[str] = []
    cn_root = DOCS / "cn"
    en_root = DOCS / "en"
    cn_files = markdown_files(cn_root)
    en_files = markdown_files(en_root)

    root_markdown = sorted(DOCS.glob("*.md"))
    for path in root_markdown:
        errors.append(f"{path.relative_to(ROOT)}: documents must live below docs/cn or docs/en")

    for relative in sorted(set(cn_files) | set(en_files)):
        cn = cn_files.get(relative)
        en = en_files.get(relative)
        if cn is None:
            errors.append(f"docs/en/{relative}: missing counterpart docs/cn/{relative}")
            continue
        if en is None:
            errors.append(f"docs/cn/{relative}: missing counterpart docs/en/{relative}")
            continue

        cn_content = cn.read_text(encoding="utf-8")
        en_content = en.read_text(encoding="utf-8")
        if not cn_content.strip() or not en_content.strip():
            errors.append(f"docs/*/{relative}: document is empty")
            continue
        if not HAN_RE.search(cn_content):
            errors.append(f"docs/cn/{relative}: Chinese document contains no Chinese text")
        if HAN_RE.search(CHINESE_LINK_RE.sub("", en_content)):
            errors.append(f"docs/en/{relative}: English document contains Chinese body text")

        en_target = relative_link(cn, en)
        cn_target = relative_link(en, cn)
        if not has_link(top_text(cn), "English", en_target):
            errors.append(f"docs/cn/{relative}: expected [English]({en_target}) near the top")
        if not has_link(top_text(en), "中文说明", cn_target):
            errors.append(f"docs/en/{relative}: expected [中文说明]({cn_target}) near the top")

    if errors:
        print("Documentation check failed:", file=sys.stderr)
        for error in errors:
            print(f"  - {error}", file=sys.stderr)
        return 1

    print(f"Documentation check passed: {len(cn_files)} locale pairs")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
