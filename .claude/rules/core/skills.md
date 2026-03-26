# 🎯 Regras de Ouro - Skills

**Versão**: 1.0.0
**Atualizado**: 2026-03-23
**Status**: Production

---

## 🎯 Regra #1: Skills Sob Demanda

**Carregar skills apenas quando necessário = economia de contexto**

### ✅ Quando Criar Skills

- **Workflows recorrentes**: Operações que você repete frequentemente
- **Processos complexos**: Multi-passos que exigem precisão
- **Automação crítica**: Deploy, commit, operations que não podem falhar
- **Conhecimento específico**: Docs pesadas que não cabem em CLAUDE.md

### ❌ Quando NÃO Criar Skills

- **Tarefas simples**: "Criar arquivo", "listar diretórios"
- **One-off operations**: Coisas que você faz apenas uma vez
- **Docs triviais**: Coisas óbvias ou que mudam constantemente
- **Coisas em CLAUDE.md**: Se já está no contexto, não duplicar em skill

---

## 📁 Estrutura de Skills

```
.claude/skills/
├── <nome-skill>/
│   ├── SKILL.md              # Frontmatter + conteúdo
│   ├── references/           # Docs auxiliares
│   └── examples/             # Exemplos de uso
```

### Frontmatter Obrigatório

```yaml
---
name: nome-skill
description: Uma linha descritiva
version: 1.0.0
author: arturdr
---
```

### disable-model-invocation

**Use para ações críticas**: Deploy, commit, delete operations

```yaml
---
disable-model-invocation: true
---
```

**Efeito**: Skill executa sem chamar LLM (mais rápido, mais seguro)

---

## 📋 Comandos de Skills

```bash
# Listar todos skills
/skills

# Executar skill
/nome-skill

# Validar skill (com superpowers)
/agent skill-validator
```

---

## 💡 Categorias de Skills

### 1. DevOps (Seu foco principal)

| Skill | Propósito | Trigger |
|-------|-----------|---------|
| **coolify-deploy** | Deploy zero-downtime via Coolify | Antes de prod |
| **tf-plan** | Terraform plan + validação | Antes de apply |
| **oci-provision** | Provisionar recursos OCI | Novos ambientes |
| **monitor-alert** | Configurar alertas SRE | Após deploy |
| **rollback** | Rollback automático com fallback | Emergências |

### 2. Git & GitHub

| Skill | Propósito | Trigger |
|-------|-----------|---------|
| **smart-commit** | Commit semântico + changelog | Ao finalizar tarefa |
| **pr-review** | Review automático de PR | Antes de merge |
| **release-notes** | Gerar release notes | Ao taggear versão |

### 3. Code Quality

| Skill | Propósito | Trigger |
|-------|-----------|---------|
| **security-scan** | Scan de vulnerabilidades | Antes de prod |
| **test-coverage** | Validar coverage > 80% | Em PRs |
| **lint-fix** | Auto-fix de linters | Ao commitar |

---

## 🚨 Problemas Comuns

### 1. Skill Não Carrega

**Sintoma**: `/skill-name` retorna "skill not found"

**Diagnóstico**:
```bash
# Verificar se SKILL.md existe
ls -la .claude/skills/<nome>/SKILL.md

# Validar frontmatter
cat .claude/skills/<nome>/SKILL.md | head -10
```

**Solução**:
- Garantir arquivo named `SKILL.md` (maiúsculas)
- Verificar sintaxe do frontmatter (YAML válido)
- Reiniciar Claude Code CLI

### 2. Contexto Muito Grande

**Sintoma**: Skill carrega mas contexto explode

**Causa**: Skill muito grande ou muitas referências

**Solução**:
- Dividir skill em múltiplos menores
- Mover referências para memórias Serena
- Usar `max_chars` para limitar tamanho

### 3. Skills em Conflito

**Sintoma**: Dois skills fazem a mesma coisa

**Solução**:
- Manter apenas um (o mais completo)
- Ou especializar (um para dev, outro para prod)

---

## 💡 Best Practices

### 1. Nomes Descritivos e Curtos

**❌ Ruim**: `skill-para-fazer-deploy-de-aplicacao-no-coolify`
**✅ Bom**: `coolify-deploy`

### 2. Uma Responsabilidade por Skill

**❌ Ruim**: Skill que faz deploy + monitor + alertas
**✅ Bom**: `coolify-deploy`, `monitor-setup`, `alert-configure`

### 3. Frontmatter Completo

```yaml
---
name: coolify-deploy
description: Deploy zero-downtime via Coolify com rollback automático
version: 1.0.0
author: arturdr
tags: [devops, coolify, deploy, zero-downtime]
disable-model-invocation: false
depends: [coolify-cli, jq]
---
```

### 4. Exemplos de Uso

Sempre incluir seção de exemplos:

```markdown
## Exemplos

### Deploy Simples
```
/coolify-deploy
App: myapp
Env: production
```

### Deploy com Rollback
```
/coolify-deploy --rollback-enabled
App: myapp
Env: production
Max retries: 3
```
```

---

## 🎯 Matriz de Decisão: Skill vs Agent vs Plugin

| Precisa de... | Use | Exemplo |
|---------------|-----|---------|
| Workflow simples, recorrente | **Skill** | Formatar commits |
| Workflow complexo, multi-step | **Skill** | Deploy completo |
| Tarefa autônoma, paralela | **Agent** | Revisar 10 PRs |
| Integração externa persistente | **Plugin** | GitHub MCP wrapper |
| Compartilhar com time | **Plugin** | Skills do time |
| Persistir跨-sessões | **Serena Memory** | Regras de ouro |

---

## 🔧 Validação de Skills

### Checklist Antes de Commitar

- [ ] Frontmatter válido (YAML)
- [ ] Descrição clara e concisa
- [ ] Exemplos de uso
- [ ] Testado manualmente
- [ ] Sem conflito com outros skills
- [ ] Documentado em MEMORY.md (se for importante)

### Teste de Skill

```bash
# 1. Listar skills
/skills

# 2. Executar skill
/nome-skill

# 3. Verificar resultado
# Funcionou como esperado?
```

---

## 📚 Skills Recomendadas (Seu Stack DevOps)

### Essenciais

```
.claude/skills/
├── devops/
│   ├── coolify-deploy/
│   ├── tf-plan/
│   ├── oci-provision/
│   └── monitor-alert/
├── git/
│   ├── smart-commit/
│   └── pr-review/
└── quality/
    ├── security-scan/
    └── test-coverage/
```

### Opcionais

```
├── docs/
│   └── generate-changelog/
└── utils/
    ├── env-validator/
    └── secrets-rotator/
```

---

## 🔧 Troubleshooting

### Skill Executa Mas Não Faz Nada

**Causa**: `disable-model-invocation: true` sem comandos executáveis

**Solução**: Remover flag ou adicionar comandos bash

### Skill Trava CLI

**Causa**: Loop infinito ou comando muito lento

**Solução**: Adicionar timeout ou breakpoint
```bash
timeout 30s comando-lento || true
```

### Skill com Erro de YAML

**Causa**: Frontmatter mal formatado

**Solução**: Validar YAML
```bash
yq eval .claude/skills/<nome>/SKILL.md
```

---

## 📚 Referências

- **Superpowers Skills**: `~/.claude/plugins/cache/.../superpowers/.../skills/`
- **Skill Docs**: `~/.claude/plugins/.../plugin-dev/skills/skill-development/SKILL.md`
- **Seus Skills**: `~/.claude/skills/`

---

**REGRA DE OURO**: Skills sob demanda, uma responsabilidade, sempre testadas antes de commitar.
