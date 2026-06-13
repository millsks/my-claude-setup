#!/usr/bin/env bash
# Show differences between versioned claude/ and the live ~/.claude config.
# Outputs in unified diff format: - = in repo, + = in live.
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CLAUDE_DIR="${HOME}/.claude"
SOURCE_DIR="${REPO_DIR}/claude"

diff_file() {
    local name="$1"
    local repo_file="${SOURCE_DIR}/${name}"
    local live_file="${CLAUDE_DIR}/${name}"

    if [[ -f "${repo_file}" && -f "${live_file}" ]]; then
        if diff -q "${repo_file}" "${live_file}" > /dev/null 2>&1; then
            echo "  unchanged: ${name}"
        else
            echo ""
            echo "--- repo/claude/${name}"
            echo "+++ ~/.claude/${name}"
            diff -u "${repo_file}" "${live_file}" | tail -n +3 || true
        fi
    elif [[ -f "${repo_file}" ]]; then
        echo "  repo only (not in live): ${name}"
    elif [[ -f "${live_file}" ]]; then
        echo "  live only (not in repo): ${name}"
    fi
}

diff_dir() {
    local name="$1"
    local repo_dir="${SOURCE_DIR}/${name}"
    local live_dir="${CLAUDE_DIR}/${name}"

    if [[ -d "${repo_dir}" && -d "${live_dir}" ]]; then
        local result
        result="$(diff -rq "${repo_dir}" "${live_dir}" 2>/dev/null || true)"
        if [[ -z "${result}" ]]; then
            echo "  unchanged: ${name}/"
        else
            echo "  changed: ${name}/"
            echo "${result}" | sed 's/^/    /'
        fi
    elif [[ -d "${repo_dir}" ]]; then
        echo "  repo only (not in live): ${name}/"
    elif [[ -d "${live_dir}" ]]; then
        echo "  live only (not in repo): ${name}/"
    fi
}

echo "=== repo/claude vs ~/.claude ==="
diff_file "CLAUDE.md"
diff_file "settings.json"
diff_dir "commands"
echo ""
