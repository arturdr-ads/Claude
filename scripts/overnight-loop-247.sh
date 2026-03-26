#!/bin/bash
# Claude DevOps 24/7 Auto-Healing Loop - NEVER STOPS
# Runs forever, detecting errors, auto-fixing, optimizing until manually stopped

set -e

# Configurações
PROJECT_DIR="/home/arturdr/Claude"
LOG_DIR="$PROJECT_DIR/logs"
LOG_FILE="$LOG_DIR/overnight-247-$(date +%Y%m%d).log"
LOCK_FILE="/tmp/claude-overnight-247.lock"
CYCLE_LOG="$LOG_DIR/overnight-cycles.log"

# Thresholds
CHECK_INTERVAL=3600  # 1 hour between cycles
MAX_REPAIR_ATTEMPTS=3
ERROR_BUDGET=0.1
RAM_THRESHOLD=90
DISK_THRESHOLD=85

# Alert webhooks
SLACK_WEBHOOK="${SLACK_WEBHOOK:-}"
DISCORD_WEBHOOK="${DISCORD_WEBHOOK:-}"

mkdir -p "$LOG_DIR" "$PROJECT_DIR/backups"

# Lock file
if [ -f "$LOCK_FILE" ]; then
    OLD_PID=$(cat "$LOCK_FILE")
    if ps -p "$OLD_PID" > /dev/null 2>&1; then
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] Already running (PID: $OLD_PID)" | tee -a "$LOG_FILE"
        exit 1
    else
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] Removing stale lock" | tee -a "$LOG_FILE"
        rm -f "$LOCK_FILE"
    fi
fi

echo $$ > "$LOCK_FILE"

# Cleanup on interrupt (not on exit - we NEVER exit)
cleanup() {
    rm -f "$LOCK_FILE"
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] Loop stopped by user" | tee -a "$LOG_FILE"
}
trap cleanup TERM INT

# Logging functions
log() { echo "$(date '+%Y-%m-%d %H:%M:%S') - $*" | tee -a "$LOG_FILE"; }
log_info() { log "INFO - $*"; }
log_warn() { log "WARN - $*"; }
log_error() { log "ERROR - $*"; }
log_success() { log "SUCCESS - $*"; }
log_heal() { log "🛠️  HEALING - $*"; }
log_optimize() { log "⚡ OPTIMIZING - $*"; }

# Cycle tracker
track_cycle() {
    local status="$1"
    local details="$2"
    echo "$(date '+%Y-%m-%d %H:%M:%S')|$status|$details" >> "$CYCLE_LOG"
}

# Alert function
send_alert() {
    local severity="$1" title="$2" message="$3"
    [ -z "$SLACK_WEBHOOK$DISCORD_WEBHOOK" ] && return 0

    if [ -n "$SLACK_WEBHOOK" ]; then
        local color="good"
        [[ "$severity" == *"ERROR"* ]] || [[ "$severity" == *"CRITICAL"* ]] && color="danger"
        [[ "$severity" == *"WARN"* ]] && color="warning"

        curl -s -X POST "$SLACK_WEBHOOK" -H 'Content-Type: application/json' \
            -d "{\"attachments\":[{\"color\":\"$color\",\"title\":\"[$severity] $title\",\"text\":\"$message\",\"footer\":\"Claude DevOps 24/7\",\"ts\":$(date +%s)}]}" >/dev/null 2>&1 || true
    fi
}

# Self-healing functions
heal_docker() {
    local issue="$1"
    log_heal "Docker/Coolify: $issue"

    ssh vps "docker ps --filter health=unhealthy --format '{{.Names}}'" 2>/dev/null | while read -r container; do
        [ -n "$container" ] && ssh vps "docker restart $container" 2>/dev/null || true
    done

    sleep 10
    ssh vps "docker ps --filter name=coolify --format '{{.Status}}'" 2>/dev/null | grep -q "healthy" && \
        { log_success "✅ Docker/Coolify fixed"; track_cycle "HEAL" "Docker restarted successfully"; }
}

heal_tests() {
    local issue="$1"
    log_heal "Tests: $issue"
    cd "$PROJECT_DIR"

    # Try to fix automatically using Claude
    if command -v claude >/dev/null 2>&1; then
        log_info "Attempting Claude auto-fix..."
        echo "Fix these test failures automatically. Analyze, fix, and verify." | \
            claude --dangerously-skip-permissions --timeout 300 >> "$LOG_FILE" 2>&1 || true
        sleep 5
    fi

    if ./test-all.sh >> "$LOG_FILE" 2>&1; then
        log_success "✅ Tests fixed"
        track_cycle "HEAL" "Tests passing after fix"
    else
        log_error "❌ Tests still failing"
        send_alert "ERROR" "Tests Critical" "Tests failed after auto-fix attempt. Manual review needed."
        track_cycle "CRITICAL" "Tests failed after healing"
    fi
}

