# Plan-only unit tests with a mock provider: no AWS credentials, nothing is created.
# Data sources return fixed values; the KMS key ARN is fixed during plan so that the
# delivery role policy can be inspected.

mock_provider "aws" {
  override_during = plan

  mock_data "aws_caller_identity" {
    defaults = {
      account_id = "111122223333"
    }
  }

  mock_data "aws_partition" {
    defaults = {
      partition  = "aws"
      dns_suffix = "amazonaws.com"
    }
  }

  mock_data "aws_region" {
    defaults = {
      region = "us-east-1"
    }
  }

  mock_resource "aws_kms_key" {
    defaults = {
      arn = "arn:aws:kms:us-east-1:111122223333:key/1234abcd-12ab-34cd-56ef-1234567890ab"
    }
  }
}

run "both_destinations_by_default" {
  command = plan

  assert {
    condition     = aws_bedrock_model_invocation_logging_configuration.this.logging_config[0].cloudwatch_config[0].log_group_name == "/aws/bedrock/model-invocation-logs"
    error_message = "CloudWatch delivery must point at the module's log group."
  }

  assert {
    condition     = aws_bedrock_model_invocation_logging_configuration.this.logging_config[0].s3_config[0].bucket_name == "bedrock-invocation-logs-111122223333-us-east-1"
    error_message = "S3 delivery must point at the derived bucket name."
  }

  assert {
    condition     = aws_bedrock_model_invocation_logging_configuration.this.logging_config[0].cloudwatch_config[0].large_data_delivery_s3_config[0].bucket_name == "bedrock-invocation-logs-111122223333-us-east-1"
    error_message = "Large request and response bodies must go to the same bucket."
  }

  assert {
    condition     = aws_bedrock_model_invocation_logging_configuration.this.logging_config[0].cloudwatch_config[0].large_data_delivery_s3_config[0].key_prefix == "bedrock-large-data"
    error_message = "Large bodies must be written under their own prefix."
  }

  assert {
    condition     = length(aws_s3_bucket_lifecycle_configuration.this[0].rule) == 2
    error_message = "Both the log prefix and the large-data prefix must expire."
  }

  assert {
    condition = (
      aws_s3_bucket_ownership_controls.this[0].rule[0].object_ownership == "BucketOwnerEnforced" &&
      aws_s3_bucket_public_access_block.this[0].block_public_policy &&
      aws_s3_bucket_public_access_block.this[0].restrict_public_buckets &&
      aws_s3_bucket_versioning.this[0].versioning_configuration[0].status == "Enabled"
    )
    error_message = "The bucket must disable ACLs, block public access and enable versioning."
  }

  assert {
    condition     = one(aws_s3_bucket_server_side_encryption_configuration.this[0].rule).apply_server_side_encryption_by_default[0].sse_algorithm == "aws:kms"
    error_message = "The bucket must default to SSE-KMS."
  }

  assert {
    condition = (
      aws_cloudwatch_log_group.this[0].retention_in_days == 90 &&
      aws_cloudwatch_log_group.this[0].kms_key_id == "arn:aws:kms:us-east-1:111122223333:key/1234abcd-12ab-34cd-56ef-1234567890ab"
    )
    error_message = "The log group must have a retention period and use the module's key."
  }

  assert {
    condition     = aws_kms_key.this.enable_key_rotation
    error_message = "Automatic key rotation must be enabled."
  }
}

run "bucket_policy_matches_documentation" {
  command = plan

  assert {
    condition = jsondecode(output.bucket_policy_json).Statement[0].Resource == [
      "arn:aws:s3:::bedrock-invocation-logs-111122223333-us-east-1/bedrock/AWSLogs/111122223333/BedrockModelInvocationLogs/*",
      "arn:aws:s3:::bedrock-invocation-logs-111122223333-us-east-1/bedrock-large-data/*",
    ]
    error_message = "Bedrock may write only under the documented log path and the large-data prefix."
  }

  assert {
    condition = (
      jsondecode(output.bucket_policy_json).Statement[0].Condition.StringEquals["aws:SourceAccount"] == "111122223333" &&
      jsondecode(output.bucket_policy_json).Statement[0].Condition.ArnLike["aws:SourceArn"] == "arn:aws:bedrock:us-east-1:111122223333:*"
    )
    error_message = "The bucket policy must carry the aws:SourceAccount and aws:SourceArn conditions."
  }

  assert {
    condition     = jsondecode(output.bucket_policy_json).Statement[1].Effect == "Deny" && jsondecode(output.bucket_policy_json).Statement[1].Condition.Bool["aws:SecureTransport"] == "false"
    error_message = "Requests without TLS must be denied."
  }

  assert {
    condition     = jsondecode(output.cloudwatch_trust_policy_json).Statement[0].Principal.Service == "bedrock.amazonaws.com"
    error_message = "Only Amazon Bedrock may assume the delivery role."
  }

  assert {
    condition     = jsondecode(aws_iam_role_policy.cloudwatch[0].policy).Statement[0].Resource == "arn:aws:logs:us-east-1:111122223333:log-group:/aws/bedrock/model-invocation-logs:log-stream:aws/bedrock/modelinvocations"
    error_message = "The delivery role may write only to the documented log stream."
  }

  assert {
    condition     = jsondecode(aws_iam_role_policy.cloudwatch[0].policy).Statement[1].Condition.StringEquals["kms:ViaService"] == "logs.us-east-1.amazonaws.com"
    error_message = "The delivery role may use the key only through CloudWatch Logs."
  }
}

