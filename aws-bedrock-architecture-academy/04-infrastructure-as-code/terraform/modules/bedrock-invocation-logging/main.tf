# Account-level, per-Region model invocation logging for Amazon Bedrock, delivered to
# CloudWatch Logs and/or Amazon S3 and encrypted with one customer managed KMS key.
#
# Documented behaviour this module encodes:
#  * Destinations must be in the same account and Region as the logging configuration.
#  * S3: bucket policy lets bedrock.amazonaws.com s3:PutObject under
#    <prefix>/AWSLogs/<account>/BedrockModelInvocationLogs/*, conditioned on aws:SourceAccount
#    and aws:SourceArn; with SSE-KMS the key policy lets bedrock.amazonaws.com kms:GenerateDataKey
#    under the same conditions; bucket ACLs must be disabled for the bucket policy to take effect.
#  * CloudWatch Logs: Bedrock assumes a role (trusting bedrock.amazonaws.com with the same
#    conditions) that may logs:CreateLogStream and logs:PutLogEvents on the
#    aws/bedrock/modelinvocations log stream. Bodies over 100 KB and binary data reach
#    CloudWatch Logs only through a large-data S3 location (written under its own prefix here).
#  * A KMS-encrypted log group needs the logs.<region> service principal in the key policy
#    (restricted with kms:EncryptionContext:aws:logs:arn), and principals that call
#    PutLogEvents need KMS permissions through kms:ViaService.
# Sources are listed in README.md.

data "aws_caller_identity" "current" {}
data "aws_partition" "current" {}
data "aws_region" "current" {}

locals {
  account_id = data.aws_caller_identity.current.account_id
  partition  = data.aws_partition.current.partition
  region     = data.aws_region.current.region
  dns_suffix = data.aws_partition.current.dns_suffix

  create_bucket = var.enable_s3 || (var.enable_cloudwatch_logs && var.cloudwatch_large_data_delivery)

  bucket_name   = coalesce(var.s3_bucket_name, "${var.name_prefix}-${local.account_id}-${local.region}")
  bucket_arn    = "arn:${local.partition}:s3:::${local.bucket_name}"
  log_group_arn = "arn:${local.partition}:logs:${local.region}:${local.account_id}:log-group:${var.log_group_name}"

  # S3 destination: Bedrock writes below <prefix>/AWSLogs/<account-id>/BedrockModelInvocationLogs/.
  log_object_prefix = join("/", compact([var.s3_key_prefix, "AWSLogs", local.account_id, "BedrockModelInvocationLogs"]))

  large_data_enabled = var.enable_cloudwatch_logs && var.cloudwatch_large_data_delivery

  # Object paths Bedrock may write to, and the prefixes the lifecycle rule expires.
  bedrock_write_arns = concat(
    var.enable_s3 ? ["${local.bucket_arn}/${local.log_object_prefix}/*"] : [],
    local.large_data_enabled ? ["${local.bucket_arn}/${var.large_data_key_prefix}/*"] : [],
  )
  expiring_prefixes = concat(
    var.enable_s3 ? ["${local.log_object_prefix}/"] : [],
    local.large_data_enabled ? ["${var.large_data_key_prefix}/"] : [],
  )

  # Confused-deputy protection used on every statement that names bedrock.amazonaws.com.
  bedrock_source_conditions = {
    StringEquals = { "aws:SourceAccount" = local.account_id }
    ArnLike      = { "aws:SourceArn" = "arn:${local.partition}:bedrock:${local.region}:${local.account_id}:*" }
  }

  key_policy_statements = concat(
    [{
      # The documented default key policy statement: lets the account manage the key
      # and delegate use through IAM policies, so the key cannot become unmanageable.
      Sid       = "EnableIAMPoliciesForTheAccount"
      Effect    = "Allow"
      Principal = { AWS = "arn:${local.partition}:iam::${local.account_id}:root" }
      Action    = "kms:*"
      Resource  = "*"
    }],
    var.enable_cloudwatch_logs ? [{
      Sid       = "AllowCloudWatchLogsForTheInvocationLogGroup"
      Effect    = "Allow"
      Principal = { Service = "logs.${local.region}.${local.dns_suffix}" }
      Action    = ["kms:Encrypt", "kms:Decrypt", "kms:ReEncrypt*", "kms:GenerateDataKey*", "kms:Describe*"]
      Resource  = "*"
      Condition = {
        ArnEquals = { "kms:EncryptionContext:aws:logs:arn" = local.log_group_arn }
      }
    }] : [],
    local.create_bucket ? [{
      Sid       = "AllowBedrockToEncryptLogObjects"
      Effect    = "Allow"
      Principal = { Service = "bedrock.amazonaws.com" }
      Action    = "kms:GenerateDataKey"
      Resource  = "*"
      Condition = local.bedrock_source_conditions
    }] : [],
  )

  key_policy_json = jsonencode({
    Version   = "2012-10-17"
    Statement = local.key_policy_statements
  })

  bucket_policy_json = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "AmazonBedrockLogsWrite"
        Effect    = "Allow"
        Principal = { Service = "bedrock.amazonaws.com" }
        Action    = "s3:PutObject"
        Resource  = local.bedrock_write_arns
        Condition = local.bedrock_source_conditions
      },
      {
        Sid       = "DenyInsecureTransport"
        Effect    = "Deny"
        Principal = "*"
        Action    = "s3:*"
        Resource  = [local.bucket_arn, "${local.bucket_arn}/*"]
        Condition = { Bool = { "aws:SecureTransport" = "false" } }
      },
    ]
  })

  cloudwatch_trust_policy_json = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Sid       = "AllowBedrockToDeliverInvocationLogs"
      Effect    = "Allow"
      Principal = { Service = "bedrock.amazonaws.com" }
      Action    = "sts:AssumeRole"
      Condition = local.bedrock_source_conditions
    }]
  })

  cloudwatch_log_stream_arn = "${local.log_group_arn}:log-stream:aws/bedrock/modelinvocations"
}

