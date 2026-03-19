# Controle de Invocação de Skills

## Referência Rápida

| Configuração | Usuário | Claude | Quando Usar |
|--------------|---------|--------|-------------|
| *(padrão)* | ✅ | ✅ | Skills gerais |
| `disable-model-invocation: true` | ✅ | ❌ | Operações com side effects |
| `user-invocable: false` | ❌ | ✅ | Background knowledge |

---

## disable-model-invocation: true

**Previne que Claude invoque a skill automaticamente.**

### Quando Usar

✅ **Operações com side effects irreversíveis:**
- Deploy em produção
- Deleção de recursos
- Envio de emails/notificações
- Modificação de banco de dados

✅ **Comandos que requerem julgamento humano:**
- Aprovação de mudanças
- Revisão de segurança
- Decisões de negócio

✅ **Skills pesadas:**
- Terraform plan/apply
- Testes completos (suite inteira)
- Build de containers

### Exemplo

```yaml
---
name: prod-deploy
description: Deploy to production environment
disable-model-invocation: true
---
```

**Resultado:** Só roda com `/prod-deploy`, nunca automaticamente.

---

## user-invocable: false

**Previne que o usuário invoque a skill manualmente.**

### Quando Usar

✅ **Conhecimento de background:**
- Convenções do projeto
- Padrões de arquitetura
- Estilos de código

✅ **Contexto automático:**
- Informações sobre o time
- Histórico de decisões
- Documentação de referência

### Exemplo

```yaml
---
name: project-conventions
description: Code style and patterns for this project
user-invocable: false
---
```

**Resultado:** Claude aplica automaticamente, usuário não vê.

---

## Skills Otimizadas (Seu Setup)

| Skill | Config | Motivo |
|-------|--------|--------|
| auto-deploy | `disable: true` | Deploy tem side effects |
| devops-oci | `disable: true` | Operações de infra |
| terraform-plan | `disable: true` | IaC é crítico |
| test-all | `disable: true` | Suite pesada |
| feedback-loop | *(padrão)* | Claude deve poder usar |
| mcp-health-check | *(padrão)* | Monitoramento pode ser auto |

---

## Economia de Tokens

```
Sem disable-model-invocation:
├── Descrição carregada na sessão
├── Conteúdo completo carregado "sob demanda"
└── Claude decide quando invocar

Com disable-model-invocation: true:
├── Descrição carregada na sessão
├── Conteúdo SÓ carrega com /comando explícito
└── Economia: skills pesadas não ocupam contexto
```

---

## Exemplos Práticos

### Skill de Deploy (Manual Only)

```yaml
---
name: deploy-production
description: Deploy application to production environment
argument-hint: [version] [environment]
disable-model-invocation: true
allowed-tools: Bash(kubectl:*), Bash(helm:*)
---

Deploy $1 to $2 environment following deployment runbook.
```

**Uso:** `/deploy-production v1.2.3 production`

### Skill de Convenções (Auto Only)

```yaml
---
name: react-conventions
description: React patterns and conventions for this project
user-invocable: false
---

## Component Structure
- Functional components with hooks
- Props interface with TypeScript
- Storybook stories for all components

## Naming
- Components: PascalCase
- Files: kebab-case
- Tests: `.spec.ts` suffix
```

**Uso:** Claude aplica automaticamente ao criar componentes.

---

## Frontmatter Completo

```yaml
---
name: my-skill
description: Brief description under 60 chars
version: 1.0.0
tags: [category, subcategory]
dependencies:
  - tool1
  - tool2
disable-model-invocation: true  # ← ou false, ou omita
user-invocable: false            # ← ou true, ou omita
allowed-tools: Read, Write, Bash(git:*)
model: sonnet                    # ← haiku, sonnet, opus
argument-hint: [arg1] [arg2]
---
```

---

## Boas Práticas

1. **Comece sem restrições** - Adicione conforme necessário
2. **Documente o motivo** - Por que desabilitou auto-invocação?
3. **Teste ambos os modos** - Manual e automático
4. **Monitore uso** - Skills desabilitadas são úteis?
5. **Revise periodicamente** - Remova restrições se não for mais necessário
