---
name: feedback-pixi-init
description: Always use `pixi init` to create pixi projects — never manually write pixi.toml
metadata:
  type: feedback
---

Always run `pixi init <project-dir>` to scaffold a pixi project. Never manually create `pixi.toml` from scratch, and never use `pixi init --pyproject`.

**Why:** Hand-written `pixi.toml` files use the old `[project]` table, but the current pixi spec requires `[workspace]`. `--pyproject` embeds pixi config into `pyproject.toml`, which should be reserved for Python tool configuration only (pytest, ruff, mypy, git-cliff).

**How to apply:** Any time a new pixi project is needed — run `pixi init` first, then edit the generated `pixi.toml`. Pixi settings (deps, features, tasks) always live in `pixi.toml`; Python tool config always lives in `pyproject.toml`.
