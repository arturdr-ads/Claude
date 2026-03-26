# 💻 Workflow: Programar Features

**Versão**: 1.0.0
**Atualizado**: 2026-03-23

---

## 📋 Overview

Workflow completo para desenvolvimento de features, desde a ideia até o deploy, seguindo TDD e code review.

---

## 🎯 Fase 1: Ideia e Brainstorming

### 1.1 Capturar Ideia

```bash
# Usar brainstorming skill
/skill brainstorming

# Definir feature
- O que fazer?
- Por que fazer?
- Como medir sucesso?
```

### 1.2 Especificar Requisitos

- **Funcionalidades**: O que o sistema deve fazer?
- **Não-funcionais**: Performance, segurança, usabilidade
- **Constraints**: Tempo, recursos, tecnologia

---

## 📐 Fase 2: Design e Spec

### 2.1 Criar Design Document

```bash
# Usar writing-plans skill
/skill writing-plans

# Criar spec
docs/superpowers/specs/YYYY-MM-DD-<feature>-design.md
```

### 2.2 Conteúdo do Spec

```markdown
# Feature: [Nome]

## Resumo
[2-3 linhas]

## Requisitos Funcionais
- RF1: [Descrição]
- RF2: [Descrição]

## Requisitos Não-Funcionais
- Performance: [Tempo de resposta]
- Segurança: [Requisitos]
- Usabilidade: [Critérios]

## Arquitetura
[Diagramas ou descrição]

## Casos de Uso
[Exemplos de uso]

## Critérios de Aceite
- [ ] [Critério 1]
- [ ] [Critério 2]
```

### 2.3 Review do Spec

```bash
# Usar spec-reviewer subagent
/agent spec-reviewer --spec docs/.../design.md

# Corrigir issues
# Re-dispatch até approved
```

---

## 🧪 Fase 3: TDD - Test Driven Development

### 3.1 Usar superpowers:test-driven-development

```bash
/skill test-driven-development

# Ciclo TDD:
# 1. VERMELHO: Escrever teste que falha
# 2. VERDE: Escrever código mínimo para passar
# 3. REFACTOR: Melhorar código mantendo testes verdes
```

### 3.2 Escrever Testes Primeiro

```python
# Exemplo: test_feature.py
def test_nova_funcionalidade():
    """Testa feature X funciona corretamente"""
    result = nova_funcionalidade(input)
    assert result == expected

def test_edge_cases():
    """Testa casos extremos"""
    assert nova_funcionalidade(None) == default
    assert nova_funcionalidade("") == empty_result
```

### 3.3 Executar Testes

```bash
# Rodar testes e ver falhar
pytest tests/test_feature.py -v  # Deve falhar (VERMELHO)

# Implementar código mínimo
# Rodar novamente e ver passar (VERDE)

# Refatorar e manter testes verdes (REFACTOR)
```

---

## 🔨 Fase 4: Implementação

### 4.1 Seguir Plano

```bash
/skill executing-plans

# Executar tarefas em ordem
- Criar arquivos
- Implementar funções
- Adicionar testes
```

### 4.2 Usar Serena para Navegação

```bash
# Encontrar símbolos
/serena find_symbol --name-path "FeatureName" --relative-path "src/"

# Encontrar referências
/serena find_referencing_symbols --name-path "functionName" --relative_path "src/feature.py"
```

### 4.3 Edição Simbólica

```bash
# Editar corpo de função
/serena replace_symbol_body \
  --name-path "FeatureName/methodName" \
  --relative-path "src/feature.py" \
  --body "[novo código]"
```

---

## ✅ Fase 5: Testes e Validação

### 5.1 Testes Unitários

```bash
# Rodar suite de testes
pytest tests/ -v --cov=src

# Verificar coverage > 80%
pytest tests/ --cov=src --cov-report=html
```

### 5.2 Testes de Integração

```bash
# Testar integração com outros componentes
pytest tests/integration/ -v
```

### 5.3 Testes E2E

```bash
# Testar fluxo completo
pytest tests/e2e/ -v
```

### 5.4 Verificação Antes de Completar

```bash
# Usar verification-before-completion
/skill verification-before-completion

# Checklist:
- [ ] Todos testes passam
- [ ] Coverage > 80%
- [ ] Code review feito
- [ ] Documentação atualizada
- [ ] Changelog atualizado
```

---

## 👁️ Fase 6: Code Review

### 6.1 Self-Review

```bash
# Usar code-reviewer skill
/skill code-reviewer

# Revisar próprio código
- Busca bugs
- Verifica code smells
- Sugere melhorias
```

### 6.2 Criar Pull Request

```bash
# Usar superpowers:finishing-a-development-branch
/skill finishing-a-development-branch

# Criar PR
gh pr create \
  --title "feat: implement feature X" \
  --body "$(cat docs/.../design.md | sed '1,/## Resumo/d')"
```

### 6.3 Code Review Automático

```bash
# Usar GitHub MCP + Serena
/agent pr-reviewer --pr-number 123

# Agent analisa:
- Mudanças no código
- Impacto em outros componentes
- Possíveis bugs
- Sugestões de melhoria
```

---

## 🚀 Fase 7: Deploy

### 7.1 Deploy para Staging

```bash
# Usar skill de deploy
/deploy-app \
  --app myapp \
  --env staging \
  --rollback-enabled
```

### 7.2 Testes em Staging

```bash
# Rodar testes E2E em staging
pytest tests/e2e/ --env=staging

# Testes manuais
# [Checklist de validação]
```

### 7.3 Deploy para Produção

```bash
# Deploy zero-downtime
/deploy-app \
  --app myapp \
  --env production \
  --rollback-enabled \
  --max-retries 3
```

### 7.4 Monitoramento

```bash
# Verificar logs
/agent sre-engineer --action check-logs --app myapp

# Verificar métricas
/agent sre-engineer --action check-metrics --app myapp

# Verificar alertas
/agent sre-engineer --action check-alerts --app myapp
```

---

## 🔄 Fase 8: Pós-Deploy

### 8.1 Verificar Saúde do Sistema

```bash
# Health checks
curl https://myapp.example.com/health

# Métricas de negócio
# [Verificar KPIs]
```

### 8.2 Monitoramento por 24h

```bash
# Agent SRE monitora
/agent sre-engineer --action monitor --duration 24h --app myapp
```

### 8.3 Rollback se Necessário

```bash
# Rollback automático se SLOs violados
/rollback \
  --app myapp \
  --env production \
  --reason "error-rate > 1%"
```

---

## 📚 Referências

- **TDD**: .claude/rules/core/skills.md → test-driven-development
- **Code Review**: .claude/rules/core/agents.md → pr-reviewer
- **Deploy**: .claude/rules/workflows/deploy.md
- **Monitoring**: .claude/rules/devops/monitoramento.md

---

## 💡 Checklist Completo

### Pré-Coding
- [ ] Brainstorming feito
- [ ] Spec escrito e aprovado
- [ ] Testes planejados

### Coding
- [ ] TDD seguido (V-E-R)
- [ ] Serena usado para navegação
- [ ] Edição simbólica aplicada

### Testing
- [ ] Testes unitários passando
- [ ] Testes de integração passando
- [ ] Testes E2E passando
- [ ] Coverage > 80%

### Review
- [ ] Self-review feito
- [ ] PR criado
- [ ] Code review automático feito
- [ ] Issues corrigidas

### Deploy
- [ ] Deploy staging feito
- [ ] Testes staging passando
- [ ] Deploy production feito
- [ ] Monitoramento ativo por 24h

---

**Próximo workflow**: `revisar.md` → Como fazer code review eficaz
