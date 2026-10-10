---
name: worktree-guard-compound-git
description: Worktree-isolated agents get commands refused when git appears inside a compound command or a long heredoc; run git alone, edit big snippets via Edit tool
metadata:
  type: feedback
---

In an isolated agent worktree the guard refuses whole Bash calls that combine `git ...`
with other commands (`make ...; git -C ... status`) and sometimes long python heredocs
that edit files ("too complex to verify that it stays inside the worktree").

**Why:** seen on android-087 (2026-10-10); the call is rejected, nothing runs.
**How to apply:** run `git status`/`git add`/`git commit` as standalone commands from
the worktree cwd; for large multi-line code insertions prefer the Edit tool over a
python heredoc. Short `python3 /dev/stdin <file> <<'EOF'` replacements did pass.
