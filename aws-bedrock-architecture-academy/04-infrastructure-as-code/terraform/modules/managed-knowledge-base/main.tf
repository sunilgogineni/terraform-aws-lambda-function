# Amazon Bedrock Managed Knowledge Base (type MANAGED) with an Amazon S3 data source
# connected through the managed connector, and a least-privilege service role.
#
# Documented behaviour this module encodes:
#  * A managed knowledge base has knowledge_base_configuration.type = MANAGED and no
#    storage_configuration; embedding is MANAGED (default) or CUSTOM (model ARN plus a
#    1,024-dimension float32 embedding configuration). The type cannot be changed later.
#  * Data sources for managed knowledge bases use type MANAGED_KNOWLEDGE_BASE_CONNECTOR with
#    managedKnowledgeBaseConnectorConfiguration; s3Configuration is for self-managed ones.
#  * S3 connector parameters: type S3, version "1", connectionConfiguration, optional
#    filterConfiguration, metadataFilesPrefix, aclEnabled (permanent) and aclConfiguration.
#  * Deletion protection threshold 0-100 (default 15); sync schedule daily, weekly or monthly.
#  * Service role: trust bedrock.amazonaws.com with aws:SourceAccount and aws:SourceArn;
#    s3:ListBucket and s3:GetObject with aws:ResourceAccount; bedrock:InvokeModel for a custom
#    embedding model; cloudwatch:PutMetricData for the AWS/Bedrock/KnowledgeBases namespace.
#  * With a customer managed key, Bedrock uses a grant created for the identity that creates
#    the knowledge base; the service role needs no key permissions.
# Sources are listed in README.md.

data "aws_caller_identity" "current" {}
data "aws_partition" "current" {}
data "aws_region" "current" {}

