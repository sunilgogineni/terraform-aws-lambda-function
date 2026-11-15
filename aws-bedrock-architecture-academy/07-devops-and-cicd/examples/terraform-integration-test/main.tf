# Integration-test fixture for the bedrock-invocation-role module.
#
# It creates ONE real IAM role (no Bedrock resources, no model calls) so that the
# tests in integration/ can ask the IAM policy simulator what the role may do.
# Run it only in a sandbox account: see README.md.

provider "aws" {
  region = var.region

  default_tags {
    tags = var.tags
  }
}

data "aws_partition" "current" {}

data "aws_caller_identity" "current" {}

resource "random_id" "suffix" {
  byte_length = 3
}

locals {
  name          = "${var.name_prefix}-${random_id.suffix.hex}"
  guardrail_arn = "arn:${data.aws_partition.current.partition}:bedrock:${var.region}:${data.aws_caller_identity.current.account_id}:guardrail/${var.guardrail_id}"
}

module "invocation_role" {
  source = "../../../04-infrastructure-as-code/terraform/modules/bedrock-invocation-role"

  name                           = local.name
  trusted_services               = ["lambda.amazonaws.com"]
  foundation_model_ids           = var.foundation_model_ids
  model_regions                  = var.model_regions
  guardrail_arns                 = [local.guardrail_arn]
  required_guardrail_arn_pattern = "${local.guardrail_arn}:*"
}

# IAM is eventually consistent: give the new role policy time to propagate
# before the simulation runs read it.
resource "time_sleep" "iam_propagation" {
  create_duration = "20s"

  depends_on = [module.invocation_role]
}
