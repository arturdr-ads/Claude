#!/usr/bin/env python3
"""
MCP Resource Monitor

Monitors CPU and RAM usage of all running MCP servers.
Alerts if usage exceeds thresholds.
Integrates with test-all skill for comprehensive monitoring.
"""

import psutil
import json
import sys
from datetime import datetime

# MCP process names to monitor
MCP_PROCESSES = [
    "serena",
    "context7-mcp",
    "uvx",  # Serena runs via uvx
]

# Thresholds for alerts
CPU_THRESHOLD = 80.0  # percent
RAM_THRESHOLD = 80.0  # percent of available RAM
RAM_ABSOLUTE_THRESHOLD = 1024 * 1024 * 1024  # 1GB absolute


def find_mcp_processes():
    """Find all MCP-related processes."""
    mcp_procs = []
    for proc in psutil.process_iter(['pid', 'name', 'cmdline', 'cpu_percent', 'memory_info']):
        try:
            cmdline = ' '.join(proc.info['cmdline'] or [])
            name = proc.info['name'].lower()

            # Check if this is an MCP process
            if any(mcp in cmdline.lower() or mcp in name for mcp in MCP_PROCESSES):
                mcp_procs.append(proc)
        except (psutil.NoSuchProcess, psutil.AccessDenied):
            continue
    return mcp_procs


def get_process_metrics(proc):
    """Get CPU and memory metrics for a process."""
    try:
        cpu = proc.cpu_percent(interval=0.1)
        mem = proc.memory_info()
        ram_mb = mem.rss / (1024 * 1024)
        ram_percent = (mem.rss / psutil.virtual_memory().total) * 100

        return {
            'pid': proc.pid,
            'name': proc.name(),
            'cmdline': ' '.join(proc.info['cmdline'] or [])[:100],
            'cpu_percent': cpu,
            'ram_mb': ram_mb,
            'ram_percent': ram_percent,
            'status': 'ok'
        }
    except (psutil.NoSuchProcess, psutil.AccessDenied):
        return None


def check_alerts(metrics):
    """Check if metrics exceed thresholds."""
    alerts = []

    if metrics['cpu_percent'] > CPU_THRESHOLD:
        alerts.append(f"High CPU: {metrics['cpu_percent']:.1f}%")
        metrics['status'] = 'warning'

    if metrics['ram_mb'] > RAM_ABSOLUTE_THRESHOLD / (1024 * 1024):
        alerts.append(f"High RAM: {metrics['ram_mb']:.0f}MB")
        metrics['status'] = 'critical'

    return alerts


def main():
    """Main monitoring function."""
    print(f"# MCP Resource Monitor - {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
    print()

    processes = find_mcp_processes()

    if not processes:
        print("❌ No MCP processes found!")
        print("\nTroubleshooting:")
        print("  1. Check if Claude Code is running")
        print("  2. Verify .mcp.json configuration")
        print("  3. Restart Claude Code if needed")
        sys.exit(1)

    print(f"Found {len(processes)} MCP process(es)\n")

    results = []
    total_cpu = 0
    total_ram = 0

    for proc in processes:
        metrics = get_process_metrics(proc)
        if metrics:
            alerts = check_alerts(metrics)
            metrics['alerts'] = alerts
            results.append(metrics)

            total_cpu += metrics['cpu_percent']
            total_ram += metrics['ram_mb']

    # Print results
    print("┌──────────────┬──────────┬──────────┬─────────┬────────┐")
    print("│ MCP          │ CPU %    │ RAM MB   │ RAM %   │ Status │")
    print("├──────────────┼──────────┼──────────┼─────────┼────────┤")

    for r in results:
        status_emoji = "✅" if r['status'] == "ok" else "⚠️" if r['status'] == "warning" else "🔴"
        print(f"│ {r['name'][:12]:12} │ {r['cpu_percent']:6.1f}%  │ {r['ram_mb']:6.0f}MB │ {r['ram_percent']:5.1f}%  │ {status_emoji} {r['status']:6} │")

        if r['alerts']:
            for alert in r['alerts']:
                print(f"│   ⚠️  {alert:<78} │")

    print("└──────────────┴──────────┴──────────┴─────────┴────────┘")
    print(f"\nTotal: {total_cpu:.1f}% CPU, {total_ram:.0f}MB RAM")

    # JSON output for CI/CD integration
    json_output = {
        'timestamp': datetime.now().isoformat(),
        'processes': results,
        'total_cpu_mb': total_cpu,
        'total_ram_mb': total_ram,
        'all_healthy': all(r['status'] == 'ok' for r in results)
    }

    print("\n--- JSON Output ---")
    print(json.dumps(json_output, indent=2))

    # Exit code based on health
    if not json_output['all_healthy']:
        sys.exit(1)


if __name__ == '__main__':
    main()
