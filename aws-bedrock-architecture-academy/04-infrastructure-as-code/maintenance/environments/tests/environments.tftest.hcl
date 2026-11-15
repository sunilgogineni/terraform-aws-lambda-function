# One root configuration, four environments. Each run below mirrors the values in
# env/<environment>/terraform.tfvars.example and checks what that environment
# would get. A mock provider is used: no AWS credentials, no backend, nothing created.
# Run with: terraform init -backend=false && terraform test

mock_provider "aws" {
  mock_data "aws_partition" {
    defaults = {
      partition = "aws"
    }
  }
}

# Shared by every environment: promotion moves the same model choice forward.
variables {
  region                = "us-east-1"
  foundation_model_ids  = ["amazon.nova-2-lite-v1:0"]
  inference_profile_ids = ["us.amazon.nova-2-lite-v1:0"]
  model_regions         = ["us-east-1", "us-east-2", "us-west-2"]
}

run "dev" {
  command = plan

  variables {
    environment         = "dev"
    account_id          = "111122223333"
    deployment_role_arn = "arn:aws:iam::111122223333:role/example-terraform-deploy-dev"
    guardrail_arn       = "arn:aws:bedrock:us-east-1:111122223333:guardrail/replaceguardrailid"
    guardrail_version   = "DRAFT"
    require_guardrail   = false
    max_output_tokens   = 512
  }

  assert {
    condition     = output.role_name == "chat-dev-invoke"
    error_message = "dev must produce the role name chat-dev-invoke."
  }

  assert {
    condition     = output.runtime_config_parameter_name == "/chat/dev/runtime-config"
    error_message = "dev runtime configuration must live under /chat/dev/."
  }

  assert {
    condition     = output.inference_profile_arns == ["arn:aws:bedrock:us-east-1:111122223333:inference-profile/us.amazon.nova-2-lite-v1:0"]
    error_message = "The inference profile ARN must be built for the dev account and home Region."
  }

  assert {
    condition     = length([for s in jsondecode(output.policy_json).Statement : s if s.Effect == "Deny"]) == 0
    error_message = "dev does not enforce the guardrail, so there must be no Deny statement."
  }

  assert {
    condition     = jsondecode(aws_ssm_parameter.runtime_config.insecure_value).guardrail_version == "DRAFT"
    error_message = "dev publishes the DRAFT guardrail version to the application."
  }
}

run "test" {
  command = plan

  variables {
    environment         = "test"
    account_id          = "444455556666"
    deployment_role_arn = "arn:aws:iam::444455556666:role/example-terraform-deploy-test"
    guardrail_arn       = "arn:aws:bedrock:us-east-1:444455556666:guardrail/replaceguardrailid"
    guardrail_version   = "DRAFT"
    require_guardrail   = true
  }

  assert {
    condition     = output.role_name == "chat-test-invoke"
    error_message = "test must produce the role name chat-test-invoke."
  }

  assert {
    condition     = length([for s in jsondecode(output.policy_json).Statement : s if s.Effect == "Deny"]) == 1
    error_message = "test enforces the guardrail with exactly one Deny statement."
  }
}

run "staging" {
  command = plan

  variables {
    environment              = "staging"
    account_id               = "777788889999"
    deployment_role_arn      = "arn:aws:iam::777788889999:role/example-terraform-deploy-staging"
    guardrail_arn            = "arn:aws:bedrock:us-east-1:777788889999:guardrail/replaceguardrailid"
    guardrail_version        = "3"
    require_guardrail        = true
    permissions_boundary_arn = "arn:aws:iam::777788889999:policy/example-workload-boundary"
  }

  assert {
    condition     = output.role_name == "chat-staging-invoke"
    error_message = "staging must produce the role name chat-staging-invoke."
  }

  assert {
    condition = (
      [for s in jsondecode(output.policy_json).Statement : s.Condition.ArnNotLike["bedrock:GuardrailIdentifier"] if s.Effect == "Deny"]
      == ["arn:aws:bedrock:us-east-1:777788889999:guardrail/replaceguardrailid:*"]
    )
    error_message = "staging must deny inference without its own guardrail."
  }

  assert {
    condition     = jsondecode(aws_ssm_parameter.runtime_config.insecure_value).guardrail_version == "3"
    error_message = "staging publishes the pinned guardrail version."
  }
}

run "prod" {
  command = plan

  variables {
    environment              = "prod"
    account_id               = "999999999999"
    deployment_role_arn      = "arn:aws:iam::999999999999:role/example-terraform-deploy-prod"
    guardrail_arn            = "arn:aws:bedrock:us-east-1:999999999999:guardrail/replaceguardrailid"
    guardrail_version        = "3"
    require_guardrail        = true
    permissions_boundary_arn = "arn:aws:iam::999999999999:policy/example-workload-boundary"
  }

  assert {
    condition     = output.role_name == "chat-prod-invoke"
    error_message = "prod must produce the role name chat-prod-invoke."
  }

  assert {
    condition     = output.runtime_config_parameter_name == "/chat/prod/runtime-config"
    error_message = "prod runtime configuration must live under /chat/prod/."
  }

  assert {
    condition     = output.inference_profile_arns == ["arn:aws:bedrock:us-east-1:999999999999:inference-profile/us.amazon.nova-2-lite-v1:0"]
    error_message = "The inference profile ARN must be built for the prod account."
  }

  assert {
    condition     = jsondecode(aws_ssm_parameter.runtime_config.insecure_value).model_id == "us.amazon.nova-2-lite-v1:0"
    error_message = "The application must be told to call the inference profile, not the bare model ID."
  }
}

run "prod_rejects_draft_guardrail" {
  command = plan

  variables {
    environment       = "prod"
    account_id        = "999999999999"
    guardrail_arn     = "arn:aws:bedrock:us-east-1:999999999999:guardrail/replaceguardrailid"
    guardrail_version = "DRAFT"
    require_guardrail = true
  }

  expect_failures = [var.guardrail_version]
}

run "prod_rejects_unenforced_guardrail" {
  command = plan

  variables {
    environment       = "prod"
    account_id        = "999999999999"
    guardrail_arn     = "arn:aws:bedrock:us-east-1:999999999999:guardrail/replaceguardrailid"
    guardrail_version = "3"
    require_guardrail = false
  }

  expect_failures = [var.require_guardrail]
}

run "staging_requires_a_guardrail" {
  command = plan

  variables {
    environment       = "staging"
    account_id        = "777788889999"
    guardrail_version = "3"
    require_guardrail = true
  }

  expect_failures = [var.guardrail_arn]
}

run "rejects_unknown_environment" {
  command = plan

  variables {
    environment = "qa"
    account_id  = "111122223333"
  }

  expect_failures = [var.environment]
}
