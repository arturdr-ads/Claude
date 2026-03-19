#!/usr/bin/env python3
"""
EXA Advanced Search Utility
Buscas web avançadas otimizadas para LLMs via EXA API
"""

import os
import json
from typing import List, Dict, Optional
from exa_py import Exa


class ExaSearcher:
    """Utilitário de busca avançada usando EXA API"""

    def __init__(self, api_key: Optional[str] = None):
        """
        Inicializa o searcher EXA

        Args:
            api_key: Chave da API EXA. Se None, usa EXA_API_KEY do ambiente
        """
        self.api_key = api_key or os.environ.get("EXA_API_KEY")
        if not self.api_key:
            raise ValueError("EXA_API_KEY não encontrada no ambiente")

        self.client = Exa(api_key=self.api_key)

    def search(
        self,
        query: str,
        num_results: int = 10,
        search_type: str = "auto",
        max_characters: int = 4000,
        include_highlights: bool = True,
        use_autoprompt: bool = True,
    ) -> Dict:
        """
        Executa uma busca avançada

        Args:
            query: Query de busca
            num_results: Número de resultados (default: 10)
            search_type: Tipo de busca (auto, web, neural, keyword)
            max_characters: Caracteres máximos nos highlights
            include_highlights: Incluir highlights de conteúdo
            use_autoprompt: Usar autoprompt para otimizar query

        Returns:
            Dicionário com resultados da busca
        """
        try:
            contents = {}
            if include_highlights:
                contents["highlights"] = {"maxCharacters": max_characters}

            results = self.client.search(
                query=query,
                type=search_type,
                num_results=num_results,
                contents=contents if contents else None,
            )

            return {
                "success": True,
                "query": query,
                "num_results": len(results.results),
                "results": [self._format_result(r) for r in results.results],
            }

        except Exception as e:
            return {
                "success": False,
                "error": str(e),
                "query": query,
            }

    def search_with_filters(
        self,
        query: str,
        domain: Optional[str] = None,
        start_crawl_date: Optional[str] = None,
        end_crawl_date: Optional[str] = None,
        exclude_domains: Optional[List[str]] = None,
        **kwargs
    ) -> Dict:
        """
        Busca com filtros avançados

        Args:
            query: Query de busca
            domain: Restringir a um domínio específico
            start_crawl_date: Data de início (ISO 8601)
            end_crawl_date: Data de fim (ISO 8601)
            exclude_domains: Lista de domínios para excluir
            **kwargs: Outros argumentos passados para search()

        Returns:
            Dicionário com resultados
        """
        try:
            contents = {}
            if kwargs.get("include_highlights", True):
                contents["highlights"] = {
                    "maxCharacters": kwargs.get("max_characters", 4000)
                }

            results = self.client.search(
                query=query,
                type=kwargs.get("search_type", "auto"),
                num_results=kwargs.get("num_results", 10),
                domain=domain,
                start_crawl_date=start_crawl_date,
                end_crawl_date=end_crawl_date,
                exclude_domains=exclude_domains,
                contents=contents if contents else None,
            )

            return {
                "success": True,
                "query": query,
                "num_results": len(results.results),
                "results": [self._format_result(r) for r in results.results],
            }

        except Exception as e:
            return {
                "success": False,
                "error": str(e),
                "query": query,
            }

    def find_similar(self, url: str, num_results: int = 10) -> Dict:
        """
        Encontra páginas similares a uma URL

        Args:
            url: URL de referência
            num_results: Número de resultados

        Returns:
            Dicionário com resultados similares
        """
        try:
            results = self.client.find_similar(
                url=url,
                num_results=num_results,
                contents={"highlights": {"max_characters": 2000}},
            )

            return {
                "success": True,
                "reference_url": url,
                "num_results": len(results.results),
                "results": [self._format_result(r) for r in results.results],
            }

        except Exception as e:
            return {
                "success": False,
                "error": str(e),
                "reference_url": url,
            }

    def _format_result(self, result) -> Dict:
        """Formata um resultado EXA para saída padronizada"""
        formatted = {
            "title": result.title if result.title else "Sem título",
            "url": result.url,
            "score": result.score if result.score else 0,
        }

        # Adicionar texto/highlights se disponíveis
        if hasattr(result, 'text') and result.text:
            formatted["text"] = result.text[:1000]  # Primeiros 1000 caracteres

        # Adicionar autor/data se disponíveis
        if hasattr(result, 'author') and result.author:
            formatted["author"] = result.author

        if hasattr(result, 'published_date') and result.published_date:
            formatted["published_date"] = result.published_date

        return formatted


def main():
    """CLI simples para testes"""
    import sys

    if len(sys.argv) < 2:
        print("Uso: python exa_search.py <query> [num_results]")
        sys.exit(1)

    query = sys.argv[1]
    num_results = int(sys.argv[2]) if len(sys.argv) > 2 else 10

    searcher = ExaSearcher()
    result = searcher.search(query, num_results=num_results)

    if result["success"]:
        print(f"\n✅ Busca: {result['query']}")
        print(f"📊 {result['num_results']} resultados encontrados\n")
        print("=" * 80)

        for i, r in enumerate(result["results"], 1):
            print(f"\n[{i}] {r['title']}")
            print(f"URL: {r['url']}")
            print(f"Score: {r.get('score', 'N/A')}")
            if "text" in r:
                print(f"\n{r['text'][:500]}...")
            print("-" * 80)
    else:
        print(f"❌ Erro na busca: {result['error']}")


if __name__ == "__main__":
    main()
