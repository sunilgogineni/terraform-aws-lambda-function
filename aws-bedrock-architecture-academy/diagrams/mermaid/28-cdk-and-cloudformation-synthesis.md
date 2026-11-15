# Diagram 28 — AWS CDK and CloudFormation synthesis architecture

> **Verified:** 2026-11-15 · **Type:** academy design, not an official AWS reference architecture · **Related chapters:** [Synthesis and CloudFormation templates](../../04-infrastructure-as-code/aws-cdk/03-synthesis-and-cloudformation.md) · [Bootstrap and deployment](../../04-infrastructure-as-code/aws-cdk/06-bootstrap-and-deployment.md) · [Testing CDK applications](../../04-infrastructure-as-code/aws-cdk/07-testing.md) · [CDK coverage for Amazon Bedrock](../../04-infrastructure-as-code/aws-cdk/09-cdk-for-bedrock.md) · [Change sets and drift detection](../../04-infrastructure-as-code/cloudformation/04-change-sets-and-drift.md)

This set documents what happens between a line of CDK code such as `new bedrock.CfnGuardrail(...)` and a guardrail that exists in an AWS account: synthesis into a cloud assembly, the bootstrap resources and roles in the target account, asset publishing, the change set that CloudFormation executes as the execution role, stack events, rollback and drift. It answers "which identity does what, where are the artifacts, and what happens when a resource fails?". Role and bucket names are those of the default bootstrap template (qualifier `hnb659fds`) in CDK CLI 2.1148.1.

