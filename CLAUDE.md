# Claude Code - Auto-Pilot DevOps Mode

## Visão Geral

Este repositório está configurado para funcionar completamente automático usando Claude Code CLI com hooks de auto-formatação e git add.

### Stack Tecnológico

- **IaC**: Terraform (OCI, OCIR, OKE, OCI Compute)
- **Containers**: Docker, docker-compose.yml, Dockerfiles
- **Deploy**: Coolify (YAML)
- **CI/CD**: GitHub Actions, GitOps

### Modo de Operação

**Auto-Pilot**: Todas as ações são executadas automaticamente:
- ✅ Formatação automática após cada Edit/Write
- ✅ Git add automático de arquivos modificados
- ✅ Segurança via Hookify (bloqueia comandos perigosos)
- ✅ Permissões automatizadas (via allow/deny lists)

---

## Auto-Formatting Hooks

### Arquivos Suportados

| Extensão | Formatter | Uso |
|-----------|-----------|-----|
| `*.tf`, `*.tfvars` | `terraform fmt -diff=false` | Infraestrutura OCI |
| `*.yml`, `*.yaml`, `Dockerfile` | `yq --prettyPrint -i` | Configurações, Coolify, Docker |

**NÃO formatados automaticamente**: Shell (`*.sh`), JavaScript/TypeScript/JSON (manual quando necessário)

### Como Funciona

1. Você cria/edita um arquivo via Claude Code CLI
2. Hook **PostToolUse** roda automaticamente:
   - Formata o arquivo (terraform fmt ou yq)
   - Executa `git add` no arquivo
3. Arquivo já está pronto para commit

### Performance

- Arquivos típicos (< 10KB): < 1s
- Arquivos grandes (10-100KB): < 2s
- Arquivos muito grandes (> 100KB): Timeout de 3s (previne travamento)

---

## Segurança

### Hookify (Regras Ativas)

- ✅ `block-dangerous-commands` - Bloqueia `rm -rf`, `kill -9`, `dd`
- ✅ `warn-secrets-files` - Avisa sobre `.env`, `credentials`, `.pem`
- ✅ `warn-terraform-state` - Avisa sobre arquivos `.tfstate`
- ✅ `warn-node-modules` - Avisa sobre `node_modules/`
- ✅ `require-verification` - Pede verificação antes de completar

### Permissões Deny List

Arquivos **bloqueados** para leitura/escrita:
- `.env` (variáveis de ambiente)
- `secrets/**` (segredos e credenciais)

---

## Troubleshooting

### Hooks causando problemas?

**1. Reverter hooks:**
```bash
git checkout HEAD -- .claude/settings.json
```

**2. Desabilitar completamente:**
```bash
echo '{"hooks":{}}' > .claude/settings.json
```

**3. Restaurar hooks:**
```bash
git checkout 9d172f3 -- .claude/settings.json
```

### CLI travando?

- Provavelmente causado por `npx prettier` (removido da config)
- Verifique timeout de 3s no PostToolUse hook
- Use `git status` para verificar se há operações em andamento

---

## Comandos Úteis

```bash
# Ver configuração atual
jq . .claude/settings.json

# Ver hooks ativos
jq '.hooks.PostToolUse' .claude/settings.json

# Ver permissões deny list
jq '.permissions.deny' .claude/settings.json

# Ver worktrees
git worktree list

# Verificar formatação manualmente
terraform fmt <arquivo.tf>
yq --prettyPrint -i <arquivo.yml>
```

---

## Documentação Relacionada

- **Spec**: `@docs/superpowers/specs/2026-03-19-claude-code-cli-hooks-design.md`
- **Plano**: `@docs/superpowers/plans/2026-03-19-claude-code-cli-hooks.md`
- **Memória**: `@memory/`

---

## Convenções do Projeto

### Formatação Automática

- **Terraform**: 2 espaços, alinhamento de atributos
- **YAML**: 2 espaços, listas com indentação extra
- **Shell**: shfmt com 2 espaços (manual quando necessário)

### Commits

- Mensagens de commit em inglês (conventional commits)
- `feat:` para novas funcionalidades
- `fix:` para correções
- `docs:` para documentação
- `chore:` para manutenção

### Branches

- `main` - branch principal
- `feature/*` - novas funcionalidades
- `fix/*` - correções
- `docs/*` - documentação

---

## Desenvolvimento

### Iniciando novo trabalho

1. Criar branch de feature: `git checkout -b feature/nome-da-feature`
2. Desenvolver com Claude Code CLI
3. Hooks formatam automaticamente
4. Commitar quando pronto
5. Push e criar PR

### Code Review

- Usar `/review-pr` para revisão automática
- Verificar se formatação está correta
- Testar em ambiente isolado se necessário

---

**Última atualização**: 2026-03-23
**Versão**: 1.0
