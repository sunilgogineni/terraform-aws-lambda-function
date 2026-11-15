# AWS CDK and CloudFormation — Bedrock-related constructs and resource types

> **Generated from the installed library** — `aws-cdk-lib` **2.277.0**, on 2026-11-15.
> Regenerate with `scripts/gen-cdk-reference.py`; do not edit by hand.

The CDK's L1 (`Cfn*`) constructs are generated from the CloudFormation resource specification, so the resource types below are the CloudFormation types this CDK release knows about. A type that is missing here may still exist in CloudFormation if it was released after this CDK version — check the [CloudFormation template reference](https://docs.aws.amazon.com/AWSCloudFormation/latest/TemplateReference/aws-template-resource-type-ref.html).

Related chapters: [CDK coverage for Amazon Bedrock](../04-infrastructure-as-code/aws-cdk/09-cdk-for-bedrock.md) · [CloudFormation coverage for Amazon Bedrock](../04-infrastructure-as-code/cloudformation/07-cloudformation-for-bedrock.md) · [Feature verification matrix](../FEATURE-VERIFICATION.md)

## Summary

| Module | CloudFormation types (L1) | Stable L2 resource constructs |
|:--|--:|--:|
| Amazon Bedrock | 23 | 0 |
| Amazon Bedrock AgentCore | 27 | 14 |
| Amazon Bedrock (bedrock-mantle endpoint) | 1 | 0 |
| AWS Agent Registry | 2 | 0 |
| Amazon S3 Vectors | 3 | 0 |
| Amazon OpenSearch Serverless | 9 | 0 |

## Amazon Bedrock — `aws-cdk-lib/aws-bedrock`

Import: `import { aws_bedrock } from 'aws-cdk-lib';`

### CloudFormation resource types and their L1 constructs

| CloudFormation type | L1 construct |
|:--|:--|
| `AWS::Bedrock::Agent` | `aws_bedrock.CfnAgent` |
| `AWS::Bedrock::AgentAlias` | `aws_bedrock.CfnAgentAlias` |
| `AWS::Bedrock::ApplicationInferenceProfile` | `aws_bedrock.CfnApplicationInferenceProfile` |
| `AWS::Bedrock::AutomatedReasoningPolicy` | `aws_bedrock.CfnAutomatedReasoningPolicy` |
| `AWS::Bedrock::AutomatedReasoningPolicyVersion` | `aws_bedrock.CfnAutomatedReasoningPolicyVersion` |
| `AWS::Bedrock::Blueprint` | `aws_bedrock.CfnBlueprint` |
| `AWS::Bedrock::DataAutomationLibrary` | `aws_bedrock.CfnDataAutomationLibrary` |
| `AWS::Bedrock::DataAutomationProject` | `aws_bedrock.CfnDataAutomationProject` |
| `AWS::Bedrock::DataSource` | `aws_bedrock.CfnDataSource` |
| `AWS::Bedrock::EnforcedGuardrailConfiguration` | `aws_bedrock.CfnEnforcedGuardrailConfiguration` |
| `AWS::Bedrock::Flow` | `aws_bedrock.CfnFlow` |
| `AWS::Bedrock::FlowAlias` | `aws_bedrock.CfnFlowAlias` |
| `AWS::Bedrock::FlowVersion` | `aws_bedrock.CfnFlowVersion` |
| `AWS::Bedrock::Guardrail` | `aws_bedrock.CfnGuardrail` |
| `AWS::Bedrock::GuardrailVersion` | `aws_bedrock.CfnGuardrailVersion` |
| `AWS::Bedrock::IntelligentPromptRouter` | `aws_bedrock.CfnIntelligentPromptRouter` |
| `AWS::Bedrock::KnowledgeBase` | `aws_bedrock.CfnKnowledgeBase` |
| `AWS::Bedrock::KnowledgeBasePolicy` | `aws_bedrock.CfnKnowledgeBasePolicy` |
| `AWS::Bedrock::Prompt` | `aws_bedrock.CfnPrompt` |
| `AWS::Bedrock::PromptVersion` | `aws_bedrock.CfnPromptVersion` |
| `AWS::Bedrock::ResourcePolicy` | `aws_bedrock.CfnResourcePolicy` |
| `AWS::Bedrock::RetrievalInstruction` | `aws_bedrock.CfnRetrievalInstruction` |
| `AWS::Bedrock::Session` | `aws_bedrock.CfnSession` |

