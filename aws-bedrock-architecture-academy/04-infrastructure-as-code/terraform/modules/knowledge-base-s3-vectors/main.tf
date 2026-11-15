# Customer-managed Amazon Bedrock knowledge base (type VECTOR) on Amazon S3 Vectors,
# with an Amazon S3 data source and a least-privilege service role.
#
# Documented behaviour this module encodes:
#  * Trust: bedrock.amazonaws.com, restricted with aws:SourceAccount and an aws:SourceArn of
#    knowledge-base/* in this account and Region.
#  * Role permissions: bedrock:InvokeModel on the embedding model (plus the documented
#    ListFoundationModels/ListCustomModels statement); s3:ListBucket and s3:GetObject with
#    aws:ResourceAccount; s3vectors:PutVectors, GetVectors, DeleteVectors, QueryVectors and
#    GetIndex on the index ARN; optional KMS statements for encrypted documents, transient
#    ingestion data and SSE-KMS vector buckets.
#  * The index stores float32 vectors only, 1-4096 dimensions, cosine or euclidean; Bedrock's
#    AMAZON_BEDROCK_TEXT and AMAZON_BEDROCK_METADATA keys must be non-filterable (max 10 keys).
#  * Data source operations do not pass a role, so the role is the only boundary on what can
#    be ingested: GetObject is narrowed to the inclusion prefix.
# Sources are listed in README.md.

data "aws_caller_identity" "current" {}
data "aws_partition" "current" {}
data "aws_region" "current" {}

locals {
  account_id = data.aws_caller_identity.current.account_id
  partition  = data.aws_partition.current.partition
  region     = data.aws_region.current.region
  dns_suffix = data.aws_partition.current.dns_suffix

  vector_bucket_name = "${var.name}-vectors"
  index_name         = "${var.name}-index"
  vector_bucket_arn  = "arn:${local.partition}:s3vectors:${local.region}:${local.account_id}:bucket/${local.vector_bucket_name}"
  index_arn          = "${local.vector_bucket_arn}/index/${local.index_name}"

  bucket_owner_account_id = coalesce(var.data_source_bucket_owner_account_id, local.account_id)

  document_object_arn = "${var.data_source_bucket_arn}/${var.inclusion_prefix == null ? "" : var.inclusion_prefix}*"

  non_filterable_metadata_keys = setunion(
    toset(["AMAZON_BEDROCK_TEXT", "AMAZON_BEDROCK_METADATA"]),
    toset(var.additional_non_filterable_metadata_keys),
  )

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
    [
      {
        # Documented on the KB permissions page; these list actions are read-only metadata calls.
        Sid      = "ListEmbeddingModels"
        Effect   = "Allow"
        Action   = ["bedrock:ListFoundationModels", "bedrock:ListCustomModels"]
        Resource = "*"
      },
      {
        Sid      = "InvokeEmbeddingModel"
        Effect   = "Allow"
        Action   = "bedrock:InvokeModel"
        Resource = var.embedding_model_arn
      },
      {
        Sid       = "S3ListBucketStatement"
        Effect    = "Allow"
        Action    = "s3:ListBucket"
        Resource  = var.data_source_bucket_arn
        Condition = { StringEquals = { "aws:ResourceAccount" = local.bucket_owner_account_id } }
      },
      {
        Sid       = "S3GetObjectStatement"
        Effect    = "Allow"
        Action    = "s3:GetObject"
        Resource  = local.document_object_arn
        Condition = { StringEquals = { "aws:ResourceAccount" = local.bucket_owner_account_id } }
      },
      {
        Sid      = "S3VectorBucketReadAndWritePermission"
        Effect   = "Allow"
        Action   = ["s3vectors:PutVectors", "s3vectors:GetVectors", "s3vectors:DeleteVectors", "s3vectors:QueryVectors", "s3vectors:GetIndex"]
        Resource = local.index_arn
      },
    ],
    var.data_source_kms_key_arn == null ? [] : [{
      Sid       = "DecryptDocumentsThroughS3"
      Effect    = "Allow"
      Action    = "kms:Decrypt"
      Resource  = var.data_source_kms_key_arn
      Condition = { StringEquals = { "kms:ViaService" = "s3.${local.region}.${local.dns_suffix}" } }
    }],
    var.transient_data_kms_key_arn == null ? [] : [{
      Sid      = "TransientIngestionDataKey"
      Effect   = "Allow"
      Action   = ["kms:GenerateDataKey", "kms:Decrypt"]
      Resource = var.transient_data_kms_key_arn
    }],
    var.vector_kms_key_arn == null ? [] : [{
      Sid       = "UseVectorBucketKeyThroughS3Vectors"
      Effect    = "Allow"
      Action    = ["kms:Decrypt", "kms:GenerateDataKey"]
      Resource  = var.vector_kms_key_arn
      Condition = { StringEquals = { "kms:ViaService" = "s3vectors.${local.region}.${local.dns_suffix}" } }
    }],
  )

  service_role_policy_json = jsonencode({
    Version   = "2012-10-17"
    Statement = local.service_role_statements
  })

  # Statement the caller must add to the vector bucket's KMS key policy (SSE-KMS only).
  vector_kms_key_policy_statement = var.vector_kms_key_arn == null ? null : {
    Sid       = "AllowS3VectorsServicePrincipal"
    Effect    = "Allow"
    Principal = { Service = "indexing.s3vectors.amazonaws.com" }
    Action    = "kms:Decrypt"
    Resource  = "*"
    Condition = {
      ArnLike      = { "aws:SourceArn" = "arn:${local.partition}:s3vectors:${local.region}:${local.account_id}:bucket/*" }
      StringEquals = { "aws:SourceAccount" = local.account_id }
      "ForAnyValue:StringEquals" = {
        "kms:EncryptionContextKeys" = ["aws:s3vectors:arn", "aws:s3vectors:resource-id"]
      }
    }
  }

  chunking = {
    FIXED_SIZE   = { fixed = [var.fixed_size_chunking], hierarchical = [], semantic = [] }
    HIERARCHICAL = { fixed = [], hierarchical = [var.hierarchical_chunking], semantic = [] }
    SEMANTIC     = { fixed = [], hierarchical = [], semantic = [var.semantic_chunking] }
    NONE         = { fixed = [], hierarchical = [], semantic = [] }
  }[var.chunking_strategy]
}

