# Amazon Bedrock API operations

> **Generated from the AWS SDK's service models** — `botocore` **1.44.3**, on 2026-11-15.
> Regenerate with `scripts/gen-api-reference.py`; do not edit by hand.

Every operation the SDK knows for the Bedrock family of services, with its HTTP binding. Use it to check that an operation exists, which service namespace it belongs to, and what its request fields are called. Top-level request and response members for every operation are in [`bedrock-api-operations.json`](bedrock-api-operations.json).

[References](README.md) · [Feature verification matrix](../FEATURE-VERIFICATION.md) · [What Amazon Bedrock is: services, namespaces and planes](../01-amazon-bedrock/overview/01-what-is-amazon-bedrock.md)

> [!IMPORTANT]
> **Status** — The OpenAI-compatible and Anthropic-compatible APIs (Responses, Chat Completions, Messages) and the `bedrock-mantle` endpoint are **not** modelled in the AWS SDK, so they do not appear here. They are documented in [Endpoints, APIs and authentication](../01-amazon-bedrock/overview/02-endpoints-apis-and-authentication.md).

## Services

| SDK service name | Endpoint prefix | SigV4 signing name | API version | Operations | What it is for |
|:--|:--|:--|:--|--:|:--|
| `agent-registry` | `agent-registry` | `agent-registry` | 2025-12-01 | 3 | AWS Agent Registry data plane (discovery) |
| `agent-registry-control` | `agent-registry-control` | `agent-registry` | 2025-12-01 | 15 | AWS Agent Registry control plane |
| `bedrock` | `bedrock` | `bedrock` | 2023-04-20 | 108 | Control plane: models, customization, guardrails, evaluation, inference profiles, Provisioned Throughput, batch jobs, logging |
| `bedrock-agent` | `bedrock-agent` | `bedrock` | 2023-06-05 | 86 | Build time for Agents Classic, knowledge bases, data sources, flows and prompts |
| `bedrock-agent-runtime` | `bedrock-agent-runtime` | `bedrock` | 2023-07-26 | 35 | Run time for Agents Classic, knowledge base retrieval, agentic retrieval, flows, reranking, sessions |
| `bedrock-agentcore` | `bedrock-agentcore` | `bedrock-agentcore` | 2024-02-28 | 68 | AgentCore data plane: invoke runtimes and harnesses, memory events, tokens, code interpreter, browser |
| `bedrock-agentcore-control` | `bedrock-agentcore-control` | `bedrock-agentcore` | 2023-06-05 | 172 | AgentCore control plane: runtimes, harnesses, gateways, memory, identity, policy, evaluations |
| `bedrock-data-automation` | `bedrock-data-automation` | `bedrock` | 2023-07-26 | 27 | Bedrock Data Automation build time: projects, blueprints, libraries |
| `bedrock-data-automation-runtime` | `bedrock-data-automation-runtime` | `bedrock` | 2024-06-13 | 6 | Bedrock Data Automation run time: invoke and status |
| `bedrock-runtime` | `bedrock-runtime` | `bedrock` | 2023-09-30 | 11 | Inference data plane: Converse, InvokeModel, ApplyGuardrail, async invoke, token counting |
| `s3vectors` | `s3vectors` | `s3vectors` | 2025-07-15 | 21 | Amazon S3 Vectors: vector buckets, indexes and vector operations |

## `agent-registry`

Agent Registry · 3 operations.

| Operation | HTTP | Path | Required request members |
|:--|:--|:--|:--|
| `BatchGetDiscoverableRegistryRecord` | POST | `/discoverable-records-batch` | `entries` |
| `ListDiscoverableRegistryRecords` | POST | `/registries/{registryId}/discoverable-records-list` | `registryId` |
| `SearchDiscoverableRegistryRecords` | POST | `/discoverable-records-search` | `registryIds`, `searchQuery` |

## `agent-registry-control`

Agent Registry Control · 15 operations.

| Operation | HTTP | Path | Required request members |
|:--|:--|:--|:--|
| `CreateRegistry` | POST | `/registries` | `name` |
| `CreateRegistryRecord` | POST | `/registries/{registryId}/records` | `descriptors`, `name`, `recordType`, `registryId` |
| `DeleteRegistry` | DELETE | `/registries/{registryId}` | `registryId` |
| `DeleteRegistryRecord` | DELETE | `/registries/{registryId}/records/{recordId}` | `recordId`, `registryId` |
| `GetRegistry` | GET | `/registries/{registryId}` | `registryId` |
| `GetRegistryRecord` | GET | `/registries/{registryId}/records/{recordId}` | `recordId`, `registryId` |
| `ListRegistries` | POST | `/registries-list` | — |
| `ListRegistryRecords` | POST | `/registries/{registryId}/records-list` | `registryId` |
| `ListTagsForResource` | GET | `/tags/{resourceArn+}` | `resourceArn` |
| `SubmitRegistryRecordForApproval` | POST | `/registries/{registryId}/records/{recordId}/submit-for-approval` | `recordId`, `registryId` |
| `TagResource` | POST | `/tags/{resourceArn+}` | `resourceArn`, `tags` |
| `UntagResource` | DELETE | `/tags/{resourceArn+}` | `resourceArn`, `tagKeys` |
| `UpdateRegistry` | PATCH | `/registries/{registryId}` | `registryId` |
| `UpdateRegistryRecord` | PATCH | `/registries/{registryId}/records/{recordId}` | `recordId`, `registryId` |
| `UpdateRegistryRecordStatus` | PATCH | `/registries/{registryId}/records/{recordId}/status` | `recordId`, `registryId`, `status`, `statusReason` |

## `bedrock`

Amazon Bedrock · 108 operations.

