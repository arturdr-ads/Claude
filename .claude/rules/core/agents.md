# 🤖 Regras de Ouro - Agents & Subagents

**Versão**: 1.0.0
**Atualizado**: 2026-03-23
**Status**: Production

---

## 🎯 Regra #1: Agents para Tarefas Autônomas e Paralelas

**Use agents quando**: A tarefa pode ser executada independentemente, em paralelo, ou requer especialização profunda.

### ✅ Quando Usar Agents

- **Tarefas paralelas**: Revisar 10 PRs simultaneamente
- **Especialização**: Análise de segurança requires expertise específica
- **Long-running**: Monitoramento contínuo, scans demorados
- **Isolamento**: Operações que não devem bloquear o contexto principal

### ❌ Quando NÃO Usar Agents

- **Tarefas simples**: "Listar arquivos", "Criar diretório"
- **One-off rápidas**: Coisas que levam < 30s
- **Altamente interativas**: Coisas que requerem feedback constante do usuário
- **Dependentes**: Tasks que dependem umas das outras (execução sequencial é melhor)

---

## 📁 Estrutura de Agents

```
.claude/agents/
├── <nome-agent>/
│   ├── agent.md              # Configuração principal
│   ├── prompt.md             # System prompt
│   ├── tools/                # Tools permitidas (opcional)
│   └── examples/             # Exemplos de uso
```

### agent.md (Frontmatter)

```yaml
---
name: mcp-validator
description: Valida todos MCPs, skills e plugins do projeto
version: 1.0.0
author: arturdr
tools: [Bash, Glob, Read, Write]  # Tools permitidas (restrito)
mode: auto  # auto | interactive
max_iterations: 10
timeout: 300  # segundos
---
```

### Restringir Tools (Boa Prática)

**Por quê?** Agents com todas as tools podem causar danos

**Exemplo**:
```yaml
tools: [Read, Glob]  # Apenas leitura = seguro
```

**Sem restrição**:
```yaml
# Herda todas as tools do pai
# Pode ser perigoso para agentes de produção
```

---

## 📋 Comandos de Agents

```bash
# Listar agents disponíveis
/agents

# Executar agent
/agent <nome-agent>

# Executar com parâmetros
/agent <nome-agent> --param valor

# Executar em background
/agent <nome-agent> --background
```

---

## 💡 Categorias de Agents

### 1. DevOps (Seu foco principal)

| Agent | Propósito | Tools | Trigger |
|-------|-----------|-------|---------|
| **iac-engineer** | Valida planos Terraform/Pulumi | Read, Bash, Glob | Antes de apply |
| **deployer** | Deploy zero-downtime com rollback | Bash, GitHub MCP | Deploy para prod |
| **sre-engineer** | Monitoramento, SLOs, alertas | Bash, Serena, Tavily | Após incidente |
| **security-auditor** | Scan de vulnerabilidades | Bash, EXA, GitHub | Antes de release |
| **cost-optimizer** | Otimiza custos OCI/AWS | Bash, Context7 | Mensalmente |

### 2. Code Quality

| Agent | Propósito | Tools | Trigger |
|-------|-----------|-------|---------|
| **pr-reviewer** | Revisa PRs automaticamente | GitHub, Serena | Em cada PR |
| **code-analyzer** | Análise estática de código | Serena, Glob | Em PRs |
| **test-runner** | Executa suite de testes | Bash | Antes de merge |
| **doc-generator** | Gera documentação | Serena, Write | Ao release |

### 3. Operations

| Agent | Propósito | Tools | Trigger |
|-------|-----------|-------|---------|
| **mcp-auditor** | Valida saúde dos MCPs | Bash | Diariamente |
| **backup-manager** | Gerencia backups | Bash, GitHub MCP | Automaticamente |
| **log-analyzer** | Analisa logs de erro | Bash, Tavily | Em incidentes |

---

## 🚨 Problemas Comuns

### 1. Agent Não Encontrado

**Sintoma**: `/agent nome` retorna "agent not found"

**Diagnóstico**:
```bash
# Verificar se agent.md existe
ls -la .claude/agents/<nome>/agent.md

# Validar frontmatter
cat .claude/agents/<nome>/agent.md | head -15
```

**Solução**:
- Garantir arquivo named `agent.md` (não `AGENT.md`)
- Verificar sintaxe do frontmatter
- Reiniciar Claude Code CLI

### 2. Agent Executa Infinitamente

**Sintoma**: Agent nunca termina

**Causa**: Sem `max_iterations` ou timeout

**Solução**:
```yaml
max_iterations: 10  # Limite de iterações
timeout: 300  # Limite de tempo em segundos
```

### 3. Agent com Tools Perigosas

**Sintoma**: Agent executou `rm -rf` ou similar

**Causa**: Agent herdou todas tools sem restrição

**Solução**: Sempre restringir tools
```yaml
tools: [Read, Glob]  # Apenas leitura para agentes de auditoria
```

---

## 💡 Best Practices

### 1. Agents Especializados vs Generalistas