# --- Vector store: one vector bucket and one index, owned by this knowledge base -----------

resource "aws_s3vectors_vector_bucket" "this" {
  vector_bucket_name = local.vector_bucket_name
  force_destroy      = var.vector_bucket_force_destroy
  tags               = var.tags

  encryption_configuration = [var.vector_kms_key_arn == null ? {
    sse_type    = "AES256"
    kms_key_arn = null
    } : {
    sse_type    = "aws:kms"
    kms_key_arn = var.vector_kms_key_arn
  }]
}

resource "aws_s3vectors_index" "this" {
  index_name         = local.index_name
  vector_bucket_name = aws_s3vectors_vector_bucket.this.vector_bucket_name
  data_type          = "float32" # S3 Vectors stores floating-point vectors only
  dimension          = var.embedding_dimensions
  distance_metric    = var.distance_metric
  tags               = var.tags

  metadata_configuration {
    non_filterable_metadata_keys = local.non_filterable_metadata_keys
  }
}

# --- Service role ---------------------------------------------------------------------------

resource "aws_iam_role" "this" {
  name                 = "${var.name}-kb-service-role"
  description          = "Assumed by Amazon Bedrock for knowledge base ${var.name}"
  assume_role_policy   = local.trust_policy_json
  permissions_boundary = var.permissions_boundary_arn
  tags                 = var.tags
}

resource "aws_iam_role_policy" "this" {
  name   = "${var.name}-kb-access"
  role   = aws_iam_role.this.id
  policy = local.service_role_policy_json
}

# --- Knowledge base and data source ---------------------------------------------------------

resource "aws_bedrockagent_knowledge_base" "this" {
  name        = var.name
  description = var.description
  role_arn    = aws_iam_role.this.arn
  tags        = var.tags

  knowledge_base_configuration {
    type = "VECTOR"

    vector_knowledge_base_configuration {
      embedding_model_arn = var.embedding_model_arn

      embedding_model_configuration {
        bedrock_embedding_model_configuration {
          dimensions          = var.embedding_dimensions
          embedding_data_type = "FLOAT32"
        }
      }
    }
  }

  storage_configuration {
    type = "S3_VECTORS"

    s3_vectors_configuration {
      # index_arn alone: the API rejects index_arn together with index_name.
      index_arn = aws_s3vectors_index.this.index_arn
    }
  }

  # The role must already reach the model, the documents and the index.
  depends_on = [aws_iam_role_policy.this]
}

resource "aws_bedrockagent_data_source" "this" {
  knowledge_base_id    = aws_bedrockagent_knowledge_base.this.id
  name                 = "${var.name}-s3"
  description          = "Amazon S3 documents for knowledge base ${var.name}"
  data_deletion_policy = var.data_deletion_policy

  data_source_configuration {
    type = "S3"

    s3_configuration {
      bucket_arn              = var.data_source_bucket_arn
      bucket_owner_account_id = local.bucket_owner_account_id
      inclusion_prefixes      = var.inclusion_prefix == null ? null : [var.inclusion_prefix]
    }
  }

  dynamic "server_side_encryption_configuration" {
    for_each = var.transient_data_kms_key_arn == null ? [] : [var.transient_data_kms_key_arn]

    content {
      kms_key_arn = server_side_encryption_configuration.value
    }
  }

  vector_ingestion_configuration {
    chunking_configuration {
      chunking_strategy = var.chunking_strategy

      dynamic "fixed_size_chunking_configuration" {
        for_each = local.chunking.fixed

        content {
          max_tokens         = fixed_size_chunking_configuration.value.max_tokens
          overlap_percentage = fixed_size_chunking_configuration.value.overlap_percentage
        }
      }

      dynamic "hierarchical_chunking_configuration" {
        for_each = local.chunking.hierarchical

        content {
          overlap_tokens = hierarchical_chunking_configuration.value.overlap_tokens

          level_configuration {
            max_tokens = hierarchical_chunking_configuration.value.parent_max_tokens
          }

          level_configuration {
            max_tokens = hierarchical_chunking_configuration.value.child_max_tokens
          }
        }
      }

      dynamic "semantic_chunking_configuration" {
        for_each = local.chunking.semantic

        content {
          max_token                       = semantic_chunking_configuration.value.max_tokens
          buffer_size                     = semantic_chunking_configuration.value.buffer_size
          breakpoint_percentile_threshold = semantic_chunking_configuration.value.breakpoint_percentile_threshold
        }
      }
    }
  }
}
