# Plan-only unit tests with a mock provider: no AWS credentials, nothing is created.

mock_provider "aws" {
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
}

variables {
  name               = "support-kb"
  source_bucket_name = "example-support-docs"
}

run "managed_embedding_defaults" {
  command = plan

  assert {
    condition = (
      aws_bedrockagent_knowledge_base.this.knowledge_base_configuration[0].type == "MANAGED" &&
      aws_bedrockagent_knowledge_base.this.knowledge_base_configuration[0].managed_knowledge_base_configuration[0].embedding_model_type == "MANAGED" &&
      length(aws_bedrockagent_knowledge_base.this.storage_configuration) == 0
    )
    error_message = "A managed knowledge base has type MANAGED, managed embedding and no storage configuration."
  }

  assert {
    condition = (
      aws_bedrockagent_data_source.this.data_source_configuration[0].type == "MANAGED_KNOWLEDGE_BASE_CONNECTOR" &&
      length(aws_bedrockagent_data_source.this.data_source_configuration[0].s3_configuration) == 0 &&
      aws_bedrockagent_data_source.this.data_deletion_policy == "DELETE"
    )
    error_message = "The S3 source must use the managed connector, not s3_configuration."
  }

  assert {
    condition = (
      jsondecode(output.connector_parameters_json).type == "S3" &&
      jsondecode(output.connector_parameters_json).version == "1" &&
      jsondecode(output.connector_parameters_json).connectionConfiguration.bucketName == "example-support-docs" &&
      jsondecode(output.connector_parameters_json).connectionConfiguration.bucketOwnerAccountId == "111122223333" &&
      jsondecode(output.connector_parameters_json).aclEnabled == false
    )
    error_message = "Connector parameters must name the S3 connector, version 1, the bucket and its owner, with ACLs off."
  }

  assert {
    condition = (
      aws_bedrockagent_data_source.this.data_source_configuration[0].managed_knowledge_base_connector_configuration[0].deletion_protection_configuration[0].deletion_protection_status == "ENABLED" &&
      aws_bedrockagent_data_source.this.data_source_configuration[0].managed_knowledge_base_connector_configuration[0].deletion_protection_configuration[0].deletion_protection_threshold == 15 &&
      length(aws_bedrockagent_data_source.this.data_source_configuration[0].managed_knowledge_base_connector_configuration[0].sync_schedule) == 0
    )
    error_message = "Deletion protection must be on at 15% and syncs on demand by default."
  }

  assert {
    condition = toset([for s in jsondecode(output.service_role_policy_json).Statement : s.Sid]) == toset([
      "S3ListBucketStatement", "S3GetObjectStatement", "PublishKnowledgeBaseMetrics",
    ])
    error_message = "With managed embedding the role needs no model permissions."
  }

  assert {
    condition = one([
      for s in jsondecode(output.service_role_policy_json).Statement : s.Condition.StringEquals["cloudwatch:namespace"]
      if s.Sid == "PublishKnowledgeBaseMetrics"
    ]) == "AWS/Bedrock/KnowledgeBases"
    error_message = "PutMetricData must be limited to the knowledge base namespace."
  }
}

run "custom_embedding_model" {
  command = plan

  variables {
    embedding_model_type       = "CUSTOM"
    custom_embedding_model_arn = "arn:aws:bedrock:us-east-1::foundation-model/example.embed-model-v1:0"
    kms_key_arn                = "arn:aws:kms:us-east-1:111122223333:key/11111111-2222-3333-4444-555555555555"
  }

  assert {
    condition = (
      aws_bedrockagent_knowledge_base.this.knowledge_base_configuration[0].managed_knowledge_base_configuration[0].embedding_model_configuration[0].bedrock_embedding_model_configuration[0].dimensions == 1024 &&
      aws_bedrockagent_knowledge_base.this.knowledge_base_configuration[0].managed_knowledge_base_configuration[0].embedding_model_configuration[0].bedrock_embedding_model_configuration[0].embedding_data_type == "FLOAT32"
    )
    error_message = "A custom embedding model must be configured for 1,024 float32 dimensions."
  }

  assert {
    condition = one([
      for s in jsondecode(output.service_role_policy_json).Statement : s.Resource
      if s.Sid == "InvokeCustomEmbeddingModel"
    ]) == "arn:aws:bedrock:us-east-1::foundation-model/example.embed-model-v1:0"
    error_message = "The role must be allowed to invoke exactly the custom model."
  }

  assert {
    condition     = aws_bedrockagent_knowledge_base.this.knowledge_base_configuration[0].managed_knowledge_base_configuration[0].server_side_encryption_configuration[0].kms_key_arn == "arn:aws:kms:us-east-1:111122223333:key/11111111-2222-3333-4444-555555555555"
    error_message = "The customer managed key must be set on the knowledge base."
  }

  assert {
    condition     = length([for s in jsondecode(output.service_role_policy_json).Statement : s if startswith(jsonencode(s.Action), "\"kms:")]) == 0
    error_message = "The service role needs no permissions on the knowledge base key."
  }
}