**❌ Ruim**: Agent "do-everything" que faz tudo
**✅ Bom**: Agents especializados (iac-engineer, deployer, sre)

**Por quê?**
- Mais fácil de debugar
- Pode ser executado em paralelo
- Ferramentas restritas por domínio

### 2. Frontmatter Completo

```yaml
---
name: iac-engineer
description: Valida planos Terraform/Pulumi com análise de drift e segurança
version: 1.0.0
author: arturdr
tags: [devops, terraform, pulumi, iac, security]
tools: [Read, Bash, Glob, mcp__serena__find_symbol]
mode: auto
max_iterations: 10
timeout: 300
depends: [terraform, pulumi, jq]
---
```

### 3. System Prompt Clara

```markdown
## Role

Você é um engenheiro de IaC especializado em Terraform e Pulumi.

## Responsabilidades

1. Validar planos antes de apply
2. Verificar drift de infraestrutura
3. Analisar configurações de segurança
4. Sugerir otimizações de custo

## Restrições

- NUNCA fazer apply sem aprovação explícita
- Sempre mostrar diff completo
- Alertar sobre mudanças destrutivas
- Verificar compliance com políticas OCI

## Exemplo de Uso

```
/agent iac-engineer
Directory: terraform/oci/production
Action: plan
```
```

### 4. Exemplos de Uso

Sempre incluir exemplos concretos no prompt.md

---

## 🎯 Matriz de Decisão: Agent vs Skill vs Função

| Precisa de... | Use | Exemplo |
|---------------|-----|---------|
| Workflow simples, recorrente | **Skill** | Formatar commits |
| Tarefa autônoma, paralela | **Agent** | Revisar 10 PRs |
| Workflow complexo, guiado | **Skill** + Agent | Deploy com agentes especializados |
| Integração externa persistente | **Plugin** | GitHub MCP wrapper |
| Análise profunda, iterativa | **Agent** | Refactoring de código base |
| Ação rápida, local | **Função direta** | Criar arquivo |

---

## 🔧 Validação de Agents

### Checklist Antes de Commitar

- [ ] Frontmatter válido (YAML)
- [ ] Tools restritas (se aplicável)
- [ ] max_iterations e timeout definidos
- [ ] System prompt claro e completo
- [ ] Exemplos de uso
- [ ] Testado manualmente
- [ ] Sem conflito com outros agents

### Teste de Agent

```bash
# 1. Listar agents
/agents

# 2. Executar agent
/agent <nome>

# 3. Verificar resultado
# Funcionou como esperado?
# Respeitou restrições de tools?
# Terminou em tempo hábil?
```

---

## 📚 Agents Recomendados (Seu Stack DevOps)

### Essenciais

```
.claude/agents/
├── devops/
│   ├── iac-engineer.md       # Terraform/Pulumi validation
│   ├── deployer.md           # Zero-downtime deployments
│   ├── sre-engineer.md       # Monitoring, SLOs, incidentes
│   └── security-auditor.md   # Security scans, compliance
├── code/
│   ├── pr-reviewer.md        # Automated PR reviews
│   └── code-analyzer.md      # Static analysis
└── ops/
    ├── mcp-auditor.md        # MCP health checks
    └── backup-manager.md     # Backup automation
```

### Opcionais

```
├── cost/
│   └── cost-optimizer.md     # OCI/AWS cost optimization
└── docs/
    └── doc-generator.md      # Auto-generate docs
```

---

## 🔄 Execução Paralela de Agents

### Exemplo: Deploy Completo

```bash
# Agent 1: Valida IaC
/agent iac-engineer --dir terraform/oci/prod &

# Agent 2: Executa testes
/agent test-runner --suite full &

# Agent 3: Scan de segurança
/agent security-auditor --scope production &

# Agent 4: Review (aguarda os anteriores)
/agent pr-reviewer --pr-id 123

# Agent 5: Deploy (após todos aprovarem)
/agent deployer --env production --rollback-enabled
```

**Benefício**: Execução paralela = deploy mais rápido

---

## 🔧 Troubleshooting

### Agent Nunca Termina

**Causa**: Loop infinito ou tarefa muito demorada

**Solução**:
```yaml
max_iterations: 10
timeout: 300  # 5 minutos
```

### Agent com Acesso Perigosas

**Causa**: Tools não restritas

**Solução**: Sempre especificar tools
```yaml
tools: [Read, Glob]  # Safe para auditoria
```

### Agent com Resultado Inesperado

**Causa**: System prompt ambígua

**Solução**: Ser extremamente específico no prompt.md
```markdown
## NÃO FAZER
- NUNCA executar apply sem aprovação
- NUNCA modificar arquivos fora do diretório especificado
```

---

## 📚 Referências

- **Superpowers Agents**: `~/.claude/plugins/cache/.../superpowers/.../skills/subagent-driven-development/`
- **Agent Docs**: `~/.claude/plugins/.../plugin-dev/skills/.../`
- **Seus Agents**: `~/.claude/agents/`

---

**REGRA DE OURO**: Agents para tarefas autônomas e paralelas, sempre com tools restritas e timeouts definidos.
