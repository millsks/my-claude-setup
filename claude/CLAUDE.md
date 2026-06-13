# CLAUDE.md

This file provides global guidance to Claude Code (claude.ai/code) across all projects.
Project-specific CLAUDE.md files cover architecture, commands, and off-limits areas only.

---

## 1. Toolchain

| Tool | Role |
|---|---|
| **Pixi** | Package manager and task runner — never use `pip install` directly |
| **Python 3.13** | Dev version; CI matrix tests 3.12, 3.13, 3.14-dev |
| **pytest + pytest-cov** | Testing (≥90% coverage required, enforced by `--cov-fail-under=90`) |
| **mypy** | Type checking (`strict = true`) |
| **ruff** | Linting and formatting |
| **structlog** | Structured logging (preferred); loguru is the acceptable alternative |
| **Conventional Commits** | Every commit message must follow the spec |
| **git-cliff** | CHANGELOG generation (`pixi run changelog`) |

Package preference: **conda-forge first**. Use `[pypi-dependencies]` only for packages absent from conda-forge.

---

## 2. Coding Standards

- **PEP 8**, max line length **120**
- Full type hints on all public function signatures
- Python 3.10+ syntax: `X | Y`, `list[X]`, `dict[K, V]` — never `Union`, `List`, `Dict`
- **Google-style docstrings** on all public functions and classes
- **Never** use `print()` anywhere — not in library code, scripts, CLI entry points, or tests
- **Never** use stdlib `logging` — always use `structlog` (preferred) or `loguru` for structured, machine-parseable output
- Configure `structlog` with JSON or key=value rendering so logs are capturable by log aggregators without parsing heuristics
- Never use bare `except:` — always catch specific exception types
- Never silently swallow exceptions — log at an appropriate level or re-raise; `except SomeError: pass` is forbidden

---

## 3. Test Requirements

Every code change — new feature, bug fix, hotfix, refactor — must include a corresponding test. No exceptions.

**General rules:**
- New code: write at least one test that exercises the new behavior directly.
- Modified code: update any existing tests that cover the changed behavior; add new tests if the change introduces paths not previously covered.
- Deleted code: remove or update tests that no longer apply.
- The change is not complete until `pixi run cov` passes (coverage ≥90%) with the new/updated tests included.
- Never use `@pytest.mark.skip` or `@pytest.mark.xfail` without a comment linking to an open issue that explains why.

**What to test:** public behavior, not implementation details. Test the contract (inputs → outputs, side effects) rather than internal call sequences.

### Unit tests (`tests/unit/`)

- Test a single function or class in isolation — no I/O, no network, no database
- Fast: each test should complete in milliseconds
- Mocking external dependencies (DB clients, HTTP clients, filesystem) is acceptable
- Mirror the `src/<package>/` structure: `tests/unit/test_<module>.py`

### Integration tests (`tests/integration/`)

- Test components working together against real resources
- Mark every integration test: `@pytest.mark.integration`
- Use `tmp_path` for filesystem, real DB instances for database code, `respx` for HTTP interception — do not mock infrastructure
- Mirror the `src/<package>/` structure: `tests/integration/test_<module>.py`
- Each test must leave resources in the state it found them — use setup/teardown fixtures or DB transactions that roll back on completion; tests that leave state behind cause non-deterministic failures in subsequent runs

Both test types count toward the 90% coverage threshold enforced by `pixi run cov`.

### Fixtures and conftest.py

- `tests/conftest.py` — shared fixtures available to both unit and integration tests
- `tests/unit/conftest.py` — fixtures specific to unit tests
- `tests/integration/conftest.py` — fixtures specific to integration tests (e.g., DB connections, seeded test data)

---

## 4. Pixi Task Standard

Every project defines these tasks (names are the standard):

