# Integration test for the bedrock-invocation-role module.
#
# NEEDS A SANDBOX AWS ACCOUNT. The first run block creates a real IAM role (IAM is not
# billed) and `terraform test` destroys it at the end. The other run blocks only ask the
# IAM policy simulator. Never run by the academy (ADR-003); validated with
# `terraform validate -test-directory=integration`.
#
#   terraform init -test-directory=integration
#   terraform test -test-directory=integration -var-file=sandbox.tfvars

run "create_role" {
  # command defaults to apply: real resources in the sandbox account.

  assert {
    condition     = length(output.foundation_model_arns) == length(var.foundation_model_ids) * length(var.model_regions)
    error_message = "Expected one model ARN per model and Region."
  }
}

run "granted_models_are_allowed_with_the_guardrail" {
  command = plan

  module {
    source = "./integration/simulate"
  }

  variables {
    role_arn             = run.create_role.role_arn
    action_names         = ["bedrock:InvokeModel", "bedrock:InvokeModelWithResponseStream"]
    resource_arns        = run.create_role.foundation_model_arns
    guardrail_identifier = "${run.create_role.guardrail_arn}:1"
  }

  assert {
    condition     = output.all_allowed
    error_message = "IAM did not allow the granted models with the required guardrail: ${jsonencode(output.decisions)}"
  }
}

run "calls_without_the_guardrail_are_explicitly_denied" {
  command = plan

  module {
    source = "./integration/simulate"
  }

  variables {
    role_arn      = run.create_role.role_arn
    action_names  = ["bedrock:InvokeModel"]
    resource_arns = run.create_role.foundation_model_arns
  }

  assert {
    condition     = output.decisions == toset(["explicitDeny"])
    error_message = "A call without the guardrail must hit the explicit Deny, got ${jsonencode(output.decisions)}"
  }
}

run "other_models_are_not_granted" {
  command = plan

  module {
    source = "./integration/simulate"
  }

  variables {
    role_arn             = run.create_role.role_arn
    action_names         = ["bedrock:InvokeModel"]
    resource_arns        = ["arn:aws:bedrock:${run.create_role.region}::foundation-model/not-granted.example-v1:0"]
    guardrail_identifier = "${run.create_role.guardrail_arn}:1"
  }

  assert {
    condition     = output.decisions == toset(["implicitDeny"])
    error_message = "A model that was never granted must be implicitly denied, got ${jsonencode(output.decisions)}"
  }
}

run "no_control_plane_access" {
  command = plan

  module {
    source = "./integration/simulate"
  }

  variables {
    role_arn      = run.create_role.role_arn
    action_names  = ["bedrock:CreateGuardrail", "bedrock:DeleteGuardrail", "bedrock:PutModelInvocationLoggingConfiguration"]
    resource_arns = ["*"]
  }

  assert {
    condition     = !output.all_allowed
    error_message = "The invocation role must not be able to change guardrails or logging."
  }
}
