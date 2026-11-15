variable "name_prefix" {
  description = "Prefix of the role name. A random suffix is added so parallel test runs never collide."
  type        = string
  default     = "itest"

  validation {
    condition     = can(regex("^[a-z][a-z0-9-]{1,40}$", var.name_prefix))
    error_message = "name_prefix must be 2-41 characters: lowercase letters, digits and hyphens."
  }
}

variable "region" {
  description = "Region of the sandbox account in which the role is created and the guardrail ARN is built."
  type        = string
  default     = "us-east-1"
}

variable "foundation_model_ids" {
  description = "Model IDs the role may invoke. The policy simulator does not need the models to exist, but use IDs from the model catalog so the test mirrors production."
  type        = list(string)
}

variable "model_regions" {
  description = "Regions in which the models may be invoked."
  type        = list(string)
}

variable "guardrail_id" {
  description = "ID of the guardrail the role must use. The guardrail does not have to exist for the policy simulation."
  type        = string
  default     = "itestguardrail"
}

variable "tags" {
  description = "Tags for everything the test creates, so a sweeper can find leftovers."
  type        = map(string)
  default = {
    Purpose = "integration-test"
  }
}