| Task | Purpose |
|---|---|
| `bootstrap` | One-time setup: install pre-commit hooks, etc. |
| `fmt` | `ruff format .` |
| `lint` | `ruff check .` |
| `check` | `mypy src/` |
| `test` | `pytest tests/unit/` — unit tests only (fast) |
| `test-integration` | `pytest tests/integration/` — integration tests only |
| `cov` | `pytest tests/ --cov=src --cov-report=term-missing --cov-fail-under=90` — full suite, coverage gate |
| `build` | Build the package distribution |
| `changelog` | `git cliff -o CHANGELOG.md` |
| `ci` | Full validation sequence (via `depends-on`): pre-commit → build → check → lint → cov |
| `act` | `act --container-architecture linux/amd64` (local CI via nektos/act) |

The `ci` task is the harness entry point — it must exit 0 before any task is considered done.

---

## 5. Git Workflow

**Branch naming:**

| Type | Prefix | Example |
|---|---|---|
| Feature | `feature/` | `feature/add-auth` |
| Bug fix | `bugfix/` | `bugfix/csv-export-crash` |
| Hotfix | `hotfix/` | `hotfix/payment-null-pointer` |

**Commit type mapping:**

| Branch prefix | Commit type |
|---|---|
| `feature/` | `feat:` |
| `bugfix/` | `fix:` |
| `hotfix/` | `fix:` |
| Any | `chore:`, `docs:`, `refactor:`, `perf:`, `test:` as appropriate |

**Rules:**
- PRs required for all merges to `main`; direct pushes require explicit user confirmation (see §7)
- Keep PRs focused on a single concern; one PR per feature, fix, or hotfix
- Delete the branch after it is merged
- Every commit: Conventional Commits format — `type(scope): description`
- Never use `--no-verify` — fix the hook failure instead
- Never amend a commit that has already been pushed

---

## 6. The Change Harness

The harness ensures every change leaves the repository valid: formatted, typed, linted, tested, and buildable. It operates at two levels — a fast inner loop during active development, and a full CI gate before every commit.

### Stop hook

A Claude Code session hook configured in `.claude/settings.json` automatically runs `pixi run ci` when a task completes. It blocks the session from marking any task done until the gate exits 0. This is not optional — never disable, bypass, or work around it. If the hook is not present in a project's settings, add it before starting work.

### Branch discipline

Before writing any code, confirm the working branch is `feature/`, `bugfix/`, or `hotfix/`. The harness validates code quality but does not enforce branch discipline — work committed on `main` can pass every gate and still violate §5. Check the branch first; switch if needed.

### Inner loop (during active development)

Run these frequently while writing code — do not wait until the end to discover failures:

1. `pixi run test` — run unit tests after every meaningful change; each should complete in milliseconds
2. `pixi run fmt` — auto-format before staging; avoids pre-commit auto-fix surprises at gate time
3. `pixi run lint && pixi run check` — surface ruff and mypy issues before they accumulate
4. `pixi run test-integration` — run when touching code that crosses a resource boundary (DB, HTTP, filesystem)

The inner loop is not a substitute for the CI gate. It is preparation for it. Never skip directly to `pixi run ci` as the first validation of a session.

### CI gate (before every commit)

`pixi run ci` is the final validation before staging and committing. The sequence is ordered fast-fail first — static checks run before the full test suite so type and lint errors surface without paying the cost of running tests:

1. `pre-commit run --all-files` — ruff format (auto-fix), ruff lint (auto-fix), and mypy across all changed files; conventional-commit validation runs separately at the commit-msg stage
2. `pixi run build` — verify the package is distributable; catches import errors and packaging mistakes
3. `pixi run check` — mypy across the full `src/` tree using the strict pyproject.toml config
4. `pixi run lint` — ruff across all files, zero warnings or errors
5. `pixi run cov` — full test suite (unit + integration), coverage ≥90% required

**Why mypy runs twice:** step 1 runs mypy incrementally per changed file via the pre-commit hook environment; step 3 runs mypy against the complete module graph in the full pixi environment with strict pyproject.toml settings. Both must pass — they catch different failure modes.

### Loop rules

When `pixi run ci` fails:

