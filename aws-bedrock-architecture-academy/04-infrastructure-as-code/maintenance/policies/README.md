# Policy as code: no unscoped Bedrock inference

> **Code status:** Rego — `opa check --strict` ✅ · `conftest verify` ✅ 13 unit tests · `conftest test` run on three hand-built plan-shaped inputs · Guard — `cfn-guard test` ✅ 7 cases · `cfn-guard validate` on two templates that pass `cfn-lint` · **never run against a real Terraform plan, never deployed**

One rule, written twice: an IAM `Allow` statement must not grant `bedrock:InvokeModel` or
`bedrock:InvokeModelWithResponseStream` on `Resource: "*"` (or through `NotResource`). The Rego
version gates Terraform plans; the Guard version gates CloudFormation templates, including the
ones the AWS CDK synthesizes. The reasoning is in
[Secrets management and policy as code](../04-secrets-and-policy-as-code.md).

[IaC maintenance](../README.md) · [Environments example](../environments/README.md) · [Module `bedrock-invocation-role`](../../terraform/modules/bedrock-invocation-role/README.md)

## Layout

```text
policies/
├── policy/
│   ├── bedrock_invoke.rego        deny / warn rules for `terraform show -json` output (package main)
│   └── bedrock_invoke_test.rego   13 Rego unit tests
├── inputs/
│   ├── plan-compliant.json        shaped like the environments example's prod plan → passes
│   ├── plan-wildcard.json         three violations plus a Deny "*" and a delete that must not fail → fails
│   └── plan-review.json           a wildcard inside an ARN and an unknown policy → warnings only
└── guard/
    ├── bedrock_invoke.guard       the same rule for CloudFormation (two rules)
    ├── tests.yaml                 7 Guard unit tests
    ├── compliant.yaml             passes
    └── wildcard.yaml              fails both rules
```

## What exactly was tested

A real `terraform show -json` file needs a saved plan, and a plan needs AWS credentials, which
this repository never uses. The three files in `inputs/` are therefore **hand-built**. They follow
the documented [JSON output format](https://developer.hashicorp.com/terraform/internals/json-format)
for the parts the policy reads — `resource_changes[].address`, `.mode`, `.type`,
`.change.actions`, `.change.after.policy` (a JSON **string**, as Terraform renders it) and
`.change.after_unknown` — and render the policy strings the way `jsonencode` does. They omit the
sections the policy does not read (`planned_values`, `configuration`, `prior_state`).

| Command | Result on 2026-11-15 |
|:--|:--|
| `conftest verify --policy policy` | 13 tests, 13 passed |
| `opa test policy` · `opa check --strict policy` | 13/13 pass · no errors |
| `conftest test --policy policy inputs/plan-compliant.json` | 3 passed, 0 failures — exit code 0 |
| `conftest test --policy policy inputs/plan-wildcard.json` | 3 failures (an `aws_iam_policy` with `bedrock:*`, an updated `aws_iam_role_policy`, an `aws_iam_role` inline policy using `NotAction`) — exit code 1 |
| `conftest test --policy policy inputs/plan-review.json` | 2 warnings, 0 failures — exit code 0 |
| `cfn-guard test -r guard/bedrock_invoke.guard -t guard/tests.yaml` | 7 test cases pass |
| `cfn-guard validate -r guard/bedrock_invoke.guard -d guard/compliant.yaml` | PASS — exit code 0 |
| `cfn-guard validate -r guard/bedrock_invoke.guard -d guard/wildcard.yaml` | FAIL on both rules — exit code 19 |
| `cfn-lint guard/compliant.yaml guard/wildcard.yaml` | no findings |

Tool versions: Conftest built from source (embedding OPA 1.21.1), OPA 1.22.4, cfn-guard 3.2.1,
cfn-lint 1.60.1.

## Run it

```bash
cd 04-infrastructure-as-code/maintenance/policies
conftest verify --policy policy
conftest test --policy policy inputs/plan-wildcard.json     # expect 3 failures

# Against a real plan, in your own sandbox account with credentials:
terraform -chdir=../environments plan -var-file=env/dev/terraform.tfvars -out=dev.tfplan
terraform -chdir=../environments show -json dev.tfplan > dev.tfplan.json
conftest test --policy policy dev.tfplan.json

# CloudFormation or CDK:
cfn-guard test -r guard/bedrock_invoke.guard -t guard/tests.yaml
cfn-guard validate -r guard/bedrock_invoke.guard -d path/to/template.json
```

> [!CAUTION]
> **Cost or security hazard** — A saved plan and its JSON rendering contain every value Terraform
> knows, including sensitive ones. Treat `*.tfplan` and `*.tfplan.json` as secrets: keep them in
> the pipeline's workspace, never commit them (the academy's `.gitignore` excludes `*.tfplan`).

## Design notes

- **Deny statements are ignored on purpose.** The module's guardrail enforcement is a `Deny` on
  `Resource: "*"`; a naive "no `*` anywhere" rule would reject the safest policy in the repository.
- **IAM wildcards are matched, not string-compared.** `bedrock:*`, `bedrock:Invoke*`, `*` and
  mixed-case names such as `Bedrock:invokeModel` all match, using `glob.match`.
- **`NotAction` and `NotResource` count.** `Allow` + `NotAction: ["iam:*"]` + `Resource: "*"` grants
  Bedrock inference on everything, so it fails.
- **Deletes are not gated; replacements are.** A plan that removes a bad policy must not be blocked.
- **Unknown values warn.** If the policy document is computed during apply, the plan has no value
  to check; the rule says so instead of passing silently.
- **Guard compares only string resources.** CDK templates use `Fn::Sub` and `Fn::Join` objects in
  `Resource`; comparing those with `"*"` made Guard report a false failure until the rule was
  restricted to strings (`when this is_string`).

## Limitations

- Only resources Terraform creates or updates in this plan are checked. Policies attached outside
  Terraform, AWS managed policies and service control policies are out of scope.
- `data "aws_iam_policy_document"` blocks are not read directly; the rule checks the rendered
  `policy` string on the resource that uses them.
- The Guard rule's action pattern is a regular expression that covers common wildcards only
  (documented at the top of the file).
- Checkov 3.4.5 produced no findings on these hand-built inputs; its plan scanner reads parts of
  the plan JSON these files omit. On HCL source, its built-in check `CKV_AWS_355` flagged the same
  wildcard policies in an offline run.
