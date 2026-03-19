# Claude Code CLI Auto-Pilot Hooks Implementation Plan

> **For agentic workers:** REQUIRED: Use superpowers:subagent-driven-development (if subagents available) or superpowers:executing-plans to implement this plan. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Configure Claude Code CLI with automatic formatting (Terraform + YAML) and git add after Edit/Write, without freezing.

**Architecture:** Single PostToolUse hook in settings.json that runs formatters with 3s timeout, then git add. Security via Hookify (already active) + permissions deny list.

**Tech Stack:** Claude Code CLI hooks, jq, terraform fmt, yq, git worktree (for testing)

---

## Chunk 1: Environment Setup and Verification

### Task 1: Verify Prerequisites

**Files:**
- None (verification only)

- [ ] **Step 1: Check jq installation**

Run: `jq --version`
Expected: `jq-1.6` or similar (any version works)
If FAIL: `sudo apt install jq` or `brew install jq`

- [ ] **Step 2: Check terraform installation**

Run: `terraform version`
Expected: `Terraform v1.0.0` or higher
If FAIL: Install from https://developer.hashicorp.com/terraform/install

- [ ] **Step 3: Check yq installation**

Run: `yq --version`
Expected: `yq version 4.x.x` or higher
If FAIL: `snap install yq` or `brew install yq`

- [ ] **Step 4: Check timeout/gtimeout installation**

Run (Linux): `timeout --version`
Run (macOS): `gtimeout --version`
Expected: Version output
If FAIL (macOS): `brew install coreutils`

- [ ] **Step 5: Check git worktree support**

Run: `git worktree list`
Expected: List of worktrees (or empty)
If FAIL: Update git to 2.17+

- [ ] **Step 6: Verify platform support**

Run: `uname -s`
Expected: `Linux` (fully supported) or `Darwin` (macOS, needs gtimeout)
If FAIL (Windows or other non-Unix): Stop - Unix-like OS required (Linux/macOS/BSD)

---

### Task 2: Create Testing Worktree

**Files:**
- Create: git worktree at `../test-hooks`

- [ ] **Step 1: Verify current location**

Run: `pwd` and `git branch --show-current`
Expected: Shows main repo path and current branch
Note: Record the branch name shown (e.g., `main`, `master`) for next step

- [ ] **Step 2: Create worktree branch**

Run: `git worktree add ../test-hooks <BRANCH_FROM_STEP_1>`
Expected: Worktree created successfully
If FAIL (directory exists): `git worktree remove ../test-hooks 2>/dev/null; git worktree add ../test-hooks <BRANCH_FROM_STEP_1>`

- [ ] **Step 3: Navigate to worktree**

Run: `cd ../test-hooks`
Expected: Now in isolated testing environment

- [ ] **Step 4: Verify worktree is separate**

Run: `git status` and `pwd`
Expected: Shows clean status in `/path/to/test-hooks`

- [ ] **Step 5: Verify worktree in git list**

Run: `git worktree list`
Expected: Shows `../test-hooks` in worktree list
If FAIL: Worktree creation failed, check git errors

---

## Chunk 2: Create Test Files

### Task 3: Create Test Infrastructure

**Files:**
- Create: `test-files/terraform-test.tf`
- Create: `test-files/yaml-test.yml`
- Create: `test-files/docker-test`
- Create: `test-files/shell-test.sh`

- [ ] **Step 1: Create test directory**

Run: `mkdir -p test-files`

- [ ] **Step 2: Create Terraform test file (1KB)**

Write to `test-files/terraform-test.tf`:
```hcl
# Test terraform file - poorly formatted
resource "aws_s3_bucket" "test" {
bucket = "my-test-bucket"
tags = {
Name = "Test"
Environment = "Dev"
}
}
```

- [ ] **Step 3: Create YAML test file (1KB)**

Write to `test-files/yaml-test.yml`:
```yaml
# Test YAML - poorly formatted
apiserver:
  enabled:true
  replicaCount:3
  image:
    repository:nginx
    tag:latest
  resources:
    limits:
      memory:256Mi
```

- [ ] **Step 4: Create Dockerfile test (poorly formatted)**

Write to `test-files/Dockerfile`:
```dockerfile
FROM node:18
WORKDIR /app
COPY . .
RUN npm install
CMD ["node","server.js"]
```

- [ ] **Step 5: Create Shell test file (should NOT be formatted)**

