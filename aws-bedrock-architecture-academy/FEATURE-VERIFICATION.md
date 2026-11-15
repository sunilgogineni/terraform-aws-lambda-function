# Feature verification matrix

> **Verification date: 2026-11-15.** Everything below was read on that date from the official page
> linked in the same row, or taken mechanically from a tool (the Terraform provider's schema, the
> installed AWS CDK library). Nothing in this file is written from memory.

This is the academy's source of truth for **what exists, what it is called today, and what
status it has**. Chapters cite from here. If a chapter and this file disagree, this file is
wrong or stale — fix it here first.

[Academy home](README.md) · [Source register](SOURCES.md) · [Generated Terraform reference](references/terraform-aws-provider-bedrock.md) · [Generated CDK / CloudFormation reference](references/cdk-and-cloudformation-bedrock.md)

## How to read this file

| Symbol / word | Meaning |
|:--|:--|
| **GA** | Generally available |
| **Preview** | Public preview — APIs, limits and pricing can change |
| **Maintenance** | Still works for existing users; closed to new customers or no new features |
| ✅ | Supported — the named resource exists in the stated tool version |
| ❌ | No resource of that kind in the stated tool version |
| n/a | Not something you provision (a request-time option or data-plane call) |
| **UNVERIFIED** | Could not be confirmed on an official page — see [Open items](#open-items--unverified) |

**Tool versions used for the IaC columns**

| Tool | Version | How the column was produced |
|:--|:--|:--|
| Terraform CLI | 1.17.2 | — |
| `hashicorp/aws` provider | 6.73.0 | `terraform providers schema -json` → [`references/terraform-aws-provider-bedrock.md`](references/terraform-aws-provider-bedrock.md) |
| `aws-cdk-lib` | 2.277.0 | Installed package inspected → [`references/cdk-and-cloudformation-bedrock.md`](references/cdk-and-cloudformation-bedrock.md) |
| `@aws-cdk/aws-bedrock-alpha` | 2.277.0-alpha.0 | Installed package inspected (experimental API) |
| CloudFormation | resource spec bundled in `aws-cdk-lib` 2.277.0 | L1 constructs are generated from the CloudFormation specification |
| AWS SDK service models | `botocore` 1.44.3 | API operation names and request members → [`references/bedrock-api-operations.md`](references/bedrock-api-operations.md) |

> [!IMPORTANT]
> **Status** — A "❌" in the CloudFormation column means the type is absent from the specification
> bundled with `aws-cdk-lib` 2.277.0. CloudFormation itself may have added it later; check the
> [CloudFormation template reference](https://docs.aws.amazon.com/AWSCloudFormation/latest/TemplateReference/aws-template-resource-type-ref.html).

## What changed since older tutorials

If you learned Bedrock from material written before mid-2026, these are the facts most likely
to be out of date in your head.

| # | Then | Now (verified 2026-11-15) | Source |
|--:|:--|:--|:--|
| 1 | "Amazon Bedrock Agents" is the way to build agents | Renamed **Amazon Bedrock Agents Classic**; in **maintenance mode**; closed to new customers since **2026-07-30**. AWS recommends AgentCore, with the managed **harness** as the migration path | [Agents Classic maintenance mode](https://docs.aws.amazon.com/bedrock/latest/userguide/agents-classic-maintenance-mode.html) |
| 2 | A knowledge base always needs a vector store you create | Two types: **Managed Knowledge Base** (GA 2026-06-17, AWS-managed storage, recommended by AWS) and **customer-managed** | [Managed Knowledge Base GA](https://aws.amazon.com/about-aws/whats-new/2026/06/amazon-bedrock-managed-knowledge-base/) |
| 3 | `RetrieveAndGenerate` is the one-call RAG API | Not supported on Managed Knowledge Base; **`AgenticRetrieveStream`** replaces it (and with `maxAgentIteration=1` behaves as single-shot RAG) | [AgenticRetrieveStream](https://docs.aws.amazon.com/bedrock/latest/APIReference/API_agent-runtime_AgenticRetrieveStream.html) |
| 4 | You must "request model access" in the console first | The request step is gone (since 2025-10-15). Access is on by default when the IAM principal has AWS Marketplace subscribe permissions | [Model access](https://docs.aws.amazon.com/bedrock/latest/userguide/model-access.html) |
| 5 | Converse and InvokeModel are the inference APIs | `bedrock-runtime` also serves the **OpenAI Responses and Chat Completions** APIs and the **Anthropic Messages** API. A second endpoint, **`bedrock-mantle`**, carries Projects/Workspaces, background inference and the Web Search tool | [Endpoints](https://docs.aws.amazon.com/bedrock/latest/userguide/endpoints.html) |
| 6 | Cross-Region inference = geography profiles (`us.`, `eu.`) | **Geo** profiles plus **Global** (`global.`) profiles, and four **service tiers** (reserved, priority, default, flex) | [Cross-Region inference](https://docs.aws.amazon.com/bedrock/latest/userguide/cross-region-inference.html), [Service tiers](https://docs.aws.amazon.com/bedrock/latest/userguide/service-tiers-inference.html) |
| 7 | Prompt caching lasts 5 minutes | TTL **depends on the model**: 5 min and 1 h for current Claude models, 30 min for GPT-5.6/6.x, 5 min for Nova | [Prompt caching](https://docs.aws.amazon.com/bedrock/latest/userguide/prompt-caching.html) |
| 8 | AgentCore = Runtime, Gateway, Identity, Memory, Observability, Browser, Code Interpreter | **Thirteen services**: those seven plus Harness, Policy, Evaluations, Optimization, Registry and Payments (GA since 2026-08-18), with Web Search / Web Answer as separate features | [What is AgentCore](https://docs.aws.amazon.com/bedrock-agentcore/latest/devguide/what-is-bedrock-agentcore.html), [Payments GA](https://aws.amazon.com/about-aws/whats-new/2026/08/bedrock-agentcore-payments-ga/) |
| 9 | Terraform S3 state needs a DynamoDB lock table | **Native S3 locking** (`use_lockfile = true`) is GA since Terraform 1.11; DynamoDB locking is deprecated | [S3 backend](https://developer.hashicorp.com/terraform/language/backend/s3) |
| 10 | tfsec for Terraform security scanning | tfsec is folded into **Trivy**; and Trivy's GitHub Action was compromised in March 2026 — pin Actions to commit SHAs | [tfsec README](https://raw.githubusercontent.com/aquasecurity/tfsec/master/README.md), [Trivy advisory](https://github.com/aquasecurity/trivy/security/advisories/GHSA-69fq-xp46-6x23) |
| 11 | CDK for Terraform (CDKTF) is an option | **Archived** on 2025-12-10; HashiCorp no longer maintains it | [CDKTF README](https://raw.githubusercontent.com/hashicorp/terraform-cdk/main/README.md) |
| 12 | Amazon Kendra as a managed retriever | Kendra is in **maintenance mode** (effective 2026-06-30) and closed to new customers since **2026-07-30**; AWS points migrations to Managed Knowledge Base | [AWS service availability change](https://aws.amazon.com/about-aws/whats-new/2026/06/aws-service-availability/), [Kendra availability change](https://docs.aws.amazon.com/kendra/latest/dg/kendra-availability-change.html) |

## A. Amazon Bedrock — core service

Service namespaces referred to below: `bedrock` (control plane), `bedrock-runtime` (inference),
`bedrock-mantle` (second inference endpoint), `bedrock-agent` and `bedrock-agent-runtime`
(Agents Classic, knowledge bases, flows, prompts), `bedrock-data-automation` and
`bedrock-data-automation-runtime`.

### A1. Inference

| Feature | Status | APIs and namespace | Notes verified | Terraform | CloudFormation | CDK | Source |
|:--|:-:|:--|:--|:--|:--|:--|:--|
| Converse / ConverseStream | GA | `bedrock-runtime` | Unified message API across models | n/a (data plane) | n/a | n/a | [Overview](https://docs.aws.amazon.com/bedrock/latest/userguide/what-is-bedrock.html) |
| InvokeModel / InvokeModelWithResponseStream | GA | `bedrock-runtime` | Model-native request body | n/a | n/a | n/a | [Overview](https://docs.aws.amazon.com/bedrock/latest/userguide/what-is-bedrock.html) |
| Other `bedrock-runtime` operations | — | `StartAsyncInvoke` / `GetAsyncInvoke` / `ListAsyncInvokes` (asynchronous invoke, output to S3); `InvokeModelWithBidirectionalStream` (two-way stream); `CountTokens` (`POST /model/{modelId}/count-tokens`, returns `inputTokens`) | All present in the SDK model. Token counting "for some models" since 2025-08-21; on `bedrock-mantle`, Claude token counting uses the Anthropic `count_tokens` path, including models that `CountTokens` on `bedrock-runtime` does not support (2026-05-26). Supported models per operation **UNVERIFIED** (U17) | n/a | n/a | n/a | [Generated API reference](references/bedrock-api-operations.md), [Document history](https://docs.aws.amazon.com/bedrock/latest/userguide/bedrock-ug-doc-history.html) |
| Latency-optimized inference | **Preview** | `performanceConfig.latency` = `standard` (default) or `optimized` on `bedrock-runtime` | Amazon Nova Pro, Claude 3.5 Haiku, Llama 3.1 405B and 70B, through cross-Region inference in US East (Ohio) and US West (Oregon) (Nova Pro also US East (N. Virginia)). Above the latency-optimization quota, requests fall back to standard latency and standard price. The FAQ still names Ohio only; the user guide is followed | n/a (request option) | n/a | n/a | [Latency-optimized inference](https://docs.aws.amazon.com/bedrock/latest/userguide/latency-optimized-inference.html), [Bedrock FAQ](https://aws.amazon.com/bedrock/faqs/) |
| OpenAI Responses and Chat Completions APIs | GA | `bedrock-runtime` at `/openai/v1`; also `bedrock-mantle` | On `bedrock-runtime` the Responses API is synchronous only, default project only, and rejects application inference profiles. Whether Chat Completions accepts application inference profiles: two AWS pages disagree (C6) — the academy treats both APIs as **not** accepting them | n/a | n/a | n/a | [Responses API](https://docs.aws.amazon.com/bedrock/latest/userguide/inference-responses-api.html), [Endpoints](https://docs.aws.amazon.com/bedrock/latest/userguide/endpoints.html), [Application inference profiles](https://docs.aws.amazon.com/bedrock/latest/userguide/cost-mgmt-application-inference-profiles.html) |
| Anthropic Messages API | GA | `bedrock-runtime` at `/anthropic`; also `bedrock-mantle` | — | n/a | n/a | n/a | [Endpoints](https://docs.aws.amazon.com/bedrock/latest/userguide/endpoints.html) |
| `bedrock-mantle` endpoint | GA | `bedrock-mantle.{region}.api.aws`; IAM action `bedrock-mantle:CreateInference` | Needed only for server-side tools (Web Search), `background=true`, Projects/Workspaces, or mantle-only models. **AWS recommends `bedrock-runtime` for new applications.** Guardrails and intelligent prompt routing are runtime-only. Same per-token price on both endpoints | ❌ | ✅ `AWS::BedrockMantle::Project` | L1 `aws_bedrockmantle.CfnProject` | [Endpoints](https://docs.aws.amazon.com/bedrock/latest/userguide/endpoints.html) |
| Authentication | GA | SigV4, or a Bedrock API key sent as `Authorization: Bearer` (or `AWS_BEARER_TOKEN_BEDROCK`) | API keys come in two types. **Short-term**: up to 12 h (or the session, if shorter), inherits the generating principal's permissions, one Region; generated with `aws-bedrock-token-generator`; AWS recommends it for production. **Long-term**: an IAM user plus a service-specific credential (`iam:CreateServiceSpecificCredential` for `bedrock.amazonaws.com`, limited with `iam:ServiceSpecificCredentialAgeDays`); AWS says exploration only. Key use is authorised by the IAM-only actions `bedrock:CallWithBearerToken` and `bedrock-mantle:CallWithBearerToken`, with condition key `bedrock:bearerTokenType` (`SHORT_TERM` / `LONG_TERM`); denying them blocks API-key use | n/a | n/a | n/a | [Endpoints](https://docs.aws.amazon.com/bedrock/latest/userguide/endpoints.html), [API keys](https://docs.aws.amazon.com/bedrock/latest/userguide/api-keys.html) |
| Data retention modes | — (no preview label; API only at launch, no console UI) | Account per Region: `GetAccountDataRetention` / `PutAccountDataRetention` (`bedrock`, `/data-retention`) for `bedrock-runtime`; `/v1/data_retention` and per-project settings on `bedrock-mantle` | Modes, least to most permissive: `none` (zero retention) < `default` (the model's own policy) < `aws_review` (AWS may retain and human-review; content not shared with the provider) < `provider_data_share` (legacy, not exercised). `inherit` defers to the broader scope: project → account → model default. Each model declares `allowed_modes`; below its minimum the model is unavailable on mantle and returns `ValidationException` on runtime (for example, Claude Fable 5.x require `aws_review`). Enforced for the Messages, Chat Completions and Responses APIs | ❌ | ❌ | ❌ | [Data retention](https://docs.aws.amazon.com/bedrock/latest/userguide/data-retention.html), [Generated API reference](references/bedrock-api-operations.md) |
| Regional endpoints and quotas | — | Control plane `bedrock`, runtime `bedrock-runtime`, `bedrock-mantle` (a subset of Regions) | The General Reference lists the control plane in 35 Regions and `bedrock-runtime` in **22**; the user guide says `bedrock-runtime` is available in every Region where Bedrock is offered — C9. 2026-09-21: the per-model tokens-per-day quota on `bedrock-runtime` became a cross-model, per-account, per-Region quota | n/a | n/a | n/a | [Bedrock endpoints and quotas](https://docs.aws.amazon.com/general/latest/gr/bedrock.html), [Regional availability by endpoints](https://docs.aws.amazon.com/bedrock/latest/userguide/endpoints-region-availability.html), [Document history](https://docs.aws.amazon.com/bedrock/latest/userguide/bedrock-ug-doc-history.html) |
| Cross-Region inference — Geo profiles | GA | Inference profile IDs prefixed `us.`, `eu.`, `in.` … | Requests stay inside the geography. New in 2026: US Geo for OpenAI models, India geo profiles | data source `aws_bedrock_inference_profile(s)` | n/a | alpha `CrossRegionInferenceProfile` | [Cross-Region inference](https://docs.aws.amazon.com/bedrock/latest/userguide/cross-region-inference.html) |
| Cross-Region inference — Global profiles | GA | IDs prefixed `global.` | Can route to any commercial Region; about 10% cheaper. The "Supported Regions and models for inference profiles" page still says Global is "only supported on Anthropic Claude Sonnet 4"; the document history adds Global profiles for many later models — stale page, C10 | same data sources | n/a | alpha `CrossRegionInferenceProfile` | [Cross-Region inference](https://docs.aws.amazon.com/bedrock/latest/userguide/cross-region-inference.html), [Inference profiles support](https://docs.aws.amazon.com/bedrock/latest/userguide/inference-profiles-support.html) |
| Application inference profiles | GA | `bedrock` control plane | Cost attribution (tags to Cost Explorer and CUR) for **InvokeModel and Converse on `bedrock-runtime`**; one profile per model. For Responses and Chat Completions AWS points to Projects (mantle), IAM principal attribution or request metadata. One page says both APIs reject these profiles on either endpoint with HTTP 400; the cost-tracking comparison table lists Chat Completions as supported — C6 | ✅ `aws_bedrock_inference_profile` | ✅ `AWS::Bedrock::ApplicationInferenceProfile` | L1 · alpha `ApplicationInferenceProfile` | [Cross-Region inference](https://docs.aws.amazon.com/bedrock/latest/userguide/cross-region-inference.html), [Application inference profiles](https://docs.aws.amazon.com/bedrock/latest/userguide/cost-mgmt-application-inference-profiles.html), [Track usage and costs](https://docs.aws.amazon.com/bedrock/latest/userguide/cost-management.html) |
| Service tiers | GA | `service_tier`: `reserved`, `priority`, `default`, `flex` on `bedrock-runtime` | Reserved: 1- or 3-month terms, minimum 100k input / 10k output tokens per minute, through the account team; overflow goes to Standard; 99.5% uptime target. Priority costs about 75% more; Flex about 50% less. Per model. The on-demand quota is shared by priority, default and flex. Priority and Flex added 2025-11-18, Reserved 2025-11-26. A "Capacity and Performance" page describes Reserved in "model units" with per-tier RPM/TPM ranges — C8; the academy follows the service-tiers page | n/a (request option) | n/a | n/a | [Service tiers](https://docs.aws.amazon.com/bedrock/latest/userguide/service-tiers-inference.html), [Capacity and Performance](https://docs.aws.amazon.com/bedrock/latest/userguide/capacity-limits-cost-optimization.html), [Document history](https://docs.aws.amazon.com/bedrock/latest/userguide/bedrock-ug-doc-history.html) |
| Provisioned Throughput | GA | `bedrock` (`CreateProvisionedModelThroughput`) | The purchase page names **two types, by Tokens and by Model Units**; the overview page and the purchase steps describe model units only — the by-Tokens API, terms and prices are **UNVERIFIED** (U15). Model-unit terms: no commitment, 1 month, 6 months; MUs must first be requested through AWS Support. GovCloud: custom models, no commitment only. Not supported with inference profiles. The overview page says customized models *must* use Provisioned Throughput, while the custom-model page also offers on-demand deployment — C7 | ✅ `aws_bedrock_provisioned_model_throughput` | ❌ | ❌ (`ProvisionedModel` only references an existing one) | [Provisioned Throughput](https://docs.aws.amazon.com/bedrock/latest/userguide/prov-throughput.html), [Purchase Provisioned Throughput](https://docs.aws.amazon.com/bedrock/latest/userguide/prov-thru-purchase.html) |
| Batch inference | GA | `CreateModelInvocationJob` (`bedrock`) | About 50% cheaper than on-demand. 2026: Converse input format supported; on-demand traffic takes priority; completion not guaranteed; timeout 24 h default, 168 h max. The API accepts `modelInvocationType` and `tags`; in Terraform 6.73.0 `model_invocation_type` is read-only and there is no `tags` argument, so Converse-format or tagged jobs need the API or CLI | ✅ `aws_bedrock_model_invocation_job` (no Converse format, no tags) | ❌ | ❌ | [Document history](https://docs.aws.amazon.com/bedrock/latest/userguide/bedrock-ug-doc-history.html), [Terraform reference](references/terraform-aws-provider-bedrock.md), [Generated API reference](references/bedrock-api-operations.md) |
| Model invocation logging | GA | `bedrock` (`PutModelInvocationLoggingConfiguration`) | Off by default. Logs Converse, ConverseStream, InvokeModel, InvokeModelWithResponseStream — and the OpenAI-compatible APIs — **only on `bedrock-runtime`**; calls through `bedrock-mantle` are not captured. Destinations: CloudWatch Logs and/or S3 in the same account and Region; bodies over 100 KB go to S3 | ✅ `aws_bedrock_model_invocation_logging_configuration` | ❌ | ❌ | [Model invocation logging](https://docs.aws.amazon.com/bedrock/latest/userguide/model-invocation-logging.html), [Terraform reference](references/terraform-aws-provider-bedrock.md) |
| Intelligent prompt routing | GA | `bedrock-runtime` only (not on mantle) | — | ❌ | ✅ `AWS::Bedrock::IntelligentPromptRouter` | L1 · alpha `PromptRouter` | [Endpoints](https://docs.aws.amazon.com/bedrock/latest/userguide/endpoints.html) |

### A2. Models, access and customization

| Feature | Status | APIs and namespace | Notes verified | Terraform | CloudFormation | CDK | Source |
|:--|:-:|:--|:--|:--|:--|:--|:--|
| Model providers | GA | Model catalog | Pricing page lists AI21, Amazon, Anthropic, Cohere, DeepSeek, Google, Luma, Meta, MiniMax, Mistral, Moonshot, NVIDIA, OpenAI, Qwen, Stability, TwelveLabs, Writer, xAI and Z AI | data source `aws_bedrock_foundation_model(s)` | n/a | `FoundationModel` (reference helper) | [Bedrock pricing](https://aws.amazon.com/bedrock/pricing/) |
| Model access | GA | `PutUseCaseForModelAccess`, `GetFoundationModelAvailability` | No "request access" step. Third-party models auto-subscribe on first call (up to 15 min). Anthropic's first-time-use form still applies to Claude models older than Opus 4.7 (not via mantle). Some models are gated. Some older pages (for example "Prerequisites for inference profiles") still list "requested access" as a prerequisite — stale, C10 | ✅ `aws_bedrock_foundation_model_agreement`, `aws_bedrock_use_case_for_model_access` | ❌ | ❌ | [Model access](https://docs.aws.amazon.com/bedrock/latest/userguide/model-access.html), [Prerequisites for inference profiles](https://docs.aws.amazon.com/bedrock/latest/userguide/inference-profiles-prereq.html) |
| Model lifecycle (legacy / end of life) | — | — | Legacy models cannot be fine-tuned and cannot get new Provisioned Throughput. Example notices: Claude 3.7 Sonnet (move by 2026-04-28), Claude Opus 4 (move by 2026-05-31) | n/a | n/a | n/a | [Document history](https://docs.aws.amazon.com/bedrock/latest/userguide/bedrock-ug-doc-history.html) |
| Supervised fine-tuning | GA | `CreateModelCustomizationJob` (`bedrock`) | Per model | ✅ `aws_bedrock_custom_model` | ❌ | ❌ | [Custom models](https://docs.aws.amazon.com/bedrock/latest/userguide/custom-models.html) |
| Reinforcement fine-tuning | GA | `bedrock`; OpenAI-compatible Files and fine-tuning APIs for open-weight models (2026-02-17) | Per model | ✅ `aws_bedrock_custom_model` (check `customization_type` values in the schema) | ❌ | ❌ | [Custom models](https://docs.aws.amazon.com/bedrock/latest/userguide/custom-models.html) |
| Model distillation | GA | `bedrock` | Per model | ✅ `aws_bedrock_custom_model` (as above) | ❌ | ❌ | [Custom models](https://docs.aws.amazon.com/bedrock/latest/userguide/custom-models.html) |
| Continued pre-training | **UNVERIFIED** | — | No longer listed on the customization overview page; no AWS deprecation notice found | — | — | — | [Custom models](https://docs.aws.amazon.com/bedrock/latest/userguide/custom-models.html) |
| Custom Model Import | GA | `bedrock` (import job) | Billed per Custom Model Unit; scales to zero after 5 idle minutes | ❌ | ❌ | ❌ | [Bedrock pricing](https://aws.amazon.com/bedrock/pricing/) |
| Custom model on-demand deployment | GA | `bedrock` | Since 2025-07-16: deploy a custom model and invoke it by the deployment ARN, pay per token, no Provisioned Throughput. The Provisioned Throughput overview page still says custom models require it — C7 | ❌ | ❌ | ❌ | [Document history](https://docs.aws.amazon.com/bedrock/latest/userguide/bedrock-ug-doc-history.html), [Set up inference for a custom model](https://docs.aws.amazon.com/bedrock/latest/userguide/model-customization-use.html) |
| Amazon Bedrock Marketplace | GA | Subscribe, deploy to a **SageMaker AI-managed endpoint**, then call through InvokeModel / Converse | 2026-10-22: private offers from the AWS Marketplace purchase confirmation page | ❌ | ❌ | ❌ | [Bedrock Marketplace](https://docs.aws.amazon.com/bedrock/latest/userguide/amazon-bedrock-marketplace.html) |
| Model and RAG evaluation | GA | `CreateEvaluationJob`, `StopEvaluationJob`, `BatchDeleteEvaluationJob` (`bedrock`) | Automatic, LLM-as-judge, human workers, RAG evaluation. Judge lists include 2026 models (for example OpenAI GPT-5.4 and GPT-5.5, Claude Opus 4.8). Generator models can be called through the OpenAI Responses API on `bedrock-mantle` — API and CLI only, not the console. API task types: `Summarization`, `Classification`, `QuestionAndAnswer`, `Generation`, `Custom`; `metricNames` 1–25 per dataset in the SDK model (other figures reported — U16). Terraform 6.73.0: destroy only stops the job (provider docs say jobs cannot be deleted, the API has `BatchDeleteEvaluationJob` — C21); RAG settings limited to knowledge base, model and number of results (no filters, reranking, generation or orchestration settings) | ✅ `aws_bedrock_evaluation_job` (limits in notes) | ❌ | ❌ | [Evaluation](https://docs.aws.amazon.com/bedrock/latest/userguide/evaluation.html), [LLM as a judge](https://docs.aws.amazon.com/bedrock/latest/userguide/evaluation-judge.html), [Generated API reference](references/bedrock-api-operations.md), [Terraform resource docs](https://raw.githubusercontent.com/hashicorp/terraform-provider-aws/main/website/docs/r/bedrock_evaluation_job.html.markdown) |

### A3. Prompts

| Feature | Status | APIs and namespace | Notes verified | Terraform | CloudFormation | CDK | Source |
|:--|:-:|:--|:--|:--|:--|:--|:--|
| Prompt management | GA | `bedrock-agent` (`CreatePrompt` …) | — | ✅ `aws_bedrockagent_prompt` | ✅ `AWS::Bedrock::Prompt`, `PromptVersion` | L1 · alpha `Prompt`, `PromptVersion` | [Prompt management](https://docs.aws.amazon.com/bedrock/latest/userguide/prompt-management.html) |
| Advanced Prompt Optimization | GA (2026-05-14) | Console and Bedrock APIs | Up to 5 models per job, 10 templates, 100 samples per template. Evaluation by Lambda, LLM-as-judge or steering criteria. Oct 2026: prompt shortening; application inference profiles as targets. Exact Region list **UNVERIFIED** | ❌ | ❌ | ❌ | [Launch announcement](https://aws.amazon.com/about-aws/whats-new/2026/05/amazon-bedrock-advanced-prompt-optimization-migration-tool/), [How it works](https://docs.aws.amazon.com/bedrock/latest/userguide/advanced-prompt-optimization-how.html) |
| Prompt caching | GA | Converse (`cachePoint`), InvokeModel (`cache_control`), Responses / Chat Completions (`prompt_cache_breakpoint`) | TTL by model: Claude 5 min and 1 h (`"ttl":"1h"`, since 2026-01-26); GPT-5.6/6.x 30 min, no explicit caching via Converse; Nova 5 min. Implicit and explicit caching both exist | n/a (request option) | n/a | n/a | [Prompt caching](https://docs.aws.amazon.com/bedrock/latest/userguide/prompt-caching.html), [1-hour TTL](https://aws.amazon.com/about-aws/whats-new/2026/01/amazon-bedrock-one-hour-duration-prompt-caching/) |

### A4. Knowledge bases and retrieval

| Feature | Status | APIs and namespace | Notes verified | Terraform | CloudFormation | CDK | Source |
|:--|:-:|:--|:--|:--|:--|:--|:--|
| **Managed Knowledge Base** | GA 2026-06-17 | `bedrock-agent` (create, data sources, ingestion); `bedrock-agent-runtime`: `Retrieve`, `AgenticRetrieveStream`, `GetDocumentContent` | AWS-managed storage, hybrid search always on, managed embedding and reranker models (bring-your-own embedding must be float32, 1024 dimensions). Connectors: S3, SharePoint, Confluence, Google Drive, OneDrive, Web Crawler, Custom, plus Salesforce and Zendesk (added 2026-09-23, with their own connector pages); the build page's comparison table and the Kendra migration guide still say "7" — C5. Document-level ACLs; sync schedules. **Resource-based policies** (managed type only): `PutResourcePolicy` / `GetResourcePolicy` / `DeleteResourcePolicy`, granting only `bedrock:Retrieve` and `bedrock:GetDocumentContent`, for example to other accounts. **`RetrieveAndGenerate` is not supported** (API reference; the Kendra migration guide says otherwise — C20). Runtime metrics in `AWS/Bedrock/KnowledgeBases`. Regions: us-east-1, us-west-2, eu-west-1, eu-west-2, eu-central-1, ap-northeast-1, ap-southeast-1, ap-southeast-2, us-gov-west-1 (GovCloud is restricted: S3 and Custom connectors only, no ACLs, no managed models, no agentic retrieval) | ✅ `aws_bedrockagent_knowledge_base` with `managed_knowledge_base_configuration` | ✅ `AWS::Bedrock::KnowledgeBase`, `KnowledgeBasePolicy` | L1 · alpha `KnowledgeBase` | [GA announcement](https://aws.amazon.com/about-aws/whats-new/2026/06/amazon-bedrock-managed-knowledge-base/), [Build a managed KB](https://docs.aws.amazon.com/bedrock/latest/userguide/kb-build-managed.html), [Salesforce and Zendesk connectors](https://aws.amazon.com/about-aws/whats-new/2026/09/amazon-bedrock-managed-knowledge-base-salesforce-zendesk-native-data-source-connectors/), [Resource policies](https://docs.aws.amazon.com/bedrock/latest/userguide/kb-managed-cross-account.html), [RetrieveAndGenerate](https://docs.aws.amazon.com/bedrock/latest/APIReference/API_agent-runtime_RetrieveAndGenerate.html), [Regions](https://docs.aws.amazon.com/bedrock/latest/userguide/kb-managed-regions.html), [Quotas](https://docs.aws.amazon.com/bedrock/latest/userguide/kb-managed-quotas.html) |
| Managed KB pricing dimensions | — | — | Raw data stored per GB-month; `Retrieve` per 1,000 calls; agentic calls per 1,000 plus the underlying retrieves. Managed parsing, embedding and reranking are not charged separately. Figures quoted by research: $5/GB-month, $1 per 1k Retrieve, $4 per 1k agentic calls — confirm on the pricing page before relying on them | — | — | — | [Bedrock pricing](https://aws.amazon.com/bedrock/pricing/) |
| **Customer-managed knowledge base** | GA (AWS now recommends Managed) | `bedrock-agent` (`CreateKnowledgeBase`, `CreateDataSource`, `StartIngestionJob`); `bedrock-agent-runtime`: `Retrieve`, `RetrieveAndGenerate`, `RetrieveAndGenerateStream`, `GenerateQuery` | Quick-create vector stores: OpenSearch Serverless, Aurora PostgreSQL, Neptune Analytics (GraphRAG), S3 Vectors. Bring-your-own: OpenSearch managed clusters (public domains only). **Since 2026-09-30 no new Confluence, SharePoint, Salesforce or Web Crawler connectors** — new ones are S3 and Custom only; existing ones keep working. Resource-based policies are **not** supported (only the managed type) | ✅ `aws_bedrockagent_knowledge_base` (`vector_`, `kendra_`, `sql_knowledge_base_configuration`), `aws_bedrockagent_data_source` | ✅ `AWS::Bedrock::KnowledgeBase`, `DataSource` | L1 · alpha `KnowledgeBase` | [Create a knowledge base](https://docs.aws.amazon.com/bedrock/latest/userguide/knowledge-base-create.html), [Data source connectors](https://docs.aws.amazon.com/bedrock/latest/userguide/data-source-connectors.html), [Supported stores](https://docs.aws.amazon.com/bedrock/latest/userguide/knowledge-base-supported.html) |
| Third-party vector stores (Pinecone, Redis Enterprise Cloud, MongoDB Atlas) for customer-managed KBs | **UNVERIFIED** | — | Not confirmed as still supported; the quick-create section read during research does not list them | provider accepts `pinecone_`, `redis_enterprise_cloud_`, `mongo_db_atlas_configuration` under `storage_configuration` | — | — | [Supported stores](https://docs.aws.amazon.com/bedrock/latest/userguide/knowledge-base-supported.html) |
| Structured data retrieval (Redshift) | GA | `GenerateQuery`, `Retrieve` | Available in 16 Regions. 2026 changes **UNVERIFIED** | ✅ `sql_knowledge_base_configuration` | ✅ | L1 | [Supported stores](https://docs.aws.amazon.com/bedrock/latest/userguide/knowledge-base-supported.html) |
| Kendra GenAI index as a knowledge base | GA; Kendra itself in maintenance mode | — | Whether new use is blocked is **UNVERIFIED** | ✅ `kendra_knowledge_base_configuration` | ✅ | L1 | [AWS service availability change](https://aws.amazon.com/about-aws/whats-new/2026/06/aws-service-availability/) |
| **Agentic retrieval** | GA | `AgenticRetrieveStream` (`bedrock-agent-runtime`, `POST /agenticRetrieveStream`); IAM `bedrock:AgenticRetrieveStream` | **Managed knowledge bases only.** A model plans sub-queries, retrieves, can expand full documents, then streams an answer with citations (`generateResponse` defaults to true). Up to 5 retrievers per request. Model type `MANAGED` or `CUSTOM`; guardrails require `CUSTOM` and only the BLOCK action works. Default quota 300 requests per minute per account. 2026-08: AgentCore Memory (`memoryConfiguration`). 2026-10-19: retrieval instructions. 2026-11-09: `maxAgentIteration` 0–5 (0 = retrieve only, 1 = single-shot RAG). Not in GovCloud | n/a (data plane) | ✅ `AWS::Bedrock::RetrievalInstruction` | L1 | [Test agentic retrieval](https://docs.aws.amazon.com/bedrock/latest/userguide/kb-test-agentic-retrieve.html), [API reference](https://docs.aws.amazon.com/bedrock/latest/APIReference/API_agent-runtime_AgenticRetrieveStream.html) |
| Amazon S3 Vectors (vector store) | GA | `s3vectors` | Quick-create option for customer-managed KBs | ✅ `aws_s3vectors_vector_bucket`, `aws_s3vectors_index`, `aws_s3vectors_vector_bucket_policy` | ✅ `AWS::S3Vectors::VectorBucket`, `Index`, `VectorBucketPolicy` | L1 | [Create a knowledge base](https://docs.aws.amazon.com/bedrock/latest/userguide/knowledge-base-create.html) |

### A5. Agents Classic, Flows, Guardrails, Data Automation

| Feature | Status | APIs and namespace | Notes verified | Terraform | CloudFormation | CDK | Source |
|:--|:-:|:--|:--|:--|:--|:--|:--|
| **Amazon Bedrock Agents Classic** | **Maintenance** | `bedrock-agent`, `bedrock-agent-runtime` (unchanged) | Closed to new customers 2026-07-30. Accounts with no Agents activity in the previous 12 months get HTTP 403 on `CreateAgent` and `InvokeInlineAgent`. Model catalog frozen as of that date. No end-of-life date and no migration deadline announced | ✅ `aws_bedrockagent_agent`, `_agent_action_group`, `_agent_alias`, `_agent_knowledge_base_association` | ✅ `AWS::Bedrock::Agent`, `AgentAlias` | L1 · alpha `Agent`, `AgentAlias` | [Maintenance mode](https://docs.aws.amazon.com/bedrock/latest/userguide/agents-classic-maintenance-mode.html) |
| Multi-agent collaboration (Classic) | Maintenance | `bedrock-agent` | Works for existing accounts only. The AgentCore migration table rates multi-agent routing as "Limited" | ✅ `aws_bedrockagent_agent_collaborator` | ✅ (properties of `AWS::Bedrock::Agent`) | L1 · alpha `AgentCollaborator` | [Maintenance mode](https://docs.aws.amazon.com/bedrock/latest/userguide/agents-classic-maintenance-mode.html) |
| Inline agents (Classic) | Maintenance | `InvokeInlineAgent` | Existing accounts only | n/a | n/a | n/a | [Maintenance mode](https://docs.aws.amazon.com/bedrock/latest/userguide/agents-classic-maintenance-mode.html) |
| Amazon Bedrock Flows | GA | `bedrock-agent`, `bedrock-agent-runtime` (`InvokeFlow`) | No maintenance notice on the Flows page. Earlier name: "Prompt flows". 2026 changes **UNVERIFIED** | ✅ `aws_bedrockagent_flow` | ✅ `AWS::Bedrock::Flow`, `FlowAlias`, `FlowVersion` | L1 | [Flows](https://docs.aws.amazon.com/bedrock/latest/userguide/flows.html) |
| Amazon Bedrock Guardrails | GA | `CreateGuardrail` (`bedrock`); `ApplyGuardrail` (`bedrock-runtime`) | Policies: content filters (text and image, including prompt attacks), denied topics, word filters, sensitive information, contextual grounding, Automated Reasoning. Tiers: Classic and Standard (Standard covers harmful content inside code). 2026-10-19: contextual grounding supports the Standard tier. Works on runtime Responses API via headers; **not on mantle** | ✅ `aws_bedrock_guardrail`, `aws_bedrock_guardrail_version`; ephemeral `aws_bedrockruntime_apply_guardrail` | ✅ `AWS::Bedrock::Guardrail`, `GuardrailVersion` | L1 · alpha `Guardrail`, `GuardrailVersion` | [Guardrails](https://docs.aws.amazon.com/bedrock/latest/userguide/guardrails.html) |
| Automated Reasoning checks | GA | `bedrock` | A guardrail policy type | ❌ | ✅ `AWS::Bedrock::AutomatedReasoningPolicy`, `AutomatedReasoningPolicyVersion` | L1 | [Guardrails](https://docs.aws.amazon.com/bedrock/latest/userguide/guardrails.html) |
| Guardrail enforcement and sharing | GA | IAM condition keys; organisation-wide sharing | IAM condition-key enforcement since 2025; org-wide sharing since Nov 2025. Full Region list for cross-Region guardrail inference **UNVERIFIED** | ✅ `aws_bedrock_enforced_guardrail_configuration`, `aws_bedrock_guardrail_resource_policy` | ✅ `AWS::Bedrock::EnforcedGuardrailConfiguration`, `ResourcePolicy` | L1 | [Guardrails](https://docs.aws.amazon.com/bedrock/latest/userguide/guardrails.html) |
| Amazon Bedrock Data Automation | GA | `bedrock-data-automation` (projects, blueprints, libraries); `bedrock-data-automation-runtime` (`InvokeDataAutomationAsync`, plus a synchronous invoke since Nov 2025) | Requires cross-Region profiles (`us.`, `eu.`, `apac.`, `na.`, `us-gov.data-automation-v1`; `global.` in Singapore). 2026-04-03: Data Automation Library (custom vocabulary). A dedicated Region page was not retrievable — Region list **UNVERIFIED** beyond the cross-Region profile page | ✅ `aws_bedrockdataautomation_project`, `_blueprint`, `_library` | ✅ `AWS::Bedrock::DataAutomationProject`, `Blueprint`, `DataAutomationLibrary` | L1 | [BDA cross-Region inference](https://docs.aws.amazon.com/bedrock/latest/userguide/bda-cris.html), [BDA library](https://docs.aws.amazon.com/bedrock/latest/userguide/bda-library.html) |

### A6. Added in 2026

| Feature | Status | APIs and namespace | Notes verified | Terraform | CloudFormation | Source |
|:--|:-:|:--|:--|:--|:--|:--|
| Web Search tool | GA 2026-08-04 | `web_search` tool in the Responses API, **mantle only**. IAM: `bedrock-websearch:InvokeSearch`, `InvokeFetch`, `ExternalWebAccess` | OpenAI GPT-5.4 and later only. Uses an AWS-hosted web index. Regions: us-east-1, us-east-2, us-west-2; GovCloud (US-West) since 2026-09-02 | n/a | n/a | [Web Search](https://docs.aws.amazon.com/bedrock/latest/userguide/web-search.html) |
| Projects and Workspaces | GA | Projects (OpenAI-compatible) and Workspaces (Anthropic-compatible) on mantle; `bedrock-runtime` supports only the default project | Cost and usage isolation. 2026-08-11: cost allocation by IAM principal on mantle. 2026-09-21: daily token quota became cross-model, per account | ❌ | ✅ `AWS::BedrockMantle::Project` | [Endpoints](https://docs.aws.amazon.com/bedrock/latest/userguide/endpoints.html) |
| Session management APIs | **UNVERIFIED** | — | `AWS::Bedrock::Session` exists in the CloudFormation specification; the feature itself was not researched | ❌ | ✅ `AWS::Bedrock::Session` | [CDK / CFN reference](references/cdk-and-cloudformation-bedrock.md) |

## B. Amazon Bedrock AgentCore

Namespaces: `bedrock-agentcore` (data plane), `bedrock-agentcore-control` (control plane);
Registry uses `agent-registry`. The overview names thirteen services. Platform GA: **2025-10-13**.

| Service | Status | What it is | Key APIs | Limits and isolation (as documented) | Authentication | Networking | Pricing dimensions | Source |
|:--|:-:|:--|:--|:--|:--|:--|:--|:--|
| **Runtime** | GA | Serverless host for agents and tools; any framework or model. Compute: **microVMs** or **Instances** (EC2 in your account, since Aug 2026). Platform version V2 starts agents from a snapshot | `CreateAgentRuntime`, `CreateAgentRuntimeEndpoint`; `InvokeAgentRuntime`, `StopRuntimeSession`, `GetAgentCard` | One microVM per session. Idle timeout 15 min. Max session 8 h (microVM), 14 days (Instances). Sync request 15 min. Payload 100 MB. Streaming 60 min. Default 2 vCPU / 8 GB, up to 8 vCPU / 32 GB (V2). Image 2 GB (V1) or 10 GB (V2). Zip 250 MB compressed / 750 MB uncompressed | Inbound SigV4 or OAuth 2.0 (JWT) | VPC mode; PrivateLink `com.amazonaws.<region>.bedrock-agentcore` and `…bedrock-agentcore-control`; VPC egress | Per-second CPU and memory actually used (1 s minimum, 128 MB minimum; CPU not billed during I/O wait). Instances: EC2 cost plus a management fee | [Runtime](https://docs.aws.amazon.com/bedrock-agentcore/latest/devguide/agents-tools-runtime.html), [Limits](https://docs.aws.amazon.com/bedrock-agentcore/latest/devguide/bedrock-agentcore-limits.html) |
| **Harness** | GA (Jul 2026; preview Apr 2026) | Managed agent loop: model, prompt and tools declared in one API call. Each session runs in an isolated microVM. **AWS's recommended path from Agents Classic** | `CreateHarness`, `InvokeHarness`, `UpdateHarness` | Bound by Runtime quotas | IAM auth to remote MCP servers (Nov 2026) | Same as Runtime | Not listed separately on the pricing page — **UNVERIFIED** | [What is AgentCore](https://docs.aws.amazon.com/bedrock-agentcore/latest/devguide/what-is-bedrock-agentcore.html), [Document history](https://docs.aws.amazon.com/bedrock-agentcore/latest/devguide/doc-history.html) |
| **Gateway** | GA | Turns APIs, Lambda functions and services into MCP tools; also fronts MCP servers, agents (HTTP / A2A) and model providers (inference targets) | `CreateGateway`, `CreateGatewayTarget`, `SynchronizeGatewayTargets` | 100 targets per gateway; 1,000 tools per target; 15 min invocation; 6 MB payload | Inbound: JWT, IAM SigV4, authenticate-only, or none. Outbound: execution role or Identity credential providers | PrivateLink `…bedrock-agentcore.gateway`; private CA; VPC Lattice targets | Per operation, per search query, per tool indexed | [Gateway core concepts](https://docs.aws.amazon.com/bedrock-agentcore/latest/devguide/gateway-core-concepts.html) |
| **Identity** | GA | Workload (agent) identity plus a token vault for OAuth tokens and API keys | `CreateWorkloadIdentity`, `GetWorkloadAccessToken…`, `GetResourceOauth2Token`, `GetResourceApiKey` | 11,000 workload identities; 50 OAuth2 and 50 API-key providers | 2-legged, 3-legged and on-behalf-of OAuth flows; Private Key JWT. Vault encrypted with KMS. Consent Portal (Sep 2026) | PrivateLink (data and control) | No charge when used through Runtime or Gateway; otherwise per token or key requested | [Identity overview](https://docs.aws.amazon.com/bedrock-agentcore/latest/devguide/identity-overview.html) |
| **Memory** | GA | Short-term memory (events) and long-term memory (records extracted by strategies) | `CreateMemory`; `CreateEvent`, `IngestData`, `RetrieveMemoryRecords`, `ListEvents` | 150 memories per Region; 6 strategies per memory; event expiry 7–365 days; 100 KB per message | IAM | PrivateLink | Short-term: ingestion, storage, retrieval. Long-term: per record stored, per retrieval | [Memory strategies](https://docs.aws.amazon.com/bedrock-agentcore/latest/devguide/memory-strategies.html) |
| **Code Interpreter** | GA | Sandbox for running code (Python, JavaScript, TypeScript) | `StartCodeInterpreterSession`, `InvokeCodeInterpreter` | 2 vCPU / 8 GB; 10 GB disk; timeout 900 s default, 28,800 s max | IAM | PrivateLink. Network modes **UNVERIFIED** | Per-second CPU and peak memory | [Session characteristics](https://docs.aws.amazon.com/bedrock-agentcore/latest/devguide/code-interpreter-session-characteristics.html) |
| **Browser** | GA | Managed cloud browser; works with Playwright and BrowserUse | Start / stop browser session; automation and live-view streams | 1 vCPU / 4 GB; 10 GB disk; 15 min default, 8 h max | IAM | Public network mode; PrivateLink. VPC support **UNVERIFIED** | Same as Code Interpreter; Browser Profiles stored in S3 | [Browser session management](https://docs.aws.amazon.com/bedrock-agentcore/latest/devguide/browser-resource-session-management.html) |
| **Observability** | GA | Traces, metrics and logs in Amazon CloudWatch | CloudWatch namespace `AWS/Bedrock-AgentCore` | Spans can go to the agent's own log group (Jul 2026) | — | Cross-account monitoring | CloudWatch rates | [Configure observability](https://docs.aws.amazon.com/bedrock-agentcore/latest/devguide/observability-configure.html) |
| **Evaluations** | GA 2026-03-31 | LLM-as-judge scoring: 13 built-in evaluators, custom (LLM or Lambda) and third-party | Online, on-demand and batch evaluations | 1,000 evaluation configs per Region | IAM | PrivateLink | Built-in: tokens. Custom: per evaluation | [GA announcement](https://aws.amazon.com/about-aws/whats-new/2026/03/agentcore-evaluations-generally-available) |
| **Optimization** | Recommendations, batch evaluation and A/B tests GA (Jul 2026); Insights in preview | Recommends prompt and tool-description changes and validates them | Configuration bundles, A/B tests | — | IAM | PrivateLink | See pricing page | [AgentCore pricing](https://aws.amazon.com/bedrock/agentcore/pricing/) |
| **Policy** | GA 2026-03-03 | Deterministic checks on Gateway tool calls, written in **Cedar**; natural-language authoring | Policy engine attached to a Gateway; `LOG_ONLY` or enforce | Default-deny; forbid wins | — | PrivateLink | Per authorisation request; per token for natural-language authoring | [Policy](https://docs.aws.amazon.com/bedrock-agentcore/latest/devguide/policy.html), [Core concepts](https://docs.aws.amazon.com/bedrock-agentcore/latest/devguide/policy-core-concepts.html) |
| **Registry** ("AWS Agent Registry") | GA (Aug 2026) | Governed catalog of agents, MCP servers, tools and skills, with hybrid search | `agent-registry` namespace | — | IAM or JWT | PrivateLink | Records and search/list/get calls | [Document history](https://docs.aws.amazon.com/bedrock-agentcore/latest/devguide/doc-history.html) |
| **Payments** | **Preview** (May 2026) | Agent micropayments (x402 and MPP) through wallet providers | `CreatePaymentInstrument`, `CreatePaymentSession`, `ProcessPayment` | — | Payment credential providers | — | Per wallet operation. Whether it has since gone GA is **UNVERIFIED** | [Document history](https://docs.aws.amazon.com/bedrock-agentcore/latest/devguide/doc-history.html) |
| **Web Search / Web Answer** | Web Search tool GA (Jul 2026); Web Answer GA (Nov 2026, us-east-1 only) | Web search and cited answers as a Gateway connector or direct API | `InvokeWebSearch` | 10 TPS | — | PrivateLink | Per 1,000 queries / calls | [AgentCore pricing](https://aws.amazon.com/bedrock/agentcore/pricing/) |

### B1. AgentCore — Regions

The [AgentCore Regions page](https://docs.aws.amazon.com/bedrock-agentcore/latest/devguide/agentcore-regions.html)
lists 22 Regions (21 commercial plus AWS GovCloud (US-West)).

| Available in | Services |
|:--|:--|
| All 22 | Runtime (microVMs), Gateway, Identity, built-in tools, Observability, Policy, Evaluations |
| 21 (no GovCloud) | Optimization |
| 16 | Memory, Harness |
| 15 | Runtime Instances |
| 12 | Payments |
| 10 | Registry |
| 7 / 6 / 1 | Web Search tool / Web Search API / Web Answer |

### B2. AgentCore — protocols, deployment and tooling

| Topic | Verified fact | Source |
|:--|:--|:--|
| Runtime protocols | HTTP, MCP, A2A, AG-UI, WebSocket. Default container ports: HTTP 8080, MCP 8000, A2A 9000 | [Runtime service contract](https://docs.aws.amazon.com/bedrock-agentcore/latest/devguide/runtime-service-contract.html) |
| Container deployment | Image in Amazon ECR, must be **ARM64**, listening on `0.0.0.0` | [Runtime service contract](https://docs.aws.amazon.com/bedrock-agentcore/latest/devguide/runtime-service-contract.html) |
| Direct code deployment | `.zip` — Python, and Node.js since Apr 2026 | [Code deploy](https://docs.aws.amazon.com/bedrock-agentcore/latest/devguide/runtime-get-started-code-deploy.html) |
| Frameworks documented | Strands Agents, LangGraph, CrewAI, LlamaIndex, Google ADK, OpenAI Agents SDK | [Supported frameworks](https://docs.aws.amazon.com/bedrock-agentcore/latest/devguide/supported-frameworks.html) |
| SDK and CLI | AgentCore Python SDK (`bedrock-agentcore`, `BedrockAgentCoreApp`); a TypeScript SDK; **AgentCore CLI** `@aws/agentcore` (v1.0 in Oct 2026, includes `agentcore migrate`). The earlier starter toolkit is marked deprecated in its repository | [Develop agents](https://docs.aws.amazon.com/bedrock-agentcore/latest/devguide/develop-agents.html) |
| Gateway target categories | **MCP targets** (Lambda, API Gateway REST stages, OpenAPI 3.0/3.1, Smithy, MCP servers, integration templates, connectors such as Managed Knowledge Base, Web Search, Step Functions); **HTTP targets** (Runtime agents, A2A, external MCP servers); **inference targets** (model providers) | [Gateway core concepts](https://docs.aws.amazon.com/bedrock-agentcore/latest/devguide/gateway-core-concepts.html) |
| Semantic tool search | Built-in tool `x_amz_bedrock_agentcore_search`, enabled at gateway creation | [Semantic search](https://docs.aws.amazon.com/bedrock-agentcore/latest/devguide/gateway-using-mcp-semantic-search.html) |
| Memory strategies | Built-in: `SemanticMemoryStrategy`, `SummaryMemoryStrategy`, `UserPreferenceMemoryStrategy`, `EpisodicStrategy`; plus built-in overrides and self-managed | [Built-in strategies](https://docs.aws.amazon.com/bedrock-agentcore/latest/devguide/long-term-configuring-built-in-strategies.html) |
| Knowledge bases from agents | No direct Memory–Knowledge Base integration was found. Knowledge bases reach agents through a **Gateway connector** for Managed Knowledge Base (exposes `AgenticRetrieveStream` and `Retrieve` as tools) | [Gateway core concepts](https://docs.aws.amazon.com/bedrock-agentcore/latest/devguide/gateway-core-concepts.html) |

### B3. AgentCore — IaC support

| AgentCore resource | Terraform 6.73.0 | CloudFormation | CDK 2.277.0 |
|:--|:--|:--|:--|
| Runtime | ✅ `aws_bedrockagentcore_agent_runtime` | ✅ `AWS::BedrockAgentCore::Runtime` | L1 · stable L2 `Runtime` |
| Runtime endpoint | ✅ `aws_bedrockagentcore_agent_runtime_endpoint` | ✅ `RuntimeEndpoint` | L1 · stable L2 `RuntimeEndpoint` |
| Harness | ✅ `aws_bedrockagentcore_harness` | ✅ `Harness`, `HarnessEndpoint` | L1 only |
| Gateway | ✅ `aws_bedrockagentcore_gateway` | ✅ `Gateway` | L1 · stable L2 `Gateway` |
| Gateway target | ✅ `aws_bedrockagentcore_gateway_target` | ✅ `GatewayTarget` | L1 · stable L2 `GatewayTarget` |
| Gateway rule / rate limit | ✅ `aws_bedrockagentcore_gateway_rule` | ✅ `GatewayRule`, `GatewayRateLimit` | L1 only |
| Memory | ✅ `aws_bedrockagentcore_memory`, `aws_bedrockagentcore_memory_strategy` | ✅ `Memory` | L1 · stable L2 `Memory` |
| Workload identity | ✅ `aws_bedrockagentcore_workload_identity` | ✅ `WorkloadIdentity` | L1 · stable L2 `WorkloadIdentity` |
| Credential providers | ✅ `aws_bedrockagentcore_api_key_credential_provider`, `aws_bedrockagentcore_oauth2_credential_provider` | ✅ `ApiKeyCredentialProvider`, `OAuth2CredentialProvider` | L1 · stable L2 for both |
| Token vault KMS key | ✅ `aws_bedrockagentcore_token_vault_cmk` | ❌ | ❌ |
| Browser | ✅ `aws_bedrockagentcore_browser`, `aws_bedrockagentcore_browser_profile` | ✅ `BrowserCustom`, `BrowserProfile` | L1 · stable L2 `BrowserCustom` |
| Code Interpreter | ✅ `aws_bedrockagentcore_code_interpreter` | ✅ `CodeInterpreterCustom` | L1 · stable L2 `CodeInterpreterCustom` |
| Policy | ✅ `aws_bedrockagentcore_policy`, `aws_bedrockagentcore_policy_engine` | ✅ `Policy`, `PolicyEngine` | L1 · stable L2 for both |
| Evaluations | ✅ `aws_bedrockagentcore_evaluator`, `aws_bedrockagentcore_online_evaluation_config` | ✅ `Evaluator`, `OnlineEvaluationConfig`, `Dataset` | L1 · stable L2 `Evaluator`, `OnlineEvaluationConfig` |
| Optimization | ❌ | ✅ `ConfigurationBundle` | L1 only |
| Registry | ✅ `aws_bedrockagentcore_registry` | ❌ | ❌ |
| Resource policy | ✅ `aws_bedrockagentcore_resource_policy` | ✅ `ResourcePolicy` | L1 only |
| Payments | ❌ | ✅ `PaymentManager`, `PaymentConnector`, `PaymentCredentialProvider` | L1 only |
| Consent portal, capacity provider | ❌ | ✅ `ConsentPortal`, `CapacityProvider` | L1 only |

## C. Infrastructure-as-code tooling

| Topic | Verified fact | Source |
|:--|:--|:--|
| Terraform S3 backend locking | Native locking with `use_lockfile = true` (writes a `.tflock` object) appeared in 1.10 and is GA in 1.11. `dynamodb_table` is deprecated and "will be removed in a future minor version" — the removal version is **UNVERIFIED** | [S3 backend](https://developer.hashicorp.com/terraform/language/backend/s3) |
| Terraform language features | `moved` 1.1 · `import` blocks 1.5 · `check` blocks 1.5 · `terraform test` 1.6 · test mocking 1.7 · `removed` blocks 1.7 · ephemeral resources 1.10 · write-only arguments 1.11 · list resources and `terraform query` 1.14 · actions 1.14 · Terraform Policy 1.17 | [Terraform changelogs](https://raw.githubusercontent.com/hashicorp/terraform/v1.14/CHANGELOG.md) |
| Terraform Stacks | GA (Sept 2025), **HCP Terraform only**; component files are `.tfcomponent.hcl` | [Stacks](https://developer.hashicorp.com/terraform/language/stacks/update-GA) |
| Terraform licence | Business Source License from version 1.6.0. OpenTofu is the open-source fork (1.13.x current — exact latest **UNVERIFIED**) | [Terraform LICENSE](https://raw.githubusercontent.com/hashicorp/terraform/main/LICENSE) |
| AWS provider v6 | "Enhanced Region Support": a `region` argument on most resources. Upgrade to the latest 5.x first | [v6 upgrade guide](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/guides/version-6-upgrade) |
| HCP Terraform health assessments | Periodic drift detection and continuous validation; Standard or Premium | [Health assessments](https://developer.hashicorp.com/terraform/cloud-docs/workspaces/health) |
| CDK CLI versioning | Since Feb 2025 the CLI is released separately (`2.1000.0+`); rule: CLI release date ≥ library release date | [CDK CLI split](https://aws.amazon.com/blogs/opensource/aws-cdk-is-splitting-construct-library-and-cli/) |
| CDK CLI commands | `cdk drift` and `cdk import`: no preview flag. `cdk refactor`: needs `--unstable=refactor`. `cdk gc`: needs `--unstable=gc`. `cdk migrate`: experimental. `cdk deploy` has `--import-existing-resources` and `--revert-drift` | [CDK CLI README](https://raw.githubusercontent.com/aws/aws-cdk-cli/main/packages/aws-cdk/README.md) |
| CDK Bedrock constructs | AgentCore L2s are **stable** in `aws-cdk-lib/aws-bedrockagentcore` (graduated in 2.255.0). Agent, knowledge base, guardrail and prompt L2s are in the **experimental** `@aws-cdk/aws-bedrock-alpha`. The Bedrock L2s in `@cdklabs/generative-ai-cdk-constructs` are deprecated | [CDK changelog](https://raw.githubusercontent.com/aws/aws-cdk/main/CHANGELOG.v2.md) |
| CDK for Terraform | Archived 2025-12-10 | [CDKTF README](https://raw.githubusercontent.com/hashicorp/terraform-cdk/main/README.md) |
| CloudFormation Hooks | Guard hooks and Lambda hooks; stack, change-set and Cloud Control API targets; Control Tower proactive controls as hooks | [Hooks document history](https://docs.aws.amazon.com/cloudformation-cli/latest/hooks-userguide/doc-history.html) |
| CloudFormation stack refactoring | Available since 2025-02-06 | [Stack refactoring](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/stack-refactoring.html) |
| Drift-aware change sets | `--deployment-mode REVERT_DRIFT` (2025-11-18) | [Announcement](https://aws.amazon.com/about-aws/whats-new/2025/11/configuration-drift-enhanced-cloudformation-sets/) |
| CloudFormation Guard | Major version 3 | [2025 year in review](https://aws.amazon.com/blogs/devops/aws-cloudformation-2025-year-in-review/) |
| AWS SAM | CLI 1.172.x. Templates accept native CloudFormation types; there is no `AWS::Serverless::*` Bedrock type | [SAM CLI issue 9339](https://github.com/aws/aws-sam-cli/issues/9339) |
| Pulumi | `@pulumi/aws` major version 7 covers Bedrock and AgentCore; `aws-native` has a `bedrockagentcore` module | [Pulumi AWS Bedrock](https://www.pulumi.com/registry/packages/aws/api-docs/bedrock/) |
| tfsec | Folded into Trivy; last tag v1.28.14 (May 2025) | [tfsec README](https://raw.githubusercontent.com/aquasecurity/tfsec/master/README.md) |
| Trivy supply-chain incident | 2026-03-19: malicious Trivy v0.69.4 published and `trivy-action` / `setup-trivy` tags force-pushed. Guidance: pin Actions to full commit SHAs | [Advisory GHSA-69fq-xp46-6x23](https://github.com/aquasecurity/trivy/security/advisories/GHSA-69fq-xp46-6x23) |
| Tool versions seen | Trivy 0.76.x · Checkov 3.4.x · TFLint 0.66.x · Terratest 1.0.x · OPA 1.22.x · Conftest 0.71.x · Infracost 0.10.x · cdk-nag 3.0.x · cfn-lint 1.60.x · cfn-guard 3.x | Package registries, 2026-11-15 |
| GitHub Actions to AWS | OIDC with `aws-actions/configure-aws-credentials` (current major v6) is the documented approach | [Action README](https://raw.githubusercontent.com/aws-actions/configure-aws-credentials/main/README.md) |
| AWS CodePipeline | V1 and V2 pipeline types | [Pipeline types](https://docs.aws.amazon.com/codepipeline/latest/userguide/pipeline-types.html) |
| AWS CodeCommit | Closed to new customers 2024-07-25; returned to general availability 2025-11-25 | [CodeCommit history](https://docs.aws.amazon.com/codecommit/latest/userguide/history.html) |

## Open items — UNVERIFIED

These could not be confirmed on an official page on the verification date. Chapters must carry
the same label wherever they touch these points.

| # | Item | What is missing |
|--:|:--|:--|
| U1 | Continued pre-training | Not on the customization overview page; no AWS deprecation notice found |
| U2 | Managed Knowledge Base before GA | The document history dates managed knowledge bases to 2026-03-02; whether that was a preview is not stated |
| U3 | Kendra GenAI index for new knowledge bases | Whether new use is blocked now that Kendra is in maintenance mode |
| U4 | Third-party vector stores for customer-managed KBs | Whether Pinecone, Redis Enterprise Cloud and MongoDB Atlas are still supported. The Terraform provider 6.73.0 still accepts `pinecone_configuration`, `redis_enterprise_cloud_configuration` and `mongo_db_atlas_configuration` blocks, which shows the API shape exists — not that AWS still recommends or documents them |
| U5 | Flows and model evaluation changes in 2026 | Document history shows none; not otherwise confirmed |
| U6 | Cross-Region guardrail inference | Full current Region list |
| U7 | Bedrock Data Automation Regions | No dedicated Region page was retrievable |
| U8 | Advanced Prompt Optimization Regions; status of the older `OptimizePrompt` API | Exact list and status |
| U9 | AgentCore per-unit prices | The pricing page text retrieved was truncated; dimensions are verified, figures are not |
| U10 | AgentCore harness and Payments pricing; whether Payments is GA | Not found |
| U11 | Code Interpreter network modes; Browser VPC support | Not confirmed |
| U12 | Terraform version that removes DynamoDB state locking | Docs say only "a future minor version" |
| U13 | Latest OpenTofu release | Inferred from a changelog, not a release page |
| U14 | `AWS::Bedrock::Session` | Present in the CloudFormation specification; feature not researched |

## Conflicts between sources

| # | Conflict | How the academy treats it |
|--:|:--|:--|
| C1 | Managed Knowledge Base: document history says 2026-03-02, the GA announcement says 2026-06-17 | GA date is 2026-06-17; the March entry is treated as an earlier release of unknown status |
| C2 | AgentCore Policy in CDK: the changelog says it graduated to stable in 2.269.0; the alpha README still calls it alpha | The installed `aws-cdk-lib` 2.277.0 contains `Policy` and `PolicyEngine` in the stable module — we treat it as stable and tell readers to check on upgrade |
| C3 | AgentCore Runtime new-session rate: the code-deploy page gives 25/s for zip versus 1.6/s for containers; the quotas page gives 25 TPS per account | Quote the quotas page and link both |
| C4 | AgentCore Registry namespace cut-over date differs between AWS docs and third-party provider docs | Use the AWS documentation |

## Maintenance mode and deprecations to design around

| Item | Status | Design consequence |
|:--|:--|:--|
| Amazon Bedrock Agents Classic | Maintenance; closed to new customers 2026-07-30 | New agent work goes on AgentCore. Project D uses AgentCore |
| Amazon Kendra | Maintenance from 2026-07-30 | Do not design new retrieval around Kendra |
| Customer-managed KB connectors for Confluence, SharePoint, Salesforce, Web Crawler | No new connectors after 2026-09-30 | Use Managed Knowledge Base for those sources |
| DynamoDB state locking in Terraform | Deprecated | Use `use_lockfile = true` |
| tfsec | Folded into Trivy | Use Trivy or Checkov, pinned by commit SHA in CI |
| CDK for Terraform | Archived | Not covered as an option |
| `@cdklabs/generative-ai-cdk-constructs` Bedrock L2s | Deprecated | Use `@aws-cdk/aws-bedrock-alpha` or L1 |

## How to re-verify

1. Open the two document histories first — they are the fastest way to see what changed:
   [Bedrock](https://docs.aws.amazon.com/bedrock/latest/userguide/bedrock-ug-doc-history.html) and
   [AgentCore](https://docs.aws.amazon.com/bedrock-agentcore/latest/devguide/doc-history.html).
2. Re-read each row's source link and update status, dates and notes.
3. Upgrade the pinned tool versions, then regenerate the two files in [`references/`](references/README.md).
4. Update the verification date at the top of this file and in every chapter you touched.
5. Record what changed in [`CHANGELOG.md`](CHANGELOG.md).

The full method is taught in
[Keeping up with AWS changes](09-advanced-topics/15-keeping-up-with-aws-changes.md).
