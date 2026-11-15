#!/usr/bin/env bash
# Show differences between versioned claude/ and the live ~/.claude config.
# Covers every path sync-out applies. Unified diff format: - = in repo, + = in live.
# With --check, prints only drifted paths and exits 1 if repo and live differ.
set -euo pipefail

# shellcheck source=scripts/lib.sh
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"

CHECK=0
if [[ "${1:-}" == "--check" ]]; then CHECK=1; fi
DRIFT=0

report() {
    if [[ "${CHECK}" -eq 0 ]]; then echo "$@"; fi
}

drifted() {
    DRIFT=1
    if [[ "${CHECK}" -eq 1 ]]; then echo "  drift: $1"; fi
}

# Files only in live will be DELETED by sync-out (rsync --delete); call that out explicitly.
annotate_deletions() {
    local name="$1" live_dir="$2" result="$3" line
    while IFS= read -r line; do
        if [[ "${line}" == "Only in ${live_dir}"* ]]; then
            echo "    DELETED by sync-out: ${name}/${line##*: }"
        else
            echo "    ${line}"
        fi
    done <<<"${result}"
}

diff_file() {
    local name="$1"
    local repo_file="${SOURCE_DIR}/${name}"
    local live_file="${CLAUDE_DIR}/${name}"

    if [[ -f "${repo_file}" && -f "${live_file}" ]]; then
        local live_tmp
        live_tmp="$(mktemp)"
        live_view "${name}" >"${live_tmp}"
        if diff -q "${repo_file}" "${live_tmp}" >/dev/null 2>&1; then
            report "  unchanged: ${name}"
        else
            drifted "${name}"
            report ""
            report "--- repo/claude/${name}"
            report "+++ ~/.claude/${name}"
            if [[ "${CHECK}" -eq 0 ]]; then diff -u "${repo_file}" "${live_tmp}" | tail -n +3 || true; fi
        fi
        rm -f "${live_tmp}"
    elif [[ -f "${repo_file}" ]]; then
        drifted "${name}"
        report "  repo only (sync-out will create): ${name}"
    elif [[ -f "${live_file}" ]]; then
        drifted "${name}"
        report "  live only (not tracked yet): ${name}"
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
            report "  unchanged: ${name}/"
        else
            drifted "${name}/"
            report "  changed: ${name}/"
            if [[ "${CHECK}" -eq 0 ]]; then annotate_deletions "${name}" "${live_dir}" "${result}"; fi
        fi
    elif [[ -d "${repo_dir}" ]]; then
        drifted "${name}/"
        report "  repo only (sync-out will create): ${name}/"
    elif [[ -d "${live_dir}" ]]; then
        drifted "${name}/"
        report "  live only (not tracked yet): ${name}/"
    fi
}

report "=== repo/claude vs ~/.claude ==="
for name in "${TRACKED_FILES[@]}"; do diff_file "${name}"; done
for name in "${TRACKED_DIRS[@]}"; do diff_dir "${name}"; done
report ""

if [[ "${CHECK}" -eq 1 && "${DRIFT}" -eq 1 ]]; then
    echo "Repo and ~/.claude have drifted. Run 'pixi run diff' to inspect, then sync-in or sync-out." >&2
    exit 1
fi
