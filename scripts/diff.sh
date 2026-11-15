#!/usr/bin/env bash
# Show differences between versioned claude/ and the live ~/.claude config.
# Covers every path sync-out applies. Unified diff format: - = in repo, + = in live.
set -euo pipefail

# shellcheck source=scripts/lib.sh
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"

diff_file() {
    local name="$1"
    local repo_file="${SOURCE_DIR}/${name}"
    local live_file="${CLAUDE_DIR}/${name}"

    if [[ -f "${repo_file}" && -f "${live_file}" ]]; then
        if diff -q "${repo_file}" "${live_file}" >/dev/null 2>&1; then
            echo "  unchanged: ${name}"
        else
            echo ""
            echo "--- repo/claude/${name}"
            echo "+++ ~/.claude/${name}"
            diff -u "${repo_file}" "${live_file}" | tail -n +3 || true
        fi
    elif [[ -f "${repo_file}" ]]; then
        echo "  repo only (sync-out will create): ${name}"
    elif [[ -f "${live_file}" ]]; then
        echo "  live only (not tracked yet): ${name}"
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
            # Files only in live will be DELETED by sync-out (rsync --delete); call that out.
            echo "${result}" | sed -e "s|^Only in ${live_dir}.*: \(.*\)|DELETED by sync-out: ${name}/\1|" -e 's/^/    /'
        fi
    elif [[ -d "${repo_dir}" ]]; then
        echo "  repo only (sync-out will create): ${name}/"
    elif [[ -d "${live_dir}" ]]; then
        echo "  live only (not tracked yet): ${name}/"
    fi
}

echo "=== repo/claude vs ~/.claude ==="
for name in "${TRACKED_FILES[@]}"; do diff_file "${name}"; done
for name in "${TRACKED_DIRS[@]}"; do diff_dir "${name}"; done
echo ""
