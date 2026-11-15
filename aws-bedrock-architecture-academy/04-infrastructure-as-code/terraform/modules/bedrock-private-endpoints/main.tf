# Interface VPC endpoints (AWS PrivateLink) for Amazon Bedrock and Amazon Bedrock AgentCore.
#
# Documented behaviour this module encodes:
#  * Service names are com.amazonaws.<region>.<suffix>; the suffixes below are the ones listed on
#    the Bedrock and AgentCore interface-endpoint pages (FIPS variants excluded, see README).
#  * Private DNS needs enableDnsSupport and enableDnsHostnames on the VPC.
#  * The endpoint security group must allow inbound HTTPS from the callers.
#  * Without a policy, an endpoint allows full access. An endpoint policy never grants access
#    on its own; it is one more filter next to identity-based policies. It needs a Principal
#    element and cannot exceed 20,480 characters.
#  * Endpoint policies can restrict IAM principals only: OAuth callers of AgentCore Runtime and
#    Gateway need Principal "*" with no principal-based condition.
# Sources are listed in README.md.

data "aws_partition" "current" {}

data "aws_region" "current" {}

data "aws_vpc" "this" {
  id = var.vpc_id
}

locals {
  # Allow-list of service-name suffixes -> IAM action prefix of the APIs the endpoint carries.
  service_action_prefix = {
    "bedrock"                   = "bedrock"
    "bedrock-runtime"           = "bedrock"
    "bedrock-mantle"            = "bedrock-mantle"
    "bedrock-agent"             = "bedrock"
    "bedrock-agent-runtime"     = "bedrock"
    "bedrock-agentcore"         = "bedrock-agentcore"
    "bedrock-agentcore-control" = "bedrock-agentcore"
    "bedrock-agentcore.gateway" = "bedrock-agentcore"
  }

  # Endpoints whose callers may authenticate with OAuth bearer tokens instead of SigV4.
  oauth_capable_services = ["bedrock-agentcore", "bedrock-agentcore.gateway"]

  # reverse_dns_prefix is "com.amazonaws" in the aws partition.
  service_names = {
    for s in var.services :
    s => "${data.aws_partition.current.reverse_dns_prefix}.${data.aws_region.current.region}.${s}"
  }

  org_condition = var.principal_org_id == null ? null : {
    StringEquals = { "aws:PrincipalOrgID" = var.principal_org_id }
  }

  # Policy for the bedrock-runtime endpoint: inference on named models and profiles only.
  runtime_statements = concat(
    [merge(
      {
        Sid       = "InvokeListedModelsOnly"
        Effect    = "Allow"
        Principal = "*"
        Action    = ["bedrock:InvokeModel", "bedrock:InvokeModelWithResponseStream"]
        Resource  = var.invoke_resource_arns
      },
      local.org_condition == null ? {} : { Condition = local.org_condition },
    )],
    length(var.guardrail_arns) > 0 ? [merge(
      {
        Sid       = "ApplyListedGuardrailsOnly"
        Effect    = "Allow"
        Principal = "*"
        Action    = ["bedrock:ApplyGuardrail"]
        Resource  = var.guardrail_arns
      },
      local.org_condition == null ? {} : { Condition = local.org_condition },
    )] : [],
  )

  runtime_invoke_policy = length(var.invoke_resource_arns) > 0 ? jsonencode({
    Version   = "2012-10-17"
    Statement = local.runtime_statements
  }) : null

  # Organization-only policy for every other selected endpoint (when principal_org_id is set).
  org_policies = {
    for s in var.services : s => jsonencode({
      Version = "2012-10-17"
      Statement = [{
        Sid       = "OrganizationPrincipalsOnly"
        Effect    = "Allow"
        Principal = "*"
        Action    = "${local.service_action_prefix[s]}:*"
        Resource  = "*"
        Condition = local.org_condition
      }]
    })
    if var.principal_org_id != null && (var.apply_org_policy_to_oauth_services || !contains(local.oauth_capable_services, s))
  }

  # null means "no custom policy": the endpoint keeps the AWS default full-access policy.
  endpoint_policies = {
    for s in var.services :
    s => s == "bedrock-runtime" && local.runtime_invoke_policy != null ? local.runtime_invoke_policy : lookup(local.org_policies, s, null)
  }
}

