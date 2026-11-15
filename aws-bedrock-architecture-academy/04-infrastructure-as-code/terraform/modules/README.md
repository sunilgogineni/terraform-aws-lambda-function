# Reusable Terraform modules

> **Verified:** 2026-11-15 · Terraform ≥ 1.11 · `hashicorp/aws` `~> 6.73` · every module is validated and mock-tested offline, **never applied against AWS**

Small, composable modules for the Bedrock building blocks used throughout the course. The
[practical projects](../../../05-practical-projects/README.md) and the
[environment examples](../../maintenance/environments/) are built from them.

[Terraform chapters](../README.md) · [Modules chapter](../03-modules.md) · [Module and construct versioning](../../maintenance/02-module-and-construct-versioning.md) · [Generated provider reference](../../../references/terraform-aws-provider-bedrock.md)

## Catalog

| Module | Purpose | Main resources |
|:--|:--|:--|
| [`bedrock-invocation-role`](bedrock-invocation-role/README.md) | Least-privilege role for calling inference APIs, scoped to models, Regions, inference profiles and guardrails | `aws_iam_role`, `aws_iam_role_policy` |
| [`bedrock-guardrail`](bedrock-guardrail/README.md) | A guardrail with content, topic, word and sensitive-information policies, plus a published version | `aws_bedrock_guardrail`, `aws_bedrock_guardrail_version` |
| [`bedrock-invocation-logging`](bedrock-invocation-logging/README.md) | Account-level model invocation logging to CloudWatch Logs and S3 with a customer managed key | `aws_bedrock_model_invocation_logging_configuration`, `aws_cloudwatch_log_group`, `aws_s3_bucket`, `aws_kms_key` |
| [`knowledge-base-s3-vectors`](knowledge-base-s3-vectors/README.md) | Customer-managed knowledge base on Amazon S3 Vectors with an S3 data source | `aws_bedrockagent_knowledge_base`, `aws_bedrockagent_data_source`, `aws_s3vectors_vector_bucket`, `aws_s3vectors_index` |
| [`managed-knowledge-base`](managed-knowledge-base/README.md) | Managed Knowledge Base with an S3 data source | `aws_bedrockagent_knowledge_base`, `aws_bedrockagent_data_source` |
| [`bedrock-private-endpoints`](bedrock-private-endpoints/README.md) | Interface VPC endpoints for the Bedrock services, with a security group and endpoint policies | `aws_vpc_endpoint`, `aws_security_group` |
| [`agentcore-runtime`](agentcore-runtime/README.md) | An AgentCore Runtime with an endpoint and execution role | `aws_bedrockagentcore_agent_runtime`, `aws_bedrockagentcore_agent_runtime_endpoint`, `aws_iam_role` |
| [`terraform-state-backend`](terraform-state-backend/README.md) | S3 bucket for remote state with versioning, encryption and native locking | `aws_s3_bucket` and its configuration resources, `aws_kms_key` |

## Module standard

Every module in this folder follows the same contract.

```text
module-name/
├── README.md          purpose, diagram, inputs, outputs, design notes, limitations
├── versions.tf        required_version and required_providers — no provider block
├── variables.tf       typed, described, validated inputs
├── main.tf            resources and locals
├── outputs.tf         described outputs
└── tests/
    └── *.tftest.hcl   plan-mode tests with a mock provider
```

| Rule | Why |
|:--|:--|
| No `provider` blocks inside a module | The caller decides Region, account and default tags; a module with its own provider cannot be removed cleanly or used with `for_each` |
| `required_providers` with a version constraint in every module | The module states what it was tested with |
| Every variable has a `type` and a `description`; constraints live in `validation` blocks | Errors surface at plan time with a readable message |
| No hard-coded account IDs, Regions, ARNs or model IDs | Reusable across accounts, partitions and model generations |
| Logic that can be pure is in `locals` and exposed through an output | It can be unit-tested with a mock provider |
| At least one `*.tftest.hcl` with plan-mode runs and a mock provider | Tests run in CI without credentials |
| Secure by default: encryption on, public access off, no wildcard permissions | The safe path is the default path |
| Outputs expose IDs and ARNs, never secrets | Outputs are stored in state and shown in logs |
| The README states the code status and the limitations | Readers know how far it was tested |

## Versioning convention

Modules are versioned with [Semantic Versioning](https://semver.org/) and published as Git tags
of the form `module-name/vMAJOR.MINOR.PATCH`.

| Change | Version bump | Example |
|:--|:--|:--|
| Removing or renaming a variable or output; changing a default in a way that changes resources; a change that forces replacement of existing resources | **Major** | Renaming `model_ids` to `foundation_model_ids` |
| A new optional variable or output; a new optional resource behind a flag | **Minor** | Adding `allow_global_inference` defaulting to `false` |
| A fix that does not change the interface or the planned resources for valid inputs | **Patch** | Correcting an error message |

Consumers pin a version and upgrade deliberately:

```hcl
module "invoke_role" {
  source = "git::https://example.com/platform/terraform-modules.git//bedrock-invocation-role?ref=bedrock-invocation-role/v1.2.0"
  # ...
}
```

Inside this repository the projects reference modules by relative path so that everything
validates offline. The full discussion — registries, changelogs, deprecation windows, `moved`
blocks for refactoring without breaking callers — is in
[Module and construct versioning](../../maintenance/02-module-and-construct-versioning.md).

## Validate every module

```bash
bash scripts/validate-terraform.sh 04-infrastructure-as-code/terraform/modules
```

No AWS credentials are needed: `terraform validate` is offline and the tests use mock providers.
