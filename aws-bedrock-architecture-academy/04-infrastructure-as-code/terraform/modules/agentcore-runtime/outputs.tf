output "agent_runtime_arn" {
  description = "ARN of the agent runtime; pass it to InvokeAgentRuntime."
  value       = aws_bedrockagentcore_agent_runtime.this.agent_runtime_arn
}

output "agent_runtime_id" {
  description = "ID of the agent runtime."
  value       = aws_bedrockagentcore_agent_runtime.this.agent_runtime_id
}

output "agent_runtime_version" {
  description = "Latest version of the agent runtime (the one DEFAULT points at)."
  value       = aws_bedrockagentcore_agent_runtime.this.agent_runtime_version
}

output "endpoint_arn" {
  description = "ARN of the endpoint created by this module."
  value       = aws_bedrockagentcore_agent_runtime_endpoint.this.agent_runtime_endpoint_arn
}

output "endpoint_name" {
  description = "Name of the endpoint; pass it as the qualifier of InvokeAgentRuntime."
  value       = aws_bedrockagentcore_agent_runtime_endpoint.this.name
}

output "workload_identity_arn" {
  description = "ARN of the workload identity AgentCore created for the runtime (null until known)."
  value       = try(aws_bedrockagentcore_agent_runtime.this.workload_identity_details[0].workload_identity_arn, null)
}

output "execution_role_arn" {
  description = "ARN of the execution role."
  value       = aws_iam_role.execution.arn
}

output "execution_role_name" {
  description = "Name of the execution role, for attaching permissions the agent needs beyond this module (Memory, Gateway, data stores)."
  value       = aws_iam_role.execution.name
}

output "ecr_repository_arn" {
  description = "ECR repository ARN derived from container_uri; the only repository the role can pull from."
  value       = local.ecr_repository_arn
}

output "execution_policy_json" {
  description = "The rendered execution policy, so callers and tests can inspect exactly what was granted."
  value       = local.execution_policy_json
}

output "trust_policy_json" {
  description = "The rendered trust policy of the execution role."
  value       = local.trust_policy_json
}
