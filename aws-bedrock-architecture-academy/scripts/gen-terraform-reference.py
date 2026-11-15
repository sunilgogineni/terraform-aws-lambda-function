#!/usr/bin/env python3
"""Generate the Bedrock-related Terraform reference from the REAL provider schema.

Input : the output of `terraform providers schema -json` for a root module that
        pins hashicorp/aws (see references/README.md for the exact commands).
Output: references/terraform-aws-provider-bedrock.md          (human-readable)
        references/terraform-aws-provider-bedrock-schema.json  (compact, for tooling)

Nothing here is written from memory: every resource type, argument and nested
block listed comes straight out of the provider binary's own schema.

Usage: python3 scripts/gen-terraform-reference.py SCHEMA.json PROVIDER_VERSION
Standard library only.
"""
from __future__ import annotations

import json
import re
import sys
from datetime import date
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
PROVIDER = "registry.terraform.io/hashicorp/aws"
MATCH = re.compile(r"^aws_(bedrock|bedrockagent|bedrockagentcore|bedrockdataautomation|bedrockruntime|agentregistry|s3vectors|opensearchserverless)_")
KINDS = [
    ("resource_schemas", "Resources", "resource"),
    ("data_source_schemas", "Data sources", "data source"),
    ("ephemeral_resource_schemas", "Ephemeral resources", "ephemeral resource"),
    ("list_resource_schemas", "List resources (for `terraform query`)", "list resource"),
    ("action_schemas", "Actions", "action"),
]
FAMILIES = [
    ("aws_bedrock_", "Amazon Bedrock control plane (`bedrock`)"),
    ("aws_bedrockagent_", "Agents Classic, Knowledge Bases, Flows, Prompts (`bedrock-agent`)"),
    ("aws_bedrockagentcore_", "Amazon Bedrock AgentCore (`bedrock-agentcore-control`)"),
    ("aws_bedrockdataautomation_", "Amazon Bedrock Data Automation"),
    ("aws_bedrockruntime_", "Bedrock Runtime"),
    ("aws_agentregistry_", "AWS Agent Registry (`agent-registry-control`)"),
    ("aws_s3vectors_", "Amazon S3 Vectors (vector store for Knowledge Bases)"),
    ("aws_opensearchserverless_", "Amazon OpenSearch Serverless (vector store for Knowledge Bases)"),
]


def compact_block(block: dict) -> dict:
    """Reduce a schema block to names, requiredness and nesting."""
    out: dict = {"attributes": {}, "blocks": {}}
    if block.get("deprecated"):
        out["deprecated"] = True
    for name, attr in sorted((block.get("attributes") or {}).items()):
        flags = []
        if attr.get("required"):
            flags.append("required")
        if attr.get("optional"):
            flags.append("optional")
        if attr.get("computed"):
            flags.append("computed")
        if attr.get("sensitive"):
            flags.append("sensitive")
        if attr.get("write_only"):
            flags.append("write_only")
        if attr.get("deprecated"):
            flags.append("deprecated")
        out["attributes"][name] = ",".join(flags)
    for name, nested in sorted((block.get("block_types") or {}).items()):
        child = compact_block(nested.get("block") or {})
        child["nesting_mode"] = nested.get("nesting_mode")
        if nested.get("min_items"):
            child["min_items"] = nested["min_items"]
        if nested.get("max_items"):
            child["max_items"] = nested["max_items"]
        out["blocks"][name] = child
    return out


def summarize(block: dict) -> tuple[list[str], list[str], list[str]]:
    required, optional = [], []
    for name, flags in block["attributes"].items():
        parts = flags.split(",")
        if "required" in parts:
            required.append(name)
        elif "optional" in parts:
            optional.append(name)
    return required, optional, list(block["blocks"].keys())


def main(argv: list[str]) -> int:
    if len(argv) != 2:
        print(__doc__)
        return 2
    schema_path, version = Path(argv[0]), argv[1]
    schema = json.loads(schema_path.read_text(encoding="utf-8"))["provider_schemas"][PROVIDER]

    compact: dict = {"provider": "hashicorp/aws", "version": version, "generated": date.today().isoformat()}
    md: list[str] = [
        "# Terraform AWS provider — Bedrock-related resources",
        "",
        f"> **Generated from the provider's own schema** — `hashicorp/aws` **{version}**, "
        f"`terraform providers schema -json`, on {date.today().isoformat()}.",
        "> Regenerate with `scripts/gen-terraform-reference.py`; do not edit by hand.",
        "",
        "Use this file to answer one question quickly: *does a Terraform resource exist for this "
        "Bedrock feature, and what are its top-level arguments?* If a type is not listed here, it does "
        f"not exist in provider {version}. The full nested structure is in "
        "[`terraform-aws-provider-bedrock-schema.json`](terraform-aws-provider-bedrock-schema.json).",
        "",
        "Related chapters: [Terraform coverage for Amazon Bedrock](../04-infrastructure-as-code/terraform/10-terraform-for-bedrock.md) · "
        "[Feature verification matrix](../FEATURE-VERIFICATION.md)",
        "",
        "## Summary",
        "",
        "| Kind | Bedrock-related types |",
        "|:--|--:|",
    ]
    per_kind: dict[str, dict[str, dict]] = {}
    for key, label, _noun in KINDS:
        entries = {n: compact_block(v.get("block") or {}) for n, v in (schema.get(key) or {}).items() if MATCH.match(n)}
        per_kind[key] = entries
        compact[key] = entries
        md.append(f"| {label} | {len(entries)} |")
    md.append("")

    for key, label, _noun in KINDS:
        entries = per_kind[key]
        if not entries:
            continue
        md += [f"## {label}", ""]
        for prefix, family in FAMILIES:
            names = sorted(n for n in entries if n.startswith(prefix))
            if not names:
                continue
            md += [f"### {family}", "", "| Type | Required arguments | Optional arguments | Nested blocks |", "|:--|:--|:--|:--|"]
            for name in names:
                required, optional, blocks = summarize(entries[name])
                fmt = lambda xs: ", ".join(f"`{x}`" for x in xs) if xs else "—"  # noqa: E731
                label = f"`{name}` ⚠️ **deprecated**" if entries[name].get("deprecated") else f"`{name}`"
                md.append(f"| {label} | {fmt(required)} | {fmt(optional)} | {fmt(blocks)} |")
            md.append("")

    md += [
        "## How to read this",
        "",
        "- **Required / optional** come from the schema flags. Computed-only attributes (outputs) are omitted from the table but are in the JSON.",
        "- A **nested block** such as `knowledge_base_configuration` has its own arguments; look it up in the JSON file.",
        "- The schema says what Terraform accepts, not what the AWS API accepts in every Region or for every model. "
        "Always pair it with the AWS documentation for the feature.",
        "- **List resources** are used with `terraform query` (Terraform 1.14+) to discover existing resources for import.",
        "- ⚠️ **deprecated** means the provider schema itself flags the resource as deprecated; prefer its replacement.",
        "",
    ]

    ref_dir = ROOT / "references"
    ref_dir.mkdir(exist_ok=True)
    (ref_dir / "terraform-aws-provider-bedrock.md").write_text("\n".join(md), encoding="utf-8")
    (ref_dir / "terraform-aws-provider-bedrock-schema.json").write_text(
        json.dumps(compact, indent=1, sort_keys=True) + "\n", encoding="utf-8"
    )
    total = sum(len(v) for v in per_kind.values())
    print(f"Wrote references/terraform-aws-provider-bedrock.md and -schema.json ({total} types)")
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