| Operation | HTTP | Path | Required request members |
|:--|:--|:--|:--|
| `BatchDeleteAdvancedPromptOptimizationJob` | POST | `/advanced-prompt-optimization-job/batch-delete` | `jobIdentifiers` |
| `BatchDeleteEvaluationJob` | POST | `/evaluation-jobs/batch-delete` | `jobIdentifiers` |
| `CancelAutomatedReasoningPolicyBuildWorkflow` | POST | `/automated-reasoning-policies/{policyArn}/build-workflows/{buildWorkflowId}/cancel` | `buildWorkflowId`, `policyArn` |
| `CreateAdvancedPromptOptimizationJob` | POST | `/advanced-prompt-optimization-jobs` | `inputConfig`, `jobName`, `modelConfigurations`, `outputConfig` |
| `CreateAutomatedReasoningPolicy` | POST | `/automated-reasoning-policies` | `name` |
| `CreateAutomatedReasoningPolicyTestCase` | POST | `/automated-reasoning-policies/{policyArn}/test-cases` | `expectedAggregatedFindingsResult`, `guardContent`, `policyArn` |
| `CreateAutomatedReasoningPolicyVersion` | POST | `/automated-reasoning-policies/{policyArn}/versions` | `lastUpdatedDefinitionHash`, `policyArn` |
| `CreateCustomModel` | POST | `/custom-models/create-custom-model` | `modelName` |
| `CreateCustomModelDeployment` | POST | `/model-customization/custom-model-deployments` | `modelArn`, `modelDeploymentName` |
| `CreateEvaluationJob` | POST | `/evaluation-jobs` | `evaluationConfig`, `inferenceConfig`, `jobName`, `outputDataConfig`, `roleArn` |
| `CreateFoundationModelAgreement` | POST | `/create-foundation-model-agreement` | `modelId`, `offerToken` |
| `CreateGuardrail` | POST | `/guardrails` | `blockedInputMessaging`, `blockedOutputsMessaging`, `name` |
| `CreateGuardrailVersion` | POST | `/guardrails/{guardrailIdentifier}` | `guardrailIdentifier` |
| `CreateInferenceProfile` | POST | `/inference-profiles` | `inferenceProfileName`, `modelSource` |
| `CreateMarketplaceModelEndpoint` | POST | `/marketplace-model/endpoints` | `endpointConfig`, `endpointName`, `modelSourceIdentifier` |
| `CreateModelCopyJob` | POST | `/model-copy-jobs` | `sourceModelArn`, `targetModelName` |
| `CreateModelCustomizationJob` | POST | `/model-customization-jobs` | `baseModelIdentifier`, `customModelName`, `jobName`, `outputDataConfig`, `roleArn`, `trainingDataConfig` |
| `CreateModelImportJob` | POST | `/model-import-jobs` | `importedModelName`, `jobName`, `modelDataSource`, `roleArn` |
| `CreateModelInvocationJob` | POST | `/model-invocation-job` | `inputDataConfig`, `jobName`, `modelId`, `outputDataConfig`, `roleArn` |
| `CreatePromptRouter` | POST | `/prompt-routers` | `fallbackModel`, `models`, `promptRouterName`, `routingCriteria` |
| `CreateProvisionedModelThroughput` | POST | `/provisioned-model-throughput` | `modelId`, `modelUnits`, `provisionedModelName` |
| `DeleteAutomatedReasoningPolicy` | DELETE | `/automated-reasoning-policies/{policyArn}` | `policyArn` |
| `DeleteAutomatedReasoningPolicyBuildWorkflow` | DELETE | `/automated-reasoning-policies/{policyArn}/build-workflows/{buildWorkflowId}` | `buildWorkflowId`, `lastUpdatedAt`, `policyArn` |
| `DeleteAutomatedReasoningPolicyTestCase` | DELETE | `/automated-reasoning-policies/{policyArn}/test-cases/{testCaseId}` | `lastUpdatedAt`, `policyArn`, `testCaseId` |
| `DeleteCustomModel` | DELETE | `/custom-models/{modelIdentifier}` | `modelIdentifier` |
| `DeleteCustomModelDeployment` | DELETE | `/model-customization/custom-model-deployments/{customModelDeploymentIdentifier}` | `customModelDeploymentIdentifier` |
| `DeleteEnforcedGuardrailConfiguration` | DELETE | `/enforcedGuardrailsConfiguration/{configId}` | `configId` |
| `DeleteFoundationModelAgreement` | POST | `/delete-foundation-model-agreement` | `modelId` |
| `DeleteGuardrail` | DELETE | `/guardrails/{guardrailIdentifier}` | `guardrailIdentifier` |
| `DeleteImportedModel` | DELETE | `/imported-models/{modelIdentifier}` | `modelIdentifier` |
| `DeleteInferenceProfile` | DELETE | `/inference-profiles/{inferenceProfileIdentifier}` | `inferenceProfileIdentifier` |
| `DeleteMarketplaceModelEndpoint` | DELETE | `/marketplace-model/endpoints/{endpointArn}` | `endpointArn` |
| `DeleteModelInvocationLoggingConfiguration` | DELETE | `/logging/modelinvocations` | — |
| `DeletePromptRouter` | DELETE | `/prompt-routers/{promptRouterArn}` | `promptRouterArn` |
| `DeleteProvisionedModelThroughput` | DELETE | `/provisioned-model-throughput/{provisionedModelId}` | `provisionedModelId` |
| `DeleteResourcePolicy` | DELETE | `/resource-policy/{resourceArn}` | `resourceArn` |
| `DeregisterMarketplaceModelEndpoint` | DELETE | `/marketplace-model/endpoints/{endpointArn}/registration` | `endpointArn` |
| `ExportAutomatedReasoningPolicyVersion` | GET | `/automated-reasoning-policies/{policyArn}/export` | `policyArn` |
| `GetAccountDataRetention` | GET | `/data-retention` | — |
| `GetAdvancedPromptOptimizationJob` | GET | `/advanced-prompt-optimization-jobs/{jobIdentifier}` | `jobIdentifier` |
| `GetAutomatedReasoningPolicy` | GET | `/automated-reasoning-policies/{policyArn}` | `policyArn` |
| `GetAutomatedReasoningPolicyAnnotations` | GET | `/automated-reasoning-policies/{policyArn}/build-workflows/{buildWorkflowId}/annotations` | `buildWorkflowId`, `policyArn` |
| `GetAutomatedReasoningPolicyBuildWorkflow` | GET | `/automated-reasoning-policies/{policyArn}/build-workflows/{buildWorkflowId}` | `buildWorkflowId`, `policyArn` |
| `GetAutomatedReasoningPolicyBuildWorkflowResultAssets` | GET | `/automated-reasoning-policies/{policyArn}/build-workflows/{buildWorkflowId}/result-assets` | `assetType`, `buildWorkflowId`, `policyArn` |
| `GetAutomatedReasoningPolicyNextScenario` | GET | `/automated-reasoning-policies/{policyArn}/build-workflows/{buildWorkflowId}/scenarios` | `buildWorkflowId`, `policyArn` |
| `GetAutomatedReasoningPolicyTestCase` | GET | `/automated-reasoning-policies/{policyArn}/test-cases/{testCaseId}` | `policyArn`, `testCaseId` |
| `GetAutomatedReasoningPolicyTestResult` | GET | `/automated-reasoning-policies/{policyArn}/build-workflows/{buildWorkflowId}/test-cases/{testCaseId}/test-results` | `buildWorkflowId`, `policyArn`, `testCaseId` |
| `GetCustomModel` | GET | `/custom-models/{modelIdentifier}` | `modelIdentifier` |
| `GetCustomModelDeployment` | GET | `/model-customization/custom-model-deployments/{customModelDeploymentIdentifier}` | `customModelDeploymentIdentifier` |
| `GetEvaluationJob` | GET | `/evaluation-jobs/{jobIdentifier}` | `jobIdentifier` |
| `GetFoundationModel` | GET | `/foundation-models/{modelIdentifier}` | `modelIdentifier` |
| `GetFoundationModelAvailability` | GET | `/foundation-model-availability/{modelId}` | `modelId` |
| `GetGuardrail` | GET | `/guardrails/{guardrailIdentifier}` | `guardrailIdentifier` |
| `GetImportedModel` | GET | `/imported-models/{modelIdentifier}` | `modelIdentifier` |
| `GetInferenceProfile` | GET | `/inference-profiles/{inferenceProfileIdentifier}` | `inferenceProfileIdentifier` |
| `GetMarketplaceModelEndpoint` | GET | `/marketplace-model/endpoints/{endpointArn}` | `endpointArn` |
| `GetModelCopyJob` | GET | `/model-copy-jobs/{jobArn}` | `jobArn` |
| `GetModelCustomizationJob` | GET | `/model-customization-jobs/{jobIdentifier}` | `jobIdentifier` |
| `GetModelImportJob` | GET | `/model-import-jobs/{jobIdentifier}` | `jobIdentifier` |
| `GetModelInvocationJob` | GET | `/model-invocation-job/{jobIdentifier}` | `jobIdentifier` |
| `GetModelInvocationLoggingConfiguration` | GET | `/logging/modelinvocations` | — |
| `GetPromptRouter` | GET | `/prompt-routers/{promptRouterArn}` | `promptRouterArn` |
| `GetProvisionedModelThroughput` | GET | `/provisioned-model-throughput/{provisionedModelId}` | `provisionedModelId` |
| `GetResourcePolicy` | GET | `/resource-policy/{resourceArn}` | `resourceArn` |
| `GetUseCaseForModelAccess` | GET | `/use-case-for-model-access` | — |
| `ListAdvancedPromptOptimizationJobs` | GET | `/advanced-prompt-optimization-jobs` | — |
| `ListAutomatedReasoningPolicies` | GET | `/automated-reasoning-policies` | — |
| `ListAutomatedReasoningPolicyBuildWorkflows` | GET | `/automated-reasoning-policies/{policyArn}/build-workflows` | `policyArn` |
| `ListAutomatedReasoningPolicyTestCases` | GET | `/automated-reasoning-policies/{policyArn}/test-cases` | `policyArn` |
| `ListAutomatedReasoningPolicyTestResults` | GET | `/automated-reasoning-policies/{policyArn}/build-workflows/{buildWorkflowId}/test-results` | `buildWorkflowId`, `policyArn` |
| `ListCustomModelDeployments` | GET | `/model-customization/custom-model-deployments` | — |
| `ListCustomModels` | GET | `/custom-models` | — |
| `ListEnforcedGuardrailsConfiguration` | GET | `/enforcedGuardrailsConfiguration` | — |
| `ListEvaluationJobs` | GET | `/evaluation-jobs` | — |
| `ListFoundationModelAgreementOffers` | GET | `/list-foundation-model-agreement-offers/{modelId}` | `modelId` |
| `ListFoundationModels` | GET | `/foundation-models` | — |
| `ListGuardrails` | GET | `/guardrails` | — |
| `ListImportedModels` | GET | `/imported-models` | — |
| `ListInferenceProfiles` | GET | `/inference-profiles` | — |
| `ListMarketplaceModelEndpoints` | GET | `/marketplace-model/endpoints` | — |
| `ListModelCopyJobs` | GET | `/model-copy-jobs` | — |
| `ListModelCustomizationJobs` | GET | `/model-customization-jobs` | — |
| `ListModelImportJobs` | GET | `/model-import-jobs` | — |
| `ListModelInvocationJobs` | GET | `/model-invocation-jobs` | — |
| `ListPromptRouters` | GET | `/prompt-routers` | — |
| `ListProvisionedModelThroughputs` | GET | `/provisioned-model-throughputs` | — |
| `ListTagsForResource` | POST | `/listTagsForResource` | `resourceARN` |
| `PutAccountDataRetention` | PUT | `/data-retention` | `mode` |
| `PutEnforcedGuardrailConfiguration` | PUT | `/enforcedGuardrailsConfiguration` | `guardrailInferenceConfig` |
| `PutModelInvocationLoggingConfiguration` | PUT | `/logging/modelinvocations` | `loggingConfig` |
| `PutResourcePolicy` | POST | `/resource-policy` | `resourceArn`, `resourcePolicy` |
| `PutUseCaseForModelAccess` | POST | `/use-case-for-model-access` | `formData` |
| `RegisterMarketplaceModelEndpoint` | POST | `/marketplace-model/endpoints/{endpointIdentifier}/registration` | `endpointIdentifier`, `modelSourceIdentifier` |
| `StartAutomatedReasoningPolicyBuildWorkflow` | POST | `/automated-reasoning-policies/{policyArn}/build-workflows/{buildWorkflowType}/start` | `buildWorkflowType`, `policyArn`, `sourceContent` |
| `StartAutomatedReasoningPolicyTestWorkflow` | POST | `/automated-reasoning-policies/{policyArn}/build-workflows/{buildWorkflowId}/test-workflows` | `buildWorkflowId`, `policyArn` |
| `StopAdvancedPromptOptimizationJob` | POST | `/advanced-prompt-optimization-jobs/{jobIdentifier}/stop` | `jobIdentifier` |
| `StopEvaluationJob` | POST | `/evaluation-job/{jobIdentifier}/stop` | `jobIdentifier` |
| `StopModelCustomizationJob` | POST | `/model-customization-jobs/{jobIdentifier}/stop` | `jobIdentifier` |
| `StopModelInvocationJob` | POST | `/model-invocation-job/{jobIdentifier}/stop` | `jobIdentifier` |
| `TagResource` | POST | `/tagResource` | `resourceARN`, `tags` |
| `UntagResource` | POST | `/untagResource` | `resourceARN`, `tagKeys` |
| `UpdateAutomatedReasoningPolicy` | PATCH | `/automated-reasoning-policies/{policyArn}` | `policyArn`, `policyDefinition` |
| `UpdateAutomatedReasoningPolicyAnnotations` | PATCH | `/automated-reasoning-policies/{policyArn}/build-workflows/{buildWorkflowId}/annotations` | `annotations`, `buildWorkflowId`, `lastUpdatedAnnotationSetHash`, `policyArn` |
| `UpdateAutomatedReasoningPolicyTestCase` | PATCH | `/automated-reasoning-policies/{policyArn}/test-cases/{testCaseId}` | `expectedAggregatedFindingsResult`, `guardContent`, `lastUpdatedAt`, `policyArn`, `testCaseId` |
| `UpdateCustomModelDeployment` | PATCH | `/model-customization/custom-model-deployments/{customModelDeploymentIdentifier}` | `customModelDeploymentIdentifier`, `modelArn` |
| `UpdateGuardrail` | PUT | `/guardrails/{guardrailIdentifier}` | `blockedInputMessaging`, `blockedOutputsMessaging`, `guardrailIdentifier`, `name` |
| `UpdateMarketplaceModelEndpoint` | PATCH | `/marketplace-model/endpoints/{endpointArn}` | `endpointArn`, `endpointConfig` |
| `UpdateProvisionedModelThroughput` | PATCH | `/provisioned-model-throughput/{provisionedModelId}` | `provisionedModelId` |

