# AWS CDK chapter examples

> **Code status:** `tsc` ✅ (TypeScript 7.0.2) · Jest ✅ 25 tests and 1 snapshot with `aws-cdk-lib/assertions` and cdk-nag 3.0.2 · `cdk synth` ✅ (CLI 2.1148.1, `aws-cdk-lib` 2.277.0) · `cfn-lint` 1.60.1: no errors · **never bootstrapped, never deployed**

One small CDK app that holds the worked examples for chapters 6 to 9. Every file is
referenced from a chapter; read the chapter first.

[AWS CDK chapters](../README.md) · [Construct library](../construct-library/README.md) · [Diagram 28](../../../diagrams/mermaid/28-cdk-and-cloudformation-synthesis.md)

| File | Chapter | What it shows |
|:--|:--|:--|
| [`lib/delivery-pipeline-stack.ts`](lib/delivery-pipeline-stack.ts) | [6 — Bootstrap and deployment](../06-bootstrap-and-deployment.md) | CDK Pipelines in a tooling account deploying a stage into a workload account |
| [`test/delivery-pipeline.test.ts`](test/delivery-pipeline.test.ts) | 6 | The bootstrap contract in the template: deploy and execution roles, the `BootstrapVersion` check, a custom qualifier |
| [`lib/no-bedrock-wildcards.ts`](lib/no-bedrock-wildcards.ts) | [7 — Testing](../07-testing.md) | An Aspect that reports wildcard Bedrock actions |
| [`test/policy-checks.test.ts`](test/policy-checks.test.ts) | 7 | Testing an Aspect with `Annotations`, cdk-nag 3 as a validation plugin, a snapshot |
| [`lib/content-guardrail.ts`](lib/content-guardrail.ts) | [8 — Construct libraries](../08-construct-libraries.md) | A reusable construct: props with defaults, validation, exposed members, a `grantApply` method |
| [`test/content-guardrail.test.ts`](test/content-guardrail.test.ts) | 7 and 8 | `Match`, `Capture`, `resourceCountIs`, validation errors, a logical-ID contract test |
| [`lib/guardrail-l1-stack.ts`](lib/guardrail-l1-stack.ts) | [9 — CDK for Bedrock](../09-cdk-for-bedrock.md) | A guardrail and a version with the L1 `CfnGuardrail` |
| [`lib/agent-memory-stack.ts`](lib/agent-memory-stack.ts) | 9 | AgentCore Memory with the stable L2 `Memory` and its `grant*` methods |
| [`lib/invocation-logging-stack.ts`](lib/invocation-logging-stack.ts) | 9 | A gap with no CloudFormation type, filled with `AwsCustomResource` |
| [`test/bedrock-stacks.test.ts`](test/bedrock-stacks.test.ts) | 9 | What each construct level puts into the template |

## Run it offline

```bash
npm ci
npx tsc                 # type-check only (noEmit)
npx jest --ci           # unit tests; no credentials needed
npx cdk synth --quiet   # writes cdk.out/; no lookups, no Docker
```

Or from the academy root: `bash scripts/validate-cdk.sh 04-infrastructure-as-code/aws-cdk/examples`.

The account IDs in `cdk.json` (`111122223333`, `444455556666`) and the connection ARN are
documentation placeholders. Replace them with your own before you try anything beyond `synth`.

> [!CAUTION]
> **Cost or security hazard** — Deploying these stacks creates resources that can incur charges
> (a CodePipeline pipeline, CodeBuild projects, a customer managed KMS key, S3 storage, and
> Bedrock and AgentCore usage — check each service's pricing page) and turns on account-wide
> model invocation logging, which stores prompts and responses. Deploy only to a sandbox account, and run `cdk destroy` afterwards; the log bucket is
> retained on purpose and must be emptied and deleted by hand.

## Limitations

- Tested by synthesizing templates in memory and with `cdk synth` only. CloudFormation, IAM,
  Amazon Bedrock and AgentCore have not evaluated them.
- `InvocationLoggingStack` relies on the AWS SDK for JavaScript v3 that is built into the Lambda
  Node.js runtime; that it contains the Bedrock control-plane client was not verified.
- The pipeline needs an AWS CodeConnections connection that you create once in the console.
