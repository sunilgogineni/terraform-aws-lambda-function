# Changelog

All notable changes to the academy. Dates are ISO 8601. The **verification date** is the day
the facts in a release were last checked against official documentation.

[Academy home](README.md) · [Feature verification matrix](FEATURE-VERIFICATION.md)

## How to record a change

- Add an entry under **Unreleased** with one of: `Added`, `Changed`, `Corrected`, `Removed`, `Re-verified`.
- If you changed a fact, also update the [verification matrix](FEATURE-VERIFICATION.md) and the
  **Verified** date in each chapter you touched.
- When a set of changes is complete, move them under a dated heading.

## Unreleased

_Nothing yet._

## 1.0.0 — 2026-11-15

**Verification date: 2026-11-15** · Terraform 1.17.2 · `hashicorp/aws` 6.73.0 · `aws-cdk-lib` 2.277.0

### Added

- Repository structure, authoring conventions, chapter templates and offline validation scripts.
- Feature verification matrix covering Amazon Bedrock, Amazon Bedrock AgentCore and IaC tooling,
  with an explicit list of unverified items and source conflicts.
- Source register of the primary sources used.
- Terraform and CDK / CloudFormation reference tables generated from the provider schema and the
  installed CDK library.
- Architecture decision records ADR-001 to ADR-015.

Later phases append to this release as they complete; see [PROGRESS.md](PROGRESS.md).
