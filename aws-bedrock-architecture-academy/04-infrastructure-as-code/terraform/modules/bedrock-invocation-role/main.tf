# Least-privilege IAM role for calling Amazon Bedrock inference APIs.
#
# Documented behaviour this module encodes:
#  * Converse needs bedrock:InvokeModel; ConverseStream needs bedrock:InvokeModelWithResponseStream.
#  * Invoking through an inference profile needs permission on the profile ARN AND on the
#    foundation model in every Region the profile can route to (Region-less ARN for Global).
#  * bedrock:InferenceProfileArn restricts model invocation to specific inference profiles.
#  * bedrock:GuardrailIdentifier can require a guardrail on every inference call.
# Sources are listed in README.md.

data "aws_partition" "current" {}

locals {
  inference_actions = concat(
    ["bedrock:InvokeModel"],
    var.allow_streaming ? ["bedrock:InvokeModelWithResponseStream"] : [],
  )

  regional_model_arns = [
    for pair in setproduct(var.model_regions, var.foundation_model_ids) :
    "arn:${data.aws_partition.current.partition}:bedrock:${pair[0]}::foundation-model/${pair[1]}"
  ]

  global_model_arns = var.allow_global_inference ? [
    for id in var.foundation_model_ids :
    "arn:${data.aws_partition.current.partition}:bedrock:::foundation-model/${id}"
  ] : []

  model_arns = concat(local.regional_model_arns, local.global_model_arns)

  profile_condition = var.restrict_to_inference_profiles ? {
    StringLike = {
      "bedrock:InferenceProfileArn" = var.inference_profile_arns
    }
  } : null

  statements = concat(
    length(var.inference_profile_arns) > 0 ? [{
      Sid      = "InvokeThroughInferenceProfiles"
      Effect   = "Allow"
      Action   = local.inference_actions
      Resource = var.inference_profile_arns
    }] : [],
    [merge(
      {
        Sid      = "InvokeFoundationModels"
        Effect   = "Allow"
        Action   = local.inference_actions
        Resource = local.model_arns
      },
      local.profile_condition == null ? {} : { Condition = local.profile_condition },
    )],
    length(var.guardrail_arns) > 0 ? [{
      Sid      = "ApplyGuardrails"
      Effect   = "Allow"
      Action   = ["bedrock:ApplyGuardrail"]
      Resource = var.guardrail_arns
    }] : [],
    var.required_guardrail_arn_pattern != null ? [{
      Sid      = "DenyInferenceWithoutRequiredGuardrail"
      Effect   = "Deny"
      Action   = ["bedrock:InvokeModel", "bedrock:InvokeModelWithResponseStream"]
      Resource = "*"
      Condition = {
        ArnNotLike = {
          "bedrock:GuardrailIdentifier" = var.required_guardrail_arn_pattern
        }
      }
    }] : [],
  )

  policy_json = jsonencode({
    Version   = "2012-10-17"
    Statement = local.statements
  })

  trust_statements = concat(
    length(var.trusted_services) > 0 ? [{
      Sid       = "TrustedServices"
      Effect    = "Allow"
      Action    = "sts:AssumeRole"
      Principal = { Service = var.trusted_services }
    }] : [],
    length(var.trusted_role_arns) > 0 ? [{
      Sid       = "TrustedPrincipals"
      Effect    = "Allow"
      Action    = "sts:AssumeRole"
      Principal = { AWS = var.trusted_role_arns }
    }] : [],
  )

  trust_policy_json = jsonencode({
    Version   = "2012-10-17"
    Statement = local.trust_statements
  })
}

resource "aws_iam_role" "this" {
  name                 = var.name
  description          = "Invokes Amazon Bedrock models: ${join(", ", var.foundation_model_ids)}"
  assume_role_policy   = local.trust_policy_json
  permissions_boundary = var.permissions_boundary_arn
  tags                 = var.tags

  lifecycle {
    precondition {
      condition     = length(var.trusted_services) + length(var.trusted_role_arns) > 0
      error_message = "Set trusted_services or trusted_role_arns: a role nobody can assume is useless."
    }
    precondition {
      condition     = !var.restrict_to_inference_profiles || length(var.inference_profile_arns) > 0
      error_message = "restrict_to_inference_profiles requires at least one entry in inference_profile_arns."
    }
  }
}

resource "aws_iam_role_policy" "invoke" {
  name   = "${var.name}-bedrock-invoke"
  role   = aws_iam_role.this.id
  policy = local.policy_json
}
