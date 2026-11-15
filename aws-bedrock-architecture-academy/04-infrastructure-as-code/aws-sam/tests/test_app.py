"""Unit tests for src/app.py. Nothing here calls AWS: the Bedrock Runtime client is stubbed.

Run from the aws-sam directory with a Python that has boto3 installed:
    python -m pytest tests -q
"""
from __future__ import annotations

import json
import os
import sys
from pathlib import Path

import boto3
import pytest
from botocore.stub import Stubber

# Configuration the SAM template would set. Placeholder values only.
os.environ.setdefault("AWS_DEFAULT_REGION", "us-east-1")
os.environ["MODEL_ID"] = "us.amazon.nova-2-lite-v1:0"
os.environ["GUARDRAIL_ID"] = "arn:aws:bedrock:us-east-1:111122223333:guardrail/abcd1234efgh"
os.environ["GUARDRAIL_VERSION"] = "1"
os.environ["MAX_TOKENS"] = "256"

sys.path.insert(0, str(Path(__file__).resolve().parent.parent / "src"))
import app  # noqa: E402  (import after the environment is prepared)


def _event(body: object) -> dict:
    return {"body": json.dumps(body), "isBase64Encoded": False}


def _converse_response(text: str, stop_reason: str = "end_turn") -> dict:
    return {
        "output": {"message": {"role": "assistant", "content": [{"text": text}]}},
        "stopReason": stop_reason,
        "usage": {"inputTokens": 12, "outputTokens": 7, "totalTokens": 19},
        "metrics": {"latencyMs": 100},
    }


@pytest.fixture()
def stubbed():
    client = boto3.client("bedrock-runtime", region_name="us-east-1")
    with Stubber(client) as stub:
        yield client, stub
        stub.assert_no_pending_responses()


def test_happy_path_sends_guardrail_and_model_from_environment(stubbed):
    client, stub = stubbed
    expected_params = {
        "modelId": "us.amazon.nova-2-lite-v1:0",
        "system": [{"text": app.SYSTEM_PROMPT}],
        "messages": [{"role": "user", "content": [{"text": "Hello"}]}],
        "inferenceConfig": {"maxTokens": 256},
        "guardrailConfig": {
            "guardrailIdentifier": os.environ["GUARDRAIL_ID"],
            "guardrailVersion": "1",
        },
    }
    stub.add_response("converse", _converse_response("Hi there."), expected_params)

    result = app.handler(_event({"message": "  Hello  "}), None, runtime=client)

    assert result["statusCode"] == 200
    body = json.loads(result["body"])
    assert body["answer"] == "Hi there."
    assert body["blockedByGuardrail"] is False
    assert body["usage"] == {"inputTokens": 12, "outputTokens": 7}


def test_guardrail_intervention_is_reported(stubbed):
    client, stub = stubbed
    stub.add_response(
        "converse", _converse_response("Sorry, I can't help with that.", "guardrail_intervened")
    )
    body = json.loads(app.handler(_event({"message": "x"}), None, runtime=client)["body"])
    assert body["blockedByGuardrail"] is True


def test_throttling_maps_to_429(stubbed):
    client, stub = stubbed
    stub.add_client_error("converse", service_error_code="ThrottlingException", http_status_code=429)
    assert app.handler(_event({"message": "x"}), None, runtime=client)["statusCode"] == 429


def test_access_denied_maps_to_502(stubbed):
    client, stub = stubbed
    stub.add_client_error("converse", service_error_code="AccessDeniedException", http_status_code=403)
    assert app.handler(_event({"message": "x"}), None, runtime=client)["statusCode"] == 502


@pytest.mark.parametrize(
    "event",
    [
        {"body": "not json"},
        _event({"message": ""}),
        _event({"text": "wrong key"}),
        _event({"message": "x" * (app.MAX_MESSAGE_CHARS + 1)}),
        {"body": "eyJtZXNzYWdlIjoiaGkifQ==", "isBase64Encoded": True},
    ],
)
def test_bad_requests_never_reach_bedrock(stubbed, event):
    client, _ = stubbed  # no responses queued: any call would raise
    assert app.handler(event, None, runtime=client)["statusCode"] == 400
