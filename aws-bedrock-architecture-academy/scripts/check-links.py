#!/usr/bin/env python3
"""Check internal Markdown links and anchors in the academy.

Usage:
    python3 scripts/check-links.py [PATH ...] [--allow-planned] [--list-external]

* Relative links must resolve to a file or directory inside the academy root.
* `#anchor` fragments must match a heading (GitHub slug rules) or an explicit
  `<a id="...">` / `<a name="...">` in the target Markdown file.
* With --allow-planned, links to chapters that are listed in
  scripts/content-map.json but not written yet are reported as "planned"
  instead of "broken" (useful while a phase is in progress).
* External (http/https) links are never fetched here; --list-external prints
  the unique set so it can be verified separately.

Standard library only. Exit code 1 if any broken link is found.
"""
from __future__ import annotations

import json
import os
import re
import sys
import unicodedata
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
SKIP_DIRS = {"node_modules", ".terraform", "cdk.out", ".git", ".venv", "__pycache__", ".validation"}

FENCE_RE = re.compile(r"^(\s*)(`{3,}|~{3,})")
INLINE_CODE_RE = re.compile(r"`[^`\n]*`")
# [text](target "title") and ![alt](target); target may be wrapped in <>.
LINK_RE = re.compile(r"!?\[(?:[^\[\]]|\[[^\[\]]*\])*\]\(\s*(<[^>]*>|[^)\s]+)(?:\s+(?:\"[^\"]*\"|'[^']*'))?\s*\)")
HTML_HREF_RE = re.compile(r"""(?:href|src)\s*=\s*["']([^"']+)["']""", re.IGNORECASE)
HTML_ID_RE = re.compile(r"""<a\s+[^>]*(?:id|name)\s*=\s*["']([^"']+)["']""", re.IGNORECASE)
HEADING_RE = re.compile(r"^(#{1,6})\s+(.*?)\s*#*\s*$")


def md_files(paths: list[Path]) -> list[Path]:
    found: list[Path] = []
    for p in paths:
        if p.is_file() and p.suffix.lower() == ".md":
            found.append(p)
        elif p.is_dir():
            for dirpath, dirnames, filenames in os.walk(p):
                dirnames[:] = [d for d in dirnames if d not in SKIP_DIRS]
                for name in filenames:
                    if name.lower().endswith(".md"):
                        found.append(Path(dirpath) / name)
    return sorted(set(found))


def strip_code(text: str) -> list[str]:
    """Return lines with fenced code blocks blanked and inline code removed."""
    out: list[str] = []
    fence: str | None = None
    for line in text.splitlines():
        m = FENCE_RE.match(line)
        if fence is None and m:
            fence = m.group(2)[0] * 3
            out.append("")
            continue
        if fence is not None:
            if m and m.group(2).startswith(fence):
                fence = None
            out.append("")
            continue
        out.append(INLINE_CODE_RE.sub("", line))
    return out


def slugify(heading: str) -> str:
    text = heading
    text = re.sub(r"!\[([^\]]*)\]\([^)]*\)", r"\1", text)  # images
    text = re.sub(r"\[([^\]]*)\]\([^)]*\)", r"\1", text)  # links
    text = re.sub(r"<[^>]+>", "", text)  # html tags
    text = text.replace("`", "")
    text = re.sub(r"(\*\*|__)(.*?)\1", r"\2", text)
    text = re.sub(r"(?<!\w)[*_](.+?)[*_](?!\w)", r"\1", text)
    text = text.strip().lower()
    kept = []
    for ch in text:
        cat = unicodedata.category(ch)
        if ch in "-_ " or cat[0] in ("L", "N") or cat == "Mn":
            kept.append(ch)
    return "".join(kept).replace(" ", "-")


_anchor_cache: dict[Path, set[str]] = {}


def anchors_for(path: Path) -> set[str]:
    if path in _anchor_cache:
        return _anchor_cache[path]
    anchors: set[str] = set()
    counts: dict[str, int] = {}
    try:
        raw = path.read_text(encoding="utf-8")
    except OSError:
        _anchor_cache[path] = anchors
        return anchors
    for m in HTML_ID_RE.finditer(raw):
        anchors.add(m.group(1))
    fence: str | None = None
    for line in raw.splitlines():
        fm = FENCE_RE.match(line)
        if fence is None and fm:
            fence = fm.group(2)[0] * 3
            continue
        if fence is not None:
            if fm and fm.group(2).startswith(fence):
                fence = None
            continue
        hm = HEADING_RE.match(line)
        if not hm:
            continue
        slug = slugify(hm.group(2))
        n = counts.get(slug, 0)
        counts[slug] = n + 1
        anchors.add(slug if n == 0 else f"{slug}-{n}")
    _anchor_cache[path] = anchors
    return anchors


