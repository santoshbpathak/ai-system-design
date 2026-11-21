#!/bin/bash
# Removes the ai-system-design skill and its startup check from Claude Code.
# Your projects' ARCHITECTURE.md files are not touched.
set -euo pipefail

CLAUDE="${CLAUDE_HOME:-$HOME/.claude}"
CMD='bash ~/.claude/hooks/architecture-check.sh 2>/dev/null || true'
SETTINGS="$CLAUDE/settings.json"

rm -rf "$CLAUDE/skills/ai-system-design"
rm -f "$CLAUDE/hooks/architecture-check.sh"
echo "Removed the skill and the check script."

if [ -f "$SETTINGS" ] && command -v jq >/dev/null 2>&1; then
  cp "$SETTINGS" "$SETTINGS.bak"
  jq --arg c "$CMD" '
    if .hooks.SessionStart then
      .hooks.SessionStart |= (map(.hooks |= map(select(.command != $c))) | map(select((.hooks | length) > 0)))
      | if (.hooks.SessionStart | length) == 0 then del(.hooks.SessionStart) else . end
      | if (.hooks | length) == 0 then del(.hooks) else . end
    else . end' "$SETTINGS.bak" > "$SETTINGS"
  echo "Removed the startup check from $SETTINGS (backup: settings.json.bak)"
else
  echo "If you switched on the startup check by hand, remove its entry from $SETTINGS."
fi
