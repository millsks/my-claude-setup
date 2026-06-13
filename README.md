# my-claude-setup

Versioned Claude Code global configuration. Tracks `~/.claude/CLAUDE.md`,
`~/.claude/settings.json`, and `~/.claude/commands/` so changes are committed,
diffable, and recoverable.

## Structure

```
claude/          mirrors the tracked subset of ~/.claude/
scripts/         sync helpers
pixi.toml        task definitions
cliff.toml       changelog configuration
```

## Workflow

**Pull live config into the repo for review and commit:**

```sh
pixi run sync-in   # copies ~/.claude/{CLAUDE.md,settings.json,commands/} → claude/
git diff           # review
git add -p && git commit -m "chore: update CLAUDE.md"
```

**Preview what would change before applying the repo to live:**

```sh
pixi run diff
```

**Apply repo config to the live Claude installation (with backup):**

```sh
pixi run sync-out  # shows diff, prompts for confirmation, backs up then applies
```

**Regenerate the changelog:**

```sh
pixi run changelog
```

## First-time setup

```sh
pixi run bootstrap   # installs pre-commit hooks (conventional commits + JSON lint)
pixi run sync-in     # pull current live config into the repo
```

## What is NOT tracked

Runtime directories (`cache/`, `sessions/`, `history.jsonl`, etc.) and
`settings.local.json` (machine-specific overrides that may contain sensitive
values) are excluded via `.gitignore`.

## Commit convention

All commits must follow [Conventional Commits](https://www.conventionalcommits.org/).
The `commit-msg` hook enforces this. Common types for this repo:

- `feat:` — new rule, command, or setting
- `fix:` — correction to an existing rule
- `docs:` — README or comment changes
- `refactor:` — restructure without behavior change
- `chore:` — dependency or tooling updates
