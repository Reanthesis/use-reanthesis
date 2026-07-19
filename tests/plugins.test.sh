#!/usr/bin/env bash
set -euo pipefail

ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)

python3 - "$ROOT" <<'PY'
import json
import pathlib
import sys

root = pathlib.Path(sys.argv[1])
source = root / "skills" / "reanthesis"
codex = root / "plugins" / "codex" / "skills" / "reanthesis"
codex_plugin = root / "plugins" / "codex"
copilot = root / "plugins" / "copilot" / "skills" / "reanthesis"
claude_skills = root / "plugins" / "claude-code" / "skills"

assert source.is_dir(), f"missing source skill: {source}"

# Agent Skills format (agentskills.io): frontmatter name matches the directory,
# description is non-empty and within budget, SKILL.md stays lean with detail
# in references/ that SKILL.md actually links.
skill_lines = (source / "SKILL.md").read_text().splitlines()
assert skill_lines[0] == "---" and "---" in skill_lines[1:], "SKILL.md missing frontmatter"
front = dict(
    line.split(":", 1)
    for line in skill_lines[1 : skill_lines[1:].index("---") + 1]
    if ":" in line
)
assert front["name"].strip() == source.name, "skill name must match its directory"
assert 0 < len(front["description"].strip()) <= 1024, "bad skill description"
assert len(skill_lines) <= 50, f"SKILL.md is {len(skill_lines)} lines; keep it under 50"
skill_text = "\n".join(skill_lines)
for reference in sorted((source / "references").glob("*.md")):
    assert f"references/{reference.name}" in skill_text, (
        f"{reference.name} exists but SKILL.md never links it"
    )

# Staleness tripwires: this repo describes the hosted connector only. If these
# words reappear, the docs have drifted back to the retired stdio design.
for doc in [root / "README.md", *sorted((root / "docs").glob("*.md")), *source.rglob("*.md")]:
    text = doc.read_text()
    for banned in ("stdio", "npx", "file_path", "credentials.json"):
        assert banned not in text, f"{doc.relative_to(root)} mentions '{banned}'"
assert codex.is_dir() and not codex.is_symlink(), (
    "Codex plugin skill must be a real directory"
)
codex_manifest = json.loads(
    (codex_plugin / ".codex-plugin" / "plugin.json").read_text()
)
assert codex_manifest["version"] == "1.0.1", "Codex plugin version was not bumped"
assert codex_manifest["mcpServers"] == "./.mcp.json", (
    "Codex plugin must declare its bundled MCP server"
)
codex_mcp = json.loads((codex_plugin / ".mcp.json").read_text())
assert codex_mcp == {
    "mcpServers": {
        "reanthesis": {
            "type": "http",
            "url": "https://reanthesis.com/mcp",
            "oauth_resource": "https://reanthesis.com/mcp",
        }
    }
}, "Codex plugin MCP config drifted"

def files(path: pathlib.Path) -> dict[str, bytes]:
    return {
        str(item.relative_to(path)): item.read_bytes()
        for item in sorted(path.rglob("*"))
        if item.is_file()
    }

assert files(codex) == files(source), (
    "plugins/codex/skills/reanthesis drifted from skills/reanthesis; "
    "re-copy the source skill"
)
assert copilot.is_dir() and files(copilot) == files(source), (
    "plugins/copilot/skills/reanthesis drifted from skills/reanthesis"
)

entries = list(claude_skills.iterdir())
assert entries, "Claude Code plugin has no skill entries"
for entry in entries:
    assert entry.is_symlink(), f"{entry.name} should be a symlink"
    assert entry.resolve() == source, (
        f"{entry.name} must resolve into skills/{entry.name}"
    )

marketplace = json.loads(
    (root / ".agents" / "plugins" / "marketplace.json").read_text()
)
entry = next(item for item in marketplace["plugins"] if item["name"] == "reanthesis")
assert entry["source"] == {"source": "local", "path": "./plugins/codex"}
assert "type" not in entry["source"]

manifest_roots = [root / ".claude-plugin", root / ".agents", root / ".github", root / "plugins"]
json_files = [
    item
    for base in manifest_roots
    for item in base.rglob("*.json")
    if item.is_file()
]
assert json_files, "no plugin manifests found"
for item in json_files:
    json.loads(item.read_text())

for script in [
    item
    for base in (root / "skills", root / "plugins")
    for item in base.rglob("scripts/*")
    if item.is_file()
]:
    assert script.stat().st_mode & 0o111, f"{script} lost its executable bit"

print("Static plugin checks passed")
PY

if ! command -v codex >/dev/null 2>&1; then
  echo "Codex CLI not installed; live install check skipped"
  exit 0
fi

CODEX_HOME=$(mktemp -d)
trap 'rm -rf "$CODEX_HOME"' EXIT
export CODEX_HOME

echo "Codex CLI detected: $(codex --version)"
codex plugin marketplace add "$ROOT"
codex plugin add reanthesis@reanthesis
codex debug prompt-input > "$CODEX_HOME/prompt-input.json"

python3 - "$CODEX_HOME/prompt-input.json" <<'PY'
import json
import pathlib
import sys

prompt_path = pathlib.Path(sys.argv[1])
prompt = prompt_path.read_text()
try:
    parsed = json.loads(prompt)
except json.JSONDecodeError:
    parsed = prompt
assert "reanthesis:reanthesis" in json.dumps(parsed), (
    "installed Reanthesis skill was not discovered"
)
print("Codex prompt-input contains reanthesis:reanthesis")
PY

echo "Codex marketplace install and skill discovery passed"
