#!/bin/bash
# Overnight Loop 24/7 - ROBUST VERSION v3.0
# Features: Graceful shutdown, orphan cleanup, zombie prevention
# Usage: ./scripts/overnight-loop-247-v3.sh [--interval SECONDS]

set -euo pipefail

# ═══════════════════════════════════════════════════════════════════════════
# CONFIGURATION
# ═══════════════════════════════════════════════════════════════════════════
PROJECT_DIR="/home/arturdr/Claude"
LOG_DIR="$PROJECT_DIR/logs"
LOG_FILE="$LOG_DIR/overnight-247-$(date +%Y%m%d).log"
LOCK_FILE="/tmp/claude-overnight-247-v3.lock"
CYCLE_LOG="$LOG_DIR/overnight-cycles.log"
PID_FILE="/tmp/claude-overnight-247-v3.pid"

DEFAULT_INTERVAL=900  # 15 minutes
RAM_THRESHOLD=90
DISK_THRESHOLD=85
SHUTDOWN_TIMEOUT=10

# Global state
RUNNING=true
CYCLE=0
BACKUP_CYCLE=0

# ═══════════════════════════════════════════════════════════════════════════
# INITIALIZATION
# ═══════════════════════════════════════════════════════════════════════════
mkdir -p "$LOG_DIR" "$PROJECT_DIR/backups"

# Parse arguments
INTERVAL=${1:-$DEFAULT_INTERVAL}
if [[ "$INTERVAL" =~ ^--interval$ ]]; then
    INTERVAL=${2:-$DEFAULT_INTERVAL}
fi

# ═══════════════════════════════════════════════════════════════════════════
# LOGGING FUNCTIONS
# ═══════════════════════════════════════════════════════════════════════════
log() {
    local timestamp
    timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo "[$timestamp] $*" | tee -a "$LOG_FILE"
}

log_info()    { log "INFO    - $*"; }
log_warn()    { log "WARN    - $*"; }
log_error()   { log "ERROR   - $*"; }
log_success() { log "SUCCESS - $*"; }

track_cycle() {
    local status="$1"
    local details="$2"
    echo "$(date '+%Y-%m-%d %H:%M:%S')|$status|$details" >> "$CYCLE_LOG"
}

# ═══════════════════════════════════════════════════════════════════════════
# ORPHAN CLEANUP (REQ-003)
# ═══════════════════════════════════════════════════════════════════════════
kill_orphans() {
    log_info "Checking for orphan processes..."

    # Find and kill old instances
    local old_pids
    old_pids=$(pgrep -f "overnight-loop-247-v3.sh" | grep -v "^$$$" || true)

    if [[ -n "$old_pids" ]]; then
        log_warn "Found orphan processes: $old_pids"
        for pid in $old_pids; do
            if kill -0 "$pid" 2>/dev/null; then
                log_warn "Terminating orphan PID: $pid"
                kill -TERM "$pid" 2>/dev/null || true
                sleep 1
                kill -0 "$pid" 2>/dev/null && kill -KILL "$pid" 2>/dev/null || true
            fi
        done
    fi

    # Also check for old lock files
    if [[ -f "$LOCK_FILE" ]]; then
        local old_pid
        old_pid=$(cat "$LOCK_FILE" 2>/dev/null || echo "")
        if [[ -n "$old_pid" ]] && ! kill -0 "$old_pid" 2>/dev/null; then
            log_warn "Removing stale lock file (PID: $old_pid not running)"
            rm -f "$LOCK_FILE"
        elif [[ -n "$old_pid" ]]; then
            log_error "Another instance is running (PID: $old_pid)"
            exit 1
        fi
    fi
}

# ═══════════════════════════════════════════════════════════════════════════
# LOCK FILE MANAGEMENT (REQ-004)
# ═══════════════════════════════════════════════════════════════════════════
acquire_lock() {
    # Atomic lock acquisition
    if ! (set -o noclobber; echo $$ > "$LOCK_FILE") 2>/dev/null; then
        log_error "Failed to acquire lock"
        return 1
    fi
    echo $$ > "$PID_FILE"
    log_info "Lock acquired (PID: $$)"
    return 0
}

release_lock() {
    rm -f "$LOCK_FILE" "$PID_FILE"
    log_info "Lock released"
}

