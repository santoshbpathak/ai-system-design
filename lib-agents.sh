# Shared by install.sh and uninstall.sh: where each coding agent keeps its skills.
# To support another agent, add its name to AGENTS and a line to skills_dir.
# INSTALL_HOME lets you test against a scratch folder instead of your real home.
ROOT="${INSTALL_HOME:-$HOME}"
AGENTS="claude codex cursor gemini copilot opencode windsurf goose"

skills_dir() {
  case "$1" in
    claude)   echo "$ROOT/.claude/skills" ;;
    codex)    echo "$ROOT/.agents/skills" ;;
    cursor)   echo "$ROOT/.cursor/skills" ;;
    gemini)   echo "$ROOT/.gemini/skills" ;;
    copilot)  echo "$ROOT/.copilot/skills" ;;
    opencode) echo "$ROOT/.config/opencode/skills" ;;
    windsurf) echo "$ROOT/.codeium/windsurf/skills" ;;
    goose)    echo "$ROOT/.config/goose/skills" ;;
    shared)   echo "$ROOT/.agents/skills" ;;
    *) return 1 ;;
  esac
}

# The folder that exists when the agent is installed on this machine.
agent_home() {
  case "$1" in
    claude)   echo "$ROOT/.claude" ;;
    codex)    echo "$ROOT/.codex" ;;
    cursor)   echo "$ROOT/.cursor" ;;
    gemini)   echo "$ROOT/.gemini" ;;
    copilot)  echo "$ROOT/.copilot" ;;
    opencode) echo "$ROOT/.config/opencode" ;;
    windsurf) echo "$ROOT/.codeium/windsurf" ;;
    goose)    echo "$ROOT/.config/goose" ;;
    *) return 1 ;;
  esac
}

CLAUDE="$ROOT/.claude"
HOOK_CMD='bash ~/.claude/hooks/architecture-check.sh 2>/dev/null || true'
BLOCK_START='<!-- ai-system-design:start -->'
BLOCK_END='<!-- ai-system-design:end -->'