locals {
  account_id = data.aws_caller_identity.current.account_id
  partition  = data.aws_partition.current.partition
  region     = data.aws_region.current.region
  dns_suffix = data.aws_partition.current.dns_suffix

  is_custom_embedding     = var.embedding_model_type == "CUSTOM"
  bucket_owner_account_id = coalesce(var.source_bucket_owner_account_id, local.account_id)
  bucket_arn              = "arn:${local.partition}:s3:::${var.source_bucket_name}"
  acl_enabled             = var.acl_global_file_s3_uri != null

  # s3://bucket/key of the global ACL file, as an object ARN.
  acl_file_arn = local.acl_enabled ? format(
    "arn:%s:s3:::%s/%s",
    local.partition,
    regex("^s3://([^/]+)/(.+)$", var.acl_global_file_s3_uri)[0],
    regex("^s3://([^/]+)/(.+)$", var.acl_global_file_s3_uri)[1],
  ) : null

  # Objects the service role may read: the whole bucket, or only what the connector needs.
  readable_object_arns = length(var.inclusion_prefixes) == 0 ? concat(
    ["${local.bucket_arn}/*"],
    local.acl_enabled && !startswith(coalesce(local.acl_file_arn, "-"), "${local.bucket_arn}/") ? [local.acl_file_arn] : [],
    ) : concat(
    [for prefix in var.inclusion_prefixes : "${local.bucket_arn}/${prefix}*"],
    var.metadata_files_prefix == null ? [] : ["${local.bucket_arn}/${var.metadata_files_prefix}*"],
    local.acl_enabled ? [local.acl_file_arn] : [],
  )

  filter_configuration = merge(
    length(var.inclusion_prefixes) > 0 ? { inclusionPrefixes = var.inclusion_prefixes } : {},
    length(var.exclusion_prefixes) > 0 ? { exclusionPrefixes = var.exclusion_prefixes } : {},
    length(var.inclusion_patterns) > 0 ? { inclusionPatterns = var.inclusion_patterns } : {},
    length(var.exclusion_patterns) > 0 ? { exclusionPatterns = var.exclusion_patterns } : {},
    var.max_file_size_mb == null ? {} : { maxFileSizeInMegaBytes = tostring(var.max_file_size_mb) },
  )

  # connector_parameters is a JSON string; its keys are the API's camelCase field names.
  connector_parameters = merge(
    {
      type    = "S3"
      version = "1"
      connectionConfiguration = {
        bucketName           = var.source_bucket_name
        bucketOwnerAccountId = local.bucket_owner_account_id
      }
      aclEnabled = local.acl_enabled
    },
    length(local.filter_configuration) > 0 ? { filterConfiguration = local.filter_configuration } : {},
    var.metadata_files_prefix == null ? {} : { metadataFilesPrefix = var.metadata_files_prefix },
    local.acl_enabled ? { aclConfiguration = { globalAccessControlListS3Uri = var.acl_global_file_s3_uri } } : {},
  )

  connector_parameters_json = jsonencode(local.connector_parameters)

  trust_policy_json = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Sid       = "AmazonBedrockKnowledgeBaseTrust"
      Effect    = "Allow"
      Principal = { Service = "bedrock.amazonaws.com" }
      Action    = "sts:AssumeRole"
      Condition = {
        StringEquals = { "aws:SourceAccount" = local.account_id }
        ArnLike      = { "aws:SourceArn" = "arn:${local.partition}:bedrock:${local.region}:${local.account_id}:knowledge-base/*" }
      }
    }]
  })

  service_role_statements = concat(
    local.is_custom_embedding ? [
      {
        # Documented on the managed KB service role page; read-only list calls.
        Sid      = "ListEmbeddingModels"
        Effect   = "Allow"
        Action   = ["bedrock:ListFoundationModels", "bedrock:ListCustomModels"]
        Resource = "*"
      },
      {
        Sid      = "InvokeCustomEmbeddingModel"
        Effect   = "Allow"
        Action   = "bedrock:InvokeModel"
        Resource = var.custom_embedding_model_arn
      },
    ] : [],
    [
      {
        Sid       = "S3ListBucketStatement"
        Effect    = "Allow"
        Action    = "s3:ListBucket"
        Resource  = local.bucket_arn
        Condition = { StringEquals = { "aws:ResourceAccount" = local.bucket_owner_account_id } }
      },
      {
        Sid       = "S3GetObjectStatement"
        Effect    = "Allow"
        Action    = "s3:GetObject"
        Resource  = local.readable_object_arns
        Condition = { StringEquals = { "aws:ResourceAccount" = local.bucket_owner_account_id } }
      },
    ],
    var.source_kms_key_arn == null ? [] : [{
      Sid       = "DecryptDocumentsThroughS3"
      Effect    = "Allow"
      Action    = "kms:Decrypt"
      Resource  = var.source_kms_key_arn
      Condition = { StringEquals = { "kms:ViaService" = "s3.${local.region}.${local.dns_suffix}" } }
    }],
    var.publish_retrieve_metrics ? [{
      # PutMetricData has no resource ARN; the namespace condition is the scope.
      Sid       = "PublishKnowledgeBaseMetrics"
      Effect    = "Allow"
      Action    = "cloudwatch:PutMetricData"
      Resource  = "*"
      Condition = { StringEquals = { "cloudwatch:namespace" = "AWS/Bedrock/KnowledgeBases" } }
    }] : [],
  )

  service_role_policy_json = jsonencode({
    Version   = "2012-10-17"
    Statement = local.service_role_statements
  })

  sync_schedule = {
    ON_DEMAND = { daily = [], weekly = [], monthly = [] }
    DAILY     = { daily = [1], weekly = [], monthly = [] }
    WEEKLY    = { daily = [], weekly = [var.sync_day_of_week], monthly = [] }
    MONTHLY   = { daily = [], weekly = [], monthly = [var.sync_day_of_month == null ? "LAST" : tostring(var.sync_day_of_month)] }
  }[var.sync_frequency]

  media_extraction_enabled = var.media_extraction.images || var.media_extraction.audio || var.media_extraction.video
}

