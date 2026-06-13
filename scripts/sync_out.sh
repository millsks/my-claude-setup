#!/usr/bin/env bash
# Apply versioned config from claude/ to ~/.claude with a timestamped backup.
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CLAUDE_DIR="${HOME}/.claude"
SOURCE_DIR="${REPO_DIR}/claude"

if [[ ! -d "${SOURCE_DIR}" ]] || [[ -z "$(ls -A "${SOURCE_DIR}" 2>/dev/null)" ]]; then
    echo "No tracked files in claude/. Run 'pixi run sync-in' first." >&2
    exit 1
fi

bash "${REPO_DIR}/scripts/diff.sh"

read -r -p "Apply these changes to ${CLAUDE_DIR}? [y/N] " confirm
[[ "${confirm}" == [yY] ]] || { echo "Aborted."; exit 0; }

BACKUP_DIR="${HOME}/.claude-config-backup-$(date +%Y%m%d-%H%M%S)"
echo "Backing up current config to ${BACKUP_DIR}"
mkdir -p "${BACKUP_DIR}"

apply_file() {
    local name="$1"
    local src="${SOURCE_DIR}/${name}"
    local dst="${CLAUDE_DIR}/${name}"
    if [[ -f "${src}" ]]; then
        [[ -f "${dst}" ]] && cp "${dst}" "${BACKUP_DIR}/${name}"
        cp "${src}" "${dst}"
        echo "  applied: ${name}"
    fi
}

apply_dir() {
    local name="$1"
    local src="${SOURCE_DIR}/${name}"
    local dst="${CLAUDE_DIR}/${name}"
    if [[ -d "${src}" ]]; then
        if [[ -d "${dst}" ]]; then
            mkdir -p "${BACKUP_DIR}/${name}"
            rsync -a "${dst}/" "${BACKUP_DIR}/${name}/"
        fi
        mkdir -p "${dst}"
        rsync -a --delete "${src}/" "${dst}/"
        echo "  applied dir: ${name}/"
    fi
}

echo "Applying claude/ → ~/.claude"
apply_file "CLAUDE.md"
apply_file "settings.json"
apply_dir "commands"

echo ""
echo "Done. Backup saved to ${BACKUP_DIR}"
