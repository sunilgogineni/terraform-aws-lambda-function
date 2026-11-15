# Partial backend configuration (ADR-011): one S3 state object per environment
# per component, with native S3 locking. The settings that are the same in
# every environment live here; bucket, key, Region, KMS key and the state
# access role come from env/<environment>/backend.hcl at init time:
#
#   terraform init -backend-config=env/dev/backend.hcl
#
# A backend block cannot reference variables, which is why the per-environment
# values live in a file instead.
terraform {
  backend "s3" {
    use_lockfile = true # writes <key>.tflock next to the state; no DynamoDB table
    encrypt      = true # server-side encryption of the state and lock files
  }
}