# --- Service role ---------------------------------------------------------------------------

resource "aws_iam_role" "this" {
  name                 = "${var.name}-kb-service-role"
  description          = "Assumed by Amazon Bedrock for managed knowledge base ${var.name}"
  assume_role_policy   = local.trust_policy_json
  permissions_boundary = var.permissions_boundary_arn
  tags                 = var.tags
}

resource "aws_iam_role_policy" "this" {
  name   = "${var.name}-kb-access"
  role   = aws_iam_role.this.id
  policy = local.service_role_policy_json
}

# --- Managed knowledge base: no storage_configuration ---------------------------------------

resource "aws_bedrockagent_knowledge_base" "this" {
  name        = var.name
  description = var.description
  role_arn    = aws_iam_role.this.arn
  tags        = var.tags

  knowledge_base_configuration {
    type = "MANAGED"

    managed_knowledge_base_configuration {
      embedding_model_type = var.embedding_model_type
      embedding_model_arn  = local.is_custom_embedding ? var.custom_embedding_model_arn : null

      dynamic "embedding_model_configuration" {
        for_each = local.is_custom_embedding ? [1] : []

        content {
          bedrock_embedding_model_configuration {
            # Bring-your-own embedding models must produce 1,024-dimension float32 vectors.
            dimensions          = 1024
            embedding_data_type = "FLOAT32"
          }
        }
      }

      dynamic "server_side_encryption_configuration" {
        for_each = var.kms_key_arn == null ? [] : [var.kms_key_arn]

        content {
          kms_key_arn = server_side_encryption_configuration.value
        }
      }
    }
  }

  depends_on = [aws_iam_role_policy.this]
}

# --- Data source: Amazon S3 through the managed connector -----------------------------------

resource "aws_bedrockagent_data_source" "this" {
  knowledge_base_id = aws_bedrockagent_knowledge_base.this.id
  name              = "${var.name}-s3"
  description       = "Amazon S3 documents (s3://${var.source_bucket_name}) for managed knowledge base ${var.name}"

  data_source_configuration {
    type = "MANAGED_KNOWLEDGE_BASE_CONNECTOR"

    managed_knowledge_base_connector_configuration {
      connector_parameters = local.connector_parameters_json

      deletion_protection_configuration {
        deletion_protection_status    = var.deletion_protection_threshold == null ? "DISABLED" : "ENABLED"
        deletion_protection_threshold = var.deletion_protection_threshold
      }

      dynamic "media_extraction_configuration" {
        for_each = local.media_extraction_enabled ? [1] : []

        content {
          image_extraction_configuration {
            image_extraction_status = var.media_extraction.images ? "ENABLED" : "DISABLED"
          }

          audio_extraction_configuration {
            audio_extraction_status = var.media_extraction.audio ? "ENABLED" : "DISABLED"
          }

          video_extraction_configuration {
            video_extraction_status = var.media_extraction.video ? "ENABLED" : "DISABLED"
          }
        }
      }

      dynamic "sync_schedule" {
        for_each = var.sync_frequency == "ON_DEMAND" ? [] : [1]

        content {
          dynamic "daily" {
            for_each = local.sync_schedule.daily

            content {}
          }

          dynamic "weekly" {
            for_each = local.sync_schedule.weekly

            content {
              day_of_week = weekly.value
            }
          }

          dynamic "monthly" {
            for_each = local.sync_schedule.monthly

            content {
              day_of_month {
                day_number = monthly.value == "LAST" ? null : tonumber(monthly.value)

                dynamic "last_day_of_month" {
                  for_each = monthly.value == "LAST" ? [1] : []

                  content {}
                }
              }
            }
          }
        }
      }
    }
  }

  vector_ingestion_configuration {
    parsing_configuration {
      # The managed parser, as in the AWS and provider examples for managed connectors.
      parsing_strategy = "SMART_PARSING"
    }
  }
}
