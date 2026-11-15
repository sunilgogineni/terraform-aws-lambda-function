# Unit tests for the policy logic. A mock provider is used, so no AWS credentials
# are needed and nothing is created: `terraform test` only evaluates the plan.

mock_provider "aws" {
  mock_data "aws_partition" {
    defaults = {
      partition = "aws"
    }
  }
}

variables {
  name                 = "chat-invoke"
  trusted_services     = ["lambda.amazonaws.com"]
  foundation_model_ids = ["example.model-a-v1:0", "example.model-b-v1:0"]
  model_regions        = ["us-east-1", "us-west-2"]
}

run "direct_invocation_defaults" {
  command = plan

  assert {
    condition     = length(output.foundation_model_arns) == 4
    error_message = "Expected one ARN per Region and model (2 x 2)."
  }

  assert {
    condition     = contains(output.foundation_model_arns, "arn:aws:bedrock:us-west-2::foundation-model/example.model-b-v1:0")
    error_message = "Regional foundation-model ARN is malformed."
  }

  assert {
    condition     = contains(jsondecode(output.policy_json).Statement[0].Action, "bedrock:InvokeModelWithResponseStream")
    error_message = "Streaming should be allowed by default."
  }

  assert {
    condition     = length(jsondecode(output.policy_json).Statement) == 1
    error_message = "With defaults there must be exactly one statement."
  }

  assert {
    condition     = aws_iam_role.this.name == "chat-invoke"
    error_message = "Role name must come from var.name."
  }
}

run "streaming_can_be_disabled" {
  command = plan

  variables {
    allow_streaming = false
  }

  assert {
    condition     = jsondecode(output.policy_json).Statement[0].Action == ["bedrock:InvokeModel"]
    error_message = "Only InvokeModel should be granted when streaming is off."
  }
}

run "global_inference_adds_regionless_arns" {
  command = plan

  variables {
    allow_global_inference = true
    inference_profile_arns = ["arn:aws:bedrock:us-east-1:111122223333:inference-profile/global.example.model-a-v1:0"]
  }

  assert {
    condition     = length(output.foundation_model_arns) == 6
    error_message = "Expected 4 Regional ARNs plus 2 Region-less ARNs."
  }

  assert {
    condition     = contains(output.foundation_model_arns, "arn:aws:bedrock:::foundation-model/example.model-a-v1:0")
    error_message = "Global inference needs the Region-less foundation-model ARN."
  }

  assert {
    condition     = jsondecode(output.policy_json).Statement[0].Sid == "InvokeThroughInferenceProfiles"
    error_message = "The inference-profile statement must be present."
  }
}

run "restricting_to_profiles_adds_condition" {
  command = plan

  variables {
    inference_profile_arns         = ["arn:aws:bedrock:us-east-1:111122223333:inference-profile/us.example.model-a-v1:0"]
    restrict_to_inference_profiles = true
  }

  assert {
    condition = (
      jsondecode(output.policy_json).Statement[1].Condition.StringLike["bedrock:InferenceProfileArn"][0]
      == "arn:aws:bedrock:us-east-1:111122223333:inference-profile/us.example.model-a-v1:0"
    )
    error_message = "Model invocation must be conditioned on the inference profile ARN."
  }
}

run "required_guardrail_adds_explicit_deny" {
  command = plan

  variables {
    guardrail_arns                 = ["arn:aws:bedrock:us-east-1:111122223333:guardrail/abc123"]
    required_guardrail_arn_pattern = "arn:aws:bedrock:us-east-1:111122223333:guardrail/abc123:*"
  }

  assert {
    condition     = length([for s in jsondecode(output.policy_json).Statement : s if s.Effect == "Deny"]) == 1
    error_message = "A required guardrail must produce exactly one Deny statement."
  }

  assert {
    condition     = length([for s in jsondecode(output.policy_json).Statement : s if s.Sid == "ApplyGuardrails"]) == 1
    error_message = "The role must be allowed to apply the guardrail it is required to use."
  }
}

run "rejects_wildcard_models" {
  command = plan

  variables {
    foundation_model_ids = ["*"]
  }

  expect_failures = [var.foundation_model_ids]
}

run "rejects_role_nobody_can_assume" {
  command = plan

  variables {
    trusted_services = []
  }

  expect_failures = [aws_iam_role.this]
}
