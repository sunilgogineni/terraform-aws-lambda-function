variable "name" {
  description = "Name of the guardrail (1-50 characters: letters, digits, hyphens and underscores)."
  type        = string

  validation {
    condition     = can(regex("^[0-9a-zA-Z_-]{1,50}$", var.name))
    error_message = "name must be 1-50 characters from the set 0-9 a-z A-Z - _ (CreateGuardrail name pattern)."
  }
}

variable "description" {
  description = "Optional description of the guardrail (1-200 characters)."
  type        = string
  default     = null

  validation {
    condition     = var.description == null ? true : (length(var.description) >= 1 && length(var.description) <= 200)
    error_message = "description must be 1-200 characters."
  }
}

variable "blocked_input_messaging" {
  description = "Message returned to the caller when the guardrail blocks a prompt (1-500 characters)."
  type        = string
  default     = "Sorry, this request cannot be processed."

  validation {
    condition     = length(var.blocked_input_messaging) >= 1 && length(var.blocked_input_messaging) <= 500
    error_message = "blocked_input_messaging must be 1-500 characters."
  }
}

variable "blocked_outputs_messaging" {
  description = "Message returned to the caller when the guardrail blocks a model response (1-500 characters)."
  type        = string
  default     = "Sorry, the response was blocked."

  validation {
    condition     = length(var.blocked_outputs_messaging) >= 1 && length(var.blocked_outputs_messaging) <= 500
    error_message = "blocked_outputs_messaging must be 1-500 characters."
  }
}

variable "kms_key_arn" {
  description = "Optional ARN of a customer managed symmetric KMS key that encrypts the guardrail at rest. null uses the service default key. The key policy must grant guardrail creators and users the actions listed in the module README."
  type        = string
  default     = null

  validation {
    condition     = var.kms_key_arn == null ? true : can(regex("^arn:aws[a-z-]*:kms:[a-z0-9-]+:[0-9]{12}:key/[a-zA-Z0-9-]+$", var.kms_key_arn))
    error_message = "kms_key_arn must be a KMS key ARN (arn:<partition>:kms:<region>:<account>:key/<key-id>), not an alias."
  }
}

variable "safeguard_tier" {
  description = "Safeguard tier for the content filters and denied topics: CLASSIC or STANDARD. STANDARD uses cross-Region inference and needs cross_region_guardrail_profile_arn."
  type        = string
  default     = "CLASSIC"

  validation {
    condition     = contains(["CLASSIC", "STANDARD"], var.safeguard_tier)
    error_message = "safeguard_tier must be CLASSIC or STANDARD."
  }

  validation {
    condition     = var.safeguard_tier == "CLASSIC" || var.cross_region_guardrail_profile_arn != null
    error_message = "The STANDARD tier requires cross_region_guardrail_profile_arn."
  }
}

variable "cross_region_guardrail_profile_arn" {
  description = "Optional ARN of a system-defined guardrail profile, for example arn:aws:bedrock:us-east-1:111122223333:guardrail-profile/us.guardrail.v1:0. It enables cross-Region guardrail inference: prompts and responses may then be processed in other Regions of the same geography."
  type        = string
  default     = null

  validation {
    condition     = var.cross_region_guardrail_profile_arn == null ? true : can(regex("^arn:aws[a-z-]*:bedrock:[a-z0-9-]+:[0-9]{12}:guardrail-profile/[a-z-]+\\.guardrail\\.v[0-9]+:[0-9]+$", var.cross_region_guardrail_profile_arn))
    error_message = "cross_region_guardrail_profile_arn must be a guardrail profile ARN (arn:<partition>:bedrock:<region>:<account>:guardrail-profile/<geo>.guardrail.v1:0)."
  }
}

