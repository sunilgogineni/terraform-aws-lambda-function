output "role_arn" {
  description = "ARN of the role. Use it as a Lambda execution role, an ECS task role, or a role to assume."
  value       = aws_iam_role.this.arn
}

output "role_name" {
  description = "Name of the role, for attaching further policies."
  value       = aws_iam_role.this.name
}

output "policy_json" {
  description = "The rendered inference policy, so callers and tests can inspect exactly what was granted."
  value       = local.policy_json
}

output "foundation_model_arns" {
  description = "Every foundation-model ARN the role may invoke."
  value       = local.model_arns
}
