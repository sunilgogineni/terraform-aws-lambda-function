# Source register

> **Verification date: 2026-11-15.** Every source below was opened on that date while building
> the academy. Sources are **primary only**: AWS documentation and announcements, tool vendors'
> own documentation and repositories, and package registries.

This register lists the authoritative sources the academy is built on and what each one was
used for. Individual chapters list the exact pages they cite in their own last section;
[Appendix A](#appendix-a--every-external-link-by-section) is generated from those citations.

[Academy home](README.md) · [Feature verification matrix](FEATURE-VERIFICATION.md) · [Keeping up with AWS changes](09-advanced-topics/15-keeping-up-with-aws-changes.md)

## How sources were accessed

| Method | Used for | Trust note |
|:--|:--|:--|
| Page fetched and read | AWS documentation, What's New posts, AWS blogs, pricing pages, HashiCorp and Pulumi documentation | The page content was read on the verification date |
| Raw file read from the vendor's repository | Terraform provider resource docs, changelogs, READMEs, LICENSE files | Read from the default branch, which can be ahead of the latest release |
| Extracted from a tool binary or package | Terraform resource and argument names (`terraform providers schema -json`), CDK constructs and CloudFormation types (installed `aws-cdk-lib`) | Mechanical — the strongest evidence for what a tool version accepts |
| Package registry metadata | Latest tool versions | npm, PyPI, Go module proxy, `releases.hashicorp.com`, Maven Central |

> [!IMPORTANT]
> **Status** — Nothing in the academy was verified by deploying to AWS. The sources tell you what
> AWS and the tools document; they are not a substitute for testing in your own account.

## 1. Authority order

When two sources disagree, the academy follows this order and records the conflict in the
[verification matrix](FEATURE-VERIFICATION.md#conflicts-between-sources).

1. AWS service documentation (user guides, API references) — `docs.aws.amazon.com`
2. AWS What's New announcements and pricing pages — `aws.amazon.com`
3. AWS blogs, architecture center and solutions library — `aws.amazon.com/blogs`, `/architecture`, `/solutions`
4. Tool vendor documentation and repositories (HashiCorp, Pulumi, AWS open-source projects)
5. Tool behaviour itself (provider schema, synthesized templates)

Third-party blogs and tutorials are **not** used as sources.

## 2. Amazon Bedrock

| ID | Source | Used for |
|:--|:--|:--|
| S-BR-01 | [Amazon Bedrock User Guide — overview](https://docs.aws.amazon.com/bedrock/latest/userguide/what-is-bedrock.html) | Service overview, supported APIs, provider list, recent launches |
| S-BR-02 | [Document history](https://docs.aws.amazon.com/bedrock/latest/userguide/bedrock-ug-doc-history.html) | Timeline of every change in 2025–2026 |
| S-BR-03 | [Endpoints](https://docs.aws.amazon.com/bedrock/latest/userguide/endpoints.html) | `bedrock-runtime` vs `bedrock-mantle`, which features live where |
| S-BR-04 | [Responses API](https://docs.aws.amazon.com/bedrock/latest/userguide/inference-responses-api.html) | OpenAI-compatible API limits on `bedrock-runtime` |
| S-BR-05 | [Model access](https://docs.aws.amazon.com/bedrock/latest/userguide/model-access.html) | Default model access, Marketplace permissions |
| S-BR-06 | [Cross-Region inference](https://docs.aws.amazon.com/bedrock/latest/userguide/cross-region-inference.html) | Geo and Global inference profiles |
| S-BR-07 | [Service tiers](https://docs.aws.amazon.com/bedrock/latest/userguide/service-tiers-inference.html) | Reserved, Priority, Standard and Flex tiers |
| S-BR-08 | [Provisioned Throughput](https://docs.aws.amazon.com/bedrock/latest/userguide/prov-throughput.html) | Model units and commitment terms |
| S-BR-09 | [Prompt management](https://docs.aws.amazon.com/bedrock/latest/userguide/prompt-management.html) | Prompt resources and versions |
| S-BR-10 | [Advanced Prompt Optimization — how it works](https://docs.aws.amazon.com/bedrock/latest/userguide/advanced-prompt-optimization-how.html) | Optimization jobs and limits |
| S-BR-11 | [Prompt caching](https://docs.aws.amazon.com/bedrock/latest/userguide/prompt-caching.html) | Cache points, TTLs by model, API syntax |
| S-BR-12 | [Custom models](https://docs.aws.amazon.com/bedrock/latest/userguide/custom-models.html) | Fine-tuning, reinforcement fine-tuning, distillation |
| S-BR-13 | [Evaluation](https://docs.aws.amazon.com/bedrock/latest/userguide/evaluation.html) | Model and RAG evaluation jobs |
| S-BR-14 | [Create a knowledge base](https://docs.aws.amazon.com/bedrock/latest/userguide/knowledge-base-create.html) | Customer-managed knowledge bases and vector stores |
| S-BR-15 | [Data source connectors](https://docs.aws.amazon.com/bedrock/latest/userguide/data-source-connectors.html) | Connector availability and the 2026-09-30 change |
| S-BR-16 | [Supported models and stores for knowledge bases](https://docs.aws.amazon.com/bedrock/latest/userguide/knowledge-base-supported.html) | Vector stores, structured stores, Regions |
| S-BR-17 | [Build a managed knowledge base](https://docs.aws.amazon.com/bedrock/latest/userguide/kb-build-managed.html) | Managed Knowledge Base setup |
| S-BR-18 | [Managed knowledge base Regions](https://docs.aws.amazon.com/bedrock/latest/userguide/kb-managed-regions.html) | Region availability |
| S-BR-19 | [Managed knowledge base quotas](https://docs.aws.amazon.com/bedrock/latest/userguide/kb-managed-quotas.html) | Limits |
| S-BR-20 | [Test agentic retrieval](https://docs.aws.amazon.com/bedrock/latest/userguide/kb-test-agentic-retrieve.html) | Agentic retrieval behaviour |
| S-BR-21 | [AgenticRetrieveStream API reference](https://docs.aws.amazon.com/bedrock/latest/APIReference/API_agent-runtime_AgenticRetrieveStream.html) | Request and response shape |
| S-BR-22 | [Agents Classic maintenance mode](https://docs.aws.amazon.com/bedrock/latest/userguide/agents-classic-maintenance-mode.html) | Maintenance status and migration mapping |
| S-BR-23 | [Flows](https://docs.aws.amazon.com/bedrock/latest/userguide/flows.html) | Flows status |
| S-BR-24 | [Guardrails](https://docs.aws.amazon.com/bedrock/latest/userguide/guardrails.html) | Policy types, tiers, enforcement |
| S-BR-25 | [Bedrock Data Automation — cross-Region inference](https://docs.aws.amazon.com/bedrock/latest/userguide/bda-cris.html) | BDA profiles and Regions |
| S-BR-26 | [Bedrock Data Automation — library](https://docs.aws.amazon.com/bedrock/latest/userguide/bda-library.html) | Custom vocabulary library |
| S-BR-27 | [Amazon Bedrock Marketplace](https://docs.aws.amazon.com/bedrock/latest/userguide/amazon-bedrock-marketplace.html) | Marketplace deployment model |
| S-BR-28 | [Web Search](https://docs.aws.amazon.com/bedrock/latest/userguide/web-search.html) | Web Search tool, IAM actions, Regions |
| S-BR-29 | [Amazon Bedrock pricing](https://aws.amazon.com/bedrock/pricing/) | Pricing dimensions, provider list |

### Announcements

| ID | Source | Used for |
|:--|:--|:--|
| S-BR-50 | [Managed Knowledge Base generally available (2026-06)](https://aws.amazon.com/about-aws/whats-new/2026/06/amazon-bedrock-managed-knowledge-base/) | GA date and Regions |
| S-BR-51 | [AWS service availability changes (2026-06)](https://aws.amazon.com/about-aws/whats-new/2026/06/aws-service-availability/) | Agents Classic and Kendra maintenance mode |
| S-BR-52 | [Advanced Prompt Optimization (2026-05)](https://aws.amazon.com/about-aws/whats-new/2026/05/amazon-bedrock-advanced-prompt-optimization-migration-tool/) | Launch details |
| S-BR-53 | [One-hour prompt caching (2026-01)](https://aws.amazon.com/about-aws/whats-new/2026/01/amazon-bedrock-one-hour-duration-prompt-caching/) | 1-hour TTL |
| S-BR-54 | [Data Automation custom vocabulary (2026-04)](https://aws.amazon.com/about-aws/whats-new/2026/04/bedrock-data-automation-vocabulary/) | BDA library |
| S-BR-55 | [Web Search in AWS GovCloud (2026-09)](https://aws.amazon.com/about-aws/whats-new/2026/09/amazon-bedrock-web-aws-govcloud/) | Region expansion |

## 3. Amazon Bedrock AgentCore

| ID | Source | Used for |
|:--|:--|:--|
| S-AC-01 | [What is Amazon Bedrock AgentCore](https://docs.aws.amazon.com/bedrock-agentcore/latest/devguide/what-is-bedrock-agentcore.html) | The list of AgentCore services |
| S-AC-02 | [Document history](https://docs.aws.amazon.com/bedrock-agentcore/latest/devguide/doc-history.html) | Launch and GA dates |
| S-AC-03 | [AgentCore Runtime](https://docs.aws.amazon.com/bedrock-agentcore/latest/devguide/agents-tools-runtime.html) | Runtime model and compute types |
| S-AC-04 | [Quotas and limits](https://docs.aws.amazon.com/bedrock-agentcore/latest/devguide/bedrock-agentcore-limits.html) | Session, payload and rate limits |
| S-AC-05 | [Runtime service contract](https://docs.aws.amazon.com/bedrock-agentcore/latest/devguide/runtime-service-contract.html) | Protocols, ports, container requirements |
| S-AC-06 | [Direct code deployment](https://docs.aws.amazon.com/bedrock-agentcore/latest/devguide/runtime-get-started-code-deploy.html) | Zip deployment |
| S-AC-07 | [Gateway core concepts](https://docs.aws.amazon.com/bedrock-agentcore/latest/devguide/gateway-core-concepts.html) | Target types, authentication |
| S-AC-08 | [Gateway semantic search](https://docs.aws.amazon.com/bedrock-agentcore/latest/devguide/gateway-using-mcp-semantic-search.html) | Tool search |
| S-AC-09 | [Identity overview](https://docs.aws.amazon.com/bedrock-agentcore/latest/devguide/identity-overview.html) | Workload identity and token vault |
| S-AC-10 | [Memory strategies](https://docs.aws.amazon.com/bedrock-agentcore/latest/devguide/memory-strategies.html) | Short- and long-term memory |
| S-AC-11 | [Built-in memory strategies](https://docs.aws.amazon.com/bedrock-agentcore/latest/devguide/long-term-configuring-built-in-strategies.html) | Strategy names |
| S-AC-12 | [Code Interpreter session characteristics](https://docs.aws.amazon.com/bedrock-agentcore/latest/devguide/code-interpreter-session-characteristics.html) | Sandbox limits |
| S-AC-13 | [Browser session management](https://docs.aws.amazon.com/bedrock-agentcore/latest/devguide/browser-resource-session-management.html) | Browser limits |
| S-AC-14 | [Configure observability](https://docs.aws.amazon.com/bedrock-agentcore/latest/devguide/observability-configure.html) | Telemetry destinations |
| S-AC-15 | [Policy](https://docs.aws.amazon.com/bedrock-agentcore/latest/devguide/policy.html) and [Policy core concepts](https://docs.aws.amazon.com/bedrock-agentcore/latest/devguide/policy-core-concepts.html) | Cedar policies on Gateway |
| S-AC-16 | [Supported frameworks](https://docs.aws.amazon.com/bedrock-agentcore/latest/devguide/supported-frameworks.html) and [Develop agents](https://docs.aws.amazon.com/bedrock-agentcore/latest/devguide/develop-agents.html) | Frameworks, SDK, CLI |
| S-AC-17 | [AgentCore Regions](https://docs.aws.amazon.com/bedrock-agentcore/latest/devguide/agentcore-regions.html) | Region availability per service |
| S-AC-18 | [AgentCore pricing](https://aws.amazon.com/bedrock/agentcore/pricing/) | Pricing dimensions |
| S-AC-19 | [AgentCore Evaluations generally available (2026-03)](https://aws.amazon.com/about-aws/whats-new/2026/03/agentcore-evaluations-generally-available) | GA date |
| S-AC-20 | [CloudFormation reference — AWS::BedrockAgentCore](https://docs.aws.amazon.com/AWSCloudFormation/latest/TemplateReference/AWS_BedrockAgentCore.html) | Resource types |

## 4. Infrastructure as code

| ID | Source | Used for |
|:--|:--|:--|
| S-TF-01 | [Terraform S3 backend](https://developer.hashicorp.com/terraform/language/backend/s3) | Native state locking |
| S-TF-02 | [Terraform changelogs](https://raw.githubusercontent.com/hashicorp/terraform/v1.14/CHANGELOG.md) (per version branch) | Version each language feature arrived in |
| S-TF-03 | [Terraform Stacks](https://developer.hashicorp.com/terraform/language/stacks/update-GA) | Stacks availability |
| S-TF-04 | [Terraform LICENSE](https://raw.githubusercontent.com/hashicorp/terraform/main/LICENSE) | Licence |
| S-TF-05 | [AWS provider v6 upgrade guide](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/guides/version-6-upgrade) | Enhanced Region support |
| S-TF-06 | [HCP Terraform health assessments](https://developer.hashicorp.com/terraform/cloud-docs/workspaces/health) | Drift detection |
| S-TF-07 | [AWS provider changelog](https://raw.githubusercontent.com/hashicorp/terraform-provider-aws/main/CHANGELOG.md) | New Bedrock resources |
| S-TF-08 | AWS provider resource documentation, for example [`aws_bedrockagent_knowledge_base`](https://raw.githubusercontent.com/hashicorp/terraform-provider-aws/main/website/docs/r/bedrockagent_knowledge_base.html.markdown) | Arguments and examples |
| S-TF-09 | **Provider schema** — `hashicorp/aws` 6.73.0, extracted with `terraform providers schema -json` | [Generated Terraform reference](references/terraform-aws-provider-bedrock.md) |
| S-TF-10 | [CDK for Terraform README](https://raw.githubusercontent.com/hashicorp/terraform-cdk/main/README.md) | Archive notice |
| S-CDK-01 | [AWS CDK splits construct library and CLI](https://aws.amazon.com/blogs/opensource/aws-cdk-is-splitting-construct-library-and-cli/) | CLI versioning |
| S-CDK-02 | [CDK CLI README](https://raw.githubusercontent.com/aws/aws-cdk-cli/main/packages/aws-cdk/README.md) | Command status |
| S-CDK-03 | [aws-cdk changelog](https://raw.githubusercontent.com/aws/aws-cdk/main/CHANGELOG.v2.md) | Module graduation |
| S-CDK-04 | [CDK Toolkit Library announcement](https://aws.amazon.com/about-aws/whats-new/2025/05/aws-cdk-toolkit-library-available/) | Toolkit library |
| S-CDK-05 | **Installed library** — `aws-cdk-lib` 2.277.0 and `@aws-cdk/aws-bedrock-alpha` 2.277.0-alpha.0 | [Generated CDK / CloudFormation reference](references/cdk-and-cloudformation-bedrock.md) |
| S-CFN-01 | [CloudFormation Hooks document history](https://docs.aws.amazon.com/cloudformation-cli/latest/hooks-userguide/doc-history.html) | Hooks capabilities |
| S-CFN-02 | [Stack refactoring](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/stack-refactoring.html) | Refactoring |
| S-CFN-03 | [Drift-aware change sets](https://aws.amazon.com/about-aws/whats-new/2025/11/configuration-drift-enhanced-cloudformation-sets/) | `REVERT_DRIFT` |
| S-CFN-04 | [CloudFormation 2025 year in review](https://aws.amazon.com/blogs/devops/aws-cloudformation-2025-year-in-review/) | 2025 feature summary |
| S-CFN-05 | [CloudFormation template reference](https://docs.aws.amazon.com/AWSCloudFormation/latest/TemplateReference/aws-template-resource-type-ref.html) | Resource types |
| S-SAM-01 | [SAM CLI issue 9339](https://github.com/aws/aws-sam-cli/issues/9339) | AgentCore types in SAM validation |
| S-PUL-01 | [Pulumi AWS — Bedrock](https://www.pulumi.com/registry/packages/aws/api-docs/bedrock/) and [AWS Native — AgentCore](https://www.pulumi.com/registry/packages/aws-native/api-docs/bedrockagentcore/) | Pulumi coverage |

## 5. DevSecOps tooling

| ID | Source | Used for |
|:--|:--|:--|
| S-OPS-01 | [tfsec README](https://raw.githubusercontent.com/aquasecurity/tfsec/master/README.md) | Migration to Trivy |
| S-OPS-02 | [Trivy security advisory GHSA-69fq-xp46-6x23](https://github.com/aquasecurity/trivy/security/advisories/GHSA-69fq-xp46-6x23) | March 2026 supply-chain incident |
| S-OPS-03 | [Microsoft analysis of the Trivy compromise](https://www.microsoft.com/en-us/security/blog/2026/03/24/detecting-investigating-defending-against-trivy-supply-chain-compromise/) | Scope of the incident (secondary, corroborating) |
| S-OPS-04 | [configure-aws-credentials README](https://raw.githubusercontent.com/aws-actions/configure-aws-credentials/main/README.md) | OIDC from GitHub Actions |
| S-OPS-05 | [CodePipeline pipeline types](https://docs.aws.amazon.com/codepipeline/latest/userguide/pipeline-types.html) | V1 vs V2 |
| S-OPS-06 | [CodeCommit document history](https://docs.aws.amazon.com/codecommit/latest/userguide/history.html) | Availability changes |
| S-OPS-07 | Package registries: `releases.hashicorp.com`, `registry.npmjs.org`, `pypi.org`, `proxy.golang.org`, Maven Central | Tool versions on the verification date |

## 6. Standing sources to bookmark

These are the pages to re-open whenever you need to know whether something changed.

| Question | Page |
|:--|:--|
| What changed in Bedrock? | [Bedrock document history](https://docs.aws.amazon.com/bedrock/latest/userguide/bedrock-ug-doc-history.html) |
| What changed in AgentCore? | [AgentCore document history](https://docs.aws.amazon.com/bedrock-agentcore/latest/devguide/doc-history.html) |
| What did AWS launch this week? | [AWS What's New](https://aws.amazon.com/new/) and the [AWS News Blog](https://aws.amazon.com/blogs/aws/) |
| Is a feature in my Region? | [AWS capabilities by Region](https://builder.aws.com/build/capabilities) and each feature's Region page |
| Does Terraform support it yet? | [AWS provider changelog](https://raw.githubusercontent.com/hashicorp/terraform-provider-aws/main/CHANGELOG.md) |
| Does CloudFormation support it yet? | [CloudFormation template reference](https://docs.aws.amazon.com/AWSCloudFormation/latest/TemplateReference/aws-template-resource-type-ref.html) |
| Does the CDK have an L2 yet? | [aws-cdk changelog](https://raw.githubusercontent.com/aws/aws-cdk/main/CHANGELOG.v2.md) |
| What does it cost? | [Bedrock pricing](https://aws.amazon.com/bedrock/pricing/) and [AgentCore pricing](https://aws.amazon.com/bedrock/agentcore/pricing/) |
| Reference architectures | [AWS Architecture Center](https://aws.amazon.com/architecture/) and [AWS Solutions Library](https://aws.amazon.com/solutions/) |

<!-- SOURCE-INDEX:START — generated by scripts/build-source-index.py; do not edit by hand -->
## Appendix A — every external link, by section

_Generated in the final validation phase._
<!-- SOURCE-INDEX:END -->
