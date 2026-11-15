# Terraform AWS provider — Bedrock-related resources

> **Generated from the provider's own schema** — `hashicorp/aws` **6.73.0**, `terraform providers schema -json`, on 2026-11-15.
> Regenerate with `scripts/gen-terraform-reference.py`; do not edit by hand.

Use this file to answer one question quickly: *does a Terraform resource exist for this Bedrock feature, and what are its top-level arguments?* If a type is not listed here, it does not exist in provider 6.73.0. The full nested structure is in [`terraform-aws-provider-bedrock-schema.json`](terraform-aws-provider-bedrock-schema.json).

Related chapters: [Terraform coverage for Amazon Bedrock](../04-infrastructure-as-code/terraform/10-terraform-for-bedrock.md) · [Feature verification matrix](../FEATURE-VERIFICATION.md)

## Summary

| Kind | Bedrock-related types |
|:--|--:|
| Resources | 55 |
| Data sources | 17 |
| Ephemeral resources | 1 |
| List resources (for `terraform query`) | 22 |
| Actions | 0 |

## Resources

### Amazon Bedrock control plane (`bedrock`)

| Type | Required arguments | Optional arguments | Nested blocks |
|:--|:--|:--|:--|
| `aws_bedrock_custom_model` | `base_model_identifier`, `custom_model_name`, `hyperparameters`, `job_name`, `role_arn` | `custom_model_kms_key_id`, `customization_type`, `region`, `tags` | `output_data_config`, `timeouts`, `training_data_config`, `validation_data_config`, `vpc_config` |
| `aws_bedrock_enforced_guardrail_configuration` | `guardrail_arn`, `guardrail_version` | `region` | `model_enforcement`, `selective_content_guarding` |
| `aws_bedrock_evaluation_job` | `job_name`, `role_arn` | `application_type`, `customer_encryption_key_id`, `job_description`, `region`, `skip_destroy`, `tags` | `evaluation_config`, `inference_config`, `output_data_config`, `timeouts` |
| `aws_bedrock_foundation_model_agreement` | `model_id`, `offer_token` | `region` | `timeouts` |
| `aws_bedrock_guardrail` | `blocked_input_messaging`, `blocked_outputs_messaging`, `name` | `description`, `kms_key_arn`, `region`, `tags` | `content_policy_config`, `contextual_grounding_policy_config`, `cross_region_config`, `sensitive_information_policy_config`, `timeouts`, `topic_policy_config`, `word_policy_config` |
| `aws_bedrock_guardrail_resource_policy` | `policy`, `resource_arn` | `region` | — |
| `aws_bedrock_guardrail_version` | `guardrail_arn` | `description`, `region`, `skip_destroy` | `timeouts` |
| `aws_bedrock_inference_profile` | `name` | `description`, `region`, `tags` | `model_source`, `timeouts` |
| `aws_bedrock_model_invocation_job` | `job_name`, `model_id`, `role_arn` | `region`, `skip_destroy`, `timeout_duration_in_hours` | `input_data_config`, `output_data_config`, `timeouts`, `vpc_config` |
| `aws_bedrock_model_invocation_logging_configuration` | — | `region` | `logging_config` |
| `aws_bedrock_provisioned_model_throughput` | `model_arn`, `model_units`, `provisioned_model_name` | `commitment_duration`, `region`, `tags` | `timeouts` |
| `aws_bedrock_use_case_for_model_access` | `form_data` | — | — |

### Agents Classic, Knowledge Bases, Flows, Prompts (`bedrock-agent`)