run "prefixes_metadata_and_acl_narrow_reads" {
  command = plan

  variables {
    inclusion_prefixes     = ["public/"]
    metadata_files_prefix  = "metadata/"
    acl_global_file_s3_uri = "s3://example-support-docs/acl/global-acl.json"
    max_file_size_mb       = 50
  }

  assert {
    condition = one([
      for s in jsondecode(output.service_role_policy_json).Statement : s.Resource
      if s.Sid == "S3GetObjectStatement"
      ]) == [
      "arn:aws:s3:::example-support-docs/public/*",
      "arn:aws:s3:::example-support-docs/metadata/*",
      "arn:aws:s3:::example-support-docs/acl/global-acl.json",
    ]
    error_message = "Reads must be limited to the included prefix, the metadata prefix and the ACL file."
  }

  assert {
    condition = (
      jsondecode(output.connector_parameters_json).aclEnabled == true &&
      jsondecode(output.connector_parameters_json).aclConfiguration.globalAccessControlListS3Uri == "s3://example-support-docs/acl/global-acl.json" &&
      jsondecode(output.connector_parameters_json).filterConfiguration.inclusionPrefixes == ["public/"] &&
      jsondecode(output.connector_parameters_json).filterConfiguration.maxFileSizeInMegaBytes == "50" &&
      jsondecode(output.connector_parameters_json).metadataFilesPrefix == "metadata/"
    )
    error_message = "Connector parameters must carry the ACL, filter and metadata settings."
  }
}

run "weekly_sync_and_media_extraction" {
  command = plan

  variables {
    sync_frequency   = "WEEKLY"
    sync_day_of_week = "MONDAY"
    media_extraction = { images = true }
  }

  assert {
    condition     = aws_bedrockagent_data_source.this.data_source_configuration[0].managed_knowledge_base_connector_configuration[0].sync_schedule[0].weekly[0].day_of_week == "MONDAY"
    error_message = "The weekly schedule must use the chosen day."
  }

  assert {
    condition = (
      aws_bedrockagent_data_source.this.data_source_configuration[0].managed_knowledge_base_connector_configuration[0].media_extraction_configuration[0].image_extraction_configuration[0].image_extraction_status == "ENABLED" &&
      aws_bedrockagent_data_source.this.data_source_configuration[0].managed_knowledge_base_connector_configuration[0].media_extraction_configuration[0].audio_extraction_configuration[0].audio_extraction_status == "DISABLED"
    )
    error_message = "Only image extraction may be enabled."
  }
}

run "monthly_sync_on_last_day" {
  command = plan

  variables {
    sync_frequency = "MONTHLY"
  }

  assert {
    condition     = length(aws_bedrockagent_data_source.this.data_source_configuration[0].managed_knowledge_base_connector_configuration[0].sync_schedule[0].monthly[0].day_of_month[0].last_day_of_month) == 1
    error_message = "A monthly schedule without a day must sync on the last day of the month."
  }
}

run "rejects_custom_type_without_model" {
  command = plan

  variables {
    embedding_model_type = "CUSTOM"
  }

  expect_failures = [var.custom_embedding_model_arn]
}

run "rejects_day_29" {
  command = plan

  variables {
    sync_frequency    = "MONTHLY"
    sync_day_of_month = 29
  }

  expect_failures = [var.sync_day_of_month]
}

run "rejects_threshold_over_100" {
  command = plan

  variables {
    deletion_protection_threshold = 150
  }

  expect_failures = [var.deletion_protection_threshold]
}
