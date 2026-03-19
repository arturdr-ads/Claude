---
name: warn-terraform-state
enabled: true
event: file
conditions:
  - field: file_path
    operator: regex_match
    pattern: \.tfstate$|\.tfstate\.\d+$
action: warn
---

🚫 **ARQUIVO TERRAFORM STATE DETECTADO**

Você está editando um arquivo `.tfstate`:
- **Nunca commit** `.tfstate` no git
- **Nunca edite** `.tfstate` manualmente
- Use `terraform state` commands para manipular state

**Se precisa modificar state:**
```bash
terraform state rm <resource>
terraform state mv <old> <new>
```

**O `.gitignore` deve conter:**
```
*.tfstate
*.tfstate.*
.terraform/
```
