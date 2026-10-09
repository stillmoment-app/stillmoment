---
name: worktree-guard-commands
description: Worktree-isolation guard rejects shell vars as paths, `git -C .`, heredoc-with-git chains; auto-mode classifier rejects edits that temporarily remove a check — split commits via partial patch instead
metadata:
  type: feedback
---

In a worktree-isolated run the guard refuses commands it cannot prove stay inside the worktree:
`W=...; sed ... $W/file`, `git -C . log`, `cat > f <<EOF ... EOF; git diff`, `printf -- '- x'` in chains.
Use plain relative paths from the worktree cwd, one command per call, and the Write tool for file content.

The auto-mode classifier also denied (as "security weaken") temporarily removing a guard check from a
Makefile and commenting out an `#if DEBUG` gate for a negative build experiment.

**Why:** Both cost a denied call each during the release-hardening task (2026-10-09).
**How to apply:** To split one file's changes over two commits, `git diff -- file > scratch.patch`,
trim hunks with head/Write, `git apply --cached scratch.patch` — no reverting edits needed.
Don't plan negative experiments that disable safety gates in source; report them as not performed.
