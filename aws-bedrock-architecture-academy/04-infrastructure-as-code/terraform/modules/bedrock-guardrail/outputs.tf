output "guardrail_arn" {
  description = "ARN of the guardrail (without a version suffix). Use it in IAM policies (bedrock:ApplyGuardrail) and in the bedrock-invocation-role module."
  value       = aws_bedrock_guardrail.this.guardrail_arn
}

output "guardrail_id" {
  description = "Guardrail identifier to pass as guardrailIdentifier in Converse, InvokeModel and ApplyGuardrail calls."
  value       = aws_bedrock_guardrail.this.guardrail_id
}

output "guardrail_version" {
  description = "The published version number to pass as guardrailVersion. null when create_version is false (callers would then have to use DRAFT, which changes with every update)."
  value       = var.create_version ? aws_bedrock_guardrail_version.this[0].version : null
}

output "policy_fingerprint" {
  description = "SHA-256 of the policy configuration. A new version is published whenever it changes."
  value       = local.policy_fingerprint
}

output "content_filter_types" {
  description = "Content filter categories configured, including PROMPT_ATTACK when enabled."
  value       = [for f in local.all_content_filters : f.type]
}
