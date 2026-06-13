#!/usr/bin/env bash
# Pull tracked Claude config files from ~/.claude into claude/ for versioning.
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CLAUDE_DIR="${HOME}/.claude"
TARGET_DIR="${REPO_DIR}/claude"

mkdir -p "${TARGET_DIR}"

sync_file() {
    local name="$1"
    local src="${CLAUDE_DIR}/${name}"
    local dst="${TARGET_DIR}/${name}"
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
    local dst="${TARGET_DIR}/${name}"
    if [[ -d "${src}" ]]; then
        mkdir -p "${dst}"
        rsync -a --delete "${src}/" "${dst}/"
        echo "  synced dir: ${name}/"
    else
        echo "  skipped dir (not found): ${name}/"
    fi
}

echo "Syncing ~/.claude → claude/"
sync_file "CLAUDE.md"
sync_file "settings.json"
sync_file "keybindings.json"
sync_dir "commands"
sync_dir "memory"
sync_dir "skills"

echo ""
echo "Done. Review with: git diff"
