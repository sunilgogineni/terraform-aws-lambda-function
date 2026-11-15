# An Amazon Bedrock AgentCore Runtime (container artifact), a named endpoint, and its
# least-privilege execution role.
#
# Documented behaviour this module encodes:
#  * The execution role trusts bedrock-agentcore.amazonaws.com with aws:SourceAccount and
#    aws:SourceArn conditions.
#  * The documented execution policy grants ECR image pull, CloudWatch Logs under
#    /aws/bedrock-agentcore/runtimes/, X-Ray, cloudwatch:PutMetricData in the bedrock-agentcore
#    namespace, workload access tokens and model invocation. This module keeps every statement
#    but narrows the resources: one ECR repository, this runtime's log groups, named models.
#  * A runtime ARN is runtime/<name>-<10 characters>, and its log groups are
#    /aws/bedrock-agentcore/runtimes/<runtime id>-<endpoint name>, so "<name>-*" scopes both.
#  * DEFAULT always points at the latest version; other endpoints move only when told to.
# Sources are listed in README.md.

data "aws_partition" "current" {}

data "aws_region" "current" {}

data "aws_caller_identity" "current" {}

locals {
  # account, Region and repository are captured; a tag or a sha256 digest is required.
  container_uri_pattern = "^(?P<account>[0-9]{12})\\.dkr\\.ecr\\.(?P<region>[a-z0-9-]+)\\.amazonaws\\.com(?:\\.cn)?/(?P<repository>[a-z0-9][a-z0-9._/-]*)(?::[A-Za-z0-9_][A-Za-z0-9_.-]{0,127}|@sha256:[a-f0-9]{64})$"

  image              = regex(local.container_uri_pattern, var.container_uri)
  partition          = data.aws_partition.current.partition
  region             = data.aws_region.current.region
  account_id         = data.aws_caller_identity.current.account_id
  ecr_repository_arn = "arn:${local.partition}:ecr:${local.image.region}:${local.image.account}:repository/${local.image.repository}"

  agentcore_arn_prefix = "arn:${local.partition}:bedrock-agentcore:${local.region}:${local.account_id}"
  log_group_arn_prefix = "arn:${local.partition}:logs:${local.region}:${local.account_id}:log-group"
  runtime_log_groups   = "${local.log_group_arn_prefix}:/aws/bedrock-agentcore/runtimes/${var.name}-*"

  workload_token_actions = concat(
    [
      "bedrock-agentcore:GetWorkloadAccessToken",
      "bedrock-agentcore:GetWorkloadAccessTokenForJWT",
    ],
    var.allow_workload_token_for_user_id ? ["bedrock-agentcore:GetWorkloadAccessTokenForUserId"] : [],
  )

  execution_statements = concat(
    [
      {
        Sid      = "ECRImageAccess"
        Effect   = "Allow"
        Action   = ["ecr:BatchGetImage", "ecr:GetDownloadUrlForLayer"]
        Resource = [local.ecr_repository_arn]
      },
      {
        Sid      = "ECRTokenAccess"
        Effect   = "Allow"
        Action   = ["ecr:GetAuthorizationToken"]
        Resource = "*"
      },
      {
        Sid      = "RuntimeLogGroups"
        Effect   = "Allow"
        Action   = ["logs:DescribeLogStreams", "logs:CreateLogGroup"]
        Resource = [local.runtime_log_groups]
      },
      {
        Sid      = "SpanDeliveryToRuntimeLogGroups"
        Effect   = "Allow"
        Action   = ["logs:PutResourcePolicy"]
        Resource = [local.runtime_log_groups]
      },
      {
        Sid      = "DescribeLogGroups"
        Effect   = "Allow"
        Action   = ["logs:DescribeLogGroups"]
        Resource = ["${local.log_group_arn_prefix}:*"]
      },
      {
        Sid      = "RuntimeLogStreams"
        Effect   = "Allow"
        Action   = ["logs:CreateLogStream", "logs:PutLogEvents"]
        Resource = ["${local.runtime_log_groups}:log-stream:*"]
      },
      {
        Sid    = "XRayTracing"
        Effect = "Allow"
        Action = [
          "xray:PutTraceSegments",
          "xray:PutTelemetryRecords",
          "xray:GetSamplingRules",
          "xray:GetSamplingTargets",
        ]
        Resource = "*"
      },
      {
        Sid      = "AgentCoreMetrics"
        Effect   = "Allow"
        Action   = ["cloudwatch:PutMetricData"]
        Resource = "*"
        Condition = {
          StringEquals = { "cloudwatch:namespace" = "bedrock-agentcore" }
        }
      },
      {
        Sid    = "GetAgentAccessToken"
        Effect = "Allow"
        Action = local.workload_token_actions
        Resource = [
          "${local.agentcore_arn_prefix}:workload-identity-directory/default",
          "${local.agentcore_arn_prefix}:workload-identity-directory/default/workload-identity/${var.name}-*",
        ]
      },
    ],
    length(var.model_arns) > 0 ? [{
      Sid      = "BedrockModelInvocation"
      Effect   = "Allow"
      Action   = ["bedrock:InvokeModel", "bedrock:InvokeModelWithResponseStream"]
      Resource = var.model_arns
    }] : [],
  )

  execution_policy_json = jsonencode({
    Version   = "2012-10-17"
    Statement = local.execution_statements
  })

  trust_policy_json = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Sid       = "AssumeRolePolicy"
      Effect    = "Allow"
      Principal = { Service = "bedrock-agentcore.amazonaws.com" }
      Action    = "sts:AssumeRole"
      Condition = {
        StringEquals = { "aws:SourceAccount" = local.account_id }
        ArnLike      = { "aws:SourceArn" = "${local.agentcore_arn_prefix}:*" }
      }
    }]
  })
}

