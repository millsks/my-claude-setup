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

# Top-level settings.json keys that stay machine-local: never copied into the repo, and preserved
# in the live file on sync-out. env can hold tokens; autoMode embeds per-project environment notes.
LOCAL_SETTINGS_KEYS='["env", "autoMode", "skipDangerousModePermissionPrompt"]'

# Print a live file as it should appear in the repo (settings.json has machine-local keys removed).
live_view() {
    local name="$1"
    local file="${CLAUDE_DIR}/${name}"
    if [[ "${name}" == "settings.json" ]]; then
        jq --indent 2 --argjson keys "${LOCAL_SETTINGS_KEYS}" \
            'with_entries(select(.key as $k | $keys | index($k) | not))' "${file}"
    else
        cat "${file}"
    fi
}

# Print the repo version of settings.json merged with the live file's machine-local keys.
merged_settings() {
    local repo_file="$1"
    local live_file="$2"
    jq --indent 2 -s --argjson keys "${LOCAL_SETTINGS_KEYS}" \
        '.[0] + (.[1] | with_entries(select(.key as $k | $keys | index($k))))' "${repo_file}" "${live_file}"
}
