---
name: secrets-rotate
description: Rotação automática de secrets para OCI Vault, Kubernetes Secrets e variáveis de ambiente
version: 1.0.0
author: arturdr
tags: [devops, security, secrets, vault, rotation]
dependencies:
  - oci-cli
  - kubectl
  - jq
user-invocable: true
---

# Secrets Rotation

## Descrição

Rotação automática de secrets para OCI Vault, Kubernetes Secrets e variáveis de ambiente Coolify.

## Uso

```
/secrets-rotate
Target: [oci-vault, k8s-secret, coolify-env]
Secret: [database_password, api_key, jwt_secret]
Rotation: [30d, 90d, manual]
```

## OCI Vault Rotation

```bash
# 1. Listar secrets
oci vault secret list --compartment-id $OCI_COMPARTMENT_ID

# 2. Gerar novo secret
NEW_SECRET=$(openssl rand -base64 32)

# 3. Criar nova versão do secret
oci vault secret create-secret-version \
  --secret-id $SECRET_OCID \
  --secret-content-content $(echo -n $NEW_SECRET | base64)

# 4. Atualizar aplicação com novo secret
kubectl update secret db-credentials --from-literal=password=$NEW_SECRET -n $NAMESPACE

# 5. Restart pods para carregar novo secret
kubectl rollout restart deployment/$APP_NAME -n $NAMESPACE
```

## Kubernetes Secrets Rotation

```bash
# 1. Listar secrets
kubectl get secrets -n $NAMESPACE

# 2. Backup secret atual
kubectl get secret $SECRET_NAME -n $NAMESPACE -o yaml > secret-backup.yaml

# 3. Gerar novo valor
NEW_VALUE=$(openssl rand -base64 32)
NEW_VALUE_B64=$(echo -n $NEW_VALUE | base64)

# 4. Atualizar secret
kubectl patch secret $SECRET_NAME -n $NAMESPACE -p "{\"data\":{\"password\":\"$NEW_VALUE_B64\"}}"

# 5. Restart pods
kubectl rollout restart deployment/$APP_NAME -n $NAMESPACE

# 6. Verificar pods
kubectl get pods -n $NAMESPACE -l app=$APP_NAME -w
```

## Coolify Environment Rotation

```bash
# 1. Listar variáveis atuais
curl -s "$COOLIFY_BASE_URL/api/applications/$APP_ID/env" \
  -H "Authorization: Bearer $COOLIFY_ACCESS_TOKEN" | jq .

# 2. Gerar novo valor
NEW_VALUE=$(openssl rand -base64 32)

# 3. Atualizar variável
curl -X PATCH "$COOLIFY_BASE_URL/api/applications/$APP_ID/env" \
  -H "Authorization: Bearer $COOLIFY_ACCESS_TOKEN" \
  -H "Content-Type: application/json" \
  -d "{\"key\": \"DB_PASSWORD\", \"value\": \"$NEW_VALUE\"}"

# 4. Trigger redeploy
curl -X POST "$COOLIFY_BASE_URL/api/applications/$APP_ID/deploy" \
  -H "Authorization: Bearer $COOLIFY_ACCESS_TOKEN"
```

## Database Password Rotation

```bash
# 1. Conectar ao banco
psql -h $DB_HOST -U postgres -d $DB_NAME

# 2. Criar nova senha
ALTER USER app_user WITH PASSWORD '$NEW_PASSWORD';

# 3. Verificar conexão
psql -h $DB_HOST -U app_user -d $DB_NAME -c "SELECT 1"

# 4. Atualizar secret
kubectl patch secret db-credentials -n $NAMESPACE -p "{\"data\":{\"password\":\"$(echo -n $NEW_PASSWORD | base64)\"}}"

# 5. Restart aplicação
kubectl rollout restart deployment/$APP_NAME -n $NAMESPACE
```

## API Key Rotation

```bash
# 1. Gerar nova API key
NEW_API_KEY=$(openssl rand -hex 32)

# 2. Registrar nova key no provedor
curl -X POST "https://api.provider.com/keys" \
  -H "Authorization: Bearer $ADMIN_TOKEN" \
  -d "{\"key\": \"$NEW_API_KEY\", \"name\": \"app-$(date +%Y%m%d)\"}"

# 3. Atualizar aplicação
kubectl patch secret api-keys -n $NAMESPACE -p "{\"data\":{\"api_key\":\"$(echo -n $NEW_API_KEY | base64)\"}}"

# 4. Restart
kubectl rollout restart deployment/$APP_NAME -n $NAMESPACE

# 5. Revogar key antiga (após validação)
curl -X DELETE "https://api.provider.com/keys/$OLD_KEY_ID" \
  -H "Authorization: Bearer $ADMIN_TOKEN"
```

## JWT Secret Rotation

```bash
# 1. Gerar novo secret
NEW_JWT_SECRET=$(openssl rand -base64 64)

# 2. Atualizar com overlap (suportar tokens antigos por 1h)
kubectl set env deployment/$APP_NAME \
  JWT_SECRET_NEW=$NEW_JWT_SECRET \
  JWT_SECRET_OLD=$CURRENT_JWT_SECRET \
  JWT_OVERLAP=true \
  -n $NAMESPACE

# 3. Aguardar 1h para tokens antigos expirarem

# 4. Remover overlap
kubectl set env deployment/$APP_NAME \
  JWT_SECRET=$NEW_JWT_SECRET \
  JWT_SECRET_NEW- \
  JWT_SECRET_OLD- \
  JWT_OVERLAP- \
  -n $NAMESPACE
```

## Rotation Schedule

```yaml
# .github/workflows/secrets-rotation.yml
name: Secrets Rotation

on:
  schedule:
    - cron: '0 0 1 * *'  # Monthly

jobs:
  rotate:
    runs-on: ubuntu-latest
    steps:
      - name: Rotate DB Password
        run: |
          NEW_PASSWORD=$(openssl rand -base64 32)
          # Update secret...
```

## Checklist de Rotação

### Pré-Rotação
- [ ] Identificar secret a rotacionar
- [ ] Verificar dependências
- [ ] Backup do valor atual
- [ ] Notificar time

### Durante Rotação
- [ ] Gerar novo valor seguro
- [ ] Atualizar secret
- [ ] Restart aplicação
- [ ] Verificar health check

### Pós-Rotação
- [ ] Validar conexões
- [ ] Verificar logs de erro
- [ ] Atualizar documentação
- [ ] Agendar próxima rotação

## Security Best Practices

- Secrets com 32+ caracteres
- Rotação a cada 30-90 dias
- Nunca commitar secrets em git
- Usar OCI Vault para produção
- Auditoria de acesso a secrets

## Troubleshooting

```bash
# Secret não atualizou
kubectl describe secret $SECRET_NAME -n $NAMESPACE

# Pods não carregaram novo secret
kubectl rollout restart deployment/$APP_NAME -n $NAMESPACE

# Aplicação não conecta
kubectl logs -n $NAMESPACE -l app=$APP_NAME --tail=100 | grep -i auth
```