| Type | Required arguments | Optional arguments | Nested blocks |
|:--|:--|:--|:--|
| `aws_bedrockagent_agent` | `agent_name`, `agent_resource_role_arn`, `foundation_model` | `agent_collaboration`, `customer_encryption_key_arn`, `description`, `guardrail_configuration`, `idle_session_ttl_in_seconds`, `instruction`, `memory_configuration`, `prepare_agent`, `prompt_override_configuration`, `region`, `skip_resource_in_use_check`, `tags` | `timeouts` |
| `aws_bedrockagent_agent_action_group` | `action_group_name`, `agent_id`, `agent_version` | `action_group_state`, `description`, `parent_action_group_signature`, `prepare_agent`, `region`, `skip_resource_in_use_check` | `action_group_executor`, `api_schema`, `function_schema`, `timeouts` |
| `aws_bedrockagent_agent_alias` | `agent_alias_name`, `agent_id` | `description`, `region`, `routing_configuration`, `tags` | `timeouts` |
| `aws_bedrockagent_agent_collaborator` | `agent_id`, `collaboration_instruction`, `collaborator_name` | `agent_version`, `prepare_agent`, `region`, `relay_conversation_history` | `agent_descriptor`, `timeouts` |
| `aws_bedrockagent_agent_knowledge_base_association` | `agent_id`, `description`, `knowledge_base_id`, `knowledge_base_state` | `agent_version`, `region` | `timeouts` |
| `aws_bedrockagent_data_source` | `knowledge_base_id`, `name` | `data_deletion_policy`, `description`, `region` | `data_source_configuration`, `server_side_encryption_configuration`, `timeouts`, `vector_ingestion_configuration` |
| `aws_bedrockagent_flow` | `execution_role_arn`, `name` | `customer_encryption_key_arn`, `description`, `region`, `tags` | `definition`, `timeouts` |
| `aws_bedrockagent_knowledge_base` | `name`, `role_arn` | `description`, `region`, `tags` | `knowledge_base_configuration`, `storage_configuration`, `timeouts` |
| `aws_bedrockagent_prompt` | `name` | `customer_encryption_key_arn`, `default_variant`, `description`, `region`, `tags` | `variant` |

### Amazon Bedrock AgentCore (`bedrock-agentcore-control`)

| Type | Required arguments | Optional arguments | Nested blocks |
|:--|:--|:--|:--|
| `aws_bedrockagentcore_agent_runtime` | `agent_runtime_name`, `role_arn` | `description`, `environment_variables`, `lifecycle_configuration`, `platform_version`, `region`, `tags` | `agent_runtime_artifact`, `authorizer_configuration`, `filesystem_configuration`, `network_configuration`, `protocol_configuration`, `request_header_configuration`, `timeouts` |
| `aws_bedrockagentcore_agent_runtime_endpoint` | `agent_runtime_id`, `name` | `agent_runtime_version`, `description`, `region`, `tags` | `timeouts` |
| `aws_bedrockagentcore_api_key_credential_provider` | `name` | `api_key`, `api_key_secret_source`, `api_key_wo`, `api_key_wo_version`, `region`, `tags` | `api_key_secret_config` |
| `aws_bedrockagentcore_browser` | `name` | `description`, `execution_role_arn`, `region`, `tags` | `browser_signing`, `certificate`, `enterprise_policy`, `network_configuration`, `recording`, `timeouts` |
| `aws_bedrockagentcore_browser_profile` | `name` | `description`, `region`, `tags` | `timeouts` |
| `aws_bedrockagentcore_code_interpreter` | `name` | `description`, `execution_role_arn`, `region`, `tags` | `certificate`, `network_configuration`, `timeouts` |
| `aws_bedrockagentcore_evaluator` | `evaluator_name`, `level` | `description`, `kms_key_arn`, `region`, `tags` | `evaluator_config`, `timeouts` |
| `aws_bedrockagentcore_gateway` | `authorizer_type`, `name`, `role_arn` | `description`, `exception_level`, `kms_key_arn`, `protocol_type`, `region`, `tags` | `authorizer_configuration`, `interceptor_configuration`, `policy_engine_configuration`, `protocol_configuration`, `timeouts` |
| `aws_bedrockagentcore_gateway_rule` | `gateway_identifier`, `priority` | `description`, `region` | `action`, `condition`, `timeouts` |
| `aws_bedrockagentcore_gateway_target` | `gateway_identifier`, `name` | `description`, `region` | `credential_provider_configuration`, `metadata_configuration`, `private_endpoint`, `target_configuration`, `timeouts` |
| `aws_bedrockagentcore_harness` | `execution_role_arn`, `harness_name` | `allowed_tools`, `environment_variables`, `max_iterations`, `max_tokens`, `region`, `tags`, `timeout_seconds`, `truncation` | `authorizer_configuration`, `environment`, `environment_artifact`, `memory`, `model`, `skill`, `system_prompt`, `timeouts`, `tool` |
| `aws_bedrockagentcore_memory` | `event_expiry_duration`, `name` | `description`, `encryption_key_arn`, `memory_execution_role_arn`, `region`, `tags` | `indexed_key`, `stream_delivery_resources`, `timeouts` |
| `aws_bedrockagentcore_memory_strategy` | `memory_id`, `name`, `type` | `description`, `memory_execution_role_arn`, `namespace_templates`, `namespaces`, `region` | `configuration`, `memory_record_schema`, `reflection_configuration`, `timeouts` |
| `aws_bedrockagentcore_oauth2_credential_provider` | `credential_provider_vendor`, `name` | `region`, `tags` | `oauth2_provider_config`, `timeouts` |
| `aws_bedrockagentcore_online_evaluation_config` | `enable_on_create`, `evaluation_execution_role_arn`, `online_evaluation_config_name` | `description`, `execution_status`, `region`, `tags` | `data_source_config`, `evaluator`, `rule`, `timeouts` |
| `aws_bedrockagentcore_policy` | `name`, `policy_engine_id` | `description`, `region`, `validation_mode` | `definition`, `timeouts` |
| `aws_bedrockagentcore_policy_engine` | `name` | `description`, `encryption_key_arn`, `region`, `tags` | `timeouts` |
| `aws_bedrockagentcore_registry` | `name` | `approval_configuration`, `authorizer_type`, `description`, `region` | `authorizer_configuration`, `timeouts` |
| `aws_bedrockagentcore_resource_policy` | `policy`, `resource_arn` | `region` | — |
| `aws_bedrockagentcore_token_vault_cmk` | — | `region`, `token_vault_id` | `kms_configuration` |
| `aws_bedrockagentcore_workload_identity` | `name` | `allowed_resource_oauth2_return_urls`, `region`, `tags` | — |

