variable "name" {
  description = "Name of the managed knowledge base. Also the base of the data source (<name>-s3) and service role (<name>-kb-service-role) names. Letters and digits, optionally separated by single hyphens or underscores; at most 48 characters."
  type        = string

  validation {
    condition     = length(var.name) <= 48 && can(regex("^([0-9a-zA-Z][_-]?)+$", var.name)) && can(regex("[0-9a-zA-Z]$", var.name))
    error_message = "name must be at most 48 characters of letters and digits, optionally separated by single hyphens or underscores, ending with a letter or digit."
  }
}

variable "description" {
  description = "Optional description of the knowledge base (1-200 characters)."
  type        = string
  default     = null

  validation {
    condition     = var.description == null ? true : (length(var.description) >= 1 && length(var.description) <= 200)
    error_message = "description must be 1-200 characters."
  }
}

variable "embedding_model_type" {
  description = "MANAGED uses the service-managed embedding model (and makes the managed reranker available); CUSTOM uses custom_embedding_model_arn. Cannot be changed after creation."
  type        = string
  default     = "MANAGED"

  validation {
    condition     = contains(["MANAGED", "CUSTOM"], var.embedding_model_type)
    error_message = "embedding_model_type must be MANAGED or CUSTOM."
  }
}

variable "custom_embedding_model_arn" {
  description = "ARN of your Bedrock embedding model when embedding_model_type is CUSTOM. It must produce 1,024-dimension float32 vectors. Confirm the model ID in the Bedrock documentation."
  type        = string
  default     = null

  validation {
    condition     = (var.embedding_model_type == "CUSTOM") == (var.custom_embedding_model_arn != null)
    error_message = "Set custom_embedding_model_arn exactly when embedding_model_type is CUSTOM."
  }

  validation {
    condition     = var.custom_embedding_model_arn == null ? true : can(regex("^arn:aws[a-z-]*:bedrock:[a-z0-9-]+:[0-9]{0,12}:[a-z-]+/[^*]+$", var.custom_embedding_model_arn))
    error_message = "custom_embedding_model_arn must be a Bedrock model ARN without wildcards."
  }
}

variable "kms_key_arn" {
  description = "Optional customer managed KMS key ARN for the knowledge base's transient and stored data. Set once at creation. The key policy must allow the identity that creates the knowledge base (see README); the service role needs no key permissions."
  type        = string
  default     = null

  validation {
    condition     = var.kms_key_arn == null ? true : can(regex("^arn:aws[a-z-]*:kms:[a-z0-9-]+:[0-9]{12}:key/[a-zA-Z0-9-]+$", var.kms_key_arn))
    error_message = "kms_key_arn must be a KMS key ARN."
  }
}

variable "source_bucket_name" {
  description = "Existing general purpose S3 bucket, in the same Region as the knowledge base, that holds the documents."
  type        = string

  validation {
    condition     = can(regex("^[a-z0-9][a-z0-9.-]{1,61}[a-z0-9]$", var.source_bucket_name))
    error_message = "source_bucket_name must be a valid S3 bucket name."
  }
}

variable "source_bucket_owner_account_id" {
  description = "Account ID that owns the source bucket. null means the current account. A bucket in another account also needs a bucket policy for the service role."
  type        = string
  default     = null

  validation {
    condition     = var.source_bucket_owner_account_id == null ? true : can(regex("^[0-9]{12}$", var.source_bucket_owner_account_id))
    error_message = "source_bucket_owner_account_id must be a 12-digit account ID."
  }
}

variable "inclusion_prefixes" {
  description = "S3 key prefixes to ingest. When set, the service role can read only these prefixes (plus the metadata prefix and the ACL file). Empty ingests the whole bucket."
  type        = list(string)
  default     = []

  validation {
    condition     = alltrue([for p in var.inclusion_prefixes : length(p) >= 1 && !startswith(p, "/") && !strcontains(p, "*")])
    error_message = "Prefixes must be non-empty, must not start with a slash and must not contain wildcards."
  }
}

variable "exclusion_prefixes" {
  description = "S3 key prefixes not to ingest."
  type        = list(string)
  default     = []
}

variable "inclusion_patterns" {
  description = "Regular expressions; when set, only object keys matching at least one are ingested."
  type        = list(string)
  default     = []
}

variable "exclusion_patterns" {
  description = "Regular expressions; object keys matching any of them are not ingested."
  type        = list(string)
  default     = []
}

