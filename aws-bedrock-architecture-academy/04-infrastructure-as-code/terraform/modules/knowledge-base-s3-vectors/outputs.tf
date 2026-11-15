output "knowledge_base_id" {
  description = "Knowledge base ID. Pass it to Retrieve, RetrieveAndGenerate and StartIngestionJob."
  value       = aws_bedrockagent_knowledge_base.this.id
}

output "knowledge_base_arn" {
  description = "Knowledge base ARN, for scoping bedrock:Retrieve and bedrock:RetrieveAndGenerate in caller policies."
  value       = aws_bedrockagent_knowledge_base.this.arn
}

output "data_source_id" {
  description = "Data source ID. Pass it with the knowledge base ID to StartIngestionJob; nothing is searchable before the first sync."
  value       = aws_bedrockagent_data_source.this.data_source_id
}

output "vector_bucket_arn" {
  description = "ARN of the S3 vector bucket."
  value       = aws_s3vectors_vector_bucket.this.vector_bucket_arn
}

output "vector_index_arn" {
  description = "ARN of the S3 vector index that stores the embeddings."
  value       = aws_s3vectors_index.this.index_arn
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

output "vector_kms_key_policy_statement_json" {
  description = "Key policy statement that lets the S3 Vectors service principal use vector_kms_key_arn. Add it to that key's policy. null when the vector bucket uses SSE-S3."
  value       = local.vector_kms_key_policy_statement == null ? null : jsonencode(local.vector_kms_key_policy_statement)
}
