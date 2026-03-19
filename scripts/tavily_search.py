#!/usr/bin/env python3
"""
Tavily Advanced Search Utility
Buscas web com RAG e respostas diretas via Tavily API
"""

import os
import json
from typing import List, Dict, Optional
from tavily import TavilyClient


class TavilySearcher:
    """Utilitário de busca avançada usando Tavily API"""

    def __init__(self, api_key: Optional[str] = None):
        """
        Inicializa o searcher Tavily

        Args:
            api_key: Chave da API Tavily. Se None, usa TAVILY_API_KEY do ambiente
        """
        self.api_key = api_key or os.environ.get("TAVILY_API_KEY")
        if not self.api_key:
            raise ValueError("TAVILY_API_KEY não encontrada no ambiente")

        self.client = TavilyClient(api_key=self.api_key)

    def search(
        self,
        query: str,
        search_depth: str = "basic",
        max_results: int = 10,
        include_raw_content: bool = False,
        include_answer: bool = True,
    ) -> Dict:
        """
        Executa uma busca simples

        Args:
            query: Query de busca
            search_depth: Profundidade da busca (basic, advanced)
            max_results: Número máximo de resultados
            include_raw_content: Incluir conteúdo completo
            include_answer: Incluir resposta gerada

        Returns:
            Dicionário com resultados da busca
        """
        try:
            result = self.client.search(
                query=query,
                search_depth=search_depth,
                max_results=max_results,
                include_raw_content=include_raw_content,
                include_answer=include_answer,
            )

            return {
                "success": True,
                "query": query,
                "search_depth": search_depth,
                "answer": result.get("answer", ""),
                "num_results": len(result.get("results", [])),
                "results": [self._format_result(r) for r in result.get("results", [])],
            }

        except Exception as e:
            return {
                "success": False,
                "error": str(e),
                "query": query,
            }

    def search_with_context(
        self,
        query: str,
        search_depth: str = "advanced",
        max_results: int = 15,
        include_domains: Optional[List[str]] = None,
        exclude_domains: Optional[List[str]] = None,
        topic: str = "general",
    ) -> Dict:
        """
        Busca com contexto rico e filtros

        Args:
            query: Query de busca
            search_depth: Profundidade (basic, advanced)
            max_results: Número máximo de resultados
            include_domains: Domínios para incluir
            exclude_domains: Domínios para excluir
            topic: Tópico da busca (general, news, finance)

        Returns:
            Dicionário com resultados
        """
        try:
            result = self.client.search(
                query=query,
                search_depth=search_depth,
                max_results=max_results,
                include_domains=include_domains,
                exclude_domains=exclude_domains,
                topic=topic,
                include_raw_content=True,
                include_answer=True,
            )

            return {
                "success": True,
                "query": query,
                "search_depth": search_depth,
                "topic": topic,
                "answer": result.get("answer", ""),
                "num_results": len(result.get("results", [])),
                "results": [self._format_result(r) for r in result.get("results", [])],
            }

        except Exception as e:
            return {
                "success": False,
                "error": str(e),
                "query": query,
            }

    def qna_search(self, query: str) -> Dict:
        """
        Busca otimizada para perguntas e respostas

        Args:
            query: Pergunta ou query

        Returns:
            Dicionário com resposta e contexto
        """
        try:
            # qna_search retorna uma string diretamente
            answer = self.client.qna_search(query=query)

            return {
                "success": True,
                "query": query,
                "answer": answer,
            }

        except Exception as e:
            return {
                "success": False,
                "error": str(e),
                "query": query,
            }

    def get_search_context(
        self,
        query: str,
        search_depth: str = "advanced",
        max_results: int = 10,
        days_back: int = 7,
    ) -> Dict:
        """
        Obtém apenas o contexto da busca (sem resposta gerada)

        Args:
            query: Query de busca
            search_depth: Profundidade da busca
            max_results: Número máximo de resultados
            days_back: Dias de histórico para considerar

        Returns:
            Dicionário com contexto da busca
        """
        try:
            result = self.client.get_search_context(
                query=query,
                search_depth=search_depth,
                max_results=max_results,
                days_back=days_back,
            )

            return {
                "success": True,
                "query": query,
                "num_results": len(result),
                "context": result,
            }

        except Exception as e:
            return {
                "success": False,
                "error": str(e),
                "query": query,
            }

    def _format_result(self, result: Dict) -> Dict:
        """Formata um resultado Tavily para saída padronizada"""
        formatted = {
            "title": result.get("title", "Sem título"),
            "url": result.get("url", ""),
            "score": result.get("score", 0),
            "published_date": result.get("publishedDate", ""),
        }

        # Adicionar conteúdo se disponível
        if "content" in result and result["content"]:
            formatted["content"] = result["content"][:1000]

        return formatted


def main():
    """CLI simples para testes"""
    import sys

    if len(sys.argv) < 2:
        print("Uso: python tavily_search.py <query> [mode]")
        print("Modos: search, qna, context")
        sys.exit(1)

    query = sys.argv[1]
    mode = sys.argv[2] if len(sys.argv) > 2 else "search"

    searcher = TavilySearcher()

    if mode == "qna":
        result = searcher.qna_search(query)
        if result["success"]:
            print(f"\n✅ Pergunta: {result['query']}")
            print(f"\n💡 Resposta:\n{result['answer']}")
        else:
            print(f"❌ Erro: {result['error']}")

    elif mode == "context":
        result = searcher.get_search_context(query)
        if result["success"]:
            print(f"\n✅ Contexto para: {result['query']}")
            print(f"📊 {result['num_results']} fontes\n")
            for i, ctx in enumerate(result['context'], 1):
                print(f"[{i}] {ctx.get('url', 'N/A')}")
        else:
            print(f"❌ Erro: {result['error']}")

    else:  # default search
        result = searcher.search(query)
        if result["success"]:
            print(f"\n✅ Busca: {result['query']}")
            print(f"📊 {result['num_results']} resultados encontrados")

            if result.get("answer"):
                print(f"\n💡 Resposta gerada:\n{result['answer']}\n")

            print("=" * 80)
            for i, r in enumerate(result["results"], 1):
                print(f"\n[{i}] {r['title']}")
                print(f"URL: {r['url']}")
                if "content" in r:
                    print(f"{r['content'][:300]}...")
                print("-" * 80)
        else:
            print(f"❌ Erro na busca: {result['error']}")


if __name__ == "__main__":
    main()
