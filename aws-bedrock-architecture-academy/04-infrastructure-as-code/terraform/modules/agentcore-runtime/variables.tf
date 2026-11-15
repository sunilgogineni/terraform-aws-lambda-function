variable "name" {
  description = "Name of the agent runtime. Also prefixes the execution role, the workload identity and the runtime's log groups."
  type        = string

  validation {
    condition     = can(regex("^[a-zA-Z][a-zA-Z0-9_]{0,47}$", var.name))
    error_message = "name must start with a letter and contain 1-48 letters, digits or underscores (no hyphens)."
  }
}

variable "description" {
  description = "Optional description of the agent runtime."
  type        = string
  default     = null

  validation {
    condition     = var.description == null ? true : (length(var.description) >= 1 && length(var.description) <= 4096)
    error_message = "description must be 1-4096 characters."
  }
}

variable "container_uri" {
  description = "URI of an ARM64 image in a private Amazon ECR repository, with a tag or a sha256 digest, for example 111122223333.dkr.ecr.us-east-1.amazonaws.com/support-agent:1.4.0."
  type        = string

  validation {
    condition     = can(regex(local.container_uri_pattern, var.container_uri))
    error_message = "container_uri must be a private Amazon ECR image URI with a tag (:1.4.0) or a digest (@sha256:...)."
  }
}

variable "network_mode" {
  description = "PUBLIC (sessions have internet access) or VPC (sessions get network interfaces in subnet_ids and have no internet access unless your VPC provides it)."
  type        = string
  default     = "VPC"

  validation {
    condition     = contains(["PUBLIC", "VPC"], var.network_mode)
    error_message = "network_mode must be PUBLIC or VPC."
  }
}

variable "subnet_ids" {
  description = "Private subnets for VPC mode, in Availability Zones that AgentCore supports. Use two or more Availability Zones."
  type        = list(string)
  default     = []

  validation {
    condition     = length(var.subnet_ids) <= 16 && alltrue([for id in var.subnet_ids : can(regex("^subnet-[0-9a-zA-Z]{8,17}$", id))])
    error_message = "subnet_ids takes up to 16 IDs that look like subnet-0123456789abcdef0."
  }
}

variable "security_group_ids" {
  description = "Security groups for the session network interfaces in VPC mode. Their egress rules decide what the agent can reach."
  type        = list(string)
  default     = []

  validation {
    condition     = length(var.security_group_ids) <= 16 && alltrue([for id in var.security_group_ids : can(regex("^sg-[0-9a-zA-Z]{8,17}$", id))])
    error_message = "security_group_ids takes up to 16 IDs that look like sg-0123456789abcdef0."
  }
}

variable "server_protocol" {
  description = "Service contract the container implements: HTTP (port 8080), MCP (8000), A2A (9000) or AGUI (8080)."
  type        = string
  default     = "HTTP"

  validation {
    condition     = contains(["HTTP", "MCP", "A2A", "AGUI"], var.server_protocol)
    error_message = "server_protocol must be HTTP, MCP, A2A or AGUI."
  }
}

variable "platform_version" {
  description = "V1 or V2. Set explicitly so that a change of service default cannot change behaviour. V2 is available in fewer Regions."
  type        = string
  default     = "V1"

  validation {
    condition     = contains(["V1", "V2"], var.platform_version)
    error_message = "platform_version must be V1 or V2."
  }
}

variable "idle_session_timeout_seconds" {
  description = "Seconds a session may stay idle before its compute is stopped (60-28800). Billing continues while a session is idle."
  type        = number
  default     = 900

  validation {
    condition     = var.idle_session_timeout_seconds >= 60 && var.idle_session_timeout_seconds <= 28800
    error_message = "idle_session_timeout_seconds must be between 60 and 28800."
  }
}

variable "max_lifetime_seconds" {
  description = "Maximum lifetime of the compute behind a session, in seconds (60-28800, the microVM maximum of 8 hours)."
  type        = number
  default     = 28800

  validation {
    condition     = var.max_lifetime_seconds >= 60 && var.max_lifetime_seconds <= 28800
    error_message = "max_lifetime_seconds must be between 60 and 28800."
  }
}

variable "environment_variables" {
  description = "Non-secret configuration passed to the container (at most 50 entries). Put secrets in AgentCore Identity or AWS Secrets Manager, never here."
  type        = map(string)
  default     = {}

  validation {
    condition     = length(var.environment_variables) <= 50
    error_message = "At most 50 environment variables are allowed."
  }
}

variable "model_arns" {
  description = "Foundation-model and inference-profile ARNs the agent may invoke (bedrock:InvokeModel and bedrock:InvokeModelWithResponseStream). For a cross-Region profile, list the profile and the model in every destination Region. Empty means no model access. No wildcards."
  type        = list(string)
  default     = []

  validation {
    condition     = alltrue([for arn in var.model_arns : startswith(arn, "arn:") && strcontains(arn, ":bedrock:") && !strcontains(arn, "*")])
    error_message = "model_arns must be Amazon Bedrock ARNs without wildcards."
  }
}

variable "allow_workload_token_for_user_id" {
  description = "Also grant bedrock-agentcore:GetWorkloadAccessTokenForUserId, which issues workload access tokens for a caller-supplied user ID without identity-provider verification. Leave false when callers present JWTs."
  type        = bool
  default     = false
}

variable "jwt_authorizer" {
  description = "Optional inbound JWT authorization. When null, callers authenticate with IAM (SigV4), the default."
  type = object({
    discovery_url     = string
    allowed_audiences = optional(list(string), [])
    allowed_clients   = optional(list(string), [])
  })
  default = null

  validation {
    condition = var.jwt_authorizer == null || (
      startswith(try(var.jwt_authorizer.discovery_url, ""), "https://")
      && endswith(try(var.jwt_authorizer.discovery_url, ""), "/.well-known/openid-configuration")
    )
    error_message = "jwt_authorizer.discovery_url must be an https URL ending in /.well-known/openid-configuration."
  }
}

variable "endpoint_name" {
  description = "Name of the endpoint this module creates. DEFAULT exists already and always follows the latest version."
  type        = string
  default     = "live"

  validation {
    condition     = can(regex("^[a-zA-Z][a-zA-Z0-9_]{0,47}$", var.endpoint_name)) && upper(var.endpoint_name) != "DEFAULT"
    error_message = "endpoint_name must start with a letter, contain 1-48 letters, digits or underscores, and not be DEFAULT."
  }
}

variable "endpoint_runtime_version" {
  description = "Runtime version the endpoint points at. Null makes it follow the version created by this apply; after the first apply, pin it to the version you tested."
  type        = string
  default     = null

  validation {
    condition     = var.endpoint_runtime_version == null || can(regex("^[1-9][0-9]{0,4}$", var.endpoint_runtime_version))
    error_message = "endpoint_runtime_version must be a version number such as \"3\"."
  }
}

variable "permissions_boundary_arn" {
  description = "Optional permissions boundary policy ARN for the execution role."
  type        = string
  default     = null
}

variable "tags" {
  description = "Tags added to every resource, in addition to the provider's default_tags."
  type        = map(string)
  default     = {}
}
