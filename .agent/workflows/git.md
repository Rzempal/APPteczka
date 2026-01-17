---
description:
  Workflow for AI agent to diagnose and fix Git synchronization issues (upstream, diverged branches,
  rebase).
---

# Git Diagnosis and Sync Workflow

## How to use this skill

When the user invokes this skill (e.g., `/git` or when reporting sync issues), the LLM will perform
a "technical checkup" of the Git repository and ensure local branches are correctly aligned with the
remote.

**Example usage:** `/git`

---

## Workflow

### Step 1: Deep Diagnosis

**Instructions for LLM:**

1. Check current branch and tracking status: `git branch -vv`
2. Check for uncommitted changes: `git status`
3. Fetch latest metadata from remote: `git fetch origin`
4. Compare local branch with its remote counterpart:
   `git log HEAD..origin/<current_branch> --oneline` and
   `git log origin/<current_branch>..HEAD --oneline`

---

### Step 2: Correcting Upstream (If needed)

**Instructions for LLM:** _If the current branch (especially `main`) is tracking the wrong remote
branch or no branch at all:_

1. Propose setting the correct upstream:
   `git branch --set-upstream-to=origin/<branch_name> <branch_name>`
2. Execute after user confirmation.

---

### Step 3: Reconciling Diverged Branches

**Instructions for LLM:** _If both local and remote have new, different commits (diverged):_

1. **Always prefer rebase** to maintain a clean history: `git pull --rebase origin <branch_name>`
2. **If conflicts occur:**
   - Inform the user immediately.
   - List the conflicted files.
   - Ask the user to resolve them or guide them through the resolution.
   - Once resolved, use `git rebase --continue`.

---

### Step 4: Final Sync & Cleanup

**Instructions for LLM:**

1. If local is ahead: `git push origin <current_branch>`
2. Verify final state: `git status`
3. Ensure the output says: "Your branch is up to date with 'origin/...'."

---

## Completion Summary

After finishing, report:

- ✅ Current branch and its upstream status.
- ✅ Results of fetch/sync operation.
- ✅ Cleanliness of the working tree.
- ✅ Any actions taken (rebase, push, upstream fix).

---

## Error Handling

**If any command fails:**

- Do not attempt destructive commands (like `git reset --hard`) without explicit, double
  confirmation from the user.
- Explain precisely why it failed (e.g., "Conflict in file X", "Permission denied").
