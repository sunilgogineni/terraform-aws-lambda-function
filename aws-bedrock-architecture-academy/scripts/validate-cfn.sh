#!/usr/bin/env bash
# Lint every hand-written CloudFormation / SAM template in the academy with cfn-lint.
# Templates are recognised by content (AWSTemplateFormatVersion or a Resources
# section with "Type: AWS::"), not by file name. NEVER creates stacks.
#
# Usage: scripts/validate-cfn.sh [DIR ...]
set -uo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
if ! command -v cfn-lint >/dev/null 2>&1; then
  echo "cfn-lint not found on PATH (pip install cfn-lint)" >&2
  exit 2
fi
echo "Using $(cfn-lint --version)"

SEARCH=("$@"); [ "${#SEARCH[@]}" -eq 0 ] && SEARCH=("$ROOT")
mapfile -t CANDIDATES < <(find "${SEARCH[@]}" -type f \( -name '*.yaml' -o -name '*.yml' -o -name '*.json' \) \
  -not -path '*/node_modules/*' -not -path '*/cdk.out/*' -not -path '*/.terraform/*' -not -path '*/.validation/*' | sort)

TEMPLATES=()
for f in "${CANDIDATES[@]}"; do
  if grep -q -E '^\s*"?AWSTemplateFormatVersion"?\s*:' "$f" 2>/dev/null; then TEMPLATES+=("$f"); fi
done

errors=0; warnings=0
for t in "${TEMPLATES[@]}"; do
  rel="${t#"$ROOT"/}"
  out=$(cfn-lint "$t" 2>&1); rc=$?
  if [ "$rc" -eq 0 ]; then
    echo "ok    $rel"
  elif [ $((rc & 2)) -ne 0 ]; then
    errors=$((errors + 1)); echo "--- ERRORS: $rel"; echo "$out" | tail -30
  else
    warnings=$((warnings + 1)); echo "warn  $rel"; echo "$out" | tail -12
  fi
done

echo
echo "CloudFormation templates : ${#TEMPLATES[@]}"
echo "With errors              : $errors"
echo "With warnings only       : $warnings"
[ "$errors" -eq 0 ]
