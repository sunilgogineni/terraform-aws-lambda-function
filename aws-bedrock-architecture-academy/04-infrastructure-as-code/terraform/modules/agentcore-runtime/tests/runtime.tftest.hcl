# Unit tests for the runtime configuration and the execution-role policies. A mock provider is
# used, so no AWS credentials are needed and nothing is created: `terraform test` only plans.

mock_provider "aws" {
  mock_data "aws_partition" {
    defaults = {
      partition = "aws"
    }
  }

  mock_data "aws_region" {
    defaults = {
      region = "us-east-1"
    }
  }

  mock_data "aws_caller_identity" {
    defaults = {
      account_id = "111122223333"
    }
  }
}

variables {
  name               = "support_agent"
  container_uri      = "111122223333.dkr.ecr.us-east-1.amazonaws.com/agents/support-agent:1.4.0"
  subnet_ids         = ["subnet-0123456789abcdef0", "subnet-0fedcba9876543210"]
  security_group_ids = ["sg-0123456789abcdef0"]
}

run "vpc_mode_defaults" {
  command = plan

  assert {
    condition     = aws_bedrockagentcore_agent_runtime.this.network_configuration[0].network_mode == "VPC"
    error_message = "VPC is the default network mode."
  }

  assert {
    condition     = aws_bedrockagentcore_agent_runtime.this.network_configuration[0].network_mode_config[0].subnets == toset(["subnet-0123456789abcdef0", "subnet-0fedcba9876543210"])
    error_message = "VPC mode passes the subnets through."
  }

  assert {
    condition = (
      aws_bedrockagentcore_agent_runtime.this.protocol_configuration[0].server_protocol == "HTTP"
      && aws_bedrockagentcore_agent_runtime.this.platform_version == "V1"
      && length(aws_bedrockagentcore_agent_runtime.this.authorizer_configuration) == 0
    )
    error_message = "Defaults: HTTP contract, platform V1, IAM (SigV4) inbound authorization."
  }

  assert {
    condition     = output.ecr_repository_arn == "arn:aws:ecr:us-east-1:111122223333:repository/agents/support-agent"
    error_message = "The repository ARN is derived from the image URI, without the tag."
  }

  assert {
    condition     = jsondecode(output.execution_policy_json).Statement[0].Resource == ["arn:aws:ecr:us-east-1:111122223333:repository/agents/support-agent"]
    error_message = "Image pull is limited to that one repository."
  }

  assert {
    condition     = length([for s in jsondecode(output.execution_policy_json).Statement : s if s.Sid == "BedrockModelInvocation"]) == 0
    error_message = "Without model_arns the role gets no model access."
  }

  assert {
    condition     = !contains(one([for s in jsondecode(output.execution_policy_json).Statement : s.Action if s.Sid == "GetAgentAccessToken"]), "bedrock-agentcore:GetWorkloadAccessTokenForUserId")
    error_message = "GetWorkloadAccessTokenForUserId is off by default."
  }

  assert {
    condition     = aws_bedrockagentcore_agent_runtime_endpoint.this.name == "live"
    error_message = "The module creates an endpoint named live by default."
  }
}

run "trust_policy_and_scoped_resources" {
  command = plan

  assert {
    condition = (
      jsondecode(output.trust_policy_json).Statement[0].Principal.Service == "bedrock-agentcore.amazonaws.com"
      && jsondecode(output.trust_policy_json).Statement[0].Condition.StringEquals["aws:SourceAccount"] == "111122223333"
      && jsondecode(output.trust_policy_json).Statement[0].Condition.ArnLike["aws:SourceArn"] == "arn:aws:bedrock-agentcore:us-east-1:111122223333:*"
    )
    error_message = "The trust policy must carry the documented aws:SourceAccount and aws:SourceArn conditions."
  }

  assert {
    condition = (
      one([for s in jsondecode(output.execution_policy_json).Statement : s.Resource if s.Sid == "RuntimeLogStreams"])
      == ["arn:aws:logs:us-east-1:111122223333:log-group:/aws/bedrock-agentcore/runtimes/support_agent-*:log-stream:*"]
    )
    error_message = "Log writes are limited to this runtime's log groups."
  }

  assert {
    condition = contains(
      one([for s in jsondecode(output.execution_policy_json).Statement : s.Resource if s.Sid == "GetAgentAccessToken"]),
      "arn:aws:bedrock-agentcore:us-east-1:111122223333:workload-identity-directory/default/workload-identity/support_agent-*"
    )
    error_message = "Workload access tokens are limited to this runtime's workload identity."
  }

  assert {
    condition     = one([for s in jsondecode(output.execution_policy_json).Statement : s.Condition.StringEquals["cloudwatch:namespace"] if s.Sid == "AgentCoreMetrics"]) == "bedrock-agentcore"
    error_message = "Metrics are limited to the bedrock-agentcore namespace."
  }
}

