# 🔌 Regras de Ouro - MCP Servers

**Versão**: 1.0.0
**Atualizado**: 2026-03-23
**Status**: Production

---

## 🎯 Regra #1: Limite de 5-7 MCPs Ativos

**Muitos MCPs = token bloat + lentidão**

### Stack Recomendada (Produção)

| MCP | Propósito | Prioridade |
|-----|-----------|------------|
| **Serena** | Análise simbólica de código | 🔴 Crítico |
| **GitHub** | PRs, issues, reviews | 🔴 Crítico |
| **Context7** | Documentação de libs | 🟡 Útil |
| **EXA** | Busca semântica código/docs | 🟡 Útil |
| **Tavily** | Busca web real-time | 🟢 Opcional |

**Total**: 5 MCPs (equilíbrio perfeito)

---

## 📋 Validação de MCPs

### Comandos Essenciais

```bash
# Listar todos MCPs
claude mcp list

# Validar saúde dos MCPs
claude mcp validate

# Ver detalhes de um MCP
claude mcp inspect <nome>
```

### Checklist de Validação

- [ ] Todos MCPs mostram "✓ Connected"
- [ ] Sem erros de timeout
- [ ] Tools expostas corretamente
- [ ] Contexto apropriado (desktop-app vs claude-code)

---

## 🔧 Configuração por Contexto

### Contexto: `claude-code` (Recomendado para CLI)

**Benefícios**: Remove duplicações com tools nativas do Claude Code

```json
// ~/.claude/plugins/serena/.mcp.json
{
  "context": "claude-code",
  "disabledTools": ["read_file", "execute_shell_command"]
}
```

**Tools Removidas** (CLI já tem):
- `read_file` → Use Read tool nativo
- `execute_shell_command` → Use Bash tool nativo
- `write_file` → Use Write tool nativo

### Contexto: `desktop-app` (Para IDEs)

**Benefícios**: Todas tools disponíveis, integração completa

```json
{
  "context": "desktop-app"
}
```

---

## 🚨 Problemas Comuns

### 1. MCP Não Conecta

**Sintoma**: `✗ Failed to connect` ou `✗ Timeout`

**Diagnóstico**:
```bash
# Verificar se MCP está instalado
which uvx npx

# Testar MCP manualmente
uvx --from git+https://github.com/oraios/serena serena start-mcp-server --help

# Ver logs
claude mcp logs <nome>
```

**Solução**:
- Reinstalar MCP: `claude mcp install <nome>`
- Verificar API keys em ENV vars
- Aumentar timeout em settings.json

### 2. Tools Não Expostas

**Sintoma**: MCP conecta mas tools não aparecem

**Causa**: Contexto errado ou versão incompatível

**Solução**:
```bash
# Verificar contexto
cat ~/.claude/plugins/<mcp>/.mcp.json | jq '.context'

# Testar com contexto desktop-app (todas tools)
# Se funcionar, problema é contexto claude-code
```

### 3. Token Bloat

**Sintoma**: Contexto explodindo (>50K tokens)

**Diagnóstico**:
```bash
# Verificar tamanho dos contextos MCP
claude mcp inspect --verbose
```

**Solução**:
- Desativar MCPs não essenciais
- Usar contexto claude-code (remove duplicações)
- Limitar ferramentas expostas por MCP

---

## 💡 Best Practices

### 1. Um MCP por Propósito

**❌ Ruim**: 3 MCPs de busca (EXA, Tavily, Perplexity)
**✅ Bom**: EXA (código) + Tavily (web)

### 2. Configuração Local, Não Global

**❌ Ruim**: Configurar MCPs em `~/.claude/settings.json`
**✅ Bom**: Configurar em `.claude/.mcp.json` por projeto

### 3. Validação Contínua

**Antes de sessão crítica**:
```bash
claude mcp list && claude mcp validate
```

### 4. Documentação de Integração

Para cada MCP, documente:
- Propósito e casos de uso
- Comandos de validação
- Troubleshooting comum

---

## 🎯 Stack DevOps Recomendada

```
Serena (claude-code)
├─ find_symbol: Navegação simbólica
├─ find_references: Impact analysis
├─ replace_symbol_body: Refactoring preciso
└─ memories: Persistência cross-sessão

GitHub (HTTP)
├─ pull_request_read: Revisão de PRs
├─ issue_read: Triagem de issues
├─ create_commit: Commits semânticos
└─ get_file_contents: Leitura remota

Context7
└─ query-docs: Documentação atualizada

EXA
└─ get_code_context: Busca semântica código

Tavily
├─ tavily_search: Notícias, updates
└─ tavily_research: Pesquisa profunda
```

---

## 📊 Matriz de Decisão

| Precisa de... | Use MCP | Alternativa |
|---------------|---------|-------------|
| Análise simbólica código | **Serena** | Grep (limitado) |
| Integração GitHub | **GitHub MCP** | gh CLI (manual) |
| Documentação libs | **Context7** | Google (lento) |
| Busca código | **EXA** | GitHub search |
| Notícias tempo real | **Tavily** | (sem equivalente) |
| Executar shell | ❌ Não usar MCP | Bash nativo |
| Ler arquivos | ❌ Não usar MCP | Read nativo |

---

## 🔧 Troubleshooting Avançado

### MCP Trava CLI

```bash
# 1. Identificar MCP problemático
claude mcp list --verbose

# 2. Desativar temporariamente
claude mcp disable <nome>

# 3. Reativar após fix
claude mcp enable <nome>
```

### Serena com 2 Contextos

**Você tem**: Serena em `desktop-app` + `claude-code`

**Resultado**: 6 ferramentas Serena duplicadas

**Solução**: Manter apenas `claude-code`
```bash
# Remover versão desktop-app
claude mcp disable serena-desktop

# Ou editar .mcp.json
vim ~/.claude/plugins/serena/.mcp.json
```

---

## 📚 Referências

- **Spec MCP**: https://modelcontextprotocol.io/
- **Serena Docs**: https://github.com/oraios/serena
- **Claude Code MCPs**: https://claude.ai/mcp-integrations

---

**REGRA DE OURO**: 5-7 MCPs ativos, contexto claude-code, validação contínua.
