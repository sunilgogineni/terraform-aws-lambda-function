# Unit tests for bedrock_plan.rego. Run: conftest verify --policy policy/terraform
package bedrock.plan_test

import rego.v1

import data.bedrock.plan

policy_change(address, actions, doc) := {
	"address": address,
	"type": "aws_iam_role_policy",
	"change": {
		"actions": actions,
		"after": {"policy": json.marshal(doc)},
		"after_unknown": {"id": true},
	},
}

scoped_invoke := {
	"Sid": "InvokeFoundationModels",
	"Effect": "Allow",
	"Action": ["bedrock:InvokeModel"],
	"Resource": ["arn:aws:bedrock:us-east-1::foundation-model/example.model-a-v1:0"],
}

guardrail_deny := {
	"Sid": "DenyInferenceWithoutRequiredGuardrail",
	"Effect": "Deny",
	"Action": ["bedrock:InvokeModel"],
	"Resource": "*",
	"Condition": {"ArnNotLike": {"bedrock:GuardrailIdentifier": "arn:aws:bedrock:us-east-1:111122223333:guardrail/abc123:*"}},
}

plan_input(env, changes) := {"variables": {"environment": {"value": env}}, "resource_changes": changes}

test_scoped_policy_passes if {
	inp := plan_input("dev", [policy_change(plan.invocation_policy_address, ["create"], {"Statement": [scoped_invoke]})])
	count(plan.deny) == 0 with input as inp
}

test_wildcard_action_denied if {
	doc := {"Statement": {"Effect": "Allow", "Action": "bedrock:*", "Resource": ["arn:aws:bedrock:us-east-1::foundation-model/x"]}}
	inp := plan_input("dev", [policy_change("aws_iam_role_policy.debug", ["update"], doc)])
	some msg in plan.deny with input as inp
	contains(msg, "wildcard action \"bedrock:*\"")
}

test_bedrock_action_on_star_denied if {
	doc := {"Statement": [{"Effect": "Allow", "Action": ["bedrock:InvokeModel"], "Resource": "*"}]}
	inp := plan_input("dev", [policy_change("aws_iam_role_policy.app", ["create"], doc)])
	some msg in plan.deny with input as inp
	contains(msg, "on Resource \"*\"")
}

test_deny_on_star_is_allowed if {
	inp := plan_input("dev", [policy_change("aws_iam_role_policy.app", ["create"], {"Statement": [scoped_invoke, guardrail_deny]})])
	count(plan.deny) == 0 with input as inp
}

test_prod_requires_guardrail_deny if {
	inp := plan_input("prod", [policy_change(plan.invocation_policy_address, ["update"], {"Statement": [scoped_invoke]})])
	some msg in plan.deny with input as inp
	contains(msg, "must deny inference without the environment's guardrail")
}

test_prod_with_guardrail_deny_passes if {
	inp := plan_input("prod", [policy_change(plan.invocation_policy_address, ["update"], {"Statement": [scoped_invoke, guardrail_deny]})])
	count(plan.deny) == 0 with input as inp
}

test_unknown_policy_denied if {
	rc := {
		"address": "aws_iam_role_policy.late",
		"type": "aws_iam_role_policy",
		"change": {"actions": ["create"], "after": {}, "after_unknown": {"policy": true}},
	}
	some msg in plan.deny with input as plan_input("dev", [rc])
	contains(msg, "only known after apply")
}

test_deleted_policy_is_not_checked_but_warned if {
	rc := {"address": "aws_iam_role.old", "type": "aws_iam_role", "change": {"actions": ["delete"], "before": {}, "after": null}}
	inp := plan_input("prod", [rc])
	count(plan.deny) == 0 with input as inp
	some msg in plan.warn with input as inp
	contains(msg, "aws_iam_role.old will be delete")
}
