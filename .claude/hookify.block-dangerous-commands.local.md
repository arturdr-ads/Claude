---
name: block-dangerous-commands
enabled: true
event: bash
pattern: rm\s+-rf|rm\s+-R|kill\s+-9|dd\s+if=
action: block
---

⚠️ **COMANDO PERIGOSO BLOQUEADO**

Este comando pode causar perda de dados irreversível:
- `rm -rf` ou `rm -R` - Deleção recursiva forçada
- `kill -9` - Matar processo à força
- `dd if=` - Escrita direta em disco

**Alternativas seguras:**
- Use `rm -r` para deletar (confirmação em cada arquivo)
- Use `kill` sem `-9` (permite cleanup adequado)
- Para testes: use diretórios temporários `/tmp/`

Se você REALMENTE precisa executar este comando, remova temporariamente a regra em:
`.claude/hookify.block-dangerous-commands.local.md`
