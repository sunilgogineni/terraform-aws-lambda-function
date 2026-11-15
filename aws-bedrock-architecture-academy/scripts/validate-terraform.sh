#!/usr/bin/env bash
# Format-check, initialise (no backend), validate and (where tests exist) test
# every Terraform root and module in the academy. NEVER plans or applies.
#
# A directory is treated as a Terraform root/module when it contains versions.tf.
#
# Usage: scripts/validate-terraform.sh [DIR ...]
#
# No AWS credentials are needed: `terraform validate` is offline, and the
# *.tftest.hcl files in this repository use mock providers.
# `.terraform/` data goes to a scratch directory (TF_DATA_DIR) so nothing is
# left behind in the repository.
set -uo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
WORK="${ACADEMY_VALIDATION_DIR:-${TMPDIR:-/tmp}/academy-validation}/terraform"
mkdir -p "$WORK"

if ! command -v terraform >/dev/null 2>&1; then
  echo "terraform not found on PATH" >&2
  exit 2
fi
echo "Using $(terraform version | head -1)"

echo "== terraform fmt -check -recursive"
fmt_rc=0
terraform fmt -check -recursive -diff "$ROOT" || fmt_rc=1

if [ "$#" -gt 0 ]; then
  mapfile -t DIRS < <(for d in "$@"; do find "$(cd "$d" && pwd)" -name versions.tf -not -path '*/.terraform/*' -printf '%h\n'; done | sort -u)
else
  mapfile -t DIRS < <(find "$ROOT" -name versions.tf -not -path '*/.terraform/*' -not -path '*/node_modules/*' -printf '%h\n' | sort -u)
fi

pass=0; fail=0; tested=0; failed_dirs=()
for dir in "${DIRS[@]}"; do
  rel="${dir#"$ROOT"/}"
  export TF_DATA_DIR="$WORK/$(echo "$rel" | tr '/' '_')"
  had_lock=0; [ -f "$dir/.terraform.lock.hcl" ] && had_lock=1
  ok=1
  if ! out=$(terraform -chdir="$dir" init -backend=false -input=false -no-color 2>&1); then
    ok=0; echo "--- init FAILED: $rel"; echo "$out" | tail -15
  elif ! out=$(terraform -chdir="$dir" validate -no-color 2>&1); then
    ok=0; echo "--- validate FAILED: $rel"; echo "$out" | tail -30
  elif compgen -G "$dir/*.tftest.hcl" >/dev/null || compgen -G "$dir/tests/*.tftest.hcl" >/dev/null; then
    tested=$((tested + 1))
    if ! out=$(terraform -chdir="$dir" test -no-color 2>&1); then
      ok=0; echo "--- test FAILED: $rel"; echo "$out" | tail -40
    fi
  fi
  # Remove the lock file only if this script created it.
  [ "$had_lock" -eq 0 ] && rm -f "$dir/.terraform.lock.hcl"
  if [ "$ok" -eq 1 ]; then pass=$((pass + 1)); echo "ok    $rel"; else fail=$((fail + 1)); failed_dirs+=("$rel"); fi
done
unset TF_DATA_DIR

echo
echo "Terraform directories : ${#DIRS[@]}"
echo "Validated OK          : $pass"
echo "With terraform test   : $tested"
echo "Failed                : $fail"
echo "fmt                   : $([ "$fmt_rc" -eq 0 ] && echo clean || echo 'needs formatting')"
for d in "${failed_dirs[@]:-}"; do [ -n "$d" ] && echo "  FAILED $d"; done
[ "$fail" -eq 0 ] && [ "$fmt_rc" -eq 0 ]
