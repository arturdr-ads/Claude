#!/usr/bin/env bash
#
# Coolify Monitoring Script
# Checks deployment status and logs to deployments.md
#
# Usage: ./scripts/monitor-coolify.sh
#

set -euo pipefail

# Configuration
COOLIFY_VPS="${COOLIFY_VPS:-vps}"
DEPLOYMENTS_LOG="${DEPLOYMENTS_LOG:-$(git rev-parse --show-toplevel 2>/dev/null || echo "$HOME")/deployments.md}"
MAX_LOG_LINES="${MAX_LOG_LINES:-100}"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Log function
log() {
    echo -e "${2:-}$1${NC}"
}

# Check Coolify containers status
check_coolify_containers() {
    log "🔍 Checking Coolify containers on VPS..." "$YELLOW"

    local status
    status=$(ssh "$COOLIFY_VPS" "
        docker ps \
            --filter 'name=coolify' \
            --format 'table {{.Names}}\t{{.Status}}' 2>/dev/null
    " 2>&1)

    if [[ $? -eq 0 ]]; then
        echo "$status"
        return 0
    else
        log "❌ Failed to connect to VPS: $status" "$RED"
        return 1
    fi
}

# Check for unhealthy containers
check_health() {
    local unhealthy
    unhealthy=$(ssh "$COOLIFY_VPS" "
        docker ps \
            --filter 'name=coolify' \
            --format '{{.Names}}\t{{.Health}}' \
        | grep -i 'unhealthy\|starting' \
        || echo 'healthy'
    " 2>/dev/null)

    if [[ "$unhealthy" != "healthy" ]]; then
        log "⚠️  Unhealthy containers detected:" "$YELLOW"
        echo "$unhealthy"
        return 1
    fi

    return 0
}

# Get container uptime
get_uptime() {
    ssh "$COOLIFY_VPS" "
        docker ps \
            --filter 'name=coolify' \
            --format '{{.Names}}\t{{.Status}}' \
        | column -t -s $'\t'
    " 2>/dev/null
}

# Log to deployments.md
log_to_file() {
    local timestamp
    timestamp=$(date -u '+%Y-%m-%d %H:%M:%S UTC')

    local status="$1"
    local details="$2"

    # Create file if it doesn't exist
    if [[ ! -f "$DEPLOYMENTS_LOG" ]]; then
        cat > "$DEPLOYMENTS_LOG" << 'EOF'
# Coolify Deployments Log

Auto-generated monitoring log for Coolify deployments.

## Status Legend

- ✅ Healthy - All containers running
- ⚠️  Warning - Some containers unhealthy
- ❌ Error - Critical failures

---

EOF
    fi

    # Add entry
    cat >> "$DEPLOYMENTS_LOG" << EOF

## $timestamp

**Status**: $status

<details>
<summary>Details</summary>

\`\`\`
$details
\`\`\`

</details>

---

EOF

    # Trim log if too large
    if [[ $(wc -l < "$DEPLOYMENTS_LOG") -gt $MAX_LOG_LINES ]]; then
        temp_file=$(mktemp)
        head -n 50 "$DEPLOYMENTS_LOG" > "$temp_file"
        tail -n $((MAX_LOG_LINES - 50)) "$DEPLOYMENTS_LOG" >> "$temp_file"
        mv "$temp_file" "$DEPLOYMENTS_LOG"
    fi

    log "📝 Logged to: $DEPLOYMENTS_LOG" "$GREEN"
}

# Send notification (can be extended with Slack, Discord, etc.)
send_notification() {
    local status="$1"
    local message="$2"

    # TODO: Add Slack webhook
    # curl -X POST "$SLACK_WEBHOOK" -H 'Content-Type: application/json' \
    #   -d "{\"text\": \"Coolify Monitor: $status\"}"

    log "📢 Notification: $status" "$YELLOW"
    echo "$message"
}

# Main monitoring function
main() {
    local exit_code=0
    local output
    local health_status="✅ Healthy"
    local notification_level="info"

    log "🚀 Coolify Monitoring Started" "$GREEN"

    # Check containers
    if output=$(check_coolify_containers); then
        echo "$output"

        # Check health
        if ! check_health; then
            health_status="⚠️  Warning"
            notification_level="warning"
            exit_code=1
        fi

        # Get uptime info
        log "" "$NC"
        log "📊 Container Uptime:" "$YELLOW"
        get_uptime

    else
        health_status="❌ Error"
        notification_level="error"
        exit_code=2
        output="Failed to connect to VPS"
    fi

    # Log to file
    log_to_file "$health_status" "$output"

    # Send notification if not healthy
    if [[ $exit_code -ne 0 ]]; then
        send_notification "$health_status" "$output"
    fi

    log "" "$NC"
    if [[ $exit_code -eq 0 ]]; then
        log "✅ Monitoring complete - All systems operational" "$GREEN"
    else
        log "⚠️  Monitoring complete - Issues detected (exit: $exit_code)" "$YELLOW"
    fi

    return $exit_code
}

# Run main function
main "$@"
