#!/usr/bin/env python3
"""
scripts/get-agent-def.py — Extract agent metadata and prompt for define_subagent.
Usage:
    python3 scripts/get-agent-def.py <agent-name> [--json]
"""
import sys
import os
import json
import re

def get_agent_def(name):
    # Strip any leading directory path or trailing extension if passed
    clean_name = os.path.basename(name)
    if clean_name.endswith(".md"):
        clean_name = clean_name[:-3]

    root = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
    path = os.path.join(root, ".agent", "agents", f"{clean_name}.md")
    if not os.path.exists(path):
        path = os.path.join(root, ".claude", "agents", f"{clean_name}.md")
    if not os.path.exists(path):
        print(f"Error: Agent spec not found for '{clean_name}' at {path}", file=sys.stderr)
        sys.exit(1)

    with open(path, "r", encoding="utf-8") as f:
        content = f.read()

    parts = re.split(r"^---\s*$", content, flags=re.MULTILINE)
    if len(parts) >= 3:
        frontmatter = parts[1]
        prompt = parts[2].strip()
    else:
        frontmatter = ""
        prompt = content.strip()

    desc_match = re.search(r'^description:\s*"?([^"\n\r]+)"?', frontmatter, re.MULTILINE)
    desc = desc_match.group(1).strip() if desc_match else f"Specialist subagent {clean_name}"

    # Lead and director agents get subagent delegation tools
    supervisory_roles = {
        "creative-director", "technical-director", "producer", "art-director",
        "narrative-director", "audio-director", "lead-programmer", "game-designer",
        "systems-designer", "level-designer", "qa-lead"
    }

    return {
        "name": clean_name,
        "description": desc,
        "system_prompt": prompt,
        "enable_write_tools": True,
        "enable_subagent_tools": clean_name in supervisory_roles,
        "enable_mcp_tools": True
    }

if __name__ == "__main__":
    if len(sys.argv) < 2 or sys.argv[1] in ("-h", "--help"):
        print("Usage: python3 scripts/get-agent-def.py <agent-name> [--json]")
        sys.exit(0)

    agent_data = get_agent_def(sys.argv[1])
    print(json.dumps(agent_data, indent=2, ensure_ascii=False))
