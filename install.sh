#!/bin/bash
# Installs the ai-system-design skill for the coding agents on this machine.
#   bash install.sh                  every agent found here, plus the shared folder
#   bash install.sh --agent codex    one agent (see --list for names)
#   bash install.sh --dir PATH       any skills folder, for an agent not listed
#   bash install.sh --project PATH   add the "always check" note to a project's AGENTS.md
#   bash install.sh --no-hook        skip the Claude Code startup check
#   bash install.sh --list           show supported agents and their folders
set -euo pipefail

REPO="$(cd "$(dirname "$0")" && pwd)"
. "$REPO/lib-agents.sh"

ONLY="" DIR="" PROJECT="" HOOK=1
while [ $# -gt 0 ]; do
  case "$1" in
    --agent)   ONLY="${2:?--agent needs a name}"; shift 2 ;;
    --dir)     DIR="${2:?--dir needs a folder}"; shift 2 ;;
    --project) PROJECT="${2:?--project needs a folder}"; shift 2 ;;
    --no-hook) HOOK=0; shift ;;
    --list)
      for a in $AGENTS shared; do printf '  %-9s %s\n' "$a" "$(skills_dir "$a")"; done
      exit 0 ;;
    -h|--help) sed -n '2,9p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
    *) echo "Unknown option: $1 (try --help)"; exit 1 ;;
  esac
done

copy_skill() {  # $1 = skills folder
  mkdir -p "$1/ai-system-design"
  cp -R "$REPO/skills/ai-system-design/." "$1/ai-system-design/"
  echo "Installed skill  -> $1/ai-system-design"
}

# --- A project's AGENTS.md: the "always check" note for agents without startup hooks.
if [ -n "$PROJECT" ]; then
  [ -d "$PROJECT" ] || { echo "Not a folder: $PROJECT"; exit 1; }
  FILE="$PROJECT/AGENTS.md"
  if [ -f "$FILE" ] && grep -qF "$BLOCK_START" "$FILE"; then
    echo "Note already in $FILE"
  else
    [ -f "$FILE" ] && [ -s "$FILE" ] && echo >> "$FILE"
    cat >> "$FILE" <<NOTE
$BLOCK_START
## System design
- If this project has no ARCHITECTURE.md, run the \`ai-system-design\` skill before writing implementation code, scaffolding or a build plan. Skip only for throwaway scripts, single static pages, or work that is not building software; say why in one line.
- If ARCHITECTURE.md exists, read it before changing the system, and update the affected section when a change touches it.
$BLOCK_END
NOTE
    echo "Added the note   -> $FILE"
  fi
  exit 0
fi

# --- The skill itself.
INSTALLED_CLAUDE=0
if [ -n "$DIR" ]; then
  copy_skill "$DIR"
elif [ -n "$ONLY" ]; then
  TARGET="$(skills_dir "$ONLY")" || { echo "Unknown agent: $ONLY (try --list, or use --dir)"; exit 1; }
  copy_skill "$TARGET"
  [ "$ONLY" = "claude" ] && INSTALLED_CLAUDE=1
else
  DONE=" "
  for a in $AGENTS; do
    [ -d "$(agent_home "$a")" ] || continue
    TARGET="$(skills_dir "$a")"
    case "$DONE" in *" $TARGET "*) continue ;; esac
    copy_skill "$TARGET"; DONE="$DONE$TARGET "
    [ "$a" = "claude" ] && INSTALLED_CLAUDE=1
  done
  # The shared folder is read by several agents, so it is always filled in.
  TARGET="$(skills_dir shared)"
  case "$DONE" in *" $TARGET "*) ;; *) copy_skill "$TARGET" ;; esac
fi

# --- Claude Code only: a check that runs when a session starts.
if [ "$INSTALLED_CLAUDE" = 1 ] && [ "$HOOK" = 1 ]; then
  mkdir -p "$CLAUDE/hooks"
  cp "$REPO/hooks/architecture-check.sh" "$CLAUDE/hooks/architecture-check.sh"
  chmod +x "$CLAUDE/hooks/architecture-check.sh"
  echo "Installed check  -> $CLAUDE/hooks/architecture-check.sh (Claude Code)"

  SETTINGS="$CLAUDE/settings.json"
  if ! command -v jq >/dev/null 2>&1; then
    cat <<NOJQ

'jq' is not installed, so settings.json was left untouched.
To switch the Claude Code startup check on, add this to $SETTINGS:

  "hooks": {
    "SessionStart": [
      { "hooks": [ { "type": "command", "command": "$HOOK_CMD", "timeout": 10 } ] }
    ]
  }

(or install jq and run this script again)
NOJQ
  else
    [ -f "$SETTINGS" ] || echo '{}' > "$SETTINGS"
    if jq -e --arg c "$HOOK_CMD" '[.hooks.SessionStart[]?.hooks[]?.command] | index($c)' "$SETTINGS" >/dev/null; then
      echo "Startup check already switched on in $SETTINGS"
    else
      cp "$SETTINGS" "$SETTINGS.bak"
      jq --arg c "$HOOK_CMD" \
        '.hooks.SessionStart = ((.hooks.SessionStart // []) + [{hooks: [{type: "command", command: $c, timeout: 10}]}])' \
        "$SETTINGS.bak" > "$SETTINGS"
      echo "Switched on the startup check in $SETTINGS (backup: settings.json.bak)"
    fi
  fi
fi

echo
echo "Done. Restart your coding agent (or reload your editor window), then open any project."
echo "For agents other than Claude Code, switch on the always-check note per project:"
echo "  bash \"$REPO/install.sh\" --project /path/to/your/project"
