# Web Search Utilities

Utilitários avançados para buscas web usando **EXA** e **Tavily** como alternativa à WebSearch nativa do Claude Code.

`★ Insight ─────────────────────────────────────`
EXA é otimizado para buscas semânticas e embeddings-based, ideal para conteúdo técnico. Tavily oferece respostas diretas com RAG, perfeito para perguntas específicas. O wrapper unificado (`web_search.py`) permite usar ambos de forma transparente.
`─────────────────────────────────────────────────`

## Instalação

```bash
# Instalar dependências
pip install -r requirements.txt

# Ou manualmente:
pip install exa-py tavily-python
```

## Uso

### 1. Web Search Unificada (Recomendado)

```bash
# Busca simples (auto-detecta EXA ou Tavily)
python3 scripts/web_search.py "Claude Code techniques 2025"

# Busca com mais resultados
python3 scripts/web_search.py "AI coding workflows" -n 15

# Busca avançada com mais contexto
python3 scripts/web_search.py "DevOps best practices" -a

# Forçar engine específico
python3 scripts/web_search.py "LLM deployment" -e exa
python3 scripts/web_search.py "DevOps pipelines" -e tavily

# Modo Q&A (resposta direta - Tavily)
python3 scripts/web_search.py "Como deployar com Coolify?" -q
```

### 2. EXA Search (Buscas Semânticas)

```bash
# Busca simples
python3 scripts/exa_search.py "Claude Code documentation"

# Busca com mais resultados
python3 scripts/exa_search.py "Terraform OCI examples" 15
```

### 3. Tavily Search (RAG + Respostas Diretas)

```bash
# Busca simples
python3 scripts/tavily_search.py "DevOps automation tools"

# Modo Q&A (resposta gerada)
python3 scripts/tavily_search.py "O que é Coolify?" qna

# Busca com contexto rico
python3 scripts/tavily_search.py "Docker vs Kubernetes deployment" context
```

## Uso via Python

```python
from scripts.web_search import WebSearch

# Inicializa (auto-detecta engine disponível)
searcher = WebSearch(engine="auto")

# Busca simples
result = searcher.search("Claude Code workflows")
searcher.print_results(result)

# Busca avançada
result = searcher.search(
    "DevOps automation",
    num_results=15,
    advanced=True
)

# Pergunta e resposta
result = searcher.qna("Como configurar CI/CD com GitHub Actions?")
print(result['answer'])
```

## Uso Específico

### EXA (Buscas Semânticas)
```python
from scripts.exa_search import ExaSearcher

searcher = ExaSearcher()

# Busca com filtros
result = searcher.search_with_filters(
    query="Terraform OCI",
    num_results=10,
    search_type="auto"
)

# Encontrar páginas similares
result = searcher.find_similar("https://example.com/terraform-guide")
```

### Tavily (RAG + Q&A)
```python
from scripts.tavily_search import TavilySearcher

searcher = TavilySearcher()

# Busca com filtros de domínio
result = searcher.search_with_context(
    query="DevOps news",
    include_domains=["devops.com", "cloudnative.io"],
    search_depth="advanced"
)

# Pergunta direta
result = searcher.qna_search("Quais são os benefícios do Coolify?")
```

## Comparação: EXA vs Tavily vs WebSearch

| Característica | WebSearch Nativa | EXA | Tavily |
|---------------|------------------|-----|--------|
| Buscas rápidas simples | ✅ | ✅ | ✅ |
| Buscas semânticas | ⚠️ | ✅ Excelente | ✅ Bom |
| Respostas diretas | ❌ | ❌ | ✅ |
| Embeddings-based | ❌ | ✅ | ❌ |
| RAG | ❌ | ❌ | ✅ |
| Filtros avançados | ⚠️ | ✅ | ✅ |
| Contexto rico | ❌ | ✅ | ✅ |
| Similar Pages | ❌ | ✅ | ❌ |

## Configuração

As APIs keys devem estar no ambiente:

```bash
export EXA_API_KEY="sua_chave_exa"
export TAVILY_API_KEY="sua_chave_tavily"
```

Ou configuradas no `~/.claude/settings.json`.

## Quando Usar Cada Engine

- **EXA**: Conteúdo técnico, documentação, buscas semânticas profundas
- **Tavily**: Perguntas específicas, respostas diretas, notícias recentes
- **Auto (wrapper)**: Deixa o sistema decidir baseado em disponibilidade

## API Keys

Obtenha suas API keys:
- **EXA**: https://exa.ai/dashboard
- **Tavily**: https://tavily.com/dashboard

## Troubleshooting

```bash
# Verificar se API keys estão configuradas
echo $EXA_API_KEY
echo $TAVILY_API_KEY

# Testar EXA
python3 scripts/exa_search.py "teste"

# Testar Tavily
python3 scripts/tavily_search.py "teste" qna
```
