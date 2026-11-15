# TFLint configuration used by github-actions/terraform-pr.yml.
# Copy it to the repository root. With --recursive, pass it as an absolute path:
#   tflint --init --config "$PWD/.tflint.hcl"
#   tflint --recursive --config "$PWD/.tflint.hcl" --format compact
#
# Code status: validated with TFLint 0.66.0 against the academy's Terraform using the
# bundled terraform plugin only (the aws plugin could not be downloaded offline) - never deployed.

config {
  # Inspect local module calls (source = "../...") but not registry or Git modules.
  call_module_type = "local"
}

# Bundled with TFLint: Terraform language rules (deprecated syntax, unused declarations ...).
plugin "terraform" {
  enabled = true
  preset  = "recommended"
}

# AWS provider rules: invalid instance types, invalid names, deprecated arguments ...
# The version is pinned; `tflint --init` verifies the release (artifact attestation
# where available, otherwise the PGP signature) before installing it.
plugin "aws" {
  enabled = true
  version = "0.50.0"
  source  = "github.com/terraform-linters/tflint-ruleset-aws"
}

# Stricter than the preset: every variable and output carries a description,
# and every module has the standard file layout (main.tf, variables.tf, outputs.tf).
rule "terraform_documented_variables" {
  enabled = true
}

rule "terraform_documented_outputs" {
  enabled = true
}

rule "terraform_standard_module_structure" {
  enabled = true
}
