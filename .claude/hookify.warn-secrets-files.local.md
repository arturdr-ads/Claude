---
name: warn-secrets-files
enabled: true
event: file
conditions:
  - field: file_path
    operator: regex_match
    pattern: \.env$|secrets/|credentials|\.pem$|\.key$
action: warn
---

🔐 **ARQUIVO SENSÍVEL DETECTADO**

Você está editando um arquivo que pode conter segredos:
- `.env` - Variáveis de ambiente
- `secrets/` - Diretório de segredos
- `credentials` - Credenciais
- `.pem/.key` - Chaves privadas

**⚠️ NEVER commit estes arquivos no git!**

**Verifique:**
1. `.gitignore` contém estes arquivos?
2. `.env.local` está sendo usado em vez de `.env`?
3. Nenhum segredo foi expposto acidentalmente?

Proteção ativa via permissions deny list também configurada.
