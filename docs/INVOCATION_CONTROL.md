# Controle de Invocação de Skills - Guia Completo

## Tabela de Referência

| Configuração | Usuário | Claude | Uso |
|--------------|---------|--------|-----|
| *(padrão)* | ✅ | ✅ | Skills gerais |
| `disable-model-invocation: true` | ✅ | ❌ | Operações com side effects |
| `user-invocable: false` | ❌ | ✅ | Background knowledge |

---

## Suas Skills (Configuração Atual)

### Execution Skills (Só Usuário)

Use `/nome-da-skill` para invocar:

| Skill | Comando | Quando Usar |
|-------|---------|-------------|
| auto-deploy | `/auto-deploy` | Deploy em produção |
| terraform-plan | `/terraform-plan` | Plan/apply Terraform |
| test-all | `/test-all` | Rodar suite completa |

### Background Skills (Só Claude)

Claude usa automaticamente quando relevante:

| Skill | Quando Claude Usa |
|-------|-------------------|
| devops-oci | Trabalhando com OCI/Docker |
| feedback-loop | Reviews e validações |
| mcp-health-check | Verificando MCPs |

---

## Economia de Tokens

```
Antes da otimização:
├── Todas as skills carregadas na sessão
├── Conteúdo completo "sob demanda"
└── Uso alto de contexto

Depois da otimização:
├── Skills críticas só carregam quando invocadas
├── Background skills carregam automaticamente
└── Economia estimada: 60-80%
```

---

## Como Adicionar aos Seus Projetos

### 1. Para Skills de Execução

```yaml
---
name: meu-deploy
description: Deploy para produção
disable-model-invocation: true
---
```

### 2. Para Skills de Conhecimento

```yaml
---
name: convencoes-do-projeto
description: Padrões de código e estilo
user-invocable: false
---
```

### 3. Para Skills Gerais

```yaml
---
name: minha-skill
description: Faz algo útil
---
# Sem flags = Claude e usuário podem usar
```

---

## Comandos Úteis

```bash
# Listar todas as skills
/skills

# Ver detalhes de uma skill
/invocar nome-da-skill

# Ver contexto atual
/context
```

---

## Fontes Oficiais

- Plugin Development Guide: plugin-dev/skills/command-development/
- Frontmatter Reference: frontmatter-reference.md
- Claude Code Docs: https://code.claude.com/docs/