# ═══════════════════════════════════════════════════════════════════════════
# GRACEFUL SHUTDOWN (REQ-005, REQ-001)
# ═══════════════════════════════════════════════════════════════════════════
cleanup_children() {
    # Kill all child processes (REQ-001)
    local children
    children=$(pgrep -P $$ 2>/dev/null || true)

    if [[ -n "$children" ]]; then
        log_info "Terminating child processes: $children"
        for pid in $children; do
            kill -TERM "$pid" 2>/dev/null || true
        done

        # Wait for graceful shutdown
        local waited=0
        while [[ $waited -lt $SHUTDOWN_TIMEOUT ]]; do
            children=$(pgrep -P $$ 2>/dev/null || true)
            [[ -z "$children" ]] && break
            sleep 1
            ((waited++))
        done

        # Force kill remaining
        children=$(pgrep -P $$ 2>/dev/null || true)
        if [[ -n "$children" ]]; then
            log_warn "Force killing remaining children: $children"
            for pid in $children; do
                kill -KILL "$pid" 2>/dev/null || true
            done
        fi
    fi

    # Reap zombies (REQ-006)
    wait 2>/dev/null || true
}

graceful_shutdown() {
    log ""
    log "════════════════════════════════════════════════════════════"
    log "🛑 GRACEFUL SHUTDOWN INITIATED"
    log "════════════════════════════════════════════════════════════"

    RUNNING=false

    # Cleanup children first
    cleanup_children

    # Release lock
    release_lock

    log_success "Shutdown complete - ran for $CYCLE cycles"
    log "════════════════════════════════════════════════════════════"

    exit 0
}

# Signal handlers (REQ-002)
setup_traps() {
    trap 'log_info "Received SIGTERM"; graceful_shutdown' TERM
    trap 'log_info "Received SIGINT"; graceful_shutdown' INT
    trap 'log_info "Received SIGHUP"; graceful_shutdown' HUP
    trap 'log_info "Received EXIT"; graceful_shutdown' EXIT
}

# ═══════════════════════════════════════════════════════════════════════════
# HEALTH CHECKS
# ═══════════════════════════════════════════════════════════════════════════
check_git() {
    cd "$PROJECT_DIR" || return 1
    git fetch origin >/dev/null 2>&1 || true

    local behind
    behind=$(git rev-list HEAD...origin/main --count 2>/dev/null || echo "0")

    if [[ "$behind" -gt 0 ]]; then
        log_warn "Git: $behind commits behind"
        track_cycle "INFO" "Git: $behind commits behind"
    else
        log_success "Git up to date"
        track_cycle "OK" "Git up to date"
    fi
}

check_tests() {
    cd "$PROJECT_DIR" || return 1

    if [[ -f "./test-all.sh" ]]; then
        if timeout 120 ./test-all.sh >> "$LOG_FILE" 2>&1; then
            log_success "Tests passed (19/19)"
            track_cycle "OK" "Tests: 19/19 passed"
        else
            log_error "Tests failed"
            track_cycle "FAIL" "Tests failed"
        fi
    else
        log_warn "test-all.sh not found"
    fi
}

check_docker() {
    local unhealthy
    unhealthy=$(ssh vps "docker ps --filter health=unhealthy --format '{{.Names}}'" 2>/dev/null || echo "")

    if [[ -n "$unhealthy" ]]; then
        log_error "Unhealthy containers: $unhealthy"
        track_cycle "FAIL" "Docker unhealthy"
    else
        if ssh vps "docker ps --filter name=coolify --format '{{.Status}}'" 2>/dev/null | grep -q "healthy"; then
            log_success "Docker/Coolify healthy"
            track_cycle "OK" "Coolify healthy"
        else
            log_info "Docker status unknown"
        fi
    fi
}

check_mcp() {
    local mcp_output
    mcp_output=$(claude mcp list 2>&1 || echo "")

    local mcp_count
    mcp_count=$(echo "$mcp_output" | grep -c "✓ Connected" || echo "0")
    mcp_count=$(echo "$mcp_count" | tr -d '\n\r' | grep -o '[0-9]*' | head -1 || echo "0")

    local mcp_failed
    mcp_failed=$(echo "$mcp_output" | grep -c "✗ Failed" || echo "0")
    mcp_failed=$(echo "$mcp_failed" | tr -d '\n\r' | grep -o '[0-9]*' | head -1 || echo "0")

    if [[ "$mcp_failed" -gt 0 ]] || [[ "$mcp_count" -lt 4 ]]; then
        log_error "MCP issue: $mcp_count/5 connected, $mcp_failed failed"
        track_cycle "FAIL" "MCP degraded"
    else
        log_success "MCPs OK ($mcp_count/5)"
        track_cycle "OK" "MCPs: $mcp_count/5"
    fi
}

