variable "name" {
  description = "Name of the IAM role. Also used as the prefix of the inline policy name."
  type        = string

  validation {
    condition     = can(regex("^[A-Za-z0-9+=,.@_-]{1,56}$", var.name))
    error_message = "name must be 1-56 characters from the set A-Z a-z 0-9 + = , . @ _ -"
  }
}

variable "trusted_services" {
  description = "AWS service principals allowed to assume the role, for example [\"lambda.amazonaws.com\"]."
  type        = list(string)
  default     = []
}

variable "trusted_role_arns" {
  description = "IAM principal ARNs allowed to assume the role (for example a CI role or a role in another account)."
  type        = list(string)
  default     = []
}

variable "foundation_model_ids" {
  description = "Foundation model IDs this role may invoke. Confirm current IDs in the Amazon Bedrock model catalog; they change as models are retired."
  type        = list(string)

  validation {
    condition     = length(var.foundation_model_ids) > 0
    error_message = "Provide at least one foundation model ID. A wildcard on all models is deliberately not supported by this module."
  }

  validation {
    condition     = alltrue([for id in var.foundation_model_ids : !strcontains(id, "*")])
    error_message = "Wildcards are not allowed in foundation_model_ids."
  }
}

variable "model_regions" {
  description = "Regions in which the foundation models may be invoked. With cross-Region inference this must include every destination Region of the inference profile."
  type        = list(string)

  validation {
    condition     = length(var.model_regions) > 0
    error_message = "Provide at least one Region."
  }
}

variable "inference_profile_arns" {
  description = "ARNs of system-defined or application inference profiles the role may invoke. Leave empty to allow direct on-demand invocation of the models only."
  type        = list(string)
  default     = []
}

variable "restrict_to_inference_profiles" {
  description = "When true, the foundation models can be invoked only through one of inference_profile_arns (adds a bedrock:InferenceProfileArn condition)."
  type        = bool
  default     = false
}

variable "allow_global_inference" {
  description = "When true, also allows the Region-less foundation-model ARN that Global inference profiles require."
  type        = bool
  default     = false
}

variable "allow_streaming" {
  description = "Allow bedrock:InvokeModelWithResponseStream (needed for ConverseStream and InvokeModelWithResponseStream)."
  type        = bool
  default     = true
}

variable "guardrail_arns" {
  description = "Guardrail ARNs (without a version suffix) the role may apply. Grants bedrock:ApplyGuardrail."
  type        = list(string)
  default     = []
}

variable "required_guardrail_arn_pattern" {
  description = "Optional ARN pattern, for example \"arn:aws:bedrock:us-east-1:111122223333:guardrail/abc123:*\". When set, inference is denied unless the request uses a matching guardrail."
  type        = string
  default     = null
}

variable "permissions_boundary_arn" {
  description = "Optional permissions boundary policy ARN for the role."
  type        = string
  default     = null
}

variable "tags" {
  description = "Tags added to the role, in addition to the provider's default_tags."
  type        = map(string)
  default     = {}
}
