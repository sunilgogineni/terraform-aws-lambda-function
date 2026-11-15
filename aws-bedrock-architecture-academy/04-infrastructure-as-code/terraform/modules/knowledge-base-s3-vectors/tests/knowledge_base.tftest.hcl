# Plan-only unit tests with a mock provider: no AWS credentials, nothing is created.

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

  mock_resource "aws_s3vectors_index" {
    defaults = {
      index_arn = "arn:aws:s3vectors:us-east-1:111122223333:bucket/docs-kb-vectors/index/docs-kb-index"
    }
  }
}

variables {
  name                   = "docs-kb"
  embedding_model_arn    = "arn:aws:bedrock:us-east-1::foundation-model/example.embed-model-v1:0"
  embedding_dimensions   = 1024
  data_source_bucket_arn = "arn:aws:s3:::example-documents"
}

run "vector_store_and_knowledge_base" {
  command = plan

  assert {
    condition = (
      aws_s3vectors_index.this.data_type == "float32" &&
      aws_s3vectors_index.this.dimension == 1024 &&
      aws_s3vectors_index.this.distance_metric == "cosine"
    )
    error_message = "The index must store float32 vectors with the embedding dimensions and the chosen metric."
  }

  assert {
    condition     = aws_bedrockagent_knowledge_base.this.knowledge_base_configuration[0].vector_knowledge_base_configuration[0].embedding_model_configuration[0].bedrock_embedding_model_configuration[0].dimensions == aws_s3vectors_index.this.dimension
    error_message = "Knowledge base and index dimensions must come from the same variable."
  }

  assert {
    condition     = contains(aws_s3vectors_index.this.metadata_configuration[0].non_filterable_metadata_keys, "AMAZON_BEDROCK_TEXT") && contains(aws_s3vectors_index.this.metadata_configuration[0].non_filterable_metadata_keys, "AMAZON_BEDROCK_METADATA")
    error_message = "Bedrock's text and metadata keys must be non-filterable."
  }

  assert {
    condition = (
      aws_bedrockagent_knowledge_base.this.knowledge_base_configuration[0].type == "VECTOR" &&
      aws_bedrockagent_knowledge_base.this.storage_configuration[0].type == "S3_VECTORS" &&
      aws_bedrockagent_knowledge_base.this.storage_configuration[0].s3_vectors_configuration[0].index_arn == "arn:aws:s3vectors:us-east-1:111122223333:bucket/docs-kb-vectors/index/docs-kb-index"
    )
    error_message = "The knowledge base must be type VECTOR on S3_VECTORS storage, pointing at the index ARN."
  }

  assert {
    condition     = one(aws_s3vectors_vector_bucket.this.encryption_configuration).sse_type == "AES256"
    error_message = "Without a key the vector bucket must use SSE-S3."
  }

  assert {
    condition = (
      aws_bedrockagent_data_source.this.data_source_configuration[0].type == "S3" &&
      aws_bedrockagent_data_source.this.data_deletion_policy == "DELETE" &&
      aws_bedrockagent_data_source.this.vector_ingestion_configuration[0].chunking_configuration[0].fixed_size_chunking_configuration[0].max_tokens == 300
    )
    error_message = "Default data source: S3, DELETE policy, fixed-size chunking of 300 tokens."
  }
}

run "least_privilege_service_role" {
  command = plan

  assert {
    condition     = length(jsondecode(output.service_role_policy_json).Statement) == 5
    error_message = "Without KMS keys the role must have exactly the five documented statements."
  }

  assert {
    condition = one([
      for s in jsondecode(output.service_role_policy_json).Statement : s.Resource
      if s.Sid == "S3VectorBucketReadAndWritePermission"
    ]) == "arn:aws:s3vectors:us-east-1:111122223333:bucket/docs-kb-vectors/index/docs-kb-index"
    error_message = "S3 Vectors permissions must be scoped to the one index."
  }

  assert {
    condition = one([
      for s in jsondecode(output.service_role_policy_json).Statement : s.Resource
      if s.Sid == "InvokeEmbeddingModel"
    ]) == "arn:aws:bedrock:us-east-1::foundation-model/example.embed-model-v1:0"
    error_message = "InvokeModel must be scoped to the embedding model."
  }

  assert {
    condition = one([
      for s in jsondecode(output.service_role_policy_json).Statement : s.Condition.StringEquals["aws:ResourceAccount"]
      if s.Sid == "S3GetObjectStatement"
    ]) == "111122223333"
    error_message = "S3 reads must carry the aws:ResourceAccount condition."
  }

  assert {
    condition = (
      jsondecode(output.trust_policy_json).Statement[0].Condition.ArnLike["aws:SourceArn"] == "arn:aws:bedrock:us-east-1:111122223333:knowledge-base/*" &&
      jsondecode(output.trust_policy_json).Statement[0].Condition.StringEquals["aws:SourceAccount"] == "111122223333"
    )
    error_message = "The trust policy must be limited to knowledge bases in this account and Region."
  }

  assert {
    condition     = output.vector_kms_key_policy_statement_json == null
    error_message = "No key policy statement is needed with SSE-S3."
  }
}

