# Claude Code CLI Configuration

## Auto-Pilot Hooks Configuration

This repo uses Claude Code CLI with automatic formatting:

- **Formatters:** Terraform (`*.tf`), YAML (`*.yml`, `*.yaml`, `Dockerfile`)
- **Git Add:** Automatic after Edit/Write (not Bash)
- **Timeout:** 3s per formatter (prevents freezing)
- **Security:** Hookify blocks dangerous commands, `.env`/`secrets/**` protected

### How It Works

When you edit or create a file via Claude Code CLI:
1. The PostToolUse hook automatically formats the file
2. The formatted file is automatically staged for commit
3. No manual formatting or git add needed

### Supported File Types

| Extension | Formatter |
|-----------|-----------|
| `*.tf`, `*.tfvars` | `terraform fmt -diff=false` |
| `*.yml`, `*.yaml` | `yq --prettyPrint -i` |
| `Dockerfile` | `yq --prettyPrint -i` |

**Not formatted:** Shell scripts (`*.sh`), JavaScript/TypeScript/JSON (manual when needed)

### Troubleshooting

**If hooks cause issues:**

1. **Revert hooks:**
   ```bash
   git checkout HEAD -- .claude/settings.json
   ```

2. **Disable hooks completely:**
   ```bash
   echo '{"hooks":{}}' > .claude/settings.json
   ```

3. **Restore hooks:**
   ```bash
   git checkout 9d172f3 -- .claude/settings.json
   ```

### Configuration File

Location: `.claude/settings.json`

Key settings:
- `permissions.deny`: Blocks access to `.env` and `secrets/**`
- `hooks.PostToolUse`: Runs formatters with 3s timeout, then `git add`

### Performance

- Typical files (< 10KB): < 1s
- Large files (10-100KB): < 2s
- Very large files (> 100KB): Timeout at 3s (prevents freezing)

### Related Documentation

- Spec: `docs/superpowers/specs/2026-03-19-claude-code-cli-hooks-design.md`
- Plan: `docs/superpowers/plans/2026-03-19-claude-code-cli-hooks.md`
