#!/bin/bash
# Installs the ai-system-design skill for Claude Code.
#   bash install.sh            skill + startup check (recommended)
#   bash install.sh --no-hook  skill only; you run it yourself with /ai-system-design
set -euo pipefail

REPO="$(cd "$(dirname "$0")" && pwd)"
CLAUDE="${CLAUDE_HOME:-$HOME/.claude}"
CMD='bash ~/.claude/hooks/architecture-check.sh 2>/dev/null || true'

mkdir -p "$CLAUDE/skills/ai-system-design"
cp -R "$REPO/skills/ai-system-design/." "$CLAUDE/skills/ai-system-design/"
echo "Installed skill  -> $CLAUDE/skills/ai-system-design"

if [ "${1:-}" = "--no-hook" ]; then
  echo "Skipped the startup check. Run the skill yourself with /ai-system-design."
  exit 0
fi

mkdir -p "$CLAUDE/hooks"
cp "$REPO/hooks/architecture-check.sh" "$CLAUDE/hooks/architecture-check.sh"
chmod +x "$CLAUDE/hooks/architecture-check.sh"
echo "Installed check  -> $CLAUDE/hooks/architecture-check.sh"

SETTINGS="$CLAUDE/settings.json"
if ! command -v jq >/dev/null 2>&1; then
  cat <<EOF

'jq' is not installed, so settings.json was left untouched.
To switch the startup check on, add this to $SETTINGS:

  "hooks": {
    "SessionStart": [
      { "hooks": [ { "type": "command", "command": "$CMD", "timeout": 10 } ] }
    ]
  }

(or install jq and run this script again)
EOF
  exit 0
fi

[ -f "$SETTINGS" ] || echo '{}' > "$SETTINGS"
if jq -e --arg c "$CMD" '[.hooks.SessionStart[]?.hooks[]?.command] | index($c)' "$SETTINGS" >/dev/null; then
  echo "Startup check already switched on in $SETTINGS"
else
  cp "$SETTINGS" "$SETTINGS.bak"
  jq --arg c "$CMD" \
    '.hooks.SessionStart = ((.hooks.SessionStart // []) + [{hooks: [{type: "command", command: $c, timeout: 10}]}])' \
    "$SETTINGS.bak" > "$SETTINGS"
  echo "Switched on the startup check in $SETTINGS (backup: settings.json.bak)"
fi

echo
echo "Done. Restart Claude Code (or reload your editor window), then open any project."