## `bedrock-agent`

Agents for Amazon Bedrock · 86 operations.

| Operation | HTTP | Path | Required request members |
|:--|:--|:--|:--|
| `AssociateAgentCollaborator` | PUT | `/agents/{agentId}/agentversions/{agentVersion}/agentcollaborators/` | `agentDescriptor`, `agentId`, `agentVersion`, `collaborationInstruction`, `collaboratorName` |
| `AssociateAgentKnowledgeBase` | PUT | `/agents/{agentId}/agentversions/{agentVersion}/knowledgebases/` | `agentId`, `agentVersion`, `description`, `knowledgeBaseId` |
| `CreateAgent` | PUT | `/agents/` | `agentName` |
| `CreateAgentActionGroup` | PUT | `/agents/{agentId}/agentversions/{agentVersion}/actiongroups/` | `actionGroupName`, `agentId`, `agentVersion` |
| `CreateAgentAlias` | PUT | `/agents/{agentId}/agentaliases/` | `agentAliasName`, `agentId` |
| `CreateDataSource` | PUT | `/knowledgebases/{knowledgeBaseId}/datasources/` | `dataSourceConfiguration`, `knowledgeBaseId`, `name` |
| `CreateFlow` | POST | `/flows/` | `executionRoleArn`, `name` |
| `CreateFlowAlias` | POST | `/flows/{flowIdentifier}/aliases` | `flowIdentifier`, `name`, `routingConfiguration` |
| `CreateFlowVersion` | POST | `/flows/{flowIdentifier}/versions` | `flowIdentifier` |
| `CreateKnowledgeBase` | PUT | `/knowledgebases/` | `knowledgeBaseConfiguration`, `name`, `roleArn` |
| `CreatePrompt` | POST | `/prompts/` | `name` |
| `CreatePromptVersion` | POST | `/prompts/{promptIdentifier}/versions` | `promptIdentifier` |
| `CreateRetrievalInstruction` | POST | `/retrievalinstructions/` | `instruction`, `name` |
| `CreateRetrievalInstructionVersion` | POST | `/retrievalinstructions/{retrievalInstructionId}/versions` | `retrievalInstructionId` |
| `CreateVpcConfiguration` | POST | `/knowledgebases/{knowledgeBaseId}/vpcconfigurations/` | `knowledgeBaseId`, `port`, `protocol`, `resolutionMode`, `resourceTarget`, `subnetIds`, `vpcId` |
| `DeleteAgent` | DELETE | `/agents/{agentId}/` | `agentId` |
| `DeleteAgentActionGroup` | DELETE | `/agents/{agentId}/agentversions/{agentVersion}/actiongroups/{actionGroupId}/` | `actionGroupId`, `agentId`, `agentVersion` |
| `DeleteAgentAlias` | DELETE | `/agents/{agentId}/agentaliases/{agentAliasId}/` | `agentAliasId`, `agentId` |
| `DeleteAgentVersion` | DELETE | `/agents/{agentId}/agentversions/{agentVersion}/` | `agentId`, `agentVersion` |
| `DeleteDataSource` | DELETE | `/knowledgebases/{knowledgeBaseId}/datasources/{dataSourceId}` | `dataSourceId`, `knowledgeBaseId` |
| `DeleteFlow` | DELETE | `/flows/{flowIdentifier}/` | `flowIdentifier` |
| `DeleteFlowAlias` | DELETE | `/flows/{flowIdentifier}/aliases/{aliasIdentifier}` | `aliasIdentifier`, `flowIdentifier` |
| `DeleteFlowVersion` | DELETE | `/flows/{flowIdentifier}/versions/{flowVersion}/` | `flowIdentifier`, `flowVersion` |
| `DeleteKnowledgeBase` | DELETE | `/knowledgebases/{knowledgeBaseId}` | `knowledgeBaseId` |
| `DeleteKnowledgeBaseDocuments` | POST | `/knowledgebases/{knowledgeBaseId}/datasources/{dataSourceId}/documents/deleteDocuments` | `dataSourceId`, `documentIdentifiers`, `knowledgeBaseId` |
| `DeletePrompt` | DELETE | `/prompts/{promptIdentifier}/` | `promptIdentifier` |
| `DeleteResourcePolicy` | DELETE | `/resourcepolicy/{resourceArn}` | `resourceArn` |
| `DeleteRetrievalInstruction` | DELETE | `/retrievalinstructions/{retrievalInstructionId}` | `retrievalInstructionId` |
| `DeleteVpcConfiguration` | DELETE | `/knowledgebases/{knowledgeBaseId}/vpcconfigurations/{vpcConfigurationId}` | `knowledgeBaseId`, `vpcConfigurationId` |
| `DisassociateAgentCollaborator` | DELETE | `/agents/{agentId}/agentversions/{agentVersion}/agentcollaborators/{collaboratorId}/` | `agentId`, `agentVersion`, `collaboratorId` |
| `DisassociateAgentKnowledgeBase` | DELETE | `/agents/{agentId}/agentversions/{agentVersion}/knowledgebases/{knowledgeBaseId}/` | `agentId`, `agentVersion`, `knowledgeBaseId` |
| `GetAgent` | GET | `/agents/{agentId}/` | `agentId` |
| `GetAgentActionGroup` | GET | `/agents/{agentId}/agentversions/{agentVersion}/actiongroups/{actionGroupId}/` | `actionGroupId`, `agentId`, `agentVersion` |
| `GetAgentAlias` | GET | `/agents/{agentId}/agentaliases/{agentAliasId}/` | `agentAliasId`, `agentId` |
| `GetAgentCollaborator` | GET | `/agents/{agentId}/agentversions/{agentVersion}/agentcollaborators/{collaboratorId}/` | `agentId`, `agentVersion`, `collaboratorId` |
| `GetAgentKnowledgeBase` | GET | `/agents/{agentId}/agentversions/{agentVersion}/knowledgebases/{knowledgeBaseId}/` | `agentId`, `agentVersion`, `knowledgeBaseId` |
| `GetAgentVersion` | GET | `/agents/{agentId}/agentversions/{agentVersion}/` | `agentId`, `agentVersion` |
| `GetDataSource` | GET | `/knowledgebases/{knowledgeBaseId}/datasources/{dataSourceId}` | `dataSourceId`, `knowledgeBaseId` |
| `GetFlow` | GET | `/flows/{flowIdentifier}/` | `flowIdentifier` |
| `GetFlowAlias` | GET | `/flows/{flowIdentifier}/aliases/{aliasIdentifier}` | `aliasIdentifier`, `flowIdentifier` |
| `GetFlowVersion` | GET | `/flows/{flowIdentifier}/versions/{flowVersion}/` | `flowIdentifier`, `flowVersion` |
| `GetIngestionJob` | GET | `/knowledgebases/{knowledgeBaseId}/datasources/{dataSourceId}/ingestionjobs/{ingestionJobId}` | `dataSourceId`, `ingestionJobId`, `knowledgeBaseId` |
| `GetKnowledgeBase` | GET | `/knowledgebases/{knowledgeBaseId}` | `knowledgeBaseId` |
| `GetKnowledgeBaseDocuments` | POST | `/knowledgebases/{knowledgeBaseId}/datasources/{dataSourceId}/documents/getDocuments` | `dataSourceId`, `documentIdentifiers`, `knowledgeBaseId` |
| `GetPrompt` | GET | `/prompts/{promptIdentifier}/` | `promptIdentifier` |
| `GetResourcePolicy` | GET | `/resourcepolicy/{resourceArn}` | `resourceArn` |
| `GetRetrievalInstruction` | GET | `/retrievalinstructions/{retrievalInstructionId}` | `retrievalInstructionId` |
| `GetVpcConfiguration` | GET | `/knowledgebases/{knowledgeBaseId}/vpcconfigurations/{vpcConfigurationId}` | `knowledgeBaseId`, `vpcConfigurationId` |
| `IngestKnowledgeBaseDocuments` | PUT | `/knowledgebases/{knowledgeBaseId}/datasources/{dataSourceId}/documents` | `dataSourceId`, `documents`, `knowledgeBaseId` |
| `ListAgentActionGroups` | POST | `/agents/{agentId}/agentversions/{agentVersion}/actiongroups/` | `agentId`, `agentVersion` |
| `ListAgentAliases` | POST | `/agents/{agentId}/agentaliases/` | `agentId` |
| `ListAgentCollaborators` | POST | `/agents/{agentId}/agentversions/{agentVersion}/agentcollaborators/` | `agentId`, `agentVersion` |
| `ListAgentKnowledgeBases` | POST | `/agents/{agentId}/agentversions/{agentVersion}/knowledgebases/` | `agentId`, `agentVersion` |
| `ListAgentVersions` | POST | `/agents/{agentId}/agentversions/` | `agentId` |
| `ListAgents` | POST | `/agents/` | — |
| `ListDataSources` | POST | `/knowledgebases/{knowledgeBaseId}/datasources/` | `knowledgeBaseId` |
| `ListFlowAliases` | GET | `/flows/{flowIdentifier}/aliases` | `flowIdentifier` |
| `ListFlowVersions` | GET | `/flows/{flowIdentifier}/versions` | `flowIdentifier` |
| `ListFlows` | GET | `/flows/` | — |
| `ListIngestionJobs` | POST | `/knowledgebases/{knowledgeBaseId}/datasources/{dataSourceId}/ingestionjobs/` | `dataSourceId`, `knowledgeBaseId` |
| `ListKnowledgeBaseDocuments` | POST | `/knowledgebases/{knowledgeBaseId}/datasources/{dataSourceId}/documents` | `dataSourceId`, `knowledgeBaseId` |
| `ListKnowledgeBases` | POST | `/knowledgebases/` | — |
| `ListPrompts` | GET | `/prompts/` | — |
| `ListRetrievalInstructionVersions` | GET | `/retrievalinstructions/{retrievalInstructionId}/versions` | `retrievalInstructionId` |
| `ListRetrievalInstructions` | GET | `/retrievalinstructions/` | — |
| `ListTagsForResource` | GET | `/tags/{resourceArn}` | `resourceArn` |
| `ListVpcConfigurations` | GET | `/knowledgebases/{knowledgeBaseId}/vpcconfigurations/` | `knowledgeBaseId` |
| `PrepareAgent` | POST | `/agents/{agentId}/` | `agentId` |
| `PrepareFlow` | POST | `/flows/{flowIdentifier}/` | `flowIdentifier` |
| `PutResourcePolicy` | PUT | `/resourcepolicy/{resourceArn}` | `policy`, `resourceArn` |
| `StartIngestionJob` | PUT | `/knowledgebases/{knowledgeBaseId}/datasources/{dataSourceId}/ingestionjobs/` | `dataSourceId`, `knowledgeBaseId` |
| `StopIngestionJob` | POST | `/knowledgebases/{knowledgeBaseId}/datasources/{dataSourceId}/ingestionjobs/{ingestionJobId}/stop` | `dataSourceId`, `ingestionJobId`, `knowledgeBaseId` |
| `TagResource` | POST | `/tags/{resourceArn}` | `resourceArn`, `tags` |
| `UntagResource` | DELETE | `/tags/{resourceArn}` | `resourceArn`, `tagKeys` |
| `UpdateAgent` | PUT | `/agents/{agentId}/` | `agentId`, `agentName`, `agentResourceRoleArn`, `foundationModel` |
| `UpdateAgentActionGroup` | PUT | `/agents/{agentId}/agentversions/{agentVersion}/actiongroups/{actionGroupId}/` | `actionGroupId`, `actionGroupName`, `agentId`, `agentVersion` |
| `UpdateAgentAlias` | PUT | `/agents/{agentId}/agentaliases/{agentAliasId}/` | `agentAliasId`, `agentAliasName`, `agentId` |
| `UpdateAgentCollaborator` | PUT | `/agents/{agentId}/agentversions/{agentVersion}/agentcollaborators/{collaboratorId}/` | `agentDescriptor`, `agentId`, `agentVersion`, `collaborationInstruction`, `collaboratorId`, `collaboratorName` |
| `UpdateAgentKnowledgeBase` | PUT | `/agents/{agentId}/agentversions/{agentVersion}/knowledgebases/{knowledgeBaseId}/` | `agentId`, `agentVersion`, `knowledgeBaseId` |
| `UpdateDataSource` | PUT | `/knowledgebases/{knowledgeBaseId}/datasources/{dataSourceId}` | `dataSourceConfiguration`, `dataSourceId`, `knowledgeBaseId`, `name` |
| `UpdateFlow` | PUT | `/flows/{flowIdentifier}/` | `executionRoleArn`, `flowIdentifier`, `name` |
| `UpdateFlowAlias` | PUT | `/flows/{flowIdentifier}/aliases/{aliasIdentifier}` | `aliasIdentifier`, `flowIdentifier`, `name`, `routingConfiguration` |
| `UpdateKnowledgeBase` | PUT | `/knowledgebases/{knowledgeBaseId}` | `knowledgeBaseConfiguration`, `knowledgeBaseId`, `name`, `roleArn` |
| `UpdatePrompt` | PUT | `/prompts/{promptIdentifier}/` | `name`, `promptIdentifier` |
| `UpdateRetrievalInstruction` | PUT | `/retrievalinstructions/{retrievalInstructionId}` | `instruction`, `retrievalInstructionId` |
| `ValidateFlowDefinition` | POST | `/flows/validate-definition` | `definition` |

