variable "name" {
  description = "Name of the knowledge base. Also the base of the vector bucket (<name>-vectors), the vector index (<name>-index), the data source and the service role names. Lowercase letters, digits and single hyphens."
  type        = string

  validation {
    condition     = can(regex("^[a-z0-9][a-z0-9-]{1,46}[a-z0-9]$", var.name)) && !strcontains(var.name, "--")
    error_message = "name must be 3-48 characters of lowercase letters, digits and single hyphens, starting and ending with a letter or digit."
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

variable "embedding_model_arn" {
  description = "ARN of the Bedrock embedding model, for example arn:aws:bedrock:us-east-1::foundation-model/<model-id>. Confirm the model ID, its Region and its supported dimensions in the Bedrock documentation."
  type        = string

  validation {
    condition     = can(regex("^arn:aws[a-z-]*:bedrock:[a-z0-9-]+:[0-9]{0,12}:[a-z-]+/[^*]+$", var.embedding_model_arn))
    error_message = "embedding_model_arn must be a Bedrock model ARN without wildcards."
  }
}

variable "embedding_dimensions" {
  description = "Vector dimensions. Must be a value the embedding model produces; the vector index is created with the same value (1-4096)."
  type        = number
  default     = 1024

  validation {
    condition     = var.embedding_dimensions >= 1 && var.embedding_dimensions <= 4096 && floor(var.embedding_dimensions) == var.embedding_dimensions
    error_message = "embedding_dimensions must be an integer between 1 and 4096."
  }
}

variable "distance_metric" {
  description = "Similarity metric of the vector index: cosine or euclidean."
  type        = string
  default     = "cosine"

  validation {
    condition     = contains(["cosine", "euclidean"], var.distance_metric)
    error_message = "distance_metric must be cosine or euclidean."
  }
}

variable "additional_non_filterable_metadata_keys" {
  description = "Extra non-filterable metadata keys for the index. AMAZON_BEDROCK_TEXT and AMAZON_BEDROCK_METADATA are always added; the total may not exceed 10."
  type        = list(string)
  default     = []

  validation {
    condition     = length(setunion(toset(var.additional_non_filterable_metadata_keys), toset(["AMAZON_BEDROCK_TEXT", "AMAZON_BEDROCK_METADATA"]))) <= 10
    error_message = "At most 10 non-filterable metadata keys are allowed, including AMAZON_BEDROCK_TEXT and AMAZON_BEDROCK_METADATA."
  }
}

variable "data_source_bucket_arn" {
  description = "ARN of the existing general purpose S3 bucket that holds the documents. It must be in the same Region as the knowledge base."
  type        = string

  validation {
    condition     = can(regex("^arn:aws[a-z-]*:s3:::[a-z0-9][a-z0-9.-]{1,61}[a-z0-9]$", var.data_source_bucket_arn))
    error_message = "data_source_bucket_arn must be an S3 bucket ARN (arn:<partition>:s3:::<bucket>) without an object path or wildcard."
  }
}

variable "data_source_bucket_owner_account_id" {
  description = "Account ID that owns the documents bucket. null means the current account. For a bucket in another account, its bucket policy must also grant the service role access."
  type        = string
  default     = null

  validation {
    condition     = var.data_source_bucket_owner_account_id == null ? true : can(regex("^[0-9]{12}$", var.data_source_bucket_owner_account_id))
    error_message = "data_source_bucket_owner_account_id must be a 12-digit account ID."
  }
}

variable "inclusion_prefix" {
  description = "S3 key prefix to ingest, for example \"documents/\". The S3 data source accepts one prefix, and the service role can read only that prefix. null ingests, and lets the role read, the whole bucket."
  type        = string
  default     = null

  validation {
    condition     = var.inclusion_prefix == null ? true : (length(var.inclusion_prefix) >= 1 && length(var.inclusion_prefix) <= 300 && !startswith(var.inclusion_prefix, "/") && !strcontains(var.inclusion_prefix, "*"))
    error_message = "inclusion_prefix must be 1-300 characters, must not start with a slash and must not contain wildcards."
  }
}

variable "chunking_strategy" {
  description = "How documents are split: FIXED_SIZE, HIERARCHICAL, SEMANTIC or NONE. Fixed when the data source is created."
  type        = string
  default     = "FIXED_SIZE"

  validation {
    condition     = contains(["FIXED_SIZE", "HIERARCHICAL", "SEMANTIC", "NONE"], var.chunking_strategy)
    error_message = "chunking_strategy must be FIXED_SIZE, HIERARCHICAL, SEMANTIC or NONE."
  }
}

variable "fixed_size_chunking" {
  description = "Settings used when chunking_strategy is FIXED_SIZE: max_tokens 1-8192, overlap_percentage 1-99."
  type = object({
    max_tokens         = optional(number, 300)
    overlap_percentage = optional(number, 20)
  })
  default = {}

  validation {
    condition = (
      var.fixed_size_chunking.max_tokens >= 1 && var.fixed_size_chunking.max_tokens <= 8192 &&
      var.fixed_size_chunking.overlap_percentage >= 1 && var.fixed_size_chunking.overlap_percentage <= 99
    )
    error_message = "fixed_size_chunking: max_tokens must be 1-8192 and overlap_percentage 1-99."
  }
}

variable "hierarchical_chunking" {
  description = "Settings used when chunking_strategy is HIERARCHICAL: the parent and child layer sizes in tokens and the overlap in tokens."
  type = object({
    parent_max_tokens = optional(number, 1500)
    child_max_tokens  = optional(number, 300)
    overlap_tokens    = optional(number, 60)
  })
  default = {}

  validation {
    condition = (
      var.hierarchical_chunking.overlap_tokens >= 1 &&
      var.hierarchical_chunking.child_max_tokens >= 1 &&
      var.hierarchical_chunking.parent_max_tokens > var.hierarchical_chunking.child_max_tokens
    )
    error_message = "hierarchical_chunking: overlap_tokens and child_max_tokens must be at least 1, and parent_max_tokens greater than child_max_tokens."
  }
}

variable "semantic_chunking" {
  description = "Settings used when chunking_strategy is SEMANTIC: max_tokens 1-8192, buffer_size 0-1, breakpoint_percentile_threshold 50-99."
  type = object({
    max_tokens                      = optional(number, 300)
    buffer_size                     = optional(number, 0)
    breakpoint_percentile_threshold = optional(number, 95)
  })
  default = {}

  validation {
    condition = (
      var.semantic_chunking.max_tokens >= 1 && var.semantic_chunking.max_tokens <= 8192 &&
      var.semantic_chunking.buffer_size >= 0 && var.semantic_chunking.buffer_size <= 1 &&
      var.semantic_chunking.breakpoint_percentile_threshold >= 50 && var.semantic_chunking.breakpoint_percentile_threshold <= 99
    )
    error_message = "semantic_chunking: max_tokens must be 1-8192, buffer_size 0-1 and breakpoint_percentile_threshold 50-99."
  }
}

variable "data_deletion_policy" {
  description = "What happens to the vectors when the data source is deleted: DELETE or RETAIN."
  type        = string
  default     = "DELETE"

  validation {
    condition     = contains(["DELETE", "RETAIN"], var.data_deletion_policy)
    error_message = "data_deletion_policy must be DELETE or RETAIN."
  }
}

variable "vector_kms_key_arn" {
  description = "Optional customer managed KMS key ARN for the vector bucket (SSE-KMS). null uses SSE-S3. Fixed at creation. The key policy must include the statement in the vector_kms_key_policy_statement_json output."
  type        = string
  default     = null

  validation {
    condition     = var.vector_kms_key_arn == null ? true : can(regex("^arn:aws[a-z-]*:kms:[a-z0-9-]+:[0-9]{12}:key/[a-zA-Z0-9-]+$", var.vector_kms_key_arn))
    error_message = "vector_kms_key_arn must be a full KMS key ARN; S3 Vectors does not accept key IDs or aliases."
  }
}

variable "data_source_kms_key_arn" {
  description = "Optional ARN of the KMS key that encrypts the documents bucket (SSE-KMS). Grants the service role kms:Decrypt through Amazon S3."
  type        = string
  default     = null

  validation {
    condition     = var.data_source_kms_key_arn == null ? true : can(regex("^arn:aws[a-z-]*:kms:[a-z0-9-]+:[0-9]{12}:key/[a-zA-Z0-9-]+$", var.data_source_kms_key_arn))
    error_message = "data_source_kms_key_arn must be a KMS key ARN."
  }
}

variable "transient_data_kms_key_arn" {
  description = "Optional customer managed KMS key ARN for data that Bedrock stores transiently during ingestion. null uses an AWS owned key."
  type        = string
  default     = null

  validation {
    condition     = var.transient_data_kms_key_arn == null ? true : can(regex("^arn:aws[a-z-]*:kms:[a-z0-9-]+:[0-9]{12}:key/[a-zA-Z0-9-]+$", var.transient_data_kms_key_arn))
    error_message = "transient_data_kms_key_arn must be a KMS key ARN."
  }
}

variable "vector_bucket_force_destroy" {
  description = "Allow terraform destroy to delete the vector bucket while it still holds indexes and vectors. Leave false outside sandboxes."
  type        = bool
  default     = false
}

variable "permissions_boundary_arn" {
  description = "Optional permissions boundary policy ARN for the service role."
  type        = string
  default     = null
}

variable "tags" {
  description = "Tags added to the knowledge base, the vector bucket, the index and the role, in addition to the provider's default_tags."
  type        = map(string)
  default     = {}
}
