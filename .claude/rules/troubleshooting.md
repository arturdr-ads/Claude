# Troubleshooting Guide

**Versão**: 1.0.0
**Atualizado**: 2026-03-24

---

## Hooks

### Hooks não executam?

```bash
# Verificar hooks ativos
cat .claude/settings.json | jq '.hooks'

# Validar
/hookify validate

# Ver logs
cat ~/.claude/hookify.log 2>/dev/null || echo "No errors"
```

### CLI travando?

1. Verificar timeout (3s)
2. Verificar se `npx prettier` está no config (removido)
3. Usar `git status` para ver se há operações

### Formatação falhando?

1. Verificar se o arquivo tem sintaxe válida (YAML, Terraform)
2. Executar formatação manualmente

```bash
terraform fmt <arquivo.tf>
yq --prettyPrint -i <arquivo.yml>
```

### MCPs com problemas?

```bash
# Verificar MCPs
claude mcp list
claude mcp validate

# Ver logs
cat ~/.claude/mcp.log 2>/dev/null || echo "No errors"
```

## Git

### Push bloque?

- Hooks de segurança bloqueam push para main
- **Solução**: Comentar sobre branch ou usar `--no-verify`

### Revert changes?

- Hooks de segurança alertam
- Use `git reset --hard` apenas como último
- **Solução**: Criar branch separado e stash changes

### Worktree issues?

```bash
# Listar worktrees
git worktree list

# Remover worktree
git worktree remove <path>

# Limpar worktrees órfãos
git worktree prune
```

## Docker

### Container não inicia?

```bash
# Verificar container
docker ps -a

# Verificar logs
docker logs <container> --tail 100

# Restart container
docker restart <container>
```

## Terraform

### Plan shows changes?

```bash
terraform plan
```

### Apply changes?

```bash
terraform apply
```

### Drift detected?

```bash
terraform plan -detailed-exitcode=2
```

### State locked?

- **Solução**: Remover `.terraform.lock` files
- **Prevention**: Add `.terraform/*.lock` to `.gitignore`

## Coolify

### Deploy falhou?

1. Verificar logs: `docker logs <container> --tail 100`
2. Verificar health: `curl http://localhost:3000/health`
3. Verificar resources: `free -h && df -h`
4. Rollback: Use `/rollback` skill

### Application not responding?

1. Verificar logs
2. Verificar container status: `docker ps`
3. Restart: `docker restart <container>`

## Performance

### Slow operations?

- Hooks de timeout (3s max)
- MCPs desconectando
- **Solução**: Reduzir número de MCPs

### Formatação lenta?

- Hooks sem timeout (3s max)
- **Solução**: Aumentar timeout em settings.json
