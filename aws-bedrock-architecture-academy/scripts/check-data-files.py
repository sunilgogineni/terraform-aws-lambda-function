#!/usr/bin/env python3
"""Parse every JSON and YAML file in the academy to catch syntax errors.

* JSON: standard library `json` (tsconfig-style files with // comments are
  parsed after stripping comments).
* YAML: PyYAML if installed (CloudFormation short-form tags such as !Ref and
  !GetAtt are accepted). If PyYAML is missing, YAML files are reported as
  "not checked" rather than silently passed.

Usage: python3 scripts/check-data-files.py [DIR ...]
Exit code 1 if any file fails to parse.
"""
from __future__ import annotations

import json
import os
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
SKIP_DIRS = {"node_modules", ".terraform", "cdk.out", ".git", ".venv", "__pycache__", ".validation"}
JSONC_NAMES = {"tsconfig.json", "cdk.json", ".markdownlint.json"}

try:
    import yaml  # type: ignore

    class _Loader(yaml.SafeLoader):
        pass

    def _any_tag(loader, tag_suffix, node):
        if isinstance(node, yaml.ScalarNode):
            return loader.construct_scalar(node)
        if isinstance(node, yaml.SequenceNode):
            return loader.construct_sequence(node)
        return loader.construct_mapping(node)

    _Loader.add_multi_constructor("!", _any_tag)
    HAVE_YAML = True
except ImportError:  # pragma: no cover
    HAVE_YAML = False


def strip_jsonc(text: str) -> str:
    text = re.sub(r"/\*.*?\*/", "", text, flags=re.DOTALL)
    text = re.sub(r"(^|[^:\"'])//[^\n]*", r"\1", text)
    return re.sub(r",(\s*[}\]])", r"\1", text)


def main(argv: list[str]) -> int:
    targets = [Path(a).resolve() for a in argv] or [ROOT]
    json_ok = yaml_ok = failed = yaml_skipped = 0
    for target in targets:
        for dirpath, dirnames, filenames in os.walk(target):
            dirnames[:] = [d for d in dirnames if d not in SKIP_DIRS]
            for name in sorted(filenames):
                path = Path(dirpath) / name
                rel = path.relative_to(ROOT) if ROOT in path.parents else path
                lower = name.lower()
                try:
                    if lower.endswith(".json") and lower != "package-lock.json":
                        text = path.read_text(encoding="utf-8")
                        try:
                            json.loads(text)
                        except json.JSONDecodeError:
                            if name in JSONC_NAMES:
                                json.loads(strip_jsonc(text))
                            else:
                                raise
                        json_ok += 1
                    elif lower.endswith((".yaml", ".yml")):
                        if not HAVE_YAML:
                            yaml_skipped += 1
                            continue
                        with path.open(encoding="utf-8") as fh:
                            list(yaml.load_all(fh, Loader=_Loader))
                        yaml_ok += 1
                except Exception as exc:  # noqa: BLE001 - report every parse problem
                    failed += 1
                    print(f"--- FAILED: {rel}: {str(exc).splitlines()[0]}")
    print(f"JSON files parsed : {json_ok}")
    print(f"YAML files parsed : {yaml_ok}")
    if yaml_skipped:
        print(f"YAML NOT CHECKED  : {yaml_skipped} (PyYAML not installed)")
    print(f"Failed            : {failed}")
    return 1 if failed else 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
