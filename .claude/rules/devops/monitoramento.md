# 📊 Monitoramento e Alertas - SRE

**Versão**: 1.0.0
**Atualizado**: 2026-03-23
**Stack**: Prometheus + Grafana + Scripts Customizados

---

## 🎯 Visão Geral

Sistema de monitoramento para:
- **Health Checks**: Verificação de saúde das aplicações
- **SLOs**: Service Level Objectives
- **Alertas**: Notificação de incidentes
- **Postmortem**: Análise pós-incidente

---

## 📁 Scripts de Monitoramento

### Scripts Existentes

```bash
# Health check básico do Coolify
scripts/monitor-coolify.sh

# Health check via MCP (mais avançado)
scripts/monitor-coolify-mcp.sh
```

### Estrutura dos Scripts

```bash
#!/bin/bash
# monitor-coolify.sh

# Variáveis
COOLIFY_BASE_URL="https://coolify.activeads.com.br"
HEALTH_ENDPOINT="/health"
ALERT_THRESHOLD=3  # 3 falhas consecutivas → alerta

# Loop de monitoramento
while true; do
  # Health check
  STATUS=$(curl -s -o /dev/null -w "%{http_code}" "$COOLIFY_BASE_URL$HEALTH_ENDPOINT")

  # Verificar status
  if [ "$STATUS" -eq 200 ]; then
    # OK
    echo "$(date): Health check PASS"
  else
    # FALHA
    echo "$(date): Health check FAIL (HTTP $STATUS)"
    # Incrementar contador de falhas
    # Se >= ALERT_THRESHOLD → disparar alerta
  fi

  sleep 60
done
```

---

## 🎯 SLOs (Service Level Objectives)

### SLOs Padrão

| Métrica | Objetivo | Janela |
|---------|----------|--------|
| **Disponibilidade** | 99.9% | 30 dias |
| **Error Rate** | < 0.1% | 24h |
| **Latência (p95)** | < 200ms | 24h |
| **Latência (p99)** | < 500ms | 24h |

### SLOs por Aplicação

```yaml
# myapp SLOs
availability:
  target: 99.9
  window: 30d

error_rate:
  target: 0.001  # 0.1%
  window: 24h

latency:
  p95:
    target: 200ms
    window: 24h
  p99:
    target: 500ms
    window: 24h
```

### Monitorar SLOs

```bash
# Agent SRE monitora SLOs
/agent sre-engineer \
  --action monitor-slo \
  --app myapp \
  --slo "error-rate < 0.1%" \
  --slo "latency-p95 < 200ms" \
  --duration 24h
```

---

## 🚨 Alertas

### Tipos de Alerta

| Severidade | Condição | Ação |
|------------|----------|------|
| **P1 (Critical)** | App DOWN | Rollback + notificação |
| **P2 (High)** | Error rate > 1% | Investigar + notificar |
| **P3 (Medium)** | Latência p95 > 500ms | Investigar |
| **P4 (Low)** | Disk > 80% | Planejar manutenção |

### Configurar Alertas

```bash
# Alertar se app ficar DOWN
/monitor-alert \
  --app myapp \
  --endpoint https://myapp.example.com/health \
  --interval 60s \
  --threshold 3 \
  --severity P1 \
  --notification slack
```

### Canais de Notificação

```bash
# Slack
SLACK_WEBHOOK_URL="https://hooks.slack.com/services/..."

# Email
ALERT_EMAIL="oncall@company.com"

# SMS (para P1)
TWILIO_PHONE="+5511999999999"
```

---

## 🤖 Agent: sre-engineer

### Configuração

```yaml
name: sre-engineer
description: Monitoramento, SLOs, incident response
version: 1.0.0
tools: [Bash, Serena, Tavily, GitHub MCP]
max_iterations: 10
timeout: 300
```

### Ações

#### monitor-slo

```bash
/agent sre-engineer \
  --action monitor-slo \
  --app myapp \
  --slo "error-rate < 0.1%" \
  --slo "latency-p95 < 200ms" \
  --duration 24h
```

#### incident

```bash
# Declarar incidente
/agent sre-engineer \
  --action incident-declare \
  --severity P1 \
  --app myapp \
  --reason "App unresponsive"

# Investigar
/agent sre-engineer \
  --action incident-investigate \
  --incident INC-2026-03-23-001 \
  --logs-duration 1h

# Fechar incidente
/agent sre-engineer \
  --action incident-close \
  --incident INC-2026-03-23-001 \
  --resolution "Rollback executado, problema resolvido"
```

#### postmortem

```bash
/agent sre-engineer \
  --action postmortem \
  --incident INC-2026-03-23-001 \
  --output docs/postmortems/
```

