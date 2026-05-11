---
name: commit
description: Stage, commit, push, open a PR, and merge to main. Use ONLY on explicit commit intent — user says "commit", "ship it", "push this", "open a PR", "merge to main", "let's commit this", or prefixes with `/commit`. Do NOT auto-invoke on vague end-of-task phrases ("we're done", "wrap up") — those require explicit confirmation first. Runs the standard commit-PR-merge cycle; never force-pushes or skips hooks.
argument-hint: "[optional: commit message]"
allowed-tools: ["Bash", "Read", "Glob", "Task"]
---

# Commit, PR, and Merge

Stage changes, verify quality gates, commit with a descriptive message, create a PR, and merge to main.

## Commit Message Contract

Every commit message MUST include:
1. **WHY** the change was made (not just WHAT changed).
2. **Phase and stage reference** when applicable (e.g., "Phase 1, stage G").
3. **Claude commits** must include: `Made by: Claude (model: <model>)`.
4. **User-directed changes** must include: `Reason given by user: "<verbatim quote>"`.

## Steps

### Step 0: Quality Gate (Pre-Commit)

**Run before branching.** For every changed `.R` or `.do` file, review against
the quality rubrics in `.claude/rules/quality-gates.md`.

- If any file scores below **80**, halt and report the findings. The user must
  either fix the issues or explicitly override with phrases like *"commit anyway"*
  or *"skip quality gate"*.
- If all files score 80+, continue.

For changed pipeline scripts (A-I), also verify against `.claude/rules/verification-protocol.md`:
- If sample data available: run and compare to gold standard.
- If not available: state "static-checked only" in commit body.

### Step 1: Check current state

```bash
git status
git diff --stat
git log --oneline -5
```

### Step 2: Create a branch

```bash
git checkout -b <short-descriptive-branch-name>
```

### Step 3: Stage files

Add specific files (never use `git add -A`):

```bash
git add <file1> <file2> ...
```

Do NOT stage `.claude/settings.local.json` or any files containing secrets.

### Step 4: Commit with a descriptive message

If `$ARGUMENTS` is provided, use it as the commit message. Otherwise, analyze the staged changes and write a message that explains *why*, not just *what*.

```bash
git commit -m "$(cat <<'EOF'
<commit message here>
EOF
)"
```

### Step 5: Push and create PR

```bash
git push -u origin <branch-name>
gh pr create --title "<short title>" --body "$(cat <<'EOF'
## Summary
<1-3 bullet points>

## Test plan
<checklist>

🤖 Generated with [Claude Code](https://claude.com/claude-code)
EOF
)"
```

### Step 6: Merge and clean up

```bash
gh pr merge <pr-number> --merge --delete-branch
git checkout main
git pull
```

### Step 7: Report

Report the PR URL and what was merged.

## Important

- **Never skip Step 0.** Quality gates catch broken compilation, bad citations, and hardcoded paths before they reach `main`. If the user insists on skipping, record their override reason in the commit message.
- Always create a NEW branch — never commit directly to main.
- Exclude `settings.local.json` and sensitive files from staging.
- Use `--merge` (not `--squash` or `--rebase`) unless asked otherwise.
- If the commit message from `$ARGUMENTS` is provided, use it exactly.
