#!/usr/bin/env bash
#
# scripts/sync-engine-config.sh — Synchronize engine settings between CLAUDE.md and ANTIGRAVITY.md
#
# When /setup-engine modifies CLAUDE.md, this script mirrors the Technology Stack
# and Engine Version Reference sections to ANTIGRAVITY.md (and vice-versa).
#
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

if [ ! -f "CLAUDE.md" ] || [ ! -f "ANTIGRAVITY.md" ]; then
  echo "Error: CLAUDE.md or ANTIGRAVITY.md missing in $ROOT" >&2
  exit 1
fi

python3 -c '
import re, sys

try:
    with open("CLAUDE.md", "r", encoding="utf-8") as f:
        claude = f.read()
    with open("ANTIGRAVITY.md", "r", encoding="utf-8") as f:
        anti = f.read()

    def get_section(text, heading):
        pattern = rf"(^## {re.escape(heading)}\b.*?)(?=\n## |\Z)"
        m = re.search(pattern, text, re.DOTALL | re.MULTILINE)
        return m.group(1).rstrip() if m else None

    claude_stack = get_section(claude, "Technology Stack")
    claude_engine_ref = get_section(claude, "Engine Version Reference")

    updated = False
    if claude_stack and "## Technology Stack" in anti:
        # Preserve trailing divider or spacing in anti
        anti = re.sub(
            r"^## Technology Stack\b.*?(?=\n---\n|\n## |\Z)",
            claude_stack,
            anti,
            count=1,
            flags=re.DOTALL | re.MULTILINE
        )
        updated = True

    if claude_engine_ref and "## Engine Version Reference" in anti:
        # Preserve any sync notice block in anti if present
        sync_notice_match = re.search(r"(> \*\*Engine Configuration Synchronization\*\*:.*?\n\n)", anti, re.DOTALL)
        sync_notice = ("\n\n" + sync_notice_match.group(1)) if sync_notice_match else ""
        
        replacement = claude_engine_ref + sync_notice
        anti = re.sub(
            r"^## Engine Version Reference\b.*?(?=\n---\n|\n## |\Z)",
            replacement,
            anti,
            count=1,
            flags=re.DOTALL | re.MULTILINE
        )
        updated = True

    if updated:
        with open("ANTIGRAVITY.md", "w", encoding="utf-8") as f:
            f.write(anti)
        print("[PASS] Synchronized Technology Stack and Engine Reference from CLAUDE.md to ANTIGRAVITY.md")
    else:
        print("[WARN] No matching sections found to synchronize.")
except Exception as e:
    print(f"[FAIL] Error synchronizing configs: {e}", file=sys.stderr)
    sys.exit(1)
'
