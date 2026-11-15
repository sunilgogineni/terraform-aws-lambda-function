# An Amazon S3 bucket for Terraform remote state with native S3 locking (use_lockfile = true).
# No DynamoDB table: DynamoDB-based locking is deprecated.
#
# Documented behaviour this module encodes:
#  * HashiCorp recommends bucket versioning so that state can be recovered.
#  * With use_lockfile, the backend writes <key>.tflock next to the state object and needs
#    s3:GetObject, s3:PutObject and s3:DeleteObject on it; on the state object it needs
#    s3:GetObject and s3:PutObject (never DeleteObject); on the bucket s3:ListBucket.
#  * With kms_key_id set, the backend needs kms:Encrypt, kms:Decrypt and kms:GenerateDataKey,
#    and sends the key in the x-amz-server-side-encryption-aws-kms-key-id header.
#  * S3 bucket policies can deny plain-HTTP requests (aws:SecureTransport) and writes that are
#    not encrypted with a specific KMS key.
# Sources are listed in README.md.

data "aws_partition" "current" {}

data "aws_region" "current" {}

locals {
  bucket_arn = "arn:${data.aws_partition.current.partition}:s3:::${var.bucket_name}"
  kms_alias  = coalesce(var.kms_alias_name, "alias/terraform-state-${var.bucket_name}")

  bucket_policy_statements = concat(
    [
      {
        Sid       = "DenyInsecureTransport"
        Effect    = "Deny"
        Principal = "*"
        Action    = "s3:*"
        Resource  = [local.bucket_arn, "${local.bucket_arn}/*"]
        Condition = { Bool = { "aws:SecureTransport" = "false" } }
      },
      {
        Sid       = "DenyObjectsNotEncryptedWithStateKey"
        Effect    = "Deny"
        Principal = "*"
        Action    = "s3:PutObject"
        Resource  = "${local.bucket_arn}/*"
        Condition = {
          ArnNotEqualsIfExists = { "s3:x-amz-server-side-encryption-aws-kms-key-id" = aws_kms_key.state.arn }
        }
      },
    ],
    var.require_kms_key_header ? [{
      Sid       = "DenyObjectsWithoutKmsKeyHeader"
      Effect    = "Deny"
      Principal = "*"
      Action    = "s3:PutObject"
      Resource  = "${local.bucket_arn}/*"
      Condition = { Null = { "s3:x-amz-server-side-encryption-aws-kms-key-id" = "true" } }
    }] : [],
  )

  bucket_policy_json = jsonencode({
    Version   = "2012-10-17"
    Statement = local.bucket_policy_statements
  })

  # Identity-based policy for whoever runs terraform init/plan/apply against this backend.
  backend_access_policy_json = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid      = "ListStateBucket"
        Effect   = "Allow"
        Action   = "s3:ListBucket"
        Resource = local.bucket_arn
      },
      {
        Sid      = "ReadWriteState"
        Effect   = "Allow"
        Action   = ["s3:GetObject", "s3:PutObject"]
        Resource = [for k in var.state_keys : "${local.bucket_arn}/${k}"]
      },
      {
        Sid      = "ManageLockFiles"
        Effect   = "Allow"
        Action   = ["s3:GetObject", "s3:PutObject", "s3:DeleteObject"]
        Resource = [for k in var.state_keys : "${local.bucket_arn}/${k}.tflock"]
      },
      {
        Sid      = "UseStateKey"
        Effect   = "Allow"
        Action   = ["kms:Encrypt", "kms:Decrypt", "kms:GenerateDataKey"]
        Resource = aws_kms_key.state.arn
      },
    ]
  })

  backend_config = {
    bucket       = var.bucket_name
    region       = data.aws_region.current.region
    encrypt      = true
    kms_key_id   = aws_kms_key.state.arn
    use_lockfile = true
  }
}

resource "aws_kms_key" "state" {
  description             = "Encrypts Terraform state in s3://${var.bucket_name}"
  enable_key_rotation     = true
  rotation_period_in_days = var.kms_rotation_period_in_days
  deletion_window_in_days = var.kms_deletion_window_in_days
  tags                    = var.tags
  # No policy argument: the default key policy lets IAM policies in this account grant use of
  # the key, which is how backend_access_policy_json takes effect.
}

resource "aws_kms_alias" "state" {
  name          = local.kms_alias
  target_key_id = aws_kms_key.state.key_id
}

resource "aws_s3_bucket" "state" {
  bucket        = var.bucket_name
  force_destroy = false
  tags          = var.tags
}

resource "aws_s3_bucket_ownership_controls" "state" {
  bucket = aws_s3_bucket.state.id

  rule {
    object_ownership = "BucketOwnerEnforced"
  }
}

resource "aws_s3_bucket_public_access_block" "state" {
  bucket = aws_s3_bucket.state.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_versioning" "state" {
  bucket = aws_s3_bucket.state.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "state" {
  bucket = aws_s3_bucket.state.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = "aws:kms"
      kms_master_key_id = aws_kms_key.state.arn
    }
    bucket_key_enabled       = true
    blocked_encryption_types = ["SSE-C"]
  }
}

resource "aws_s3_bucket_policy" "state" {
  bucket = aws_s3_bucket.state.id
  policy = local.bucket_policy_json

  depends_on = [aws_s3_bucket_public_access_block.state]
}

resource "aws_s3_bucket_lifecycle_configuration" "state" {
  count = var.noncurrent_version_expiration_days == null ? 0 : 1

  bucket = aws_s3_bucket.state.id

  rule {
    id     = "expire-old-state-versions"
    status = "Enabled"

    filter {}

    noncurrent_version_expiration {
      noncurrent_days           = var.noncurrent_version_expiration_days
      newer_noncurrent_versions = var.noncurrent_versions_to_keep
    }

    # Every lock release deletes <key>.tflock, which leaves a delete marker in a versioned
    # bucket. Once the noncurrent lock versions expire, the marker is removed as well.
    expiration {
      expired_object_delete_marker = true
    }

    abort_incomplete_multipart_upload {
      days_after_initiation = var.abort_incomplete_multipart_upload_days
    }
  }

  depends_on = [aws_s3_bucket_versioning.state]
}
