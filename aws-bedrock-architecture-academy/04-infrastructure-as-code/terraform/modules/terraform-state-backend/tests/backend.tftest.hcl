# Unit tests for the bucket configuration, the bucket policy and the backend access policy.
# A mock provider is used, so no AWS credentials are needed and nothing is created.
# override_during = plan (Terraform 1.11+) makes the mocked key ARN known at plan time, so the
# policies that embed it can be asserted in plan mode.

mock_provider "aws" {
  override_during = plan

  mock_data "aws_partition" {
    defaults = {
      partition = "aws"
    }
  }

  mock_data "aws_region" {
    defaults = {
      region = "us-east-1"
    }
  }

  mock_resource "aws_kms_key" {
    defaults = {
      arn    = "arn:aws:kms:us-east-1:111122223333:key/1234abcd-12ab-34cd-56ef-1234567890ab"
      key_id = "1234abcd-12ab-34cd-56ef-1234567890ab"
    }
  }
}

variables {
  bucket_name = "academy-tfstate-111122223333-us-east-1"
  state_keys  = ["prod/network/terraform.tfstate", "prod/agents/terraform.tfstate"]
}

run "secure_bucket_defaults" {
  command = plan

  assert {
    condition     = aws_s3_bucket_versioning.state.versioning_configuration[0].status == "Enabled"
    error_message = "Versioning must be enabled for state recovery."
  }

  assert {
    condition     = aws_s3_bucket_ownership_controls.state.rule[0].object_ownership == "BucketOwnerEnforced"
    error_message = "ACLs must be disabled (BucketOwnerEnforced)."
  }

  assert {
    condition = (
      aws_s3_bucket_public_access_block.state.block_public_acls
      && aws_s3_bucket_public_access_block.state.block_public_policy
      && aws_s3_bucket_public_access_block.state.ignore_public_acls
      && aws_s3_bucket_public_access_block.state.restrict_public_buckets
    )
    error_message = "All four Block Public Access settings must be on."
  }

  assert {
    condition = alltrue([
      for r in aws_s3_bucket_server_side_encryption_configuration.state.rule :
      r.apply_server_side_encryption_by_default[0].sse_algorithm == "aws:kms"
      && r.apply_server_side_encryption_by_default[0].kms_master_key_id == "arn:aws:kms:us-east-1:111122223333:key/1234abcd-12ab-34cd-56ef-1234567890ab"
      && r.bucket_key_enabled
    ])
    error_message = "Default encryption must be SSE-KMS with the module's key and an S3 Bucket Key."
  }

  assert {
    condition     = aws_kms_key.state.enable_key_rotation && aws_kms_key.state.rotation_period_in_days == 365
    error_message = "Key rotation must be on."
  }

  assert {
    condition     = aws_s3_bucket.state.force_destroy == false
    error_message = "A state bucket must not be emptied by terraform destroy."
  }

  assert {
    condition = (
      aws_s3_bucket_lifecycle_configuration.state[0].rule[0].noncurrent_version_expiration[0].noncurrent_days == 90
      && aws_s3_bucket_lifecycle_configuration.state[0].rule[0].noncurrent_version_expiration[0].newer_noncurrent_versions == 10
    )
    error_message = "By default noncurrent versions expire after 90 days, keeping the 10 newest."
  }
}

run "bucket_policy_denies_plain_http_and_wrong_encryption" {
  command = plan

  assert {
    condition     = length(jsondecode(output.bucket_policy_json).Statement) == 3
    error_message = "TLS-only, key-enforcement and key-header statements are expected."
  }

  assert {
    condition = (
      jsondecode(output.bucket_policy_json).Statement[0].Condition.Bool["aws:SecureTransport"] == "false"
      && jsondecode(output.bucket_policy_json).Statement[0].Resource == [
        "arn:aws:s3:::academy-tfstate-111122223333-us-east-1",
        "arn:aws:s3:::academy-tfstate-111122223333-us-east-1/*",
      ]
    )
    error_message = "Plain-HTTP requests to the bucket and its objects must be denied."
  }

  assert {
    condition = (
      jsondecode(output.bucket_policy_json).Statement[1].Condition.ArnNotEqualsIfExists["s3:x-amz-server-side-encryption-aws-kms-key-id"]
      == "arn:aws:kms:us-east-1:111122223333:key/1234abcd-12ab-34cd-56ef-1234567890ab"
    )
    error_message = "Writes naming another KMS key must be denied."
  }

  assert {
    condition     = alltrue([for s in jsondecode(output.bucket_policy_json).Statement : s.Effect == "Deny"])
    error_message = "The bucket policy only denies; access comes from identity-based policies."
  }
}

