---
paths:
  - "src/**/*.tf"
  - "terraform/**/*"
  - "*.tf"
  - "*.tfvars"
---

# Terraform Validation Rules

**Versão**: 1.0.0
**Atualizado**: 2026-03-24
**Status**: Production

---

## Regra #1: Validação O Terraform Plans. Obrigatory.

## Regra #2: Drift Detection

Execute `terraform plan` after each `terraform apply` to validate if there infrastructure changes.
 If issues found, fix them when applying.

## Regra #3: Validar Terraform fmt
Execute `terraform fmt -diff=false` **before** running `terraform validate` on directory
- If issues found, fix them when running
- Run `terraform plan` to understand the changes
- If issues found, fix them when applying

## Regra #4: Security Scan
Run `tfsec` on all `.tf` files before commiting
- Fix any critical vulnerabilities
- Never commit secrets in `.tf` files

## Quick Reference

```bash
# Validate single file
terraform validate

# Format file
terraform fmt -diff=false

# Plan changes
terraform plan

# Apply with auto-approve
terraform apply -auto-approve

# Security scan
tfsec .
```