Write to `test-files/shell-test.sh`:
```bash
#!/bin/bash
# Poorly formatted shell - should remain unchanged
echo "hello"
if [ -f "test.txt" ]; then
  echo "exists"
fi
```

- [ ] **Step 6: Verify test files created**

Run: `ls -la test-files/`
Expected: 4 files listed

- [ ] **Step 7: Commit test files**

Run: `git add test-files/ && git commit -m "test: add test files for hooks validation"`

---

## Chunk 3: Apply Configuration

### Task 4: Create New settings.json

**Files:**
- Create: `.claude/settings.json`
- Backup: `.claude/settings.json.backup`

- [ ] **Step 1: Backup existing settings (if exists)**

Run: `cp .claude/settings.json .claude/settings.json.backup 2>/dev/null || echo "No existing settings"`

- [ ] **Step 2: Create new settings.json with hooks**

Write to `.claude/settings.json`:
```json
{
  "$schema": "https://json.schemastore.org/claude-code-settings.json",
  "enabledPlugins": {
    "local-devops@local": true
  },
  "permissions": {
    "defaultMode": "acceptEdits",
    "deny": [
      "Read(.env)",
      "Read(secrets/**)",
      "Write(.env)",
      "Write(secrets/**)"
    ]
  },
  "hooks": {
    "PostToolUse": [
      {
        "matcher": "Edit|Write",
        "hooks": [
          {
            "type": "command",
            "command": "FILE=$(jq -r '.tool_input.file_path // empty' 2>/dev/null); case \"$FILE\" in *.tf|*.tfvars) timeout 3s terraform fmt -diff=false \"$FILE\" 2>/dev/null ;; *.yml|*.yaml) timeout 3s yq --prettyPrint -i \"$FILE\" 2>/dev/null ;; */Dockerfile|Dockerfile) timeout 3s yq --prettyPrint -i \"$FILE\" 2>/dev/null ;; esac; git add \"$FILE\" 2>/dev/null || true"
          }
        ]
      }
    ]
  }
}
```

- [ ] **Step 3: Verify JSON is valid**

Run: `jq . .claude/settings.json > /dev/null`
Expected: No output (exit code 0)
If FAIL: JSON syntax error, fix above

- [ ] **Step 4: Verify settings structure**

Run: `jq '.hooks.PostToolUse[0].matcher' .claude/settings.json`
Expected: `"Edit|Write"`

- [ ] **Step 5: Commit new settings**

