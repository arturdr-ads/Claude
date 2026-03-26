# Claude Code - Auto-Pilot DevOps Mode

> Personal preferences in CLAUDE.local.md

## Visão Geral

Este repositório está configurado para funcionar completamente automático usando Claude Code CLI com **Regras de Ouro** para desenvolvimento, operations e monitoring.

## 📚 Regras de Ouro - Sistema Comple

**Documentação completa em `.claude/rules/`** (Matriz 2D Híbrida)

### Regra #1: Hookify é OBRIGatÓrio
- **SEMPRE** usar Hookify para criar/modificar/remover hooks
- **NUNCA** editar `.claude/settings.json` manualmente para hooks

### Stack Configurado
**MCPs (6 ativos)**: Serena (2x), Context7, GitHub, Tavily, EXA
**Plugins (7 ativos)**: superpowers, context7, feature-dev, github, serena, explanatory, frontend-design

**devOps Skills**: 31 skills instaladas via `/plugin install devops-skills@akin-ozer`

### Estrutura de Regras
```
.claude/rules/
├── core/           # hooks.md, mcps.md, skills.md, agents.md, plugins.md
├── workflows/      # criar-sistema.md, programar.md
├── devops/         # devops-architecture.md, coolify.md, monitoramento.md
└── terraform/       # validation.md (NEW)
```

### Quick Reference
- **Hooks**: `.claude/rules/core/hooks.md` → Hookify obrigatório
- **MCPs**: `.claude/rules/core/mcps.md` → 5-7 MCPs ativos
- **DevOps**: `.claude/rules/devops/devops-architecture.md` → IaC + GitOps + CI/CD
- **Terraform**: `.claude/rules/terraform/validation.md` → Terraform validation

### Stack Tecnológico
- **IaC**: Terraform (OCI, OCIR, OKE, OCI Compute)
- **Containers**: Docker, docker-compose.yml, Dockerfiles
- **Deploy**: Coolify (YAML)
- **CI/CD**: GitHub Actions, GitOps

### Modo de Operação
**Auto-Pilot**: Todas as ações são executadas automatically:
- ✅ Formatação automática após cada Edit/Write
- ✅ Git add automático de arquivos modificados
- ✅ Segurança via Hookify (bloqueia comandos perigosos)
- ✅ Permissões automatizadas (via allow/deny lists)

## Troubleshooting
See `.claude/rules/troubleshooting.md`

## Documentação
- **Spec**: `docs/superpowers/specs/2026-03-19-claude-code-cli-hooks-design.md`
- **Plano**: `docs/superpowers/plans/2026-03-19-claude-code-cli-hooks.md`
- **Memória**: `~/.claude/memory/`

## Convenções
- **Terraform**: 2 espaços, alinhamento de atributos
- **YAML**: 2 espaços, listas com indentação extra
- **Commits**: Conventional commits (`feat:`, `fix:`, `docs:`, `chore:`)
- **Branches**: `main`, `feature/*`, `fix/*`, `docs/*`

## Development Workflow
1. Create feature branch
2. Develop with Claude Code CLI
3. Hooks format automatically
4. Commit when ready
5. Push and create PR

---
**Última atualização**: 2026-03-24 | **Versão**: 2.0.0
