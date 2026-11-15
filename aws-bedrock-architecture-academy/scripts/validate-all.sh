#!/usr/bin/env bash
# Run every offline quality check in the academy and print one summary table.
# Nothing here talks to AWS: no plan, no apply, no deploy, no credentials.
#
# Usage: scripts/validate-all.sh [--strict-links] [--render]
#   --strict-links  fail on links to chapters that are planned but not written
#   --render        also render Mermaid and PlantUML diagrams into diagrams/rendered/
set -uo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"
STRICT=0; RENDER=0
for a in "$@"; do
  case "$a" in
    --strict-links) STRICT=1 ;;
    --render) RENDER=1 ;;
  esac
done

LOGDIR="${ACADEMY_VALIDATION_DIR:-${TMPDIR:-/tmp}/academy-validation}/logs"
mkdir -p "$LOGDIR"
declare -a NAMES RESULTS

run() { # run NAME REQUIRED_TOOL CMD...
  local name="$1" tool="$2"; shift 2
  local log="$LOGDIR/$(echo "$name" | tr ' /' '__').log"
  if [ -n "$tool" ] && ! command -v "$tool" >/dev/null 2>&1; then
    NAMES+=("$name"); RESULTS+=("NOT RUN ($tool not installed)"); return
  fi
  if "$@" >"$log" 2>&1; then RESULTS+=("PASS"); else RESULTS+=("FAIL (see $log)"); fi
  NAMES+=("$name")
  tail -8 "$log" | sed "s/^/    /"
}

echo "== Navigation is up to date";      run "Navigation (build-nav --check)" python3 python3 scripts/build-nav.py --check
if [ "$STRICT" -eq 1 ]; then
  echo "== Internal links (strict)";     run "Internal Markdown links" python3 python3 scripts/check-links.py
else
  echo "== Internal links";              run "Internal Markdown links" python3 python3 scripts/check-links.py --allow-planned
fi
echo "== Mermaid"
if [ "$RENDER" -eq 1 ]; then             run "Mermaid diagrams" node node scripts/check-mermaid.cjs --render diagrams/rendered
else                                     run "Mermaid diagrams" node node scripts/check-mermaid.cjs; fi
echo "== PlantUML"
if [ "$RENDER" -eq 1 ]; then             run "PlantUML diagrams" java bash scripts/check-plantuml.sh --render diagrams/rendered
else                                     run "PlantUML diagrams" java bash scripts/check-plantuml.sh; fi
echo "== draw.io";                       run "draw.io XML structure" python3 python3 scripts/check-drawio.py
echo "== JSON / YAML";                   run "JSON and YAML syntax" python3 python3 scripts/check-data-files.py
echo "== Secrets";                       run "Secret and PII scan" python3 python3 scripts/scan-secrets.py
echo "== API names";                     run "API names vs AWS SDK models" python3 python3 scripts/check-api-names.py --strict
echo "== Terraform";                     run "Terraform fmt/validate/test" terraform bash scripts/validate-terraform.sh
echo "== CloudFormation";                run "CloudFormation cfn-lint" cfn-lint bash scripts/validate-cfn.sh
echo "== CDK";                           run "CDK tsc/jest/synth" node bash scripts/validate-cdk.sh
echo "== Python";                        run "Python byte-compile" python3 python3 -m compileall -q -x '(node_modules|\.terraform|cdk\.out|\.venv)' .
if command -v pytest >/dev/null 2>&1; then
  echo "== Python unit tests";           run "Python unit tests (pytest)" pytest pytest -q -p no:cacheprovider .
fi
find "$ROOT" -name __pycache__ -type d -prune -exec rm -rf {} + 2>/dev/null

echo
echo "================ SUMMARY ================"
fail=0
for i in "${!NAMES[@]}"; do
  printf '%-34s %s\n' "${NAMES[$i]}" "${RESULTS[$i]}"
  case "${RESULTS[$i]}" in FAIL*) fail=1 ;; esac
done
exit "$fail"
