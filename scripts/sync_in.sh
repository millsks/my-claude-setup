#!/usr/bin/env bash
# Pull tracked Claude config files from ~/.claude into claude/ for versioning.
set -euo pipefail

# shellcheck source=scripts/lib.sh
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"

mkdir -p "${SOURCE_DIR}"

sync_file() {
    local name="$1"
    local src="${CLAUDE_DIR}/${name}"
    local dst="${SOURCE_DIR}/${name}"
    if [[ -f "${src}" ]]; then
        cp "${src}" "${dst}"
        echo "  synced: ${name}"
    else
        echo "  skipped (not found): ${name}"
    fi
}

sync_dir() {
    local name="$1"
    local src="${CLAUDE_DIR}/${name}"
    local dst="${SOURCE_DIR}/${name}"
    if [[ -d "${src}" ]]; then
        mkdir -p "${dst}"
        rsync -a --delete "${src}/" "${dst}/"
        echo "  synced dir: ${name}/"
    else
        echo "  skipped dir (not found): ${name}/"
    fi
}

echo "Syncing ${CLAUDE_DIR} -> ${SOURCE_DIR}"
for name in "${TRACKED_FILES[@]}"; do sync_file "${name}"; done
for name in "${TRACKED_DIRS[@]}"; do sync_dir "${name}"; done

echo ""
echo "Done. Review with: git diff"
