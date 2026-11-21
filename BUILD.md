# BUILD.md — AI System Design

Briefing for whoever works on this repo next, human or AI.

## Current state (2026-11-21)
- Open-source repo for one Claude Code skill, `ai-system-design`. Public at https://github.com/santoshbpathak/ai-system-design (MIT), branch `main`.
- This repo is the source of truth. The installed copy in `~/.claude/` is made by `bash install.sh`; re-run it after any change here.
- `private/` is git-ignored. It holds `scope.md`, the talk transcript the skill was built from. It contains other people's names and must not be published.
- Unfinished: Windows is untested. No CI.
- Commits use the GitHub no-reply address (set in this repo's local git config) so no personal email is published.

## Module map
| Path | Responsibility |
|---|---|
| `skills/ai-system-design/SKILL.md` | The pre-flight process, five rules, pattern ladder, scaling ladder, red flags |
| `skills/ai-system-design/templates/ARCHITECTURE.md` | Blank 10-section file the skill fills in |
| `skills/ai-system-design/scripts/napkin.py` | LLM bill, cost per user or per tenant, margin, spend cap |
| `hooks/architecture-check.sh` | SessionStart check: no ARCHITECTURE.md → run the skill; exists → read it |
| `install.sh` / `uninstall.sh` | Copy into `~/.claude/` and add or remove the hook entry in settings.json, with a backup |
| `examples/ARCHITECTURE.example.md` | Filled-in example (made-up product, placeholder prices) |
| `README.md`, `CONTRIBUTING.md` | Written for builders who aren't engineers. Keep the plain language. |

## Golden numbers
- Calculator regression check: 5,000 DAU × 20 msgs × 30 days → 3.00M messages, 9.00B input tokens, 900.00M output tokens.
- Example file numbers (300 DAU, 6 msgs, 3000/300 tokens, $3/$15, caches 0.5/0.15, 10 tenants at $150): $729.00 without caching, $433.75 with, $43.38 per tenant, 71% margin, $867.51 cap.

## Traps
- **Currency.** All calculator prices are USD; `--fx` only adds a display column. An earlier version read `--price-per-user` as local currency and produced margins like −2000%.
- **B2B.** Use `--tenants` with `--price-per-tenant`. Per-user pricing understates revenue for products sold per company.
- **Hook silence.** The check prints nothing in `~` and `~/.claude` on purpose.
- **Installer and jq.** Without `jq` the installer copies files but can't edit settings.json; it prints the snippet instead.
- **SKILL.md description.** It lists only when to use the skill, never what the skill does. A description that summarises the steps makes Claude follow the summary and skip the file.

## Working agreements
- Test skill changes with a before/after run in fresh sessions (see CONTRIBUTING.md). If the "before" run already behaves, don't add the line.
- Test the installer with `CLAUDE_HOME=<scratch folder>`, never against real settings.
- No model prices in any file.

## Next action
- Add CI that runs the calculator regression check and `bash -n` on the three shell scripts for every pull request, so outside contributions are checked automatically.
- Before every push: `git ls-files` must show only the 13 public files; `private/` must never appear.
