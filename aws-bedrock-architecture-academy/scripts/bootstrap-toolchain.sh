#!/usr/bin/env bash
# Rebuild the offline validation toolchain used to check this academy.
#
# Everything is installed under $ACADEMY_TOOLS (default: ~/.cache/academy-tools), never
# inside the repository. Nothing here contacts AWS or needs AWS credentials.
#
#   bash scripts/bootstrap-toolchain.sh          # install or refresh
#   source "$ACADEMY_TOOLS/env.sh"               # then use the tools
#   bash scripts/validate-all.sh
#
# Versions are the ones the academy was verified with on 2026-11-15.
# Needs: curl, sha256sum/sha1sum, python3, unzip support in Python, Node 22+ with npm,
# uv (or pip), Java 17+. Optional: Go (TFLint, OPA, Conftest) and Cargo (cfn-guard).
set -euo pipefail

TF_VERSION="1.17.2"
AWS_PROVIDER_VERSION="6.73.0"
CDK_LIB_VERSION="2.277.0"
CDK_CLI_VERSION="2.1148.1"
CDK_ALPHA_VERSION="2.277.0-alpha.0"
CDK_NAG_VERSION="3.0.2"
MERMAID_VERSIONS=("10.9.3" "11" "12.2.0")
PLANTUML_VERSION="1.2026.10"
TFLINT_VERSION="v0.66.0"

T="${ACADEMY_TOOLS:-$HOME/.cache/academy-tools}"
mkdir -p "$T/bin" "$T/dl" "$T/tf-mirror" "$T/java"
OS=linux; ARCH=amd64
case "$(uname -m)" in aarch64|arm64) ARCH=arm64 ;; esac
case "$(uname -s)" in Darwin) OS=darwin ;; esac
log() { printf '\n== %s\n' "$*"; }

unzip_to() { python3 -c "import zipfile,sys; zipfile.ZipFile(sys.argv[1]).extractall(sys.argv[2])" "$1" "$2"; }

log "Terraform $TF_VERSION"
cd "$T/dl"
f="terraform_${TF_VERSION}_${OS}_${ARCH}.zip"
curl -fsSLO "https://releases.hashicorp.com/terraform/${TF_VERSION}/${f}"
curl -fsSLO "https://releases.hashicorp.com/terraform/${TF_VERSION}/terraform_${TF_VERSION}_SHA256SUMS"
grep " ${f}\$" "terraform_${TF_VERSION}_SHA256SUMS" | sha256sum -c -
unzip_to "$f" "$T/bin"; chmod +x "$T/bin/terraform"

log "Provider mirror (checksums verified)"
mirror_provider() {
  local name=$1 version=$2 zip="terraform-provider-${1}_${2}_${OS}_${ARCH}.zip"
  local dest="$T/tf-mirror/registry.terraform.io/hashicorp/$name/$version/${OS}_${ARCH}"
  [ -d "$dest" ] && { echo "have $name $version"; return; }
  curl -fsSLO "https://releases.hashicorp.com/terraform-provider-${name}/${version}/${zip}"
  curl -fsSLO "https://releases.hashicorp.com/terraform-provider-${name}/${version}/terraform-provider-${name}_${version}_SHA256SUMS"
  grep " ${zip}\$" "terraform-provider-${name}_${version}_SHA256SUMS" | sha256sum -c -
  mkdir -p "$dest"; unzip_to "$zip" "$dest"; chmod +x "$dest"/terraform-provider-*
}
mirror_provider aws "$AWS_PROVIDER_VERSION"
for p in archive random null time; do
  v=$(curl -fsSL "https://releases.hashicorp.com/terraform-provider-$p/index.json" | python3 -c \
    "import json,sys,re; vs=[v for v in json.load(sys.stdin)['versions'] if re.fullmatch(r'[0-9.]+',v)]; print(sorted(vs,key=lambda s:[int(x) for x in s.split('.')])[-1])")
  mirror_provider "$p" "$v"