_No L2 resource constructs for this module in the stable library; use the L1 constructs above._

## Amazon Bedrock AgentCore — `aws-cdk-lib/aws-bedrockagentcore`

Import: `import { aws_bedrockagentcore } from 'aws-cdk-lib';`

### CloudFormation resource types and their L1 constructs

| CloudFormation type | L1 construct |
|:--|:--|
| `AWS::BedrockAgentCore::ApiKeyCredentialProvider` | `aws_bedrockagentcore.CfnApiKeyCredentialProvider` |
| `AWS::BedrockAgentCore::BrowserCustom` | `aws_bedrockagentcore.CfnBrowserCustom` |
| `AWS::BedrockAgentCore::BrowserProfile` | `aws_bedrockagentcore.CfnBrowserProfile` |
| `AWS::BedrockAgentCore::CapacityProvider` | `aws_bedrockagentcore.CfnCapacityProvider` |
| `AWS::BedrockAgentCore::CodeInterpreterCustom` | `aws_bedrockagentcore.CfnCodeInterpreterCustom` |
| `AWS::BedrockAgentCore::ConfigurationBundle` | `aws_bedrockagentcore.CfnConfigurationBundle` |
| `AWS::BedrockAgentCore::ConsentPortal` | `aws_bedrockagentcore.CfnConsentPortal` |
| `AWS::BedrockAgentCore::Dataset` | `aws_bedrockagentcore.CfnDataset` |
| `AWS::BedrockAgentCore::Evaluator` | `aws_bedrockagentcore.CfnEvaluator` |
| `AWS::BedrockAgentCore::Gateway` | `aws_bedrockagentcore.CfnGateway` |
| `AWS::BedrockAgentCore::GatewayRateLimit` | `aws_bedrockagentcore.CfnGatewayRateLimit` |
| `AWS::BedrockAgentCore::GatewayRule` | `aws_bedrockagentcore.CfnGatewayRule` |
| `AWS::BedrockAgentCore::GatewayTarget` | `aws_bedrockagentcore.CfnGatewayTarget` |
| `AWS::BedrockAgentCore::Harness` | `aws_bedrockagentcore.CfnHarness` |
| `AWS::BedrockAgentCore::HarnessEndpoint` | `aws_bedrockagentcore.CfnHarnessEndpoint` |
| `AWS::BedrockAgentCore::Memory` | `aws_bedrockagentcore.CfnMemory` |
| `AWS::BedrockAgentCore::OAuth2CredentialProvider` | `aws_bedrockagentcore.CfnOAuth2CredentialProvider` |
| `AWS::BedrockAgentCore::OnlineEvaluationConfig` | `aws_bedrockagentcore.CfnOnlineEvaluationConfig` |
| `AWS::BedrockAgentCore::PaymentConnector` | `aws_bedrockagentcore.CfnPaymentConnector` |
| `AWS::BedrockAgentCore::PaymentCredentialProvider` | `aws_bedrockagentcore.CfnPaymentCredentialProvider` |
| `AWS::BedrockAgentCore::PaymentManager` | `aws_bedrockagentcore.CfnPaymentManager` |
| `AWS::BedrockAgentCore::Policy` | `aws_bedrockagentcore.CfnPolicy` |
| `AWS::BedrockAgentCore::PolicyEngine` | `aws_bedrockagentcore.CfnPolicyEngine` |
| `AWS::BedrockAgentCore::ResourcePolicy` | `aws_bedrockagentcore.CfnResourcePolicy` |
| `AWS::BedrockAgentCore::Runtime` | `aws_bedrockagentcore.CfnRuntime` |
| `AWS::BedrockAgentCore::RuntimeEndpoint` | `aws_bedrockagentcore.CfnRuntimeEndpoint` |
| `AWS::BedrockAgentCore::WorkloadIdentity` | `aws_bedrockagentcore.CfnWorkloadIdentity` |