---

## 📈 Métricas

### Métricas de Aplicação

```bash
# HTTP metrics
http_requests_total{status="200"}
http_requests_total{status="500"}
http_request_duration_seconds{quantile="0.95"}

# Business metrics
orders_total
orders_failed
revenue_total
```

### Métricas de Infraestrutura

```bash
# CPU
cpu_usage_percent{app="myapp"}

# Memory
memory_usage_bytes{app="myapp"}

# Disk
disk_usage_percent{mount="/data"}

# Network
network_receive_bytes_total{interface="eth0"}
network_transmit_bytes_total{interface="eth0"}
```

### Coletar Métricas

```bash
# Via Prometheus
curl http://prometheus:9090/api/v1/query?query=up

# Via Grafana
curl http://grafana:3000/api/datasources

# Via script customizado
./scripts/collect-metrics.sh --app myapp --output metrics.json
```

---

## 🔧 Troubleshooting

### App Respondendo Lentamente

```bash
# 1. Verificar métricas de latência
/agent sre-engineer --action check-metrics --app myapp --metric latency

# 2. Verificar CPU/Memory
coolify stats myapp production

# 3. Verificar logs
coolify logs myapp production --tail 100

# 4. Verificar database (se aplicável)
/agent sre-engineer --action check-db --app myapp
```

### Error Rate Alto

```bash
# 1. Declarar incidente se > 1%
if [ "$(error_rate)" -gt 1 ]; then
  /agent sre-engineer --action incident-declare --severity P2
fi

# 2. Verificar logs de erro
coolify logs myapp production --grep "ERROR" --tail 100

# 3. Verificar mudanças recentes
git log --oneline -10

# 4. Considerar rollback se começou após deploy
if [ "error_rate_increased_after_deploy" ]; then
  /rollback --app myapp --env production
fi
```

### App Down

```bash
# 1. Declarar incidente CRÍTICO
/agent sre-engineer \
  --action incident-declare \
  --severity P1 \
  --app myapp \
  --reason "App unresponsive"

# 2. ROLLBACK IMEDIATO
/rollback --app myapp --env production --force

# 3. Verificar logs do deploy falho
coolify logs myapp production --tail 500 > incident.log

# 4. Verificar saúde após rollback
curl https://myapp.example.com/health

# 5. Notificar time
# (Slack/Email integrado via hook)
```

---

## 📊 Dashboards

### Grafana Dashboard

```json
{
  "dashboard": {
    "title": "MyApp - Production",
    "panels": [
      {
        "title": "Request Rate",
        "targets": [
          {
            "expr": "rate(http_requests_total[5m])"
          }
        ]
      },
      {
        "title": "Error Rate",
        "targets": [
          {
            "expr": "rate(http_requests_total{status=~\"5..\"}[5m]) / rate(http_requests_total[5m])"
          }
        ]
      },
      {
        "title": "Latency (p95)",
        "targets": [
          {
            "expr": "histogram_quantile(0.95, http_request_duration_seconds)"
          }
        ]
      }
    ]
  }
}
```

---

## 📝 Postmortem

### Template de Postmortem

```markdown
# Postmortem: INC-2026-03-23-001

## Resumo
[Breve descrição do incidente]

## Impacto
- Duração: X horas
- Usuários afetados: Y
- Receita perdida: R$ Z

## Linha do Tempo
- **10:00** - Alerta disparado (app DOWN)
- **10:05** - Rollback executado
- **10:10** - App restaurado
- **10:30** - Investigação inicial completa
- **11:00** - Incidente fechado

## Causa Raiz
[Análise da causa]

## O Que Aconteceu
[Descrição detalhada]

## O Que Funcionou Bem
- Rollback automático funcionou
- Alerta chegou rapidamente

## O Que Poderia Ser Melhor
- Detecção mais precoce
- Mais detalhes no alerta

## Ações de Melhoria
- [ ] Adicionar health check mais granular
- [ ] Implementar cache de fallback
- [ ] Documentar procedimento de rollback manual

## Envolvidos
- Artur (SRE)
- [Time member 2]
```

### Gerar Postmortem

```bash
/agent sre-engineer \
  --action postmortem \
  --incident INC-2026-03-23-001 \
  --output docs/postmortems/INC-2026-03-23-001.md
```

---

## 📚 Referências

- **Prometheus**: https://prometheus.io/docs
- **Grafana**: https://grafana.com/docs
- **SRE Book**: https://sre.google/sre-book/table-of-contents/
- **DevOps Architecture**: .claude/rules/devops/devops-architecture.md
- **Scripts**: scripts/monitor-coolify*.sh

---

**Fim da documentação DevOps**
