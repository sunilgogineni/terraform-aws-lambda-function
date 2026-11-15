output "environment" {
  description = "The environment this state belongs to."
  value       = var.environment
}

output "role_name" {
  description = "Name of the Bedrock invocation role in this environment."
  value       = module.invocation_role.role_name
}

output "role_arn" {
  description = "ARN of the Bedrock invocation role, for the application stack to use as its execution role."
  value       = module.invocation_role.role_arn
}

output "inference_profile_arns" {
  description = "Inference profile ARNs the role may invoke, built for this environment's account and Region."
  value       = local.inference_profile_arns
}

output "policy_json" {
  description = "The rendered inference policy, for review and for policy-as-code checks."
  value       = module.invocation_role.policy_json
}

output "runtime_config_parameter_name" {
  description = "Parameter Store name the application reads its model and guardrail settings from."
  value       = aws_ssm_parameter.runtime_config.name
}
