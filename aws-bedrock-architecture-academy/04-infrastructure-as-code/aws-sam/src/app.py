"""AWS Lambda handler for the academy's AWS SAM example: POST /chat -> Amazon Bedrock Converse.

Code status: syntax-checked (py_compile) and mock-tested with botocore Stubber
(tests/test_app.py). Never deployed.

Configuration comes from environment variables that template.yaml sets:
  MODEL_ID           inference profile ID (or model ID) passed to Converse as modelId
  GUARDRAIL_ID       guardrail identifier (the template passes the guardrail ARN)
  GUARDRAIL_VERSION  published guardrail version number, for example "1"
  MAX_TOKENS         upper bound on generated tokens
The model ID is configuration, never a literal in code; confirm current IDs in the
Amazon Bedrock model catalog before you deploy.
"""
from __future__ import annotations

import json
import logging
import os
from typing import Any

import boto3
from botocore.config import Config
from botocore.exceptions import ClientError

LOGGER = logging.getLogger()
LOGGER.setLevel(logging.INFO)

MAX_MESSAGE_CHARS = 4000  # reject oversized prompts before they cost tokens
SYSTEM_PROMPT = "You are a concise assistant. Answer in at most five sentences."

# Created once per execution environment and reused across invocations.
_RUNTIME = boto3.client(
    "bedrock-runtime",
    config=Config(retries={"mode": "standard", "max_attempts": 3}, read_timeout=25),
)


def _response(status: int, body: dict[str, Any]) -> dict[str, Any]:
    """API Gateway HTTP API (payload format 2.0) response."""
    return {
        "statusCode": status,
        "headers": {"content-type": "application/json"},
        "body": json.dumps(body),
    }


def _parse_message(event: dict[str, Any]) -> str:
    raw = event.get("body") or ""
    if event.get("isBase64Encoded"):
        raise ValueError("send the request body as JSON text, not base64")
    try:
        payload = json.loads(raw)
    except json.JSONDecodeError as exc:
        raise ValueError("body must be JSON") from exc
    message = payload.get("message") if isinstance(payload, dict) else None
    if not isinstance(message, str) or not message.strip():
        raise ValueError('body must contain a non-empty "message" string')
    if len(message) > MAX_MESSAGE_CHARS:
        raise ValueError(f"message is longer than {MAX_MESSAGE_CHARS} characters")
    return message.strip()


def handler(event: dict[str, Any], context: Any, runtime: Any = None) -> dict[str, Any]:
    """Entry point. `runtime` lets unit tests inject a stubbed client."""
    client = runtime or _RUNTIME
    try:
        message = _parse_message(event)
    except ValueError as exc:
        return _response(400, {"error": str(exc)})

    request = {
        "modelId": os.environ["MODEL_ID"],
        "system": [{"text": SYSTEM_PROMPT}],
        "messages": [{"role": "user", "content": [{"text": message}]}],
        "inferenceConfig": {"maxTokens": int(os.environ.get("MAX_TOKENS", "512"))},
        "guardrailConfig": {
            "guardrailIdentifier": os.environ["GUARDRAIL_ID"],
            "guardrailVersion": os.environ["GUARDRAIL_VERSION"],
        },
    }

    try:
        result = client.converse(**request)
    except ClientError as exc:
        code = exc.response.get("Error", {}).get("Code", "Unknown")
        # Log the error class only: never log prompts or completions here.
        LOGGER.warning("Converse failed: %s", code)
        if code == "ThrottlingException":
            return _response(429, {"error": "busy, retry later"})
        if code in ("ValidationException", "AccessDeniedException", "ResourceNotFoundException"):
            return _response(502, {"error": "model configuration error"})
        return _response(502, {"error": "model unavailable"})

    blocks = result.get("output", {}).get("message", {}).get("content", [])
    text = "".join(block.get("text", "") for block in blocks)
    usage = result.get("usage", {})
    LOGGER.info(
        "stopReason=%s inputTokens=%s outputTokens=%s",
        result.get("stopReason"),
        usage.get("inputTokens"),
        usage.get("outputTokens"),
    )
    return _response(
        200,
        {
            "answer": text,
            "blockedByGuardrail": result.get("stopReason") == "guardrail_intervened",
            "usage": {
                "inputTokens": usage.get("inputTokens"),
                "outputTokens": usage.get("outputTokens"),
            },
        },
    )
