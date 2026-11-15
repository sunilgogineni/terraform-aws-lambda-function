# Helper module used only by the integration tests: asks the IAM policy simulator
# (iam:SimulatePrincipalPolicy) how IAM would decide hypothetical requests.
# Nothing is created and no Bedrock API is called.

data "aws_iam_principal_policy_simulation" "this" {
  policy_source_arn = var.role_arn
  action_names      = var.action_names
  resource_arns     = var.resource_arns

  dynamic "context" {
    for_each = var.guardrail_identifier == null ? [] : [var.guardrail_identifier]
    content {
      key    = "bedrock:GuardrailIdentifier"
      type   = "string"
      values = [context.value]
    }
  }
}
