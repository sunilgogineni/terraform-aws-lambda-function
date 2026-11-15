# Architecture decisions

> **Verified:** 2026-11-15 · These are the **academy's own decisions**. None of them is an
> official AWS recommendation unless a row under "Documented facts" says so and links the page.

Each record separates what the documentation says (facts) from what we chose to do about it
(decision). Use [`templates/adr-template.md`](templates/adr-template.md) to add one.

[Academy home](README.md) · [Feature verification matrix](FEATURE-VERIFICATION.md) · [Source register](SOURCES.md)

## Index

| ADR | Decision | Scope |
|:--|:--|:--|
| [ADR-001](#adr-001-the-academy-lives-in-one-isolated-folder) | The academy lives in one isolated folder | Repository |
| [ADR-002](#adr-002-register-first-primary-sources-only) | Register first, primary sources only | All content |
| [ADR-003](#adr-003-validate-offline-never-deploy) | Validate offline, never deploy | All code |
| [ADR-004](#adr-004-mermaid-first-with-a-restricted-syntax) | Mermaid first, with a restricted syntax | Diagrams |
| [ADR-005](#adr-005-navigation-is-generated-from-a-content-map) | Navigation is generated from a content map | Repository |
| [ADR-006](#adr-006-pin-tool-versions-and-generate-iac-references-from-the-tools) | Pin tool versions; generate IaC references from the tools | IaC |
| [ADR-007](#adr-007-converse-on-bedrock-runtime-is-the-default-inference-api-in-examples) | Converse on `bedrock-runtime` is the default in examples | Bedrock inference |
| [ADR-008](#adr-008-new-agent-work-targets-agentcore) | New agent work targets AgentCore | Agents |
| [ADR-009](#adr-009-the-rag-project-ships-two-knowledge-base-variants) | The RAG project ships two knowledge base variants | RAG |
| [ADR-010](#adr-010-model-and-inference-profile-ids-are-always-configuration) | Model and inference profile IDs are always configuration | All code |
| [ADR-011](#adr-011-terraform-state-in-s3-with-native-locking-one-state-per-environment) | Terraform state in S3 with native locking, one state per environment | Terraform |
| [ADR-012](#adr-012-cdk-in-typescript-stable-constructs-first) | CDK in TypeScript, stable constructs first | CDK |
| [ADR-013](#adr-013-one-aws-account-per-environment) | One AWS account per environment | Multi-account |
| [ADR-014](#adr-014-pipelines-use-oidc-and-pin-actions-by-commit-sha) | Pipelines use OIDC and pin Actions by commit SHA | CI/CD |
| [ADR-015](#adr-015-security-controls-are-layered-and-none-is-trusted-alone) | Security controls are layered and none is trusted alone | Security |

---

## ADR-001: The academy lives in one isolated folder

| Field | Value |
|:--|:--|
| Status | Accepted |
| Date | 2026-11-15 |
| Scope | Repository layout |

**Context.** The host repository is an unrelated Terraform module with its own CI, CODEOWNERS and
ignore rules.

**Decision.** Everything — documentation, diagrams, code, scripts, generated assets — lives under
`aws-bedrock-architecture-academy/`. No file outside it is created or changed. The folder has
its own `.gitignore`; example pipelines live under `07-devops-and-cicd/examples/`, never in the
host repository's `.github/`.

**Consequences.** The folder can be moved to its own repository unchanged. The host's CI is
unaffected. The host's `.gitignore` ignores `.terraform.lock.hcl`, so lock files are not
committed here; chapters explain that you **should** commit them in a real project.

## ADR-002: Register first, primary sources only

| Field | Value |
|:--|:--|
| Status | Accepted |
| Date | 2026-11-15 |
| Scope | All content |

**Context.** Bedrock changed substantially during 2026 — see
[what changed since older tutorials](FEATURE-VERIFICATION.md#what-changed-since-older-tutorials).
Anything written from memory or from older tutorials is likely to be wrong somewhere.

**Decision.** A [verification matrix](FEATURE-VERIFICATION.md) is built from official pages
before any chapter is written, and chapters cite from it. Only primary sources are used.
Anything not confirmed is labelled `UNVERIFIED — REQUIRES DOCUMENTATION REVIEW`. Documented
facts and academy recommendations use different callouts.

| Option | For | Against |
|:--|:--|:--|
| Write from expertise, cite later | Fast | Unverifiable; stale within months |
| **Register first (chosen)** | Every claim traceable; easy to re-verify | Slower; some gaps stay visibly open |

**Consequences.** Some sections say "unverified" instead of sounding confident. Re-verification
is a defined procedure rather than a rewrite.

## ADR-003: Validate offline, never deploy

| Field | Value |
|:--|:--|
| Status | Accepted |
| Date | 2026-11-15 |
| Scope | All infrastructure and application code |

**Context.** The academy was built with no AWS credentials, and creating billable resources was
out of scope.

**Decision.** Code is checked with tools that need no account: `terraform fmt`, `terraform
validate`, `terraform test` with mock providers, `tsc`, Jest assertions, `cdk synth`, `cfn-lint`,
Python byte-compilation and unit tests with stubbed clients. No `plan`, `apply`, `deploy` or AWS
CLI call is ever run. Every code artifact states its status.

**Consequences.** The code is proven consistent with the provider schema and CloudFormation
specification, **not** proven to deploy. Service-side validation (quotas, Region support, model
access, IAM propagation) can still fail. Each project lists this under "Limitations".

## ADR-004: Mermaid first, with a restricted syntax

| Field | Value |
|:--|:--|
| Status | Accepted |
| Date | 2026-11-15 |
| Scope | Diagrams |

**Context.** Diagrams must be versionable, reviewable in a pull request and renderable where the
Markdown is read. Markdown hosts ship their own Mermaid version, which can be older than the
newest release.

**Decision.** Mermaid is the primary format, limited to long-stable diagram types and quoted
labels ([conventions](templates/CONVENTIONS.md#5-diagrams)). Every diagram is rendered on three
Mermaid major versions by `scripts/check-mermaid.cjs`. PlantUML is used where UML notation is
clearer; draw.io XML is provided for a few flagship architectures that benefit from manual layout.

| Option | For | Against |
|:--|:--|:--|
| **Mermaid (chosen as primary)** | Text, diff-friendly, renders inline | Limited layout control |
| PlantUML | Rich UML | Needs a renderer; not inline on most hosts |
| draw.io | Polished, editable, AWS shape library | XML diffs are unreadable; no offline render here |
| Images only | Pixel control | Not maintainable; goes stale silently |

**Consequences.** No AWS icons in Mermaid diagrams; services are identified by full name and
colour class. draw.io files are structurally checked but not rendered in this environment.

## ADR-005: Navigation is generated from a content map

| Field | Value |
|:--|:--|
| Status | Accepted |
| Date | 2026-11-15 |
| Scope | Repository |

**Decision.** [`scripts/content-map.json`](scripts/content-map.json) defines the course order.
[`scripts/build-nav.py`](scripts/build-nav.py) writes chapter footers, section indexes, the
[content map](CONTENT-MAP.md), the [diagram index](diagrams/diagram-index.md) and the progress
table between marker comments. Authors never write previous/next links.

**Consequences.** Reordering or adding a chapter is a one-line change. Hand-written text outside
the markers is never touched. `build-nav.py --check` fails CI if navigation is stale.

## ADR-006: Pin tool versions and generate IaC references from the tools

| Field | Value |
|:--|:--|
| Status | Accepted |
| Date | 2026-11-15 |
| Scope | Infrastructure as code |

**Documented facts.** The Terraform AWS provider adds Bedrock resources in most releases
([changelog](https://raw.githubusercontent.com/hashicorp/terraform-provider-aws/main/CHANGELOG.md)).
AgentCore L2 constructs graduated to stable in `aws-cdk-lib` 2.255.0
([changelog](https://raw.githubusercontent.com/aws/aws-cdk/main/CHANGELOG.v2.md)).

**Decision.** The academy pins Terraform 1.17.2, `hashicorp/aws` 6.73.0 and `aws-cdk-lib`
2.277.0, and generates its resource tables from the provider schema and the installed CDK
library ([references](references/README.md)). Example code constrains the provider with
`~> 6.73` and pins `aws-cdk-lib` exactly.

**Consequences.** "Does Terraform support X?" has a mechanical answer for the pinned version.
The tables go stale on every upgrade and must be regenerated — which is one command.

## ADR-007: Converse on `bedrock-runtime` is the default inference API in examples

| Field | Value |
|:--|:--|
| Status | Accepted |
| Date | 2026-11-15 |
| Scope | Bedrock inference examples |

**Documented facts.** `bedrock-runtime` serves Converse, InvokeModel, the OpenAI Responses and
Chat Completions APIs and the Anthropic Messages API. AWS recommends `bedrock-runtime` for new
applications; `bedrock-mantle` is needed only for specific features. Guardrails and intelligent
prompt routing are available on `bedrock-runtime` only
([Endpoints](https://docs.aws.amazon.com/bedrock/latest/userguide/endpoints.html)).

**Decision.** Examples and projects use **Converse** on `bedrock-runtime` with SigV4 and IAM
roles. The compatible APIs are taught in their own chapter.

| Option | For | Against |
|:--|:--|:--|
| **Converse (chosen)** | One request shape across providers; works with guardrails, inference profiles and IAM as taught | Not the API existing OpenAI/Anthropic SDK code already uses |
| OpenAI- or Anthropic-compatible APIs | Minimal change for existing SDK code | Feature limits differ per endpoint; ties examples to one provider's shape |
| InvokeModel | Full access to provider-specific parameters | Different body per model |

**Consequences.** Readers porting existing SDK code should read the compatible-APIs chapter
first. If AWS's guidance shifts further toward the compatible APIs, revisit this.

## ADR-008: New agent work targets AgentCore

| Field | Value |
|:--|:--|
| Status | Accepted |
| Date | 2026-11-15 |
| Scope | Agent chapters, Project D |

**Documented facts.** Amazon Bedrock Agents Classic is in maintenance mode and closed to new
customers since 2026-07-30; AWS recommends AgentCore with the managed harness as the migration
path ([maintenance mode](https://docs.aws.amazon.com/bedrock/latest/userguide/agents-classic-maintenance-mode.html)).

**Decision.** Agents Classic is documented so that people maintaining existing agents can
understand them, and its Terraform and CloudFormation resources are listed. Everything new —
patterns, Project D, the agentic chapters — is built on AgentCore.

**Consequences.** A reader with a brand-new AWS account can follow the agent material; they
could not create a Classic agent. Multi-agent collaboration is taught as a pattern on AgentCore,
with the Classic feature described for context.

## ADR-009: The RAG project ships two knowledge base variants

| Field | Value |
|:--|:--|
| Status | Accepted |
| Date | 2026-11-15 |
| Scope | Project C, RAG chapters |

**Documented facts.** AWS recommends Managed Knowledge Base; agentic retrieval works only on it;
`RetrieveAndGenerate` works only on customer-managed knowledge bases. Managed Knowledge Base is
available in fewer Regions ([matrix](FEATURE-VERIFICATION.md#a4-knowledge-bases-and-retrieval)).

**Decision.** Project C contains (1) a customer-managed knowledge base on Amazon S3 Vectors —
explicit embeddings and vector store, so every moving part is visible — and (2) a Managed
Knowledge Base, which is what AWS now recommends.

| Vector store for variant 1 | For | Against |
|:--|:--|:--|
| **S3 Vectors (chosen)** | Fully creatable with the AWS provider alone; no cluster or index bootstrap | Newer service |
| OpenSearch Serverless | Mature, hybrid search | Index must be created outside the AWS provider; minimum capacity cost |
| Aurora PostgreSQL (pgvector) | Familiar SQL | Schema bootstrap needed; a database to run |

**Consequences.** Readers see both models side by side and can compare what each hides.

## ADR-010: Model and inference profile IDs are always configuration

| Field | Value |
|:--|:--|
| Status | Accepted |
| Date | 2026-11-15 |
| Scope | All code |

**Documented facts.** Models move through Active, Legacy and End-of-life states, and legacy
notices appeared several times in 2025–2026
([document history](https://docs.aws.amazon.com/bedrock/latest/userguide/bedrock-ug-doc-history.html)).

**Decision.** No model ID or inference profile ID is hard-coded in logic. They are Terraform
variables, CDK props or environment configuration, with a default that was seen in the
documentation on the verification date and a note to confirm it.

**Consequences.** Replacing a retired model is a configuration change. IAM policies that scope
to a model ARN must be updated in the same change — chapters call this out.

## ADR-011: Terraform state in S3 with native locking, one state per environment

| Field | Value |
|:--|:--|
| Status | Accepted |
| Date | 2026-11-15 |
| Scope | Terraform |

**Documented facts.** The S3 backend supports native locking with `use_lockfile = true` (GA in
Terraform 1.11); DynamoDB-based locking is deprecated
([S3 backend](https://developer.hashicorp.com/terraform/language/backend/s3)).

**Decision.** Examples use the S3 backend with `use_lockfile = true`, bucket versioning and
SSE-KMS, and **one state object per environment per component**. CLI workspaces are explained
but not used for environment separation.

**Consequences.** No DynamoDB table to manage. A mistake in one environment cannot corrupt
another's state. More backend configuration to keep in step — handled with partial backend
configuration files per environment.

## ADR-012: CDK in TypeScript, stable constructs first

| Field | Value |
|:--|:--|
| Status | Accepted |
| Date | 2026-11-15 |
| Scope | AWS CDK |

**Documented facts.** AgentCore L2 constructs are in the stable `aws-cdk-lib`; agent, knowledge
base, guardrail and prompt L2s are in the experimental `@aws-cdk/aws-bedrock-alpha`
([reference](references/cdk-and-cloudformation-bedrock.md)).

**Decision.** TypeScript throughout. Use a stable L2 when one exists, otherwise the L1
(`Cfn*`) construct. The alpha package appears only in clearly labelled examples.

**Consequences.** More verbose code where only L1 exists, but no dependency on an API that can
break in any release.

## ADR-013: One AWS account per environment

| Field | Value |
|:--|:--|
| Status | Accepted |
| Date | 2026-11-15 |
| Scope | Multi-account pattern, Project F, environment examples |

**Decision.** Development, test, staging and production are separate AWS accounts in separate
organizational units, with separate state, separate deployment roles and promotion by pipeline.
Shared services (logging, security tooling, deployment tooling) have their own accounts.

**Consequences.** Blast radius, quotas and cost are isolated per environment — Bedrock quotas
are per account and Region, so a test load cannot starve production. More accounts to govern;
AWS Organizations and Control Tower carry that.

## ADR-014: Pipelines use OIDC and pin Actions by commit SHA

| Field | Value |
|:--|:--|
| Status | Accepted |
| Date | 2026-11-15 |
| Scope | CI/CD examples |

**Documented facts.** OIDC is the recommended way to authenticate GitHub Actions to AWS
([configure-aws-credentials](https://raw.githubusercontent.com/aws-actions/configure-aws-credentials/main/README.md)).
In March 2026 the tags of `trivy-action` and `setup-trivy` were force-pushed to malicious
commits ([advisory](https://github.com/aquasecurity/trivy/security/advisories/GHSA-69fq-xp46-6x23)).

**Decision.** Example workflows hold no long-lived AWS keys, assume a role through OIDC, and
reference every third-party Action by full commit SHA with the version in a comment.

**Consequences.** Upgrading an Action is a deliberate, reviewable change. The SHAs in the
examples are placeholders that the reader must replace with ones they have verified.

## ADR-015: Security controls are layered and none is trusted alone

| Field | Value |
|:--|:--|
| Status | Accepted |
| Date | 2026-11-15 |
| Scope | Security chapters, all patterns |

**Decision.** Every reference design combines identity (least-privilege roles, scoped to model
and resource ARNs), network (private endpoints where supported), data protection (customer
managed keys, logging controls), content controls (guardrails) and deterministic authorisation
for agent tools (AgentCore Policy). A guardrail or a system prompt is never the only barrier
between untrusted input and a privileged action.

**Consequences.** More components per design. Chapters state which threat each layer addresses
and what still gets through.
