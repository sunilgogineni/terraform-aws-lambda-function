variable "name_prefix" {
  description = "Prefix for the IAM role, the KMS key description and the default bucket name. Lowercase letters, digits and hyphens."
  type        = string
  default     = "bedrock-invocation-logs"

  validation {
    condition     = can(regex("^[a-z0-9][a-z0-9-]{1,30}[a-z0-9]$", var.name_prefix))
    error_message = "name_prefix must be 3-32 characters of lowercase letters, digits and hyphens, starting and ending with a letter or digit."
  }
}

variable "enable_cloudwatch_logs" {
  description = "Deliver invocation logs to a CloudWatch Logs log group (created by this module, encrypted with the module's KMS key)."
  type        = bool
  default     = true
}

variable "enable_s3" {
  description = "Deliver invocation logs to an S3 bucket (created by this module: versioned, SSE-KMS, public access blocked, ACLs disabled)."
  type        = bool
  default     = true

  validation {
    condition     = var.enable_s3 || var.enable_cloudwatch_logs
    error_message = "Enable at least one destination: enable_s3 and/or enable_cloudwatch_logs."
  }
}

variable "cloudwatch_large_data_delivery" {
  description = "With CloudWatch Logs delivery, send request and response bodies larger than 100 KB and binary data to the S3 bucket (creates the bucket even when enable_s3 is false). Without it such data is not published to CloudWatch Logs."
  type        = bool
  default     = true
}

variable "log_group_name" {
  description = "Name of the CloudWatch Logs log group."
  type        = string
  default     = "/aws/bedrock/model-invocation-logs"

  validation {
    condition     = can(regex("^[.\\-_/#A-Za-z0-9]{1,512}$", var.log_group_name))
    error_message = "log_group_name must be 1-512 characters from a-z A-Z 0-9 . - _ / #"
  }
}

variable "log_retention_days" {
  description = "Retention of the log group in days. One of the values accepted by PutRetentionPolicy; never-expire is deliberately not offered (use the S3 destination for long-term retention)."
  type        = number
  default     = 90

  validation {
    condition     = contains([1, 3, 5, 7, 14, 30, 60, 90, 120, 150, 180, 365, 400, 545, 731, 1096, 1827, 2192, 2557, 2922, 3288, 3653], var.log_retention_days)
    error_message = "log_retention_days must be one of 1, 3, 5, 7, 14, 30, 60, 90, 120, 150, 180, 365, 400, 545, 731, 1096, 1827, 2192, 2557, 2922, 3288, 3653."
  }
}

variable "s3_bucket_name" {
  description = "Name of the log bucket. null derives \"<name_prefix>-<account-id>-<region>\"."
  type        = string
  default     = null

  validation {
    condition     = var.s3_bucket_name == null ? true : can(regex("^[a-z0-9][a-z0-9.-]{1,61}[a-z0-9]$", var.s3_bucket_name))
    error_message = "s3_bucket_name must be a valid S3 bucket name (3-63 characters: lowercase letters, digits, dots and hyphens)."
  }
}

variable "s3_key_prefix" {
  description = "Key prefix for log objects, without leading or trailing slash. Bedrock writes under <prefix>/AWSLogs/<account-id>/BedrockModelInvocationLogs/. Empty string for no prefix."
  type        = string
  default     = "bedrock"

  validation {
    condition     = var.s3_key_prefix == "" || can(regex("^[A-Za-z0-9!_.*'()-]+(/[A-Za-z0-9!_.*'()-]+)*$", var.s3_key_prefix))
    error_message = "s3_key_prefix must not start or end with a slash and may contain only S3 safe characters."
  }
}

variable "s3_log_expiration_days" {
  description = "Delete log objects after this many days (noncurrent versions after 30 more days). null keeps objects indefinitely."
  type        = number
  default     = 365

  validation {
    condition     = var.s3_log_expiration_days == null ? true : var.s3_log_expiration_days >= 1
    error_message = "s3_log_expiration_days must be at least 1, or null."
  }
}

variable "force_destroy" {
  description = "Allow terraform destroy to delete a log bucket that still contains objects. Leave false outside sandboxes: invocation logs are audit evidence."
  type        = bool
  default     = false
}

variable "data_delivery" {
  description = "Which data types are included in the logs. Each defaults to true, as in the provider."
  type = object({
    text      = optional(bool, true)
    image     = optional(bool, true)
    embedding = optional(bool, true)
    video     = optional(bool, true)
  })
  default = {}
}

variable "kms_key_deletion_window_in_days" {
  description = "Waiting period before the KMS key is deleted after destroy (7-30 days)."
  type        = number
  default     = 30

  validation {
    condition     = var.kms_key_deletion_window_in_days >= 7 && var.kms_key_deletion_window_in_days <= 30
    error_message = "kms_key_deletion_window_in_days must be between 7 and 30."
  }
}

variable "tags" {
  description = "Tags added to every taggable resource, in addition to the provider's default_tags."
  type        = map(string)
  default     = {}
}
