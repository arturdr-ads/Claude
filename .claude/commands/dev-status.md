---
description: Check deployment status with Coolify
argument-hint: app name (production/staging)
disable-model-invocation: false
---
# Deployment Status Checker

Check the deployment status of any application via Coolify.

!`!git remote get remote --tags`
!`curl -s -H "Authorization: Bearer $COOLIFY_ACCESS_TOKEN" "$COOLIFY_BASE_URL/api/v1/applications/$APP_name"
!`curl -s -H "Authorization: Bearer $COOLIFY_ACCESS_TOKEN" "$COOLIFY_BASE_URL/api/v1/deployments?app=$app_name"`

## Available Tools

- Read
- Bash
- Glob

- Grep
- WebFetch (via curl)

- mcp__github__*

## Output Format

Markdown table with columns: App Name, Status  URL  Health