# --- Customer managed KMS key shared by the log group and the bucket -----------------------

resource "aws_kms_key" "this" {
  description             = "${var.name_prefix}: Amazon Bedrock model invocation logs"
  enable_key_rotation     = true
  deletion_window_in_days = var.kms_key_deletion_window_in_days
  policy                  = local.key_policy_json
  tags                    = var.tags
}

# --- CloudWatch Logs destination ------------------------------------------------------------

resource "aws_cloudwatch_log_group" "this" {
  count = var.enable_cloudwatch_logs ? 1 : 0

  name              = var.log_group_name
  retention_in_days = var.log_retention_days
  kms_key_id        = aws_kms_key.this.arn
  tags              = var.tags
}

resource "aws_iam_role" "cloudwatch" {
  count = var.enable_cloudwatch_logs ? 1 : 0

  name               = "${var.name_prefix}-cloudwatch-delivery"
  description        = "Assumed by Amazon Bedrock to write model invocation logs to ${var.log_group_name}"
  assume_role_policy = local.cloudwatch_trust_policy_json
  tags               = var.tags
}

resource "aws_iam_role_policy" "cloudwatch" {
  count = var.enable_cloudwatch_logs ? 1 : 0

  name = "${var.name_prefix}-cloudwatch-delivery"
  role = aws_iam_role.cloudwatch[0].id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid      = "WriteInvocationLogStream"
        Effect   = "Allow"
        Action   = ["logs:CreateLogStream", "logs:PutLogEvents"]
        Resource = local.cloudwatch_log_stream_arn
      },
      {
        Sid      = "UseLogGroupKeyThroughCloudWatchLogs"
        Effect   = "Allow"
        Action   = ["kms:Encrypt", "kms:Decrypt", "kms:GenerateDataKey", "kms:DescribeKey"]
        Resource = aws_kms_key.this.arn
        Condition = {
          StringEquals = { "kms:ViaService" = "logs.${local.region}.${local.dns_suffix}" }
        }
      },
    ]
  })
}