resource "aws_iam_role" "execution" {
  name                 = "${var.name}-execution"
  description          = "Execution role for AgentCore Runtime ${var.name}"
  assume_role_policy   = local.trust_policy_json
  permissions_boundary = var.permissions_boundary_arn
  tags                 = var.tags
}

resource "aws_iam_role_policy" "execution" {
  name   = "agentcore-runtime-execution"
  role   = aws_iam_role.execution.id
  policy = local.execution_policy_json
}

resource "aws_bedrockagentcore_agent_runtime" "this" {
  agent_runtime_name    = var.name
  description           = var.description
  role_arn              = aws_iam_role.execution.arn
  platform_version      = var.platform_version
  environment_variables = length(var.environment_variables) > 0 ? var.environment_variables : null
  tags                  = var.tags

  agent_runtime_artifact {
    container_configuration {
      container_uri = var.container_uri
    }
  }

  network_configuration {
    network_mode = var.network_mode

    dynamic "network_mode_config" {
      for_each = var.network_mode == "VPC" ? [1] : []
      content {
        subnets         = var.subnet_ids
        security_groups = var.security_group_ids
      }
    }
  }

  protocol_configuration {
    server_protocol = var.server_protocol
  }

  lifecycle_configuration {
    idle_runtime_session_timeout = var.idle_session_timeout_seconds
    max_lifetime                 = var.max_lifetime_seconds
  }

  # No block: inbound authorization is IAM (SigV4). With a block: JWT bearer tokens only.
  dynamic "authorizer_configuration" {
    for_each = var.jwt_authorizer == null ? [] : [var.jwt_authorizer]
    content {
      custom_jwt_authorizer {
        discovery_url    = authorizer_configuration.value.discovery_url
        allowed_audience = length(authorizer_configuration.value.allowed_audiences) > 0 ? authorizer_configuration.value.allowed_audiences : null
        allowed_clients  = length(authorizer_configuration.value.allowed_clients) > 0 ? authorizer_configuration.value.allowed_clients : null
      }
    }
  }

  # The role must be able to pull the image before the runtime is created.
  depends_on = [aws_iam_role_policy.execution]

  lifecycle {
    precondition {
      condition     = var.network_mode != "VPC" || (length(var.subnet_ids) > 0 && length(var.security_group_ids) > 0)
      error_message = "VPC mode needs subnet_ids and security_group_ids. Use network_mode = \"PUBLIC\" only if sessions may reach the internet."
    }
    precondition {
      condition     = var.network_mode != "PUBLIC" || (length(var.subnet_ids) == 0 && length(var.security_group_ids) == 0)
      error_message = "subnet_ids and security_group_ids are ignored in PUBLIC mode; remove them or set network_mode = \"VPC\"."
    }
  }
}

resource "aws_bedrockagentcore_agent_runtime_endpoint" "this" {
  name             = var.endpoint_name
  description      = "Endpoint ${var.endpoint_name} of ${var.name}; moves to a new version only when endpoint_runtime_version changes"
  agent_runtime_id = aws_bedrockagentcore_agent_runtime.this.agent_runtime_id
  agent_runtime_version = coalesce(
    var.endpoint_runtime_version,
    aws_bedrockagentcore_agent_runtime.this.agent_runtime_version,
  )
  tags = var.tags
}
