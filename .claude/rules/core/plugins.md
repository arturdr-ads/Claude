# 🔌 Regras de Ouro - Plugins

**Versão**: 1.0.0
**Atualizado**: 2026-03-23
**Status**: Production

---

## 🎯 Regra #1: Plugins Agrupam Funcionalidades Relacionadas

**Plugin = Skills + MCPs + Hooks + Configs** (tudo num pacote)

### ✅ Quando Criar Plugins

- **Compartilhar com time**: Skills que outros desenvolvedores usam
- **Integração complexa**: Requer MCP + skills + hooks
- **Distribuição pública**: Publicar no marketplace
- **Configuração reutilizável: Ambientes repeatáveis

### ❌ Quando NÃO Criar Plugins

- **Uso pessoal**: Skills pessoais → `.claude/skills/`
- **Simples demais**: Uma skill isolada não precisa de plugin
- **One-off**: Coisas que não serão reutilizadas

---

## 📁 Estrutura de Plugins

```
<plugin-name>/
├── .claude-plugin/
│   └── plugin.json          # Manifesto obrigatório
├── skills/                   # Skills do plugin
│   └── <nome>/
│       └── SKILL.md
├── .mcp.json                 # Config MCP (opcional)
├── README.md                 # Documentação
└── package.json              # NPM package (opcional)
```

### plugin.json (Manifesto)

```json
{
  "name": "local-devops",
  "description": "DevOps skills for OCI, Terraform, Docker, and Coolify workflows",
  "version": "1.0.0",
  "author": {
    "name": "arturdr",
    "email": "arturdr@users.noreply.github.com"
  },
  "homepage": "https://github.com/arturdr/local-devops",
  "repository": "https://github.com/arturdr/local-devops",
  "license": "MIT",
  "keywords": ["devops", "oci", "terraform", "docker", "coolify", "oke", "ocir"],
  "mcpServers": {},
  "hooks": {}
}
```

---

## 📋 Comandos de Plugins

```bash
# Listar plugins instalados
claude plugin list

# Instalar plugin do marketplace
claude plugin install <nome>

# Instalar plugin local
claude plugin install --local /caminho/plugin

# Recarregar plugins
/reload-plugins

# Desabilitar plugin
claude plugin disable <nome>

# Habilitar plugin
claude plugin enable <nome>
```

---

## 💡 Categorias de Plugins

### 1. Oficiais Claude Code

| Plugin | Propósito | Skills |
|--------|-----------|--------|
| **superpowers** | Framework de desenvolvimento | brainstorming, TDD, debugging, etc. |
| **feature-dev** | Desenvolvimento de features | code-architect, code-explorer |
| **github** | Integração GitHub | PR reviews, issues |
| **serena** | Análise simbólica de código | Symbolic tools |
| **frontend-design** | Design frontend | Componentes UI |
| **context7** | Documentação de bibliotecas | Doc queries |

### 2. Locais (Seu caso)

| Plugin | Status | Skills | Problema |
|--------|--------|--------|----------|
| **local-devops** | ⚠️ Falhou | 6 skills | Falta package.json |

### 3. Marketplace

| Plugin | Propósito | Avaliação |
|--------|-----------|-----------|
| **hookify** | Gerenciar hooks com segurança | ⭐⭐⭐⭐⭐ |
| **stripe** | Integração Stripe | ⭐⭐⭐⭐ |
| **openai** | Integração OpenAI | ⭐⭐⭐⭐ |

---

## 🚨 Problemas Comuns

### 1. Plugin Não Carrega

**Sintoma**: `✘ failed to load` em `claude plugin list`

**Diagnóstico**:
```bash
# Verificar estrutura
ls -la ~/.claude/plugins/<nome>/

# Verificar plugin.json
cat ~/.claude/plugins/<nome>/.claude-plugin/plugin.json

# Ver logs
claude plugin logs <nome>
```

**Solução**:
- Garantir `.claude-plugin/plugin.json` existe
- Validar JSON do manifesto
- Verificar dependências

### 2. Skills do Plugin Não Aparecem

**Sintoma**: Plugin carrega mas skills não listam

**Causa**: Skills fora da estrutura esperada

**Solução**:
```bash
# Estrutura correta
<plugin>/
└── skills/
    └── <nome>/
        └── SKILL.md
```

### 3. package.json Faltando

**Sintoma**: `Plugin not found in marketplace local`

**Causa**: Plugin local sem package.json na raiz

**Solução**:
```bash
cd ~/.claude/plugins/<nome>/
npm init -y
# ou criar package.json manualmente
```

---

## 💡 Best Practices

### 1. Um Propósito por Plugin

