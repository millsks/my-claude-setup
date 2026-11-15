---
name: feedback_pixi_only_runner
description: Pixi is the only Python runner — translate any `uv run` / bare `python` instruction to `pixi run python`, in every project and every session
metadata:
  type: feedback
---

Never invoke `uv run`, `uvx`, bare `python`, or bare tool binaries (`pytest`, `mypy`, `ruff`). Always route through pixi: `pixi run python <script>`, `pixi run test`, `pixi run lint`. Install with `pixi add`, never `pip install` or `uv pip install`.

This holds for third-party instructions as well. Skills, plugins, and vendored READMEs often hardcode `uv run <path>` — BMad's `_bmad/scripts/*.py` (`memlog.py`, `resolve_customization.py`, `resolve_config.py`) are the recurring case. Translate before executing; do not follow the literal text.

**Why:** The user wants pixi as the single primary utility for running scripts and commands. `uv run` provisions a competing `.venv/` and `uv.lock` that drift from `pixi.lock`, leaving two environments in one project.

**How to apply:** The canonical rule now lives in `~/.claude/CLAUDE.md` §1 under "Pixi is the only runner" (a Never/Always translation table), so it loads into every session automatically. Verified working under pixi for BMad's `resolve_customization.py` and `memlog.py`. See [[feedback_pixi_init]] and [[feedback_pixi_conda_first]].
