# my-claude-setup

[![CI](https://github.com/millsks/my-claude-setup/actions/workflows/ci.yml/badge.svg)](https://github.com/millsks/my-claude-setup/actions/workflows/ci.yml)

Versioned Claude Code global configuration. Mirrors a tracked subset of `~/.claude/` so changes are
committed, diffable, and recoverable.

## What is tracked

The list lives in one place, `scripts/lib.sh`, and every sync script reads it.

| Path | Notes |
|---|---|
| `CLAUDE.md` | Global instructions |
| `settings.json` | Machine-local keys are stripped (see below) |
| `keybindings.json` | If present |
| `commands/` | If present |
| `memory/` | Global memory files |

**Not tracked:**

- `skills/`: `~/.claude/skills/` holds skills synced from claude.ai, which are not authored here and must not be published.
- Runtime directories (`cache/`, `sessions/`, `projects/`, `history.jsonl`, and so on) and `settings.local.json`.
- Machine-local `settings.json` keys: `env` (may hold tokens), `autoMode` (per-project environment notes) and
  `skipDangerousModePermissionPrompt`. `sync-in` removes them, and `sync-out` keeps the live values.

## Structure

```
claude/          mirrors the tracked subset of ~/.claude/
scripts/         sync helpers (lib.sh holds the tracked-path list)
tests/           bats tests for the sync scripts
pixi.toml        task definitions
cliff.toml       changelog configuration
```

## Workflow

**Pull live config into the repo for review and commit:**

```sh
pixi run sync-in   # copies tracked paths from ~/.claude -> claude/
git diff           # review
git add claude/CLAUDE.md && git commit -m "fix: ..."
```

**Preview what would change before applying the repo to live:**

```sh
pixi run diff          # full unified diff; flags live files sync-out would delete
pixi run drift-check   # quiet; exits 1 if repo and ~/.claude differ
```

**Apply repo config to the live Claude installation (with backup):**

```sh
pixi run sync-out  # shows diff, prompts, backs up to ~/.claude-config-backup-<timestamp>, then applies
```

**Regenerate the changelog:**

```sh
pixi run changelog   # unreleased commits are labelled with today's date (tags are YYYY-MM-DD)
```

## First-time setup

```sh
pixi install
pixi run bootstrap   # installs pre-commit hooks (conventional commits, JSON/YAML lint, detect-secrets)
pixi run sync-in     # pull current live config into the repo
```

## Development

```sh
pixi run fmt    # shfmt
pixi run lint   # shellcheck + shfmt check
pixi run test   # bats tests against a throwaway HOME
pixi run ci     # pre-commit + lint + test; also runs in GitHub Actions
```

If `detect-secrets` flags a false positive, audit it into the baseline:
`pixi run detect-secrets scan --baseline .secrets.baseline --exclude-files 'pixi\.lock$'`, then
`pixi run detect-secrets audit .secrets.baseline`.

## Commit convention

All commits must follow [Conventional Commits](https://www.conventionalcommits.org/); the `commit-msg` hook
enforces this.

- `feat:`: new rule, command, or setting
- `fix:`: correction to an existing rule
- `docs:`: README or comment changes
- `refactor:`: restructure without behavior change
- `chore:`: dependency or tooling updates

## License

See [LICENSE](LICENSE).
