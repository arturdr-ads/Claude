---
name: require-verification
enabled: true
event: stop
pattern: completing|finished|done|ready
action: warn
---

✅ **VERIFICAÇÃO ANTES DE CONCLUIR**

Antes de declarar trabalho completo, verifique:

1. **Testes passaram?**
   - Rodou todos os testes?
   - Coverage mínimo atingido?

2. **Código limpo?**
   - Formatação aplicada?
   - Sem console.log ou debug code?

3. **Documentação?**
   - README atualizado?
   - Mudanças documentadas?

4. **Segurança?**
   - Nenhum segredo exposto?
   - `.env` no gitignore?

**Use `/verify` skill para verificação completa.**

Técnica #11 de Boris Cherny: Feedback Loops antes de claim completion.
