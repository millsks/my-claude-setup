---
name: feedback_pixi_conda_first
description: When adding packages to pixi, always check conda-forge first; only fall back to pypi-dependencies if the package is absent from conda-forge
metadata:
  type: feedback
---

Always check conda-forge before reaching for `[pypi-dependencies]` when adding a package to `pixi.toml`.

**Why:** conda-forge packages integrate better with the rest of the pixi environment (ABI compatibility, solver consistency). Using PyPI for a package that exists on conda-forge is unnecessary and was the source of a mistake where `claude-agent-sdk` was incorrectly added to `[pypi-dependencies]` when it was available on conda-forge all along.

**How to apply:** Before adding any package, verify it exists on conda-forge (e.g., query repodata or check prefix.dev). Add to `[dependencies]` if found; only use `[pypi-dependencies]` if it is genuinely absent from conda-forge. This mirrors the rule already in the global CLAUDE.md ("conda-forge first") but applies it explicitly at the point of package lookup, not just as a general preference.

See also: [[feedback_pixi_init]]
