# METADATA
# title: No unscoped Amazon Bedrock inference
# description: >-
#   Denies a Terraform plan that creates or updates an IAM policy whose Allow
#   statement grants bedrock:InvokeModel or bedrock:InvokeModelWithResponseStream
#   on Resource "*" (or through NotResource). Input: `terraform show -json <planfile>`.
package main

# IAM resource types whose `policy` argument is a JSON policy document string.
policy_resource_types := {
	"aws_iam_policy",
	"aws_iam_role_policy",
	"aws_iam_user_policy",
	"aws_iam_group_policy",
}

# The actions behind Converse/InvokeModel and ConverseStream/InvokeModelWithResponseStream,
# keyed by their lower-case form because IAM action names are case-insensitive.
inference_actions := {
	"bedrock:invokemodel": "bedrock:InvokeModel",
	"bedrock:invokemodelwithresponsestream": "bedrock:InvokeModelWithResponseStream",
}

# Resource changes that will exist after apply. Deletes and no-ops are not gated.
changed_resources contains rc if {
	some rc in input.resource_changes
	rc.mode == "managed"
	some action in rc.change.actions
	action in {"create", "update"}
}

# Every policy document in the plan, as [resource address, parsed document].
documents contains [rc.address, doc] if {
	some rc in changed_resources
	rc.type in policy_resource_types
	is_string(rc.change.after.policy)
	doc := json.unmarshal(rc.change.after.policy)
}

documents contains [rc.address, doc] if {
	some rc in changed_resources
	rc.type == "aws_iam_role"
	some inline in rc.change.after.inline_policy
	is_string(inline.policy)
	doc := json.unmarshal(inline.policy)
}

statements(doc) := doc.Statement if is_array(doc.Statement)

statements(doc) := [doc.Statement] if is_object(doc.Statement)

as_list(x) := x if is_array(x)

as_list(x) := [x] if is_string(x)

# IAM action names are case-insensitive and may contain * and ? wildcards.
action_matches(patterns, action) if {
	some pattern in as_list(patterns)
	glob.match(lower(pattern), null, action)
}

granted_actions(stmt) := {name |
	some key, name in inference_actions
	action_matches(stmt.Action, key)
} if stmt.Action

# Allow + NotAction grants every action the NotAction list does not exclude.
granted_actions(stmt) := {name |
	some key, name in inference_actions
	not action_matches(stmt.NotAction, key)
} if {
	not stmt.Action
	stmt.NotAction
}

unscoped_resource(stmt) if {
	some r in as_list(stmt.Resource)
	r == "*"
}

unscoped_resource(stmt) if stmt.NotResource

statement_label(stmt, _) := sprintf("%q", [stmt.Sid]) if stmt.Sid

statement_label(stmt, i) := sprintf("#%d", [i]) if not stmt.Sid

deny contains msg if {
	some [address, doc] in documents
	some i, stmt in statements(doc)
	stmt.Effect == "Allow"
	actions := granted_actions(stmt)
	count(actions) > 0
	unscoped_resource(stmt)
	msg := sprintf(
		"%s: statement %s allows %s on every resource. Scope Amazon Bedrock inference to foundation-model, inference-profile and guardrail ARNs.",
		[address, statement_label(stmt, i), concat(", ", sort(actions))],
	)
}

# Wildcards inside a Bedrock ARN are sometimes intended (all models of one provider),
# so they are reported for review instead of failing the build.
warn contains msg if {
	some [address, doc] in documents
	some i, stmt in statements(doc)
	stmt.Effect == "Allow"
	count(granted_actions(stmt)) > 0
	some r in as_list(stmt.Resource)
	r != "*"
	contains(r, "*")
	msg := sprintf("%s: statement %s grants inference on the wildcard ARN %q. Confirm this is intended.", [address, statement_label(stmt, i), r])
}

# A policy computed from values known only after apply cannot be checked at plan time.
warn contains msg if {
	some rc in changed_resources
	rc.type in policy_resource_types
	rc.change.after_unknown.policy == true
	msg := sprintf("%s: the policy document is unknown until apply, so this check could not evaluate it.", [rc.address])
}