run "prefixes_and_keys_narrow_and_extend_the_role" {
  command = plan

  variables {
    inclusion_prefix           = "handbooks/"
    vector_kms_key_arn         = "arn:aws:kms:us-east-1:111122223333:key/11111111-2222-3333-4444-555555555555"
    data_source_kms_key_arn    = "arn:aws:kms:us-east-1:111122223333:key/66666666-7777-8888-9999-000000000000"
    transient_data_kms_key_arn = "arn:aws:kms:us-east-1:111122223333:key/aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee"
  }

  assert {
    condition = one([
      for s in jsondecode(output.service_role_policy_json).Statement : s.Resource
      if s.Sid == "S3GetObjectStatement"
    ]) == "arn:aws:s3:::example-documents/handbooks/*"
    error_message = "GetObject must be limited to the inclusion prefix."
  }

  assert {
    condition     = length(jsondecode(output.service_role_policy_json).Statement) == 8
    error_message = "Each KMS key must add exactly one statement."
  }

  assert {
    condition = (
      one(aws_s3vectors_vector_bucket.this.encryption_configuration).sse_type == "aws:kms" &&
      aws_bedrockagent_data_source.this.server_side_encryption_configuration[0].kms_key_arn == "arn:aws:kms:us-east-1:111122223333:key/aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee"
    )
    error_message = "The vector bucket must use SSE-KMS and the data source the transient-data key."
  }

  assert {
    condition     = jsondecode(output.vector_kms_key_policy_statement_json).Principal.Service == "indexing.s3vectors.amazonaws.com"
    error_message = "The key policy statement must name the S3 Vectors indexing service principal."
  }
}

run "semantic_chunking" {
  command = plan

  variables {
    chunking_strategy = "SEMANTIC"
    semantic_chunking = { max_tokens = 512, breakpoint_percentile_threshold = 90 }
  }

  assert {
    condition = (
      aws_bedrockagent_data_source.this.vector_ingestion_configuration[0].chunking_configuration[0].semantic_chunking_configuration[0].max_token == 512 &&
      length(aws_bedrockagent_data_source.this.vector_ingestion_configuration[0].chunking_configuration[0].fixed_size_chunking_configuration) == 0
    )
    error_message = "Only the semantic chunking block may be rendered for SEMANTIC."
  }
}

run "hierarchical_chunking_has_two_levels" {
  command = plan

  variables {
    chunking_strategy = "HIERARCHICAL"
  }

  assert {
    condition     = length(aws_bedrockagent_data_source.this.vector_ingestion_configuration[0].chunking_configuration[0].hierarchical_chunking_configuration[0].level_configuration) == 2
    error_message = "Hierarchical chunking needs exactly two levels."
  }
}

run "rejects_too_many_dimensions" {
  command = plan

  variables {
    embedding_dimensions = 8192
  }

  expect_failures = [var.embedding_dimensions]
}

run "rejects_wildcard_bucket_arn" {
  command = plan

  variables {
    data_source_bucket_arn = "arn:aws:s3:::example-documents/*"
  }

  expect_failures = [var.data_source_bucket_arn]
}

run "rejects_unknown_chunking_strategy" {
  command = plan

  variables {
    chunking_strategy = "PARAGRAPH"
  }

  expect_failures = [var.chunking_strategy]
}