## `bedrock-agent-runtime`

Agents for Amazon Bedrock Runtime · 35 operations.

| Operation | HTTP | Path | Required request members |
|:--|:--|:--|:--|
| `AgenticRetrieveStream` | POST | `/agenticRetrieveStream` | `agenticRetrieveConfiguration`, `messages`, `retrievers` |
| `CheckIngestedDocumentAcl` | POST | `/knowledgebases/{knowledgeBaseId}/datasources/{dataSourceId}/check-ingested-document-acl` | `dataSourceId`, `documentId`, `knowledgeBaseId`, `userContext` |
| `CreateInvocation` | PUT | `/sessions/{sessionIdentifier}/invocations/` | `sessionIdentifier` |
| `CreateSession` | PUT | `/sessions/` | — |
| `DeleteAgentMemory` | DELETE | `/agents/{agentId}/agentAliases/{agentAliasId}/memories` | `agentAliasId`, `agentId` |
| `DeleteSession` | DELETE | `/sessions/{sessionIdentifier}/` | `sessionIdentifier` |
| `EndSession` | PATCH | `/sessions/{sessionIdentifier}` | `sessionIdentifier` |
| `GenerateQuery` | POST | `/generateQuery` | `queryGenerationInput`, `transformationConfiguration` |
| `GetAgentMemory` | GET | `/agents/{agentId}/agentAliases/{agentAliasId}/memories` | `agentAliasId`, `agentId`, `memoryId`, `memoryType` |
| `GetDocumentContent` | POST | `/knowledgebases/{knowledgeBaseId}/datasources/{dataSourceId}/documents/{documentId}/content` | `dataSourceId`, `documentId`, `knowledgeBaseId` |
| `GetExecutionFlowSnapshot` | GET | `/flows/{flowIdentifier}/aliases/{flowAliasIdentifier}/executions/{executionIdentifier}/flowsnapshot` | `executionIdentifier`, `flowAliasIdentifier`, `flowIdentifier` |
| `GetFlowExecution` | GET | `/flows/{flowIdentifier}/aliases/{flowAliasIdentifier}/executions/{executionIdentifier}` | `executionIdentifier`, `flowAliasIdentifier`, `flowIdentifier` |
| `GetIngestedDocumentAcl` | POST | `/knowledgebases/{knowledgeBaseId}/datasources/{dataSourceId}/get-ingested-document-acl` | `dataSourceId`, `documentId`, `knowledgeBaseId` |
| `GetInvocationStep` | POST | `/sessions/{sessionIdentifier}/invocationSteps/{invocationStepId}` | `invocationIdentifier`, `invocationStepId`, `sessionIdentifier` |
| `GetSession` | GET | `/sessions/{sessionIdentifier}/` | `sessionIdentifier` |
| `InvokeAgent` | POST | `/agents/{agentId}/agentAliases/{agentAliasId}/sessions/{sessionId}/text` | `agentAliasId`, `agentId`, `sessionId` |
| `InvokeFlow` | POST | `/flows/{flowIdentifier}/aliases/{flowAliasIdentifier}` | `flowAliasIdentifier`, `flowIdentifier`, `inputs` |
| `InvokeInlineAgent` | POST | `/agents/{sessionId}` | `foundationModel`, `instruction`, `sessionId` |
| `ListFlowExecutionEvents` | GET | `/flows/{flowIdentifier}/aliases/{flowAliasIdentifier}/executions/{executionIdentifier}/events` | `eventType`, `executionIdentifier`, `flowAliasIdentifier`, `flowIdentifier` |
| `ListFlowExecutions` | GET | `/flows/{flowIdentifier}/executions` | `flowIdentifier` |
| `ListInvocationSteps` | POST | `/sessions/{sessionIdentifier}/invocationSteps/` | `sessionIdentifier` |
| `ListInvocations` | POST | `/sessions/{sessionIdentifier}/invocations/` | `sessionIdentifier` |
| `ListSessions` | POST | `/sessions/` | — |
| `ListTagsForResource` | GET | `/tags/{resourceArn}` | `resourceArn` |
| `OptimizePrompt` | POST | `/optimize-prompt` | `input`, `targetModelId` |
| `PutInvocationStep` | PUT | `/sessions/{sessionIdentifier}/invocationSteps/` | `invocationIdentifier`, `invocationStepTime`, `payload`, `sessionIdentifier` |
| `Rerank` | POST | `/rerank` | `queries`, `rerankingConfiguration`, `sources` |
| `Retrieve` | POST | `/knowledgebases/{knowledgeBaseId}/retrieve` | `knowledgeBaseId`, `retrievalQuery` |
| `RetrieveAndGenerate` | POST | `/retrieveAndGenerate` | `input` |
| `RetrieveAndGenerateStream` | POST | `/retrieveAndGenerateStream` | `input` |
| `StartFlowExecution` | POST | `/flows/{flowIdentifier}/aliases/{flowAliasIdentifier}/executions` | `flowAliasIdentifier`, `flowIdentifier`, `inputs` |
| `StopFlowExecution` | POST | `/flows/{flowIdentifier}/aliases/{flowAliasIdentifier}/executions/{executionIdentifier}/stop` | `executionIdentifier`, `flowAliasIdentifier`, `flowIdentifier` |
| `TagResource` | POST | `/tags/{resourceArn}` | `resourceArn`, `tags` |
| `UntagResource` | DELETE | `/tags/{resourceArn}` | `resourceArn`, `tagKeys` |
| `UpdateSession` | PUT | `/sessions/{sessionIdentifier}/` | `sessionIdentifier` |

## `bedrock-agentcore`

Amazon Bedrock AgentCore · 68 operations.

