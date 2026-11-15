#!/usr/bin/env bats
# Exercises sync-in, diff and sync-out against a throwaway HOME so the real ~/.claude is never touched.

setup() {
    SCRIPTS="${BATS_TEST_DIRNAME}/../scripts"
    export HOME="${BATS_TEST_TMPDIR}/home"
    export CLAUDE_SETUP_LIVE_DIR="${HOME}/.claude"
    export CLAUDE_SETUP_REPO_DIR="${BATS_TEST_TMPDIR}/repo"
    mkdir -p "${CLAUDE_SETUP_LIVE_DIR}/memory" "${CLAUDE_SETUP_LIVE_DIR}/skills/synced" "${CLAUDE_SETUP_REPO_DIR}"
    echo "# live" >"${CLAUDE_SETUP_LIVE_DIR}/CLAUDE.md"
    echo '{"permissions": {}}' >"${CLAUDE_SETUP_LIVE_DIR}/settings.json"
    echo '{"bindings": []}' >"${CLAUDE_SETUP_LIVE_DIR}/keybindings.json"
    echo "a" >"${CLAUDE_SETUP_LIVE_DIR}/memory/a.md"
    echo "s" >"${CLAUDE_SETUP_LIVE_DIR}/skills/synced/SKILL.md"
}

@test "sync-in copies every tracked path" {
    run bash "${SCRIPTS}/sync_in.sh"
    [ "${status}" -eq 0 ]
    [ -f "${CLAUDE_SETUP_REPO_DIR}/CLAUDE.md" ]
    [ -f "${CLAUDE_SETUP_REPO_DIR}/keybindings.json" ]
    [ -f "${CLAUDE_SETUP_REPO_DIR}/memory/a.md" ]
}

@test "sync-in never copies skills" {
    bash "${SCRIPTS}/sync_in.sh"
    [ ! -e "${CLAUDE_SETUP_REPO_DIR}/skills" ]
}

@test "diff reports unchanged after sync-in" {
    bash "${SCRIPTS}/sync_in.sh"
    run bash "${SCRIPTS}/diff.sh"
    [ "${status}" -eq 0 ]
    [[ "${output}" == *"unchanged: keybindings.json"* ]]
    [[ "${output}" == *"unchanged: memory/"* ]]
}

@test "diff covers keybindings.json" {
    bash "${SCRIPTS}/sync_in.sh"
    echo '{"bindings": [1]}' >"${CLAUDE_SETUP_LIVE_DIR}/keybindings.json"
    run bash "${SCRIPTS}/diff.sh"
    [[ "${output}" == *"+++ ~/.claude/keybindings.json"* ]]
}

@test "diff warns when sync-out would delete a live memory file" {
    bash "${SCRIPTS}/sync_in.sh"
    echo "b" >"${CLAUDE_SETUP_LIVE_DIR}/memory/b.md"
    run bash "${SCRIPTS}/diff.sh"
    [[ "${output}" == *"DELETED by sync-out: memory/b.md"* ]]
}

@test "sync-out aborts without confirmation" {
    bash "${SCRIPTS}/sync_in.sh"
    echo "# repo" >"${CLAUDE_SETUP_REPO_DIR}/CLAUDE.md"
    run bash "${SCRIPTS}/sync_out.sh" <<<"n"
    [ "${status}" -eq 0 ]
    [[ "${output}" == *"Aborted."* ]]
    [ "$(cat "${CLAUDE_SETUP_LIVE_DIR}/CLAUDE.md")" = "# live" ]
}

@test "sync-out applies repo and backs up live" {
    bash "${SCRIPTS}/sync_in.sh"
    echo "# repo" >"${CLAUDE_SETUP_REPO_DIR}/CLAUDE.md"
    run bash "${SCRIPTS}/sync_out.sh" <<<"y"
    [ "${status}" -eq 0 ]
    [ "$(cat "${CLAUDE_SETUP_LIVE_DIR}/CLAUDE.md")" = "# repo" ]
    backup="$(echo "${HOME}"/.claude-config-backup-*)"
    [ "$(cat "${backup}/CLAUDE.md")" = "# live" ]
}

@test "sync-out leaves live skills alone" {
    bash "${SCRIPTS}/sync_in.sh"
    bash "${SCRIPTS}/sync_out.sh" <<<"y"
    [ -f "${CLAUDE_SETUP_LIVE_DIR}/skills/synced/SKILL.md" ]
}

@test "sync-out refuses an empty repo dir" {
    run bash "${SCRIPTS}/sync_out.sh" <<<"y"
    [ "${status}" -eq 1 ]
}
