# Claude Code CLI - Auto-Pilot DevOps Mode

Sistema profissional de auto-pilot para Claude Code CLI com hooks avançados, formatação automática e integração OCI/Terraform.

## 🚀 Features

### Hooks Automáticos

| Hook | Gatilho | Ação |
|------|---------|------|
| **SessionStart** | Início da sessão | Mostra mudanças recentes |
| **PreToolUse** | `git push.*main` | Alerta sobre push para main |
| **PostToolUse** | `Edit\|Write` | Auto-format + git add |
| **PostToolUse** | `git commit.*` | Confirmação de commit |
| **UserPromptSubmit** | Tarefas | Log de atividades |

### Auto-Format

| Extensão | Formatter |
|----------|-----------|
| `*.tf`, `*.tfvars` | `terraform fmt` |
| `*.yml`, `*.yaml` | `yq --prettyPrint` |
| `Dockerfile` | `yq --prettyPrint` |

### GitHub Actions

- **Claude PR Review** - Review automático com `@claude`
- **Terraform Plan** - Plan automático em PRs
- **Security Scan** - tfsec para arquivos TF

## 📦 Instalação

```bash
# Clonar repositório
git clone https://github.com/arturdr-ads/Claude.git
cd Claude

# Copiar configuração
cp .claude/settings.json.example .claude/settings.json

# Instalar dependências
sudo apt install -y terraform yq

# Configurar GitHub OAuth
gh auth login --web
gh auth setup-git
```

## 🔐 Configuração

### Variáveis de Ambiente

```bash
# GitHub
GITHUB_TOKEN=$(gh auth token)

# Coolify
COOLIFY_BASE_URL=https://coolify.activeads.com.br
COOLIFY_ACCESS_TOKEN=seu_token_aqui

# Cloudflare
CLOUDFLARE_API_TOKEN=seu_token_aqui
CLOUDFLARE_ACCOUNT_ID=seu_id_aqui

# APIs de busca
TAVILY_API_KEY=sua_chave_aqui
EXA_API_KEY=sua_chave_aqui
```

### Secrets do GitHub

No repositório, adicicionar:

```
ANTHROPIC_API_KEY=sk-ant-...
```

## 📝 Como Usar

### Reviews Automáticos de PR

1. Crie um Pull Request
2. Comente `@claude review changes`
3. Claude analisa e comenta no PR

### Terraform Plan Automático

```bash
# Em um PR com arquivos .tf
# O workflow roda terraform plan automaticamente
# Os resultados aparecem como comentário
```

### Deploy via Coolify

```bash
# Ler skill do Coolify
cat .claude/skills/coolify/SKILL.md

# Deploy via API
curl -X POST $COOLIFY_BASE_URL/api/applications/1/deploy \
  -H "Authorization: Bearer $COOLIFY_ACCESS_TOKEN"
```

## 🧪 Testes

### Testar hooks

```bash
# Criar arquivo Terraform mal formatado
echo 'resource "oci_bucket" "test"{name="test"}' > test.tf

# Verificar formatação automática
cat test.tf

# Verificar git add automático
git status
```

### Testar com max-turns

```bash
# Deploy OCI stack via hooks
claude --max-turns 20 "deploy OCI stack via hooks"
```

## 🛠️ Troubleshooting

### Ver status dos hooks

```bash
# No Claude Code CLI
/hooks

# Ver configuração
cat .claude/settings.json | jq .
```

### Debug mode

```bash
# Ativar verbose
Ctrl+O

# Debug completo
claude --debug "comando aqui"
```

### Logs

```bash
# Log de tarefas
cat ~/.claude/task.log

# Log de comandos
cat ~/.claude/command-log.txt
```

## 📚 Estrutura

```
Claude/
├── .claude/
│   ├── settings.json          # Configuração de hooks
│   ├── settings.local.json    # Permissões locais
│   └── skills/
│       └── coolify/
│           └── SKILL.md       # Skill de deploy Coolify
├── .github/
│   └── workflows/
│       └── claude-pr.yml      # GitHub Actions
└── README.md
```

## 🔗 Links

- **Repositório**: https://github.com/arturdr-ads/Claude
- **Claude Code Docs**: https://code.claude.com/docs
- **Coolify Docs**: https://coolify.io/docs

## 📄 Licença

MIT

---

**Auto-Pilot DevOps Mode** - Transforma Claude Code CLI em um sistema profissional de automação DevOps.