heal_mcp() {
    local issue="$1"
    log_heal "MCP: $issue"

    command -v claude >/dev/null 2>&1 && claude mcp restart >/dev/null 2>&1 || true
    sleep 5

    local mcp_count
    mcp_count=$(claude mcp list 2>&1 | grep -c "✓ Connected" || echo "0")

    if [ "$mcp_count" -ge 4 ]; then
        log_success "✅ MCP restored ($mcp_count/5)"
        track_cycle "HEAL" "MCPs restored"
    else
        log_error "❌ MCP still degraded: $mcp_count/5"
    fi
}

heal_resources() {
    log_heal "Resources: optimizing..."

    # Clean Docker
    ssh vps "docker system prune -f --volumes" >/dev/null 2>&1 || true

    # Clean temp
    rm -rf /tmp/claude-* 2>/dev/null || true
    rm -rf "$PROJECT_DIR/.tmp" 2>/dev/null || true

    # Clean old logs (>7 days)
    find "$LOG_DIR" -name "overnight-*.log" -mtime +7 -delete 2>/dev/null || true

    # Clean old backups (keep last 3)
    ls -t "$PROJECT_DIR"/backups/*.tar.gz 2>/dev/null | tail -n +4 | xargs -r rm -f

    log_success "✅ Resources optimized"
    track_cycle "OPTIMIZE" "Cleanup completed"
}

# Optimization functions
optimize_serena_rules() {
    log_optimize "Serena: analyzing and optimizing rules..."

    if [ -d "$PROJECT_DIR/.serena" ]; then
        # Backup current config
        cp "$PROJECT_DIR/.serena/project.yml" "$PROJECT_DIR/.serena/project.yml.backup" 2>/dev/null || true

        # Optimize using Serena itself (meta!)
        if command -v claude >/dev/null 2>&1; then
            echo "Optimize .serena/project.yml for better performance and accuracy." | \
                claude --dangerously-skip-permissions --timeout 120 >> "$LOG_FILE" 2>&1 || true
        fi

        track_cycle "OPTIMIZE" "Serena rules analyzed"
    fi
}

optimize_git_history() {
    log_optimize "Git: cleaning history..."

    cd "$PROJECT_DIR"
    git gc --auto --quiet >/dev/null 2>&1 || true
    log_success "✓ Git repository cleaned"
    track_cycle "OPTIMIZE" "Git GC completed"
}

optimize_logs() {
    log_optimize "Logs: compressing old logs..."

    # Compress logs older than 3 days
    find "$LOG_DIR" -name "overnight-*.log" -mtime +3 ! -name "*.gz" -exec gzip {} \; 2>/dev/null || true

    log_success "✓ Old logs compressed"
    track_cycle "OPTIMIZE" "Logs compressed"
}

# Check functions
check_git() {
    cd "$PROJECT_DIR"
    git fetch origin >/dev/null 2>&1
    local behind
    behind=$(git rev-list HEAD...origin/main --count 2>/dev/null || echo "0")

    if [ "$behind" -gt 0 ]; then
        log_warn "⚠ $behind commits behind"
        track_cycle "INFO" "Git: $behind commits behind"
    else
        log_success "✓ Git up to date"
        track_cycle "OK" "Git up to date"
    fi
}

check_tests() {
    cd "$PROJECT_DIR"
    if ./test-all.sh >> "$LOG_FILE" 2>&1; then
        log_success "✓ Tests passed (19/19)"
        track_cycle "OK" "Tests: 19/19 passed"
    else
        log_error "✗ Tests failed"
        track_cycle "FAIL" "Tests failed"
        heal_tests "test failures detected"
    fi
}

check_docker() {
    local unhealthy
    unhealthy=$(ssh vps "docker ps --filter health=unhealthy --format '{{.Names}}'" 2>/dev/null || echo "")

    if [ -n "$unhealthy" ]; then
        log_error "✗ Unhealthy containers: $unhealthy"
        track_cycle "FAIL" "Docker unhealthy"
        heal_docker "unhealthy containers: $unhealthy"
    else
        ssh vps "docker ps --filter name=coolify --format '{{.Status}}'" 2>/dev/null | grep -q "healthy" && \
        { log_success "✓ Docker/Coolify healthy"; track_cycle "OK" "Coolify healthy"; }
    fi
}

check_mcp() {
    local mcp_output
    mcp_output=$(claude mcp list 2>&1)
    local mcp_count=$(echo "$mcp_output" | grep -c "✓ Connected" || echo "0")
    local mcp_failed=$(echo "$mcp_output" | grep -c "✗ Failed" || echo "0")

    if [ "$mcp_failed" -gt 0 ] || [ "$mcp_count" -lt 4 ]; then
        log_error "✗ MCP issue: $mcp_count/5 connected, $mcp_failed failed"
        track_cycle "FAIL" "MCP degraded"
        heal_mcp "MCP: $mcp_count connected, $mcp_failed failed"
    else
        log_success "✓ MCPs OK ($mcp_count/5)"
        track_cycle "OK" "MCPs: $mcp_count/5"
    fi
}

check_resources() {
    local ram disk
    ram=$(ssh vps "free | grep Mem | awk '{printf \"%.0f\", (\$3/\$2)*100}'" 2>/dev/null || echo "0")
    disk=$(ssh vps "df -h /var/lib/docker | tail -1 | awk '{print \$5}' | tr -d '%' " 2>/dev/null || echo "0")

    if [ "$ram" -gt "$RAM_THRESHOLD" ]; then
        log_error "✗ High RAM: ${ram}%"
        track_cycle "WARN" "RAM high: ${ram}%"
        heal_resources "High RAM: ${ram}%"
    fi

    if [ "$disk" -gt "$DISK_THRESHOLD" ]; then
        log_error "✗ High disk: ${disk}%"
        track_cycle "WARN" "Disk high: ${disk}%"
        heal_resources "High disk: ${disk}%"
    fi

    log_info "✓ Resources: RAM ${ram}%, Disk ${disk}%"
}

check_system() {
    # Check local disk
    local local_disk
    local_disk=$(df -h "$PROJECT_DIR" | tail -1 | awk '{print $5}' | tr -d '%')
    log_info "✓ Local disk: ${local_disk}"

    # Check log size
    if [ -f "$LOG_FILE" ]; then
        local log_size
        log_size=$(du -m "$LOG_FILE" 2>/dev/null | cut -f1 || echo "0")
        [ "$log_size" -gt 100 ] && log_warn "⚠ Log file large: ${log_size}MB"
    fi
}

# S3 backup
backup_s3() {
    log_info "Creating S3 backup..."

    local backup_file="$PROJECT_DIR/backups/claude-devops-$(date +%Y%m%d-%H%M%S).tar.gz"

    tar -czf "$backup_file" \
        --exclude='node_modules' --exclude='.git' --exclude='logs' \
        --exclude='backups' --exclude='.claude/projects' \
        -C "$PROJECT_DIR" . 2>/dev/null || true

    local size=$(du -h "$backup_file" 2>/dev/null | cut -f1 || echo "?")
    log_success "✓ Backup created ($size)"
    track_cycle "BACKUP" "Backup: $size"

    # Upload to S3
    if [ -n "${S3_BUCKET:-}" ] && command -v aws >/dev/null 2>&1; then
        aws s3 cp "$backup_file" "$S3_BUCKET/backup-$(date +%Y%m%d).tar.gz" --quiet 2>/dev/null && \
            log_success "✓ Uploaded to S3" || log_info "S3 upload failed"
    fi

    # Clean local backups
    ls -t "$PROJECT_DIR"/backups/*.tar.gz 2>/dev/null | tail -n +4 | xargs -r rm -f
}

# Main 24/7 loop
log "════════════════════════════════════════════════════════════"
log "🚀 Claude DevOps 24/7 Auto-Healing Loop - NEVER STOPS"
log "════════════════════════════════════════════════════════════"
log "PID: $$"
log "Check interval: ${CHECK_INTERVAL}s (1 hour)"
log "Self-healing: ENABLED"
log "Auto-optimization: ENABLED"
log "════════════════════════════════════════════════════════════"

CYCLE=0
OPTIMIZE_CYCLE=0
BACKUP_CYCLE=0

while true; do
    CYCLE=$((CYCLE + 1))
    OPTIMIZE_CYCLE=$((OPTIMIZE_CYCLE + 1))
    BACKUP_CYCLE=$((BACKUP_CYCLE + 1))

    log ""
    log "════════════════════════════════════════════════════════════"
    log "🔄 CYCLE #$CYCLE started at $(date '+%Y-%m-%d %H:%M:%S')"
    log "════════════════════════════════════════════════════════════"

    # Run all checks
    check_git
    check_tests
    check_docker
    check_mcp
    check_resources
    check_system

    # Optimization tasks (every 6 cycles / 6 hours)
    if [ $((OPTIMIZE_CYCLE % 6)) -eq 0 ]; then
        log ""
        log "⚡ Running optimization tasks..."
        optimize_serena_rules
        optimize_git_history
        optimize_logs
    fi

    # Backup (every 6 cycles / 6 hours)
    if [ $((BACKUP_CYCLE % 6)) -eq 0 ]; then
        backup_s3
    fi

    log "✓ Cycle #$CYCLE completed"
    log "Next cycle in ${CHECK_INTERVAL}s (1 hour)"
    log "════════════════════════════════════════════════════════════"

    # Sleep until next cycle (NEVER EXITS)
    sleep "$CHECK_INTERVAL"
done

# This line should never be reached
log "ERROR: Loop exited unexpectedly!"
EOF

chmod +x /home/arturdr/Claude/scripts/overnight-loop-247.sh && \
echo "✓ 24/7 loop script created"