variable "content_filters" {
  description = "Harmful-content filters keyed by category (HATE, INSULTS, SEXUAL, VIOLENCE, MISCONDUCT). Strengths are NONE, LOW, MEDIUM or HIGH; actions are BLOCK or NONE (detect only); modalities are TEXT and/or IMAGE. Set to {} to disable the categories."
  type = map(object({
    input_strength    = string
    output_strength   = string
    input_action      = optional(string, "BLOCK")
    output_action     = optional(string, "BLOCK")
    input_modalities  = optional(list(string), ["TEXT"])
    output_modalities = optional(list(string), ["TEXT"])
  }))
  default = {
    HATE       = { input_strength = "HIGH", output_strength = "HIGH" }
    INSULTS    = { input_strength = "HIGH", output_strength = "HIGH" }
    SEXUAL     = { input_strength = "HIGH", output_strength = "HIGH" }
    VIOLENCE   = { input_strength = "HIGH", output_strength = "HIGH" }
    MISCONDUCT = { input_strength = "HIGH", output_strength = "HIGH" }
  }

  validation {
    condition     = alltrue([for k in keys(var.content_filters) : contains(["HATE", "INSULTS", "SEXUAL", "VIOLENCE", "MISCONDUCT"], k)])
    error_message = "content_filters keys must be HATE, INSULTS, SEXUAL, VIOLENCE or MISCONDUCT. Configure prompt attacks with prompt_attack_filter."
  }

  validation {
    condition = alltrue(flatten([
      for f in values(var.content_filters) : [
        contains(["NONE", "LOW", "MEDIUM", "HIGH"], f.input_strength),
        contains(["NONE", "LOW", "MEDIUM", "HIGH"], f.output_strength),
        contains(["BLOCK", "NONE"], f.input_action),
        contains(["BLOCK", "NONE"], f.output_action),
      ]
    ]))
    error_message = "Strengths must be NONE, LOW, MEDIUM or HIGH; actions must be BLOCK or NONE."
  }

  validation {
    condition = alltrue(flatten([
      for f in values(var.content_filters) : [
        length(f.input_modalities) >= 1 && length(f.input_modalities) <= 2,
        length(f.output_modalities) >= 1 && length(f.output_modalities) <= 2,
        alltrue([for m in concat(f.input_modalities, f.output_modalities) : contains(["TEXT", "IMAGE"], m)]),
      ]
    ]))
    error_message = "Modalities must be a list of 1-2 values from TEXT and IMAGE."
  }
}

variable "prompt_attack_filter" {
  description = "Prompt attack (jailbreak and prompt injection) filter. It evaluates prompts only, so the module always sends an output strength of NONE. Set to null to disable."
  type = object({
    input_strength = optional(string, "HIGH")
    input_action   = optional(string, "BLOCK")
  })
  default = {}

  validation {
    condition = var.prompt_attack_filter == null ? true : (
      contains(["NONE", "LOW", "MEDIUM", "HIGH"], var.prompt_attack_filter.input_strength) &&
      contains(["BLOCK", "NONE"], var.prompt_attack_filter.input_action)
    )
    error_message = "prompt_attack_filter.input_strength must be NONE, LOW, MEDIUM or HIGH and input_action BLOCK or NONE."
  }
}

variable "denied_topics" {
  description = "Topics to deny. name: 1-100 characters from letters, digits, space and - _ ! ? . ; definition: up to 200 characters (CLASSIC) or 1,000 (STANDARD); examples: up to 5 example prompts of up to 100 characters each."
  type = list(object({
    name       = string
    definition = string
    examples   = optional(list(string), [])
  }))
  default = []

  validation {
    condition     = alltrue([for t in var.denied_topics : can(regex("^[0-9a-zA-Z_ !?.-]{1,100}$", t.name))])
    error_message = "Each topic name must be 1-100 characters from letters, digits, space and - _ ! ? ."
  }

  validation {
    condition     = alltrue([for t in var.denied_topics : length(t.definition) >= 1 && length(t.definition) <= (var.safeguard_tier == "STANDARD" ? 1000 : 200)])
    error_message = "Each topic definition must be 1-200 characters with the CLASSIC tier, or 1-1000 with STANDARD."
  }

  validation {
    condition     = alltrue([for t in var.denied_topics : length(t.examples) <= 5 && alltrue([for e in t.examples : length(e) >= 1 && length(e) <= 100])])
    error_message = "Each topic may have at most 5 examples of 1-100 characters."
  }
}

variable "blocked_words" {
  description = "Custom words or phrases to block (exact match), each 1-100 characters."
  type        = list(string)
  default     = []

  validation {
    condition     = alltrue([for w in var.blocked_words : length(w) >= 1 && length(w) <= 100])
    error_message = "Each blocked word or phrase must be 1-100 characters."
  }
}

variable "block_profanity" {
  description = "Add the AWS managed PROFANITY word list to the word policy."
  type        = bool
  default     = false
}

