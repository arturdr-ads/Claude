# Especificação: Auto-Pilot Mode para Claude Code CLI

## Visão Geral

Configuração completa para operar o Claude Code CLI em modo totalmente automático, sem necessidade de invocação manual de ferramentas. O sistema seleciona ferramentas dinamicamente, aplica formatação automática e gerencia o Git automaticamente.

**Data**: 2026-03-12
**Versão**: 1.0

---

## 1. Arquitetura da Configuração

```
~/.claude/                          # Configurações Globais (todos projetos)
├── settings.json                   # Configurações de auto-mode, permissões, hooks
├── CLAUDE.md                      # Instruções principais (~200 tokens)
└── skills/
    └── devops-oci.md              # Skill on-demand DevOps (carregada sob demanda)

.claude/                            # Configurações Locais (projeto atual)
└── settings.local.json            # Sobrescritas privadas (se necessário)
```

---

## 2. Configurações Globais (~/.claude/settings.json)

### 2.1. Configurações de Auto-Mode

| Configuração | Valor | Descrição |
|--------------|-------|-----------|
| `tool_choice` | `"auto"` | Seleção dinâmica de ferramentas |
| `enableAllProjectMcpServers` | `true` | MCPs habilitados automaticamente |
| `teammateMode` | `"auto"` | Agent teams orquestrados automaticamente |

### 2.2. Permissões

```json
{
  "permissions": {
    "defaultMode": "acceptEdits",
    "allow": [
      "Bash(*)",
      "Read(*)",
      "Edit(*)",
      "Write(*)",
      "mcp__*",
      "Glob(*)",
      "Grep(*)",
      "WebSearch",
      "AskUserQuestion",
      "EnterPlanMode",
      "ExitPlanMode",
      "TaskCreate",
      "TaskGet",
      "TaskUpdate",
      "TaskList",
      "Agent(*)",
      "Skill(*)"
    ],
    "deny": [
      "Bash(rm -rf|rm -R|kill -9)",
      "Read(.env)",
      "Read(secrets/**)",
      "Write(.env)",
      "Write(secrets/**)"
    ]
  }
}
```

**Comportamento**:
- `defaultMode: "acceptEdits"`: Todas as edições são aceitas automaticamente sem confirmação
- `allow`: Permite todas as operações essenciais
- `deny`: Bloqueia comandos perigosos e acesso a arquivos sensíveis

### 2.3. Hooks

#### PreToolUse - Segurança

```json
{
  "PreToolUse": [
    {
      "matcher": "Bash(rm -rf|rm -R|kill -9)",
      "hooks": [
        {
          "type": "command",
          "command": "echo '⚠️  Comando perigoso bloqueado.' >&2; exit 2"
        }
      ]
    }
  ]
}
```

**Comportamento**: Bloqueia comandos perigosos antes da execução.

#### PostToolUse - Formatação e Git

```json
{
  "PostToolUse": [
    {
      "matcher": "Edit|Write",
      "hooks": [
        {
          "type": "command",
          "command": "jq -r '.tool_input.file_path' | xargs -I {} bash -c 'case \"{}\" in *.tf|*.tfvars) terraform fmt \"{}\" 2>/dev/null || true ;; *.yml|*.yaml|Dockerfile) yq --prettyPrint \"{}\" 2>/dev/null || true ;; *.sh) shfmt -i 2 -ci \"{}\" 2>/dev/null || true ;; *.ts|*.js|*.json) npx prettier --write \"{}\" 2>/dev/null || true ;; esac'"
        }
      ]
    },
    {
      "matcher": "Bash",
      "hooks": [
        {
          "type": "command",
          "command": "git add ."
        }
      ]
    }
  ]
}
```

**Comportamento**:
- Após cada edição de arquivo, aplica o formatter apropriado
- Após cada comando Bash, executa `git add .`

---

## 3. Formatters por Extensão

| Extensão | Formatter | Comando |
|----------|-----------|---------|
| *.tf, *.tfvars | terraform fmt | `terraform fmt {file}` |
| *.yml, *.yaml, Dockerfile | yq | `yq --prettyPrint {file}` |
| *.sh | shfmt | `shfmt -i 2 -ci {file}` |
| *.ts, *.js, *.json | prettier | `npx prettier --write {file}` |

---

## 4. CLAUDE.md - Instruções Principais

**Objetivo**: Fornecer contexto mínimo (~200 tokens) para economizar contexto de conversação.

```markdown
# Auto-Pilot DevOps Mode

Este projeto está configurado para funcionar completamente automático.

## Stack Tecnológico
- Terraform/IaC: OCI, OCIR, OKE, OCI Compute
- Docker: docker-compose.yml, Dockerfiles
- Coolify: Deploy automático via YAML

## Comportamento Automático
- Todas as edições são aceitas automaticamente
- MCPs são habilitados automaticamente
- Seleção de ferramentas é dinâmica
- Formatação é aplicada após cada edição
- Comandos Bash executam git add automaticamente

## Proteções de Segurança
- Comandos perigosos (rm -rf, kill -9) são bloqueados
- Arquivos .env e secrets/** não podem ser lidos/escritos

## Skills On-Demand
Instruções detalhadas em `skills/devops-oci.md` - carregadas sob demanda.
```

---

