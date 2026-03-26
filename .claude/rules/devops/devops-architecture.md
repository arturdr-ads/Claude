# 🏗️ DevOps Architecture - Agentic IaC + GitOps Monorepo

**Versão**: 1.0.0
**Atualizado**: 2026-03-23
**Stack**: Claude Code CLI + Serena + OCI + Coolify

---

## 🎯 Visão Geral

Arquitetura DevOps completa para automação zero-downtime usando:
- **IaC**: Terraform/Pulumi para OCI
- **GitOps**: ArgoCD/Flux + GitHub Actions
- **CI/CD**: Coolify + Nixpacks
- **Monitoring**: Scripts customizados + Prometheus/Grafana
- **Agents**: Subagents especializados SRE/DevOps

---

## 📊 Matriz de Camadas

```
┌─────────────────────────────────────────────────────────────┐
│  CLAUDE CODE CLI (Orquestrador)                              │
│  - Serena (symbolic analysis)                                │
│  - Agents (iac-engineer, deployer, sre-engineer)             │
│  - Skills (coolify-deploy, tf-plan, monitor-alert)           │
└─────────────────────────────────────────────────────────────┘
                              │
        ┌─────────────────────┼─────────────────────┐
        │                     │                     │
        ▼                     ▼                     ▼
┌──────────────┐    ┌──────────────┐    ┌──────────────┐
│  IaC Layer   │    │  CI/CD Layer │    │ Monitoring   │
├──────────────┤    ├──────────────┤    ├──────────────┤
│ Terraform    │    │ Coolify      │    │ monitor-*    │
│ Pulumi       │    │ Nixpacks     │    │ Prometheus   │
│ OCI OIDC     │    │ GitHub MCP   │    │ Grafana      │
│ ESC Secrets  │    │ gh CLI       │    │ Alertas SRE  │
└──────────────┘    └──────────────┘    └──────────────┘
        │                     │                     │
        └─────────────────────┼─────────────────────┘
                              │
                              ▼
                    ┌──────────────┐
                    │  GitOps      │
                    ├──────────────┤
                    │ ArgoCD/Flux  │
                    │ blue-green   │
                    │ worktrees    │
                    └──────────────┘
```

---

## 🔧 Camada 1: IaC/Infra

### Ferramentas

| Ferramenta | Uso | Agent/Skill Relacionado |
|------------|-----|------------------------|
| **Terraform** | Infraestrutura OCI | `iac-engineer` agent, `tf-plan` skill |
| **Pulumi** | Infraestrutura multi-cloud | `iac-engineer` agent |
| **OCI OIDC** | Autenticação segura | `oci-provision` skill |
| **ESC (EnvSafe)** | Secrets management | `secrets-rotator` skill |

### Workflow IaC

```bash
# 1. Planejar mudanças
/tf-plan --dir terraform/oci/production

# 2. Validar com agent
/agent iac-engineer \
  --dir terraform/oci/production \
  --action validate

# 3. Aplicar (após aprovação)
terraform apply terraform/oci/production

# 4. Verificar drift
/agent iac-engineer --action check-drift
```

### Hooks IaC

```bash
# Hook: Valida Terraform antes de commit
/hookify add PreToolUse \
  --matcher "Bash(git commit.*)" \
  --file-pattern "*.tf" \
  --command "terraform fmt -check && tflint --recursive"
```

---

## 🚀 Camada 2: CI/CD

### Ferramentas

| Ferramenta | Uso | Agent/Skill Relacionado |
|------------|-----|------------------------|
| **Coolify** | Deploy zero-downtime | `coolify-deploy` skill, `deployer` agent |
| **Nixpacks** | Build reproducível | `deployer` agent |
| **GitHub MCP** | PR automation | `pr-reviewer` agent |
| **gh CLI** | Git operations | `smart-commit` skill |

### Workflow CI/CD

```bash
# 1. Feature branch (worktree paralelo)
git worktree add ../feature-DeployX feature/deploy-x

# 2. Desenvolver + testar
/agent test-runner --suite full

# 3. Criar PR
gh pr create --title "feat: deploy X" --body "..."

# 4. Code review automático
/agent pr-reviewer --pr-number 123

# 5. Merge + deploy
/deploy-app --app myapp --env production --rollback-enabled
```

