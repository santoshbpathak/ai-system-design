# BUILD.md — AI System Design

Briefing for whoever works on this repo next, human or AI.

## Current state (2026-11-21)
- Open-source repo for one skill, `ai-system-design`, in the open Agent Skills format (agentskills.io). It is agent-neutral: it must work in any coding agent, not just Claude Code. Public at https://github.com/santoshbpathak/ai-system-design (MIT), branch `main`.
- This repo is the source of truth. `bash install.sh` copies the skill into the skills folder of every agent found on the machine, plus the shared `~/.agents/skills/`; re-run it after any change here.
- `private/` is git-ignored. It holds `scope.md`, the talk transcript the skill was built from. It contains other people's names and must not be published.
- Unfinished: Windows is untested. No CI.
- Commits use the GitHub no-reply address (set in this repo's local git config) so no personal email is published.

## Module map
| Path | Responsibility |
|---|---|
| `skills/ai-system-design/SKILL.md` | The pre-flight process, five rules, pattern ladder, scaling ladder, red flags |
| `skills/ai-system-design/templates/ARCHITECTURE.md` | Blank 10-section file the skill fills in |
| `skills/ai-system-design/scripts/napkin.py` | LLM bill, cost per user or per tenant, margin, spend cap |
| `hooks/architecture-check.sh` | Claude Code only. SessionStart check: no ARCHITECTURE.md → run the skill; exists → read it |
| `lib-agents.sh` | The one list of supported agents: name, skills folder, and the folder that shows the agent is installed |
| `install.sh` / `uninstall.sh` | Copy the skill into each agent's folder (`--agent`, `--dir`, `--list`); `--project DIR` appends the always-check note to that project's `AGENTS.md`; for Claude Code also add or remove the hook entry in settings.json, with a backup |
| `AGENTS.md` | Rules for any agent working on this repo. `CLAUDE.md` only imports it. |
| `examples/ARCHITECTURE.example.md` | Filled-in example (made-up product, placeholder prices) |
| `README.md`, `CONTRIBUTING.md` | Written for builders who aren't engineers. Keep the plain language. |

## Golden numbers
- Calculator regression check: 5,000 DAU × 20 msgs × 30 days → 3.00M messages, 9.00B input tokens, 900.00M output tokens.
- Example file numbers (300 DAU, 6 msgs, 3000/300 tokens, $3/$15, caches 0.5/0.15, 10 tenants at $150): $729.00 without caching, $433.75 with, $43.38 per tenant, 71% margin, $867.51 cap.

## Golden facts: agent folders
Verified 2026-11-21 against the `vercel-labs/skills` docs (docs/agents.md) and this machine. Global skills folders: Claude Code `~/.claude/skills`; Codex, Cline, Zed, Warp `~/.agents/skills`; Cursor `~/.cursor/skills`; Gemini CLI `~/.gemini/skills`; GitHub Copilot `~/.copilot/skills`; OpenCode `~/.config/opencode/skills`; Windsurf `~/.codeium/windsurf/skills`; Goose `~/.config/goose/skills`. That tool finds this repo's `skills/<name>/SKILL.md` layout, so do not move the skill folder.

## Traps
- **Currency.** All calculator prices are USD; `--fx` only adds a display column. An earlier version read `--price-per-user` as local currency and produced margins like −2000%.
- **B2B.** Use `--tenants` with `--price-per-tenant`. Per-user pricing understates revenue for products sold per company.
- **Agent-specific paths in the skill.** `SKILL.md`, the template and the example once pointed at `~/.claude/skills/...`, which only exists for Claude Code users. Paths inside the skill are now relative to the skill's own folder (`scripts/napkin.py`, `templates/ARCHITECTURE.md`). Never put an agent's folder, slash command or another skill's name in those three files.
- **Only Claude Code has the startup hook.** Other agents get the same behaviour from the marked block that `install.sh --project` writes into the project's `AGENTS.md`, and from step 5 of the skill, which adds a read-ARCHITECTURE.md line to the project's agent instructions.
- **Hook silence.** The check prints nothing in `~` and `~/.claude` on purpose.
- **Installer and jq.** Without `jq` the installer copies files but can't edit settings.json; it prints the snippet instead.
- **SKILL.md description.** It lists only when to use the skill, never what the skill does. A description that summarises the steps makes Claude follow the summary and skip the file.

## Working agreements
- Test skill changes with a before/after run in fresh sessions (see CONTRIBUTING.md). If the "before" run already behaves, don't add the line.
- Test the installer with `INSTALL_HOME=<scratch folder>` (create empty `.claude`, `.codex` folders inside it to stand in for agents), never against real settings.
- Test skill wording in at least two different agents when the change could be agent-specific.
- No model prices in any file.

## Next action
- Add CI that runs the calculator regression check and `bash -n` on the four shell scripts for every pull request, so outside contributions are checked automatically.
- Before every push: `git ls-files` must show only the 15 public files; `private/` must never appear.