| Operation | HTTP | Path | Required request members |
|:--|:--|:--|:--|
| `BatchCreateMemoryRecords` | POST | `/memories/{memoryId}/memoryRecords/batchCreate` | `memoryId`, `records` |
| `BatchDeleteMemoryRecords` | POST | `/memories/{memoryId}/memoryRecords/batchDelete` | `memoryId`, `records` |
| `BatchUpdateMemoryRecords` | POST | `/memories/{memoryId}/memoryRecords/batchUpdate` | `memoryId`, `records` |
| `CompleteResourceTokenAuth` | POST | `/identities/CompleteResourceTokenAuth` | `sessionUri`, `userIdentifier` |
| `CreateABTest` | POST | `/ab-tests` | `evaluationConfig`, `gatewayArn`, `name`, `roleArn`, `variants` |
| `CreateEvent` | POST | `/memories/{memoryId}/events` | `actorId`, `eventTimestamp`, `memoryId`, `payload` |
| `CreatePaymentInstrument` | POST | `/payments/createPaymentInstrument` | `paymentConnectorId`, `paymentInstrumentDetails`, `paymentInstrumentType`, `paymentManagerArn` |
| `CreatePaymentSession` | POST | `/payments/createPaymentSession` | `expiryTimeInMinutes`, `paymentManagerArn` |
| `DeleteABTest` | DELETE | `/ab-tests/{abTestId}` | `abTestId` |
| `DeleteBatchEvaluation` | DELETE | `/evaluations/batch-evaluate/{batchEvaluationId}` | `batchEvaluationId` |
| `DeleteCapacityProviderSession` | DELETE | `/capacity-providers/{capacityProviderId}/sessions/{sessionId}` | `capacityProviderId`, `sessionId` |
| `DeleteEvent` | DELETE | `/memories/{memoryId}/actor/{actorId}/sessions/{sessionId}/events/{eventId}` | `actorId`, `eventId`, `memoryId`, `sessionId` |
| `DeleteMemoryRecord` | DELETE | `/memories/{memoryId}/memoryRecords/{memoryRecordId}` | `memoryId`, `memoryRecordId` |
| `DeletePaymentInstrument` | POST | `/payments/deletePaymentInstrument` | `paymentConnectorId`, `paymentInstrumentId`, `paymentManagerArn` |
| `DeletePaymentSession` | POST | `/payments/deletePaymentSession` | `paymentManagerArn`, `paymentSessionId` |
| `DeleteRecommendation` | DELETE | `/recommendations/{recommendationId}` | `recommendationId` |
| `Evaluate` | POST | `/evaluations/evaluate/{evaluatorId}` | `evaluationInput`, `evaluatorId` |
| `GetABTest` | GET | `/ab-tests/{abTestId}` | `abTestId` |
| `GetAgentCard` | GET | `/runtimes/{agentRuntimeArn}/invocations/.well-known/agent-card.json` | `agentRuntimeArn` |
| `GetBatchEvaluation` | GET | `/evaluations/batch-evaluate/{batchEvaluationId}` | `batchEvaluationId` |
| `GetBrowserSession` | GET | `/browsers/{browserIdentifier}/sessions/get` | `browserIdentifier`, `sessionId` |
| `GetCodeInterpreterSession` | GET | `/code-interpreters/{codeInterpreterIdentifier}/sessions/get` | `codeInterpreterIdentifier`, `sessionId` |
| `GetEvent` | GET | `/memories/{memoryId}/actor/{actorId}/sessions/{sessionId}/events/{eventId}` | `actorId`, `eventId`, `memoryId`, `sessionId` |
| `GetMemoryRecord` | GET | `/memories/{memoryId}/memoryRecord/{memoryRecordId}` | `memoryId`, `memoryRecordId` |
| `GetPaymentInstrument` | POST | `/payments/getPaymentInstrument` | `paymentInstrumentId`, `paymentManagerArn` |
| `GetPaymentInstrumentBalance` | POST | `/payments/getPaymentInstrumentBalance` | `chain`, `paymentConnectorId`, `paymentInstrumentId`, `paymentManagerArn`, `token` |
| `GetPaymentSession` | POST | `/payments/getPaymentSession` | `paymentManagerArn`, `paymentSessionId` |
| `GetRecommendation` | GET | `/recommendations/{recommendationId}` | `recommendationId` |
| `GetResourceApiKey` | POST | `/identities/api-key` | `resourceCredentialProviderName`, `workloadIdentityToken` |
| `GetResourceOauth2Token` | POST | `/identities/oauth2/token` | `oauth2Flow`, `resourceCredentialProviderName`, `scopes`, `workloadIdentityToken` |
| `GetResourcePaymentToken` | POST | `/identities/payment/token` | `paymentTokenRequest`, `resourceCredentialProviderName`, `workloadIdentityToken` |
| `GetWorkloadAccessToken` | POST | `/identities/GetWorkloadAccessToken` | `workloadName` |
| `GetWorkloadAccessTokenForJWT` | POST | `/identities/GetWorkloadAccessTokenForJWT` | `userToken`, `workloadName` |
| `GetWorkloadAccessTokenForUserId` | POST | `/identities/GetWorkloadAccessTokenForUserId` | `userId`, `workloadName` |
| `IngestData` | POST | `/memories/{memoryId}/ingest` | `actorId`, `contentTimestamp`, `memoryId`, `source` |
| `InvokeAgentRuntime` | POST | `/runtimes/{agentRuntimeArn}/invocations` | `agentRuntimeArn`, `payload` |
| `InvokeAgentRuntimeCommand` | POST | `/runtimes/{agentRuntimeArn}/commands` | `agentRuntimeArn`, `body` |
| `InvokeBrowser` | POST | `/browsers/{browserIdentifier}/sessions/invoke` | `action`, `browserIdentifier`, `sessionId` |
| `InvokeCodeInterpreter` | POST | `/code-interpreters/{codeInterpreterIdentifier}/tools/invoke` | `codeInterpreterIdentifier`, `name` |
| `InvokeHarness` | POST | `/harnesses/invoke` | `harnessArn`, `messages`, `runtimeSessionId` |
| `InvokeWebSearch` | POST | `/web-search/{webSearchId}/invoke` | `searchQuery`, `webSearchId` |
| `ListABTests` | GET | `/ab-tests` | — |
| `ListActors` | POST | `/memories/{memoryId}/actors` | `memoryId` |
| `ListBatchEvaluations` | GET | `/evaluations/batch-evaluate` | — |
| `ListBrowserSessions` | POST | `/browsers/{browserIdentifier}/sessions/list` | `browserIdentifier` |
| `ListCodeInterpreterSessions` | POST | `/code-interpreters/{codeInterpreterIdentifier}/sessions/list` | `codeInterpreterIdentifier` |
| `ListEvents` | POST | `/memories/{memoryId}/actor/{actorId}/sessions/{sessionId}` | `actorId`, `memoryId`, `sessionId` |
| `ListMemoryExtractionJobs` | POST | `/memories/{memoryId}/extractionJobs` | `memoryId` |
| `ListMemoryRecords` | POST | `/memories/{memoryId}/memoryRecords` | `memoryId` |
| `ListPaymentInstruments` | POST | `/payments/listPaymentInstruments` | `paymentManagerArn` |
| `ListPaymentSessions` | POST | `/payments/listPaymentSessions` | `paymentManagerArn` |
| `ListRecommendations` | GET | `/recommendations` | — |
| `ListSessions` | POST | `/memories/{memoryId}/actor/{actorId}/sessions` | `actorId`, `memoryId` |
| `ProcessPayment` | POST | `/payments/processPayment` | `paymentInput`, `paymentInstrumentId`, `paymentManagerArn`, `paymentSessionId`, `paymentType` |
| `RetrieveMemoryRecords` | POST | `/memories/{memoryId}/retrieve` | `memoryId`, `searchCriteria` |
| `SaveBrowserSessionProfile` | PUT | `/browser-profiles/{profileIdentifier}/save` | `browserIdentifier`, `profileIdentifier`, `sessionId` |
| `SearchRegistryRecords` | POST | `/registry-records/search` | `registryIds`, `searchQuery` |
| `StartBatchEvaluation` | POST | `/evaluations/batch-evaluate` | `batchEvaluationName`, `dataSourceConfig` |
| `StartBrowserSession` | PUT | `/browsers/{browserIdentifier}/sessions/start` | `browserIdentifier` |
| `StartCodeInterpreterSession` | PUT | `/code-interpreters/{codeInterpreterIdentifier}/sessions/start` | `codeInterpreterIdentifier` |
| `StartMemoryExtractionJob` | POST | `/memories/{memoryId}/extractionJobs/start` | `extractionJob`, `memoryId` |
| `StartRecommendation` | POST | `/recommendations` | `name`, `recommendationConfig`, `type` |
| `StopBatchEvaluation` | POST | `/evaluations/batch-evaluate/{batchEvaluationId}/stop` | `batchEvaluationId` |
| `StopBrowserSession` | PUT | `/browsers/{browserIdentifier}/sessions/stop` | `browserIdentifier`, `sessionId` |
| `StopCodeInterpreterSession` | PUT | `/code-interpreters/{codeInterpreterIdentifier}/sessions/stop` | `codeInterpreterIdentifier`, `sessionId` |
| `StopRuntimeSession` | POST | `/runtimes/{agentRuntimeArn}/stopruntimesession` | `agentRuntimeArn`, `runtimeSessionId` |
| `UpdateABTest` | PUT | `/ab-tests/{abTestId}` | `abTestId` |
| `UpdateBrowserStream` | PUT | `/browsers/{browserIdentifier}/sessions/streams/update` | `browserIdentifier`, `sessionId`, `streamUpdate` |

## `bedrock-agentcore-control`

Amazon Bedrock AgentCore Control · 172 operations.

