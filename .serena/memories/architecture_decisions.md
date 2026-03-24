# Decisões de Arquitetura

## MCP Servers

### Serena
- **Propósito**: Análise simbólica de código (IDE-like tools)
- **Contexto**: `claude-code` (otimizado para Claude Code CLI)
- **Languages**: TypeScript, Bash, YAML, Terraform, Python
- **Ferramentas**: find_symbol, rename_symbol, replace_symbol_body, etc.

### Context7
- **Propósito**: Documentação up-to-date de bibliotecas
- **Uso**: Buscar documentação técnica recente

### GitHub
- **Propósito**: Integração com GitHub (Issues, PRs, Actions)
- **Autenticação**: Personal Access Token

### Tavily
- **Propósito**: Busca web em tempo-real
- **Uso**: Notícias, documentação recente, atualizações

### EXA
- **Propósito**: Busca semântica
- **Uso**: Pesquisa profunda, papers, documentação técnica

## Hooks do Claude Code

### PostToolUse Hook
- **Gatilho**: Edit|Write
- **Ação**: Formatação + git add
- **Timeout**: 3s (previne travamento)

### PreToolUse Hook
- **Gatilho**: git push.*main
- **Ação**: Alerta de confirmação

### SessionStart Hook
- **Ação**: Mostrar mudanças recentes

## Estrutura de Memórias

### Humanas (memory/)
- **Propósito**: Documentação para humanos
- **Formato**: Markdown
- **Conteúdo**: Specs, planos, troubleshooting

### Serena (.serena/memories/)
- **Propósito**: Contexto para o agente Serena
- **Formato**: Markdown
- **Conteúdo**: Estrutura do projeto, comandos, convenções

## Integração Serena + Claude Code

1. **Serena** fornece ferramentas simbólicas (find_symbol, rename_symbol)
2. **Claude Code** fornece Edit/Write/Read nativos
3. **Contexto claude-code** remove duplicações
4. **Memórias Serena** persistem contexto entre sessões