### Amazon Bedrock Data Automation

| Type | Required arguments | Optional arguments | Nested blocks |
|:--|:--|:--|:--|
| `aws_bedrockdataautomation_blueprint` | `name`, `schema`, `type` | `region`, `tags` | `encryption_configuration` |
| `aws_bedrockdataautomation_library` | `name` | `description`, `region`, `tags` | `encryption_configuration`, `timeouts` |
| `aws_bedrockdataautomation_project` | `name` | `description`, `region`, `tags`, `type` | `custom_output_configuration`, `data_automation_library_configuration`, `encryption_configuration`, `override_configuration`, `standard_output_configuration`, `timeouts` |

### Amazon S3 Vectors (vector store for Knowledge Bases)

| Type | Required arguments | Optional arguments | Nested blocks |
|:--|:--|:--|:--|
| `aws_s3vectors_index` | `data_type`, `dimension`, `distance_metric`, `index_name`, `vector_bucket_name` | `encryption_configuration`, `region`, `tags` | `metadata_configuration` |
| `aws_s3vectors_vector_bucket` | `vector_bucket_name` | `encryption_configuration`, `force_destroy`, `region`, `tags` | — |
| `aws_s3vectors_vector_bucket_policy` | `policy`, `vector_bucket_arn` | `region` | — |

### Amazon OpenSearch Serverless (vector store for Knowledge Bases)

| Type | Required arguments | Optional arguments | Nested blocks |
|:--|:--|:--|:--|
| `aws_opensearchserverless_access_policy` | `name`, `policy`, `type` | `description`, `region` | — |
| `aws_opensearchserverless_collection` | `name` | `collection_group_name`, `description`, `encryption_config`, `region`, `standby_replicas`, `tags`, `type`, `vector_options` | `timeouts` |
| `aws_opensearchserverless_collection_group` | `name`, `standby_replicas` | `capacity_limits`, `description`, `generation`, `region`, `tags` | — |
| `aws_opensearchserverless_lifecycle_policy` | `name`, `policy`, `type` | `description`, `region` | — |
| `aws_opensearchserverless_security_config` | `name`, `type` | `description`, `region` | `iam_federation_options`, `iam_identity_center_options`, `saml_options` |
| `aws_opensearchserverless_security_policy` | `name`, `policy`, `type` | `description`, `region` | — |
| `aws_opensearchserverless_vpc_endpoint` | `name`, `subnet_ids`, `vpc_id` | `region`, `security_group_ids` | `timeouts` |

## Data sources

### Amazon Bedrock control plane (`bedrock`)

| Type | Required arguments | Optional arguments | Nested blocks |
|:--|:--|:--|:--|
| `aws_bedrock_custom_model` | `model_id` | `region` | — |
| `aws_bedrock_custom_models` | — | `region` | — |
| `aws_bedrock_foundation_model` | `model_id` | `region` | — |
| `aws_bedrock_foundation_model_agreement_offers` | `model_id` | `offer_type`, `region` | — |
| `aws_bedrock_foundation_models` | — | `by_customization_type`, `by_inference_type`, `by_output_modality`, `by_provider`, `region` | — |
| `aws_bedrock_inference_profile` | `inference_profile_id` | `region` | — |
| `aws_bedrock_inference_profiles` | — | `region`, `type` | — |
| `aws_bedrock_use_case_for_model_access` | — | — | — |