Run: `git add .claude/settings.json && git commit -m "feat: add PostToolUse hooks for auto-format and git add"

---

## Chunk 4: Run Tests

### Task 5: Test Terraform Formatting

**Files:**
- Test: `test-files/terraform-test.tf`

- [ ] **Step 1: Trigger Edit on Terraform file**

Open `test-files/terraform-test.tf` in editor
Make a trivial edit (add a space or comment)
Save the file

- [ ] **Step 2: Wait for hook to complete**

Wait 2-3 seconds

- [ ] **Step 3: Verify file was formatted**

Run: `git diff test-files/terraform-test.tf`
Expected: Formatting changes applied (proper indentation)

- [ ] **Step 4: Verify file was staged**

Run: `git status test-files/terraform-test.tf`
Expected: Shows "new file" or "modified" in green (staged)

- [ ] **Step 5: Verify performance (< 1s for 1KB file)**

Note: Operation should feel instantaneous

---

### Task 6: Test YAML Formatting

**Files:**
- Test: `test-files/yaml-test.yml`

- [ ] **Step 1: Trigger Edit on YAML file**

Open `test-files/yaml-test.yml` in editor
Make a trivial edit (add a space or comment)
Save the file

- [ ] **Step 2: Wait for hook to complete**

Wait 2-3 seconds

- [ ] **Step 3: Verify file was formatted**

Run: `git diff test-files/yaml-test.yml`
Expected: Proper YAML formatting with correct indentation

- [ ] **Step 4: Verify file was staged**

Run: `git status test-files/yaml-test.yml`
Expected: Shows "modified" in green (staged)

---

### Task 7: Test Dockerfile Formatting

**Files:**
- Test: `test-files/Dockerfile`

- [ ] **Step 1: Trigger Edit on Dockerfile**

Open `test-files/Dockerfile` in editor
Make a trivial edit
Save the file

- [ ] **Step 2: Wait for hook to complete**

Wait 2-3 seconds

- [ ] **Step 3: Verify file was formatted**

Run: `git diff test-files/Dockerfile`
Expected: YAML-like formatting applied (yq treats Dockerfile as YAML)

- [ ] **Step 4: Verify file was staged**

Run: `git status test-files/Dockerfile`
Expected: Shows "modified" in green (staged)

---

### Task 8: Test Shell File (NO Formatting)

**Files:**
- Test: `test-files/shell-test.sh`

- [ ] **Step 1: Trigger Edit on Shell file**

Open `test-files/shell-test.sh` in editor
Make a trivial edit
Save the file

- [ ] **Step 2: Wait for hook to complete**

Wait 2-3 seconds

- [ ] **Step 3: Verify file was NOT formatted**

Run: `git diff test-files/shell-test.sh`
Expected: Only shows your trivial edit, NOT formatting changes

- [ ] **Step 4: Verify file was still staged**

Run: `git status test-files/shell-test.sh`
Expected: Shows "modified" in green (staged)

---

### Task 9: Test Permissions Deny (.env)

**Files:**
- Create: `test-files/.env`

- [ ] **Step 1: Attempt to create .env file**

Write to `test-files/.env`:
```bash
SECRET_KEY=supersecret
DB_PASSWORD=mypassword
```

- [ ] **Step 2: Verify access was blocked**

Expected: Tool denies write to `.env` file
Or: Tool shows warning/error

- [ ] **Step 3: Verify .env was NOT created**

Run: `ls test-files/.env 2>/dev/null`
Expected: "No such file or directory"

---

### Task 10: Performance Test with Large File

**Files:**
- Create: `test-files/large.tf` (100KB)

- [ ] **Step 1: Create large Terraform file**

Run:
```bash
cat > test-files/large.tf << 'EOF'
# Large terraform file for performance testing
$(for i in {1..500}; do
  echo "resource \"aws_s3_bucket\" \"bucket_$i\" {"
  echo "  bucket = \"my-bucket-$i\""
  echo "  tags = {"
  echo "    Name = \"Bucket-$i\""
  echo "    Environment = \"Test\""
  echo "  }"
  echo "}"
done)
EOF
```

- [ ] **Step 2: Measure edit operation time**

Run: `time (echo "# comment" >> test-files/large.tf)`
Expected: < 2s (hook timeout is 3s)

- [ ] **Step 3: Verify file was staged**

Run: `git status test-files/large.tf`
Expected: Shows "modified" in green (staged)

---

### Task 11: Load Test (10 Files Sequential)

**Files:**
- Create: `test-files/load-test-{1..10}.tf`

- [ ] **Step 1: Create 10 test files**

Run:
```bash
for i in {1..10}; do
  echo "resource \"null_resource\" \"test_$i\" {}" > "test-files/load-test-$i.tf"
