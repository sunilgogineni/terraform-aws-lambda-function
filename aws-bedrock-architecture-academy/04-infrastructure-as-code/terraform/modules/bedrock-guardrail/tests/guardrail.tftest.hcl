# Plan-only unit tests with a mock provider: no AWS credentials, nothing is created.

mock_provider "aws" {}

variables {
  name = "chat-guardrail"
}

run "secure_defaults" {
  command = plan

  assert {
    condition     = length(output.content_filter_types) == 6
    error_message = "Defaults must configure the five harmful categories plus PROMPT_ATTACK."
  }

  assert {
    condition = alltrue([
      for f in aws_bedrock_guardrail.this.content_policy_config[0].filters_config :
      f.input_strength == "HIGH" && f.input_action == "BLOCK"
    ])
    error_message = "Every default filter must block at HIGH strength on input."
  }

  assert {
    condition = one([
      for f in aws_bedrock_guardrail.this.content_policy_config[0].filters_config :
      f.output_strength if f.type == "PROMPT_ATTACK"
    ]) == "NONE"
    error_message = "The prompt attack filter applies to prompts only; its output strength must be NONE."
  }

  assert {
    condition     = aws_bedrock_guardrail.this.content_policy_config[0].tier_config[0].tier_name == "CLASSIC"
    error_message = "The default tier must be CLASSIC (no cross-Region inference)."
  }

  assert {
    condition = (
      length(aws_bedrock_guardrail.this.topic_policy_config) == 0 &&
      length(aws_bedrock_guardrail.this.word_policy_config) == 0 &&
      length(aws_bedrock_guardrail.this.sensitive_information_policy_config) == 0 &&
      length(aws_bedrock_guardrail.this.contextual_grounding_policy_config) == 0 &&
      length(aws_bedrock_guardrail.this.cross_region_config) == 0
    )
    error_message = "Application-specific policies must be absent unless configured."
  }

  assert {
    condition     = length(aws_bedrock_guardrail_version.this) == 1 && aws_bedrock_guardrail_version.this[0].skip_destroy
    error_message = "A version must be published by default and earlier versions retained."
  }

  assert {
    condition     = length(output.policy_fingerprint) == 64
    error_message = "The policy fingerprint must be a SHA-256 hex digest."
  }
}

run "all_policies_configured" {
  command = plan

  variables {
    denied_topics = [{
      name       = "Investment advice"
      definition = "Recommendations about specific stocks, funds or other investments."
      examples   = ["Which stock should I buy?"]
    }]
    blocked_words   = ["CompetitorProduct"]
    block_profanity = true
    pii_entities = {
      EMAIL          = { action = "ANONYMIZE" }
      AWS_SECRET_KEY = { action = "BLOCK" }
    }
    regex_filters = [{
      name    = "booking-reference"
      pattern = "BK-[0-9]{8}"
      action  = "ANONYMIZE"
    }]
    contextual_grounding = {
      grounding_threshold = 0.7
      relevance_threshold = 0.5
    }
  }

  assert {
    condition     = aws_bedrock_guardrail.this.topic_policy_config[0].topics_config[0].type == "DENY"
    error_message = "Denied topics must use type DENY."
  }

  assert {
    condition = (
      aws_bedrock_guardrail.this.word_policy_config[0].managed_word_lists_config[0].type == "PROFANITY" &&
      aws_bedrock_guardrail.this.word_policy_config[0].words_config[0].text == "CompetitorProduct"
    )
    error_message = "Word policy must contain the managed profanity list and the custom word."
  }

  assert {
    condition     = length(aws_bedrock_guardrail.this.sensitive_information_policy_config[0].pii_entities_config) == 2
    error_message = "Both PII entity filters must be configured."
  }

  assert {
    condition = alltrue([
      for p in aws_bedrock_guardrail.this.sensitive_information_policy_config[0].pii_entities_config :
      p.input_action == p.action && p.output_action == p.action
    ])
    error_message = "Without overrides, input and output actions must equal the entity action."
  }

  assert {
    condition = toset([
      for f in aws_bedrock_guardrail.this.contextual_grounding_policy_config[0].filters_config : f.type
    ]) == toset(["GROUNDING", "RELEVANCE"])
    error_message = "Both grounding and relevance checks must be configured."
  }
}

run "standard_tier_with_profile" {
  command = plan

  variables {
    safeguard_tier                     = "STANDARD"
    cross_region_guardrail_profile_arn = "arn:aws:bedrock:us-east-1:111122223333:guardrail-profile/us.guardrail.v1:0"
    denied_topics = [{
      name       = "Medical diagnosis"
      definition = "Requests to diagnose a medical condition from symptoms."
    }]
  }

  assert {
    condition     = aws_bedrock_guardrail.this.cross_region_config[0].guardrail_profile_identifier == "arn:aws:bedrock:us-east-1:111122223333:guardrail-profile/us.guardrail.v1:0"
    error_message = "The STANDARD tier must carry the cross-Region guardrail profile."
  }

  assert {
    condition = (
      aws_bedrock_guardrail.this.content_policy_config[0].tier_config[0].tier_name == "STANDARD" &&
      aws_bedrock_guardrail.this.topic_policy_config[0].tier_config[0].tier_name == "STANDARD"
    )
    error_message = "Content and topic policies must both use the STANDARD tier."
  }
}

run "filters_can_be_switched_off_and_versioning_disabled" {
  command = plan

  variables {
    content_filters      = {}
    prompt_attack_filter = null
    blocked_words        = ["internal-codename"]
    create_version       = false
  }

  assert {
    condition     = length(aws_bedrock_guardrail.this.content_policy_config) == 0
    error_message = "With no filters the content policy block must be omitted."
  }

  assert {
    condition     = length(aws_bedrock_guardrail_version.this) == 0 && output.guardrail_version == null
    error_message = "No version must be published when create_version is false."
  }
}

run "rejects_standard_tier_without_profile" {
  command = plan

  variables {
    safeguard_tier = "STANDARD"
  }

  expect_failures = [var.safeguard_tier]
}

run "rejects_grounding_threshold_of_one" {
  command = plan

  variables {
    contextual_grounding = { grounding_threshold = 1 }
  }

  expect_failures = [var.contextual_grounding]
}

run "rejects_long_topic_definition_on_classic_tier" {
  command = plan

  variables {
    denied_topics = [{
      name       = "Too long"
      definition = join("", [for i in range(25) : "0123456789"])
    }]
  }

  expect_failures = [var.denied_topics]
}

run "rejects_unknown_content_category" {
  command = plan

  variables {
    content_filters = { PROMPT_ATTACK = { input_strength = "HIGH", output_strength = "NONE" } }
  }

  expect_failures = [var.content_filters]
}
