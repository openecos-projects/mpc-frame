#!/usr/bin/env python3
"""Check the repository's Chinese-first bilingual documentation convention."""

from __future__ import annotations

import re
import sys
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
LINK_SCAN_LINES = 10
HAN_RE = re.compile(r"[\u3400-\u4dbf\u4e00-\u9fff]")
CHINESE_LINK_RE = re.compile(r"\[中文说明\]\([^)]+\)")


def documentation_files() -> list[Path]:
    files = [ROOT / "README.md", ROOT / "designs/template/README.md.in"]
    for directory in (ROOT / "docs", ROOT / "reference"):
        files.extend(directory.rglob("*.md"))
        files.extend(directory.rglob("*.md.in"))
    return sorted(
        {
            path
            for path in files
            if path.is_file()
            and "qa" not in path.relative_to(ROOT).parts
            and not path.name.endswith("-qa.md")
        }
    )


def is_english(path: Path) -> bool:
    return path.name.endswith(".en.md") or path.name.endswith(".en.md.in")


def english_path(chinese: Path) -> Path:
    if chinese.name.endswith(".md.in"):
        return chinese.with_name(chinese.name.removesuffix(".md.in") + ".en.md.in")
    return chinese.with_name(chinese.name.removesuffix(".md") + ".en.md")


def chinese_path(english: Path) -> Path:
    if english.name.endswith(".en.md.in"):
        return english.with_name(english.name.removesuffix(".en.md.in") + ".md.in")
    return english.with_name(english.name.removesuffix(".en.md") + ".md")


def top_text(path: Path) -> str:
    return "\n".join(path.read_text(encoding="utf-8").splitlines()[:LINK_SCAN_LINES])


def rendered_name(path: Path) -> str:
    return path.name.removesuffix(".in")


def has_link(text: str, label: str, target: str) -> bool:
    pattern = rf"\[{re.escape(label)}\]\(<?{re.escape(target)}>?\)"
    return re.search(pattern, text) is not None


def main() -> int:
    errors: list[str] = []
    files = documentation_files()

    for path in files:
        relative = path.relative_to(ROOT)
        content = path.read_text(encoding="utf-8")
        if not content.strip():
            errors.append(f"{relative}: document is empty")
            continue

        if is_english(path):
            counterpart = chinese_path(path)
            label = "中文说明"
            english_body = CHINESE_LINK_RE.sub("", content)
            if HAN_RE.search(english_body):
                errors.append(
                    f"{relative}: English document contains Chinese text outside "
                    "the language link"
                )
        else:
            counterpart = english_path(path)
            label = "English"
            if not HAN_RE.search(content):
                errors.append(f"{relative}: Chinese primary document contains no Chinese text")

        if not counterpart.is_file():
            errors.append(
                f"{relative}: missing counterpart {counterpart.relative_to(ROOT)}"
            )
            continue

        target = rendered_name(counterpart)
        if not has_link(top_text(path), label, target):
            errors.append(
                f"{relative}: first {LINK_SCAN_LINES} lines must contain "
                f"[{label}]({target})"
            )

    if errors:
        print("Documentation check failed:", file=sys.stderr)
        for error in errors:
            print(f"  - {error}", file=sys.stderr)
        return 1

    chinese_count = sum(not is_english(path) for path in files)
    print(f"Documentation check passed: {chinese_count} bilingual pairs")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