| Operation | HTTP | Path | Required request members |
|:--|:--|:--|:--|
| `AddDatasetExamples` | POST | `/datasets/{datasetId}/examples/add` | `datasetId`, `source` |
| `BatchPutGatewayRateLimits` | PUT | `/gateways/{gatewayIdentifier}/rate-limits/batch` | `gatewayIdentifier`, `rateLimits` |
| `CreateAgentRuntime` | PUT | `/runtimes/` | `agentRuntimeArtifact`, `agentRuntimeName`, `roleArn` |
| `CreateAgentRuntimeEndpoint` | PUT | `/runtimes/{agentRuntimeId}/runtime-endpoints/` | `agentRuntimeId`, `name` |
| `CreateApiKeyCredentialProvider` | POST | `/identities/CreateApiKeyCredentialProvider` | `name` |
| `CreateBrowser` | PUT | `/browsers` | `name`, `networkConfiguration` |
| `CreateBrowserProfile` | PUT | `/browser-profiles` | `name` |
| `CreateCapacityProvider` | PUT | `/capacity-providers` | `computeConfiguration`, `name`, `permissionsConfiguration` |
| `CreateCodeInterpreter` | PUT | `/code-interpreters` | `name`, `networkConfiguration` |
| `CreateConfigurationBundle` | POST | `/configuration-bundles/create` | `bundleName`, `components` |
| `CreateConsentPortal` | POST | `/identities/CreateConsentPortal` | `executionRoleArn`, `idpConfig`, `name`, `sources` |
| `CreateDataset` | POST | `/datasets` | `datasetName`, `schemaType`, `source` |
| `CreateDatasetVersion` | POST | `/datasets/{datasetId}/versions` | `datasetId` |
| `CreateEvaluator` | POST | `/evaluators/create` | `evaluatorConfig`, `evaluatorName`, `level` |
| `CreateGateway` | POST | `/gateways/` | `authorizerType`, `name`, `roleArn` |
| `CreateGatewayRateLimit` | POST | `/gateways/{gatewayIdentifier}/rate-limits` | `dimensionKeys`, `entries`, `gatewayIdentifier` |
| `CreateGatewayRule` | POST | `/gateways/{gatewayIdentifier}/rules` | `actions`, `gatewayIdentifier`, `priority` |
| `CreateGatewayTarget` | POST | `/gateways/{gatewayIdentifier}/targets/` | `gatewayIdentifier`, `targetConfiguration` |
| `CreateHarness` | POST | `/harnesses` | `executionRoleArn`, `harnessName` |
| `CreateHarnessEndpoint` | POST | `/harnesses/{harnessId}/endpoints` | `endpointName`, `harnessId` |
| `CreateMemory` | POST | `/memories/create` | `eventExpiryDuration`, `name` |
| `CreateOauth2CredentialProvider` | POST | `/identities/CreateOauth2CredentialProvider` | `credentialProviderVendor`, `name`, `oauth2ProviderConfigInput` |
| `CreateOnlineEvaluationConfig` | POST | `/online-evaluation-configs/create` | `dataSourceConfig`, `enableOnCreate`, `evaluationExecutionRoleArn`, `onlineEvaluationConfigName`, `rule` |
| `CreatePaymentConnector` | POST | `/payments/managers/{paymentManagerId}/connectors` | `credentialProviderConfigurations`, `name`, `paymentManagerId`, `type` |
| `CreatePaymentCredentialProvider` | POST | `/identities/CreatePaymentCredentialProvider` | `credentialProviderVendor`, `name`, `providerConfigurationInput` |
| `CreatePaymentManager` | POST | `/payments/managers` | `authorizerType`, `name`, `roleArn` |
| `CreatePolicy` | POST | `/policy-engines/{policyEngineId}/policies` | `definition`, `name`, `policyEngineId` |
| `CreatePolicyEngine` | POST | `/policy-engines` | `name` |
| `CreateRegistry` | POST | `/registries` | `name` |
| `CreateRegistryRecord` | POST | `/registries/{registryId}/records` | `descriptorType`, `name`, `registryId` |
| `CreateWorkloadIdentity` | POST | `/identities/CreateWorkloadIdentity` | `name` |
| `DeleteAgentRuntime` | DELETE | `/runtimes/{agentRuntimeId}/` | `agentRuntimeId` |
| `DeleteAgentRuntimeEndpoint` | DELETE | `/runtimes/{agentRuntimeId}/runtime-endpoints/{endpointName}/` | `agentRuntimeId`, `endpointName` |
| `DeleteApiKeyCredentialProvider` | POST | `/identities/DeleteApiKeyCredentialProvider` | `name` |
| `DeleteBrowser` | DELETE | `/browsers/{browserId}` | `browserId` |
| `DeleteBrowserProfile` | DELETE | `/browser-profiles/{profileId}` | `profileId` |
| `DeleteCapacityProvider` | DELETE | `/capacity-providers/{capacityProviderId}` | `capacityProviderId` |
| `DeleteCodeInterpreter` | DELETE | `/code-interpreters/{codeInterpreterId}` | `codeInterpreterId` |
| `DeleteConfigurationBundle` | DELETE | `/configuration-bundles/{bundleId}` | `bundleId` |
| `DeleteConsentPortal` | POST | `/identities/DeleteConsentPortal` | `consentPortalIdentifier` |
| `DeleteDataset` | DELETE | `/datasets/{datasetId}` | `datasetId` |
| `DeleteDatasetExamples` | POST | `/datasets/{datasetId}/examples/delete` | `datasetId`, `exampleIds` |
| `DeleteEvaluator` | DELETE | `/evaluators/{evaluatorId}` | `evaluatorId` |
| `DeleteGateway` | DELETE | `/gateways/{gatewayIdentifier}/` | `gatewayIdentifier` |
| `DeleteGatewayRateLimit` | DELETE | `/gateways/{gatewayIdentifier}/rate-limits/{rateLimitId}` | `gatewayIdentifier`, `rateLimitId` |
| `DeleteGatewayRule` | DELETE | `/gateways/{gatewayIdentifier}/rules/{ruleId}` | `gatewayIdentifier`, `ruleId` |
| `DeleteGatewayTarget` | DELETE | `/gateways/{gatewayIdentifier}/targets/{targetId}/` | `gatewayIdentifier`, `targetId` |
| `DeleteHarness` | DELETE | `/harnesses/{harnessId}` | `harnessId` |
| `DeleteHarnessEndpoint` | DELETE | `/harnesses/{harnessId}/endpoints/{endpointName}` | `endpointName`, `harnessId` |
| `DeleteMemory` | DELETE | `/memories/{memoryId}/delete` | `memoryId` |
| `DeleteOauth2CredentialProvider` | POST | `/identities/DeleteOauth2CredentialProvider` | `name` |
| `DeleteOnlineEvaluationConfig` | DELETE | `/online-evaluation-configs/{onlineEvaluationConfigId}` | `onlineEvaluationConfigId` |
| `DeletePaymentConnector` | DELETE | `/payments/managers/{paymentManagerId}/connectors/{paymentConnectorId}` | `paymentConnectorId`, `paymentManagerId` |
| `DeletePaymentCredentialProvider` | POST | `/identities/DeletePaymentCredentialProvider` | `name` |
| `DeletePaymentManager` | DELETE | `/payments/managers/{paymentManagerId}` | `paymentManagerId` |
| `DeletePolicy` | DELETE | `/policy-engines/{policyEngineId}/policies/{policyId}` | `policyEngineId`, `policyId` |
| `DeletePolicyEngine` | DELETE | `/policy-engines/{policyEngineId}` | `policyEngineId` |
| `DeleteRegistry` | DELETE | `/registries/{registryId}` | `registryId` |
| `DeleteRegistryRecord` | DELETE | `/registries/{registryId}/records/{recordId}` | `recordId`, `registryId` |
| `DeleteResourcePolicy` | DELETE | `/resourcepolicy/{resourceArn}` | `resourceArn` |
| `DeleteWorkloadIdentity` | POST | `/identities/DeleteWorkloadIdentity` | `name` |
| `GetAgentRuntime` | GET | `/runtimes/{agentRuntimeId}/` | `agentRuntimeId` |
| `GetAgentRuntimeEndpoint` | GET | `/runtimes/{agentRuntimeId}/runtime-endpoints/{endpointName}/` | `agentRuntimeId`, `endpointName` |
| `GetApiKeyCredentialProvider` | POST | `/identities/GetApiKeyCredentialProvider` | `name` |
| `GetBrowser` | GET | `/browsers/{browserId}` | `browserId` |
| `GetBrowserProfile` | GET | `/browser-profiles/{profileId}` | `profileId` |
| `GetCapacityProvider` | GET | `/capacity-providers/{capacityProviderId}` | `capacityProviderId` |
| `GetCodeInterpreter` | GET | `/code-interpreters/{codeInterpreterId}` | `codeInterpreterId` |
| `GetConfigurationBundle` | GET | `/configuration-bundles/{bundleId}` | `bundleId` |
| `GetConfigurationBundleVersion` | GET | `/configuration-bundles/{bundleId}/versions/{versionId}` | `bundleId`, `versionId` |
| `GetConsentPortal` | POST | `/identities/GetConsentPortal` | `consentPortalIdentifier` |
| `GetDataset` | GET | `/datasets/{datasetId}` | `datasetId` |
| `GetEvaluator` | GET | `/evaluators/{evaluatorId}` | `evaluatorId` |
| `GetGateway` | GET | `/gateways/{gatewayIdentifier}/` | `gatewayIdentifier` |
| `GetGatewayRateLimit` | GET | `/gateways/{gatewayIdentifier}/rate-limits/{rateLimitId}` | `gatewayIdentifier`, `rateLimitId` |
| `GetGatewayRule` | GET | `/gateways/{gatewayIdentifier}/rules/{ruleId}` | `gatewayIdentifier`, `ruleId` |
| `GetGatewayTarget` | GET | `/gateways/{gatewayIdentifier}/targets/{targetId}/` | `gatewayIdentifier`, `targetId` |
| `GetHarness` | GET | `/harnesses/{harnessId}` | `harnessId` |
| `GetHarnessEndpoint` | GET | `/harnesses/{harnessId}/endpoints/{endpointName}` | `endpointName`, `harnessId` |
| `GetMemory` | GET | `/memories/{memoryId}/details` | `memoryId` |
| `GetOauth2CredentialProvider` | POST | `/identities/GetOauth2CredentialProvider` | `name` |
| `GetOnlineEvaluationConfig` | GET | `/online-evaluation-configs/{onlineEvaluationConfigId}` | `onlineEvaluationConfigId` |
| `GetPaymentConnector` | GET | `/payments/managers/{paymentManagerId}/connectors/{paymentConnectorId}` | `paymentConnectorId`, `paymentManagerId` |
| `GetPaymentCredentialProvider` | POST | `/identities/GetPaymentCredentialProvider` | `name` |
| `GetPaymentManager` | GET | `/payments/managers/{paymentManagerId}` | `paymentManagerId` |
| `GetPolicy` | GET | `/policy-engines/{policyEngineId}/policies/{policyId}` | `policyEngineId`, `policyId` |
| `GetPolicyEngine` | GET | `/policy-engines/{policyEngineId}` | `policyEngineId` |
| `GetPolicyEngineSummary` | GET | `/policy-engine-summaries/{policyEngineId}` | `policyEngineId` |
| `GetPolicyGeneration` | GET | `/policy-engines/{policyEngineId}/policy-generations/{policyGenerationId}` | `policyEngineId`, `policyGenerationId` |
| `GetPolicyGenerationSummary` | GET | `/policy-engines/{policyEngineId}/policy-generation-summaries/{policyGenerationId}` | `policyEngineId`, `policyGenerationId` |
| `GetPolicySummary` | GET | `/policy-engines/{policyEngineId}/policy-summaries/{policyId}` | `policyEngineId`, `policyId` |
| `GetRegistry` | GET | `/registries/{registryId}` | `registryId` |
| `GetRegistryRecord` | GET | `/registries/{registryId}/records/{recordId}` | `recordId`, `registryId` |
| `GetResourcePolicy` | GET | `/resourcepolicy/{resourceArn}` | `resourceArn` |
| `GetTokenVault` | POST | `/identities/get-token-vault` | — |
| `GetWorkloadIdentity` | POST | `/identities/GetWorkloadIdentity` | `name` |
| `ListAgentRuntimeEndpoints` | POST | `/runtimes/{agentRuntimeId}/runtime-endpoints/` | `agentRuntimeId` |
| `ListAgentRuntimeVersions` | POST | `/runtimes/{agentRuntimeId}/versions/` | `agentRuntimeId` |
| `ListAgentRuntimeVersionsByCapacityProvider` | POST | `/capacity-providers/{capacityProviderId}/runtime-versions` | `capacityProviderId` |
| `ListAgentRuntimes` | POST | `/runtimes/` | — |
| `ListApiKeyCredentialProviders` | POST | `/identities/ListApiKeyCredentialProviders` | — |
| `ListBrowserProfiles` | POST | `/browser-profiles` | — |
| `ListBrowsers` | POST | `/browsers` | — |
| `ListCapacityProviders` | POST | `/capacity-providers` | — |
| `ListCodeInterpreters` | POST | `/code-interpreters` | — |
| `ListConfigurationBundleVersions` | POST | `/configuration-bundles/{bundleId}/versions` | `bundleId` |
| `ListConfigurationBundles` | POST | `/configuration-bundles` | — |
| `ListConsentPortals` | POST | `/identities/ListConsentPortals` | — |
| `ListDatasetExamples` | GET | `/datasets/{datasetId}/examples` | `datasetId` |
| `ListDatasetVersions` | GET | `/datasets/{datasetId}/versions` | `datasetId` |
| `ListDatasets` | GET | `/datasets` | — |
| `ListEvaluators` | POST | `/evaluators` | — |
| `ListGatewayRateLimits` | GET | `/gateways/{gatewayIdentifier}/rate-limits` | `gatewayIdentifier` |
| `ListGatewayRules` | GET | `/gateways/{gatewayIdentifier}/rules` | `gatewayIdentifier` |
| `ListGatewayTargets` | GET | `/gateways/{gatewayIdentifier}/targets/` | `gatewayIdentifier` |
| `ListGateways` | GET | `/gateways/` | — |
| `ListHarnessEndpoints` | GET | `/harnesses/{harnessId}/endpoints` | `harnessId` |
| `ListHarnessVersions` | GET | `/harnesses/{harnessId}/versions` | `harnessId` |
| `ListHarnesses` | GET | `/harnesses` | — |
| `ListMemories` | POST | `/memories/` | — |
| `ListOauth2CredentialProviders` | POST | `/identities/ListOauth2CredentialProviders` | — |
| `ListOnlineEvaluationConfigs` | POST | `/online-evaluation-configs` | — |
| `ListPaymentConnectors` | POST | `/payments/managers/{paymentManagerId}/connectors-list` | `paymentManagerId` |
| `ListPaymentCredentialProviders` | POST | `/identities/ListPaymentCredentialProviders` | — |
| `ListPaymentManagers` | POST | `/payments/managers-list` | — |
| `ListPolicies` | GET | `/policy-engines/{policyEngineId}/policies` | `policyEngineId` |
| `ListPolicyEngineSummaries` | GET | `/policy-engine-summaries` | — |
| `ListPolicyEngines` | GET | `/policy-engines` | — |
| `ListPolicyGenerationAssets` | GET | `/policy-engines/{policyEngineId}/policy-generations/{policyGenerationId}/assets` | `policyEngineId`, `policyGenerationId` |
| `ListPolicyGenerationSummaries` | GET | `/policy-engines/{policyEngineId}/policy-generation-summaries` | `policyEngineId` |
| `ListPolicyGenerations` | GET | `/policy-engines/{policyEngineId}/policy-generations` | `policyEngineId` |
| `ListPolicySummaries` | GET | `/policy-engines/{policyEngineId}/policy-summaries` | `policyEngineId` |
| `ListRegistries` | GET | `/registries` | — |
| `ListRegistryRecords` | GET | `/registries/{registryId}/records` | `registryId` |
| `ListTagsForResource` | GET | `/tags/{resourceArn}` | `resourceArn` |
| `ListWorkloadIdentities` | POST | `/identities/ListWorkloadIdentities` | — |
| `PutResourcePolicy` | PUT | `/resourcepolicy/{resourceArn}` | `policy`, `resourceArn` |
| `ResetTokenVaultKeyMaterial` | POST | `/identities/reset-token-vault-key-material` | `tokenVaultId` |
| `RotatePaymentConnectorCredentials` | POST | `/payments/managers/{paymentManagerId}/connectors/{paymentConnectorId}/rotate-credentials` | `credentialsToRotate`, `paymentConnectorId`, `paymentManagerId` |
| `SetTokenVaultCMK` | POST | `/identities/set-token-vault-cmk` | `kmsConfiguration` |
| `StartPolicyGeneration` | POST | `/policy-engines/{policyEngineId}/policy-generations` | `content`, `name`, `policyEngineId`, `resource` |
| `SubmitRegistryRecordForApproval` | POST | `/registries/{registryId}/records/{recordId}/submit-for-approval` | `recordId`, `registryId` |
| `SynchronizeGatewayTargets` | PUT | `/gateways/{gatewayIdentifier}/synchronizeTargets` | `gatewayIdentifier`, `targetIdList` |
| `TagResource` | POST | `/tags/{resourceArn}` | `resourceArn`, `tags` |
| `UntagResource` | DELETE | `/tags/{resourceArn}` | `resourceArn`, `tagKeys` |
| `UpdateAgentRuntime` | PUT | `/runtimes/{agentRuntimeId}/` | `agentRuntimeArtifact`, `agentRuntimeId`, `roleArn` |
| `UpdateAgentRuntimeEndpoint` | PUT | `/runtimes/{agentRuntimeId}/runtime-endpoints/{endpointName}/` | `agentRuntimeId`, `endpointName` |
| `UpdateApiKeyCredentialProvider` | POST | `/identities/UpdateApiKeyCredentialProvider` | `name` |
| `UpdateCapacityProvider` | PUT | `/capacity-providers/{capacityProviderId}` | `capacityProviderId` |
| `UpdateConfigurationBundle` | PUT | `/configuration-bundles/{bundleId}` | `bundleId`, `commitMessage`, `parentVersionIds` |
| `UpdateConsentPortal` | POST | `/identities/UpdateConsentPortal` | `consentPortalIdentifier` |
| `UpdateDataset` | PUT | `/datasets/{datasetId}` | `datasetId` |
| `UpdateDatasetExamples` | POST | `/datasets/{datasetId}/examples/update` | `datasetId`, `examples` |
| `UpdateEvaluator` | PUT | `/evaluators/{evaluatorId}` | `evaluatorId` |
| `UpdateGateway` | PUT | `/gateways/{gatewayIdentifier}/` | `authorizerType`, `gatewayIdentifier`, `name`, `roleArn` |
| `UpdateGatewayRateLimit` | PATCH | `/gateways/{gatewayIdentifier}/rate-limits/{rateLimitId}` | `entries`, `gatewayIdentifier`, `rateLimitId` |
| `UpdateGatewayRule` | PATCH | `/gateways/{gatewayIdentifier}/rules/{ruleId}` | `gatewayIdentifier`, `ruleId` |
| `UpdateGatewayTarget` | PUT | `/gateways/{gatewayIdentifier}/targets/{targetId}/` | `gatewayIdentifier`, `targetConfiguration`, `targetId` |
| `UpdateHarness` | PATCH | `/harnesses/{harnessId}` | `harnessId` |
| `UpdateHarnessEndpoint` | PATCH | `/harnesses/{harnessId}/endpoints/{endpointName}` | `endpointName`, `harnessId` |
| `UpdateMemory` | PUT | `/memories/{memoryId}/update` | `memoryId` |
| `UpdateOauth2CredentialProvider` | POST | `/identities/UpdateOauth2CredentialProvider` | `credentialProviderVendor`, `name`, `oauth2ProviderConfigInput` |
| `UpdateOnlineEvaluationConfig` | PUT | `/online-evaluation-configs/{onlineEvaluationConfigId}` | `onlineEvaluationConfigId` |
| `UpdatePaymentConnector` | PATCH | `/payments/managers/{paymentManagerId}/connectors/{paymentConnectorId}` | `paymentConnectorId`, `paymentManagerId` |
| `UpdatePaymentCredentialProvider` | POST | `/identities/UpdatePaymentCredentialProvider` | `credentialProviderVendor`, `name`, `providerConfigurationInput` |
| `UpdatePaymentManager` | PATCH | `/payments/managers/{paymentManagerId}` | `paymentManagerId` |
| `UpdatePolicy` | PATCH | `/policy-engines/{policyEngineId}/policies/{policyId}` | `policyEngineId`, `policyId` |
| `UpdatePolicyEngine` | PATCH | `/policy-engines/{policyEngineId}` | `policyEngineId` |
| `UpdateRegistry` | PATCH | `/registries/{registryId}` | `registryId` |
| `UpdateRegistryRecord` | PATCH | `/registries/{registryId}/records/{recordId}` | `recordId`, `registryId` |
| `UpdateRegistryRecordStatus` | PATCH | `/registries/{registryId}/records/{recordId}/status` | `recordId`, `registryId`, `status`, `statusReason` |
| `UpdateWorkloadIdentity` | POST | `/identities/UpdateWorkloadIdentity` | `name` |

