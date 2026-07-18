# Agent notes

This repository is the public connection kit for Reanthesis: the Agent Skill,
client plugins, and the documentation for the hosted MCP server at
`https://reanthesis.com/mcp`. The server itself is not here — its source of
truth (tool definitions, OAuth surface, scope enforcement) lives in the
private Reanthesis API. Nothing in this repo runs on a user's machine.

## Layout

| Path | Purpose |
| --- | --- |
| `skills/reanthesis/` | The Agent Skill: `SKILL.md` (kept under 50 lines) plus `references/` loaded on demand |
| `plugins/claude-code/` | Claude Code plugin: symlinked skill + bundled HTTP connector (`.mcp.json`) |
| `plugins/codex/`, `plugins/copilot/` | Plugins with real copies of the skill |
| `.claude-plugin/`, `.agents/`, `.github/plugin/` | Host marketplace manifests |
| `docs/` | Public tool contract and authentication documentation |
| `tests/plugins.test.sh` | Layout, skill-format, doc-staleness, and install drift alarms |

The tool list is 13 names. When the API's tool definitions change, update
`docs/mcp-tools.md` and the skill in the same commit — stale docs are release
blockers here, not cleanup.

## Plugin file discipline

The Claude Code plugin's `skills/reanthesis` entry is a symlink into the root
`skills/` directory; Claude Code follows it during plugin loading.

The Codex and Copilot plugins each carry a real byte-for-byte copy of the
skill directory. Codex's plugin cache drops symlinks and can install a linked
skill as an empty directory. When the drift test fails, re-copy:

```sh
rm -rf plugins/codex/skills/reanthesis plugins/copilot/skills/reanthesis
cp -R skills/reanthesis plugins/codex/skills/
cp -R skills/reanthesis plugins/copilot/skills/
```

## Checks

```sh
bash tests/plugins.test.sh
```

Validates the skill's frontmatter and size budget, symlinks, plugin copies,
manifest JSON, marketplace source objects, doc-staleness tripwires (no stdio
or npx claims may reappear), and — when Codex CLI is installed — a live
marketplace install with skill discovery.

## Release checklist

1. Keep plugin manifest versions in sync across all three plugins.
2. Run `bash tests/plugins.test.sh`.
3. Reread README and docs against the deployed server: tool names, argument
   names, and auth claims must match what `https://reanthesis.com/mcp`
   actually serves.
4. Tag the release after the checks pass.
