# Unit tests for the endpoint and policy logic. A mock provider is used, so no AWS credentials
# are needed and nothing is created: `terraform test` only evaluates the plan.

mock_provider "aws" {
  mock_data "aws_partition" {
    defaults = {
      partition          = "aws"
      reverse_dns_prefix = "com.amazonaws"
    }
  }

  mock_data "aws_region" {
    defaults = {
      region = "us-east-1"
    }
  }

  mock_data "aws_vpc" {
    defaults = {
      enable_dns_support   = true
      enable_dns_hostnames = true
    }
  }
}

variables {
  name                       = "academy"
  vpc_id                     = "vpc-0123456789abcdef0"
  subnet_ids                 = ["subnet-0123456789abcdef0", "subnet-0fedcba9876543210"]
  allowed_security_group_ids = ["sg-0123456789abcdef0"]
}

run "defaults_create_one_runtime_endpoint" {
  command = plan

  assert {
    condition     = output.service_names == { "bedrock-runtime" = "com.amazonaws.us-east-1.bedrock-runtime" }
    error_message = "By default only the bedrock-runtime endpoint is created, with the Regional service name."
  }

  assert {
    condition     = aws_vpc_endpoint.this["bedrock-runtime"].vpc_endpoint_type == "Interface" && aws_vpc_endpoint.this["bedrock-runtime"].private_dns_enabled
    error_message = "Endpoints must be Interface endpoints with private DNS on."
  }

  assert {
    condition     = output.endpoint_policies["bedrock-runtime"] == null
    error_message = "Without invoke_resource_arns or principal_org_id no custom policy is attached."
  }

  assert {
    condition     = length(aws_vpc_security_group_ingress_rule.https_from_security_group) == 1 && length(aws_vpc_security_group_ingress_rule.https_from_cidr) == 0
    error_message = "One ingress rule per allowed security group, none for CIDRs."
  }

  assert {
    condition = (
      aws_vpc_security_group_ingress_rule.https_from_security_group["sg-0123456789abcdef0"].from_port == 443
      && aws_vpc_security_group_ingress_rule.https_from_security_group["sg-0123456789abcdef0"].to_port == 443
      && aws_vpc_security_group_ingress_rule.https_from_security_group["sg-0123456789abcdef0"].ip_protocol == "tcp"
    )
    error_message = "Ingress must be TCP 443 only."
  }
}

run "agentcore_and_agent_service_names" {
  command = plan

  variables {
    services            = ["bedrock-agent-runtime", "bedrock-agentcore", "bedrock-agentcore-control", "bedrock-agentcore.gateway"]
    allowed_cidr_blocks = ["10.0.0.0/16"]
  }

  assert {
    condition     = output.service_names["bedrock-agentcore.gateway"] == "com.amazonaws.us-east-1.bedrock-agentcore.gateway"
    error_message = "The AgentCore Gateway service name keeps its dotted suffix."
  }

  assert {
    condition     = length(aws_vpc_endpoint.this) == 4
    error_message = "One endpoint per selected service."
  }

  assert {
    condition     = aws_vpc_security_group_ingress_rule.https_from_cidr["10.0.0.0/16"].cidr_ipv4 == "10.0.0.0/16"
    error_message = "CIDR sources become one ingress rule each."
  }
}

