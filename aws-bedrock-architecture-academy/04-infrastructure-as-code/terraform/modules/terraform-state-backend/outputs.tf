output "bucket_name" {
  description = "Name of the state bucket."
  value       = aws_s3_bucket.state.bucket
}

output "bucket_arn" {
  description = "ARN of the state bucket."
  value       = aws_s3_bucket.state.arn
}

output "kms_key_arn" {
  description = "ARN of the customer managed key. Use the ARN, not the alias, as kms_key_id: the bucket policy compares the ARN."
  value       = aws_kms_key.state.arn
}

output "kms_alias_name" {
  description = "Alias of the customer managed key, for people and consoles."
  value       = aws_kms_alias.state.name
}

output "backend_config" {
  description = "Values for the S3 backend: bucket, region, encrypt, kms_key_id and use_lockfile. Each root module adds its own key."
  value       = local.backend_config
}

output "backend_config_hcl" {
  description = "The same values as a partial backend configuration file, for terraform init -backend-config=<file>."
  value       = <<-EOT
    bucket       = "${local.backend_config.bucket}"
    region       = "${local.backend_config.region}"
    encrypt      = true
    kms_key_id   = "${local.backend_config.kms_key_id}"
    use_lockfile = true
  EOT
}

output "backend_access_policy_json" {
  description = "Identity-based policy with exactly the S3 and KMS permissions the S3 backend with use_lockfile = true needs for state_keys. Attach it to the role that runs Terraform."
  value       = local.backend_access_policy_json
}

output "bucket_policy_json" {
  description = "The bucket policy attached by this module (TLS only, KMS key enforced on writes)."
  value       = local.bucket_policy_json
}
