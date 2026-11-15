#!/usr/bin/env python3
"""Audit API operation names used in the academy against the AWS SDK's models.

Scans Markdown for inline-code tokens that look like API operations
(`Converse`, `CreateKnowledgeBase`, `InvokeAgentRuntime` ...) and classifies
each one:

* known Bedrock-family operation  (in references/bedrock-api-operations.json)
* known operation of another AWS service (only if botocore is installed)
* UNKNOWN — not found in any SDK model: either a typo, an invented name, an
  operation newer than the SDK snapshot, or something that is not an AWS API
  (those can be added to ALLOW below with a reason)

Usage: python3 scripts/check-api-names.py [PATH ...] [--strict] [--list-known]
       --strict exits 1 if any UNKNOWN token is found.
"""
from __future__ import annotations

import gzip
import json
import os
import re
import sys
from collections import defaultdict
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
SKIP_DIRS = {"node_modules", ".terraform", "cdk.out", ".git", ".venv", "__pycache__", ".validation", "rendered", "references"}
VERBS = (
    "Create", "Get", "List", "Update", "Delete", "Invoke", "Start", "Stop", "Retrieve", "Converse", "Apply",
    "Put", "Batch", "Tag", "Untag", "Associate", "Disassociate", "Prepare", "Rerank", "Generate", "Optimize",
    "Ingest", "Synchronize", "Search", "Evaluate", "Process", "Complete", "Count", "Validate", "Export",
    "Register", "Deregister", "Submit", "Save", "End", "Check", "Cancel", "Agentic", "Describe", "Assume",
    "Send", "Receive", "Publish", "Subscribe", "Encrypt", "Decrypt", "Detect", "Enable", "Disable", "Query", "Scan",
)
TOKEN_RE = re.compile(r"`([A-Z][A-Za-z0-9]{3,60})`")
# Things that match the heuristic but are not AWS API operations.
ALLOW = {
    # CloudFormation / CDK / Terraform / general vocabulary
    "GetAtt", "CreateChangeSet", "ListResources", "CreateStack", "UpdateStack", "DeleteStack",
    "PutEvents",  # EventBridge operation, kept for environments without botocore
    "StartOnLoad", "CountTokensExample", "GetParameter", "GetSecretValue", "AssumeRole", "AssumeRoleWithWebIdentity",
    "PutObject", "GetObject", "ListBucket", "DeleteObject", "PutItem", "GetItem", "Query", "Scan", "SendMessage",
    "ReceiveMessage", "Publish", "Encrypt", "Decrypt", "GenerateDataKey", "DescribeKey", "CreateGrant",
    "StartExecution", "StartSyncExecution", "PutRecord", "PutRecords", "PutMetricData", "PutLogEvents",
    "CreateLogStream", "CreateLogGroup", "DescribeLogGroups", "GetCallerIdentity", "CreateNetworkInterface",
    "DescribeNetworkInterfaces", "DeleteNetworkInterface", "PutUseCaseForModelAccess",
    # IAM actions of endpoints that are not modelled in the AWS SDK (bedrock-mantle, bedrock-websearch).
    # They are documented on the Bedrock "Endpoints" and "Web Search" pages, not in an SDK model.
    "CreateInference", "GetInference", "DeleteInference", "CancelInference", "InvokeSearch", "InvokeFetch",
    # IAM actions for responses stored by the OpenAI-compatible Responses API on bedrock-runtime.
    # Documented at https://docs.aws.amazon.com/bedrock/latest/userguide/inference-prereq.html
    "GetInvoke", "CancelInvoke", "DeleteInvoke",
    # IAM action for IAM-authorised AgentCore gateways (gateways are called over MCP, not an SDK operation).
    # Documented at https://docs.aws.amazon.com/bedrock-agentcore/latest/devguide/gateway-inbound-auth.html
    "InvokeGateway",
    # AgentCore Runtime WebSocket operations; the AWS SDK models do not describe WebSocket APIs.
    "InvokeAgentRuntimeWithWebSocketStream", "InvokeAgentRuntimeCommandShell",
    # Neptune Analytics IAM actions used by GraphRAG knowledge-base service roles.
    "ReadDataViaQuery", "WriteDataViaQuery", "DeleteDataViaQuery",
    # Name used in AgentCore release notes; the chapter explains that the API is CreateGatewayRateLimit.
    "CreateRateLimit",
}