def planned_paths() -> set[Path]:
    planned: set[Path] = set()
    cmap = ROOT / "scripts" / "content-map.json"
    if not cmap.exists():
        return planned
    data = json.loads(cmap.read_text(encoding="utf-8"))
    for section in data.get("sections", []):
        sdir = ROOT / section["path"]
        planned.add(sdir / "README.md")
        for group in section.get("groups", []):
            gdir = sdir / group["path"] if group["path"] else sdir
            planned.add(gdir / "README.md")
            for fname, _title in group.get("chapters", []):
                planned.add(gdir / fname)
    for _num, fname, _title in data.get("diagrams", []):
        planned.add(ROOT / "diagrams" / "mermaid" / fname)
    for rel in data.get("planned_files", []):
        planned.add(ROOT / rel)
    for name in (
        "README.md", "LEARNING-ROADMAP.md", "SOURCES.md", "FEATURE-VERIFICATION.md",
        "ARCHITECTURE-DECISIONS.md", "GLOSSARY.md", "CHANGELOG.md", "PROGRESS.md",
        "QUALITY-CHECK-REPORT.md", "CONTENT-MAP.md", "diagrams/diagram-index.md",
    ):
        planned.add(ROOT / name)
    return {p.resolve() for p in planned}


def main(argv: list[str]) -> int:
    allow_planned = "--allow-planned" in argv
    list_external = "--list-external" in argv
    args = [a for a in argv if not a.startswith("--")]
    targets = [Path(a).resolve() for a in args] or [ROOT]
    files = md_files(targets)
    planned = planned_paths() if allow_planned else set()

    broken: list[str] = []
    pending: list[str] = []
    external: dict[str, list[str]] = {}
    checked = 0

    for md in files:
        text = md.read_text(encoding="utf-8")
        rel = md.relative_to(ROOT) if ROOT in md.parents or md == ROOT else md
        for lineno, line in enumerate(strip_code(text), start=1):
            targets_in_line = [m.group(1) for m in LINK_RE.finditer(line)]
            targets_in_line += [m.group(1) for m in HTML_HREF_RE.finditer(line)]
            for target in targets_in_line:
                target = target.strip()
                if target.startswith("<") and target.endswith(">"):
                    target = target[1:-1]
                if not target or target.startswith(("mailto:", "tel:", "data:")):
                    continue
                if re.match(r"^[a-zA-Z][a-zA-Z0-9+.-]*://", target):
                    external.setdefault(target, []).append(f"{rel}:{lineno}")
                    continue
                checked += 1
                path_part, _, anchor = target.partition("#")
                if path_part:
                    dest = (md.parent / path_part).resolve()
                else:
                    dest = md.resolve()
                where = f"{rel}:{lineno}"
                if ROOT != dest and ROOT not in dest.parents:
                    broken.append(f"{where}: link leaves the academy root -> {target}")
                    continue
                if not dest.exists():
                    if allow_planned and dest in planned:
                        pending.append(f"{where}: planned, not written yet -> {target}")
                    else:
                        broken.append(f"{where}: missing target -> {target}")
                    continue
                if anchor and dest.is_file() and dest.suffix.lower() == ".md":
                    if anchor.lower() not in {a.lower() for a in anchors_for(dest)}:
                        broken.append(f"{where}: missing anchor #{anchor} in {dest.relative_to(ROOT)}")

    if list_external:
        for url in sorted(external):
            print(url)
        return 0

    print(f"Markdown files scanned : {len(files)}")
    print(f"Internal links checked : {checked}")
    print(f"External links (unique): {len(external)} (not fetched by this script)")
    print(f"Planned (not yet built): {len(pending)}")
    print(f"Broken                 : {len(broken)}")
    for line in pending:
        print(f"  PLANNED {line}")
    for line in broken:
        print(f"  BROKEN  {line}")
    return 1 if broken else 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
