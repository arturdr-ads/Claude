# 🚀 Workflow: Criar Sistema do Zero

**Versão**: 1.0.0
**Atualizado**: 2026-03-23

---

## 📋 Overview

Este workflow define como criar um novo sistema Claude Code CLI do zero, seguindo as regras de ouro estabelecidas.

---

## 🎯 Fase 1: Planejamento (Brainstorming)

### 1.1 Usar superpowers:brainstorming

```bash
# Entrar em modo brainstorming
/skill brainstorming

# Definir requisitos do sistema
- Público-alvo (interno, time, open source)
- Stack tecnologica (MCPs, plugins)
- Escopo (DevOps, web, mobile, etc.)
```

### 1.2 Responder Perguntas Chave

- **Objetivo principal**: Qual problema o sistema resolve?
- **Público-alvo**: Quem vai usar?
- **Stack MCP**: Quais MCPs são necessários? (limite: 5-7)
- **Plugins**: Plugins oficiais ou customizados?
- **Skills**: Quais workflows recorrentes?
- **Agents**: Quais tarefas autônomas?

### 1.3 Aprovação do Design

- Apresentar design em seções
- Obter aprovação após cada seção
- Escrever spec document

---

## 🔧 Fase 2: Configuração Base

### 2.1 Criar Estrutura de Diretórios

```bash
# Estrutura matriz 2D
mkdir -p .claude/rules/{core,workflows,devops}
mkdir -p .claude/skills
mkdir -p .claude/agents
mkdir -p scripts
```

### 2.2 Configurar Hooks (OBRIGATÓRIO: Hookify)

```bash
# Adicionar hook de formatação Terraform
/hookify add PostToolUse \
  --matcher "Edit|Write" \
  --file-pattern "*.tf,*.tfvars" \
  --command "timeout 3s terraform fmt -diff=false \"$FILE\" && git add \"$FILE\""

# Adicionar hook de formatação YAML
/hookify add PostToolUse \
  --matcher "Edit|Write" \
  --file-pattern "*.yml,*.yaml,Dockerfile" \
  --command "timeout 3s yq --prettyPrint -i \"$FILE\" 2>/dev/null; git add \"$FILE\""

# Validar hooks
/hookify validate
```

### 2.3 Configurar MCPs

```bash
# Lista de MCPs recomendados
claude mcp list

# Instalar MCPs necessários
claude mcp install serena
claude mcp install github
claude mcp install context7
claude mcp install exa
claude mcp install tavily

# Validar MCPs
claude mcp validate
```

---

## 📝 Fase 3: Documentação

### 3.1 Criar CLAUDE.md

```markdown
# Projeto - Claude Code CLI

## Visão Geral
[Descrição do projeto]

## Stack Tecnologica
- **MCPs**: Serena, GitHub, Context7, EXA, Tavily
- **Plugins**: superpowers, feature-dev, github, serena

## Regras de Ouro
1. Hooks: SEMPRE usar Hookify
2. MCPs: Máximo 5-7 ativos
3. Skills: Sob demanda, bem testadas

## Workflows
- Criar sistema: .claude/rules/workflows/criar-sistema.md
- Programar: .claude/rules/workflows/programar.md
- Deploy: .claude/rules/workflows/deploy.md
```

### 3.2 Criar MEMORY.md

```markdown
# Memória do Projeto

**Última atualização**: [DATA]

## Regras de Ouro
[Resumo das regras principais]

## Histórico de Problemas Resolvidos
[Documentar bugs e soluções]

## Comandos Frequentes
[Comandos úteis do dia a dia]
```

### 3.3 Criar Regras Core

```bash
# Copiar templates de regras
cp -r ~/.claude/rules/core/* .claude/rules/core/

# Customizar para o projeto
vim .claude/rules/core/mcps.md
vim .claude/rules/core/hooks.md
```

---

## 🎯 Fase 4: Skills & Agents

### 4.1 Criar Skills Essenciais

```bash
# Exemplo: Skill de deploy
mkdir -p .claude/skills/deploy-app
cat > .claude/skills/deploy-app/SKILL.md << 'EOF'
---
name: deploy-app
description: Deploy zero-downtime da aplicação
version: 1.0.0
author: arturdr
disable-model-invocation: false
---

# Deploy App

## Descrição
Realiza deploy zero-downtime via Coolify com rollback automático.

## Uso
```
/deploy-app
App: myapp
Env: production
```
EOF
```

### 4.2 Criar Agents Especializados

```bash
# Exemplo: Agent de IaC
mkdir -p .claude/agents
cat > .claude/agents/iac-engineer.md << 'EOF'
---
name: iac-engineer
description: Valida planos Terraform/Pulumi
version: 1.0.0
author: arturdr
tools: [Read, Bash, Glob]
max_iterations: 10
timeout: 300
---

# IaC Engineer

## Role
Engenheiro de IaC especializado em Terraform e Pulumi.

## Responsabilidades
1. Validar planos antes de apply
2. Verificar drift de infraestrutura
3. Analisar configurações de segurança

## Restrições
- NUNCA fazer apply sem aprovação
- Sempre mostrar diff completo
EOF
```

---

## ✅ Fase 5: Validação

### 5.1 Checklist de Validação

- [ ] Hooks configurados com Hookify
- [ ] MCPs validados (5-7 ativos)
- [ ] CLAUDE.md criado
- [ ] MEMORY.md criado
- [ ] Regras core criadas
- [ ] Skills testadas
- [ ] Agents testados
- [ ] Serena memories criadas

### 5.2 Teste End-to-End

```bash
# Testar hooks
echo "test: true" > test.yml
# Deve formatar automaticamente

# Testar MCPs
claude mcp list
claude mcp validate

# Testar skills
/skills
/deploy-app --dry-run

# Testar agents
/agents
/agent iac-engineer --test
```

### 5.3 Salvar no Serena

```bash
# Usar Serena para persistir regras
/serena write_memory --memory-name system_rules --content "..."
```

---

## 🚀 Fase 6: Primeira Feature

### 6.1 Usar superpowers:writing-plans

```bash
/skill writing-plans

# Criar plano de implementação
- Feature: [Nome da feature]
- Arquivos: [Lista de arquivos]
- Testes: [Lista de testes]
```

### 6.2 Executar Plano

```bash
/skill executing-plans

# Seguir plano passo a passo
- Marcar tarefas como completas
- Testar cada componente
```

---

## 📚 Referências

- **Hooks**: .claude/rules/core/hooks.md
- **MCPs**: .claude/rules/core/mcps.md
- **Skills**: .claude/rules/core/skills.md
- **Agents**: .claude/rules/core/agents.md
- **Plugins**: .claude/rules/core/plugins.md

---

## 💡 Tips

1. **Comece simples**: Adicione complexidade gradualmente
2. **Teste tudo**: Valide cada componente antes de prosseguir
3. **Documente**: Mantenha CLAUDE.md e MEMORY.md atualizados
4. **Use Hookify**: NUNCA edite hooks manualmente
5. **Limite MCPs**: 5-7 MCPs é o sweet spot

---

**Próximo workflow**: `programar.md` → Como desenvolver features seguindo as regras