> [!NOTE]
> **Documented fact** — By the time CloudFormation starts deploying, the CDK app has already finished running and exited; it cannot react to deployment events, and values unknown at synthesis time (such as a generated guardrail ID) appear in the app only as tokens. During deployment the identity assumes the deploy role and passes the CloudFormation execution role, and assumes the file and image publishing roles to upload assets.
> Source: [Deploy AWS CDK applications](https://docs.aws.amazon.com/cdk/v2/guide/deploy.html)

## A. Conceptual view

```mermaid
---
title: 28-A · From CDK code to AWS resources (conceptual)
---
flowchart LR
    code["CDK app<br/>TypeScript constructs"]:::client
    synth["cdk synth<br/>runs the app locally"]:::compute
    assembly[("Cloud assembly<br/>templates, manifest, assets")]:::data
    cfn["AWS CloudFormation<br/>change set, then stack"]:::edge
    res["AWS resources<br/>Bedrock guardrail, AgentCore Memory"]:::ai
    code -- "1. construct tree" --> synth
    synth -- "2. write" --> assembly
    assembly -- "3. cdk deploy: upload + change set" --> cfn
    cfn -- "4. create, update, delete" --> res
    cfn -. "5. stack events" .-> code

    classDef client  fill:#E8F1FB,stroke:#1F6FEB,color:#0B1F33
    classDef compute fill:#FDEBD0,stroke:#D97706,color:#3B2300
    classDef edge    fill:#E0F7FA,stroke:#00838F,color:#00363A
    classDef ai      fill:#E6F4EA,stroke:#1E8E3E,color:#0B2E13
    classDef data    fill:#EDE7F6,stroke:#6A1B9A,color:#2A0A3D
```

**What this shows** — The CDK is a compiler, not a deployment engine. It turns code into CloudFormation templates plus files; CloudFormation, a service in your account, does the deployment and keeps the stack's state. Everything you know about CloudFormation (change sets, rollback, drift, hooks) applies unchanged.

## B. Detailed implementation view

```mermaid
---
title: 28-B · Synthesis, bootstrap contract, asset publishing, change set and drift (detailed implementation)
---
flowchart TB
    subgraph build["Build environment · developer machine or CI · synthesis needs no AWS credentials"]
        code["CDK app code<br/>App, Stage, Stack, constructs"]:::client
        tree["Construct tree<br/>paths become logical IDs"]:::compute
        tokens["Tokens<br/>placeholders for deploy-time values"]:::compute
        prep["Prepare and validate<br/>Aspects, validation plugins"]:::security
        subgraph cdkout["Cloud assembly · cdk.out"]
            tmpl[("Stack templates<br/>*.template.json")]:::data
            manifest[("manifest.json<br/>role ARNs, bootstrap version")]:::data
            assetFiles[("*.assets.json + asset files<br/>content-hash names")]:::data
        end
        cli["CDK CLI<br/>cdk deploy, cdk drift"]:::compute
    end
    subgraph target["Target AWS account 444455556666 · us-east-1"]
        subgraph toolkit["CDKToolkit bootstrap stack"]
            ssm[("SSM parameter<br/>/cdk-bootstrap/hnb659fds/version")]:::data
            filePub["file-publishing-role"]:::security
            imgPub["image-publishing-role"]:::security
            deployRole["deploy-role<br/>change sets, iam:PassRole"]:::security
            execRole["cfn-exec-role<br/>execution policies + boundary"]:::security
            bucket[("S3 staging bucket<br/>SSE-KMS, TLS only, versioned")]:::data
            ecr[("ECR container assets<br/>immutable tags")]:::data
        end
        cfn["AWS CloudFormation<br/>change set, stack, rollback"]:::edge
        res["Stack resources<br/>guardrail, Memory, Lambda, S3"]:::ai
        events[("Stack events")]:::obs
        oob["Out-of-band change<br/>console or SDK"]:::external
    end
    code -- "1. constructors run" --> tree
    tree -- "2. attributes as tokens" --> tokens
    tree -- "3. Aspects, validation" --> prep
    prep -- "4. resolve tokens to Ref and Fn::GetAtt" --> tmpl
    prep -- "4. write" --> manifest
    prep -- "4. write" --> assetFiles
    manifest -- "5. read" --> cli
    cli -- "6. sts:AssumeRole" --> deployRole
    deployRole -- "7. ssm:GetParameter" --> ssm
    cli -- "8. sts:AssumeRole" --> filePub
    filePub -- "9. PutObject assets + template" --> bucket
    cli -- "8. sts:AssumeRole" --> imgPub
    imgPub -- "9. push image" --> ecr
    deployRole -- "10. CreateChangeSet, ExecuteChangeSet" --> cfn
    cfn -- "11. GetObject template" --> bucket
    cfn -- "12. assume" --> execRole
    execRole -- "13. service API calls" --> res
    cfn == "14. stack events" ==> events
    events -. "15. polled" .-> cli
    oob -. "drift source" .-> res
    cli -- "16. cdk drift: detect drift" --> cfn

    classDef client   fill:#E8F1FB,stroke:#1F6FEB,color:#0B1F33
    classDef edge     fill:#E0F7FA,stroke:#00838F,color:#00363A
    classDef compute  fill:#FDEBD0,stroke:#D97706,color:#3B2300
    classDef ai       fill:#E6F4EA,stroke:#1E8E3E,color:#0B2E13
    classDef data     fill:#EDE7F6,stroke:#6A1B9A,color:#2A0A3D
    classDef security fill:#FDECEA,stroke:#C62828,color:#3D0A0A
    classDef obs      fill:#FFF8E1,stroke:#B28704,color:#3D2E00
    classDef external fill:#F1F3F4,stroke:#5F6368,color:#202124,stroke-dasharray:4 3
```

**Legend** — solid arrow: request or write · dashed arrow: response, polling, or an out-of-band change · thick arrow: asynchronous event stream · cylinder: data at rest · red: IAM roles and policy checks · grey dashed: outside the IaC process · nested boxes: build environment, target account, bootstrap stack, cloud assembly.

### Component roles

| Component | Role in this architecture | Security control |
|:--|:--|:--|
| Construct tree | In-memory model of the app; each construct path determines a CloudFormation logical ID | Construct IDs are part of a library's contract ([chapter 8](../../04-infrastructure-as-code/aws-cdk/08-construct-libraries.md)) |
| Tokens | Stand-ins for values known only at deployment, rendered as `Ref` / `Fn::GetAtt` | Prevents secrets or IDs being hard-coded |
| Prepare and validate | Aspects modify or inspect the tree; validation plugins (cdk-nag 3, built-in CloudFormation validation) check templates and can stop synthesis | Policy as code before anything reaches AWS |
| Cloud assembly | Templates, `manifest.json` (per stack: deploy role ARN, execution role ARN, template URL, minimum bootstrap version) and asset manifests | Reviewable, diffable artifact; deploy the same assembly you tested |
| SSM version parameter | Read by the CLI and by the template's `BootstrapVersion` parameter; the `CheckBootstrapVersion` rule fails old environments | Contract between template and bootstrap stack |
| Publishing roles | Write assets to the staging bucket and repository | Trust policy: the account itself plus `--trust` accounts; external IDs denied |
| Deploy role | Create and execute change sets, pass the execution role, read the staging bucket | Cannot create workload resources itself |
| Execution role | The permissions CloudFormation uses for every resource operation | Execution policies from `--cloudformation-execution-policies`, optional permissions boundary |
| CloudFormation | Computes the change set, orders operations by dependency, emits events, rolls back on failure | Hooks and Guard rules can inspect change sets ([Hooks and CloudFormation Guard](../../04-infrastructure-as-code/cloudformation/05-hooks-and-guard.md)) |

### Connections

| # | From → To | Protocol / operation | Direction of data | Auth |
|--:|:--|:--|:--|:--|
| 1–4 | App code → construct tree → cloud assembly | In-process (Node.js), file writes | Code to files | None; no AWS calls without context lookups |
| 5 | Cloud assembly → CLI | File read | Manifest to CLI | Local |
| 6 | CLI → deploy role | `sts:AssumeRole` over HTTPS | Credentials to CLI | Caller's IAM identity, trusted by the role |
| 7 | Deploy role → SSM | `ssm:GetParameter` | Version to CLI | Deploy role policy (that parameter only) |
| 8–9 | CLI → publishing roles → S3 / ECR | `sts:AssumeRole`; S3 `PutObject`; ECR image push | Assets to account | Publishing roles; TLS-only bucket policy |
| 10 | Deploy role → CloudFormation | Create and execute change set with `RoleARN` = execution role | Template URL and parameters | Deploy role plus `iam:PassRole` on the execution role |
| 11 | CloudFormation → S3 | Read template | Template to CloudFormation | Service access to the staging bucket |
| 12–13 | CloudFormation → execution role → services | Service APIs over HTTPS, SigV4 | Resource configuration | Execution role trusted only by `cloudformation.amazonaws.com` |
| 14–15 | CloudFormation → events → CLI | Stack events, polled | Status to CLI | Deploy role (`AWSCloudFormationReadOnlyAccess`) |
| 16 | CLI → CloudFormation | Drift detection | Actual versus expected properties | CLI credentials for the target account |

## C. Sequence view

`cdk deploy` from a CI role in a tooling account into a workload account. The stack already exists with a guardrail; this change adds an AgentCore Memory, and the Memory fails.

```mermaid
---
title: 28-C · Cross-account cdk deploy with a failed resource and rollback (execution sequence)
---
sequenceDiagram
    autonumber
    participant CI as CI job (tooling account 111122223333)
    participant STS as AWS STS
    participant SSM as AWS Systems Manager (workload account)
    participant S3 as Amazon S3 staging bucket
    participant CFN as AWS CloudFormation
    participant BR as Amazon Bedrock control plane
    participant AC as AgentCore control plane
    CI->>CI: npm ci, jest, cdk synth (no AWS calls)
    CI->>STS: AssumeRoleWithWebIdentity (OIDC) for the CI role
    STS-->>CI: CI role credentials
    CI->>STS: AssumeRole cdk-hnb659fds-deploy-role-444455556666-us-east-1
    STS-->>CI: deploy role credentials
    CI->>SSM: GetParameter /cdk-bootstrap/hnb659fds/version
    SSM-->>CI: "33"
    CI->>STS: AssumeRole file-publishing-role
    CI->>S3: PutObject assets and template (skipped if the hash already exists)
    CI->>CFN: CreateChangeSet (RoleARN = cfn-exec-role)
    CFN-->>CI: change set: Add Memory, Add IAM role, Modify policy
    Note over CI,CFN: --require-approval broadening: a new IAM statement needs approval or --require-approval=never
    CI->>CFN: ExecuteChangeSet
    Note over CFN,AC: CloudFormation acts as cfn-exec-role for every call below
    CFN->>CFN: create Memory execution role
    CFN->>AC: CreateMemory
    alt Memory creation fails (for example AccessDenied or Region not supported)
        AC-->>CFN: error
        CFN->>CFN: UPDATE_ROLLBACK_IN_PROGRESS
        CFN->>CFN: delete resources created by this update
        CFN-->>CI: events end in UPDATE_ROLLBACK_COMPLETE
        CI-->>CI: exit code non-zero, guardrail unchanged
    else success
        AC-->>CFN: memory ARN and ID
        CFN-->>CI: UPDATE_COMPLETE, then clean-up of replaced resources
    end
    opt Later: someone edits the guardrail in the console
        CI->>CFN: cdk drift (DetectStackDrift)
        CFN->>BR: read actual configuration (only for resource types that support drift detection)
        CFN-->>CI: MODIFIED, property differences
    end
```

**Failure paths**

- **Default rollback.** CloudFormation undoes the update; resources created by the failed update are deleted and modified ones restored. The guardrail is untouched, so the application keeps working.
- **First deployment fails.** A failed *create* ends in `ROLLBACK_COMPLETE`, which cannot be updated; the stack must be deleted before the next attempt (CDK Pipelines troubleshooting).
- **`--no-rollback`.** The stack stays in a failed state with the successful resources kept; fix the code and deploy again, or run `cdk rollback`, which needs bootstrap version 23 or later.
- **Rollback itself fails** (a resource cannot be restored). `cdk rollback --orphan <LogicalId>` or `--force` skips such resources.
- **Approval required in CI.** With no terminal, a change that needs approval fails the deployment before execution.

## Variations

| Variation | What changes in the diagrams |
|:--|:--|
| **CDK Pipelines** (`aws-cdk-lib/pipelines`) | The CI job becomes CodePipeline and CodeBuild in the tooling account. A synth action produces the assembly; an *Assets* stage runs CodeBuild to publish to the target's staging bucket; per stack, a *Prepare* action (CloudFormation `CHANGE_SET_REPLACE`, as the deploy role, passing the execution role) and a *Deploy* action (execute the change set). The pipeline updates itself first (self-mutation). Cross-account needs `crossAccountKeys: true` and targets bootstrapped with `--trust`. See [the pipeline example](../../04-infrastructure-as-code/aws-cdk/examples/lib/delivery-pipeline-stack.ts) |
| **AWS SAM transform** | The template declares `Transform: AWS::Serverless-2016-10-31`. CloudFormation expands `AWS::Serverless::*` resources when it creates the change set, so the change set (step 10) contains the expanded resources rather than what you wrote. There is no SAM resource type for Bedrock; Bedrock resources use the native `AWS::Bedrock::*` types ([AWS SAM](../../04-infrastructure-as-code/aws-sam/01-aws-sam.md)) |
| **Pre-synthesized template without the CDK CLI** | Any CloudFormation tool can deploy `cdk.out/<stack>.template.json`, but you must first publish the assets listed in `<stack>.assets.json` (the `cdk-assets` tool, or `cdk publish-assets --unstable=publish-assets`). The target must still be bootstrapped: the template reads the version from SSM and its assets live in the bootstrap bucket. Steps 5–9 move to your tooling; the execution role is whatever role you pass to CloudFormation |
| **Deploy from an existing assembly** | `cdk deploy --app cdk.out` skips synthesis, so the tested assembly is exactly what is deployed |
| **Two-step change set review** | `cdk deploy --method=prepare-change-set`, review, then `--method=execute-change-set`: step 10 splits in two with a human or a hook in between |
| **`--method=direct`** | No change set: CloudFormation updates the stack directly, faster but with less progress information |
| **Custom qualifier** | Every `hnb659fds` becomes your qualifier; the app's synthesizer must use the same value |

## Practical example

The [CDK chapter examples](../../04-infrastructure-as-code/aws-cdk/examples/README.md) implement this architecture and can be synthesized offline:

- [`lib/delivery-pipeline-stack.ts`](../../04-infrastructure-as-code/aws-cdk/examples/lib/delivery-pipeline-stack.ts) — the CDK Pipelines variation, tooling account to workload account.
- [`test/delivery-pipeline.test.ts`](../../04-infrastructure-as-code/aws-cdk/examples/test/delivery-pipeline.test.ts) — asserts the deploy and execution role ARNs, the `BootstrapVersion` parameter and a custom qualifier.
- [`lib/invocation-logging-stack.ts`](../../04-infrastructure-as-code/aws-cdk/examples/lib/invocation-logging-stack.ts) — a stack with a file asset (the custom-resource handler), so step 9 publishes a zip as well as the template.

Run `npx cdk synth` there and open `cdk.out/assembly-AcademyDeliveryPipeline-Workload/manifest.json` to see the role ARNs and template URLs of step 5. [Lab 4](../../labs/lab-04-cdk-synth-and-inspect.md) walks through reading a cloud assembly.

## References

- [Deploy AWS CDK applications](https://docs.aws.amazon.com/cdk/v2/guide/deploy.html) — app lifecycle, cloud assembly, deployment permissions and roles.
- [Bootstrap your environment for use with the AWS CDK](https://docs.aws.amazon.com/cdk/v2/guide/bootstrapping-env.html) — bootstrap resources, roles and template versions.
- [Customize AWS CDK bootstrapping](https://docs.aws.amazon.com/cdk/v2/guide/bootstrapping-customizing.html) — trust, execution policies, qualifier, bootstrap contract.
- [Identifiers and the AWS CDK](https://docs.aws.amazon.com/cdk/v2/guide/identifiers.html) — paths and logical IDs.
- [CDK CLI README](https://raw.githubusercontent.com/aws/aws-cdk-cli/main/packages/aws-cdk/README.md) — `deploy` methods, approval, rollback, drift, publish-assets.
- [cdk-assets README](https://raw.githubusercontent.com/aws/aws-cdk-cli/main/packages/cdk-assets/README.md) — publishing assets from an asset manifest.
- [cdk drift](https://docs.aws.amazon.com/cdk/v2/guide/ref-cli-cmd-drift.html) — drift detection versus `cdk diff`.
- [CDK Pipelines](https://docs.aws.amazon.com/cdk/api/v2/docs/aws-cdk-lib.pipelines-readme.html) — cross-account keys, bootstrapping with `--trust`, troubleshooting `ROLLBACK_COMPLETE`.
- [Update CloudFormation stacks using change sets](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/using-cfn-updating-stacks-changesets.html) — create, review and execute change sets.
- [Choose how to handle failures when provisioning resources](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/stack-failure-options.html) — rollback and preserving provisioned resources.
- [AWS::Serverless transform](https://docs.aws.amazon.com/AWSCloudFormation/latest/TemplateReference/transform-aws-serverless.html) — transform processing during change set creation.