variable "max_file_size_mb" {
  description = "Largest file, in megabytes, that the connector ingests. null keeps the service default."
  type        = number
  default     = null

  validation {
    condition     = var.max_file_size_mb == null ? true : (var.max_file_size_mb >= 1 && floor(var.max_file_size_mb) == var.max_file_size_mb)
    error_message = "max_file_size_mb must be a positive integer, or null."
  }
}

variable "metadata_files_prefix" {
  description = "Optional S3 prefix where the .metadata.json sidecar files are stored."
  type        = string
  default     = null
}

variable "acl_global_file_s3_uri" {
  description = "Optional s3:// URI of the global ACL file. Setting it enables document-level access control on the data source, which is permanent: queries must then pass userContext."
  type        = string
  default     = null

  validation {
    condition     = var.acl_global_file_s3_uri == null ? true : can(regex("^s3://[a-z0-9][a-z0-9.-]{1,61}[a-z0-9]/.+$", var.acl_global_file_s3_uri))
    error_message = "acl_global_file_s3_uri must be an s3://bucket/key URI."
  }
}

variable "source_kms_key_arn" {
  description = "Optional ARN of the KMS key that encrypts the source bucket (SSE-KMS). Grants the service role kms:Decrypt through Amazon S3."
  type        = string
  default     = null

  validation {
    condition     = var.source_kms_key_arn == null ? true : can(regex("^arn:aws[a-z-]*:kms:[a-z0-9-]+:[0-9]{12}:key/[a-zA-Z0-9-]+$", var.source_kms_key_arn))
    error_message = "source_kms_key_arn must be a KMS key ARN."
  }
}

variable "sync_frequency" {
  description = "Automatic sync schedule: ON_DEMAND (call StartIngestionJob yourself), DAILY, WEEKLY or MONTHLY."
  type        = string
  default     = "ON_DEMAND"

  validation {
    condition     = contains(["ON_DEMAND", "DAILY", "WEEKLY", "MONTHLY"], var.sync_frequency)
    error_message = "sync_frequency must be ON_DEMAND, DAILY, WEEKLY or MONTHLY."
  }
}

variable "sync_day_of_week" {
  description = "Day of the weekly sync (SUNDAY to SATURDAY). Used when sync_frequency is WEEKLY."
  type        = string
  default     = "SUNDAY"

  validation {
    condition     = contains(["SUNDAY", "MONDAY", "TUESDAY", "WEDNESDAY", "THURSDAY", "FRIDAY", "SATURDAY"], var.sync_day_of_week)
    error_message = "sync_day_of_week must be SUNDAY, MONDAY, TUESDAY, WEDNESDAY, THURSDAY, FRIDAY or SATURDAY."
  }
}

variable "sync_day_of_month" {
  description = "Day of the monthly sync (1-28). null syncs on the last day of the month. Used when sync_frequency is MONTHLY."
  type        = number
  default     = null

  validation {
    condition     = var.sync_day_of_month == null ? true : (var.sync_day_of_month >= 1 && var.sync_day_of_month <= 28 && floor(var.sync_day_of_month) == var.sync_day_of_month)
    error_message = "sync_day_of_month must be an integer from 1 to 28, or null for the last day of the month."
  }
}

variable "deletion_protection_threshold" {
  description = "Maximum percentage (0-100) of indexed documents one sync may delete; a sync that would delete more skips its delete phase. null disables deletion protection."
  type        = number
  default     = 15

  validation {
    condition     = var.deletion_protection_threshold == null ? true : (var.deletion_protection_threshold >= 0 && var.deletion_protection_threshold <= 100)
    error_message = "deletion_protection_threshold must be between 0 and 100, or null."
  }
}

variable "media_extraction" {
  description = "Extract and index content from images (standalone and embedded in PDF and Office files), audio and video."
  type = object({
    images = optional(bool, false)
    audio  = optional(bool, false)
    video  = optional(bool, false)
  })
  default = {}
}

variable "publish_retrieve_metrics" {
  description = "Allow the service role to publish Retrieve metrics (cloudwatch:PutMetricData limited to the AWS/Bedrock/KnowledgeBases namespace). Metric publishing is best effort; requests work without it."
  type        = bool
  default     = true
}

variable "permissions_boundary_arn" {
  description = "Optional permissions boundary policy ARN for the service role."
  type        = string
  default     = null
}

variable "tags" {
  description = "Tags added to the knowledge base and the role, in addition to the provider's default_tags."
  type        = map(string)
  default     = {}
}