run "public_mode_with_models_and_user_id_tokens" {
  command = plan

  variables {
    network_mode                     = "PUBLIC"
    subnet_ids                       = []
    security_group_ids               = []
    server_protocol                  = "MCP"
    allow_workload_token_for_user_id = true
    model_arns = [
      "arn:aws:bedrock:us-east-1:111122223333:inference-profile/us.example.model-a-v1:0",
      "arn:aws:bedrock:us-east-1::foundation-model/example.model-a-v1:0",
      "arn:aws:bedrock:us-west-2::foundation-model/example.model-a-v1:0",
    ]
  }

  assert {
    condition     = length(aws_bedrockagentcore_agent_runtime.this.network_configuration[0].network_mode_config) == 0
    error_message = "PUBLIC mode has no network_mode_config block."
  }

  assert {
    condition     = one([for s in jsondecode(output.execution_policy_json).Statement : length(s.Resource) if s.Sid == "BedrockModelInvocation"]) == 3
    error_message = "Model invocation is granted on exactly the listed ARNs."
  }

  assert {
    condition     = contains(one([for s in jsondecode(output.execution_policy_json).Statement : s.Action if s.Sid == "GetAgentAccessToken"]), "bedrock-agentcore:GetWorkloadAccessTokenForUserId")
    error_message = "The flag adds GetWorkloadAccessTokenForUserId."
  }
}

run "jwt_authorizer_and_digest_image" {
  command = plan

  variables {
    container_uri = "111122223333.dkr.ecr.us-east-1.amazonaws.com/support-agent@sha256:0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef"
    jwt_authorizer = {
      discovery_url   = "https://idp.example.com/.well-known/openid-configuration"
      allowed_clients = ["example-client"]
    }
    endpoint_runtime_version = "3"
  }

  assert {
    condition     = aws_bedrockagentcore_agent_runtime.this.authorizer_configuration[0].custom_jwt_authorizer[0].discovery_url == "https://idp.example.com/.well-known/openid-configuration"
    error_message = "The JWT authorizer is configured from jwt_authorizer."
  }

  assert {
    condition     = aws_bedrockagentcore_agent_runtime.this.authorizer_configuration[0].custom_jwt_authorizer[0].allowed_audience == null
    error_message = "An empty audience list is left unset."
  }

  assert {
    condition     = output.ecr_repository_arn == "arn:aws:ecr:us-east-1:111122223333:repository/support-agent"
    error_message = "A digest reference is stripped from the repository ARN."
  }

  assert {
    condition     = aws_bedrockagentcore_agent_runtime_endpoint.this.agent_runtime_version == "3"
    error_message = "A pinned endpoint version is used as given."
  }
}

run "rejects_image_without_tag_or_digest" {
  command = plan

  variables {
    container_uri = "111122223333.dkr.ecr.us-east-1.amazonaws.com/support-agent"
  }

  expect_failures = [var.container_uri]
}

run "rejects_vpc_mode_without_subnets" {
  command = plan

  variables {
    subnet_ids = []
  }

  expect_failures = [aws_bedrockagentcore_agent_runtime.this]
}

run "rejects_wildcard_model_arn" {
  command = plan

  variables {
    model_arns = ["arn:aws:bedrock:*::foundation-model/*"]
  }

  expect_failures = [var.model_arns]
}

run "rejects_hyphenated_name_and_default_endpoint" {
  command = plan

  variables {
    name          = "support-agent"
    endpoint_name = "DEFAULT"
  }

  expect_failures = [var.name, var.endpoint_name]
}