# --- S3 destination -------------------------------------------------------------------------

resource "aws_s3_bucket" "this" {
  count = local.create_bucket ? 1 : 0

  bucket        = local.bucket_name
  force_destroy = var.force_destroy
  tags          = var.tags
}

resource "aws_s3_bucket_ownership_controls" "this" {
  count = local.create_bucket ? 1 : 0

  bucket = aws_s3_bucket.this[0].id

  rule {
    # Disables ACLs, which the documentation requires for the bucket policy to take effect.
    object_ownership = "BucketOwnerEnforced"
  }
}

resource "aws_s3_bucket_public_access_block" "this" {
  count = local.create_bucket ? 1 : 0

  bucket                  = aws_s3_bucket.this[0].id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_versioning" "this" {
  count = local.create_bucket ? 1 : 0

  bucket = aws_s3_bucket.this[0].id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "this" {
  count = local.create_bucket ? 1 : 0

  bucket = aws_s3_bucket.this[0].id

  rule {
    bucket_key_enabled = true

    apply_server_side_encryption_by_default {
      sse_algorithm     = "aws:kms"
      kms_master_key_id = aws_kms_key.this.arn
    }
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "this" {
  count = local.create_bucket && var.s3_log_expiration_days != null ? 1 : 0

  bucket = aws_s3_bucket.this[0].id

  dynamic "rule" {
    for_each = local.expiring_prefixes

    content {
      id     = "expire-${replace(trimsuffix(rule.value, "/"), "/", "-")}"
      status = "Enabled"

      filter {
        prefix = rule.value
      }

      expiration {
        days = var.s3_log_expiration_days
      }

      noncurrent_version_expiration {
        noncurrent_days = 30
      }
    }
  }

  depends_on = [aws_s3_bucket_versioning.this]
}

resource "aws_s3_bucket_policy" "this" {
  count = local.create_bucket ? 1 : 0

  bucket = aws_s3_bucket.this[0].id
  policy = local.bucket_policy_json

  depends_on = [aws_s3_bucket_public_access_block.this, aws_s3_bucket_ownership_controls.this]
}

# --- The logging configuration (one per account and Region) ---------------------------------

resource "aws_bedrock_model_invocation_logging_configuration" "this" {
  logging_config {
    text_data_delivery_enabled      = var.data_delivery.text
    image_data_delivery_enabled     = var.data_delivery.image
    embedding_data_delivery_enabled = var.data_delivery.embedding
    video_data_delivery_enabled     = var.data_delivery.video

    dynamic "cloudwatch_config" {
      for_each = var.enable_cloudwatch_logs ? [1] : []

      content {
        log_group_name = aws_cloudwatch_log_group.this[0].name
        role_arn       = aws_iam_role.cloudwatch[0].arn

        dynamic "large_data_delivery_s3_config" {
          for_each = var.cloudwatch_large_data_delivery ? [1] : []

          content {
            bucket_name = aws_s3_bucket.this[0].bucket
            key_prefix  = var.large_data_key_prefix
          }
        }
      }
    }

    dynamic "s3_config" {
      for_each = var.enable_s3 ? [1] : []

      content {
        bucket_name = aws_s3_bucket.this[0].bucket
        key_prefix  = var.s3_key_prefix == "" ? null : var.s3_key_prefix
      }
    }
  }

  # Create every destination permission before logging is switched on, so that
  # the first deliveries are not refused.
  depends_on = [
    aws_iam_role_policy.cloudwatch,
    aws_s3_bucket_policy.this,
    aws_s3_bucket_server_side_encryption_configuration.this,
  ]
}