variable "pii_entities" {
  description = "Sensitive-information (PII) filters keyed by entity type (for example EMAIL, US_SOCIAL_SECURITY_NUMBER, AWS_SECRET_KEY). action is BLOCK, ANONYMIZE or NONE; input_action and output_action override it per direction."
  type = map(object({
    action        = string
    input_action  = optional(string)
    output_action = optional(string)
  }))
  default = {}

  validation {
    condition = alltrue([for k in keys(var.pii_entities) : contains([
      "ADDRESS", "AGE", "AWS_ACCESS_KEY", "AWS_SECRET_KEY", "CA_HEALTH_NUMBER", "CA_SOCIAL_INSURANCE_NUMBER",
      "CREDIT_DEBIT_CARD_CVV", "CREDIT_DEBIT_CARD_EXPIRY", "CREDIT_DEBIT_CARD_NUMBER", "DRIVER_ID", "EMAIL",
      "INTERNATIONAL_BANK_ACCOUNT_NUMBER", "IP_ADDRESS", "LICENSE_PLATE", "MAC_ADDRESS", "NAME", "PASSWORD",
      "PHONE", "PIN", "SWIFT_CODE", "UK_NATIONAL_HEALTH_SERVICE_NUMBER", "UK_NATIONAL_INSURANCE_NUMBER",
      "UK_UNIQUE_TAXPAYER_REFERENCE_NUMBER", "URL", "USERNAME", "US_BANK_ACCOUNT_NUMBER", "US_BANK_ROUTING_NUMBER",
      "US_INDIVIDUAL_TAX_IDENTIFICATION_NUMBER", "US_PASSPORT_NUMBER", "US_SOCIAL_SECURITY_NUMBER",
      "VEHICLE_IDENTIFICATION_NUMBER",
    ], k)])
    error_message = "pii_entities keys must be PII entity types from the GuardrailPiiEntityConfig API reference."
  }

  validation {
    condition = alltrue(flatten([
      for p in values(var.pii_entities) : [
        contains(["BLOCK", "ANONYMIZE", "NONE"], p.action),
        contains(["BLOCK", "ANONYMIZE", "NONE"], coalesce(p.input_action, p.action)),
        contains(["BLOCK", "ANONYMIZE", "NONE"], coalesce(p.output_action, p.action)),
      ]
    ]))
    error_message = "PII actions must be BLOCK, ANONYMIZE or NONE."
  }
}

variable "regex_filters" {
  description = "Custom regular-expression filters in the sensitive-information policy. name: 1-100 characters; pattern: 1-500 characters; action: BLOCK, ANONYMIZE or NONE."
  type = list(object({
    name        = string
    pattern     = string
    action      = string
    description = optional(string)
  }))
  default = []

  validation {
    condition = alltrue([
      for r in var.regex_filters :
      length(r.name) >= 1 && length(r.name) <= 100 &&
      length(r.pattern) >= 1 && length(r.pattern) <= 500 &&
      contains(["BLOCK", "ANONYMIZE", "NONE"], r.action)
    ])
    error_message = "Each regex filter needs a 1-100 character name, a 1-500 character pattern and an action of BLOCK, ANONYMIZE or NONE."
  }
}

variable "contextual_grounding" {
  description = "Optional contextual grounding check. Set grounding_threshold and/or relevance_threshold (0 to 0.99); responses that score below a threshold are filtered. null disables the policy."
  type = object({
    grounding_threshold = optional(number)
    relevance_threshold = optional(number)
  })
  default = null

  validation {
    condition = var.contextual_grounding == null ? true : alltrue([
      for t in [var.contextual_grounding.grounding_threshold, var.contextual_grounding.relevance_threshold] :
      t == null ? true : (t >= 0 && t <= 0.99)
    ])
    error_message = "Contextual grounding thresholds must be between 0 and 0.99 (1 would block every response)."
  }

  validation {
    condition     = var.contextual_grounding == null ? true : (var.contextual_grounding.grounding_threshold != null || var.contextual_grounding.relevance_threshold != null)
    error_message = "Set at least one of grounding_threshold and relevance_threshold, or set contextual_grounding to null."
  }
}

variable "create_version" {
  description = "Publish a numbered, immutable guardrail version. A new version is published whenever the policy configuration changes."
  type        = bool
  default     = true
}

variable "version_description" {
  description = "Optional description for the published version."
  type        = string
  default     = null
}

variable "retain_previous_versions" {
  description = "Keep earlier published versions when a new one is published or the module is destroyed (skip_destroy), so callers pinned to an old version keep working."
  type        = bool
  default     = true
}

variable "tags" {
  description = "Tags added to the guardrail, in addition to the provider's default_tags."
  type        = map(string)
  default     = {}
}
