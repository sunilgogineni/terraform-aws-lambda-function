variable "role_arn" {
  description = "Role whose attached policies are simulated."
  type        = string
}

variable "action_names" {
  description = "IAM actions to simulate, for example [\"bedrock:InvokeModel\"]."
  type        = list(string)
}

variable "resource_arns" {
  description = "Resources the simulated requests target. They do not have to exist."
  type        = list(string)
}

variable "guardrail_identifier" {
  description = "Value of the bedrock:GuardrailIdentifier condition key in the simulated request, or null to simulate a request without a guardrail."
  type        = string
  default     = null
}
