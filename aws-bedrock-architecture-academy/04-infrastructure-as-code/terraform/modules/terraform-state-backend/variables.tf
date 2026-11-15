variable "bucket_name" {
  description = "Name of the state bucket. Lowercase letters, digits and hyphens; no dots, so that virtual-hosted-style HTTPS works."
  type        = string

  validation {
    condition     = can(regex("^[a-z0-9][a-z0-9-]{1,61}[a-z0-9]$", var.bucket_name)) && !startswith(var.bucket_name, "xn--")
    error_message = "bucket_name must be 3-63 lowercase letters, digits or hyphens, start and end with a letter or digit, and not start with xn--."
  }
}

variable "state_keys" {
  description = "State object keys (or key patterns such as \"prod/*\") that the backend access policy covers, for example [\"prod/network/terraform.tfstate\"]. The matching .tflock lock files are added automatically."
  type        = list(string)
  default     = ["terraform.tfstate"]

  validation {
    condition     = length(var.state_keys) > 0
    error_message = "Provide at least one state key."
  }

  validation {
    condition     = alltrue([for k in var.state_keys : length(k) > 0 && !startswith(k, "/") && k != "*"])
    error_message = "State keys must be non-empty, must not start with / and must not be a bare *."
  }
}

variable "kms_alias_name" {
  description = "Alias for the customer managed key. Defaults to alias/terraform-state-<bucket_name>."
  type        = string
  default     = null

  validation {
    condition     = var.kms_alias_name == null ? true : (can(regex("^alias/[a-zA-Z0-9/_-]+$", var.kms_alias_name)) && !startswith(var.kms_alias_name, "alias/aws/"))
    error_message = "kms_alias_name must start with alias/, use letters, digits, /, _ or -, and not start with alias/aws/."
  }
}

variable "kms_deletion_window_in_days" {
  description = "Waiting period before the key is deleted after a destroy (7-30 days). Deleting the key makes every state version unreadable."
  type        = number
  default     = 30

  validation {
    condition     = var.kms_deletion_window_in_days >= 7 && var.kms_deletion_window_in_days <= 30
    error_message = "kms_deletion_window_in_days must be between 7 and 30."
  }
}

variable "kms_rotation_period_in_days" {
  description = "Days between automatic rotations of the key material (90-2560). Rotation is always on."
  type        = number
  default     = 365

  validation {
    condition     = var.kms_rotation_period_in_days >= 90 && var.kms_rotation_period_in_days <= 2560
    error_message = "kms_rotation_period_in_days must be between 90 and 2560."
  }
}

variable "require_kms_key_header" {
  description = "Deny PutObject requests that do not name a KMS key. The backend sends the header when encrypt = true and kms_key_id are set, as in the backend_config output."
  type        = bool
  default     = true
}

variable "noncurrent_version_expiration_days" {
  description = "Days after which noncurrent state versions (and the versions left by deleted .tflock files) expire. Null disables the lifecycle rule and keeps every version."
  type        = number
  default     = 90

  validation {
    condition     = var.noncurrent_version_expiration_days == null ? true : var.noncurrent_version_expiration_days >= 1
    error_message = "noncurrent_version_expiration_days must be at least 1, or null."
  }
}

variable "noncurrent_versions_to_keep" {
  description = "Number of most recent noncurrent versions of each object that are kept regardless of age. Null keeps none beyond the age rule."
  type        = number
  default     = 10

  validation {
    condition     = var.noncurrent_versions_to_keep == null ? true : var.noncurrent_versions_to_keep >= 1
    error_message = "noncurrent_versions_to_keep must be at least 1, or null."
  }
}

variable "abort_incomplete_multipart_upload_days" {
  description = "Days after which incomplete multipart uploads are aborted (part of the lifecycle rule)."
  type        = number
  default     = 7

  validation {
    condition     = var.abort_incomplete_multipart_upload_days >= 1
    error_message = "abort_incomplete_multipart_upload_days must be at least 1."
  }
}

variable "tags" {
  description = "Tags added to every resource, in addition to the provider's default_tags."
  type        = map(string)
  default     = {}
}
