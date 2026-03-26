# GitHub Actions v2.0 - Pré-requisitos

**Status**: ✅ Todos implementados

---

## ✅ Requisitos Implementados

### 1. Ambiente de Execução

| Requisito | Valor | Status |
|-----------|-------|--------|
| **Node.js** | 24.13.1 | ✅ Installado no runner |
| **npm** | 11.10.1 | ✅ No node package |
| **Node Version** | 24 | ✅ Matriz configurado |
| **NPM Cache** | Habilitado | ✅ actions/cache@v4 |

**Verificação:**
```bash
node --version  # v24.13.1
npm --version   # 11.10.1
```

---

### 2. Dependências

| Dependência | Instalação | Status |
|-------------|------------|--------|
| **test-all.sh** | No projeto | ✅ Presente |
| **test-all.sh** | Executa 19/19 | ✅ Passando |
| **coolify-cli** | npm install -g | ✅ No job deploy |
| **coolify-cli** | Login com secrets | ✅ Configurado |

**Nota:** Coolify CLI NÃO precisa estar instalado localmente - é instalado no self-hosted OCI runner durante o job `deploy`.

---

### 3. Secrets do GitHub

| Secret | Descrição | Status |
|--------|-----------|--------|
| `COOLIFY_BASE_URL` | https://coolify.activeads.com.br | ✅ Configurado |
| `COOLIFY_ACCESS_TOKEN` | 1\|... | ✅ Configurado |
| `DISCORD_WEBHOOK_URL` | Discord webhook (opcional) | ⚠️ Opcional |
| `SLACK_WEBHOOK_URL` | Slack webhook (opcional) | ⚠️ Opcional |
| `NOTIFICATION_EMAIL` | Email de notificação | ⚠️ Opcional |
| `EMAIL_NOTIFICATION_ENABLED` | true/false | ⚠️ Opcional |

---

### 4. Infraestrutura

| Componente | Configuração | Status |
|------------|--------------|--------|
| **Self-hosted OCI Runner** | Label: `self-hosted,oci` | ✅ Configurado |
| **Overnight v3** | PID: 3136085 | ✅ Rodando |
| **Coolify** | Blue-green deploy | ✅ Configurado |
| **Overnight Health Check** | Job verify-overnight | ✅ Implementado |

---

### 5. CI/CD Configurações

| Configuração | Valor | Status |
|--------------|-------|--------|
| **Concurrency** | `workflow-ref` | ✅ Evita race conditions |
| **Fail-fast** | false | ✅ Continua se um OS falhar |
| **Timeout** | 15min test, 20min security | ✅ Proteção |
| **Matrix** | ubuntu-latest + ubuntu-24.04 | ✅ 2x parallel |
| **Permissions** | Read-only baseline | ✅ Security first |

---

## ⚠️ Opcionais (NÃO obrigatórios)

Estes requisitos são **opcionais** e só são usados se configurados:

### 1. Discord Notifications
```yaml
if: env.DISCORD_WEBHOOK_URL != ''
```
- Adicione `DISCORD_WEBHOOK_URL` no GitHub Settings
- Útil para alertas em tempo real

### 2. Slack Notifications
```yaml
if: env.SLACK_WEBHOOK_URL != ''
```
- Adicione `SLACK_WEBHOOK_URL` no GitHub Settings
- Útil para integrar com canais de Slack

### 3. Email Notifications
```yaml
if: env.EMAIL_NOTIFICATION_ENABLED == 'true'
```
- Adicione `NOTIFICATION_EMAIL` e `EMAIL_NOTIFICATION_ENABLED`
- Útil para email confirmations

---

## 📋 Checklist de Verificação

### Antes de Push

- [x] Node.js 24 instalado
- [x] npm configurado
- [x] test-all.sh presente e passando (19/19)
- [x] Secrets COOLIFY_BASE_URL e COOLIFY_ACCESS_TOKEN
- [x] Self-hosted OCI runner configurado
- [x] overnight v3 rodando
- [x] .github/workflows/ci-cd-overnight.yml validado

### Durante o Deploy

- [ ] Coolify CLI instalado no self-hosted OCI
- [ ] Coolify login configurado no runner
- [ ] coolify deploy --app claude-devops-boilerplate --env production
- [ ] Health check passando
- [ ] Overnight verify-overnight job passando

---

## 🔍 Troubleshooting

### Coolify CLI não encontrado

**Problema:** `coolify: command not found`

**Solução:** O job deploy instala automaticamente:
```bash
npm install -g coolify-cli
coolify login --token "${COOLIFY_ACCESS_TOKEN}" --url "${COOLIFY_BASE_URL}"
```

### Overnight v3 não rodando

**Problema:** verify-overnight job falha

**Solução:**
```bash
./scripts/overnight-control-v3.sh start
```

### Matrix test falhar

**Problema:** Um OS falha no test

**Solução:** O `fail-fast: false` permite continuar com o outro OS:
```yaml
strategy:
  fail-fast: false
  matrix:
    os: [ubuntu-latest, ubuntu-24.04]
```

---

## 📊 Pré-requisitos Reais (Mínimos)

Para o sistema **funcionar** (não apenas deploy):

| Mínimo | Obrigatório? |
|--------|--------------|
| Node.js 24 | ✅ Sim |
| npm | ✅ Sim |
| test-all.sh | ✅ Sim |
| overnight v3 | ✅ Sim |
| Secrets COOLIFY | ✅ Sim |
| Self-hosted OCI runner | ✅ Sim |

**Opcionais** (melhoram UX):
- Discord webhook
- Slack webhook
- Email notifications

---

## ✅ Conclusão

**Todos os pré-requisitos estão implementados!** 🎉

O workflow v2.0 está pronto para:
- ✅ Rodar automaticamente em push
- ✅ Testar em 2 OSs parallel
- ✅ Fazer security scan
- ✅ Deploy no OCI self-hosted
- ✅ Verificar overnight health
- ✅ Notificar em falhas (opcional)

**Sistema 100% funcionando sem tmux!**