1. Read the full error output — identify the exact failing step and error message before touching any code
2. Record the error signature: step number + first line of the error message; confirm it changes with each iteration
3. **Pre-commit auto-fix trap:** if step 1 modifies files (ruff format or `--fix` auto-corrected code), those changes are unstaged — re-stage the modified files before re-running or the next run will fail identically against the original staged content
4. Apply one focused fix, then re-run `pixi run ci` from step 1 — never skip steps, never run steps out of order
5. If the error signature is unchanged after a fix, the fix had no effect — diagnose before retrying
6. If the **same error signature appears 10 consecutive times**: STOP, generate a triage report (see §11), and wait for human review — do not attempt an 11th fix

### Done condition

A task is complete when and only when `pixi run ci` exits 0 — all five steps pass with zero errors and zero warnings. No partial credit. No exceptions.

---

## 7. Control Constraints

**Confirm with user before:**
- Deleting any file or directory
- Force-pushing (`--force`, `--force-with-lease`)
- Pushing directly to `main` or `master`
- Adding a new runtime dependency
- Amending a pushed commit
- Destructive database operations (DROP, TRUNCATE, DELETE without WHERE)

**Never:**
- Commit `.env` files, API keys, tokens, or credentials
- Use `--no-verify` on any git command

---

## 8. Communication

- Concise responses — no trailing summaries of what was just done
- No emojis
- No multi-paragraph docstrings or comment blocks in generated code
- Code references: `file_path:line_number` format
- One sentence per status update while working
- Surface blockers immediately — never silently work around them

---

## 9. Memory Strategy

**Global memory** (`~/.claude/memory/`) — cross-project preferences and feedback. Check at session start.

**Per-project memory** — saved proactively (no need to ask) during a session when:
- A non-obvious architectural decision is made
- A project-specific footgun is discovered
- User feedback is given on an approach
- An environment quirk is found (e.g., "DB migrations require VPN")

Project memory lives in `.claude/memory/` within the project root.

---

## 10. Project Scaffold — Required Files

Every new Python project must have these from day one. Create them in this order.

### .gitignore

```gitignore
# Python
__pycache__/
*.py[cod]
*.egg-info/
dist/
build/
.eggs/

# Pixi
.pixi/

# Environment
.env
.env.*

# Tool caches
.mypy_cache/
.ruff_cache/
.pytest_cache/

# Local Claude overrides — never commit
CLAUDE.local.md

# Triage reports — never commit
triage-*.md
```

### pixi.toml

- Runtime deps in `[dependencies]` (conda-forge)
- Dev tooling in `[feature.dev.dependencies]`
- Package as editable install in `[pypi-dependencies]`
- Features kept separate: `build`, `test`, `lint`, `docs` as appropriate
- Standard tasks (see §4)
- `ci` task uses `depends-on` to chain the full validation sequence

### .pixi/config.toml

```toml
tls-root-certs = "system"   # use the OS system certificate store for TLS
```

### pyproject.toml

Tool configuration only — no runtime deps. Must include:

```toml
[tool.pytest.ini_options]
testpaths = ["tests"]
addopts = "-v --tb=short"
markers = [
    "integration: marks tests as integration tests requiring real I/O, network, or DB",
]

[tool.ruff]
line-length = 120
src = ["src", "tests"]

[tool.ruff.lint]
select = ["E", "F", "I", "UP", "B", "RUF", "D"]
ignore = ["E501"]

[tool.ruff.lint.pydocstyle]
convention = "google"

[tool.ruff.lint.isort]
known-first-party = ["<package_name>"]

[tool.mypy]
python_version = "3.12"
strict = true
warn_return_any = true
warn_unused_configs = true

[tool.git-cliff.changelog]
header = "# Changelog\n\n"
body = """
{% for group, commits in commits | group_by(attribute="group") %}
### {{ group | upper_first }}
{% for commit in commits %}
- {{ commit.message | upper_first }} ([{{ commit.id | truncate(length=7, end="") }}]({{ commit.id }}))
{% endfor %}
{% endfor %}
"""
trim = true

[tool.git-cliff.git]
conventional_commits = true
filter_unconventional = true
commit_parsers = [
    { message = "^feat", group = "Features" },
    { message = "^fix", group = "Bug Fixes" },
    { message = "^doc", group = "Documentation" },
    { message = "^perf", group = "Performance" },
    { message = "^refactor", group = "Refactoring" },
    { message = "^chore", skip = true },
]
```

