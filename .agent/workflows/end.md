---
description: Task completion workflow with code review checklist and Git commit/push process. Ensures documentation updates, lessons learned capture, and consistent commit numbering in Polish.
---

---

name: End
description: Task completion workflow with code review checklist and Git commit/push process. Ensures documentation updates, lessons learned capture, and consistent commit numbering in Polish
---

# End

## How to use this skill

When the user invokes this skill (e.g., `/end`), the LLM will guide them through the task completion workflow.

**Example usage:**

```
/end
```

Your job as LLM is to:

1. **Guide** the user through the code review checklist
2. **Verify** documentation needs updating
3. **Prepare** the commit message with proper numbering
4. **Execute** the Git commit and push

---

## Workflow

### Step 1: Code Review

**Check against these files:**

- `docs/code-review.md` - follow the code review checklist
- `lessons-learned.md` - add/update key takeaways from:
  - Completed tasks
  - Resolved technical issues
  - Ideas for process improvement

**Instructions for LLM:**

1. Check if `docs/code-review.md` exists and review its checklist
2. Ask the user to confirm all code review points are addressed
3. Check if `lessons-learned.md` exists
4. Ask the user what lessons learned should be documented from this session
5. Update or create `lessons-learned.md` with new insights

---

### Step 2: Documentation Update

**Verify if updates are needed:**

1. Check if `README.md` needs updating (new features, changes in usage, etc.)
2. Check if `docs/` folder needs updating (refer to `docs/contributing.md` for guidelines)

**Instructions for LLM:**

1. Review changes made during the session
2. Identify if README.md or docs/ require updates
3. If updates needed, make them before committing
4. If `docs/contributing.md` exists, follow its documentation guidelines

---

### Step 3: Git Commit

**Commit message format:**

```
#N description of changes in Polish
```

**Rules:**

- **N** = continuation of numbering from the previous commit (parse #XXX from last commit on main)
- **Description** = changes described in Polish
- **No Polish special characters**: ą=a, ć=c, ę=e, ł=l, ń=n, ó=o, ś=s, ź=z, ż=z

**Instructions for LLM:**

1. Fetch and get last commit: `git fetch origin main && git log origin/main --oneline -1`
2. Parse number from commit message (e.g., `#411 add merge.md` → 411)
3. Use N = parsed_number + 1 for the new commit number
4. Generate commit message in Polish without special characters
5. Show the commit message to user for approval
6. Execute: `git add .`
7. Execute: `git commit -m "#N description"`

**Example:**

```bash
git fetch origin main
git log origin/main --oneline -1
# Output: 58d09e1 #411 add merge.md workflow
# Parsed: 411, Next: 412
git add .
git commit -m "#412 Refaktoryzacja struktury plikow i aktualizacja dokumentacji"
```

---

### Step 4: Git Push

**Instructions for LLM:**

1. After successful commit, execute: `git push`
2. Confirm push was successful
3. Summarize what was committed and pushed

---

## Completion Summary

After finishing all steps, provide the user with:

- ✅ Code review completed
- ✅ Lessons learned documented
- ✅ Documentation updated (if needed)
- ✅ Commit #N created with message: "..."
- ✅ Changes pushed to remote repository

---

## Next Step: Merge to Main

After `/end` workflow, user can merge to main using:

1. **VS Code Task:** `Ctrl+Shift+P` → "Tasks: Run Task" → "Git: PR + Merge to Main"
2. **Terminal:** `.\scripts\run_merge_pr.bat`
3. **Claude workflow:** `/merge` (see `.agent/workflows/merge.md`)

---

## Error Handling

**If any step fails:**

- Stop the workflow
- Explain the error to the user
- Ask how to proceed (fix and retry, or skip)
- Do not proceed to next steps until current step succeeds