done
```

- [ ] **Step 2: Measure total time**

Run:
```bash
time (for i in {1..10}; do
  echo "# comment" >> "test-files/load-test-$i.tf"
  sleep 0.1  # Simulate typing delay
done)
```
Expected: < 20s total (2s avg per file)

- [ ] **Step 3: Verify all files staged**

Run: `git status test-files/load-test-*.tf`
Expected: All 10 files show as staged

---

## Chunk 5: Security Verification

### Task 12: Verify Hookify Integration

**Files:**
- Verify: `.claude/hookify.block-dangerous-commands.local.md`
- Verify: `.claude/hookify.warn-secrets-files.local.md`

- [ ] **Step 1: Verify Hookify files exist**

Run: `ls -la .claude/hookify*.md`
Expected: 5 hookify files listed

- [ ] **Step 2: Test dangerous command block**

Run: `echo "rm -rf /tmp/test" | grep -E "rm\s+-rf"`
Expected: Matches pattern (Hookify would block)

- [ ] **Step 3: Verify settings deny list**

Run: `jq '.permissions.deny' .claude/settings.json`
Expected: Shows `.env` and `secrets/**` in deny list

---

## Chunk 6: Rollback Testing

### Task 13: Test Rollback Procedure

**Files:**
- Restore: `.claude/settings.json.backup`

- [ ] **Step 1: Test settings.json revert**

Run: `git checkout HEAD -- .claude/settings.json`
Expected: settings.json reverted to before hooks

- [ ] **Step 2: Verify hooks are gone**

Run: `jq '.hooks.PostToolUse' .claude/settings.json`
Expected: `null` or empty

- [ ] **Step 3: Restore hooks for continued use**

Run: `git checkout HEAD~1 -- .claude/settings.json`
Expected: settings.json with hooks restored

---

## Chunk 7: Final Verification and Apply to Main

### Task 14: Final Checklist

**Files:**
- All test files and settings

- [ ] **Step 1: Verify all tests passed**

Checklist:
- [ ] Terraform formatting works
- [ ] YAML formatting works
- [ ] Dockerfile formatting works
- [ ] Shell files NOT formatted (correct)
- [ ] .env write blocked
- [ ] Performance < 2s typical
- [ ] Large file timeout works (3s)
- [ ] Load test passes (10 files < 20s)
- [ ] Hookify still active
- [ ] Permissions deny list works

- [ ] **Step 2: Clean up test files**

Run: `git clean -fd test-files/`
Or: `rm -rf test-files/`

- [ ] **Step 3: Verify worktree is clean**

Run: `git status`
Expected: Only settings.json and related commits

---

### Task 15: Apply to Main Branch

**Files:**
- Apply to: Main branch `.claude/settings.json`

- [ ] **Step 1: Navigate back to main repo**

Run: `cd ..` (to main repo)

- [ ] **Step 2: Copy settings.json from worktree**

Run: `cp ../test-hooks/.claude/settings.json .claude/settings.json`

- [ ] **Step 3: Verify settings in main**

Run: `jq '.hooks.PostToolUse' .claude/settings.json`
Expected: Shows hook configuration

- [ ] **Step 4: Test on main branch**

Edit any `.tf` or `.yml` file
Expected: Formatting and git add work

- [ ] **Step 5: Commit to main**

Run:
```bash
git add .claude/settings.json
git commit -m "feat: apply auto-pilot hooks configuration

- Terraform + YAML formatting with 3s timeout
- Git add after Edit/Write (not Bash)
- Security: Hookify + .env/secrets deny list
- Tested in isolated worktree

Fixes: Claude Code CLI freezing with old hooks
Related: docs/superpowers/specs/2026-03-19-claude-code-cli-hooks-design.md

Co-Authored-By: Claude Sonnet 4.6 <noreply@anthropic.com>"
```

- [ ] **Step 6: Remove worktree (cleanup)**

Run: `git worktree remove ../test-hooks`

- [ ] **Step 7: Prune worktree list**

Run: `git worktree prune`

- [ ] **Step 8: Verify worktree removed**

Run: `git worktree list`
Expected: Worktree no longer listed

---

## Chunk 8: Documentation

### Task 16: Update Documentation

**Files:**
- Create: `CLAUDE.md` (if not exists)
- Or: Append to existing `CLAUDE.md`

- [ ] **Step 1: Document hooks in CLAUDE.md**

Append to `CLAUDE.md`:
```markdown
## Auto-Pilot Hooks Configuration

This repo uses Claude Code CLI with automatic formatting:

- **Formatters:** Terraform (*.tf), YAML (*.yml, *.yaml, Dockerfile)
- **Git Add:** Automatic after Edit/Write (not Bash)
- **Timeout:** 3s per formatter (prevents freezing)
- **Security:** Hookify blocks dangerous commands, .env/secrets protected

### Troubleshooting

If hooks cause issues:
1. Revert: `git checkout HEAD -- .claude/settings.json`
2. Or disable: `echo '{"hooks":{}}' > .claude/settings.json`
```

- [ ] **Step 2: Commit documentation**

Run: `git add CLAUDE.md && git commit -m "docs: document auto-pilot hooks configuration"`

---

## Chunk 9: Final Validation

### Task 17: End-to-End Validation

**Files:**
- All configurations

- [ ] **Step 1: Complete workflow test**

1. Create new `.tf` file with bad formatting
2. Edit and save
3. Verify: File formatted + Staged for commit
4. Run: `git status` to confirm

- [ ] **Step 2: Verify no freezing**

Edit multiple files in quick succession
Expected: CLI remains responsive, no freezing

- [ ] **Step 3: Verify security**

Try to edit `.env` file
Expected: Blocked or warning shown

- [ ] **Step 4: Final commit**

Run: `git commit -m "test: validate auto-pilot hooks working"`
Expected: Commit succeeds with formatted files

---

## Completion Checklist

- [ ] All 17 tasks completed
- [ ] All tests passing
- [ ] Documentation updated
- [ ] Worktree cleaned up
- [ ] Main branch updated
- [ ] No freezing issues
- [ ] Security verified

**Next Steps:**
- Monitor hook performance in daily use
- Add more formatters if needed (shfmt, prettier) - but test for freezing first
- Adjust timeout values if needed