run "backend_access_policy_matches_documented_permissions" {
  command = plan

  assert {
    condition     = jsondecode(output.backend_access_policy_json).Statement[0].Action == "s3:ListBucket"
    error_message = "The backend needs s3:ListBucket on the bucket."
  }

  assert {
    condition = (
      jsondecode(output.backend_access_policy_json).Statement[1].Action == ["s3:GetObject", "s3:PutObject"]
      && contains(jsondecode(output.backend_access_policy_json).Statement[1].Resource, "arn:aws:s3:::academy-tfstate-111122223333-us-east-1/prod/network/terraform.tfstate")
    )
    error_message = "State objects get GetObject and PutObject only, never DeleteObject."
  }

  assert {
    condition = (
      jsondecode(output.backend_access_policy_json).Statement[2].Action == ["s3:GetObject", "s3:PutObject", "s3:DeleteObject"]
      && jsondecode(output.backend_access_policy_json).Statement[2].Resource == [
        "arn:aws:s3:::academy-tfstate-111122223333-us-east-1/prod/network/terraform.tfstate.tflock",
        "arn:aws:s3:::academy-tfstate-111122223333-us-east-1/prod/agents/terraform.tfstate.tflock",
      ]
    )
    error_message = "Each state key gets a matching .tflock lock file with GetObject, PutObject and DeleteObject."
  }

  assert {
    condition     = jsondecode(output.backend_access_policy_json).Statement[3].Action == ["kms:Encrypt", "kms:Decrypt", "kms:GenerateDataKey"]
    error_message = "The documented KMS permissions for kms_key_id are required."
  }

  assert {
    condition     = length([for s in jsondecode(output.backend_access_policy_json).Statement : s if strcontains(jsonencode(s.Action), "dynamodb")]) == 0
    error_message = "No DynamoDB permissions: locking is native to S3."
  }
}

run "backend_config_uses_native_locking" {
  command = plan

  assert {
    condition = output.backend_config == {
      bucket       = "academy-tfstate-111122223333-us-east-1"
      region       = "us-east-1"
      encrypt      = true
      kms_key_id   = "arn:aws:kms:us-east-1:111122223333:key/1234abcd-12ab-34cd-56ef-1234567890ab"
      use_lockfile = true
    }
    error_message = "The backend configuration must enable encryption with the key ARN and native S3 locking."
  }

  assert {
    condition     = strcontains(output.backend_config_hcl, "use_lockfile = true") && !strcontains(output.backend_config_hcl, "dynamodb")
    error_message = "The partial configuration file uses use_lockfile, not a DynamoDB table."
  }

  assert {
    condition     = aws_kms_alias.state.name == "alias/terraform-state-academy-tfstate-111122223333-us-east-1"
    error_message = "The default alias is derived from the bucket name."
  }
}

run "optional_controls_can_be_turned_off" {
  command = plan

  variables {
    require_kms_key_header             = false
    noncurrent_version_expiration_days = null
  }

  assert {
    condition     = length(jsondecode(output.bucket_policy_json).Statement) == 2
    error_message = "Without the header requirement only two deny statements remain."
  }

  assert {
    condition     = length(aws_s3_bucket_lifecycle_configuration.state) == 0
    error_message = "A null expiration disables the lifecycle rule."
  }
}

run "rejects_invalid_bucket_name" {
  command = plan

  variables {
    bucket_name = "Academy.TFState"
  }

  expect_failures = [var.bucket_name]
}

run "rejects_bad_state_key_key_settings_and_alias" {
  command = plan

  variables {
    state_keys                  = ["/prod/terraform.tfstate"]
    kms_deletion_window_in_days = 3
    kms_alias_name              = "alias/aws/s3"
  }

  expect_failures = [var.state_keys, var.kms_deletion_window_in_days, var.kms_alias_name]
}
