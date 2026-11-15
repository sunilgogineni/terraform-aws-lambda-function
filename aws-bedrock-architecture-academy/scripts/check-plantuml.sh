#!/usr/bin/env bash
# Syntax-check every PlantUML source and optionally render it to SVG.
#
# Usage: scripts/check-plantuml.sh [--render OUT_DIR]
#
# Needs Java and a PlantUML jar: set PLANTUML_JAR, or ACADEMY_TOOLS (expects
# $ACADEMY_TOOLS/java/plantuml.jar). The sources use `!pragma layout smetana`
# so Graphviz is not required, and they include nothing from the network.
set -uo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
JAR="${PLANTUML_JAR:-${ACADEMY_TOOLS:-}/java/plantuml.jar}"
if [ ! -f "$JAR" ]; then echo "PlantUML jar not found (set PLANTUML_JAR)" >&2; exit 2; fi
RENDER=""
if [ "${1:-}" = "--render" ]; then RENDER="$(mkdir -p "$2" && cd "$2" && pwd)"; fi

mapfile -t FILES < <(find "$ROOT/diagrams/plantuml" -type f \( -name '*.puml' -o -name '*.plantuml' \) | sort)
fail=0
for f in "${FILES[@]}"; do
  rel="${f#"$ROOT"/}"
  if out=$(java -Djava.awt.headless=true -jar "$JAR" -checkonly -failfast2 "$f" 2>&1); then
    echo "ok    $rel"
    if [ -n "$RENDER" ]; then
      java -Djava.awt.headless=true -jar "$JAR" -tsvg -o "$RENDER" "$f" >/dev/null 2>&1 || { echo "--- render FAILED: $rel"; fail=$((fail + 1)); }
    fi
  else
    fail=$((fail + 1)); echo "--- FAILED: $rel"; echo "$out" | tail -10
  fi
done
echo
echo "PlantUML sources : ${#FILES[@]}"
echo "Failed           : $fail"
[ "$fail" -eq 0 ]
