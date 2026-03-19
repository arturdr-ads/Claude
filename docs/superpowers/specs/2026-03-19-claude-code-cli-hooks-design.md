# Claude Code CLI: Auto-Pilot Hooks Configuration

**Date:** 2026-03-19
**Status:** Revised - Pending Re-Review
**Author:** Claude Sonnet 4.6 (with user collaboration)
**Revision:** 1.0 - Fixed issues from spec review

---

## Problem Statement

The Claude Code CLI was experiencing freezing/lagging issues when using PostToolUse hooks for automatic formatting and git add. The Gemini AI assistant removed most of the `settings.json` configuration (from 61 lines to 5 lines) to resolve the freezing, but this eliminated useful automation features.

**Root Cause Analysis:**
- PostToolUse hook was running `npx prettier` which can take 5-10 seconds
- Multiple formatters ran sequentially on every Edit/Write
- `git add .` after every Bash command is slow on large repos

---

## Goals

Restore automatic formatting and git add functionality **without causing freezing**, optimized for DevOps workflows (Terraform + YAML).

### Success Criteria
- ✅ Automatic formatting for Terraform and YAML files
- ✅ Automatic git add after Edit/Write (not Bash)
- ✅ Security via Hookify (already active) + permissions deny list
- ✅ Performance < 2s per operation
- ✅ No freezing even with large files

---

## Prerequisites

### Required Tools

