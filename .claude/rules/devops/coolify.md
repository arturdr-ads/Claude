# 🐳 Coolify - Zero-Downtime Deployment

**Versão**: 1.0.0
**Atualizado**: 2026-03-23
**URL**: https://coolify.activeads.com.br

---

## 🎯 Visão Geral

Coolify é a plataforma de deploy usada para zero-downtime deployments com rollback automático.

### Stack

- **Coolify**: Platform as a Service
- **Nixpacks**: Build reproducível
- **Docker**: Containers
- **Blue-Green**: Deploy strategy

---

## 🔧 Configuração

### Variáveis de Ambiente

```bash
# Já configuradas no ambiente
COOLIFY_BASE_URL=https://coolify.activeads.com.br
COOLIFY_ACCESS_TOKEN=1|R7LCIFeFwbaSfHS11rrHtcMfGi3A1vCu8xLh3tOzb4ffe9ae

# Verificar
env | grep COOLIFY
```

### CLI do Coolify

```bash
# Instalar CLI (se necessário)
npm install -g coolify-cli

# Autenticar
coolify login --token $COOLIFY_ACCESS_TOKEN --url $COOLIFY_BASE_URL

# Verificar aplicações
coolify apps list
```

---

## 🚀 Deploy Strategies

### 1. Blue-Green (Recomendado para Produção)

**Vantagens**: Zero-downtime, rollback instantâneo

```bash
/coolify-deploy \
  --app myapp \
  --env production \
  --strategy blue-green \
  --health-check "/health" \
  --rollback-on-failure \
  --max-retries 3
```

**Fluxo**:
1. Nova versão deployada em ambiente "green"
2. Health checks executados em green
3. Se OK → Traffic switch para green
4. Se FALHA → Traffic mantido em blue, rollback automático

### 2. Rolling (Para Mutiple Instances)

**Vantagens**: Gradual, baixo risco

```bash
/coolify-deploy \
  --app myapp \
  --env production \
  --strategy rolling \
  --batch-size 2 \
  --health-check "/health"
```

**Fluxo**:
1. Deploy em 2 instances (batch)
2. Health checks
3. Próximo batch
4. Repetir até todas instances atualizadas

### 3. Canary (Para Testes Graduais)

**Vantagens**: Teste com traffic real

```bash
/coolify-deploy \
  --app myapp \
  --env production \
  --strategy canary \
  --canary-percent 10 \
  --duration 15m
```

**Fluxo**:
1. 10% do traffic para nova versão
2. Monitorar por 15 min
3. Se OK → 100% traffic
4. Se FALHA → Rollback

---

## 📋 Health Checks

### Configuração

```dockerfile
# Dockerfile healthcheck
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD curl -f http://localhost:3000/health || exit 1
```

### Endpoints de Health

```bash
# HTTP health endpoint
GET /health
# Response: {"status": "healthy", "version": "1.0.0"}

# Deep health (com dependências)
GET /health/deep
# Response: {"status": "healthy", "db": "up", "redis": "up", "api": "up"}
```

### Critérios de Saúde

- [ ] HTTP 200 em /health
- [ ] Error rate < 1%
- [ ] Latência p95 < 200ms
- [ ] CPU < 80%
- [ ] Memory < 80%
- [ ] Disk < 80%

---

## 🔄 Rollback Automático

### Condições de Rollback

```bash
# Qualquer uma das condições → rollback automático
- Health check falha > 3 tentativas
- Error rate > 1% por 5 min
- Latência p95 > 500ms por 5 min
- Crash count > 5 em 10 min
```

### Rollback Manual

```bash
# Rollback para versão anterior
coolify rollback myapp production

# Via skill
/rollback --app myapp --env production

# Forçar rollback (sem checks)
/rollback --app myapp --env production --force
```

---

## 🎯 Skills e Agents

### Skill: coolify-deploy

```bash
# Criar
mkdir -p .claude/skills/devops/coolify-deploy

# Ver arquivo completo em:
# .claude/rules/workflows/programar.md → Seção 6.1
```

### Agent: deployer

```yaml
name: deployer
description: Deploy zero-downtime com rollback automático
tools: [Bash, GitHub MCP, Tavily]
actions:
  - deploy: Executa deploy Coolify
  - rollback: Rollback automático
  - verify: Verifica saúde pós-deploy
```

---

## 📊 Monitoring

### Scripts Existentes

```bash
# Health check básico
./scripts/monitor-coolify.sh

# Health check via MCP
./scripts/monitor-coolify-mcp.sh
```

### Monitorar Deploy

```bash
# Ver logs de deploy
coolify logs myapp production --follow

# Ver status do deploy
coolify status myapp production

# Ver métricas
coolify metrics myapp production
```

---

## 🔧 Troubleshooting

### Deploy Trava

```bash
# 1. Ver status
coolify status myapp production

# 2. Ver logs
coolify logs myapp production --tail 100

# 3. Cancelar deploy
coolify cancel myapp production

# 4. Rollback se necessário
coolify rollback myapp production
```

### Health Check Falha

```bash
# 1. Verificar se container está rodando
coolify ps myapp production

# 2. Entrar no container
coolify exec myapp production -- bash

# 3. Testar health check manual
curl http://localhost:3000/health

# 4. Ver logs do container
coolify logs myapp production --tail 100
```

### Rollback Necessário

```bash
# Rollback imediato
coolify rollback myapp production

# Verificar健康 após rollback
curl https://myapp.example.com/health

# Investigar causa do problema
coolify logs myapp production --tail 500 > deploy-fail.log
```

---

## 🚨 Procedimentos de Emergência

### Deploy Quebrado em Produção

```bash
# 1. ROLLBACK IMEDIATO
coolify rollback myapp production --force

# 2. Verificar saúde
curl https://myapp.example.com/health

# 3. Declarar incidente
/agent sre-engineer --action incident-declare \
  --severity critical \
  --app myapp \
  --reason "deploy-failed"

# 4. Notificar time
# (Slack/Email integrado)

# 5. Investigar
coolify logs myapp production --tail 1000 > incident.log

# 6. Postmortem
/agent sre-engineer --action postmortem --incident INC-XXX
```

---

## 📚 Referências

- **Coolify Docs**: https://coolify.io/docs
- **Nixpacks**: https://nixpacks.com/docs
- **DevOps Architecture**: .claude/rules/devops/devops-architecture.md
- **Scripts**: scripts/monitor-coolify*.sh

---

**Próximo arquivo**: monitoramento.md → Monitoramento e alertas