def load_bedrock() -> dict[str, list[str]]:
    path = ROOT / "references" / "bedrock-api-operations.json"
    data = json.loads(path.read_text(encoding="utf-8"))
    ops: dict[str, list[str]] = defaultdict(list)
    for svc, body in data["services"].items():
        for name in body["operations"]:
            ops[name].append(svc)
    return ops


def load_all_aws() -> dict[str, str]:
    """Operation name -> one service that has it, from every installed botocore model."""
    try:
        import botocore
    except ImportError:
        return {}
    ops: dict[str, str] = {}
    data_dir = Path(botocore.__file__).parent / "data"
    for svc_dir in data_dir.iterdir():
        if not svc_dir.is_dir():
            continue
        versions = sorted(p for p in svc_dir.iterdir() if p.is_dir())
        if not versions:
            continue
        files = list(versions[-1].glob("service-2.json*"))
        if not files:
            continue
        opener = gzip.open if files[0].suffix == ".gz" else open
        try:
            with opener(files[0], "rt", encoding="utf-8") as fh:
                model = json.load(fh)
        except (OSError, ValueError):
            continue
        for name in model.get("operations", {}):
            ops.setdefault(name, svc_dir.name)
    return ops


def main(argv: list[str]) -> int:
    strict = "--strict" in argv
    list_known = "--list-known" in argv
    targets = [Path(a).resolve() for a in argv if not a.startswith("--")] or [ROOT]
    bedrock = load_bedrock()
    everything = load_all_aws()

    seen: dict[str, set[str]] = defaultdict(set)
    for target in targets:
        files = [target] if target.is_file() else []
        if target.is_dir():
            for dirpath, dirnames, filenames in os.walk(target):
                dirnames[:] = [d for d in dirnames if d not in SKIP_DIRS]
                files += [Path(dirpath) / n for n in filenames if n.endswith(".md")]
        for path in files:
            rel = path.relative_to(ROOT).as_posix() if ROOT in path.parents else str(path)
            for token in TOKEN_RE.findall(path.read_text(encoding="utf-8")):
                # An operation name has at least two capitalised words ("CreateAgent"); single words
                # such as "Completed" or "Stopped" are states, unless they are real one-word operations.
                multi_word = sum(1 for ch in token if ch.isupper()) >= 2
                if token.startswith(VERBS) and (multi_word or token in bedrock):
                    seen[token].add(rel)

    known_bedrock = {t for t in seen if t in bedrock}
    known_other = {t for t in seen if t not in bedrock and (t in everything or t in ALLOW)}
    unknown = sorted(t for t in seen if t not in known_bedrock and t not in known_other)

    print(f"Operation-like tokens found   : {len(seen)}")
    print(f"Bedrock-family operations     : {len(known_bedrock)}")
    print(f"Other AWS / allow-listed      : {len(known_other)}")
    print(f"UNKNOWN (review)              : {len(unknown)}")
    if not everything:
        print("  note: botocore not installed here, so operations of other AWS services cannot be recognised")
    if list_known:
        for t in sorted(known_bedrock):
            print(f"  ok   {t}  [{', '.join(bedrock[t])}]")
    for t in unknown:
        files = sorted(seen[t])
        print(f"  REVIEW {t}  <- {files[0]}" + (f" (+{len(files) - 1} more)" if len(files) > 1 else ""))
    return 1 if (strict and unknown) else 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
