---
name: feedback_stage_files_explicitly
description: "Never `git add -A` or `git add .` in any project — stage the files you edited, by explicit path"
metadata:
  node_type: memory
  type: feedback
  originSessionId: 3a7dc7cf-63b9-4b23-ab50-6b3c2f4d65ed
  modified: 2026-09-08T00:00:00.000Z
---

Stage files **by explicit path, in every project**. Never `git add -A`, never `git add .`.

**Why (the user's reasoning, 2026-09-08):** a blanket add sweeps whatever happens to be sitting
in the working tree. A backup file, an editor scratch file, a credential dump, a `.env` variant
or anything else not covered by `.gitignore` gets committed and then very possibly pushed.
`.gitignore` is a denylist, so it only protects against what somebody already thought of, and
the cost of being wrong once is a secret in the repository's history — which a later `git rm`
does not remove.

**How to apply:**

- Stage what you edited: `git add path/one path/two`, or `git add` over a list you constructed
  and can name aloud.
- Before staging, look at what is actually there:
  - `git status --short`
  - `git ls-files --others --exclude-standard` — the one that matters, because it lists exactly
    the untracked files a blanket add would sweep.
- A rename, a mechanical refactor or a large generated change is not an excuse. If the file
  list is long, build it from the edit itself — the files you rewrote — not from "everything
  dirty".
- `git commit -a` has the same problem for tracked files; prefer explicit paths there too.
- Same caution for `git stash` without a path, and for `git clean`.

Raised after a `git add -A` on a 19-file rename commit. Nothing unintended was staged that time,
because there were no untracked non-ignored files — but the practice is the point, not the
outcome of one instance.

Related: [[feedback_pixi_only_runner]] — same shape of instruction, a tool default that is
convenient and occasionally destructive, so the safe form is always the explicit one.