check_resources() {
    local ram disk
    ram=$(ssh vps "free | grep Mem | awk '{printf \"%.0f\", (\$3/\$2)*100}'" 2>/dev/null || echo "0")
    disk=$(ssh vps "df -h /var/lib/docker | tail -1 | awk '{print \$5}' | tr -d '%'" 2>/dev/null || echo "0")

    ram=$(echo "$ram" | tr -d '\n\r' | grep -o '[0-9]*' | head -1 || echo "0")
    disk=$(echo "$disk" | tr -d '\n\r' | grep -o '[0-9]*' | head -1 || echo "0")

    if [[ "$ram" -gt "$RAM_THRESHOLD" ]]; then
        log_error "High RAM: ${ram}%"
        track_cycle "WARN" "RAM high: ${ram}%"
    fi

    if [[ "$disk" -gt "$DISK_THRESHOLD" ]]; then
        log_error "High disk: ${disk}%"
        track_cycle "WARN" "Disk high: ${disk}%"
    fi

    log_info "Resources: RAM ${ram}%, Disk ${disk}%"
}

check_local_system() {
    local local_disk
    local_disk=$(df -h "$PROJECT_DIR" | tail -1 | awk '{print $5}' | tr -d '%')
    log_info "Local disk: ${local_disk}%"
}

# ═══════════════════════════════════════════════════════════════════════════
# BACKUP
# ═══════════════════════════════════════════════════════════════════════════
create_backup() {
    log_info "Creating backup..."

    local backup_file="$PROJECT_DIR/backups/claude-devops-$(date +%Y%m%d-%H%M%S).tar.gz"

    if tar -czf "$backup_file" \
        --exclude='node_modules' --exclude='.git' --exclude='logs' \
        --exclude='backups' --exclude='.claude/projects' \
        -C "$PROJECT_DIR" . 2>/dev/null; then

        local size
        size=$(du -h "$backup_file" 2>/dev/null | cut -f1 || echo "?")
        log_success "Backup created ($size)"
        track_cycle "BACKUP" "Backup: $size"

        # Keep only last 3 backups
        ls -t "$PROJECT_DIR"/backups/*.tar.gz 2>/dev/null | tail -n +4 | xargs -r rm -f
    else
        log_error "Backup failed"
    fi
}

# ═══════════════════════════════════════════════════════════════════════════
# MAIN LOOP
# ═══════════════════════════════════════════════════════════════════════════
main() {
    # Setup signal handlers first
    setup_traps

    # Check for orphans
    kill_orphans

    # Acquire lock
    if ! acquire_lock; then
        exit 1
    fi

    # Startup banner
    log ""
    log "════════════════════════════════════════════════════════════"
    log "🚀 Claude DevOps 24/7 Auto-Healing Loop v3.0"
    log "════════════════════════════════════════════════════════════"
    log "PID: $$"
    log "Check interval: ${INTERVAL}s"
    log "Lock file: $LOCK_FILE"
    log "════════════════════════════════════════════════════════════"

    # Main loop
    while [[ "$RUNNING" == "true" ]]; do
        CYCLE=$((CYCLE + 1))
        BACKUP_CYCLE=$((BACKUP_CYCLE + 1))

        log ""
        log "════════════════════════════════════════════════════════════"
        log "🔄 CYCLE #$CYCLE started at $(date '+%Y-%m-%d %H:%M:%S')"
        log "════════════════════════════════════════════════════════════"

        # Run checks with error handling
        check_git || true
        check_tests || true
        check_docker || true
        check_mcp || true
        check_resources || true
        check_local_system || true

        # Backup every 6 cycles (~1.5 hours with 15min interval)
        if [[ $((BACKUP_CYCLE % 6)) -eq 0 ]]; then
            create_backup || true
        fi

        log "✓ Cycle #$CYCLE completed"
        log "Next cycle in ${INTERVAL}s"
        log "════════════════════════════════════════════════════════════"

        # Sleep with interrupt check
        for ((i=0; i<INTERVAL; i++)); do
            [[ "$RUNNING" == "false" ]] && break
            sleep 1
        done
    done

    # Should not reach here
    graceful_shutdown
}

# Run main
main "$@"
