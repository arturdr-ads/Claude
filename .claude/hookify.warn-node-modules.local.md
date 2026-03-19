---
name: warn-node-modules
enabled: true
event: file
conditions:
  - field: file_path
    operator: regex_match
    pattern: node_modules/|\.venv/|__pycache__|target/|build/
action: warn
---

📦 **DIRETÓRIO DE DEPENDÊNCIA DETECTADO**

Você está editando um arquivo em diretório de dependências:
- `node_modules/` - Dependências Node
- `.venv/` - Virtual environment Python
- `__pycache__` - Cache Python
- `target/` - Build Java
- `build/` - Build geral

**⚠️ Estas mudanças serão perdidas!**

**Soluções:**
- Edite o código fonte, não as dependências
- Para mudanças permanentes: fork o pacote
- Para debug: use source maps ou breakpoints

**O `.gitignore` deve conter:**
```
node_modules/
.venv/
__pycache__/
target/
build/
```