### Agents Classic, Knowledge Bases, Flows, Prompts (`bedrock-agent`)

| Type | Required arguments | Optional arguments | Nested blocks |
|:--|:--|:--|:--|
| `aws_bedrockagent_agent_versions` | `agent_id` | `region` | `agent_version_summaries` |

### Amazon OpenSearch Serverless (vector store for Knowledge Bases)

| Type | Required arguments | Optional arguments | Nested blocks |
|:--|:--|:--|:--|
| `aws_opensearchserverless_access_policy` | `name`, `type` | `region` | — |
| `aws_opensearchserverless_collection` | — | `id`, `name`, `region` | — |
| `aws_opensearchserverless_collection_group` | — | `id`, `name`, `region` | — |
| `aws_opensearchserverless_collection_groups` | — | `region` | — |
| `aws_opensearchserverless_lifecycle_policy` | `name`, `type` | `region` | — |
| `aws_opensearchserverless_security_config` | `id` | `region` | `iam_federation_options`, `iam_identity_center_options`, `saml_options` |
| `aws_opensearchserverless_security_policy` | `name`, `type` | `id`, `region` | — |
| `aws_opensearchserverless_vpc_endpoint` | `vpc_endpoint_id` | `id`, `region` | — |

## Ephemeral resources

### Bedrock Runtime

| Type | Required arguments | Optional arguments | Nested blocks |
|:--|:--|:--|:--|
| `aws_bedrockruntime_apply_guardrail` | `guardrail_identifier`, `guardrail_version`, `source` | `region` | `content` |

## List resources (for `terraform query`)

### Amazon Bedrock control plane (`bedrock`)

| Type | Required arguments | Optional arguments | Nested blocks |
|:--|:--|:--|:--|
| `aws_bedrock_evaluation_job` | — | `region` | — |
| `aws_bedrock_guardrail_resource_policy` | — | `region` | — |
| `aws_bedrock_model_invocation_job` | — | `region` | — |

### Amazon Bedrock AgentCore (`bedrock-agentcore-control`)

| Type | Required arguments | Optional arguments | Nested blocks |
|:--|:--|:--|:--|
| `aws_bedrockagentcore_browser_profile` | — | `region` | — |
| `aws_bedrockagentcore_evaluator` | — | `region` | — |
| `aws_bedrockagentcore_gateway_rule` | `gateway_identifier` | `region` | — |
| `aws_bedrockagentcore_harness` | — | `region` | — |
| `aws_bedrockagentcore_online_evaluation_config` | — | `region` | — |
| `aws_bedrockagentcore_policy` | `policy_engine_id` | `region` | — |
| `aws_bedrockagentcore_policy_engine` | — | `region` | — |
| `aws_bedrockagentcore_registry` | — | `region` | — |
| `aws_bedrockagentcore_resource_policy` | — | `region` | — |

### Amazon Bedrock Data Automation

| Type | Required arguments | Optional arguments | Nested blocks |
|:--|:--|:--|:--|
| `aws_bedrockdataautomation_blueprint` | — | `region` | — |
| `aws_bedrockdataautomation_library` | — | `region` | — |
| `aws_bedrockdataautomation_project` | — | `region` | — |

### Amazon OpenSearch Serverless (vector store for Knowledge Bases)

| Type | Required arguments | Optional arguments | Nested blocks |
|:--|:--|:--|:--|
| `aws_opensearchserverless_access_policy` | `type` | `region` | — |
| `aws_opensearchserverless_collection` | — | `region` | — |
| `aws_opensearchserverless_collection_group` | — | `region` | — |
| `aws_opensearchserverless_lifecycle_policy` | `type` | `region` | — |
| `aws_opensearchserverless_security_config` | `type` | `region` | — |
| `aws_opensearchserverless_security_policy` | `type` | `region` | — |
| `aws_opensearchserverless_vpc_endpoint` | — | `region` | — |

## How to read this

- **Required / optional** come from the schema flags. Computed-only attributes (outputs) are omitted from the table but are in the JSON.
- A **nested block** such as `knowledge_base_configuration` has its own arguments; look it up in the JSON file.
- The schema says what Terraform accepts, not what the AWS API accepts in every Region or for every model. Always pair it with the AWS documentation for the feature.
- **List resources** are used with `terraform query` (Terraform 1.14+) to discover existing resources for import.
