---
name: worktree-guard-bash-shapes
description: Worktree-isolation guard rejects Bash with multiple heredocs or `git -C ..` relative paths; create files with Write, use absolute git -C paths
metadata:
  type: feedback
---

The worktree-isolation guard refuses Bash commands it cannot verify: several `cat > file <<EOF` heredocs in one call ("too complex") and `git -C ..` (path computed at runtime).

**Why:** Observed during android-079 (2026-10-10); both calls were rejected outright, costing a round trip.

**How to apply:** Create new source files with the Write tool; for git always `git -C <absolute worktree path>`. A single `python3 - <<'EOF'` edit script per call was accepted.
