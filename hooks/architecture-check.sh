#!/bin/bash
# SessionStart hook: make the ai-system-design pre-flight happen in every project.
# - No ARCHITECTURE.md -> tell Claude to run the skill before any implementation code.
# - ARCHITECTURE.md exists -> tell Claude to read it before changing the system.
input="$(cat)"
dir="${CLAUDE_PROJECT_DIR:-}"
if [ -z "$dir" ] && command -v jq >/dev/null 2>&1; then
  dir="$(printf '%s' "$input" | jq -r '.cwd // empty' 2>/dev/null)"
fi
dir="${dir:-$PWD}"

# Not a project: home directory or Claude's own config.
case "$dir" in
  "$HOME"|"$HOME/"|"$HOME/.claude"|"$HOME/.claude/"*) exit 0 ;;
esac

if [ -f "$dir/ARCHITECTURE.md" ]; then
  msg="This project has an ARCHITECTURE.md (system design decisions: sizing, LLM bill, trust boundaries, tenant isolation, failure design, observability, scale triggers). Read it before changing anything that touches its nine boxes. If a change alters any of them, update the affected section and its 'Last reviewed' date, using the ai-system-design skill."
else
  msg="This project has no ARCHITECTURE.md. Before writing implementation code, scaffolding, or planning a build here, invoke the ai-system-design skill: it asks the 4 sizing questions, runs the napkin cost math, and writes ARCHITECTURE.md. Skip only for throwaway scripts, static single pages, or work that is not building software (docs, decks, content). If you skip it, say why in one line."
fi

jq -n --arg m "$msg" '{hookSpecificOutput:{hookEventName:"SessionStart",additionalContext:$m}}' 2>/dev/null \
  || printf '{"hookSpecificOutput":{"hookEventName":"SessionStart","additionalContext":"%s"}}\n' "$msg"
