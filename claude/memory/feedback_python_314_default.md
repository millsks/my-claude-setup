---
name: feedback_python_314_default
description: Python 3.14 is the default for all new projects; CI matrix is 3.12, 3.13, 3.14 (no -dev entry)
metadata:
  type: feedback
---

New projects target **Python 3.14** by default — this replaced the previous 3.13 default. Whenever versions are matrixed, the set is `["3.12", "3.13", "3.14"]`. Do not write `3.14-dev`; 3.14 is stable, so the `continue-on-error` guard that used to shield the dev build was removed from the scaffold CI workflow.

`[tool.mypy] python_version` deliberately stays at the matrix **floor** (3.12), not the dev version, so 3.13-only and 3.14-only APIs are caught before they reach a 3.12 runner. Same for `requires-python = ">=3.12"`.

**Why:** The user asked for 3.14 as the default for new work while keeping the full supported range under test.

**How to apply:** The canonical rule lives in `~/.claude/CLAUDE.md` §1 (toolchain table) and §10 (pyproject.toml "Python version policy"), so it loads every session. Pin 3.14 in `pixi.toml` for the dev environment on new scaffolds. See [[feedback_pixi_only_runner]] and [[feedback_pixi_init]].