## 5. Skills On-Demand

### 5.1. Skill: DevOps OCI/Docker/Coolify

**Arquivo**: `~/.claude/skills/devops-oci.md`

**Conteúdo**: Instruções detalhadas para DevOps, carregadas apenas quando necessário.

**Seções**:
- OCI: Terraform modules, padrões de nomenclatura
- Docker: Dockerfile best practices, docker-compose estrutura
- Coolify: Deploy YAML, integrações
- Shell Scripts: Formatters e padrões
- Checklist de deploy

---

## 6. Fluxo de Operação Automática

```
1. Sessão Inicia
   ├─ settings.json carregado
   ├─ CLAUDE.md lido (contexto mínimo)
   ├─ MCPs habilitados automaticamente
   └─ Teams configurados para modo auto

2. Usuário Faz Requisição
   ├─ tool_choice: "auto" seleciona ferramenta
   ├─ Permissões verificadas (defaultMode: acceptEdits)
   └─ Hook PreToolUse: Bloqueia comandos perigosos

3. Ferramenta Executa
   ├─ Bash/Read/Write/Edit/Agent/Skill/etc.
   └─ Hook PostToolUse acionado
       ├─ Se Edit/Write: Formata arquivo
       └─ Se Bash: git add .

4. Skill On-Demand
   ├─ Se necessário: Lê skills/devops-oci.md
   └─ Contexto expandido apenas quando preciso
```

---

## 7. Contexto Otimizado

### Estratégia de Economia de Contexto

| Componente | Tokens (aprox.) | Quando Carregado |
|------------|-----------------|------------------|
| CLAUDE.md | ~200 | Sempre (início da sessão) |
| settings.json | ~500 | Sempre (configuração) |
| skills/devops-oci.md | ~1,500 | Sob demanda |
| **Total Inicial** | **~700** | Sempre carregado |

**Benefício**: Contexto inicial mínimo, expandido apenas quando necessário.

---

## 8. Comandos Descontinuados (NÃO Existem)

Os seguintes comandos citados em fontes comunitárias **NÃO existem** na documentação oficial:

| Comando | Status | Alternativa Oficial |
|---------|--------|---------------------|
| `/mcp start all` | ❌ Não existe | `enableAllProjectMcpServers: true` |
| `/team auto` | ❌ Não existe | `teammateMode: "auto"` |
| `/tool-choice auto` | ❌ Não existe | `tool_choice: "auto"` |
| `/skills load` | ❌ Não existe | Skills carregam automaticamente |
| `/add-dir .claude/mcp` | ❌ Não existe | MCP configurado em .claude.json |
| `auto_commands` | ❌ Não existe | Usar Hooks (SessionStart, etc.) |
| `default_mode` | ❌ Não existe | `permissions.defaultMode` |
| `mcp_auto_discover` | ❌ Não existe | `enableAllProjectMcpServers` |
| `skills_auto_load` | ❌ Não existe | Automático por padrão |
| `dynamic_tool_selection` | ❌ Não existe | `tool_choice: "auto"` |
| `parallel_tools` | ❌ Não existe | Automático por padrão |
| `auto_team_orchestration` | ❌ Não existe | `teammateMode: "auto"` |

---

## 9. Verificação de Funcionamento

### Checklist de Validação

- [ ] `~/.claude/settings.json` existe e é válido JSON
- [ ] `tool_choice: "auto"` está configurado
- [ ] `enableAllProjectMcpServers: true` está configurado
- [ ] `teammateMode: "auto"` está configurado
- [ ] `defaultMode: "acceptEdits"` está configurado
- [ ] Hooks PreToolUse e PostToolUse configurados
- [ ] `~/.claude/CLAUDE.md` existe
- [ ] `~/.claude/skills/devops-oci.md` existe
- [ ] Formatters instalados (terraform, yq, shfmt, prettier)

### Testes de Comportamento

1. **Edição automática**: Editar um arquivo .tf → deve ser formatado automaticamente
2. **Git automático**: Executar comando Bash → `git add .` deve ser executado
3. **Segurança**: Tentar `rm -rf` → deve ser bloqueado
4. **MCPs**: Verificar se MCPs do projeto estão habilitados
5. **Teams**: Verificar se agent teams funcionam automaticamente

---

## 10. Referências Oficiais

- Documentação oficial: https://code.claude.com/docs/pt/settings
- Hooks: https://code.claude.com/docs/pt/hooks-guide
- CLI Reference: https://code.claude.com/docs/pt/cli-reference

**NOTA**: Apenas code.claude.com é fonte oficial. Fontes comunitárias (InventiveHQ, Blake Crosley, Eesel.ai, Reddit) podem estar desatualizadas ou incorretas.

---

## 11. Manutenção

### Atualizações Recomendadas

1. **Semestral**: Revisar documentação oficial por mudanças
2. **Trimestral**: Atualizar skills DevOps com novas práticas
3. **Mensal**: Verificar formatters instalados atualizados

### Monitoramento

- Observar logs de hooks para erros de formatação
- Verificar contexto usado por sessão
- Ajustar CLAUDE.md se contexto inicial crescer

---

## Changelog

| Data | Versão | Mudanças |
|------|--------|----------|
| 2026-03-12 | 1.0 | Especificação inicial |
