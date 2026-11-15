output "role_arn" {
  description = "ARN of the role under test. Available only after time_sleep, so readers wait for IAM propagation."
  value       = module.invocation_role.role_arn

  depends_on = [time_sleep.iam_propagation]
}

output "foundation_model_arns" {
  description = "Model ARNs the role should be allowed to invoke."
  value       = module.invocation_role.foundation_model_arns
}

output "guardrail_arn" {
  description = "Guardrail ARN (without version) that every inference call must carry."
  value       = local.guardrail_arn
}

output "region" {
  description = "Region used to build the test ARNs."
  value       = var.region
}
