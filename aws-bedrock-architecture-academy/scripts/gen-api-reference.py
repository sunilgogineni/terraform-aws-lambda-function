#!/usr/bin/env python3
"""Generate the Bedrock API operation reference from the AWS SDK's own service models.

botocore (the library under boto3) ships one JSON model per AWS service. Those
models are published by AWS and list every operation, its HTTP binding and its
request and response members. Reading them answers "does this operation exist,
which endpoint is it on, and what are its top-level fields?" mechanically.

Output: references/bedrock-api-operations.md         (human-readable)
        references/bedrock-api-operations.json        (operations with top-level members)

Usage: python3 scripts/gen-api-reference.py           (run with a Python that has botocore installed)
"""
from __future__ import annotations

import gzip
import json
import re
import sys
from datetime import date
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
MATCH = re.compile(r"^(bedrock|agent-registry|s3vectors)")
DESCRIPTIONS = {
    "bedrock": "Control plane: models, customization, guardrails, evaluation, inference profiles, Provisioned Throughput, batch jobs, logging",
    "bedrock-runtime": "Inference data plane: Converse, InvokeModel, ApplyGuardrail, async invoke, token counting",
    "bedrock-agent": "Build time for Agents Classic, knowledge bases, data sources, flows and prompts",
    "bedrock-agent-runtime": "Run time for Agents Classic, knowledge base retrieval, agentic retrieval, flows, reranking, sessions",
    "bedrock-agentcore-control": "AgentCore control plane: runtimes, harnesses, gateways, memory, identity, policy, evaluations",
    "bedrock-agentcore": "AgentCore data plane: invoke runtimes and harnesses, memory events, tokens, code interpreter, browser",
    "bedrock-data-automation": "Bedrock Data Automation build time: projects, blueprints, libraries",
    "bedrock-data-automation-runtime": "Bedrock Data Automation run time: invoke and status",
    "agent-registry-control": "AWS Agent Registry control plane",
    "agent-registry": "AWS Agent Registry data plane (discovery)",
    "s3vectors": "Amazon S3 Vectors: vector buckets, indexes and vector operations",
}


def load(path: Path) -> dict:
    opener = gzip.open if path.suffix == ".gz" else open
    with opener(path, "rt", encoding="utf-8") as fh:
        return json.load(fh)


def members(model: dict, shape_name: str | None) -> tuple[list[str], list[str]]:
    if not shape_name:
        return [], []
    shape = model["shapes"].get(shape_name, {})
    required = sorted(shape.get("required", []))
    optional = sorted(m for m in shape.get("members", {}) if m not in required)
    return required, optional


def main() -> int:
    try:
        import botocore
    except ImportError:
        print("botocore is not installed in this Python environment (pip install boto3).")
        return 2
    data_dir = Path(botocore.__file__).parent / "data"
    services = sorted(p.name for p in data_dir.iterdir() if p.is_dir() and MATCH.match(p.name))
    today = date.today().isoformat()
    out_json: dict = {"botocore": botocore.__version__, "generated": today, "services": {}}
    md = [
        "# Amazon Bedrock API operations",
        "",
        f"> **Generated from the AWS SDK's service models** — `botocore` **{botocore.__version__}**, on {today}.",
        "> Regenerate with `scripts/gen-api-reference.py`; do not edit by hand.",
        "",
        "Every operation the SDK knows for the Bedrock family of services, with its HTTP binding. "
        "Use it to check that an operation exists, which service namespace it belongs to, and what its "
        "request fields are called. Top-level request and response members for every operation are in "
        "[`bedrock-api-operations.json`](bedrock-api-operations.json).",
        "",
        "[References](README.md) · [Feature verification matrix](../FEATURE-VERIFICATION.md) · "
        "[What Amazon Bedrock is: services, namespaces and planes](../01-amazon-bedrock/overview/01-what-is-amazon-bedrock.md)",
        "",
        "> [!IMPORTANT]",
        "> **Status** — The OpenAI-compatible and Anthropic-compatible APIs (Responses, Chat Completions, "
        "Messages) and the `bedrock-mantle` endpoint are **not** modelled in the AWS SDK, so they do not "
        "appear here. They are documented in "
        "[Endpoints, APIs and authentication](../01-amazon-bedrock/overview/02-endpoints-apis-and-authentication.md).",
        "",
        "## Services",
        "",
        "| SDK service name | Endpoint prefix | SigV4 signing name | API version | Operations | What it is for |",
        "|:--|:--|:--|:--|--:|:--|",
    ]
    sections: list[str] = []
    for svc in services:
        versions = sorted(p.name for p in (data_dir / svc).iterdir() if p.is_dir())
        if not versions:
            continue
        version = versions[-1]
        files = list((data_dir / svc / version).glob("service-2.json*"))
        if not files:
            continue
        model = load(files[0])
        meta = model["metadata"]
        ops = model["operations"]
        md.append(
            f"| `{svc}` | `{meta.get('endpointPrefix', '')}` | `{meta.get('signingName', meta.get('endpointPrefix', ''))}` | "
            f"{version} | {len(ops)} | {DESCRIPTIONS.get(svc, meta.get('serviceFullName', ''))} |"
        )
        svc_json: dict = {"apiVersion": version, "endpointPrefix": meta.get("endpointPrefix"),
                          "signingName": meta.get("signingName"), "operations": {}}
        sections += [f"## `{svc}`", "", f"{meta.get('serviceFullName', svc)} · {len(ops)} operations.", "",
                     "| Operation | HTTP | Path | Required request members |", "|:--|:--|:--|:--|"]
        for name in sorted(ops):
            op = ops[name]
            http = op.get("http", {})
            req, opt = members(model, (op.get("input") or {}).get("shape"))
            out_req, out_opt = members(model, (op.get("output") or {}).get("shape"))
            svc_json["operations"][name] = {
                "method": http.get("method"), "path": http.get("requestUri"),
                "request": {"required": req, "optional": opt},
                "response": sorted(out_req + out_opt),
            }
            req_cell = ", ".join(f"`{m}`" for m in req) if req else "—"
            sections.append(f"| `{name}` | {http.get('method', '')} | `{http.get('requestUri', '')}` | {req_cell} |")
        sections.append("")
        out_json["services"][svc] = svc_json
    md.append("")
    md += sections
    md += [
        "## How to use this",
        "",
        "```bash",
        "# Does an operation exist, and on which service?",
        "jq -r '.services | to_entries[] | .key as $s | .value.operations | keys[] | \"\\($s) \\(.)\"' \\",
        "  references/bedrock-api-operations.json | grep -i retrieve",
        "",
        "# What are the request fields of Converse?",
        "jq '.services[\"bedrock-runtime\"].operations.Converse.request' references/bedrock-api-operations.json",
        "```",
        "",
        "The IAM action for an operation is usually `<signing name>:<Operation>`, but not always — Converse, "
        "for example, is authorised by `bedrock:InvokeModel`. Check the operation's page in the API reference.",
        "",
    ]
    ref = ROOT / "references"
    (ref / "bedrock-api-operations.md").write_text("\n".join(md), encoding="utf-8")
    (ref / "bedrock-api-operations.json").write_text(json.dumps(out_json, indent=1, sort_keys=True) + "\n", encoding="utf-8")
    total = sum(len(s["operations"]) for s in out_json["services"].values())
    print(f"Wrote references/bedrock-api-operations.md and .json ({len(out_json['services'])} services, {total} operations)")
    return 0


if __name__ == "__main__":
    sys.exit(main())