### .pre-commit-config.yaml

```yaml
repos:
  - repo: https://github.com/compilerla/conventional-pre-commit
    rev: v4.4.0
    hooks:
      - id: conventional-pre-commit
        stages: [commit-msg]
  - repo: https://github.com/astral-sh/ruff-pre-commit
    rev: v0.15.17
    hooks:
      - id: ruff
        args: [--fix]
      - id: ruff-format
  - repo: https://github.com/pre-commit/mirrors-mypy
    rev: v2.1.0
    hooks:
      - id: mypy
        additional_dependencies: []
```

### .github/workflows/ci.yml

Two jobs: `unit` gives fast feedback on every push; `full` runs the complete harness including integration tests and is the merge gate.

```yaml
name: CI

on:
  push:
    branches: ["main"]
  pull_request:
    branches: ["main"]

jobs:
  unit:
    name: Unit Tests (Python ${{ matrix.python-version }})
    runs-on: ubuntu-latest
    continue-on-error: ${{ matrix.python-version == '3.14-dev' }}
    strategy:
      fail-fast: false
      matrix:
        python-version: ["3.12", "3.13", "3.14-dev"]

    steps:
      - uses: actions/checkout@v4

      - name: Set up Pixi
        uses: prefix-dev/setup-pixi@v0.8.1
        with:
          pixi-version: latest

      - name: Run unit tests
        run: pixi run test

  full:
    name: Full CI (Python ${{ matrix.python-version }})
    runs-on: ubuntu-latest
    continue-on-error: ${{ matrix.python-version == '3.14-dev' }}
    strategy:
      fail-fast: false
      matrix:
        python-version: ["3.12", "3.13", "3.14-dev"]
    # Add a services: block here for projects that need Postgres, Redis, etc.
    # Example:
    #   services:
    #     postgres:
    #       image: postgres:16
    #       env:
    #         POSTGRES_PASSWORD: postgres
    #       ports: ["5432:5432"]
    #       options: >-
    #         --health-cmd pg_isready
    #         --health-interval 10s
    #         --health-timeout 5s
    #         --health-retries 5

    steps:
      - uses: actions/checkout@v4

      - name: Set up Pixi
        uses: prefix-dev/setup-pixi@v0.8.1
        with:
          pixi-version: latest

      - name: Run full CI
        run: pixi run ci
```

### Project layout

Always `src/<package_name>/` (src layout). `tests/` at the project root, split into `unit/` and `integration/` subdirectories:

```
src/
  <package_name>/
tests/
  conftest.py
  unit/
    conftest.py        # unit-specific fixtures
    test_<module>.py
  integration/
    conftest.py        # DB connections, seeded data, etc.
    test_<module>.py
```

### README.md

Create at project start with at minimum these sections:

- **Project name and one-line description**
- **Badges** — CI status, coverage, PyPI version
- **Installation** — `pixi install` and any bootstrap steps
- **Quick start** — minimum to run the tool or import the library
- **Development** — how to run tests (`pixi run test`), full CI (`pixi run ci`)
- **License**

---

## 11. Triage Report

When the harness halt condition triggers (same error × 10 consecutive attempts), create `triage-<YYYYMMDD-HHMMSS>.md` in the project root:

```markdown
# Triage Report — <timestamp>

## Failing Step
<which pixi task failed and the exact command>

## Error
<exact error output, untruncated>

## Attempts
| # | Fix attempted | Outcome |
|---|---|---|
| 1 | <description> | Same error / new error |

## Hypothesis
<most likely root cause>

## Suggested Next Steps
1. <most promising thing for the human to try>
```
