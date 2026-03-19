#!/usr/bin/env python3
"""
Simple Search CLI for Claude Code
CLI simplificada para buscas web avançadas
"""

import sys
import os
import json

# Adicionar scripts ao path
sys.path.insert(0, os.path.dirname(__file__))

try:
    from web_search import WebSearch
except ImportError:
    print("⚠️  Dependências não instaladas.")
    print("Instale com: pip install exa-py tavily-python")
    sys.exit(1)


def simple_search(query: str, num_results: int = 5, engine: str = "auto"):
    """
    Executa uma busca simples e retorna resultados formatados

    Args:
        query: Query de busca
        num_results: Número de resultados
        engine: Engine ('auto', 'exa', 'tavily')
    """
    searcher = WebSearch(engine=engine)
    result = searcher.search(query, num_results=num_results)

    if result.get("success"):
        output = {
            "success": True,
            "query": result["query"],
            "engine": engine,  # Use the actual engine parameter
            "num_results": result["num_results"],
            "answer": result.get("answer", ""),
            "results": result.get("results", [])
        }
        return output
    else:
        return {
            "success": False,
            "error": result.get("error", "Unknown error"),
            "query": query
        }


def format_for_claude(result: dict) -> str:
    """Formata resultado para exibição em Claude Code"""
    if not result.get("success"):
        return f"❌ Erro na busca: {result.get('error')}"

    output = []
    output.append(f"🔍 Busca: {result['query']}")
    output.append(f"🔧 Engine: {result.get('engine', 'unknown')}")
    output.append(f"📊 {result['num_results']} resultados\n")

    if result.get("answer"):
        output.append("💡 Resposta gerada:")
        output.append(result['answer'])
        output.append("\n" + "=" * 80 + "\n")

    for i, r in enumerate(result.get("results", []), 1):
        output.append(f"[{i}] {r['title']}")
        output.append(f"URL: {r['url']}")

        if "text" in r:
            output.append(f"\n{r['text'][:400]}...")
        elif "content" in r:
            output.append(f"\n{r['content'][:400]}...")

        output.append("")

    return "\n".join(output)


def main():
    """CLI principal"""
    import argparse

    parser = argparse.ArgumentParser(
        description="Busca web simplificada para Claude Code",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Exemplos:
  python3 search.py "Claude Code techniques"
  python3 search.py "DevOps workflows" -n 10 -e exa
  python3 search.py "Coolify deployment" --json
        """
    )

    parser.add_argument("query", help="Query de busca")
    parser.add_argument("-n", "--num", type=int, default=5,
                       help="Número de resultados (default: 5)")
    parser.add_argument("-e", "--engine", choices=["auto", "exa", "tavily"],
                       default="auto", help="Engine de busca")
    parser.add_argument("-j", "--json", action="store_true",
                       help="Saída em JSON")
    parser.add_argument("-v", "--verbose", action="store_true",
                       help="Saída detalhada")

    args = parser.parse_args()

    # Executar busca
    result = simple_search(args.query, num_results=args.num, engine=args.engine)

    # Output
    if args.json:
        print(json.dumps(result, indent=2, ensure_ascii=False))
    elif args.verbose:
        print(format_for_claude(result))
    else:
        # Saída compacta para Claude Code
        if result.get("success"):
            print(f"✅ {result['num_results']} resultados encontrados")

            if result.get("answer"):
                print(f"\n{result['answer']}\n")

            for i, r in enumerate(result.get("results", []), 1):
                title = r['title'][:60] + "..." if len(r['title']) > 60 else r['title']
                print(f"[{i}] {title}")
                print(f"    {r['url']}")
        else:
            print(f"❌ {result.get('error')}")


if __name__ == "__main__":
    main()