## `bedrock-data-automation`

Data Automation for Amazon Bedrock · 27 operations.

| Operation | HTTP | Path | Required request members |
|:--|:--|:--|:--|
| `CopyBlueprintStage` | PUT | `/blueprints/{blueprintArn}/copy-stage` | `blueprintArn`, `sourceStage`, `targetStage` |
| `CreateBlueprint` | PUT | `/blueprints/` | `blueprintName`, `schema`, `type` |
| `CreateBlueprintVersion` | POST | `/blueprints/{blueprintArn}/versions/` | `blueprintArn` |
| `CreateDataAutomationLibrary` | PUT | `/data-automation-libraries/` | `libraryName` |
| `CreateDataAutomationProject` | PUT | `/data-automation-projects/` | `projectName`, `standardOutputConfiguration` |
| `DeleteBlueprint` | DELETE | `/blueprints/{blueprintArn}/` | `blueprintArn` |
| `DeleteDataAutomationLibrary` | DELETE | `/data-automation-libraries/{libraryArn}/` | `libraryArn` |
| `DeleteDataAutomationProject` | DELETE | `/data-automation-projects/{projectArn}/` | `projectArn` |
| `GetBlueprint` | POST | `/blueprints/{blueprintArn}/` | `blueprintArn` |
| `GetBlueprintOptimizationStatus` | POST | `/getBlueprintOptimizationStatus/{invocationArn}` | `invocationArn` |
| `GetDataAutomationLibrary` | POST | `/data-automation-libraries/{libraryArn}/` | `libraryArn` |
| `GetDataAutomationLibraryEntity` | POST | `/data-automation-libraries/{libraryArn}/entityType/{entityType}/entities/{entityId}` | `entityId`, `entityType`, `libraryArn` |
| `GetDataAutomationLibraryIngestionJob` | POST | `/data-automation-libraries/{libraryArn}/library-ingestion-jobs/{jobArn}` | `jobArn`, `libraryArn` |
| `GetDataAutomationProject` | POST | `/data-automation-projects/{projectArn}/` | `projectArn` |
| `InvokeBlueprintOptimizationAsync` | POST | `/invokeBlueprintOptimizationAsync` | `blueprint`, `dataAutomationProfileArn`, `outputConfiguration`, `samples` |
| `InvokeDataAutomationLibraryIngestionJob` | PUT | `/data-automation-libraries/{libraryArn}/library-ingestion-jobs/` | `entityType`, `inputConfiguration`, `libraryArn`, `operationType`, `outputConfiguration` |
| `ListBlueprints` | POST | `/blueprints/` | — |
| `ListDataAutomationLibraries` | POST | `/data-automation-libraries/` | — |
| `ListDataAutomationLibraryEntities` | POST | `/data-automation-libraries/{libraryArn}/entityType/{entityType}/entities/` | `entityType`, `libraryArn` |
| `ListDataAutomationLibraryIngestionJobs` | POST | `/data-automation-libraries/{libraryArn}/library-ingestion-jobs/` | `libraryArn` |
| `ListDataAutomationProjects` | POST | `/data-automation-projects/` | — |
| `ListTagsForResource` | POST | `/listTagsForResource` | `resourceARN` |
| `TagResource` | POST | `/tagResource` | `resourceARN`, `tags` |
| `UntagResource` | POST | `/untagResource` | `resourceARN`, `tagKeys` |
| `UpdateBlueprint` | PUT | `/blueprints/{blueprintArn}/` | `blueprintArn`, `schema` |
| `UpdateDataAutomationLibrary` | PUT | `/data-automation-libraries/{libraryArn}/` | `libraryArn` |
| `UpdateDataAutomationProject` | PUT | `/data-automation-projects/{projectArn}/` | `projectArn`, `standardOutputConfiguration` |