### Deploy Zero-Downtime

```bash
# Strategy: Blue-Green via Coolify
/deploy-app \
  --app myapp \
  --env production \
  --strategy blue-green \
  --health-check "/health" \
  --rollback-on-failure \
  --max-retries 3
```

---

## 📊 Camada 3: Monitoring

### Ferramentas Existentes

| Script | Propósito | Integração |
|--------|-----------|------------|
| **monitor-coolify.sh** | Health check Coolify | Cron + alertas |
| **monitor-coolify-mcp.sh** | Coolify via MCP | Serena + Tavily |

### Workflow Monitoring

```bash
# 1. Configurar monitoramento
/monitor-alert \
  --app myapp \
  --endpoint https://myapp.example.com \
  --interval 60s

# 2. Agent SRE monitora SLOs
/agent sre-engineer \
  --action monitor-slo \
  --app myapp \
  --slo "error-rate < 0.1%" \
  --slo "latency p95 < 200ms"

# 3. Alertas automáticos
# Se SLO violado → alerta Slack + email

# 4. Incidente response
/agent sre-engineer --action incident --app myapp
```

### Scripts de Monitoramento

```bash
# Existente: monitor-coolify.sh
# Uso: ./scripts/monitor-coolify.sh

# Existente: monitor-coolify-mcp.sh
# Uso: ./scripts/monitor-coolify-mcp.sh
```

---

## 🔄 Camada 4: GitOps

### Ferramentas

| Ferramenta | Uso | Integração |
|------------|-----|------------|
| **ArgoCD** | GitOps deployment k8s | OCI OKE |
| **Flux** | GitOps alternative | Multi-cluster |
| **Worktrees** | Branches paralelas | gh CLI |

### Workflow GitOps

```bash
# 1. Declarar estado desejado (Git)
vim k8s/production/deployment.yaml

# 2. Commit + push
git add k8s/production/deployment.yaml
git commit -m "feat: update deployment"
git push

# 3. ArgoCD sync automático
# (Detecta mudança, aplica sync)

# 4. Verificar sync
argocd app get myapp --hard-refresh

# 5. Rollback se necessário
argocd app rollback myapp
```

---

## 🤖 Agents Especializados

### iac-engineer

```yaml
name: iac-engineer
description: Valida planos Terraform/Pulumi com drift detection
tools: [Read, Bash, Glob, mcp__serena__find_symbol]
actions:
  - validate: Valida sintaxe e segurança
  - plan: Gera plano de execução
  - drift: Verifica drift de infra
triggers:
  - Antes de terraform apply
  - Após mudanças em *.tf
```

### deployer

```yaml
name: deployer
description: Deploy zero-downtime com rollback automático
tools: [Bash, GitHub MCP, mcp__tavily__tavily_search]
actions:
  - deploy: Executa deploy
  - rollback: Rollback automático
  - verify: Verifica saúde pós-deploy
triggers:
  - Merge de PR de deploy
  - Manual via /deploy-app
```

### sre-engineer

```yaml
name: sre-engineer
description: Monitoramento, SLOs, incident response
tools: [Bash, Serena, Tavily, GitHub MCP]
actions:
  - monitor-slo: Monitora SLOs configurados
  - incident: Responde a incidentes
  - postmortem: Gera postmortem de incidente
triggers:
  - SLO violado
  - Incidente reportado
  - Manual via /sre
```

### security-auditor

```yaml
name: security-auditor
description: Scan de vulnerabilidades e compliance
tools: [Bash, EXA, GitHub MCP]
actions:
  - scan: Executa scan de segurança
  - compliance: Verifica compliance OCI
  - report: Gera relatório de segurança
triggers:
  - Antes de deploy production
  - Semanalmente
  - Manual via /security-scan
```

---

## 🎯 Skills Relacionadas

### DevOps Skills

```
.claude/skills/devops/
├── coolify-deploy/      # Deploy via Coolify
├── tf-plan/             # Terraform plan + validação
├── oci-provision/       # Provisionamento OCI
├── monitor-alert/       # Configurar alertas
├── rollback/            # Rollback automático
└── secrets-rotate/      # Rotação de secrets
```

### Criar Skill: coolify-deploy

