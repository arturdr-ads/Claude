---
name: security-scan
description: Scan de vulnerabilidades com Trivy, Checkov e tfsec para containers, IaC e código
version: 1.0.0
author: arturdr
tags: [devops, security, scanning, trivy, checkov, tfsec]
dependencies:
  - trivy
  - checkov
  - tfsec
  - jq
user-invocable: true
---

# Security Scan

## Descrição

Scan de vulnerabilidades para containers Docker, IaC (Terraform), Kubernetes manifests e código fonte.

## Uso

```
/security-scan
Target: [container, iac, k8s, all]
Severity: [CRITICAL, HIGH, MEDIUM, LOW]
Format: [table, json, sarif]
```

## Container Scan (Trivy)

```bash
# Scan de imagem Docker
trivy image myapp:latest --severity CRITICAL,HIGH

# Scan com output JSON
trivy image myapp:latest --format json --output trivy-report.json

# Scan de arquivo Dockerfile
trivy config Dockerfile

# Scan de filesystem
trivy fs . --severity CRITICAL,HIGH

# Scan com ignore de vulnerabilidades conhecidas
trivy image myapp:latest --ignorefile .trivyignore.yaml
```

## IaC Scan (Checkov + tfsec)

```bash
# Terraform scan com Checkov
checkov -d terraform/ --framework terraform

# Terraform scan com tfsec
tfsec terraform/ --format json --out tfsec-report.json

# Kubernetes scan
checkov -d k8s/ --framework kubernetes

# CloudFormation scan
checkov -d cloudformation/ --framework cloudformation

# Dockerfile scan
checkov -f Dockerfile --framework dockerfile
```

## Kubernetes Manifests Scan

```bash
# Scan de manifests K8s
kubesec scan k8s/deployment.yaml

# Scan com kube-score
kube-score score k8s/*.yaml

# Scan com checkov
checkov -d k8s/ --framework kubernetes --check CKV_K8S_*
```

## SBOM Generation

```bash
# Gerar SBOM (Software Bill of Materials)
trivy image myapp:latest --format spdx-json --output sbom.spdx.json

# Verificar SBOM
trivy sbom sbom.spdx.json --severity CRITICAL,HIGH
```

## CI/CD Integration

```yaml
# .github/workflows/security-scan.yml
name: Security Scan

on:
  push:
    branches: [main]
  pull_request:

jobs:
  scan:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3

      - name: Run Trivy
        uses: aquasecurity/trivy-action@master
        with:
          scan-type: 'fs'
          severity: 'CRITICAL,HIGH'
          format: 'sarif'
          output: 'trivy-results.sarif'

      - name: Run Checkov
        uses: bridgecrewio/checkov-action@master
        with:
          directory: terraform/
          framework: terraform
          output_format: sarif

      - name: Upload SARIF
        uses: github/codeql-action/upload-sarif@v2
        with:
          sarif_file: trivy-results.sarif
```

## Severity Levels

| Level | Descrição | Ação |
|-------|-----------|------|
| CRITICAL | Vulnerabilidade crítica | Bloquear deploy |
| HIGH | Vulnerabilidade alta | Corrigir em 24h |
| MEDIUM | Vulnerabilidade média | Corrigir em 7 dias |
| LOW | Vulnerabilidade baixa | Corrigir no próximo ciclo |

## Scan Completo

```bash
#!/bin/bash
# security-scan-all.sh

echo "=== Container Scan ==="
trivy image myapp:latest --severity CRITICAL,HIGH --format table

echo "=== Terraform Scan ==="
checkov -d terraform/ --framework terraform --compact
tfsec terraform/ --format table

echo "=== Kubernetes Scan ==="
checkov -d k8s/ --framework kubernetes --compact

echo "=== Dependency Scan ==="
trivy fs . --severity CRITICAL,HIGH --skip-dirs node_modules,.git

echo "=== Summary ==="
echo "Scan completo. Verifique reports acima."
```

## Remediation

```bash
# Fix automático de vulnerabilidades conhecidas
trivy image myapp:latest --severity CRITICAL --ignore-unfixed

# Listar CVEs com fix disponível
trivy image myapp:latest --severity HIGH,CRITICAL --ignore-unfixed --format json | jq '.Results[].Vulnerabilities[] | select(.FixedVersion != null)'

# Atualizar base de dados do Trivy
trivy image --download-db-only
```

## Common Vulnerabilities

### Container

| CVE Type | Fix |
|----------|-----|
| Base image outdated | `FROM alpine:3.19` (latest) |
| Package vulnerabilities | `apk upgrade --no-cache` |
| Secrets in image | Use OCI Vault |
| Root user | `USER appuser` |

### Terraform

| Check | Fix |
|-------|-----|
| CKV_OCI_1 | Enable encryption at rest |
| CKV_OCI_2 | Enable VCN flow logs |
| CKV_OCI_3 | Disable public IP |
| CKV_OCI_4 | Enable audit logs |

### Kubernetes

| Check | Fix |
|-------|-----|
| CKV_K8S_1 | Run as non-root |
| CKV_K8S_2 | Set resource limits |
| CKV_K8S_3 | Read-only root filesystem |
| CKV_K8S_4 | Drop all capabilities |

## Checklist de Segurança

### Pré-Deploy
- [ ] Container scan sem CRITICAL/HIGH
- [ ] IaC scan passando
- [ ] K8s manifests validados
- [ ] SBOM gerado

### Pós-Deploy
- [ ] Runtime scan (opcional)
- [ ] Secrets auditados
- [ ] Network policies aplicadas
- [ ] RBAC configurado

## Reports

```bash
# Gerar relatório HTML
trivy image myapp:latest --format template --template @contrib/html.tpl --output report.html

# Gerar relatório JSON consolidado
{
  "container": $(trivy image myapp:latest --format json),
  "iac": $(checkov -d terraform/ --framework terraform --output json),
  "k8s": $(checkov -d k8s/ --framework kubernetes --output json)
}
```

## Troubleshooting

```bash
# Trivy database update failed
trivy image --download-db-only --timeout 5m

# Checkov false positive
checkov -d terraform/ --skip-check CKV_OCI_1

# tfsec config custom
tfsec terraform/ --config-file .tfsec/config.yaml

# Ignorar vulnerabilidade específica
# .trivyignore.yaml
vulnerabilities:
  - CVE-2023-12345
```
