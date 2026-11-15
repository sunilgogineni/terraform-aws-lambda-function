output "knowledge_base_id" {
  description = "Knowledge base ID. Pass it to Retrieve, AgenticRetrieveStream and StartIngestionJob."
  value       = aws_bedrockagent_knowledge_base.this.id
}

output "knowledge_base_arn" {
  description = "Knowledge base ARN, for scoping bedrock:Retrieve and bedrock:GetDocumentContent in caller policies."
  value       = aws_bedrockagent_knowledge_base.this.arn
}

output "data_source_id" {
  description = "Data source ID. Pass it to StartIngestionJob for an on-demand sync."
  value       = aws_bedrockagent_data_source.this.data_source_id
}

output "service_role_arn" {
  description = "ARN of the knowledge base service role."
  value       = aws_iam_role.this.arn
}

output "service_role_policy_json" {
  description = "The rendered service role policy, for review and tests."
  value       = local.service_role_policy_json
}

output "trust_policy_json" {
  description = "The rendered trust policy of the service role, for review and tests."
  value       = local.trust_policy_json
}

output "connector_parameters_json" {
  description = "The rendered S3 connector parameters sent to CreateDataSource. terraform validate does not check the contents of this JSON string."
  value       = local.connector_parameters_json
}
