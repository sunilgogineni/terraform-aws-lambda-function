# Amazon Bedrock guardrail with content, prompt-attack, denied-topic, word and
# sensitive-information policies, an optional contextual grounding check, an optional
# customer managed KMS key, and a published (immutable) version.
#
# Documented behaviour this module encodes:
#  * Content filter categories: HATE, INSULTS, SEXUAL, VIOLENCE, MISCONDUCT, PROMPT_ATTACK;
#    strengths NONE | LOW | MEDIUM | HIGH; actions BLOCK | NONE; modalities TEXT | IMAGE.
#  * The prompt attack filter evaluates prompts only (the API example sets inputStrength only).
#  * The STANDARD safeguard tier requires a cross-Region guardrail profile (crossRegionConfig).
#  * Denied topic definitions: 200 characters with CLASSIC, 1,000 with STANDARD.
#  * Contextual grounding thresholds are 0 to 0.99.
#  * CreateGuardrail always creates the DRAFT; CreateGuardrailVersion publishes an immutable version.
# Sources are listed in README.md.

locals {
  content_filters = [
    for category, f in var.content_filters : {
      type              = category
      input_strength    = f.input_strength
      output_strength   = f.output_strength
      input_action      = f.input_action
      output_action     = f.output_action
      input_modalities  = f.input_modalities
      output_modalities = f.output_modalities
    }
  ]

  prompt_attack_filters = var.prompt_attack_filter == null ? [] : [{
    type              = "PROMPT_ATTACK"
    input_strength    = var.prompt_attack_filter.input_strength
    output_strength   = "NONE" # required by the provider schema; the filter applies to prompts only
    input_action      = var.prompt_attack_filter.input_action
    output_action     = null
    input_modalities  = ["TEXT"]
    output_modalities = null
  }]

  all_content_filters = concat(local.content_filters, local.prompt_attack_filters)

  pii_entities = [
    for entity_type, p in var.pii_entities : {
      type          = entity_type
      action        = p.action
      input_action  = coalesce(p.input_action, p.action)
      output_action = coalesce(p.output_action, p.action)
    }
  ]

  grounding_filters = var.contextual_grounding == null ? [] : concat(
    var.contextual_grounding.grounding_threshold == null ? [] : [{ type = "GROUNDING", threshold = var.contextual_grounding.grounding_threshold }],
    var.contextual_grounding.relevance_threshold == null ? [] : [{ type = "RELEVANCE", threshold = var.contextual_grounding.relevance_threshold }],
  )

  has_content_policy   = length(local.all_content_filters) > 0
  has_topic_policy     = length(var.denied_topics) > 0
  has_word_policy      = length(var.blocked_words) > 0 || var.block_profanity
  has_sensitive_policy = length(local.pii_entities) + length(var.regex_filters) > 0

  # Everything that changes the guardrail's behaviour. A change to this fingerprint
  # publishes a new version (see terraform_data.version_trigger).
  policy_fingerprint = sha256(jsonencode({
    blocked_input_messaging   = var.blocked_input_messaging
    blocked_outputs_messaging = var.blocked_outputs_messaging
    safeguard_tier            = var.safeguard_tier
    cross_region_profile      = var.cross_region_guardrail_profile
    content_filters           = local.all_content_filters
    denied_topics             = var.denied_topics
    blocked_words             = var.blocked_words
    block_profanity           = var.block_profanity
    pii_entities              = local.pii_entities
    regex_filters             = var.regex_filters
    grounding_filters         = local.grounding_filters
    kms_key_arn               = var.kms_key_arn
  }))
}

resource "aws_bedrock_guardrail" "this" {
  name                      = var.name
  description               = var.description
  blocked_input_messaging   = var.blocked_input_messaging
  blocked_outputs_messaging = var.blocked_outputs_messaging
  kms_key_arn               = var.kms_key_arn
  tags                      = var.tags

  dynamic "cross_region_config" {
    for_each = var.cross_region_guardrail_profile == null ? [] : [var.cross_region_guardrail_profile]

    content {
      guardrail_profile_identifier = cross_region_config.value
    }
  }

  dynamic "content_policy_config" {
    for_each = local.has_content_policy ? [1] : []

    content {
      tier_config = [{ tier_name = var.safeguard_tier }]

      dynamic "filters_config" {
        for_each = local.all_content_filters

        content {
          type              = filters_config.value.type
          input_strength    = filters_config.value.input_strength
          output_strength   = filters_config.value.output_strength
          input_action      = filters_config.value.input_action
          output_action     = filters_config.value.output_action
          input_modalities  = filters_config.value.input_modalities
          output_modalities = filters_config.value.output_modalities
        }
      }
    }
  }

  dynamic "topic_policy_config" {
    for_each = local.has_topic_policy ? [1] : []

    content {
      tier_config = [{ tier_name = var.safeguard_tier }]

      dynamic "topics_config" {
        for_each = var.denied_topics

        content {
          name       = topics_config.value.name
          definition = topics_config.value.definition
          examples   = topics_config.value.examples
          type       = "DENY"
        }
      }
    }
  }

  dynamic "word_policy_config" {
    for_each = local.has_word_policy ? [1] : []

    content {
      dynamic "managed_word_lists_config" {
        for_each = var.block_profanity ? ["PROFANITY"] : []

        content {
          type = managed_word_lists_config.value
        }
      }

      dynamic "words_config" {
        for_each = var.blocked_words

        content {
          text = words_config.value
        }
      }
    }
  }

  dynamic "sensitive_information_policy_config" {
    for_each = local.has_sensitive_policy ? [1] : []

    content {
      dynamic "pii_entities_config" {
        for_each = local.pii_entities

        content {
          type          = pii_entities_config.value.type
          action        = pii_entities_config.value.action
          input_action  = pii_entities_config.value.input_action
          output_action = pii_entities_config.value.output_action
        }
      }

      dynamic "regexes_config" {
        for_each = var.regex_filters

        content {
          name        = regexes_config.value.name
          pattern     = regexes_config.value.pattern
          action      = regexes_config.value.action
          description = regexes_config.value.description
        }
      }
    }
  }

  dynamic "contextual_grounding_policy_config" {
    for_each = length(local.grounding_filters) > 0 ? [1] : []

    content {
      dynamic "filters_config" {
        for_each = local.grounding_filters

        content {
          type      = filters_config.value.type
          threshold = filters_config.value.threshold
        }
      }
    }
  }
}

# Changes whenever the policy configuration changes, and forces a new published version.
resource "terraform_data" "version_trigger" {
  input = local.policy_fingerprint
}

resource "aws_bedrock_guardrail_version" "this" {
  count = var.create_version ? 1 : 0

  guardrail_arn = aws_bedrock_guardrail.this.guardrail_arn
  description   = var.version_description
  skip_destroy  = var.retain_previous_versions

  lifecycle {
    replace_triggered_by = [terraform_data.version_trigger]
  }
}
