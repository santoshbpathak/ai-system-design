# AI System Design

Instructions for any coding agent working on this repo.

Read `BUILD.md` before changing anything, and update it after substantial work.

## Non-negotiables
- `private/` is git-ignored and must never be committed or quoted. It holds a transcript with other people's names.
- This repo is the source; each agent's skills folder holds an installed copy. Edit here, then run `bash install.sh`.
- The skill is agent-neutral. `SKILL.md`, the template and the example must not name one agent's folders, commands or other skills. Agent-specific details live only in `lib-agents.sh`, `hooks/` and the install section of README.md.
- README.md and CONTRIBUTING.md are written for builders who aren't engineers. Explain any technical term the first time it appears.
- No model prices in any file. The calculator takes them as arguments.
- Test skill wording with a before/after run in fresh sessions before keeping it.