| Tool | Minimum Version | Installation |
|------|-----------------|--------------|
| `jq` | Any | `sudo apt install jq` (Ubuntu/Debian) or `brew install jq` (macOS) |
| `terraform` | 1.0+ | [Terraform installs](https://developer.hashicorp.com/terraform/install) |
| `yq` | 4.0+ | `snap install yq` or `brew install yq` |
| `timeout` | Any (GNU coreutils) | Pre-installed on Linux, use `gtimeout` on macOS |
| `git worktree` | 2.17+ | Pre-installed with git |

### Platform Support
- ✅ **Linux** (native - fully supported)
- ⚠️ **macOS** (requires `gtimeout` from coreutils, not standard `timeout`)
- ❌ **Windows** (not supported - shell commands not compatible)

### Verification
```bash
# Run before implementation
terraform version
jq --version
yq --version
timeout --version || gtimeout --version
git worktree list
```

---

## Non-Goals (Explicitly Out of Scope)

- JavaScript/TypeScript/JSON formatting (use prettier manually when needed)
- Shell script formatting (use shfmt manually when needed)
- Pre-commit hooks (handled by Hookify)
- Formatting files edited via Bash commands (ex: `sed -i`)

---

## Architecture

```
┌─────────────────────────────────────────────────────────┐
│                   settings.json                         │
├─────────────────────────────────────────────────────────┤
│  enabledPlugins: local-devops@true                      │
│  permissions.deny: [.env, secrets/**]                   │
│  hooks.PostToolUse:                                     │
│    ├── matcher: Edit|Write                              │
│    └── command: formata (tf|yml|yaml) + git add         │
└─────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────┐
│              Hookify (already exists, keep)             │
├─────────────────────────────────────────────────────────┤
│  ✅ block-dangerous-commands                            │
│  ✅ warn-secrets-files                                  │
│  ✅ warn-terraform-state                                │
│  ✅ warn-node-modules                                   │
│  ✅ require-verification                                │
└─────────────────────────────────────────────────────────┘
```

**Flow:**
```
Edit/Write → PostToolUse hook → (terraform fmt OR yq) → git add → done
```

---

## Configuration

### Final settings.json

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

### Component Details

| Component | Value | Rationale |
|-----------|-------|-----------|
| `jq -r '.tool_input.file_path // empty'` | Extract file path | Works even if extraction fails |
| `timeout 3s` | Limit formatter runtime | Prevents freezing on large files (safety net) |
| `2>/dev/null` | Suppress errors | Missing formatter doesn't break hook |
| `|| true` | Continue on failure | Git add failure doesn't interrupt |
| `-diff=false` | Explicit flag | Consistency, speed (already default) |
| `yq --prettyPrint -i` | In-place YAML edit | Modifies file directly |
| `*/Dockerfile\|Dockerfile` | Dockerfile pattern | Matches both `Dockerfile` and `path/Dockerfile` |
| `git add "$FILE"` | Add only edited file | More precise than `git add .` |

### Performance Expectations

| File Size | Expected Time | Timeout |
|-----------|---------------|---------|
| < 10KB (typical) | < 1s | 3s (safety net) |
| 10-100KB (large) | < 2s | 3s (safety net) |
| > 100KB (huge) | Timeout at 3s | 3s (prevents freeze) |

**Note:** The 3s timeout is a safety net. Typical operations complete in < 2s. If formatter hits timeout, it's aborted but doesn't freeze the CLI.

---

## Testing Plan

### Test Environment
- Use **git worktree** for isolated testing
- Prevents polluting the main branch

### Test Cases

| # | Test | Expected | Verification |
|---|------|----------|--------------|
| 1 | Edit `.tf` file (1KB) | File formatted | `git diff` shows changes |
| 2 | Edit `.tf` file (100KB) | File formatted | `git diff` shows changes |
| 3 | Edit `.yml` file (1KB) | File formatted | `git diff` shows changes |
| 4 | Edit `.yml` file (100KB) | File formatted | `git diff` shows changes |
| 5 | Edit `Dockerfile` | File formatted | `git diff` shows changes |
| 6 | Edit `.sh` file | No formatting | `git diff` empty |
| 7 | Any Edit/Write | File staged | `git status` shows staged |
| 8 | Read `.env` | Blocked/error | Tool denies access |
| 9 | Run `rm -rf` | Blocked by Hookify | Hookify warning shown |
| 10 | Performance (1KB file) | < 1s per operation | `time` command |
| 11 | Performance (100KB file) | < 2s per operation | `time` command |
| 12 | Edge: File deleted during edit | Hook fails gracefully | No error, continues |
| 13 | Edge: Read-only file | Git add fails silently | No error, file modified |

### Load Test
```
Edit 10 .tf files sequentially → total time < 20s
```

---

## Error Handling

| Situation | Behavior | Why |
|-----------|----------|-----|
| `terraform fmt` not installed | Continues silently | `2>/dev/null \|\| true` |
| `yq` not installed | Continues silently | `2>/dev/null \|\| true` |
| Read-only file | Git add fails silently | `\|\| true` won't interrupt |
| Hook fails completely | Claude continues | Hooks aren't critical |
| `jq` fails to extract path | Hook does nothing | `// empty` returns empty |

### Edge Cases

| Edge Case | Handling |
|-----------|----------|
| `.tf` file in `node_modules/` | Skipped (gitignore ignores) |
| Edit via Bash (not Edit/Write) | No hook runs (correct) |
| Multiple simultaneous Edits | Hook runs per file |
| File deleted during hook | Hook fails gracefully |
| Giant file (>10MB) | Timeout 3s applies |

### Known Limitations
- ⚠️ Does not format files edited via Bash (ex: `sed -i`)
- ⚠️ Formatter timeout on huge files may delay (but 3s limit)

---

## Benefits

| Benefit | Value |
|---------|-------|
| 🚀 **Automation** | Formatting + git add is invisible |
| ⚡ **Performance** | < 2s typical operation |
| 🛡️ **Security** | Hookify + deny list active |
| 🔧 **Simplicity** | 1 hook, 2 formatters |
| 🧪 **Isolation** | Tested in worktree before apply |

---

## Implementation Steps

1. ✅ Design approved
2. → Create git worktree for testing
3. → Apply settings.json to worktree
4. → Run all test cases
5. → Verify performance and security
6. → Apply to main branch if all tests pass
7. → Commit with proper message

---

## Rollback Procedure

If testing fails or causes issues:

### 1. Revert settings.json
```bash
# In worktree or main branch
git checkout HEAD -- .claude/settings.json
```

### 2. Remove worktree (cleanup)
```bash
# From main branch
git worktree remove ../test-hooks
git worktree prune
```

### 3. Verify rollback
```bash
# Check hooks are gone
jq '.hooks' .claude/settings.json
# Should return null or empty
```

### 4. If already applied to main
```bash
# Revert the commit
git revert <commit-hash>
# OR reset to previous commit
git reset --hard HEAD~1
```

### Emergency Disable (if CLI freezes)
```bash
# Disable all hooks immediately
echo '{"hooks":{}}' > .claude/settings.json
```

---

## Removed Components (Why?)

| Component | Status | Reason |
|-----------|--------|--------|
| `npx prettier` | ❌ Removed | Causes freezing (5-10s runtime) |
| `shfmt` | ❌ Removed | Can be slow on large scripts |
| Sandbox config | ❌ Removed | Not needed for this workflow |
| Tool choice | ❌ Removed | Default is already good |
| `git add .` | ❌ Changed | Now `git add "$FILE"` (more precise) |

---

## Alternatives Considered

### Option 2: Complete Hooks with Timeout
**Rejected because:** More complex, may abort on large legitimate files.

### Option 3: Cache with Intelligent Skip
**Rejected because:** More complex, higher maintenance.

### Option 1 (Chosen): Lightweight Optimized Hooks
**Selected for:** Simple, fast, covers 90% of DevOps cases.

---

## References

- Original issue: Claude Code CLI freezing with PostToolUse hooks
- Related files:
  - `.claude/hookify.block-dangerous-commands.local.md`
  - `.claude/hookify.warn-secrets-files.local.md`
  - `.claude/hookify.require-verification.local.md`
  - `.claude/hookify.warn-node-modules.local.md`
  - `.claude/hookify.warn-terraform-state.local.md`

---

**End of Spec**
