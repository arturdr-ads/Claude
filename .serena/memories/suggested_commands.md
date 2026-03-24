# Comandos Essenciais do Projeto

## Gerenciamento do Projeto

```bash
# Ver status do git
git status

# Ver mudanças recentes
git diff --staged
git diff

# Ver histórico de commits
git log --oneline -10

# Criar nova branch
git checkout -b feature/nome-da-feature

# Fazer merge de PR
gh pr merge <number> --squash
```

## Claude Code CLI

```bash
# Ver configuração do Claude
cat ~/.claude/settings.json | jq '.'

# Listar MCP servers
claude mcp list

# Adicionar MCP server
claude mcp add <nome> -- <comando>

# Ver worktrees
git worktree list
```

## Formatação Manual

```bash
# Terraform
terraform fmt <arquivo.tf>

# YAML
yq --prettyPrint -i <arquivo.yml>

# Shell (shfmt)
shfmt -i 2 -ci -w <arquivo.sh>
```

## Serena MCP

```bash
# Ver configuração do Serena
cat ~/.serena/serena_config.yml

# Listar projetos Serena
uvx --from git+https://github.com/oraios/serena serena project list

# Ativar projeto
uvx --from git+https://github.com/oraios/serena serena activate Claude

# Indexar projeto
uvx --from git+https://github.com/oraios/serena serena project index
```

## Scripts de Monitoramento

```bash
# Monitorar Coolify via SSH
./scripts/monitor-coolify.sh

# Monitorar Coolify via MCP
./scripts/monitor-coolify-mcp.sh
```

## Verificação e Testes

```bash
# Verificar sintaxe Terraform
terraform fmt -check
terraform validate

# Verificar sintaxe YAML
yq '.' <arquivo.yml> > /dev/null

# Testar scripts Python
python -m py_compile scripts/*.py
```

## Troubleshooting

```bash
# Reverter hooks do Claude
git checkout HEAD -- .claude/settings.json

# Restaurar hooks
git checkout 9d172f3 -- .claude/settings.json

# Ver logs do Serena
tail -f ~/.serena/logs/latest.log
```
