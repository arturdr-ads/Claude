#!/bin/bash
# Overnight Loop Control v3 - Clean start/stop/status
# Usage: ./scripts/overnight-control-v3.sh [start|stop|status|restart]

set -euo pipefail

PROJECT_DIR="/home/arturdr/Claude"
LOCK_FILE="/tmp/claude-overnight-247-v3.lock"
PID_FILE="/tmp/claude-overnight-247-v3.pid"
SCRIPT="$PROJECT_DIR/scripts/overnight-loop-247-v3.sh"
LOG_FILE="$PROJECT_DIR/logs/overnight-247-$(date +%Y%m%d).log"

cd "$PROJECT_DIR" || exit 1

# ═══════════════════════════════════════════════════════════════════════════
# STATUS
# ═══════════════════════════════════════════════════════════════════════════
show_status() {
    echo "════════════════════════════════════════════════════════════"
    echo "🔄 OVERNIGHT LOOP 24/7 v3 - STATUS"
    echo "════════════════════════════════════════════════════════════"

    local pid=""
    if [[ -f "$PID_FILE" ]]; then
        pid=$(cat "$PID_FILE" 2>/dev/null || echo "")
    fi

    # Also check via pgrep
    local pgrep_pid
    pgrep_pid=$(pgrep -f "overnight-loop-247-v3.sh" | head -1 || true)

    if [[ -z "$pid" ]] && [[ -z "$pgrep_pid" ]]; then
        echo "Status: ⏹️ STOPPED"
        echo ""
        echo "Para iniciar: $0 start"
    else
        # Use whichever PID we found
        pid=${pid:-$pgrep_pid}

        if kill -0 "$pid" 2>/dev/null; then
            local proc_info
            proc_info=$(ps -p "$pid" -o pid,etime,stat --no-headers 2>/dev/null || echo "")
            local uptime
            uptime=$(echo "$proc_info" | awk '{print $2}')
            local status
            status=$(echo "$proc_info" | awk '{print $3}')

            echo "Status: ▶️ RUNNING"
            echo "PID: $pid"
            echo "Uptime: $uptime"
            echo "Process State: $status"
            echo ""

            # Show last cycle
            echo "---"
            echo "📋 ÚLTIMO CICLO:"
            tail -20 "$LOG_FILE" 2>/dev/null | grep -E "Cycle #|Tests|Coolify|MCPs|completed" | tail -5
            echo ""

            # Count cycles today
            local cycles
            cycles=$(grep -c "Cycle #" "$LOG_FILE" 2>/dev/null || echo "0")
            echo "📊 Ciclos hoje: $cycles"
            echo ""
            echo "Para parar: $0 stop"
        else
            echo "Status: ⚠️ STALE (PID file exists but process dead)"
            echo "Cleaning up..."
            rm -f "$LOCK_FILE" "$PID_FILE"
            echo "Para iniciar: $0 start"
        fi
    fi

    echo "════════════════════════════════════════════════════════════"
}

# ═══════════════════════════════════════════════════════════════════════════
# START
# ═══════════════════════════════════════════════════════════════════════════
start_loop() {
    # Check if already running
    if [[ -f "$PID_FILE" ]]; then
        local old_pid
        old_pid=$(cat "$PID_FILE" 2>/dev/null || echo "")
        if [[ -n "$old_pid" ]] && kill -0 "$old_pid" 2>/dev/null; then
            echo "⚠️ Loop já está rodando (PID: $old_pid)"
            exit 1
        else
            echo "🧹 Limpando lock antigo..."
            rm -f "$LOCK_FILE" "$PID_FILE"
        fi
    fi

    # Also check via pgrep
    local running_pid
    running_pid=$(pgrep -f "overnight-loop-247-v3.sh" | head -1 || true)
    if [[ -n "$running_pid" ]]; then
        echo "⚠️ Loop já está rodando (PID: $running_pid)"
        exit 1
    fi

    echo "▶️ Iniciando loop 24/7 v3..."

    # Start in background
    nohup "$SCRIPT" >> "$LOG_FILE" 2>&1 &
    local new_pid=$!
    sleep 2

    if kill -0 "$new_pid" 2>/dev/null; then
        echo "✅ Loop 24/7 v3 iniciado (PID: $new_pid)"
        echo "📊 Logs: $LOG_FILE"
        echo "📁 Lock: $LOCK_FILE"
    else
        echo "❌ Falha ao iniciar loop"
        echo "Verifique logs: $LOG_FILE"
        exit 1
    fi
}

# ═══════════════════════════════════════════════════════════════════════════
# STOP
# ═══════════════════════════════════════════════════════════════════════════
stop_loop() {
    local pid=""

    if [[ -f "$PID_FILE" ]]; then
        pid=$(cat "$PID_FILE" 2>/dev/null || echo "")
    fi

    # Also check via pgrep
    local pgrep_pid
    pgrep_pid=$(pgrep -f "overnight-loop-247-v3.sh" | head -1 || true)

    if [[ -z "$pid" ]] && [[ -z "$pgrep_pid" ]]; then
        echo "⚠️ Loop não está rodando"
        rm -f "$LOCK_FILE" "$PID_FILE"
        exit 0
    fi

    # Use whichever PID we found
    pid=${pid:-$pgrep_pid}

    echo "⏹️ Parando loop (PID: $pid)..."

    # Send SIGTERM for graceful shutdown
    kill -TERM "$pid" 2>/dev/null || true

    # Wait up to 15 seconds
    local waited=0
    while [[ $waited -lt 15 ]]; do
        if ! kill -0 "$pid" 2>/dev/null; then
            break
        fi
        sleep 1
        ((waited++))
        echo "   Aguardando... ($waited/15)"
    done

    # If still running, force kill
    if kill -0 "$pid" 2>/dev/null; then
        echo "⚠️ Forçando parada..."
        kill -KILL "$pid" 2>/dev/null || true
        sleep 1
    fi

    # Cleanup
    rm -f "$LOCK_FILE" "$PID_FILE"

    if kill -0 "$pid" 2>/dev/null; then
        echo "⚠️ Loop ainda rodando - verifique manualmente"
        exit 1
    else
        echo "✅ Loop 24/7 v3 parado"
    fi
}

# ═══════════════════════════════════════════════════════════════════════════
# RESTART
# ═══════════════════════════════════════════════════════════════════════════
restart_loop() {
    echo "🔄 Reiniciando loop..."
    stop_loop || true
    sleep 2
    start_loop
}

# ═══════════════════════════════════════════════════════════════════════════
# MAIN
# ═══════════════════════════════════════════════════════════════════════════
case "${1:-status}" in
    start)
        start_loop
        ;;
    stop)
        stop_loop
        ;;
    status)
        show_status
        ;;
    restart)
        restart_loop
        ;;
    *)
        echo "Uso: $0 [start|stop|status|restart]"
        exit 1
        ;;
esac
