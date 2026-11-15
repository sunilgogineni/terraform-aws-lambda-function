variable "environment" {
  description = "Deployment stage. Each stage is a separate AWS account (ADR-013) with its own state (ADR-011)."
  type        = string

  validation {
    condition     = contains(["dev", "test", "staging", "prod"], var.environment)
    error_message = "environment must be one of dev, test, staging, prod."
  }
}

variable "account_id" {
  description = "AWS account ID of this environment. The provider refuses to run against any other account (allowed_account_ids)."
  type        = string

  validation {
    condition     = can(regex("^[0-9]{12}$", var.account_id))
    error_message = "account_id must be a 12-digit AWS account ID."
  }
}

variable "region" {
  description = "Home Region of the workload: where the role's inference calls originate and where the runtime configuration parameter is stored."
  type        = string
  default     = "us-east-1"
}

variable "deployment_role_arn" {
  description = "Optional IAM role in the target account for Terraform to assume. Leave null when the pipeline already holds credentials for the target account (for example through OIDC)."
  type        = string
  default     = null

  validation {
    condition     = var.deployment_role_arn == null || can(regex("^arn:aws[a-z-]*:iam::[0-9]{12}:role/", var.deployment_role_arn))
    error_message = "deployment_role_arn must be an IAM role ARN."
  }
}

variable "workload" {
  description = "Short workload name used as the prefix of every resource name."
  type        = string
  default     = "chat"

  validation {
    condition     = can(regex("^[a-z][a-z0-9-]{1,20}$", var.workload))
    error_message = "workload must be 2-21 characters: lowercase letters, digits and hyphens, starting with a letter."
  }
}

variable "foundation_model_ids" {
  description = "Foundation model IDs the workload may invoke. Configuration, not code (ADR-010): confirm current IDs in the Amazon Bedrock model catalog before use."
  type        = list(string)
}

variable "inference_profile_ids" {
  description = "System-defined inference profile IDs (for example a Geo profile) the workload calls. ARNs are built for var.region and var.account_id. Empty means direct in-Region invocation."
  type        = list(string)
  default     = []
}

variable "model_regions" {
  description = "Every Region the foundation models may run in: the home Region plus every destination Region of the inference profiles."
  type        = list(string)
}

variable "guardrail_arn" {
  description = "ARN (without version) of the guardrail this environment applies. The guardrail itself is managed by a separate component with its own state. Required in staging and prod."
  type        = string
  default     = null

  validation {
    condition     = var.guardrail_arn == null || can(regex("^arn:aws[a-z-]*:bedrock:[a-z0-9-]+:[0-9]{12}:guardrail/[A-Za-z0-9-]+$", var.guardrail_arn))
    error_message = "guardrail_arn must be a guardrail ARN without a version suffix."
  }

  validation {
    condition     = !contains(["staging", "prod"], var.environment) || var.guardrail_arn != null
    error_message = "staging and prod must set guardrail_arn."
  }
}

variable "guardrail_version" {
  description = "Guardrail version the application sends with each request. DRAFT is allowed only in dev and test; staging and prod must pin a published numeric version."
  type        = string
  default     = "DRAFT"

  validation {
    condition     = var.guardrail_version == "DRAFT" || can(regex("^[0-9]+$", var.guardrail_version))
    error_message = "guardrail_version must be DRAFT or a published version number."
  }

  validation {
    condition     = !contains(["staging", "prod"], var.environment) || can(regex("^[0-9]+$", var.guardrail_version))
    error_message = "staging and prod must pin a published guardrail version, not DRAFT."
  }
}

variable "require_guardrail" {
  description = "When true, the role is denied inference calls that do not carry this environment's guardrail. Must be true in staging and prod."
  type        = bool
  default     = false

  validation {
    condition     = !contains(["staging", "prod"], var.environment) || var.require_guardrail
    error_message = "require_guardrail must be true in staging and prod."
  }
}

variable "max_output_tokens" {
  description = "Application-level cap on output tokens per request, published to the runtime configuration. Keep it below the model's documented maximum. Not an AWS quota: Bedrock quotas are per account and Region and are managed in Service Quotas."
  type        = number
  default     = 1024

  validation {
    condition     = var.max_output_tokens >= 1 && floor(var.max_output_tokens) == var.max_output_tokens
    error_message = "max_output_tokens must be a positive whole number."
  }
}

variable "permissions_boundary_arn" {
  description = "Optional permissions boundary for the invocation role, typically mandated by the platform team in higher environments."
  type        = string
  default     = null
}

variable "tags" {
  description = "Extra tags merged into the provider's default_tags."
  type        = map(string)
  default     = {}
}
