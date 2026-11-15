# Conftest policy for Terraform plans that touch Amazon Bedrock permissions.
#
# Input: the JSON plan from `terraform show -json tfplan` (resource_changes, variables).
# Run:   conftest test --policy policy/terraform --namespace bedrock.plan tfplan.json
#
# Code status: tested with `conftest verify` and `conftest test` against the fixtures in
# ../fixtures (Conftest with OPA 1.21.1, Rego v1). Academy guidance, not an official AWS
# rule set. Never evaluated against a plan produced from a real AWS account.
#
# What it checks
#   deny  - an IAM policy being created or updated allows a wildcard Bedrock action
#           ("*", "bedrock:*", "bedrock:Invoke*") or a Bedrock action on Resource "*"
#   deny  - an IAM policy whose content is unknown at plan time (it cannot be checked)
#   deny  - in staging and prod, the workload's invocation policy has no explicit Deny
#           conditioned on bedrock:GuardrailIdentifier (guardrail enforcement, ADR-015)
#   warn  - any resource that the plan deletes or replaces
#
# Known limits: NotAction/NotResource are not interpreted; policies attached outside
# this plan (SCPs, permissions boundaries, other stacks) are invisible here.
package bedrock.plan

import rego.v1

policy_types := {"aws_iam_role_policy", "aws_iam_policy", "aws_iam_group_policy", "aws_iam_user_policy"}

protected_environments := {"staging", "prod"}

# The resource in the academy's environments root that carries the workload's
# inference permissions (04-infrastructure-as-code/maintenance/environments).
invocation_policy_address := "module.invocation_role.aws_iam_role_policy.invoke"

# IAM policies that this plan creates or updates.
changed_policies contains rc if {
	some rc in input.resource_changes
	rc.type in policy_types
	some action in rc.change.actions
	action in {"create", "update"}
}

as_array(x) := x if is_array(x)

as_array(x) := [x] if not is_array(x)

wildcard_action(a) if lower(a) in {"*", "bedrock:*", "bedrock:invoke*"}

bedrock_action(a) if startswith(lower(a), "bedrock:")

statements(rc) := as_array(json.unmarshal(rc.change.after.policy).Statement)

sid(stmt) := object.get(stmt, "Sid", "(no Sid)")

deny contains msg if {
	some rc in changed_policies
	some stmt in statements(rc)
	stmt.Effect == "Allow"
	some a in as_array(stmt.Action)
	wildcard_action(a)
	msg := sprintf("%s: statement %s allows the wildcard action %q; list the Bedrock actions the workload needs", [rc.address, sid(stmt), a])
}

deny contains msg if {
	some rc in changed_policies
	some stmt in statements(rc)
	stmt.Effect == "Allow"
	"*" in as_array(stmt.Resource)
	some a in as_array(stmt.Action)
	bedrock_action(a)
	msg := sprintf("%s: statement %s allows %s on Resource \"*\"; name the model, inference profile or guardrail ARNs", [rc.address, sid(stmt), a])
}

deny contains msg if {
	some rc in changed_policies
	rc.change.after_unknown.policy == true
	msg := sprintf("%s: the policy document is only known after apply, so it cannot be checked; build it from values known at plan time", [rc.address])
}

deny contains msg if {
	input.variables.environment.value in protected_environments
	some rc in changed_policies
	rc.address == invocation_policy_address
	not enforces_guardrail(rc)
	msg := sprintf("%s: %s must deny inference without the environment's guardrail (Deny with a bedrock:GuardrailIdentifier condition)", [rc.address, input.variables.environment.value])
}

enforces_guardrail(rc) if {
	some stmt in statements(rc)
	stmt.Effect == "Deny"
	some _, keys in stmt.Condition
	"bedrock:GuardrailIdentifier" in object.keys(keys)
}

warn contains msg if {
	some rc in input.resource_changes
	"delete" in rc.change.actions
	msg := sprintf("%s will be %s; confirm this is intended before approving", [rc.address, concat("/", rc.change.actions)])
}
