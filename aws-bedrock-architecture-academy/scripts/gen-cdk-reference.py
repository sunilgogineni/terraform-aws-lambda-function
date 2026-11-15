#!/usr/bin/env python3
"""Generate the Bedrock-related AWS CDK / CloudFormation reference from an
INSTALLED aws-cdk-lib (and, if present, @aws-cdk/aws-bedrock-alpha).

The CDK's L1 constructs are generated from the CloudFormation resource
specification, so the `AWS::Bedrock::*` types found in the installed library
are the CloudFormation resource types that this CDK release knows about.

Output: references/cdk-and-cloudformation-bedrock.md

Usage: python3 scripts/gen-cdk-reference.py PATH/TO/node_modules
Standard library only.
"""
from __future__ import annotations

import json
import re
import sys
from datetime import date
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
MODULES = [
    ("aws-bedrock", "aws_bedrock", "Amazon Bedrock"),
    ("aws-bedrockagentcore", "aws_bedrockagentcore", "Amazon Bedrock AgentCore"),
    ("aws-bedrockmantle", "aws_bedrockmantle", "Amazon Bedrock (bedrock-mantle endpoint)"),
    ("aws-s3vectors", "aws_s3vectors", "Amazon S3 Vectors"),
    ("aws-opensearchserverless", "aws_opensearchserverless", "Amazon OpenSearch Serverless"),
]
L1_RE = re.compile(r'class (Cfn[A-Za-z0-9]+) extends.*?CFN_RESOURCE_TYPE_NAME\s*=\s*"(AWS::[A-Za-z0-9]+::[A-Za-z0-9]+)"', re.DOTALL)
CLASS_RE = re.compile(r"^export declare (?:abstract )?class ([A-Za-z0-9]+)", re.MULTILINE)
IFACE_RE = re.compile(r"^export interface (I[A-Z][A-Za-z0-9]+)\b", re.MULTILINE)


def classes_in(directory: Path) -> list[str]:
    names: set[str] = set()
    for dts in directory.rglob("*.d.ts"):
        if dts.name.endswith(".generated.d.ts"):
            continue
        names.update(CLASS_RE.findall(dts.read_text(encoding="utf-8", errors="ignore")))
    return sorted(n for n in names if not n.startswith("Cfn"))


def resource_classes(directory: Path) -> list[str]:
    """Classes that extend a *Base class or Resource: the deployable L2 constructs."""
    found: set[str] = set()
    pat = re.compile(r"^export declare class ([A-Za-z0-9]+) extends ([A-Za-z0-9_.]+)", re.MULTILINE)
    for dts in directory.rglob("*.d.ts"):
        if dts.name.endswith(".generated.d.ts"):
            continue
        for name, parent in pat.findall(dts.read_text(encoding="utf-8", errors="ignore")):
            if parent.endswith("Base") or parent.endswith("Resource") or parent.endswith("Construct"):
                found.add(name)
    return sorted(found)


def main(argv: list[str]) -> int:
    if len(argv) != 1:
        print(__doc__)
        return 2
    nm = Path(argv[0])
    lib = nm / "aws-cdk-lib"
    version = json.loads((lib / "package.json").read_text())["version"]
    today = date.today().isoformat()
    md: list[str] = [
        "# AWS CDK and CloudFormation — Bedrock-related constructs and resource types",
        "",
        f"> **Generated from the installed library** — `aws-cdk-lib` **{version}**, on {today}.",
        "> Regenerate with `scripts/gen-cdk-reference.py`; do not edit by hand.",
        "",
        "The CDK's L1 (`Cfn*`) constructs are generated from the CloudFormation resource specification, so "
        "the resource types below are the CloudFormation types this CDK release knows about. A type that is "
        "missing here may still exist in CloudFormation if it was released after this CDK version — check the "
        "[CloudFormation template reference](https://docs.aws.amazon.com/AWSCloudFormation/latest/TemplateReference/aws-template-resource-type-ref.html).",
        "",
        "Related chapters: [CDK coverage for Amazon Bedrock](../04-infrastructure-as-code/aws-cdk/09-cdk-for-bedrock.md) · "
        "[CloudFormation coverage for Amazon Bedrock](../04-infrastructure-as-code/cloudformation/07-cloudformation-for-bedrock.md) · "
        "[Feature verification matrix](../FEATURE-VERIFICATION.md)",
        "",
    ]
    counts: list[tuple[str, int, int]] = []
    body: list[str] = []
    for folder, alias, label in MODULES:
        mod = lib / folder
        if not mod.exists():
            continue
        l1: dict[str, str] = {}
        for js in (mod / "lib").glob("*.generated.js"):
            text = js.read_text(encoding="utf-8", errors="ignore")
            for cls, cfn in L1_RE.findall(text):
                l1[cfn] = cls
        l2 = resource_classes(mod / "lib")
        counts.append((label, len(l1), len(l2)))
        body += [f"## {label} — `aws-cdk-lib/{folder}`", "", f"Import: `import {{ {alias} }} from 'aws-cdk-lib';`", ""]
        body += ["### CloudFormation resource types and their L1 constructs", "", "| CloudFormation type | L1 construct |", "|:--|:--|"]
        for cfn in sorted(l1):
            body.append(f"| `{cfn}` | `{alias}.{l1[cfn]}` |")
        body.append("")
        if l2:
            body += [
                "### Higher-level (L2) constructs in the stable library",
                "",
                "These classes ship in `aws-cdk-lib` itself (stable, semantic-versioned API):",
                "",
                ", ".join(f"`{c}`" for c in l2),
                "",
            ]
        else:
            body += ["_No L2 resource constructs for this module in the stable library; use the L1 constructs above._", ""]

    alpha = nm / "@aws-cdk" / "aws-bedrock-alpha"
    if alpha.exists():
        aver = json.loads((alpha / "package.json").read_text())["version"]
        aclasses = resource_classes(alpha)
        body += [
            f"## Experimental L2 constructs — `@aws-cdk/aws-bedrock-alpha` {aver}",
            "",
            "> [!WARNING]",
            "> This package is **experimental**: its API can change in any release and it is versioned as "
            "`<cdk-version>-alpha.0`. Pin the exact version and expect breaking changes on upgrade.",
            "",
            ", ".join(f"`{c}`" for c in aclasses),
            "",
        ]

    md += ["## Summary", "", "| Module | CloudFormation types (L1) | Stable L2 resource constructs |", "|:--|--:|--:|"]
    for label, n1, n2 in counts:
        md.append(f"| {label} | {n1} | {n2} |")
    md.append("")
    md += body
    out = ROOT / "references" / "cdk-and-cloudformation-bedrock.md"
    out.write_text("\n".join(md), encoding="utf-8")
    print(f"Wrote {out.relative_to(ROOT)} (aws-cdk-lib {version})")
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
