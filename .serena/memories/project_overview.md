# Claude Code CLI - Auto-Pilot DevOps Mode

## Propósito do Projeto

Repositório profissional de auto-pilot para Claude Code CLI com hooks avançados, formatação automática e integração completa com Oracle Cloud Infrastructure (OCI).

## Stack Tecnológico

- **IaC**: Terraform (OCI, OCIR, OKE, OCI Compute)
- **Containers**: Docker, docker-compose.yml, Dockerfiles
- **Deploy**: Coolify (YAML auto-deploy)
- **CI/CD**: GitHub Actions, GitOps
- **Monitoring**: Scripts customizados para Coolify
- **MCPs**: Serena, Context7, GitHub, Tavily, EXA

## Estrutura do Código

```
/
├── .claude/           # Configurações do Claude Code CLI
├── .github/           # GitHub Actions (PR review, Terraform)
├── .serena/           # Configurações do Serena MCP
├── docs/              # Documentação técnica
├── scripts/           # Scripts utilitários (Python, Shell)
├── coolify-mcp/       # Servidor MCP do Coolify
└── memory/            # Memórias persistentes (humanas)
```

## Padrões e Convenções

### Formatação Automática (via Hooks)
- Terraform: `terraform fmt -diff=false`
- YAML: `yq --prettyPrint -i`
- Git add automático após cada edição

### Commits
- Formato: `tipo: descrição` (em inglês)
- Tipos: `feat`, `fix`, `docs`, `chore`, `test`, `refactor`
- Exemplo: `feat: add Serena MCP integration`

### Branches
- `main` - branch principal
- `feature/*` - novas funcionalidades
- `fix/*` - correções
- `docs/*` - documentação