run "invoke_policy_restricts_models_and_organization" {
  command = plan

  variables {
    services             = ["bedrock-runtime", "bedrock-agent-runtime", "bedrock-agentcore"]
    invoke_resource_arns = ["arn:aws:bedrock:us-east-1::foundation-model/example.model-a-v1:0"]
    guardrail_arns       = ["arn:aws:bedrock:us-east-1:111122223333:guardrail/abc123def456"]
    principal_org_id     = "o-a1b2c3d4e5"
  }

  assert {
    condition = (
      jsondecode(output.endpoint_policies["bedrock-runtime"]).Statement[0].Action
      == ["bedrock:InvokeModel", "bedrock:InvokeModelWithResponseStream"]
    )
    error_message = "The runtime policy allows only the two inference actions."
  }

  assert {
    condition = (
      jsondecode(output.endpoint_policies["bedrock-runtime"]).Statement[0].Resource
      == ["arn:aws:bedrock:us-east-1::foundation-model/example.model-a-v1:0"]
    )
    error_message = "Inference is limited to the listed ARNs."
  }

  assert {
    condition = alltrue([
      for s in jsondecode(output.endpoint_policies["bedrock-runtime"]).Statement :
      s.Condition.StringEquals["aws:PrincipalOrgID"] == "o-a1b2c3d4e5"
    ])
    error_message = "Every runtime statement carries the aws:PrincipalOrgID condition."
  }

  assert {
    condition     = jsondecode(output.endpoint_policies["bedrock-runtime"]).Statement[1].Action == ["bedrock:ApplyGuardrail"]
    error_message = "Listed guardrails can be applied through the endpoint."
  }

  assert {
    condition     = jsondecode(output.endpoint_policies["bedrock-agent-runtime"]).Statement[0].Action == "bedrock:*"
    error_message = "Other Bedrock endpoints get the organization-only policy with the bedrock action prefix."
  }

  assert {
    condition     = output.endpoint_policies["bedrock-agentcore"] == null
    error_message = "The AgentCore data-plane endpoint keeps the default policy so OAuth callers still work."
  }
}

run "org_policy_can_cover_oauth_capable_services" {
  command = plan

  variables {
    services                           = ["bedrock-agentcore", "bedrock-agentcore.gateway"]
    principal_org_id                   = "o-a1b2c3d4e5"
    apply_org_policy_to_oauth_services = true
  }

  assert {
    condition = (
      jsondecode(output.endpoint_policies["bedrock-agentcore.gateway"]).Statement[0].Action == "bedrock-agentcore:*"
      && jsondecode(output.endpoint_policies["bedrock-agentcore.gateway"]).Statement[0].Condition.StringEquals["aws:PrincipalOrgID"] == "o-a1b2c3d4e5"
    )
    error_message = "With the flag on, AgentCore endpoints are restricted to the organization too."
  }
}

run "rejects_unknown_service" {
  command = plan

  variables {
    services = ["bedrock-runtime", "bedrock-runtime-fips", "s3"]
  }

  expect_failures = [var.services]
}

run "rejects_wildcard_model_arn" {
  command = plan

  variables {
    invoke_resource_arns = ["arn:aws:bedrock:us-east-1::foundation-model/*"]
  }

  expect_failures = [var.invoke_resource_arns]
}

run "rejects_open_cidr" {
  command = plan

  variables {
    allowed_cidr_blocks = ["0.0.0.0/0"]
  }

  expect_failures = [var.allowed_cidr_blocks]
}

run "rejects_endpoint_nobody_can_reach" {
  command = plan

  variables {
    allowed_security_group_ids = []
  }

  expect_failures = [aws_security_group.endpoints]
}

run "rejects_invoke_policy_without_runtime_endpoint" {
  command = plan

  variables {
    services             = ["bedrock-agent-runtime"]
    invoke_resource_arns = ["arn:aws:bedrock:us-east-1::foundation-model/example.model-a-v1:0"]
  }

  expect_failures = [aws_security_group.endpoints]
}

run "rejects_private_dns_when_vpc_dns_is_off" {
  command = plan

  override_data {
    target = data.aws_vpc.this
    values = {
      enable_dns_support   = true
      enable_dns_hostnames = false
    }
  }

  expect_failures = [aws_vpc_endpoint.this]
}

run "warns_on_a_single_subnet" {
  command = plan

  variables {
    subnet_ids = ["subnet-0123456789abcdef0"]
  }

  expect_failures = [check.endpoints_span_two_availability_zones]
}