resource "aws_security_group" "endpoints" {
  name        = "${var.name}-bedrock-endpoints"
  description = "HTTPS from approved callers to Amazon Bedrock interface endpoints"
  vpc_id      = var.vpc_id
  tags        = merge(var.tags, { Name = "${var.name}-bedrock-endpoints" })

  # No egress rules: the endpoint network interfaces only answer connections. Terraform removes
  # the default allow-all egress rule from security groups it creates.

  lifecycle {
    precondition {
      condition     = length(var.allowed_cidr_blocks) + length(var.allowed_security_group_ids) > 0
      error_message = "Set allowed_cidr_blocks or allowed_security_group_ids: an endpoint nobody can reach is useless."
    }
    precondition {
      condition     = length(var.invoke_resource_arns) == 0 || contains(var.services, "bedrock-runtime")
      error_message = "invoke_resource_arns restricts the bedrock-runtime endpoint; add \"bedrock-runtime\" to services."
    }
    precondition {
      condition     = length(var.guardrail_arns) == 0 || length(var.invoke_resource_arns) > 0
      error_message = "guardrail_arns is only used in the restricted bedrock-runtime policy; set invoke_resource_arns as well."
    }
  }
}

resource "aws_vpc_security_group_ingress_rule" "https_from_cidr" {
  for_each = toset(var.allowed_cidr_blocks)

  security_group_id = aws_security_group.endpoints.id
  description       = "HTTPS to Bedrock endpoints from ${each.value}"
  ip_protocol       = "tcp"
  from_port         = 443
  to_port           = 443
  cidr_ipv4         = each.value
  tags              = var.tags
}

resource "aws_vpc_security_group_ingress_rule" "https_from_security_group" {
  for_each = toset(var.allowed_security_group_ids)

  security_group_id            = aws_security_group.endpoints.id
  description                  = "HTTPS to Bedrock endpoints from ${each.value}"
  ip_protocol                  = "tcp"
  from_port                    = 443
  to_port                      = 443
  referenced_security_group_id = each.value
  tags                         = var.tags
}

resource "aws_vpc_endpoint" "this" {
  for_each = local.service_names

  vpc_id              = var.vpc_id
  service_name        = each.value
  vpc_endpoint_type   = "Interface"
  subnet_ids          = var.subnet_ids
  security_group_ids  = [aws_security_group.endpoints.id]
  private_dns_enabled = var.private_dns_enabled
  policy              = local.endpoint_policies[each.key]
  tags                = merge(var.tags, { Name = "${var.name}-${each.key}" })

  lifecycle {
    precondition {
      condition     = !var.private_dns_enabled || (data.aws_vpc.this.enable_dns_support && data.aws_vpc.this.enable_dns_hostnames)
      error_message = "Private DNS needs enableDnsSupport and enableDnsHostnames on the VPC. Turn both on, or set private_dns_enabled = false and give clients the endpoint-specific DNS name."
    }
    precondition {
      condition     = local.endpoint_policies[each.key] == null ? true : length(local.endpoint_policies[each.key]) <= 20480
      error_message = "An endpoint policy cannot exceed 20,480 characters; shorten invoke_resource_arns or guardrail_arns."
    }
  }
}

check "endpoints_span_two_availability_zones" {
  assert {
    condition     = length(distinct(var.subnet_ids)) >= 2
    error_message = "Only one subnet: an impairment of that Availability Zone cuts every caller off. Use one subnet in each of two or more Availability Zones."
  }
}
