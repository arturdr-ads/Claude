#!/usr/bin/env python3
"""
Unified Web Search Wrapper
Wrapper unificado para buscas web usando EXA ou Tavily
"""

import sys
import os
from typing import Dict, Optional

# Adicionar scripts ao path
sys.path.insert(0, os.path.dirname(__file__))

from exa_search import ExaSearcher
from tavily_search import TavilySearcher


class WebSearch:
    """
    Wrapper unificado para buscas web
    Suporta EXA e Tavily
    """

    def __init__(self, engine: str = "auto"):
        """
        Inicializa o searcher

        Args:
            engine: Motor de busca ('auto', 'exa', 'tavily')
                   'auto' tenta usar o primeiro disponível
        """
        self.engine = self._select_engine(engine)
        self.searcher = None
        self._init_searcher()

    def _select_engine(self, engine: str) -> str:
        """Seleciona o motor de busca baseado em preferência e disponibilidade"""
        if engine == "auto":
            # Tenta EXA primeiro, depois Tavily
            if os.environ.get("EXA_API_KEY"):
                return "exa"
            elif os.environ.get("TAVILY_API_KEY"):
                return "tavily"
            else:
                raise ValueError("Nenhuma API key encontrada (EXA_API_KEY ou TAVILY_API_KEY)")
        return engine

    def _init_searcher(self):
        """Inicializa o searcher baseado no engine selecionado"""
        try:
            if self.engine == "exa":
                self.searcher = ExaSearcher()
                print("🔍 EXA inicializado")
            elif self.engine == "tavily":
                self.searcher = TavilySearcher()
                print("🔍 Tavily inicializado")
            else:
                raise ValueError(f"Engine desconhecido: {self.engine}")
        except Exception as e:
            # Fallback para o outro engine se falhar
            if self.engine == "exa" and os.environ.get("TAVILY_API_KEY"):
                print(f"⚠️  EXA falhou ({e}), tentando Tavily...")
                self.engine = "tavily"
                self.searcher = TavilySearcher()
            elif self.engine == "tavily" and os.environ.get("EXA_API_KEY"):
                print(f"⚠️  Tavily falhou ({e}), tentando EXA...")
                self.engine = "exa"
                self.searcher = ExaSearcher()
            else:
                raise

    def search(
        self,
        query: str,
        num_results: int = 10,
        advanced: bool = False,
        **kwargs
    ) -> Dict:
        """
        Executa uma busca web

        Args:
            query: Query de busca
            num_results: Número de resultados
            advanced: Busca avançada com mais contexto
            **kwargs: Argumentos adicionais específicos do engine

        Returns:
            Dicionário com resultados
        """
        print(f"\n🔎 Buscando: {query}")
        print(f"🔧 Engine: {self.engine} | 📊 Resultados: {num_results}")

        try:
            if self.engine == "exa":
                if advanced:
                    result = self.searcher.search(
                        query=query,
                        num_results=num_results,
                        search_type=kwargs.get("search_type", "auto"),
                        max_characters=kwargs.get("max_characters", 4000),
                    )
                else:
                    result = self.searcher.search(query, num_results=num_results)

            elif self.engine == "tavily":
                if advanced:
                    result = self.searcher.search_with_context(
                        query=query,
                        search_depth=kwargs.get("search_depth", "advanced"),
                        max_results=num_results,
                    )
                else:
                    result = self.searcher.search(query, max_results=num_results)

            return result

        except Exception as e:
            return {
                "success": False,
                "error": str(e),
                "query": query,
                "engine": self.engine,
            }

    def qna(self, query: str) -> Dict:
        """
        Busca otimizada para perguntas e respostas (apenas Tavily)

        Args:
            query: Pergunta ou query

        Returns:
            Dicionário com resposta
        """
        # Sempre tenta Tavily para Q&A
        try:
            tavily = TavilySearcher()
            return tavily.qna_search(query)
        except Exception as e:
            return {
                "success": False,
                "error": str(e),
                "query": query,
                "note": "QNA mode requer Tavily",
            }

    def print_results(self, result: Dict):
        """Imprime resultados de forma formatada"""
        if not result.get("success"):
            print(f"\n❌ Erro: {result.get('error', 'Desconhecido')}")
            return

        print("\n" + "=" * 80)
        print(f"✅ Busca concluída: {result['query']}")

        # Resposta gerada (Tavily)
        if result.get("answer"):
            print(f"\n💡 Resposta gerada:\n{result['answer']}\n")

        print(f"📊 {result['num_results']} resultados\n")
        print("=" * 80)

        for i, r in enumerate(result.get("results", []), 1):
            print(f"\n[{i}] {r['title']}")
            print(f"URL: {r['url']}")

            # Conteúdo/highlights
            if "text" in r:
                print(f"\n{r['text'][:400]}...")
            elif "content" in r:
                print(f"\n{r['content'][:400]}...")

            print("-" * 80)


def main():
    """CLI simples"""
    import argparse

    parser = argparse.ArgumentParser(description="Busca web unificada (EXA/Tavily)")
    parser.add_argument("query", help="Query de busca")
    parser.add_argument("-e", "--engine", choices=["auto", "exa", "tavily"],
                       default="auto", help="Motor de busca")
    parser.add_argument("-n", "--num-results", type=int, default=10,
                       help="Número de resultados")
    parser.add_argument("-a", "--advanced", action="store_true",
                       help="Busca avançada")
    parser.add_argument("-q", "--qna", action="store_true",
                       help="Modo Q&A (apenas Tavily)")

    args = parser.parse_args()

    searcher = WebSearch(engine=args.engine)

    if args.qna:
        result = searcher.qna(args.query)
        if result.get("success"):
            print(f"\n✅ Pergunta: {result['query']}")
            print(f"\n💡 Resposta:\n{result['answer']}")
        else:
            print(f"\n❌ Erro: {result.get('error', 'Desconhecido')}")
    else:
        result = searcher.search(
            query=args.query,
            num_results=args.num_results,
            advanced=args.advanced,
        )
        searcher.print_results(result)


if __name__ == "__main__":
    main()
