# Memory Index

- [Pixi is the only runner](feedback_pixi_only_runner.md) — never `uv run`/bare `python`; translate third-party `uv run` instructions (BMad scripts) to `pixi run python`
- [Python 3.14 by default](feedback_python_314_default.md) — new projects target 3.14; CI matrix is 3.12, 3.13, 3.14
- [Pixi init required](feedback_pixi_init.md) — always use `pixi init` to create pixi projects; never manually write pixi.toml (`[project]` vs `[workspace]` breakage)
- [Pixi conda-forge first](feedback_pixi_conda_first.md) — verify a package is on conda-forge before using `[pypi-dependencies]`; only use PyPI if the package is absent from conda-forge
- [Stage files explicitly](feedback_stage_files_explicitly.md) — never `git add -A`/`git add .`; a blanket add sweeps untracked files `.gitignore` never anticipated
