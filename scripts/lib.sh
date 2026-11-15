# shellcheck shell=bash
# Shared settings for the sync scripts. The single source of truth for what is tracked.

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# Overridable so tests can run against a temporary live dir and repo copy.
CLAUDE_DIR="${CLAUDE_SETUP_LIVE_DIR:-${HOME}/.claude}"
SOURCE_DIR="${CLAUDE_SETUP_REPO_DIR:-${REPO_DIR}/claude}"

# Files and directories mirrored between ~/.claude and claude/.
# skills/ is deliberately excluded: ~/.claude/skills/ holds skills synced from claude.ai,
# which are not authored here and must not land in this public repo.
# shellcheck disable=SC2034 # consumed by the scripts that source this file
TRACKED_FILES=(CLAUDE.md settings.json keybindings.json)
# shellcheck disable=SC2034
TRACKED_DIRS=(commands memory)

export REPO_DIR CLAUDE_DIR SOURCE_DIR
