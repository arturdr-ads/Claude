#!/bin/bash
# Claude DevOps Overnight Auto-Pilot Loop
# Executa tarefas de monitoramento e manutenção automaticamente

set -e

# Configurações
PROJECT_DIR="/home/arturdr/Claude"
LOG_DIR="$PROJECT_DIR/logs"
LOG_FILE="$LOG_DIR/overnight-$(date +%Y%m%d).log"
LOCK_FILE="/tmp/claude-overnight-loop.lock"

# Criar diretório de logs
mkdir -p "$LOG_DIR"

# Função de log
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*" | tee -a "$LOG_FILE"
}

# Função de cleanup
cleanup() {
    rm -f "$LOCK_FILE"
    log "Loop encerrado"
}

# Trap para saída graciosa
trap cleanup EXIT INT TERM

# Verificar se já está rodando
if [ -f "$LOCK_FILE" ]; then
    PID=$(cat "$LOCK_FILE")
    if ps -p "$PID" > /dev/null 2>&1; then
        log "Já está rodando (PID: $PID)"
        exit 1
    else
        log "Lock file obsoleto, removendo..."
        rm -f "$LOCK_FILE"
    fi
fi

# Criar lock file
echo $$ > "$LOCK_FILE"

# Funções de tarefa
task_run_tests() {
    log "▶ Running test suite..."
    cd "$PROJECT_DIR"
    if ./test-all.sh >> "$LOG_FILE" 2>&1; then
        log "✓ Tests passed"
    else
        log "✗ Tests failed!"
    fi
}

task_monitor_coolify() {
    log "▶ Monitoring Coolify..."
    "$PROJECT_DIR/scripts/monitor-coolify.sh" >> "$LOG_FILE" 2>&1
}

task_check_mcp() {
    log "▶ Checking MCP connections..."
    MCP_COUNT=$(claude mcp list 2>&1 | grep -c "✓ Connected" || echo "0")
    log "✓ $MCP_COUNT MCPs connected"
}

task_check_health() {
    log "▶ Checking service health..."
    # Check Coolify containers
    if ssh vps "docker ps --filter name=coolify --format '{{.Names}}: {{.Status}}' | grep -q 'healthy'"; then
        log "✓ Coolify healthy"
    else
        log "✗ Coolify unhealthy!"
    fi
}

task_check_updates() {
    log "▶ Checking for updates..."
    cd "$PROJECT_DIR"
    git fetch origin > /dev/null 2>&1
    if [ $(git rev-list HEAD...origin/main --count) -gt 0 ]; then
        log "⚠ Updates available! Origin/main is ahead by $(git rev-list HEAD...origin/main --count) commits"
    else
        log "✓ Up to date"
    fi
}

task_monitor_resources() {
    log "▶ Monitoring resources..."
    # Check VPS resources
    ssh vps "free -m | grep Mem | awk '{print \"RAM: \" \$3 \"MB used / \" \$2 \"MB total\" }'" 2>/dev/null | while read line; do
        log "  $line"
    done
    ssh vps "df -h /var/lib/docker | tail -1 | awk '{print \"Disk: \" \$3 \" used / \" \$2 \" total (\" \$5 \" used)\" }'" 2>/dev/null | while read line; do
        log "  $line"
    done
}

# Loop principal
log "════════════════════════════════════════════════════════════"
log "🚀 Claude DevOps Overnight Auto-Pilot Iniciado"
log "════════════════════════════════════════════════════════════"
log "Project: $PROJECT_DIR"
log "Log: $LOG_FILE"
log "PID: $$"
log "════════════════════════════════════════════════════════════"

CYCLE=0
while true; do
    CYCLE=$((CYCLE + 1))
    log ""
    log "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    log "Cycle #$CYCLE started at $(date '+%Y-%m-%d %H:%M:%S')"
    log "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

    # Executar tarefas em sequência
    task_check_updates
    task_run_tests
    task_monitor_coolify
    task_check_mcp
    task_check_health
    task_monitor_resources

    log "Cycle #$CYCLE completed"
    log "Next run in 1 hour (3600s)"
    log "════════════════════════════════════════════════════════════"

    # Sleep 1 hora
    sleep 3600
done
