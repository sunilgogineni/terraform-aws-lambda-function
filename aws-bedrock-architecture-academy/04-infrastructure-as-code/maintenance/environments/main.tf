# One root configuration, deployed four times: dev, test, staging and prod.
#
# The code is identical in every environment. What differs is supplied at run
# time and is reviewed like code:
#   * env/<environment>/backend.hcl          -> which state object (and account) to use
#   * env/<environment>/terraform.tfvars     -> account, model IDs, guardrail version
#
# Promotion means applying the SAME commit with the next environment's files.

provider "aws" {
  region = var.region

  # Refuse to touch any account other than the one this environment owns.
  allowed_account_ids = [var.account_id]

  dynamic "assume_role" {
    for_each = var.deployment_role_arn == null ? [] : [var.deployment_role_arn]
    content {
      role_arn     = assume_role.value
      session_name = "terraform-${var.workload}-${var.environment}"
    }
  }

  default_tags {
    tags = local.tags
  }
}

data "aws_partition" "current" {}

locals {
  name_prefix = "${var.workload}-${var.environment}"

  tags = merge(var.tags, {
    Environment = var.environment
    Workload    = var.workload
    ManagedBy   = "terraform"
  })

  # System-defined inference profile ARNs are account-scoped in the source Region:
  # arn:<partition>:bedrock:<source Region>:<account>:inference-profile/<profile ID>
  inference_profile_arns = [
    for id in var.inference_profile_ids :
    "arn:${data.aws_partition.current.partition}:bedrock:${var.region}:${var.account_id}:inference-profile/${id}"
  ]

  # What the application reads at start-up. Model and guardrail choices are
  # configuration (ADR-010), so changing them is a reviewed tfvars change.
  runtime_config = {
    environment       = var.environment
    model_id          = length(var.inference_profile_ids) > 0 ? var.inference_profile_ids[0] : var.foundation_model_ids[0]
    guardrail_arn     = var.guardrail_arn
    guardrail_version = var.guardrail_arn == null ? null : var.guardrail_version
    max_output_tokens = var.max_output_tokens
  }
}

module "invocation_role" {
  source = "../../terraform/modules/bedrock-invocation-role"

  name             = "${local.name_prefix}-invoke"
  trusted_services = ["lambda.amazonaws.com"]

  foundation_model_ids           = var.foundation_model_ids
  model_regions                  = var.model_regions
  inference_profile_arns         = local.inference_profile_arns
  restrict_to_inference_profiles = length(local.inference_profile_arns) > 0

  guardrail_arns                 = var.guardrail_arn == null ? [] : [var.guardrail_arn]
  required_guardrail_arn_pattern = var.require_guardrail && var.guardrail_arn != null ? "${var.guardrail_arn}:*" : null

  permissions_boundary_arn = var.permissions_boundary_arn
}

# Non-secret runtime configuration. Secrets never go here: see chapter 4.
resource "aws_ssm_parameter" "runtime_config" {
  #checkov:skip=CKV2_AWS_34:Non-secret configuration (model and guardrail IDs); secrets live in Secrets Manager.
  name           = "/${var.workload}/${var.environment}/runtime-config"
  description    = "Bedrock runtime configuration for ${local.name_prefix}"
  type           = "String"
  insecure_value = jsonencode(local.runtime_config)
}