## `bedrock-data-automation-runtime`

Runtime for Amazon Bedrock Data Automation · 6 operations.

| Operation | HTTP | Path | Required request members |
|:--|:--|:--|:--|
| `GetDataAutomationStatus` | POST | `/` | `invocationArn` |
| `InvokeDataAutomation` | POST | `/` | `dataAutomationProfileArn`, `inputConfiguration` |
| `InvokeDataAutomationAsync` | POST | `/` | `dataAutomationProfileArn`, `inputConfiguration`, `outputConfiguration` |
| `ListTagsForResource` | POST | `/` | `resourceARN` |
| `TagResource` | POST | `/` | `resourceARN`, `tags` |
| `UntagResource` | POST | `/` | `resourceARN`, `tagKeys` |

## `bedrock-runtime`

Amazon Bedrock Runtime · 11 operations.

| Operation | HTTP | Path | Required request members |
|:--|:--|:--|:--|
| `ApplyGuardrail` | POST | `/guardrail/{guardrailIdentifier}/version/{guardrailVersion}/apply` | `content`, `guardrailIdentifier`, `guardrailVersion`, `source` |
| `Converse` | POST | `/model/{modelId}/converse` | `modelId` |
| `ConverseStream` | POST | `/model/{modelId}/converse-stream` | `modelId` |
| `CountTokens` | POST | `/model/{modelId}/count-tokens` | `input`, `modelId` |
| `GetAsyncInvoke` | GET | `/async-invoke/{invocationArn}` | `invocationArn` |
| `InvokeGuardrailChecks` | POST | `/guardrail-checks/invoke` | `checks`, `messages` |
| `InvokeModel` | POST | `/model/{modelId}/invoke` | `modelId` |
| `InvokeModelWithBidirectionalStream` | POST | `/model/{modelId}/invoke-with-bidirectional-stream` | `body`, `modelId` |
| `InvokeModelWithResponseStream` | POST | `/model/{modelId}/invoke-with-response-stream` | `modelId` |
| `ListAsyncInvokes` | GET | `/async-invoke` | — |
| `StartAsyncInvoke` | POST | `/async-invoke` | `modelId`, `modelInput`, `outputDataConfig` |

## `s3vectors`

Amazon S3 Vectors · 21 operations.

| Operation | HTTP | Path | Required request members |
|:--|:--|:--|:--|
| `CreateIndex` | POST | `/CreateIndex` | `dataType`, `dimension`, `distanceMetric`, `indexName` |
| `CreateVectorBucket` | POST | `/CreateVectorBucket` | `vectorBucketName` |
| `DeleteIndex` | POST | `/DeleteIndex` | — |
| `DeleteVectorBucket` | POST | `/DeleteVectorBucket` | — |
| `DeleteVectorBucketPolicy` | POST | `/DeleteVectorBucketPolicy` | — |
| `DeleteVectors` | POST | `/DeleteVectors` | `keys` |
| `GetIndex` | POST | `/GetIndex` | — |
| `GetVectorBucket` | POST | `/GetVectorBucket` | — |
| `GetVectorBucketPolicy` | POST | `/GetVectorBucketPolicy` | — |
| `GetVectors` | POST | `/GetVectors` | `keys` |
| `ListIndexes` | POST | `/ListIndexes` | — |
| `ListTagsForResource` | GET | `/tags/{resourceArn}` | `resourceArn` |
| `ListVectorBuckets` | POST | `/ListVectorBuckets` | — |
| `ListVectors` | POST | `/ListVectors` | — |
| `PutVectorBucketDefaultIndexMode` | POST | `/PutVectorBucketDefaultIndexMode` | `defaultIndexMode` |
| `PutVectorBucketPolicy` | POST | `/PutVectorBucketPolicy` | `policy` |
| `PutVectors` | POST | `/PutVectors` | `vectors` |
| `QueryVectors` | POST | `/QueryVectors` | `queryVector`, `topK` |
| `TagResource` | POST | `/tags/{resourceArn}` | `resourceArn`, `tags` |
| `UntagResource` | DELETE | `/tags/{resourceArn}` | `resourceArn`, `tagKeys` |
| `UpdateIndexMode` | POST | `/UpdateIndexMode` | `indexMode` |

## How to use this

```bash
# Does an operation exist, and on which service?
jq -r '.services | to_entries[] | .key as $s | .value.operations | keys[] | "\($s) \(.)"' \
  references/bedrock-api-operations.json | grep -i retrieve

# What are the request fields of Converse?
jq '.services["bedrock-runtime"].operations.Converse.request' references/bedrock-api-operations.json
```

The IAM action for an operation is usually `<signing name>:<Operation>`, but not always — Converse, for example, is authorised by `bedrock:InvokeModel`. Check the operation's page in the API reference.
