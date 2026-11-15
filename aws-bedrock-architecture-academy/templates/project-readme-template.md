# Project X: title

> **Level:** Intermediate · **Verified:** 2026-11-15 · **IaC:** Terraform + AWS CDK · **Time:** ~2 h

> **Code status:** `terraform validate` ✅ · `terraform test` (mock providers) ✅ · `cdk synth` ✅ · Jest ✅ · **never planned or applied against AWS**

What you build, in two sentences, and what you learn from it.

> [!CAUTION]
> **Cost or security hazard** — deploying this creates billable resources. Read "Potential costs"
> and "Teardown" first. Nothing in this repository has been deployed by its authors.

## Learning objectives

- Three to five objectives.

## Prerequisites

- Chapters to read first.
- Tools and versions.
- An AWS sandbox account **only if you choose to deploy**.

## Architecture

Conceptual diagram, then the detailed one. Link to the numbered diagram set.

## Directory structure

```text
project-xx-name/
├── README.md
├── terraform/
│   ├── versions.tf
│   ├── variables.tf
│   ├── main.tf
│   ├── outputs.tf
│   ├── terraform.tfvars.example
│   └── tests/
├── cdk/
│   ├── bin/
│   ├── lib/
│   ├── test/
│   ├── cdk.json
│   ├── package.json
│   └── tsconfig.json
└── src/
```

## What gets created

| Resource | Terraform | CDK / CloudFormation | Purpose |
|:--|:--|:--|:--|
| | | | |

## Resource dependencies

A dependency graph (Mermaid) and a sentence on which dependencies are implicit (references) and
which are explicit (`depends_on` / `addDependency`).

## Security and IAM

Every role, its trust policy and its permissions, with the reason for each statement.

## Configuration

Variables (Terraform) and context/props (CDK), with defaults. Example files contain no secrets.

## Validate without deploying

```bash
# Terraform
terraform -chdir=terraform init -backend=false
terraform -chdir=terraform validate
terraform -chdir=terraform test

# CDK
cd cdk && npm ci && npx tsc --noEmit && npx jest && npx cdk synth
```

## Expected outputs

What the validation commands print, and what `terraform output` / stack outputs would be after a deployment.

## Deploying in your own sandbox (optional)

Commands for the reader, with the cost warning repeated.

## Teardown

Exact commands, and anything that survives a destroy (log groups, buckets with objects, model subscriptions).

## Potential costs

Pricing dimensions and which ones are charged while idle. Link the pricing pages.

## Limitations and unverified parts

Be explicit about anything incomplete, untested or not confirmed against the documentation.

## Knowledge check

1. Question?

<details>
<summary>Answers</summary>

1. Answer.

</details>

## Further reading

- [Page title](https://docs.aws.amazon.com/) — what it covers.
