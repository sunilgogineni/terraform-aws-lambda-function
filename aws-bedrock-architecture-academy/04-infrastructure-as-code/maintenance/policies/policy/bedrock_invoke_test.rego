# Unit tests for bedrock_invoke.rego. Run with: conftest verify --policy policy
package main

model_arn := "arn:aws:bedrock:us-east-1::foundation-model/amazon.nova-2-lite-v1:0"

# Builds a minimal plan with one aws_iam_role_policy whose document is `doc`.
plan_with(doc, actions) := {"resource_changes": [{
	"address": "aws_iam_role_policy.example",
	"mode": "managed",
	"type": "aws_iam_role_policy",
	"name": "example",
	"change": {
		"actions": actions,
		"before": null,
		"after": {"policy": json.marshal(doc)},
		"after_unknown": {},
	},
}]}

doc_with(stmt) := {"Version": "2012-10-17", "Statement": [stmt]}

test_scoped_model_arn_passes if {
	inp := plan_with(doc_with({"Effect": "Allow", "Action": ["bedrock:InvokeModel"], "Resource": [model_arn]}), ["create"])
	count(deny) == 0 with input as inp
	count(warn) == 0 with input as inp
}

test_invoke_model_on_star_is_denied if {
	inp := plan_with(doc_with({"Sid": "Wide", "Effect": "Allow", "Action": "bedrock:InvokeModel", "Resource": "*"}), ["create"])
	some msg in deny with input as inp
	contains(msg, `statement "Wide" allows bedrock:InvokeModel on every resource`)
}

test_service_wildcard_action_is_denied if {
	inp := plan_with(doc_with({"Effect": "Allow", "Action": "bedrock:*", "Resource": ["*"]}), ["update"])
	count(deny) == 1 with input as inp
}

test_action_names_are_case_insensitive if {
	inp := plan_with(doc_with({"Effect": "Allow", "Action": "Bedrock:invokeModel*", "Resource": "*"}), ["create"])
	some msg in deny with input as inp
	contains(msg, "bedrock:InvokeModel, bedrock:InvokeModelWithResponseStream")
}

test_deny_statement_on_star_is_allowed if {
	inp := plan_with(doc_with({"Effect": "Deny", "Action": ["bedrock:InvokeModel"], "Resource": "*"}), ["create"])
	count(deny) == 0 with input as inp
}

test_unrelated_action_on_star_is_ignored if {
	inp := plan_with(doc_with({"Effect": "Allow", "Action": "bedrock:ListFoundationModels", "Resource": "*"}), ["create"])
	count(deny) == 0 with input as inp
}

test_not_action_allow_is_denied if {
	inp := plan_with(doc_with({"Effect": "Allow", "NotAction": ["iam:*"], "Resource": "*"}), ["create"])
	count(deny) == 1 with input as inp
}

test_not_action_excluding_bedrock_passes if {
	inp := plan_with(doc_with({"Effect": "Allow", "NotAction": ["bedrock:*"], "Resource": "*"}), ["create"])
	count(deny) == 0 with input as inp
}

test_not_resource_is_denied if {
	inp := plan_with(doc_with({"Effect": "Allow", "Action": "bedrock:InvokeModel", "NotResource": model_arn}), ["create"])
	count(deny) == 1 with input as inp
}

test_deleted_policy_is_not_gated if {
	inp := plan_with(doc_with({"Effect": "Allow", "Action": "bedrock:InvokeModel", "Resource": "*"}), ["delete"])
	count(deny) == 0 with input as inp
}

test_replacement_is_gated if {
	inp := plan_with(doc_with({"Effect": "Allow", "Action": "bedrock:InvokeModel", "Resource": "*"}), ["delete", "create"])
	count(deny) == 1 with input as inp
}

test_wildcard_inside_arn_warns if {
	inp := plan_with(doc_with({"Effect": "Allow", "Action": "bedrock:InvokeModel", "Resource": "arn:aws:bedrock:*::foundation-model/*"}), ["create"])
	count(deny) == 0 with input as inp
	count(warn) == 1 with input as inp
}

test_unknown_policy_warns if {
	inp := {"resource_changes": [{
		"address": "aws_iam_policy.computed",
		"mode": "managed",
		"type": "aws_iam_policy",
		"name": "computed",
		"change": {"actions": ["create"], "before": null, "after": {}, "after_unknown": {"policy": true}},
	}]}
	count(deny) == 0 with input as inp
	some msg in warn with input as inp
	contains(msg, "unknown until apply")
}