done
cat > "$T/terraformrc" <<EOF
provider_installation {
  filesystem_mirror {
    path    = "$T/tf-mirror"
    include = ["registry.terraform.io/hashicorp/*"]
  }
  direct {
    exclude = ["registry.terraform.io/hashicorp/*"]
  }
}
EOF

log "Node tools (CDK, Mermaid, Jest)"
mkdir -p "$T/node" && cd "$T/node"
[ -f package.json ] || npm init -y >/dev/null
npm install --no-audit --no-fund --loglevel=error \
  "aws-cdk-lib@${CDK_LIB_VERSION}" constructs@10 "aws-cdk@${CDK_CLI_VERSION}" \
  "@aws-cdk/aws-bedrock-alpha@${CDK_ALPHA_VERSION}" "cdk-nag@${CDK_NAG_VERSION}" \
  typescript@~7.0.2 tsx jest@30 @swc/core @swc/jest @types/jest@30 @types/node \
  "mermaid@${MERMAID_VERSIONS[2]}" markdownlint-cli2 playwright
for v in "${MERMAID_VERSIONS[@]:0:2}"; do
  d="$T/node-m${v%%.*}"; mkdir -p "$d"; (cd "$d" && { [ -f package.json ] || npm init -y >/dev/null; } && npm install --no-audit --no-fund --loglevel=error "mermaid@$v")
done
echo "If Chromium is not installed for Playwright: (cd $T/node && npx playwright install chromium)"

log "Python tools (cfn-lint, yamllint, Checkov, pytest, boto3)"
if command -v uv >/dev/null 2>&1; then
  [ -x "$T/py/bin/python" ] || uv venv -q "$T/py"
  uv pip install -q --python "$T/py/bin/python" cfn-lint yamllint checkov pytest boto3 pyyaml
else
  python3 -m venv "$T/py" && "$T/py/bin/pip" install -q cfn-lint yamllint checkov pytest boto3 pyyaml
fi

log "PlantUML $PLANTUML_VERSION (checksum verified)"
cd "$T/java"
base="https://repo1.maven.org/maven2/net/sourceforge/plantuml/plantuml/${PLANTUML_VERSION}/plantuml-${PLANTUML_VERSION}.jar"
curl -fsSL -o plantuml.jar "$base"; curl -fsSL -o plantuml.jar.sha1 "$base.sha1"
echo "$(cat plantuml.jar.sha1)  plantuml.jar" | sha1sum -c -

if command -v go >/dev/null 2>&1; then
  log "Go tools (TFLint, OPA, Conftest)"
  GOBIN="$T/bin" GOPATH="$T/go" go install "github.com/terraform-linters/tflint@${TFLINT_VERSION}" || echo "TFLint install failed (optional)"
  GOBIN="$T/bin" GOPATH="$T/go" go install github.com/open-policy-agent/opa@latest || echo "OPA install failed (optional)"
  GOBIN="$T/bin" GOPATH="$T/go" go install github.com/open-policy-agent/conftest@latest || echo "Conftest install failed (optional)"
else
  echo "Go not found: skipping TFLint, OPA and Conftest (optional)"
fi
if command -v cargo >/dev/null 2>&1; then
  log "cfn-guard"
  cargo install --quiet --root "$T/cargo" cfn-guard || echo "cfn-guard install failed (optional)"
else
  echo "Cargo not found: skipping cfn-guard (optional)"
fi

cat > "$T/env.sh" <<EOF
# Source this file to use the academy's validation toolchain.
export ACADEMY_TOOLS="$T"
export PATH="$T/bin:$T/cargo/bin:$T/node/node_modules/.bin:$T/py/bin:\$PATH"
export PLANTUML_JAR="$T/java/plantuml.jar"
export TF_CLI_CONFIG_FILE="$T/terraformrc"
export CHECKPOINT_DISABLE=1
export TF_IN_AUTOMATION=1
export AWS_EC2_METADATA_DISABLED=true
EOF

log "Done"
echo "Toolchain in $T"
echo "Next: source \"$T/env.sh\" && bash scripts/validate-all.sh"
