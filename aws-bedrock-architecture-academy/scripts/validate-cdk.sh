#!/usr/bin/env bash
# Type-check, unit-test and synthesize every AWS CDK app in the academy.
# NEVER bootstraps or deploys: `cdk synth` only produces CloudFormation locally.
#
# A directory is treated as a CDK app when it contains cdk.json, and as a
# construct library when it contains package.json + tsconfig.json + jest config
# but no cdk.json.
#
# Usage: scripts/validate-cdk.sh [DIR ...]
#
# Dependencies: run `npm ci` in each project first, OR set ACADEMY_TOOLS to a
# directory whose node/node_modules contains aws-cdk-lib, constructs, aws-cdk,
# typescript, ts-node, jest and ts-jest; a node_modules symlink is then created
# for the run and removed afterwards.
set -uo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
WORK="${ACADEMY_VALIDATION_DIR:-${TMPDIR:-/tmp}/academy-validation}/cdk"
mkdir -p "$WORK"
SHARED="${ACADEMY_TOOLS:-}/node/node_modules"

if [ "$#" -gt 0 ]; then
  mapfile -t DIRS < <(for d in "$@"; do find "$(cd "$d" && pwd)" -name tsconfig.json -not -path '*/node_modules/*' -not -path '*/cdk.out/*' -printf '%h\n'; done | sort -u)
else
  mapfile -t DIRS < <(find "$ROOT" -name tsconfig.json -not -path '*/node_modules/*' -not -path '*/cdk.out/*' -printf '%h\n' | sort -u)
fi

pass=0; fail=0; failed_dirs=()
for dir in "${DIRS[@]}"; do
  rel="${dir#"$ROOT"/}"
  linked=0
  if [ ! -e "$dir/node_modules" ]; then
    if [ -d "$SHARED" ]; then ln -s "$SHARED" "$dir/node_modules"; linked=1
    else echo "--- SKIPPED (run npm ci first): $rel"; fail=$((fail + 1)); failed_dirs+=("$rel (no node_modules)"); continue; fi
  fi
  ok=1
  if ! out=$(cd "$dir" && npx --no-install tsc --noEmit 2>&1); then
    ok=0; echo "--- tsc FAILED: $rel"; echo "$out" | tail -30
  fi
  if [ "$ok" -eq 1 ] && { [ -d "$dir/test" ] || [ -d "$dir/tests" ]; }; then
    if ! out=$(cd "$dir" && npx --no-install jest --ci 2>&1); then
      ok=0; echo "--- jest FAILED: $rel"; echo "$out" | tail -40
    fi
  fi
  if [ "$ok" -eq 1 ] && [ -f "$dir/cdk.json" ]; then
    outdir="$WORK/$(echo "$rel" | tr '/' '_')"
    rm -rf "$outdir"
    if ! out=$(cd "$dir" && npx --no-install cdk synth --quiet --no-version-reporting --no-path-metadata --output "$outdir" 2>&1); then
      ok=0; echo "--- cdk synth FAILED: $rel"; echo "$out" | tail -40
    elif command -v cfn-lint >/dev/null 2>&1 && compgen -G "$outdir/*.template.json" >/dev/null; then
      out=$(cfn-lint "$outdir"/*.template.json 2>&1); rc=$?
      if [ "$rc" -ne 0 ]; then
        # cfn-lint exit codes are a bit mask: 2 = errors, 4 = warnings, 8 = informational.
        echo "--- cfn-lint findings on synthesized templates: $rel (exit $rc)"; echo "$out" | tail -30
        if [ $((rc & 2)) -ne 0 ]; then ok=0; fi
      fi
    fi
  fi
  [ "$linked" -eq 1 ] && rm -f "$dir/node_modules"
  if [ "$ok" -eq 1 ]; then pass=$((pass + 1)); echo "ok    $rel"; else fail=$((fail + 1)); failed_dirs+=("$rel"); fi
done

echo
echo "CDK/TypeScript directories : ${#DIRS[@]}"
echo "Passed                     : $pass"
echo "Failed                     : $fail"
for d in "${failed_dirs[@]:-}"; do [ -n "$d" ] && echo "  FAILED $d"; done
[ "$fail" -eq 0 ]
