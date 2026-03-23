# Coolify Deploy Skill

Auto-deploy para Coolify via API com suporte a OCI/Terraform workflows.

## Variáveis de Ambiente

- `COOLIFY_BASE_URL` - URL do Coolify (ex: https://coolify.activeads.com.br)
- `COOLIFY_ACCESS_TOKEN` - Token de acesso do Coolify

## Comandos

### Listar aplicações
```bash
curl -s "$COOLIFY_BASE_URL/api/applications" \
  -H "Authorization: Bearer $COOLIFY_ACCESS_TOKEN" | jq .
```

### Deploy da aplicação
```bash
APPLICATION_ID="1"
curl -X POST "$COOLIFY_BASE_URL/api/applications/$APPLICATION_ID/deploy" \
  -H "Authorization: Bearer $COOLIFY_ACCESS_TOKEN"
```

### Deploy com GitHub SHA
```bash
APPLICATION_ID="1"
curl -X POST "$COOLIFY_BASE_URL/api/applications/$APPLICATION_ID/deploy" \
  -H "Authorization: Bearer $COOLIFY_ACCESS_TOKEN" \
  -H "Content-Type: application/json" \
  -d "{\"commit\": \"$GITHUB_SHA\"}"
```

### Ver status do deploy
```bash
APPLICATION_ID="1"
curl -s "$COOLIFY_BASE_URL/api/applications/$APPLICATION_ID/deployments" \
  -H "Authorization: Bearer $COOLIFY_ACCESS_TOKEN" | jq '.[0]'
```

## Hooks Sugeridos

Adicionar em `.claude/settings.json`:

```json
{
  "hooks": {
    "PostToolUse": [
      {
        "matcher": "Bash(npm run build)",
        "hooks": [
          {
            "type": "command",
            "command": "curl -X POST $COOLIFY_BASE_URL/api/applications/1/deploy -H \"Authorization: Bearer $COOLIFY_ACCESS_TOKEN\""
          }
        ]
      }
    ]
  }
}
```

## Integração com Terraform

Após terraform apply em recursos OCI:

```bash
# Deploy automático após mudanças de infraestrutura
curl -X POST "$COOLIFY_BASE_URL/api/applications/$APPLICATION_ID/deploy" \
  -H "Authorization: Bearer $COOLIFY_ACCESS_TOKEN" \
  -d "{\"type\": \"trigger\", \"event\": \"terraform_apply\"}"
```

## Troubleshooting

### Verificar conexão
```bash
curl -s "$COOLIFY_BASE_URL/api/health" \
  -H "Authorization: Bearer $COOLIFY_ACCESS_TOKEN"
```

### Listar todos os resources
```bash
curl -s "$COOLIFY_BASE_URL/api/resources" \
  -H "Authorization: Bearer $COOLIFY_ACCESS_TOKEN" | jq .
```
