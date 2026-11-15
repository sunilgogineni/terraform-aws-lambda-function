output "kms_key_arn" {
  description = "ARN of the customer managed key that encrypts the log group and the log bucket. Readers of the logs need kms:Decrypt on it."
  value       = aws_kms_key.this.arn
}

output "log_group_name" {
  description = "Name of the CloudWatch Logs log group, or null when CloudWatch delivery is disabled."
  value       = var.enable_cloudwatch_logs ? aws_cloudwatch_log_group.this[0].name : null
}

output "log_group_arn" {
  description = "ARN of the CloudWatch Logs log group, or null when CloudWatch delivery is disabled."
  value       = var.enable_cloudwatch_logs ? aws_cloudwatch_log_group.this[0].arn : null
}

output "cloudwatch_delivery_role_arn" {
  description = "ARN of the role Amazon Bedrock assumes to write to CloudWatch Logs, or null."
  value       = var.enable_cloudwatch_logs ? aws_iam_role.cloudwatch[0].arn : null
}

output "s3_bucket_name" {
  description = "Name of the log bucket, or null when no bucket is created."
  value       = local.create_bucket ? aws_s3_bucket.this[0].id : null
}

output "s3_bucket_arn" {
  description = "ARN of the log bucket, or null when no bucket is created."
  value       = local.create_bucket ? aws_s3_bucket.this[0].arn : null
}

output "s3_log_object_prefix" {
  description = "Key prefix under which Bedrock writes log objects: <prefix>/AWSLogs/<account-id>/BedrockModelInvocationLogs."
  value       = local.log_object_prefix
}

output "key_policy_json" {
  description = "The rendered KMS key policy, for review and tests."
  value       = local.key_policy_json
}

output "bucket_policy_json" {
  description = "The rendered bucket policy, for review and tests."
  value       = local.bucket_policy_json
}

output "cloudwatch_trust_policy_json" {
  description = "The rendered trust policy of the CloudWatch delivery role, for review and tests."
  value       = local.cloudwatch_trust_policy_json
}