### Higher-level (L2) constructs in the stable library

These classes ship in `aws-cdk-lib` itself (stable, semantic-versioned API):

`ApiKeyCredentialProvider`, `BrowserCustom`, `CodeInterpreterCustom`, `Evaluator`, `Gateway`, `GatewayTarget`, `Memory`, `OAuth2CredentialProvider`, `OnlineEvaluationConfig`, `Policy`, `PolicyEngine`, `Runtime`, `RuntimeEndpoint`, `WorkloadIdentity`

## Amazon Bedrock (bedrock-mantle endpoint) — `aws-cdk-lib/aws-bedrockmantle`

Import: `import { aws_bedrockmantle } from 'aws-cdk-lib';`

### CloudFormation resource types and their L1 constructs

| CloudFormation type | L1 construct |
|:--|:--|
| `AWS::BedrockMantle::Project` | `aws_bedrockmantle.CfnProject` |

_No L2 resource constructs for this module in the stable library; use the L1 constructs above._

## AWS Agent Registry — `aws-cdk-lib/aws-agentregistry`

Import: `import { aws_agentregistry } from 'aws-cdk-lib';`

### CloudFormation resource types and their L1 constructs

| CloudFormation type | L1 construct |
|:--|:--|
| `AWS::AgentRegistry::Registry` | `aws_agentregistry.CfnRegistry` |
| `AWS::AgentRegistry::RegistryRecord` | `aws_agentregistry.CfnRegistryRecord` |

_No L2 resource constructs for this module in the stable library; use the L1 constructs above._

## Amazon S3 Vectors — `aws-cdk-lib/aws-s3vectors`

Import: `import { aws_s3vectors } from 'aws-cdk-lib';`

### CloudFormation resource types and their L1 constructs

| CloudFormation type | L1 construct |
|:--|:--|
| `AWS::S3Vectors::Index` | `aws_s3vectors.CfnIndex` |
| `AWS::S3Vectors::VectorBucket` | `aws_s3vectors.CfnVectorBucket` |
| `AWS::S3Vectors::VectorBucketPolicy` | `aws_s3vectors.CfnVectorBucketPolicy` |

_No L2 resource constructs for this module in the stable library; use the L1 constructs above._

## Amazon OpenSearch Serverless — `aws-cdk-lib/aws-opensearchserverless`

Import: `import { aws_opensearchserverless } from 'aws-cdk-lib';`

### CloudFormation resource types and their L1 constructs

| CloudFormation type | L1 construct |
|:--|:--|
| `AWS::OpenSearchServerless::AccessPolicy` | `aws_opensearchserverless.CfnAccessPolicy` |
| `AWS::OpenSearchServerless::Collection` | `aws_opensearchserverless.CfnCollection` |
| `AWS::OpenSearchServerless::CollectionGroup` | `aws_opensearchserverless.CfnCollectionGroup` |
| `AWS::OpenSearchServerless::CollectionIndex` | `aws_opensearchserverless.CfnCollectionIndex` |
| `AWS::OpenSearchServerless::Index` | `aws_opensearchserverless.CfnIndex` |
| `AWS::OpenSearchServerless::LifecyclePolicy` | `aws_opensearchserverless.CfnLifecyclePolicy` |
| `AWS::OpenSearchServerless::SecurityConfig` | `aws_opensearchserverless.CfnSecurityConfig` |
| `AWS::OpenSearchServerless::SecurityPolicy` | `aws_opensearchserverless.CfnSecurityPolicy` |
| `AWS::OpenSearchServerless::VpcEndpoint` | `aws_opensearchserverless.CfnVpcEndpoint` |

_No L2 resource constructs for this module in the stable library; use the L1 constructs above._

## Experimental L2 constructs — `@aws-cdk/aws-bedrock-alpha` 2.277.0-alpha.0

> [!WARNING]
> This package is **experimental**: its API can change in any release and it is versioned as `<cdk-version>-alpha.0`. Pin the exact version and expect breaking changes on upgrade.

`Agent`, `AgentAlias`, `ApplicationInferenceProfile`, `Guardrail`, `GuardrailVersion`, `KnowledgeBase`, `Prompt`, `PromptVersion`
