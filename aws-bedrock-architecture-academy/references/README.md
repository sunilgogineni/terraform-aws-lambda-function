# References

Generated, machine-verified reference material. Chapters cite these files instead of restating
resource names from memory.

[Academy home](../README.md) · [Feature verification matrix](../FEATURE-VERIFICATION.md) · [Source register](../SOURCES.md)

| File | What it is | Generated from | How to regenerate |
|:--|:--|:--|:--|
| [`terraform-aws-provider-bedrock.md`](terraform-aws-provider-bedrock.md) | Every Bedrock-related Terraform resource, data source, ephemeral resource and list resource, with top-level arguments | `terraform providers schema -json` for `hashicorp/aws` 6.73.0 | [`scripts/gen-terraform-reference.py`](../scripts/gen-terraform-reference.py) |
| [`terraform-aws-provider-bedrock-schema.json`](terraform-aws-provider-bedrock-schema.json) | The same data with full nested block structure, for lookups with `jq` | Same schema dump | Same script |
| [`cdk-and-cloudformation-bedrock.md`](cdk-and-cloudformation-bedrock.md) | CloudFormation resource types, their L1 constructs, and the L2 constructs that exist (stable and experimental) | Installed `aws-cdk-lib` 2.277.0 and `@aws-cdk/aws-bedrock-alpha` | [`scripts/gen-cdk-reference.py`](../scripts/gen-cdk-reference.py) |

## Looking something up

```bash
# Does a Terraform resource exist?
jq -r '.resource_schemas | keys[]' references/terraform-aws-provider-bedrock-schema.json | grep knowledge_base

# What arguments does a nested block take?
jq '.resource_schemas.aws_bedrockagent_knowledge_base.blocks.knowledge_base_configuration' \
  references/terraform-aws-provider-bedrock-schema.json
```

## What these files do and do not prove

- They prove what the **tool** accepts in the stated version.
- They do **not** prove what the AWS API accepts for a given Region, model or account. Pair
  them with the AWS documentation linked from each chapter.
- They go stale as soon as a new provider or CDK version ships. The versions are in each file's
  header; regenerate after upgrading.
