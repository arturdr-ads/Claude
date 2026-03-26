# 🪝 Regras de Ouro - Hooks

**Versão**: 1.0.0
**Atualizado**: 2026-03-23
**Status**: Production

---

## 🎯 Regra #1: Hookify é OBRIGATÓRIO

**SEMPRE use Hookify para gerenciar hooks.**

### ✅ Quando usar Hookify
- Criar novos hooks
- Modificar hooks existentes
- Remover hooks
- Validar configuração
- Troubleshooting

### ❌ Quando NÃO usar edição manual
- **NUNCA** edite `.claude/settings.json` manualmente para hooks
- **NUNCA** crie hooks via JSON direto
- **NUNCA** modifique hooks sem Hookify

---

## 🔧 Hooks Essenciais para DevOps

### 1. PostToolUse (Formatação Automática)

**Propósito**: Auto-formatar arquivos após Edit/Write

```yaml
Matcher: Edit|Write
Ação:
  - *.tf, *.tfvars → terraform fmt -diff=false
  - *.yml, *.yaml, Dockerfile → yq --prettyPrint -i
  - git add (adicionar arquivo modificado)
Timeout: 3s (previne travamento)
```

### 2. SessionStart (Startup)

**Propósito**: Mostrar status ao iniciar sessão

```yaml
Matcher: .*
Ação:
  - Exibir modo Auto-Pilot DevOps
  - Mostrar git diff recente (5 commits)
  - Listar MCPs ativos
```

### 3. PreToolUse (Segurança)

**Propósito**: Alertas antes de ações perigosas

```yaml
Matcher: Bash(git push.*main)
Ação: Alertar sobre push para branch principal

Matcher: Bash(rm -rf.*)
Ação: Bloquear com Hookify block-dangerous-commands
```

---

## 📋 Comandos Hookify

### Listar hooks
```bash
/hookify list
```

### Adicionar hook
```bash
/hookify add PostToolUse \
  --matcher "Edit|Write" \
  --file-pattern "*.tf,*.tfvars" \
  --command "timeout 3s terraform fmt -diff=false \"$FILE\""
```

### Remover hook
```bash
/hookify remove PostToolUse --index 0
```

### Validar hooks
```bash
/hookify validate
```

---

## 🚨 Problemas de Edição Manual

| Problema | Impacto | Hookify Resolve |
|----------|---------|-----------------|
| Sintaxe inválida | CLI quebra | ✅ Validação automática |
| Matchers incorretos | Falha silenciosa | ✅ Regex testado |
| Performance ruim | CLI trava (5-10s) | ✅ Timeouts otimizados |
| Segurança falha | Comandos perigosos | ✅ Blocklist ativa |
| Debug impossível | Não há logs | ✅ Logs estruturados |

---

## 💡 Exemplos Práticos

### Terraform + YAML Format
```bash
# Hook único para Terraform
/hookify add PostToolUse \
  --matcher "Edit|Write" \
  --file-pattern "*.tf,*.tfvars" \
  --command "timeout 3s terraform fmt -diff=false \"$FILE\" && git add \"$FILE\""

# Hook para YAML
/hookify add PostToolUse \
  --matcher "Edit|Write" \
  --file-pattern "*.yml,*.yaml,Dockerfile" \
  --command "timeout 3s yq --prettyPrint -i \"$FILE\" 2>/dev/null; git add \"$FILE\""
```

### Alerta de Push para Main
```bash
/hookify add PreToolUse \
  --matcher "Bash(git push.*main)" \
  --command "echo '⚠️ Você está fazendo push para branch main!'"
```

---

## 🎯 Checklist de Validação

Antes de commitar mudanças de hooks:

- [ ] Usei Hookify para criar/modificar?
- [ ] Validei com `/hookify validate`?
- [ ] Testei com arquivos de exemplo?
- [ ] Verifiquei performance (< 3s)?
- [ ] Documentei em CLAUDE.md ou MEMORY.md?
- [ ] Salvei regra no Serena (`hookify_mandatory_rules`)?

---

## 🔧 Troubleshooting

### Hooks não estão executando?
```bash
# Verificar se hooks estão ativos
cat ~/.claude/settings.json | jq '.hooks.PostToolUse'

# Validar com Hookify
/hookify validate
```

### CLI travando após Edit/Write?
```bash
# Provável causa: Hook sem timeout ou comando lento
# Solução: Adicionar timeout 3s ou remover hook
/hookify list
/hookify remove PostToolUse --index <problema>
```

### Formatação não happening?
```bash
# Verificar se matcher está correto
# Deve ser: "Edit|Write" (não "Edit" ou "Write" separados)
/hookify validate
```

---

## 📚 Referências

- **Hookify Plugin**: `~/.claude/plugins/marketplaces/claude-plugins-official/plugins/hookify/`
- **Serena Memory**: `hookify_mandatory_rules`
- **Spec**: `docs/superpowers/specs/2026-03-19-claude-code-cli-hooks-design.md`

---

**REGRA DE OURO**: Se envolve hooks → Hookify OBRIGATÓRIO!

**Exceção**: Nenhuma. Sempre Hookify. Sempre.
