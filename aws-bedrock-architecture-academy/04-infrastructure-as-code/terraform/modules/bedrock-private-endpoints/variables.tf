variable "name" {
  description = "Name prefix for the endpoint security group and the Name tag of every endpoint."
  type        = string

  validation {
    condition     = can(regex("^[A-Za-z0-9][A-Za-z0-9-]{0,39}$", var.name))
    error_message = "name must be 1-40 characters: letters, digits and hyphens, starting with a letter or digit."
  }
}

variable "vpc_id" {
  description = "ID of the VPC in which the interface endpoints are created."
  type        = string

  validation {
    condition     = can(regex("^vpc-[0-9a-f]{8,17}$", var.vpc_id))
    error_message = "vpc_id must look like vpc-0123456789abcdef0."
  }
}

variable "subnet_ids" {
  description = "Subnets for the endpoint network interfaces: one subnet per Availability Zone, in at least two Availability Zones."
  type        = list(string)

  validation {
    condition     = length(var.subnet_ids) > 0
    error_message = "Provide at least one subnet ID (two or more in different Availability Zones is recommended)."
  }

  validation {
    condition     = alltrue([for id in var.subnet_ids : can(regex("^subnet-[0-9a-f]{8,17}$", id))])
    error_message = "Every entry in subnet_ids must look like subnet-0123456789abcdef0."
  }
}

variable "services" {
  description = "Service-name suffixes to create interface endpoints for, for example [\"bedrock-runtime\", \"bedrock-agent-runtime\"]. Only suffixes documented on the Amazon Bedrock and AgentCore interface-endpoint pages are accepted."
  type        = set(string)
  default     = ["bedrock-runtime"]

  validation {
    condition     = length(var.services) > 0
    error_message = "Select at least one service."
  }

  validation {
    condition     = alltrue([for s in var.services : contains(keys(local.service_action_prefix), s)])
    error_message = "Unsupported service. Allowed: bedrock, bedrock-runtime, bedrock-mantle, bedrock-agent, bedrock-agent-runtime, bedrock-agentcore, bedrock-agentcore-control, bedrock-agentcore.gateway."
  }
}

variable "private_dns_enabled" {
  description = "Resolve each service's default Regional DNS name to the endpoint. Requires enableDnsSupport and enableDnsHostnames on the VPC (checked by a precondition)."
  type        = bool
  default     = true
}

variable "allowed_cidr_blocks" {
  description = "IPv4 CIDR blocks allowed to reach the endpoints on TCP 443, for example the private subnets of the callers."
  type        = list(string)
  default     = []

  validation {
    condition     = alltrue([for c in var.allowed_cidr_blocks : can(cidrnetmask(c))])
    error_message = "Every entry in allowed_cidr_blocks must be an IPv4 CIDR block such as 10.0.0.0/16."
  }

  validation {
    condition     = !contains(var.allowed_cidr_blocks, "0.0.0.0/0")
    error_message = "0.0.0.0/0 is not allowed: list the caller subnets or use allowed_security_group_ids."
  }
}

variable "allowed_security_group_ids" {
  description = "Security groups whose members may reach the endpoints on TCP 443 (preferred over CIDR blocks)."
  type        = list(string)
  default     = []

  validation {
    condition     = alltrue([for id in var.allowed_security_group_ids : can(regex("^sg-[0-9a-f]{8,17}$", id))])
    error_message = "Every entry in allowed_security_group_ids must look like sg-0123456789abcdef0."
  }
}

variable "invoke_resource_arns" {
  description = "When non-empty, the bedrock-runtime endpoint gets a policy that allows only bedrock:InvokeModel and bedrock:InvokeModelWithResponseStream on these foundation-model and inference-profile ARNs. List the same ARNs as the callers' identity policies. No wildcards."
  type        = list(string)
  default     = []

  validation {
    condition     = alltrue([for arn in var.invoke_resource_arns : startswith(arn, "arn:") && strcontains(arn, ":bedrock:") && !strcontains(arn, "*")])
    error_message = "invoke_resource_arns must be Amazon Bedrock ARNs without wildcards."
  }
}

variable "guardrail_arns" {
  description = "Guardrail ARNs that callers may apply through the bedrock-runtime endpoint (bedrock:ApplyGuardrail). Only used together with invoke_resource_arns."
  type        = list(string)
  default     = []

  validation {
    condition     = alltrue([for arn in var.guardrail_arns : can(regex("^arn:[a-z-]+:bedrock:[a-z0-9-]+:[0-9]{12}:guardrail/[a-z0-9]+$", arn))])
    error_message = "guardrail_arns must be guardrail ARNs without a version suffix, for example arn:aws:bedrock:us-east-1:111122223333:guardrail/abc123def456."
  }
}

variable "principal_org_id" {
  description = "Optional AWS Organizations ID (o-...). When set, the endpoint policies allow only principals from this organization (aws:PrincipalOrgID)."
  type        = string
  default     = null

  validation {
    condition     = var.principal_org_id == null || can(regex("^o-[a-z0-9]{10,32}$", var.principal_org_id))
    error_message = "principal_org_id must look like o-a1b2c3d4e5."
  }
}

variable "apply_org_policy_to_oauth_services" {
  description = "Also restrict the bedrock-agentcore and bedrock-agentcore.gateway endpoints to principals in principal_org_id. Leave false if any caller authenticates to AgentCore Runtime or Gateway with an OAuth bearer token: such callers are not IAM principals and would be denied."
  type        = bool
  default     = false
}

variable "tags" {
  description = "Tags added to every resource, in addition to the provider's default_tags."
  type        = map(string)
  default     = {}
}
