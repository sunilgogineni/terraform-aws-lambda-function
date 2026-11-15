#!/usr/bin/env python3
"""Structural check for draw.io (diagrams.net) XML files.

draw.io has no command-line renderer in this environment, so this checks what
can be checked offline:

* the file is well-formed XML with an <mxfile> root and at least one <diagram>
* each diagram contains an uncompressed <mxGraphModel>
* cell ids are unique, every `parent` exists, and every edge's `source` and
  `target` point at an existing cell
* every diagram has a title cell and a legend cell (by id convention:
  an id starting with "title" and one starting with "legend")

Usage: python3 scripts/check-drawio.py [FILE_OR_DIR ...]
Standard library only. Exit code 1 on any problem.
"""
from __future__ import annotations

import sys
import xml.etree.ElementTree as ET
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent


def check(path: Path) -> list[str]:
    problems: list[str] = []
    try:
        tree = ET.parse(path)
    except ET.ParseError as exc:
        return [f"not well-formed XML: {exc}"]
    root = tree.getroot()
    if root.tag != "mxfile":
        return [f"root element is <{root.tag}>, expected <mxfile>"]
    diagrams = root.findall("diagram")
    if not diagrams:
        return ["no <diagram> element"]
    for d in diagrams:
        name = d.get("name", "?")
        model = d.find("mxGraphModel")
        if model is None:
            problems.append(f"diagram '{name}': no uncompressed <mxGraphModel> (save without compression)")
            continue
        cells = model.findall("./root/mxCell") + [
            c for obj in model.findall("./root/object") + model.findall("./root/UserObject") for c in [obj]
        ]
        ids: dict[str, ET.Element] = {}
        for cell in cells:
            cid = cell.get("id")
            if cid is None:
                problems.append(f"diagram '{name}': a cell has no id")
                continue
            if cid in ids:
                problems.append(f"diagram '{name}': duplicate id '{cid}'")
            ids[cid] = cell
        for cell in model.findall("./root/mxCell"):
            cid = cell.get("id")
            parent = cell.get("parent")
            if parent is not None and parent not in ids:
                problems.append(f"diagram '{name}': cell '{cid}' has unknown parent '{parent}'")
            if cell.get("edge") == "1":
                for end in ("source", "target"):
                    ref = cell.get(end)
                    if ref is None:
                        problems.append(f"diagram '{name}': edge '{cid}' has no {end}")
                    elif ref not in ids:
                        problems.append(f"diagram '{name}': edge '{cid}' {end} '{ref}' does not exist")
        if not any(i.startswith("title") for i in ids):
            problems.append(f"diagram '{name}': no title cell (id starting with 'title')")
        if not any(i.startswith("legend") for i in ids):
            problems.append(f"diagram '{name}': no legend cell (id starting with 'legend')")
    return problems


def main(argv: list[str]) -> int:
    targets = [Path(a) for a in argv] or [ROOT / "diagrams" / "drawio"]
    files: list[Path] = []
    for t in targets:
        if t.is_dir():
            files += sorted(t.rglob("*.drawio")) + sorted(t.rglob("*.drawio.xml"))
        elif t.exists():
            files.append(t)
    failed = 0
    for f in files:
        problems = check(f)
        rel = f.resolve().relative_to(ROOT) if ROOT in f.resolve().parents else f
        if problems:
            failed += 1
            print(f"--- FAILED: {rel}")
            for p in problems:
                print(f"    {p}")
        else:
            print(f"ok    {rel}")
    print(f"\ndraw.io files : {len(files)}\nFailed        : {failed}")
    return 1 if failed else 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
