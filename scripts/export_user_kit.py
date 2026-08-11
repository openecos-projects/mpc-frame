#!/usr/bin/env python3
"""Export the supported user-facing frame from the maintainer repository."""

from __future__ import annotations

import argparse
import json
import shutil
from pathlib import Path


def resolve_child(root: Path, value: str, context: str) -> Path:
    if not isinstance(value, str) or not value:
        raise ValueError(f"{context}: expected a non-empty relative path")
    candidate = (root / value).resolve()
    try:
        candidate.relative_to(root.resolve())
    except ValueError as exc:
        raise ValueError(f"{context}: path escapes its root: {value}") from exc
    return candidate


def copy_entry(root: Path, output: Path, source_name: str, target_name: str | None = None) -> None:
    source = resolve_child(root, source_name, "source")
    target = resolve_child(output, target_name or source_name, "destination")
    if not source.exists():
        raise FileNotFoundError(f"user-kit source does not exist: {source_name}")
    target.parent.mkdir(parents=True, exist_ok=True)
    if source.is_dir():
        shutil.copytree(source, target)
    else:
        shutil.copy2(source, target)


def string_list(value: object, context: str) -> list[str]:
    if not isinstance(value, list) or not all(
        isinstance(item, str) and item for item in value
    ):
        raise ValueError(f"{context}: expected an array of non-empty strings")
    return value


def copy_public_docs(root: Path, output: Path, config: object) -> None:
    if not isinstance(config, dict) or set(config) != {"manifest", "exclude"}:
        raise ValueError("public_docs: expected only manifest and exclude")

    manifest = resolve_child(root, config["manifest"], "public_docs.manifest")
    docs_config = json.loads(manifest.read_text(encoding="utf-8"))
    if not isinstance(docs_config, dict) or set(docs_config) != {"pages"}:
        raise ValueError(f"{manifest}: expected an object containing only pages")
    pages = string_list(docs_config["pages"], f"{manifest}.pages")
    excluded = set(string_list(config["exclude"], "public_docs.exclude"))
    unknown_exclusions = excluded - set(pages)
    if unknown_exclusions:
        names = ", ".join(sorted(unknown_exclusions))
        raise ValueError(f"public_docs.exclude: pages are not published: {names}")

    for page in pages:
        page_path = Path(page)
        if page_path.is_absolute() or ".." in page_path.parts or page_path.suffix != ".md":
            raise ValueError(f"{manifest}: invalid page entry: {page!r}")
        if page in excluded:
            continue
        for locale in ("cn", "en"):
            copy_entry(root, output, str(Path("docs") / locale / page))


def export_user_kit(root: Path, output: Path, manifest: Path) -> None:
    root = root.resolve()
    output = output.resolve()
    build_root = (root / "build").resolve()
    manifest = manifest.resolve()

    if output == build_root or build_root not in output.parents:
        raise ValueError("output must be a child directory of build/")

    config = json.loads(manifest.read_text(encoding="utf-8"))
    expected_fields = {"files", "trees", "public_docs", "overrides"}
    if not isinstance(config, dict) or set(config) != expected_fields:
        raise ValueError(
            f"{manifest}: expected only {', '.join(sorted(expected_fields))}"
        )

    files = string_list(config["files"], "files")
    trees = string_list(config["trees"], "trees")
    overrides = config["overrides"]
    if not isinstance(overrides, list):
        raise ValueError("overrides: expected an array")

    shutil.rmtree(output, ignore_errors=True)
    output.mkdir(parents=True)

    for source in files:
        copy_entry(root, output, source)
    for source in trees:
        copy_entry(root, output, source)
    copy_public_docs(root, output, config["public_docs"])
    for index, override in enumerate(overrides):
        if not isinstance(override, dict) or set(override) != {"source", "destination"}:
            raise ValueError(
                f"overrides[{index}]: expected only source and destination"
            )
        copy_entry(root, output, override["source"], override["destination"])


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--root", type=Path, required=True)
    parser.add_argument("--output", type=Path, required=True)
    parser.add_argument("--manifest", type=Path)
    args = parser.parse_args()

    root = args.root.resolve()
    output = args.output.resolve()
    manifest = (args.manifest or root / "dev" / "user-kit.json").resolve()

    try:
        export_user_kit(root, output, manifest)
    except (FileNotFoundError, json.JSONDecodeError, OSError, ValueError) as exc:
        parser.error(str(exc))

    print(f"Exported user kit to {output}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
