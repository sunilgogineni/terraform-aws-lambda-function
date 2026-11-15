#!/usr/bin/env python3
"""Scan the academy for accidentally committed credentials and personal data.

This is a simple, dependency-free safety net, not a replacement for a
dedicated scanner (gitleaks, trufflehog, detect-secrets) in CI.

Flags:
* AWS access key IDs (AKIA/ASIA/...) other than AWS's documented example key
* assignments that look like secret access keys, session tokens or passwords
* private key blocks
* common vendor tokens (GitHub, Slack, Stripe-style, bearer tokens)
* 12-digit AWS account IDs that are not well-known documentation placeholders
* e-mail addresses outside example domains

Usage: python3 scripts/scan-secrets.py [DIR ...]
Exit code 1 if anything is flagged.
"""
from __future__ import annotations

import os
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
SKIP_DIRS = {"node_modules", ".terraform", "cdk.out", ".git", ".venv", "__pycache__", ".validation", "rendered"}
SKIP_FILES = {"package-lock.json", "scan-secrets.py"}
TEXT_SUFFIXES = {
    ".md", ".tf", ".tfvars", ".hcl", ".example", ".json", ".yaml", ".yml", ".py", ".ts", ".js", ".cjs",
    ".mjs", ".sh", ".txt", ".toml", ".cfg", ".ini", ".rego", ".guard", ".puml", ".drawio", ".xml",
    ".env", ".sql", ".cedar", "",
}

# Placeholders used in AWS documentation and throughout this academy.
ALLOWED_ACCOUNT_IDS = {
    "111122223333", "444455556666", "777788889999", "123456789012", "999999999999",
    "000000000000", "012345678901", "210987654321", "555555555555", "111111111111", "222222222222",
    "333333333333", "444444444444", "666666666666",
}
ALLOWED_KEY_IDS = {"AKIAIOSFODNN7EXAMPLE", "AKIAI44QH8DHBEXAMPLE", "ASIAIOSFODNN7EXAMPLE"}
ALLOWED_EMAIL_DOMAINS = ("example.com", "example.org", "example.net", "amazonaws.com", "anthropic.com", "users.noreply.github.com")

PATTERNS: list[tuple[str, re.Pattern[str]]] = [
    ("AWS access key ID", re.compile(r"\b(?:AKIA|ASIA|AIDA|AROA|AGPA|ANPA|AIPA)[A-Z0-9]{16}\b")),
    ("AWS secret access key", re.compile(r"(?i)aws_?secret_?access_?key\s*[=:]\s*[\"']?([A-Za-z0-9/+=]{40})\b")),
    ("AWS session token", re.compile(r"(?i)aws_?session_?token\s*[=:]\s*[\"']?([A-Za-z0-9/+=]{60,})")),
    ("private key block", re.compile(r"-----BEGIN (?:RSA |EC |OPENSSH |DSA |PGP )?PRIVATE KEY-----")),
    ("GitHub token", re.compile(r"\b(?:ghp|gho|ghu|ghs|ghr)_[A-Za-z0-9]{36,}\b|\bgithub_pat_[A-Za-z0-9_]{60,}\b")),
    ("Slack token", re.compile(r"\bxox[abprs]-[A-Za-z0-9-]{10,}\b")),
    ("API key (sk- style)", re.compile(r"\bsk-(?:ant-|proj-|live-)?[A-Za-z0-9_-]{32,}\b")),
    ("Bedrock API key", re.compile(r"\bABSK[A-Za-z0-9+/=]{40,}\b")),
    ("hard-coded password", re.compile(r"(?i)\b(?:password|passwd|secret|api_?key|token)\s*[=:]\s*[\"']([^\"'\s${}<>]{8,})[\"']")),
]
PLACEHOLDER_RE = re.compile(
    r"(?i)(example|placeholder|changeme|change-me|replace|your[-_ ]|dummy|redacted|xxxx|\*\*\*\*|<[^>]+>|\$\{|var\.|local\.|"
    r"secretsmanager|ssm:|resolve:|arn:aws|not-a-real|test-only|fake|sample|null|none|true|false)"
)
ACCOUNT_RE = re.compile(r"(?<![\d.])(\d{12})(?![\d.])")
ACCOUNT_CONTEXT_RE = re.compile(r"(?i)(arn:aws|account|acct|owner|principal|::\d{12}:|role/|\.dkr\.ecr\.)")
EMAIL_RE = re.compile(r"\b[A-Za-z0-9._%+-]+@([A-Za-z0-9.-]+\.[A-Za-z]{2,})\b")


def scan_file(path: Path) -> list[str]:
    findings: list[str] = []
    try:
        text = path.read_text(encoding="utf-8")
    except (UnicodeDecodeError, OSError):
        return findings
    for lineno, line in enumerate(text.splitlines(), start=1):
        for label, pattern in PATTERNS:
            for m in pattern.finditer(line):
                value = m.group(1) if m.groups() else m.group(0)
                if label == "AWS access key ID" and m.group(0) in ALLOWED_KEY_IDS:
                    continue
                if label == "hard-coded password" and PLACEHOLDER_RE.search(value):
                    continue
                findings.append(f"{lineno}: {label}: {value[:6]}…")
        if ACCOUNT_CONTEXT_RE.search(line):
            for m in ACCOUNT_RE.finditer(line):
                if m.group(1) not in ALLOWED_ACCOUNT_IDS:
                    findings.append(f"{lineno}: AWS account ID that is not a documentation placeholder: {m.group(1)}")
        for m in EMAIL_RE.finditer(line):
            domain = m.group(1).lower()
            if not domain.endswith(ALLOWED_EMAIL_DOMAINS) and "@types" not in line and "npm" not in line.lower():
                findings.append(f"{lineno}: e-mail address outside example domains: {m.group(0)}")
    return findings


def main(argv: list[str]) -> int:
    targets = [Path(a).resolve() for a in argv] or [ROOT]
    scanned = flagged = 0
    for target in targets:
        for dirpath, dirnames, filenames in os.walk(target):
            dirnames[:] = [d for d in dirnames if d not in SKIP_DIRS]
            for name in sorted(filenames):
                path = Path(dirpath) / name
                if name in SKIP_FILES or path.suffix.lower() not in TEXT_SUFFIXES:
                    continue
                scanned += 1
                findings = scan_file(path)
                if findings:
                    flagged += 1
                    rel = path.relative_to(ROOT) if ROOT in path.parents else path
                    for f in findings:
                        print(f"FLAG {rel}:{f}")
    print(f"Files scanned : {scanned}")
    print(f"Files flagged : {flagged}")
    return 1 if flagged else 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