```bash
mkdir -p .claude/skills/devops/coolify-deploy

cat > .claude/skills/devops/coolify-deploy/SKILL.md << 'EOF'
---
name: coolify-deploy
description: Deploy zero-downtime via Coolify com rollback automático
version: 1.0.0
author: arturdr
disable-model-invocation: false
---

# Coolify Deploy

## Descrição
Realiza deploy de aplicações via Coolify com estratégia blue-green e rollback automático em caso de falha.

## Uso

### Deploy Simples
```
/coolify-deploy
App: myapp
Env: production
```

### Deploy com Rollback
```
/coolify-deploy
App: myapp
Env: production
Strategy: blue-green
RollbackEnabled: true
MaxRetries: 3
HealthCheck: /health
```

### Variáveis de Ambiente
- `COOLIFY_BASE_URL`: URL do Coolify
- `COOLIFY_ACCESS_TOKEN`: Token de acesso

## Hooks Integrados
- PreToolUse: Valida Terraform antes de deploy
- PostToolUse: Notifica Slack pós-deploy

## Verificações
- [ ] Health check passando
- [ ] Error rate < 1%
- [ ] Latência p95 < 200ms

## Rollback Automático
Se qualquer verificação falhar, rollback automático é executado.
EOF
```

---

## 🔗 Integração com Ferramentas Existentes

### Scripts Atuais

```bash
# Já existem:
scripts/monitor-coolify.sh         # Health check básico
scripts/monitor-coolify-mcp.sh     # Health check via MCP

# Integrar com:
/agent sre-engineer --script scripts/monitor-coolify.sh
```

### Coolify Integration

```bash
# Variáveis de ambiente (já configuradas)
COOLIFY_BASE_URL=https://coolify.activeads.com.br
COOLIFY_ACCESS_TOKEN=1|R7LCIFeFwbaSfHS11rrHtcMfGi3A1vCu8xLh3tOzb4ffe9ae

# CLI do Coolify
coolify deploy --app myapp --env production
```

### GitHub Integration

```bash
# GitHub MCP + gh CLI
gh pr create --title "feat: deploy X"
gh pr review 123 --approve
gh pr merge 123 --squash

# Via GitHub MCP
/agent pr-reviewer --pr-number 123
```

---

## 📋 Fluxo DevOps Completo

### 1. Planejamento

```bash
/agent iac-engineer --dir terraform/oci/new-app
# Analisa requisitos, estima recursos, valida segurança
```

### 2. Codificação

```bash
# Feature branch em worktree paralelo
git worktree add ../feature-new-app feature/new-app

# Desenvolver com Serena
/serena find_symbol --name-path "Application" --relative-path "src/"
```

### 3. Review

```bash
# Code review automático
/agent pr-reviewer --pr-number 123

# Security scan
/agent security-auditor --scope new-app
```

### 4. Deploy

```bash
# Staging
/coolify-deploy --app myapp --env staging

# Testes E2E
/agent test-runner --env staging --suite e2e

# Production
/coolify-deploy --app myapp --env production --rollback-enabled
```

### 5. Monitoramento

```bash
# Scripts existentes
./scripts/monitor-coolify.sh

# Agent SRE
/agent sre-engineer --action monitor --app myapp --duration 24h
```

---

## 🚨 Procedimentos de Emergência

### Rollback Imediato

```bash
/rollback \
  --app myapp \
  --env production \
  --reason "error-rate > 5%" \
  --force
```

### Incident Response

```bash
# 1. Declarar incidente
/agent sre-engineer --action incident-declare \
  --severity critical \
  --app myapp

# 2. Investigar
/agent sre-engineer --action incident-investigate \
  --app myapp \
  --logs-duration 1h

# 3. Mitigar
/rollback --app myapp --env production

# 4. Postmortem
/agent sre-engineer --action postmortem \
  --incident INC-2026-03-23-001
```

---

## 📚 Referências

- **Terraform**: .claude/rules/devops/terraform.md
- **Coolify**: .claude/rules/devops/coolify.md
- **Monitoring**: .claude/rules/devops/monitoramento.md
- **Scripts**: scripts/monitor-coolify*.sh

---

**Próximo arquivo**: coolify.md → Configuração detalhada Coolify