**❌ Ruim**: Plugin "everything" com 50 skills desconexas
**✅ Bom**: Plugin "devops-oci" focado em OCI/Terraform

### 2. Manifesto Completo

```json
{
  "name": "devops-oci",
  "description": "OCI/Terraform DevOps automation skills",
  "version": "1.0.0",
  "author": {"name": "arturdr"},
  "keywords": ["devops", "oci", "terraform", "oke"],
  "homepage": "https://github.com/arturdr/devops-oci",
  "repository": "https://github.com/arturdr/devops-oci",
  "license": "MIT"
}
```

### 3. README.md Descritivo

```markdown
# DevOps OCI Plugin

## Skills

- **tf-plan**: Terraform plan validation
- **oci-provision**: OCI resource provisioning
- **coolify-deploy**: Coolify zero-downtime deployment

## Installation

```bash
claude plugin install --local /path/to/plugin
```

## Usage

```
/tf-plan
Directory: terraform/oci/production
```
```

### 4. Versionamento Semântico

- **1.0.0** → Primeira versão estável
- **1.1.0** → Novas features (backwards compatible)
- **1.0.1** → Bug fixes
- **2.0.0** → Breaking changes

---

## 🎯 Matriz de Decisão: Plugin vs Skill vs Agent

| Precisa de... | Use | Exemplo |
|---------------|-----|---------|
| Workflow simples pessoal | **Skill** | Formatar meus commits |
| Compartilhar com time | **Plugin** | Skills do time DevOps |
| Distribuir publicamente | **Plugin** | Hookify no marketplace |
| Tarefa autônoma paralela | **Agent** | Revisar 10 PRs |
| Integração externa complexa | **Plugin** | GitHub + Serena + hooks |
| Uso interno rápido | **Skill** | One-off automation |

---

## 🔧 Validação de Plugins

### Checklist Antes de Publicar

- [ ] `plugin.json` válido e completo
- [ ] README.md descritivo com exemplos
- [ ] Skills testadas individualmente
- [ ] package.json (se for NPM package)
- [ ] Licença definida
- [ ] Keywords para busca
- [ ] Homepage e repository

### Teste de Plugin

```bash
# 1. Instalar plugin
claude plugin install --local /caminho/plugin

# 2. Verificar status
claude plugin list

# 3. Listar skills
/skills

# 4. Executar skill
/<nome-skill>

# 5. Desinstalar
claude plugin uninstall <nome>
```

---

## 📚 Plugin Template

### Estrutura Mínima

```
my-plugin/
├── .claude-plugin/
│   └── plugin.json
├── skills/
│   └── my-skill/
│       └── SKILL.md
└── README.md
```

### plugin.json

```json
{
  "name": "my-plugin",
  "description": "My awesome plugin",
  "version": "1.0.0",
  "author": {"name": "Your Name"},
  "keywords": ["keyword1", "keyword2"],
  "license": "MIT"
}
```

### SKILL.md

```markdown
---
name: my-skill
description: My awesome skill
version: 1.0.0
---

# My Skill

## Description

Does something awesome.

## Usage

```
/my-skill
```
```

---

## 🚀 Publicando no Marketplace

### 1. Preparar Repositório

```bash
git init
git add .
git commit -m "feat: initial plugin release"
```

### 2. Publicar no GitHub

```bash
gh repo create my-plugin --public --source=.
git push -u origin main
```

### 3. Adicionar ao Marketplace

```bash
# Via PR no repo claude-plugins-official
# Ou via marketplace próprio
```

### 4. Validar

```bash
claude plugin install <username>/<my-plugin>
```

---

## 🔧 Troubleshooting

### Plugin com Erro de JSON

**Causa**: plugin.json mal formatado

**Solução**: Validar JSON
```bash
jq . ~/.claude/plugins/<nome>/.claude-plugin/plugin.json
```

### Plugin Skills Não Executam

**Causa**: Skills fora do diretório esperado

**Solução**: Mover para estrutura correta
```bash
mv skills/<skill> ~/.claude/plugins/<nome>/skills/<skill>/
```

### Plugin Conflica com Outro

**Causa**: Dois plugins com skills mesmo nome

**Solução**: Renomear skills ou desabilitar um
```bash
claude plugin disable <nome-conflitante>
```

---

## 📚 Referências

- **Plugin Dev**: `~/.claude/plugins/.../plugin-dev/skills/`
- **Marketplace**: https://github.com/anthropics/claude-plugins-official
- **Seus Plugins**: `~/.claude/plugins/`

---

**REGRA DE OURO**: Plugins agrupam funcionalidades relacionadas; um propósito por plugin; manifesto completo antes de publicar.