run "key_policy_names_documented_principals" {
  command = plan

  assert {
    condition = toset([for s in jsondecode(output.key_policy_json).Statement : s.Sid]) == toset([
      "EnableIAMPoliciesForTheAccount",
      "AllowCloudWatchLogsForTheInvocationLogGroup",
      "AllowBedrockToEncryptLogObjects",
    ])
    error_message = "The key policy must contain the account, CloudWatch Logs and Bedrock statements."
  }

  assert {
    condition = one([
      for s in jsondecode(output.key_policy_json).Statement : s.Condition.ArnEquals["kms:EncryptionContext:aws:logs:arn"]
      if s.Sid == "AllowCloudWatchLogsForTheInvocationLogGroup"
    ]) == "arn:aws:logs:us-east-1:111122223333:log-group:/aws/bedrock/model-invocation-logs"
    error_message = "CloudWatch Logs may use the key only for the invocation log group."
  }

  assert {
    condition = one([
      for s in jsondecode(output.key_policy_json).Statement : s.Action
      if s.Sid == "AllowBedrockToEncryptLogObjects"
    ]) == "kms:GenerateDataKey"
    error_message = "Bedrock needs only kms:GenerateDataKey to write SSE-KMS objects."
  }
}

run "s3_only_without_prefix" {
  command = plan

  variables {
    enable_cloudwatch_logs = false
    s3_key_prefix          = ""
    s3_bucket_name         = "example-invocation-logs"
  }

  assert {
    condition = (
      length(aws_cloudwatch_log_group.this) == 0 &&
      length(aws_iam_role.cloudwatch) == 0 &&
      length(aws_bedrock_model_invocation_logging_configuration.this.logging_config[0].cloudwatch_config) == 0
    )
    error_message = "No CloudWatch resources may be created when CloudWatch delivery is disabled."
  }

  assert {
    condition     = output.s3_log_object_prefix == "AWSLogs/111122223333/BedrockModelInvocationLogs"
    error_message = "An empty prefix must not produce a leading slash."
  }

  assert {
    condition     = jsondecode(output.bucket_policy_json).Statement[0].Resource == ["arn:aws:s3:::example-invocation-logs/AWSLogs/111122223333/BedrockModelInvocationLogs/*"]
    error_message = "Without CloudWatch delivery, Bedrock may write only under the documented log path."
  }

  assert {
    condition     = length([for s in jsondecode(output.key_policy_json).Statement : s if s.Sid == "AllowCloudWatchLogsForTheInvocationLogGroup"]) == 0
    error_message = "The CloudWatch Logs principal must not be in the key policy when CloudWatch delivery is disabled."
  }
}

run "cloudwatch_only_without_large_data" {
  command = plan

  variables {
    enable_s3                      = false
    cloudwatch_large_data_delivery = false
    data_delivery                  = { image = false, video = false }
  }

  assert {
    condition     = length(aws_s3_bucket.this) == 0
    error_message = "No bucket may be created when neither S3 delivery nor large-data delivery is enabled."
  }

  assert {
    condition = (
      aws_bedrock_model_invocation_logging_configuration.this.logging_config[0].text_data_delivery_enabled &&
      !aws_bedrock_model_invocation_logging_configuration.this.logging_config[0].image_data_delivery_enabled &&
      !aws_bedrock_model_invocation_logging_configuration.this.logging_config[0].video_data_delivery_enabled
    )
    error_message = "Data delivery flags must follow var.data_delivery."
  }
}

run "rejects_no_destination" {
  command = plan

  variables {
    enable_s3              = false
    enable_cloudwatch_logs = false
  }

  expect_failures = [var.enable_s3]
}

run "rejects_unsupported_retention" {
  command = plan

  variables {
    log_retention_days = 0
  }

  expect_failures = [var.log_retention_days]
}
