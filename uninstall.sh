#!/bin/bash
# Removes the ai-system-design skill from every agent folder install.sh can write to,
# and the Claude Code startup check.
#   bash uninstall.sh              all listed agent folders
#   bash uninstall.sh --dir PATH   a skills folder you chose with install.sh --dir
# Your projects' ARCHITECTURE.md and AGENTS.md files are not touched.
set -euo pipefail

REPO="$(cd "$(dirname "$0")" && pwd)"
. "$REPO/lib-agents.sh"

if [ "${1:-}" = "--dir" ]; then
  rm -rf "${2:?--dir needs a folder}/ai-system-design"
  echo "Removed $2/ai-system-design"
  exit 0
fi

for a in $AGENTS shared; do
  T="$(skills_dir "$a")/ai-system-design"
  if [ -d "$T" ]; then rm -rf "$T"; echo "Removed $T"; fi
done
rm -f "$CLAUDE/hooks/architecture-check.sh"

SETTINGS="$CLAUDE/settings.json"
if [ -f "$SETTINGS" ] && command -v jq >/dev/null 2>&1; then
  if jq -e --arg c "$HOOK_CMD" '[.hooks.SessionStart[]?.hooks[]?.command] | index($c)' "$SETTINGS" >/dev/null; then
    cp "$SETTINGS" "$SETTINGS.bak"
    jq --arg c "$HOOK_CMD" '
      .hooks.SessionStart |= (map(.hooks |= map(select(.command != $c))) | map(select((.hooks | length) > 0)))
      | if (.hooks.SessionStart | length) == 0 then del(.hooks.SessionStart) else . end
      | if (.hooks | length) == 0 then del(.hooks) else . end' "$SETTINGS.bak" > "$SETTINGS"
    echo "Removed the Claude Code startup check from $SETTINGS (backup: settings.json.bak)"
  fi
elif [ -f "$SETTINGS" ]; then
  echo "If you switched on the Claude Code startup check by hand, remove its entry from $SETTINGS."
fi
echo "Done. A note added with 'install.sh --project' stays in that project's AGENTS.md; delete the block there if you want it gone."
